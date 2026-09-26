#!/usr/bin/env zsh
#
# Zinit installer: install or update Zinit and load it from .zshrc.
# You can run it again at any time. It changes only what is different.
#
#   zsh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"
#   zsh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)" -- --help
#   curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh | zsh -s -- --yes

# Stage 1 (POSIX sh): start zsh when bash or sh runs this script.
if [ -z "${ZSH_VERSION-}" ]; then
  if ! command -v zsh >/dev/null 2>&1; then
    printf '%s\n' 'zinit installer: zsh is not installed. Install zsh, then run the installer again.' >&2
    exit 1
  fi
  if [ -n "${BASH_EXECUTION_STRING-}" ]; then
    exec zsh -c "$BASH_EXECUTION_STRING" install.sh "$@"
  elif [ -n "${BASH_VERSION-}" ] && [ -z "${BASH_SOURCE-}" ] && [ ! -t 0 ]; then
    exec zsh -s -- "$@"
  elif [ -f "$0" ] && grep -q _ZINIT_INSTALL_CLEAN "$0" 2>/dev/null; then
    # With "sh -c", $0 is the shell itself. Only this script contains the marker.
    exec zsh "$0" "$@"
  fi
  printf '%s\n' 'zinit installer: run the installer with zsh:' \
    '  zsh -c "$(curl -fsSL https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh)"' >&2
  exit 1
fi

# Stage 2 (zsh): run again in a clean zsh. "zsh -c" reads this script with the
# aliases and options from .zshenv. "zsh -f" does not read .zshenv.
if [[ -z ${_ZINIT_INSTALL_CLEAN-} ]]; then
  if [[ ${ZSH_EVAL_CONTEXT-} == *:file ]]; then
    print -ru2 -- 'zinit installer: run the installer as a command. Do not source it.'
    return 1
  fi
  export _ZINIT_INSTALL_CLEAN=1 ZDOTDIR=${ZDOTDIR:-$HOME}
  if [[ -n ${XDG_DATA_HOME-} ]]; then export XDG_DATA_HOME; fi
  # zsh -c 'script' --yes puts the first option in $0.
  if [[ $0 == -?* && $0 != -- ]]; then set -- "$0" "$@"; fi
  if [[ -n ${ZSH_EXECUTION_STRING-} ]]; then
    exec zsh -f -c "$ZSH_EXECUTION_STRING" install.sh "$@"
  elif [[ -o shinstdin ]]; then
    exec zsh -f -s -- "$@"
  elif [[ -f $0 ]]; then
    exec zsh -f -- "$0" "$@"
  fi
fi

# Constants

typeset -r DEFAULT_REPO=zdharma-continuum/zinit
typeset -r SCRIPT_URL=https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh
typeset -r MARK_START="### Added by Zinit's installer"
typeset -r MARK_END="### End of Zinit's installer chunk"
typeset -r HEADER='# zinit-installer v1:'
typeset -ra ANNEXES=(
  zdharma-continuum/zinit-annex-as-monitor
  zdharma-continuum/zinit-annex-bin-gem-node
  zdharma-continuum/zinit-annex-patch-dl
  zdharma-continuum/zinit-annex-rust
)
# Environment variables from the earlier installer, and the option that each one sets.
typeset -rA ENV_OPTIONS=(
  NO_INPUT yes=1              NO_EDIT edit=0            NO_ANNEXES annexes=0
  ZINIT_REPO repo             ZINIT_BRANCH branch       ZINIT_COMMIT commit
  ZINIT_HOME home_dir         ZINIT_INSTALL_DIR bin_dir ZSHRC zshrc
)

# State

typeset -A opt from        # option values, and the source of each value that is not a default
typeset -A zshrc checkout  # facts about .zshrc and about the zinit checkout
typeset -a zshrc_lines notes temp_files
typeset REPLY= tty_in= tty_out= clone_dir=
typeset c_step= c_ok= c_warn= c_err= c_bold= c_dim= c_off= sym_ok= sym_warn= sym_err=

# Help

