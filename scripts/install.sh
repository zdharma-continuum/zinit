#!/usr/bin/env bash
# -*- mode: sh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim:ft=sh:sw=2:sts=2:et:
#
# Copyright (c) 2021-2022 zdharma-continuum and contributors
#

{ # Colors
  COLOR_BOLD_BLUE='[1;34m'
  COLOR_BOLD_CYAN='[1;36m'
  COLOR_BOLD_GREEN='[1;32m'
  COLOR_BOLD_MAGENTA='[1;35m'
  COLOR_BOLD_RED='[1;31m'
  COLOR_BOLD_WHITE_ON_BLACK='[1;37;40m'
  COLOR_BOLD_YELLOW='[1;33m'
  COLOR_PALE_MAGENTA='[38;5;177m'
  COLOR_RESET='[0m'
}

check_dependencies() {
  zsh_min_version=5.5
  if ! zsh -sfc 'autoload is-at-least;
  is-at-least $1 $ZSH_VERSION' "$zsh_min_version"; then
    echo_warning "ZSH version 5.5+ is recommended for zinit." "It'll still work,but be warned."
  fi
  if ! command -v git > /dev/null 2>&1; then
    echo_error "${COLOR_BOLD_GREEN}git${COLOR_RESET} is not installed"
    exit 1
  fi
  unset zsh_min_version
}
create_zinit_home() {
  if ! test -d "${ZINIT_HOME}"; then
    mkdir -pv -- "${ZINIT_HOME}"
    chmod g-w "${ZINIT_HOME}"
    chmod o-w "${ZINIT_HOME}"
  fi
}
create_zinit_tmpdir() {
  ZINIT_TMPDIR="$(mktemp -d)"
  if [ ! -d "$ZINIT_TMPDIR" ]; then
    echo_error "Tempdir creation failed. This ain't good"
    exit 1
  fi
  trap 'rm -rvf "$ZINIT_TMPDIR"' EXIT INT
}
display_tutorial() {
  command cat << EOF

🌻 ${COLOR_BOLD_WHITE_ON_BLACK}Welcome!${COLOR_RESET}

Now to get started you can check out the following:

- The ${COLOR_BOLD_WHITE_ON_BLACK}README${COLOR_RESET} section on the ice-modifiers:
    🧊 https://github.com/${ZINIT_REPO}#ice-modifiers
- There's also an ${COLOR_BOLD_WHITE_ON_BLACK}introduction${COLOR_RESET} to Zinit on the wiki:
    📚 https://zdharma-continuum.github.io/zinit/wiki/INTRODUCTION/
- The ${COLOR_BOLD_WHITE_ON_BLACK}For-Syntax${COLOR_RESET} article on the wiki, which hilights some best practises:
    📖 https://zdharma-continuum.github.io/zinit/wiki/For-Syntax/

💁 Need help?
- 💬 Get in touch with us on Gitter: https://gitter.im/zdharma-continuum
- 🔖 Or on GitHub: https://github.com/zdharma-continuum
EOF
}
download_git_output_processor() {
  url="https://raw.githubusercontent.com/${ZINIT_REPO}/${ZINIT_COMMIT:-${ZINIT_BRANCH}}/share/git-process-output.zsh"
  script_path="${ZINIT_TMPDIR}/git-process-output.zsh"
  echo_info "Fetching git-process-output.zsh from $url"
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL -o "$script_path" "$url"
  elif command -v wget > /dev/null 2>&1; then
    wget -q -O "$script_path" "$url"
  fi
  if [ "$?" -eq 0 ]; then
    chmod a+x "$script_path" 2> /dev/null
    echo_success 'Download finished!'
  else
    echo_warning "Download failed."
  fi
  unset url script_path
}
echo_error() {
  echo_fancy "❌" "${COLOR_BOLD_RED}" "ERROR: ${*}"
}
echo_fancy() {
  emoji="$1"
  color="$2"
  shift 2
  msg=""
  if [ -z "$NO_EMOJI" ]; then
    msg="$emoji"
  fi
  for str in "$@"; do
    if [ -z "$NO_COLOR" ]; then
      msg="${msg}${color}"
    fi
    msg="${msg}${str}"
  done
  echo "${msg}${COLOR_RESET}" >&2
  unset emoji color str msg
}
echo_info() {
  echo_fancy "🔵" "${COLOR_BOLD_BLUE}" "INFO: ${*}"
}
echo_success() {
  echo_fancy "✅" "${COLOR_BOLD_GREEN}" "SUCCESS: ${*}"
}
echo_warning() {
  echo_fancy "🚧" "${COLOR_BOLD_YELLOW}" "WARNING: ${*}"
}
edit_zshrc() {
  rc_update=1
  if grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox} -E '(zinit|zplugin)\.zsh' "${ZSHRC}" > /dev/null 2>&1; then
    echo_warning "${ZSHRC} already contains zinit commands. Not making any changes."
    rc_update=0
  fi
  if [ $rc_update -eq 1 ]; then
    echo_info "Updating ${ZSHRC} (10 lines of code, at the bottom)"
    zinit_home_escaped=${ZINIT_HOME//$HOME/\$HOME}
    command cat << EOF >> "$ZSHRC"

### Added by Zinit's installer
if [[ ! -f ${zinit_home_escaped}/${ZINIT_REPO_DIR_NAME}/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} InitiativePlugin Manager (%F{33}${ZINIT_REPO}%F{220})…%f"
    command mkdir -p "${zinit_home_escaped}" && command chmod g-rwX "${zinit_home_escaped}"
    command git clone https://github.com/${ZINIT_REPO} "${zinit_home_escaped}/${ZINIT_REPO_DIR_NAME}" && \\
        print -P "%F{33} %F{34}Installation successful.%f%b" || \\
        print -P "%F{160} The clone has failed.%f%b"
fi

source "${zinit_home_escaped}/${ZINIT_REPO_DIR_NAME}/zinit.zsh"
autoload -Uz _zinit
(( \${+_comps} )) && _comps[zinit]=_zinit
EOF
  fi
  unset rc_update zinit_home_escaped
}
query_for_annexes() {
  zshrc_annex_file="$(mktemp)"
  command cat << EOF >> "$zshrc_annex_file"

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \\
    zdharma-continuum/zinit-annex-as-monitor \\
    zdharma-continuum/zinit-annex-bin-gem-node \\
    zdharma-continuum/zinit-annex-patch-dl \\
    zdharma-continuum/zinit-annex-rust

EOF
  reply=n
  if [ -n "$NO_INPUT" ]; then
    [ -z "$NO_ANNEXES" ] && reply=y
  else
    echo "${COLOR_PALE_MAGENTA}${COLOR_RESET} Would you like to add 4 useful plugins" "- the most useful annexes (Zinit extensions that add new" "functions-features to the plugin manager) to the zshrc as well?" "It will be the following snippet:"
    command cat "$zshrc_annex_file"
    printf "${COLOR_PALE_MAGENTA}${COLOR_RESET} Enter y/n and press Return: "
    read -r reply
  fi
  if [ "$reply" = y ] || [ "$reply" = Y ]; then
    command cat "$zshrc_annex_file" >> "$ZSHRC"
    echo_info "Installing annexes"
    zsh -ic "@zinit-scheduler burst"
    echo_success 'Done!'
  else
    echo_warning "Skipped the annexes."
  fi
  command cat << EOF >> "$ZSHRC"
### End of Zinit's installer chunk
EOF
  unset reply zshrc_annex_file
}
show_environment() {
  echo_info "About to setup zinit from $ZINIT_REPO" "(branch: $ZINIT_BRANCH - commit: ${ZINIT_COMMIT:-N/A})" "to ${ZINIT_INSTALL_DIR}"
}
zinit_checkout_ref() {
  ref="${ZINIT_BRANCH}"
  git_obj_type="branch"
  if [ -n "$ZINIT_COMMIT" ]; then
    ref="$ZINIT_COMMIT"
    git_obj_type="commit"
  fi
  if zinit_git_exec checkout "$ref" > /dev/null 2>&1; then
    echo_success "Checked out $git_obj_type $ref"
  else
    echo_error "Failed to check out $git_obj_type $ref"
  fi
  unset ref git_obj_type
}
zinit_current_version() {
  zinit_git_exec describe --tags 2> /dev/null
}
zinit_git_exec() {
  command git -C "${ZINIT_INSTALL_DIR}" "$@"
}
zinit_install() {
  cd "${ZINIT_HOME}" || {
    echo_error "Failed to cd to ${ZINIT_HOME}"
    exit 1
  }
  echo_info "Installing ${COLOR_BOLD_CYAN}zinit${COLOR_RESET} to " "${COLOR_BOLD_MAGENTA}${ZINIT_INSTALL_DIR}"
  {
    command git clone --progress --branch "$ZINIT_BRANCH" "https://github.com/${ZINIT_REPO}" "${ZINIT_REPO_DIR_NAME}" 2>&1 | {
      "${ZINIT_TMPDIR}/git-process-output.zsh" || cat
    }
  } 2> /dev/null
  zinit_checkout_ref
  if [ -d "${ZINIT_REPO_DIR_NAME}" ]; then
    echo_success "Zinit succesfully installed to " "${COLOR_BOLD_GREEN}${ZINIT_INSTALL_DIR}"
    echo_info "Zinit Version: ${COLOR_BOLD_GREEN}$(zinit_current_version)"
  else
    echo_error "Failed to install Zinit to ${COLOR_BOLD_YELLOW}${ZINIT_INSTALL_DIR}"
  fi
}
zinit_update() {
  cd "${ZINIT_INSTALL_DIR}" || {
    echo_error "Failed to cd to ${ZINIT_INSTALL_DIR}"
    exit 1
  }
  echo_info "Updating ${COLOR_BOLD_CYAN}zinit${COLOR_RESET} in" "in ${COLOR_BOLD_MAGENTA}${ZINIT_INSTALL_DIR}"
  {
    zinit_git_exec clean -d -f -f
    zinit_git_exec reset --hard HEAD
  } > /dev/null 2>&1
  zinit_git_exec fetch origin "$ZINIT_BRANCH"
  zinit_checkout_ref
  if zinit_git_exec pull origin "$ZINIT_BRANCH"; then
    echo_success "Updated zinit to $(zinit_current_version)"
  fi
}

# Globals. Can be overridden.
ZINIT_REPO="${ZINIT_REPO:-zdharma-continuum/zinit}"
ZINIT_BRANCH="${ZINIT_BRANCH:-main}"
ZINIT_COMMIT="${ZINIT_COMMIT:-}" # no default value
ZINIT_HOME="${ZINIT_HOME:-${XDG_DATA_HOME:-${HOME}/.local/share}/zinit}"
ZINIT_REPO_DIR_NAME="${ZINIT_REPO_DIR_NAME:-zinit.git}"
ZINIT_INSTALL_DIR=${ZINIT_INSTALL_DIR:-${ZINIT_HOME}/${ZINIT_REPO_DIR_NAME}}
ZSHRC="${ZSHRC:-${ZDOTDIR:-${HOME}}/.zshrc}"

show_environment
check_dependencies
create_zinit_home
create_zinit_tmpdir
download_git_output_processor

if [ -d "${ZINIT_INSTALL_DIR}/.git" ]; then
  zinit_update
  ZINIT_UPDATE=1
else
  zinit_install
fi

if [ -z "$NO_EDIT" ]; then
  edit_zshrc
  [ -z "$ZINIT_UPDATE" ] && query_for_annexes
fi

if [ -z "$NO_TUTORIAL" ]; then
  display_tutorial
fi

# vim: set ft=sh et ts=2 sw=2 :
