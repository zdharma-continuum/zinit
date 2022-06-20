# Copyright (c) 2016-2022 Sebastian Gniazdowski and contributors.

# FUNCTION: .zinit-exists-physically [[[
# Checks if directory of given plugin exists in PLUGIN_DIR.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-exists-physically() {
   .zinit-any-to-user-plugin "$1" "$2"
     if [[ ${reply[-2]} = % ]]; then
      [[ -d ${reply[-1]} ]] \
        && return 0 || return 1
     else
      [[ -d ${ZINIT[PLUGINS_DIR]}/${reply[-2]:+${reply[-2]}---}${reply[-1]//\//---} ]] \
        && return 0 || return 1
     fi
} # ]]]
# FUNCTION: .zinit-exists-physically-message [[[
# Checks if directory of given plugin exists in PLUGIN_DIR,
# and outputs error message if it doesn't.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-exists-physically-message() {
  builtin emulate -LR zsh
  builtin setopt extendedglob noshortloops rcquotes typesetsilent warncreateglobal

  if ! .zinit-exists-physically "$1" "$2"; then
    .zinit-any-to-user-plugin "$1" "$2"
    if [[ $reply[1] = % ]] {
      .zinit-any-to-pid "$1" "$2"
      local pluginSpec1="$REPLY"
      if [[ $1 = %* ]] {
        local pluginSpec2=%${1#%}${${1#%}:+${2:+/}}${2}
      }
      elif [[ -z $1 || -z $2 ]] {
        local pluginSpec3=%${1#%}${2#%}
      }
    }
    else {
      integer pluginSpecAbsent=1
    }

    .zinit-any-colorify-as-uspl2 "$1" "$2"
    +zinit-message "{error}Failed to locate a plugin or snippet{rst}: ${REPLY} "
    if [[ $pluginSpecAbsent -eq 0 && $pluginSpec1 != $pluginSpec2 ]] {
      +zinit-message "(i.e., {file}${pluginSpec2#%}{rst})"
    }
    return 1
  fi
  return 0
} # ]]]
# FUNCTION: .zinit-first [[[
# Search for a plugins main file they are ordered in order starting from more
# correct ones, and matched. Due to slow performance, .zinit-load-plugin() does
# not call .zinit-first(). Unconventional pattern matching is also performed in
# .zinit-find-other-matches .zinit-load(), too.
#
# $1 - plugin name (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 is passed (i.e., a user)
#
.zinit-first() {
  .zinit-any-to-user-plugin "$1" "$2"
  local user="${reply[-2]}" plugin="${reply[-1]}"

  .zinit-any-to-pid "$1" "$2"
  .zinit-get-object-path plugin "$REPLY"
  local dname="$REPLY"

  integer ret=$?
  if (( ret )) { reply=( "$dname" "" ); return 1; }

  # Look for file to compile
  if [[ -e "${dname}/${plugin}.plugin.zsh" ]] {
    reply=( "${dname}/${plugin}.plugin.zsh" )
  } else {
    .zinit-find-other-matches "$dname" "$plugin"
  }

  if [[ "${#reply}" -eq "0" ]] { reply=( "$dname" "" ); return 1 }

  # Take first entry (ksharrays resilience)
  reply=( "$dname" "${reply[-${#reply}]}" )
  return 0
} # ]]]
# FUNCTION: .zinit-any-colorify-as-uspl2 [[[
# Returns ANSI-colorified "user/plugin" string, from any supported plugin spec
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin) $2 -
# plugin (only when $1 - i.e. user - given)
#
# $REPLY - ANSI-colorified "user/plugin" string
#
.zinit-any-colorify-as-uspl2() {
  .zinit-any-to-user-plugin "$1" "$2"
  local user="${reply[-2]}" plugin="${reply[-1]}" OMZ_PATTERN="(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk"
  if [[ "$user" = "%" ]] {
    .zinit-any-to-pid "" $plugin
    REPLY="${REPLY/https--github.com--${OMZ_PATTERN}--/OMZ::}"
    REPLY="${REPLY/https--github.com--${OMZ_PATTERN}--lib--/OMZL::}"
    REPLY="${REPLY/https--github.com--${OMZ_PATTERN}--lib/OMZL}"
    REPLY="${REPLY/https--github.com--${OMZ_PATTERN}--plugins--/OMZP::}"
    REPLY="${REPLY/https--github.com--${OMZ_PATTERN}--plugins/OMZP}"
    REPLY="${REPLY/https--github.com--${OMZ_PATTERN}--themes--/OMZT::}"
    REPLY="${REPLY/https--github.com--${OMZ_PATTERN}--themes/OMZT}"
    REPLY="${REPLY/https--github.com--${OMZ_PATTERN}/OMZ}"
    REPLY="${REPLY/https--github.com--sorin-ionescu--prezto--trunk--/PZT::}"
    REPLY="${REPLY/https--github.com--sorin-ionescu--prezto--trunk--modules--/PZTM::}"
    REPLY="${REPLY/https--github.com--sorin-ionescu--prezto--trunk--modules/PZTM}"
    REPLY="${REPLY/https--github.com--sorin-ionescu--prezto--trunk/PZT}"
    REPLY="${REPLY/(#b)%([A-Z]##)(#c0,1)(*)/%$ZINIT[col-uname]$match[1]$ZINIT[col-pname]$match[2]$ZINIT[col-rst]}"
  } elif [[ $user == http(|s): ]] {
    REPLY="${ZINIT[col-ice]}${user}/${plugin}${ZINIT[col-rst]}"
  } else {
    REPLY="${user:+${ZINIT[col-uname]}${user}${ZINIT[col-rst]}/}${ZINIT[col-pname]}${plugin}${ZINIT[col-rst]}"
  }
} # ]]]
# FUNCTION: .zinit-two-paths [[[
#
# RecURL without specification if it is an SVN URL (points to
# directory) or regular URL (points to file)
#
# $1 - URL
# $REPLY - Array containing two filepaths
.zinit-two-paths() {
  emulate -LR zsh
  setopt extendedglob typesetsilent warncreateglobal noshortloops

  local url=$1 dirnameA dirnameB local_dirA local_dirB svn_dirA url1 url2
  local -a fileB_there

  # Remove leading whitespace and trailing /
  url="${${url#"${url%%[! $'\t']*}"}%/}"
  url1=$url url2=$url

  .zinit-get-object-path snippet "$url1"
  local_dirA=$reply[-3] dirnameA=$reply[-2]
  if [[ -d "$local_dirA/$dirnameA/.svn" ]] {
    svn_dirA=".svn"
    if { .zinit-first % "$local_dirA/$dirnameA"; } {
      fileB_there=( ${reply[-1]} )
    }
  }

  .zinit-get-object-path snippet "$url2"
  local_dirB=$reply[-3] dirnameB=$reply[-2]
  if [[ -z $svn_dirA ]] {
    fileB_there=( "$local_dirB/$dirnameB"/*~*.(zwc|md|js|html)(.-DOnN[1]) )
  }

  reply=( "$local_dirA/$dirnameA" "$svn_dirA" "$local_dirB/$dirnameB" "${fileB_there[1]##$local_dirB/$dirnameB/#}" )
} # ]]]
# FUNCTION: .zinit-compute-ice [[[
#
# By default, computes ICE array via:
#
# a) input ice
# b) static ice
# c) saved ice
#
# Also returns path to snippet directory and
# optional name of snippet file (only valid if ICE[svn] is not set).
#
# Additionally,  also pack resulting ices into ZINIT_SICE (see $2).
#
# $1 - URL (also plugin-spec)
# $2 - "pack" or "nopack" or "pack-nf" - packing means ICE
#      wins with static ice; "pack-nf" means that disk-ices will
#      be ignored (no-file?)
# $3 - output associative array, "ICE" is the default
# $4 - output string parameter, to hold path to directory ("local_dir")
# $5 - output string parameter, to hold filename ("filename")
# $6 - output string parameter, to hold is-snippet 0/1-bool ("is_snippet")
.zinit-compute-ice() {
  emulate -LR zsh
  setopt extendedglob typesetsilent warncreateglobal noshortloops

  local ___URL="${1%/}" ___pack="$2" ___is_snippet=0
  local ___var_name1="${3:-ZINIT_ICE}" ___var_name2="${4:-local_dir}" ___var_name3="${5:-filename}" ___var_name4="${6:-is_snippet}"

  # Copy from .zinit-recall
  local -a ice_order static_ices
  ice_order=(
    ${(s.|.)ZINIT[ice-list]}
    # Include all possible ices – after stripping them from the possible: ''
    ${(@)${(@Akons:|:)${ZINIT_EXTS[ice-mods]//\'\'/}}/(#s)<->-/}
  )
  static_ices=(
    ${(s.|.)ZINIT[nval-ice-list]}
    # Include only those additional ices, don't have the '' in their name,
    # i.e. aren't designed to hold value
    ${(@)${(@)${(@Akons:|:)ZINIT_EXTS[ice-mods]}:#*\'\'*}/(#s)<->-/}
    # Must be last
    svn
  )

  # Remove whitespace from beginning of URL
  ___URL="${${___URL#"${___URL%%[! $'\t']*}"}%/}"

  # Snippet?
  .zinit-two-paths "$___URL"
  local ___s_path="${reply[-4]}" ___s_svn="${reply[-3]}" ___path="${reply[-2]}" ___filename="${reply[-1]}" ___local_dir
  if [[ -d "$___s_path" || -d "$___path" ]]; then
    ___is_snippet=1
  else
    # Plugin
    .zinit-any-to-user-plugin "$___URL" ""
    local ___user="${reply[-2]}" ___plugin="${reply[-1]}"
    ___s_path="" ___filename=""
    [[ "$___user" = "%" ]] && ___path="$___plugin" || ___path="${ZINIT[PLUGINS_DIR]}/${___user:+${___user}---}${___plugin//\//---}"
    .zinit-exists-physically-message "$___user" "$___plugin" || return 1
  fi

  if [[ $___pack = pack* && (( ${#ICE} > 0 )) ]] {
      .zinit-pack-ice "${___user-$___URL}" "$___plugin"
  }

  local -A ___sice
  local -a ___tmp
  ___tmp=( "${(z@)ZINIT_SICE[${___user-$___URL}${${___user:#(%|/)*}:+/}$___plugin]}" )
  (( ${#___tmp[@]} > 1 && ${#___tmp[@]} % 2 == 0 )) && ___sice=( "${(Q)___tmp[@]}" )

  if [[ "${+___sice[svn]}" = "1" || -n "$___s_svn" ]]; then
    if (( !___is_snippet && ${+___sice[svn]} == 1 )); then
      builtin print -r -- "The \`svn' ice is given, but the argument ($___URL) is a plugin"
      builtin print -r -- "(\`svn' can be used only with snippets)"
      return 1
    elif (( !___is_snippet )); then
      builtin print -r -- "Undefined behavior #1 occurred, please report at https://github.com/zdharma-continuum/zinit/issues"
      return 1
    fi
    if [[ -e "$___s_path" && -n "$___s_svn" ]] {
      ___sice[svn]=""
      ___local_dir="$___s_path"
    } else {
      if [[ ! -e "$___path" ]] {
        builtin print -r -- "No such snippet, looked at paths (1): $___s_path, and: $___path"
        return 1
      }
      unset '___sice[svn]'
      ___local_dir="$___path"
    }
  else
    if [[ -e "$___path" ]] {
      unset '___sice[svn]'
      ___local_dir="$___path"
    } else {
      builtin print -r -- "No such snippet found at: $___s_path or $___path"
      return 1
    }
  fi

  local ___zinit_path="$___local_dir/._zinit"

  # Read disk-Ice
  local -A ___mdata
  local ___key
  {
    for ___key in mode url is_release is_release{2..5} ${ice_order[@]}; do
      [[ -f "$___zinit_path/$___key" ]] && ___mdata[$___key]="$(<$___zinit_path/$___key)"
    done
    [[ "${___mdata[mode]}" = "1" ]] && ___mdata[svn]=""
  } 2>/dev/null

  # Handle flag-Ices; svn must be last
  for ___key in ${ice_order[@]}; do
    [[ $___key == (no|)compile ]] && continue
    (( 0 == ${+ICE[no$___key]} \
      && 0 == ${+___sice[no$___key]} )) \
      && continue
    # "If there is such ice currently, and there's no no* ice given, and
    # there's the no* ice in the static ice" – skip, don't unset. With
    # conjunction with the previous line this has the proper meaning: uset if
    # at least in one – current or static – ice there's the no* ice, but not if
    # it's only in the static ice (unless there's on such ice "anyway").
    (( 1 == ${+ICE[$___key]} && 0 == ${+ICE[no$___key]} \
      && 1 == ${+___sice[no$___key]} )) \
      && continue

    if [[ "$___key" = "svn" ]]; then
      command builtin print -r -- "0" >! "$___zinit_path/mode"
      ___mdata[mode]=0
    else
      command rm -f -- "$___zinit_path/$___key"
    fi

    unset "___mdata[$___key]" "___sice[$___key]" "ICE[$___key]"
  done

  # Final decision, static ice vs. saved ice
  local -A ___MY_ICE
  for ___key in mode url is_release is_release{2..5} ${ice_order[@]}; do
    # The second sum is: if the pack is *not* pack-nf, then depending on the
    # disk availability, otherwise: no disk ice
    (( ${+___sice[$___key]} + ${${${___pack:#pack-nf*}:+${+___mdata[$___key]}}:-0} )) \
      && ___MY_ICE[$___key]="${___sice[$___key]-${___mdata[$___key]}}"
  done
  # One more round for the special case – update, which ALWAYS needs the
  # teleid from the disk or static ice
  ___key=teleid
  if [[ "$___pack" = pack-nftid ]] {
    (( ${+___sice[$___key]} + ${+___mdata[$___key]} ))
    ___MY_ICE[$___key]="${___sice[$___key]-${___mdata[$___key]}}"
  }

  : ${(PA)___var_name1::="${(kv)___MY_ICE[@]}"}
  : ${(P)___var_name2::=$___local_dir}
  : ${(P)___var_name3::=$___filename}
  : ${(P)___var_name4::=$___is_snippet}

  return 0
} # ]]]
# FUNCTION: .zinit-store-ices [[[
#
# Convert list of ices to a hash and save to disk.
#
# $1 - directory where to create / delete files
# $2 - name of hash that holds values
# $3 - additional keys of hash to store, space separated
# $4 - additional keys of hash to store, empty-meaningful ices, space separated
# $5 – url, if applicable
# $6 – mode ( 0 - single file | 1 - svn), if applicable
#
.zinit-store-ices() {
  local ___pfx="$2" ___ice_var="$2" ___add_ices_0="$3" ___add_ices_1="$4" url="$5" mode="$6"
  # Copy from .zinit-recall
  local -a ice_order nval_ices
  ice_order=(
    ${(s.|.)ZINIT[ice-list]}
    # include all additional ices – after stripping values ''
    ${(@)${(@Akons:|:)${ZINIT_EXTS[ice-mods]//\'\'/}}/(#s)<->-/}
  )
  nval_ices=(
    ${(s.|.)ZINIT[nval-ice-list]}
    # include only static ices (e.g., do not have '', thus take no values)
    ${(@)${(@)${(@Akons:|:)ZINIT_EXTS[ice-mods]}:#*\'\'*}/(#s)<->-/}
    # must be called last
    svn
  )

  command mkdir -p "$___pfx"
  local ___key ___var_name
  # no nval_ices here
  for ___key in ${ice_order[@]:#(${(~j:|:)nval_ices[@]})} ${(s: :)___add_ices[@]}; do
    ___var_name="${___ice_var}[$___key]"
    if (( ${(P)+___var_name} )) { builtin print -r -- "${(P)___var_name}" >! "$___pfx"/"$___key" }
  done

  # Empty ices (e.g., lucid) must be captured, too
  for ___key in ${nval_ices[@]} ${(s: :)___add_ices_2[@]}; do
    ___var_name="${___ice_var}[$___key]"
    if (( ${(P)+___var_name} )) {
      builtin print -r -- "${(P)___var_name}" >! "$___pfx"/"$___key"
    } else {
      command rm -f "$___pfx"/"$___key"
    }
  done

  # url and mode are declared at the beginning of the body
  for ___key in url mode; do
    [[ -n "${(P)___key}" ]] && builtin print -r -- "${(P)___key}" >! "$___pfx"/"$___key"
  done
} # ]]]
# FUNCTION: .zinit-countdown [[[
#
# Displays a countdown 5...4... etc. and returns 0 if it sucessfully reaches 0,
# or 1 if Ctrl-C will be pressed.
#
.zinit-countdown() {
  (( !${+ICE[countdown]} )) && return 0

  emulate -L zsh -o extendedglob
  trap "+zinit-message '{ehi}ABORTING, the ice {ice}$ice{ehi} not ran{rst}'; return 1" INT
  local count=5 ice="${ICE[$1]}" tpe=$1

  if [[ $tpe = "atpull" && $ice = "%atclone" ]] { ice="${ICE[atclone]}" }

  ice="{b}{ice}$tpe{ehi}:{rst}${ice//(#b)(\{[a-z0-9…–_-]##\})/\\$match[1]}"
  +zinit-message -n -- "{hi}Waiting ${count} seconds before running {hi}$ice{rst} "
  while (( -- count + 1 )) { +zinit-message -n -- "{b}{error}"$(( count + 1 ))"{rst}"; sleep 1 }
  +zinit-message -r -- "{b}{error}0 --- running {hi}$ice{error} now{rst}{…}"

  return 0
} # ]]]

# vim:ft=zsh:sw=2:sts=2:et:foldmarker=[[[,]]]:foldmethod=marker