usage() {
  print -r -- "\
Usage: install.sh [options]

Install or update Zinit and load it from .zshrc. You can run the installer
again at any time. It changes only what is different, and it never discards
local changes. The options that change the zinit block in .zshrc are kept in
the block, so the next run uses them again.

  zsh -c \"\$(curl -fsSL $SCRIPT_URL)\" -- [options]
  curl -fsSL $SCRIPT_URL | zsh -s -- [options]

Options:
  -y, --yes           Do not ask for confirmation.
  -n, --dry-run       Show the plan and the .zshrc diff. Change nothing.
  -q, --quiet         Show only warnings and errors.
      --no-edit       Do not change .zshrc. Print the zinit block instead.
      --annexes       Load the recommended annexes (default).
      --no-annexes    Do not load the recommended annexes.
      --repo REPO     Install from REPO: owner/name on GitHub, a git URL or a path.
                      Default: $DEFAULT_REPO
      --branch NAME   Install branch NAME. Default: the default branch of REPO.
      --commit SHA    Check out commit SHA (detached HEAD).
      --home-dir DIR  Keep plugins and other zinit data in DIR.
                      Default: \${XDG_DATA_HOME:-~/.local/share}/zinit
      --bin-dir DIR   Keep the zinit checkout in DIR. Default: HOME-DIR/zinit.git
      --zshrc FILE    Add the zinit block to FILE. Default: \${ZDOTDIR:-~}/.zshrc
      --uninstall     Remove the zinit block from .zshrc. Delete no files.
  -h, --help          Show this help.

Environment variables (an option on the command line overrides them):
  NO_INPUT, NO_EDIT, NO_ANNEXES
                      Same as --yes, --no-edit and --no-annexes.
  ZINIT_REPO, ZINIT_BRANCH, ZINIT_COMMIT
                      Same as --repo, --branch and --commit.
  ZINIT_HOME          Same as --home-dir.
  ZINIT_INSTALL_DIR   Same as --bin-dir. ZINIT_REPO_DIR_NAME sets only its name.
  ZSHRC               Same as --zshrc.
  NO_COLOR, NO_EMOJI, NO_TUTORIAL
                      Turn off colors, symbols or the links to the documentation.
  A variable with any value that is not empty turns its setting on.

Exit status:
  0  Success, or nothing to do.
  1  Failure, or you cancelled.
  2  Usage error.
  130  Interrupted."
}

# Output

# Set the colors and symbols. Colors need a terminal, no NO_COLOR and a TERM that is not dumb.
setup_output() {
  if [[ -t 2 && -z ${NO_COLOR-} && ${TERM:-dumb} != dumb ]]; then
    c_step=$'\e[1;34m' c_ok=$'\e[32m' c_warn=$'\e[33m' c_err=$'\e[31m'
    c_bold=$'\e[1m' c_dim=$'\e[2m' c_off=$'\e[0m'
  fi
  sym_ok='✔' sym_warn='!' sym_err='✘'
  if [[ -n ${NO_EMOJI-} ]] || ! is_utf8; then
    sym_ok='ok' sym_err='x'
  fi
}

is_utf8() {
  if zmodload zsh/langinfo 2>/dev/null && [[ ${langinfo[CODESET]-} == UTF-8 ]]; then
    return 0
  fi
  case ${LC_ALL:-${LC_CTYPE:-${LANG-}}} in
    (*UTF-8*|*utf-8*|*UTF8*|*utf8*) return 0 ;;
  esac
  return 1
}

# Messages go to stderr. Data (help, dry-run output, the zinit block) goes to stdout.
step()  { (( opt[quiet] )) || print -ru2 -- "${c_step}==>${c_off} ${c_bold}$*${c_off}"; }
info()  { (( opt[quiet] )) || print -ru2 -- "${*:+    $*}"; }
ok()    { (( opt[quiet] )) || print -ru2 -- "${c_ok}${sym_ok}${c_off} $*"; }
warn()  { print -ru2 -- "${c_warn}${sym_warn}${c_off} $*"; }
error() { print -ru2 -- "${c_err}${sym_err}${c_off} $*"; }

usage_error() {
  error "$*"
  print -ru2 -- 'Run the installer with --help to see the options.'
}

# Options

# Set option $1 to value $2. $3 is the source of the value, for the plan output.
set_opt() {
  opt[$1]=$2
  from[$1]=$3
}

# Succeed when a command-line option or an environment variable set option $1.
is_explicit() {
  case ${from[$1]-} in
    (-*|\$*) return 0 ;;
  esac
  return 1
}

# Set the options in this order: defaults, options kept in the zinit block,
# environment variables, command-line options. A later source wins.
load_options() {
  opt=( help 0 yes 0 dry_run 0 quiet 0 edit 1 annexes 1 uninstall 0
        repo $DEFAULT_REPO url '' branch '' commit '' home_dir '' bin_dir '' zshrc '' )
  from=()
  notes=()
  if [[ -n ${zshrc[options]-} ]]; then
    apply_args "${(D)zshrc[file]}" ${(Q)${(z)zshrc[options]}}
  fi
  apply_env
  apply_args '' "$@"
  resolve_options
}

apply_env() {
  local var key value
  for var key in ${(kv)ENV_OPTIONS}; do
    value=${(P)var-}
    [[ -n $value ]] || continue
    if [[ $key == *=* ]]; then
      value=${key#*=}
      key=${key%%=*}
    fi
    set_opt $key $value "\$$var"
  done
}

# Apply options in command-line form. $1 is the source label. An empty label means the option name.
apply_args() {
  local label=$1 arg
  shift
  while (( $# )); do
    arg=$1
    shift
    if [[ $arg == --?*=* ]]; then
      set -- "${arg#*=}" "$@"
      arg=${arg%%=*}
    fi
    case $arg in
      (-h|--help)    opt[help]=1 ;;
      (-y|--yes)     set_opt yes 1 ${label:-$arg} ;;
      (-n|--dry-run) set_opt dry_run 1 ${label:-$arg} ;;
      (-q|--quiet)   set_opt quiet 1 ${label:-$arg} ;;
      (--no-edit)    set_opt edit 0 ${label:-$arg} ;;
      (--annexes)    set_opt annexes 1 ${label:-$arg} ;;
      (--no-annexes) set_opt annexes 0 ${label:-$arg} ;;
      (--uninstall)  set_opt uninstall 1 ${label:-$arg} ;;
      (--repo|--branch|--commit|--home-dir|--bin-dir|--zshrc)
        if [[ -z ${1-} || $1 == -* ]]; then
          usage_error "The option $arg needs a value."
          return 2
        fi
        set_opt ${${arg#--}//-/_} $1 ${label:-$arg}
        shift ;;
      (--) ;;
      (*)
        usage_error "Unknown option or argument: $arg"
        return 2 ;;
    esac
  done
}

# Make the paths absolute and get the clone URL from --repo.
resolve_options() {
  local data_home=${XDG_DATA_HOME:-$HOME/.local/share}
  # The README uses ZINIT_HOME for the checkout itself, not for its parent directory.
  if [[ ${from[home_dir]-} == '$ZINIT_HOME' && -z ${from[bin_dir]-} && -f $opt[home_dir]/zinit.zsh ]]; then
    set_opt bin_dir $opt[home_dir] '$ZINIT_HOME'
    set_opt home_dir '' ''
    notes+=( 'ZINIT_HOME contains zinit.zsh, so the installer uses it as the bin dir.' )
  fi
  expand_path ${opt[home_dir]:-$data_home/zinit}
  opt[home_dir]=$REPLY
  if [[ -z $opt[bin_dir] ]]; then
    opt[bin_dir]=$opt[home_dir]/${ZINIT_REPO_DIR_NAME:-zinit.git}
    if [[ -n ${ZINIT_REPO_DIR_NAME-} ]]; then from[bin_dir]='$ZINIT_REPO_DIR_NAME'; fi
  fi
  expand_path $opt[bin_dir]
  opt[bin_dir]=$REPLY
  expand_path ${opt[zshrc]:-${ZDOTDIR:-$HOME}/.zshrc}
  opt[zshrc]=$REPLY
  case $opt[repo] in
    (*:*)    opt[url]=$opt[repo] ;;
    ([/.~]*) expand_path $opt[repo]; opt[url]=$REPLY ;;
    (*/*/*)  usage_error "Use a git URL for --repo $opt[repo]."; return 2 ;;
    (?*/?*)  opt[url]=https://github.com/$opt[repo].git ;;
    (*)      usage_error 'The --repo value must be owner/name, a git URL or a path.'; return 2 ;;
  esac
}

# Expand a leading ~ and make the path absolute. The result goes to $REPLY.
expand_path() {
  local p=$1
  case $p in
    ('~')   p=$HOME ;;
    ('~/'*) p=$HOME/${p#\~/} ;;
  esac
  REPLY=${p:a}
}

# Checks

preflight() {
  autoload -Uz is-at-least
  if ! is-at-least 5.8; then
    warn "zsh $ZSH_VERSION is older than 5.8. Some zinit features need zsh 5.8 or newer."
  fi
  if [[ ! -d $HOME ]]; then
    error "HOME ($HOME) is not a directory."
    return 1
  fi
  if (( EUID == 0 )) && [[ ! -O $HOME ]]; then
    error 'Run the installer as your own user, not with sudo.'
    return 1
  fi
  if (( ! opt[uninstall] && ! ${+commands[git]} )); then
    error 'git is not installed. Install git, then run the installer again.'
    return 1
  fi
}

# .zshrc

# Read .zshrc. Find the zinit block, the options in its header and other lines that load zinit.
read_zshrc() {
  local file=$opt[zshrc] line
  local -a rest
  local -i i end
  zshrc=( file $file target ${file:A} content '' start 0 end 0 header '' options ''
          block_dir '' loads 0 loads_dir '' action '' block '' )
  zshrc_lines=()
  [[ -f $file ]] || return 0
  zshrc[content]=${mapfile[$zshrc[target]]}
  zshrc_lines=( "${(@f)zshrc[content]}" )
  i=${zshrc_lines[(ie)$MARK_START]}
  if (( i <= $#zshrc_lines )); then
    zshrc[start]=$i
    rest=( "${(@)zshrc_lines[i+1,-1]}" )
    end=${rest[(ie)$MARK_END]}
    if (( end <= $#rest )); then zshrc[end]=$(( i + end )); fi
    line=${zshrc_lines[i+1]-}
    if [[ $line == "$HEADER"* ]]; then
      zshrc[header]=$line
      zshrc[options]=${line#$HEADER}
    fi
  fi
  for (( i = 1; i <= $#zshrc_lines; i++ )); do
    line=${zshrc_lines[i]}
    if (( zshrc[start] && i >= zshrc[start] && i <= zshrc[end] )); then
      # The source line of a block from the earlier installer shows where zinit is.
      case $line in
        (source*zinit.zsh*) dir_from_source_line $line; zshrc[block_dir]=$REPLY ;;
      esac
      continue
    fi
    case ${line##[[:space:]]#} in
      (\#*) ;;
      (*source*zinit.zsh*|*source*zplugin.zsh*|*'. '*zinit.zsh*|*'. '*zplugin.zsh*)
        zshrc[loads]=$i
        dir_from_source_line $line
        zshrc[loads_dir]=$REPLY
        break ;;
    esac
  done
}

# Get the zinit directory from a line that sources zinit.zsh. $REPLY is empty when the path is not clear.
dir_from_source_line() {
  local -a words=( ${(Q)${(z)1}} )
  local word prev= p= rest= line
  for word in $words; do
    case $prev in
      (source|.) p=$word; break ;;
    esac
    prev=$word
  done
  # The README keeps the checkout path in ZINIT_HOME.
  case $p in
    ('${ZINIT_HOME}'*) rest=${p#'${ZINIT_HOME}'} ;;
    ('$ZINIT_HOME'*)   rest=${p#'$ZINIT_HOME'} ;;
  esac
  if [[ -n $rest ]]; then
    for line in $zshrc_lines; do
      line=${line##[[:space:]]#}
      line=${line#export }
      if [[ $line == ZINIT_HOME=* ]]; then
        p=${(Q)line#ZINIT_HOME=}$rest
        break
      fi
    done
  fi
  expand_known_vars $p
  p=$REPLY
  case $p in
    (*'$'*|'') REPLY= ;;
    (*/zinit.zsh|*/zplugin.zsh) REPLY=${p:h} ;;
    (*) REPLY= ;;
  esac
}

# Replace the variables that the earlier installer and the README write. The result goes to $REPLY.
expand_known_vars() {
  local s=$1 data_home=${XDG_DATA_HOME:-$HOME/.local/share} pat value
  # Replace the longer forms first, because they contain $HOME.
  local -a known=(
    '${XDG_DATA_HOME:-${HOME}/.local/share}' $data_home
    '${XDG_DATA_HOME:-$HOME/.local/share}'   $data_home
    '${HOME}'                                $HOME
    '$HOME'                                  $HOME
  )
  for pat value in $known; do
    s=${s//${(b)pat}/$value}
  done
  case $s in
    ('~/'*) s=$HOME/${s#\~/} ;;
  esac
  REPLY=$s
}

# Write the options that the zinit block depends on, as one line. The result goes to $REPLY.
block_options() {
  local -a words
  local default_home=${XDG_DATA_HOME:-$HOME/.local/share}/zinit
  if ! same_repo $opt[url] https://github.com/$DEFAULT_REPO.git; then words+=( --repo=$opt[repo] ); fi
  if [[ $opt[home_dir] != $default_home ]]; then words+=( --home-dir=${(D)opt[home_dir]} ); fi
  if [[ $opt[bin_dir] != $opt[home_dir]/zinit.git ]]; then words+=( --bin-dir=${(D)opt[bin_dir]} ); fi
  if (( ! opt[annexes] )); then words+=( --no-annexes ); fi
  REPLY=${(j: :)${(@q-)words}}
}

# Write a path as zsh code. Use $HOME for a path in the home directory. The result goes to $REPLY.
shell_path() {
  if [[ $1 == "$HOME"/* ]]; then
    REPLY='"$HOME"/'${(q-)1#$HOME/}
  else
    REPLY=${(q-)1}
  fi
}

# Make the zinit block for .zshrc. The result goes to $REPLY.
render_block() {
  local data_home=${XDG_DATA_HOME:-$HOME/.local/share} annex name
  local -a lines
  block_options
  lines=(
    $MARK_START
    "$HEADER${REPLY:+ $REPLY}"
    '# Run the zinit installer again to change this block. It replaces edits between the markers.'
    'declare -A ZINIT'
  )
  if [[ $opt[home_dir] == $data_home/zinit && $opt[bin_dir] == $opt[home_dir]/zinit.git ]]; then
    lines+=( 'ZINIT[BIN_DIR]="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"' )
  else
    shell_path $opt[bin_dir]
    lines+=( "ZINIT[BIN_DIR]=$REPLY" )
  fi
  if [[ $opt[home_dir] != $data_home/zinit ]]; then
    shell_path $opt[home_dir]
    lines+=( "ZINIT[HOME_DIR]=$REPLY" )
  fi
  name=${opt[repo]//[^[:alnum:]._\/:@~-]/}
  lines+=(
    'if [[ ! -f ${ZINIT[BIN_DIR]}/zinit.zsh ]]; then'
    "  print -P \"%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}$name%F{220})…%f\""
    '  command mkdir -p "${ZINIT[BIN_DIR]:h}" && command chmod g-rwX "${ZINIT[BIN_DIR]:h}"'
    "  command git clone ${(q-)opt[url]} \"\${ZINIT[BIN_DIR]}\" && \\"
    '    print -P "%F{33} %F{34}Installation successful.%f%b" || \'
    '    print -P "%F{160} The clone has failed.%f%b"'
    'fi'
    'source "${ZINIT[BIN_DIR]}/zinit.zsh"'
    'autoload -Uz _zinit'
    '(( ${+_comps} )) && _comps[zinit]=_zinit'
  )
  if (( opt[annexes] )); then
    lines+=( '' '# Load a few important annexes, without Turbo' '# (this is currently required for annexes)' 'zinit light-mode for \' )
    for annex in $ANNEXES[1,-2]; do
      lines+=( "    $annex \\" )
    done
    lines+=( "    $ANNEXES[-1]" )
  fi
  lines+=( $MARK_END )
  REPLY=${(F)lines}
}

# Decide what to do with .zshrc. The result goes to zshrc[action].
plan_zshrc() {
  local block header
  render_block
  zshrc[block]=$REPLY
  header=${${(@f)zshrc[block]}[2]}
  block=${(F)zshrc_lines[zshrc[start],zshrc[end]]}
  if (( zshrc[start] && ! zshrc[end] )); then
    zshrc[action]=broken
  elif (( opt[uninstall] )); then
    if (( zshrc[start] )); then zshrc[action]=remove; else zshrc[action]=none; fi
  elif (( ! opt[edit] )); then
    zshrc[action]=print
  elif (( zshrc[start] )); then
    if [[ $block == $zshrc[block] ]]; then
      zshrc[action]=keep
    elif [[ $zshrc[header] == $header ]]; then
      zshrc[action]=keep-edited
    elif [[ -z $zshrc[header] ]] && ! is_explicit repo && ! is_explicit home_dir &&
         ! is_explicit bin_dir && ! is_explicit annexes; then
      zshrc[action]=keep-old
    else
      zshrc[action]=replace
    fi
  elif (( zshrc[loads] )); then
    zshrc[action]=loaded-elsewhere
  else
    zshrc[action]=append
  fi
}

# Make the new .zshrc content for the planned action. The result goes to $REPLY.
render_zshrc() {
  local -a lines
  local -i s=$zshrc[start] e=$zshrc[end]
  case $zshrc[action] in
    (append)
      REPLY=$zshrc[content]
      if [[ -n $REPLY && $REPLY != *$'\n' ]]; then REPLY+=$'\n'; fi
      if [[ -n $REPLY ]]; then REPLY+=$'\n'; fi
      REPLY+=$zshrc[block]$'\n' ;;
    (replace)
      lines=( "${(@)zshrc_lines[1,s-1]}" "${(@f)zshrc[block]}" "${(@)zshrc_lines[e+1,-1]}" )
      REPLY=${(F)lines} ;;
    (remove)
      # Also remove the empty line that the installer put before the block.
      if (( s > 1 )) && [[ -z ${zshrc_lines[s-1]} ]]; then s=$(( s - 1 )); fi
      lines=( "${(@)zshrc_lines[1,s-1]}" "${(@)zshrc_lines[e+1,-1]}" )
      REPLY=${(F)lines} ;;
    (*)
      REPLY=$zshrc[content] ;;
  esac
}

# Write .zshrc through a temporary file. Keep a backup, the file mode and a symlink to the file.
# The path of the backup goes to $REPLY.
write_zshrc() {
  local target=$zshrc[target] dir tmp backup
  dir=${target:h}
  REPLY=
  if [[ ! -d $dir ]]; then command mkdir -p -- $dir; fi
  if [[ ! -w $dir ]]; then
    error "Cannot write to ${(D)dir}. Change ${(D)opt[zshrc]} by hand."
    if [[ $zshrc[action] != remove ]]; then print -r -- $zshrc[block]; fi
    return 1
  fi
  if [[ ! -e $target ]]; then
    print -rn -- $1 >| $target
    return 0
  fi
  backup_file $target
  backup=$REPLY
  tmp=$(command mktemp "$dir/.${target:t}.XXXXXXXX")
  temp_files+=( $tmp )
  command cp -p -- $target $tmp
  print -rn -- $1 >| $tmp
  command mv -f -- $tmp $target
  temp_files=( ${temp_files:#$tmp} )
  REPLY=$backup
}

# Copy file $1 to a new backup file next to it. The path goes to $REPLY.
backup_file() {
  local stamp backup
  local -i n=1
  strftime -s stamp '%Y%m%d-%H%M%S' $EPOCHSECONDS
  backup=$1.zinit-backup.$stamp
  while [[ -e $backup ]]; do
    backup=$1.zinit-backup.$stamp.$n
    n+=1
  done
  command cp -p -- $1 $backup
  REPLY=$backup
}

apply_zshrc() {
  local file=${(D)opt[zshrc]}
  case $zshrc[action] in
    (append|replace|remove)
      render_zshrc
      write_zshrc $REPLY
      case $zshrc[action] in
        (append)  ok "Added the zinit block to $file.${REPLY:+ Backup: ${(D)REPLY}}" ;;
        (replace) ok "Replaced the zinit block in $file. Backup: ${(D)REPLY}" ;;
        (remove)  ok "Removed the zinit block from $file. Backup: ${(D)REPLY}" ;;
      esac ;;
    (keep)
      ok "$file already loads zinit." ;;
    (keep-edited)
      ok "$file already loads zinit. The installer kept the changes in the zinit block." ;;
    (keep-old)
      ok "$file already loads zinit. To replace its block with the current one, give --annexes or --no-annexes." ;;
    (loaded-elsewhere)
      ok "$file loads zinit on line $zshrc[loads], so the installer added no block." ;;
    (none)
      ok "$file has no zinit block. Nothing to remove." ;;
    (print)
      info "The installer did not change $file (--no-edit). Add this block to it:"
      print -r -- $zshrc[block] ;;
  esac
}

show_diff() {
  local file=${(D)opt[zshrc]}
  render_zshrc
  if [[ $REPLY == $zshrc[content] ]]; then
    print -r -- "No changes to $file."
    return 0
  fi
  command diff -u -L $file -L "$file (new)" <(print -rn -- $zshrc[content]) <(print -rn -- $REPLY) || :
}

# Zinit checkout

git_zinit() { command git -C $opt[bin_dir] "$@"; }

zinit_version() { git_zinit describe --tags --always 2>/dev/null || print -r -- unknown; }

# Make URLs comparable: no ".git" suffix, and one form for GitHub. The result goes to $REPLY.
normalize_url() {
  local u=${1%/}
  u=${u%.git}
  u=${u/#git@github.com:/https://github.com/}
  u=${u/#ssh:\/\/git@github.com\//https://github.com/}
  REPLY=${u:l}
}

same_repo() {
  local a
  normalize_url $1
  a=$REPLY
  normalize_url $2
  [[ $a == $REPLY ]]
}

# Find the state of the checkout: missing, not-git, dirty, pinned or tracking.
inspect_checkout() {
  local dir=$opt[bin_dir] top
  local -a files
  checkout[state]=missing
  [[ -e $dir ]] || return 0
  files=( $dir/*(DN) )
  if [[ -d $dir ]] && (( ! $#files )); then return 0; fi
  top=$(command git -C $dir rev-parse --show-toplevel 2>/dev/null) || top=
  if [[ -z $top || ${top:A} != ${dir:A} ]]; then
    checkout[state]=not-git
    return 0
  fi
  checkout[origin]=$(git_zinit config --get remote.origin.url) || checkout[origin]=
  git_zinit update-index -q --refresh >/dev/null 2>&1 || :
  if ! git_zinit diff-index --quiet HEAD -- 2>/dev/null; then
    checkout[state]=dirty
    return 0
  fi
  checkout[branch]=$(git_zinit symbolic-ref --quiet --short HEAD) || checkout[branch]=
  if [[ -n $checkout[branch] ]] && git_zinit rev-parse --quiet --verify '@{u}' >/dev/null 2>&1; then
    checkout[state]=tracking
  else
    checkout[state]=pinned
  fi
}

# Decide what to do with the zinit checkout. The result goes to checkout[action].
plan_checkout() {
  checkout=( action '' state '' branch '' origin '' )
  (( ! opt[uninstall] )) || return 0
  # Use the checkout that .zshrc loads, unless an option names another one.
  if [[ -z ${from[bin_dir]-} ]]; then
    if (( zshrc[start] )) && [[ -z $zshrc[header] && -n $zshrc[block_dir] ]]; then
      set_opt bin_dir $zshrc[block_dir] ${(D)opt[zshrc]}
    elif (( zshrc[loads] && ! zshrc[start] )); then
      if [[ -z $zshrc[loads_dir] ]]; then
        checkout[action]=unknown
        return 0
      fi
      set_opt bin_dir $zshrc[loads_dir] "line $zshrc[loads] of ${(D)opt[zshrc]}"
    fi
  fi
  inspect_checkout
  if [[ $checkout[state] == not-git ]]; then
    error "${(D)opt[bin_dir]} exists, but it is not a git checkout. Remove it, or give another --bin-dir."
    return 1
  fi
  if [[ -n $checkout[origin] ]] && ! same_repo $checkout[origin] $opt[url]; then
    if is_explicit repo; then
      error "${(D)opt[bin_dir]} is a clone of $checkout[origin], not of $opt[repo]. Remove it, or give another --bin-dir."
      return 1
    fi
    set_opt repo $checkout[origin] ${(D)opt[bin_dir]}
    opt[url]=$checkout[origin]
  fi
  case $checkout[state] in
    (missing) checkout[action]=clone ;;
    (dirty)   checkout[action]=keep-dirty ;;
    (*)
      if [[ -n $opt[commit] ]]; then
        checkout[action]=commit
      elif [[ -n $opt[branch] && $opt[branch] != $checkout[branch] ]]; then
        checkout[action]=switch
      elif [[ $checkout[state] == pinned ]]; then
        checkout[action]=keep-pinned
      else
        checkout[action]=update
      fi ;;
  esac
}

clone_zinit() {
  local -a args=( clone --config core.autocrlf=false --config core.eol=lf )
  if [[ -n $opt[branch] ]]; then args+=( --branch $opt[branch] ); fi
  if (( opt[quiet] )) || [[ ! -t 2 ]]; then args+=( --quiet ); else args+=( --progress ); fi
  command mkdir -p -- ${opt[bin_dir]:h}
  # When the clone does not finish, cleanup() removes the directory.
  if [[ ! -e $opt[bin_dir] ]]; then clone_dir=$opt[bin_dir]; fi
  if ! command git $args -- $opt[url] $opt[bin_dir]; then
    error "Cannot clone $opt[url]."
    return 1
  fi
  if [[ -n $opt[commit] ]]; then checkout_commit; fi
  clone_dir=
}

checkout_commit() {
  if ! git_zinit rev-parse --quiet --verify "$opt[commit]^{commit}" >/dev/null; then
    error "Commit $opt[commit] is not in $opt[repo]."
    return 1
  fi
  git_zinit checkout --quiet --detach $opt[commit]
}

# Compile zinit as "zinit self-update" does. A failed compile does not stop the installer.
compile_zinit() {
  local dir=$opt[bin_dir] file
  local -a zwc failed
  zwc=( $dir/*.zwc(N) )
  if (( $#zwc )); then command rm -f -- $zwc; fi
  for file in $dir/zinit{,-side,-install,-autoload,-additional}.zsh $dir/share/git-process-output.zsh; do
    if [[ -f $file ]] && ! builtin zcompile -U $file 2>/dev/null; then
      failed+=( ${file:t} )
    fi
  done
  if (( $#failed )); then warn "Cannot compile: $failed"; fi
  return 0
}

apply_checkout() {
  local dir=${(D)opt[bin_dir]} before after
  case $checkout[action] in
    (clone)
      step "Cloning $opt[repo] into $dir"
      clone_zinit
      compile_zinit
      ok "Installed zinit $(zinit_version) in $dir." ;;
    (update|switch|commit)
      step "Updating zinit in $dir"
      before=$(git_zinit rev-parse HEAD)
      git_zinit fetch --quiet
      case $checkout[action] in
        (switch)
          git_zinit checkout --quiet $opt[branch]
          git_zinit merge --quiet --ff-only '@{u}' ;;
        (commit)
          checkout_commit ;;
        (update)
          if ! git_zinit merge --quiet --ff-only '@{u}'; then
            warn "Cannot fast-forward $checkout[branch] in $dir. The installer did not change it."
            return 0
          fi ;;
      esac
      after=$(git_zinit rev-parse HEAD)
      if [[ $before == $after ]]; then
        ok "zinit $(zinit_version) in $dir is up to date."
      else
        compile_zinit
        ok "Updated zinit in $dir to $(zinit_version)."
      fi ;;
    (keep-dirty)
      warn "$dir has local changes, so the installer did not update it."
      info 'Commit or stash the changes, then run the installer again.' ;;
    (keep-pinned)
      ok "zinit in $dir is pinned at $(zinit_version). To follow a branch, give --branch NAME." ;;
    (unknown)
      warn "The installer cannot find the zinit that ${(D)opt[zshrc]} loads. To update it, give --bin-dir DIR." ;;
  esac
}

# Plan, confirmation and summary

show_plan() {
  local fd=2
  if (( opt[dry_run] )); then fd=1; elif (( opt[quiet] )); then return 0; fi
  local repo=$opt[repo] branch=${opt[branch]:-default branch} bin=${(D)opt[bin_dir]}
  local rc=${(D)opt[zshrc]} annexes=no note
  if (( opt[annexes] )); then annexes=yes; fi
  local -A actions=(
    clone          "Clone $repo into $bin."
    update         "Update $bin (fast-forward only)."
    switch         "Switch $bin to branch $opt[branch]."
    commit         "Check out commit $opt[commit] in $bin."
    keep-dirty     "Keep $bin: it has local changes."
    keep-pinned    "Keep $bin: it is pinned to a commit."
    unknown        "Keep the zinit that $rc loads."
    append         "Add the zinit block to $rc."
    replace        "Replace the zinit block in $rc."
    remove         "Remove the zinit block from $rc."
    none           "Nothing to remove from $rc."
    keep           "Keep $rc: it already loads zinit."
    keep-edited    "Keep $rc: the zinit block has manual changes."
    keep-old       "Keep $rc: it has a block from an earlier installer."
    loaded-elsewhere "Keep $rc: line $zshrc[loads] loads zinit."
    print          "Print the zinit block. Do not change $rc."
    broken         "Stop: $rc has the start marker on line $zshrc[start], but no end marker."
  )
  print -ru$fd -- "${c_step}==>${c_off} ${c_bold}Zinit installer${c_off}"
  if (( ! opt[uninstall] )); then
    plan_row repo "$repo" repo
    plan_row branch "$branch" branch
    if [[ -n $opt[commit] ]]; then plan_row commit $opt[commit] commit; fi
    plan_row 'bin dir' $bin bin_dir
    plan_row 'home dir' ${(D)opt[home_dir]} home_dir
    plan_row annexes $annexes annexes
  fi
  plan_row zshrc $rc zshrc
  for note in $notes; do print -ru$fd -- "    $note"; done
  print -ru$fd -- "${c_step}==>${c_off} ${c_bold}Plan${c_off}"
  if [[ -n $checkout[action] ]]; then print -ru$fd -- "    ${actions[$checkout[action]]}"; fi
  print -ru$fd -- "    ${actions[$zshrc[action]]}"
}

# Print one setting of the plan: label, value and the source of the value.
plan_row() {
  local origin=${from[$3]-}
  print -ru$fd -- "    ${(r:9:)1} $2${origin:+  ${c_dim}(from $origin)${c_off}}"
}

needs_confirmation() {
  (( ! opt[yes] )) || return 1
  case $checkout[action]:$zshrc[action] in
    (clone:*|*:append|*:replace|*:remove) return 0 ;;
  esac
  return 1
}

# Ask on the terminal, also when stdin is a pipe. With no terminal, the answer is yes.
confirm() {
  local answer dev=${_ZINIT_INSTALL_TTY:-/dev/tty}
  { exec {tty_in}<$dev } 2>/dev/null || tty_in=
  [[ -n $tty_in ]] || return 0
  { exec {tty_out}>>$dev } 2>/dev/null || tty_out=2
  while true; do
    print -rn -u $tty_out -- 'Continue? [Y/n] '
    if ! read -r -u $tty_in answer; then
      print -u $tty_out
      return 0
    fi
    case $answer in
      (''|[Yy]|[Yy][Ee][Ss]) return 0 ;;
      ([Nn]|[Nn][Oo]) return 1 ;;
    esac
  done
}

show_next_steps() {
  (( ! opt[quiet] )) || return 0
  if (( opt[uninstall] )); then
    if [[ $zshrc[action] == remove ]]; then
      info 'Start a new shell to stop loading zinit: exec zsh'
    fi
    info "To delete zinit and its plugins: rm -rf ${(q-)opt[home_dir]}"
    if [[ $opt[bin_dir] != $opt[home_dir]/* ]]; then
      info "To delete the zinit checkout: rm -rf ${(q-)opt[bin_dir]}"
    fi
    return 0
  fi
  case $checkout[action]:$zshrc[action] in
    (clone:*|*:append|*:replace)
      info 'Start a new shell to load zinit: exec zsh' ;;
  esac
  if [[ $checkout[action] == clone && -z ${NO_TUTORIAL-} ]]; then
    info
    info 'Get started:'
    info '  Introduction   https://zdharma-continuum.github.io/zinit/wiki/INTRODUCTION/'
    info '  Ice modifiers  https://github.com/zdharma-continuum/zinit#ice-modifiers'
    info '  For-syntax     https://zdharma-continuum.github.io/zinit/wiki/For-Syntax/'
    info '  Chat           https://matrix.to/#/#zdharma-continuum_community:gitter.im'
    info '  Issues         https://github.com/zdharma-continuum/zinit/issues'
  fi
}

# Main

run() {
  setup_output
  load_options "$@"
  if (( opt[help] )); then
    usage
    return 0
  fi
  read_zshrc
  if [[ -n $zshrc[options] ]]; then load_options "$@"; fi
  preflight
  plan_checkout
  plan_zshrc
  show_plan
  if [[ $zshrc[action] == broken ]]; then
    error "Add \"$MARK_END\" after the zinit block in ${(D)opt[zshrc]}, or remove the block."
    return 1
  fi
  if (( opt[dry_run] )); then
    show_diff
    return 0
  fi
  if needs_confirmation && ! confirm; then
    warn 'Cancelled. Nothing changed.'
    return 1
  fi
  apply_checkout
  apply_zshrc
  show_next_steps
}

cleanup() {
  if [[ -n $clone_dir && $clone_dir != / && $clone_dir != $HOME ]]; then
    command rm -rf -- $clone_dir
  fi
  if (( $#temp_files )); then command rm -f -- $temp_files; fi
  if [[ -n $tty_in ]]; then exec {tty_in}<&-; fi
  if [[ $tty_out == <3-> ]]; then exec {tty_out}>&-; fi
}

main() {
  emulate -L zsh
  setopt err_return pipe_fail warn_create_global extended_glob
  umask 022
  zmodload zsh/datetime
  zmodload -F zsh/mapfile p:mapfile
  trap 'exit 130' INT
  trap 'exit 143' TERM
  {
    run "$@"
  } always {
    cleanup
  }
}

main "$@"

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et
