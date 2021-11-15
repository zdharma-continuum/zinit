#!/bin/sh

#
# Clone or pull
#

ZINIT_HOME="${ZINIT_HOME:-$ZPLG_HOME}"
if [ -z "$ZINIT_HOME" ]; then
    ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"
fi

ZINIT_BIN_DIR_NAME="${ZINIT_BIN_DIR_NAME:-$ZPLG_BIN_DIR_NAME}"
if [ -z "$ZINIT_BIN_DIR_NAME" ]; then
    ZINIT_BIN_DIR_NAME="zinit.git"
fi

if ! test -d "$ZINIT_HOME"; then
    mkdir -p "$ZINIT_HOME"
    chmod g-w "$ZINIT_HOME"
    chmod o-w "$ZINIT_HOME"
fi

if ! command -v git >/dev/null 2>&1; then
    echo "[1;31m▓▒░[0m Something went wrong: [1;32mgit[0m is not available, cannot proceed."
    exit 1
fi

ZINIT_BRANCH="${ZINIT_BRANCH:-master}"
ZINIT_TMPDIR="$(mktemp -d)" # use -d instead of --directory for macos (BSD) compatibility
if [ ! -d "$ZINIT_TMPDIR" ]; then
    echo "Tempdir creation failed. This ain't good." >&2
    exit 1
fi

# Get the download-progress bar tool
GIT_PROCESS_SCRIPT_URL="https://raw.githubusercontent.com/zdharma-continuum/zinit/${ZINIT_BRANCH}/git-process-output.zsh"
trap 'rm -rvf "$ZINIT_TMPDIR"' EXIT INT
if command -v curl >/dev/null 2>&1; then
    curl -fsSL -o "${ZINIT_TMPDIR}/git-process-output.zsh" "$GIT_PROCESS_SCRIPT_URL"
elif command -v wget >/dev/null 2>&1; then
    wget -q -O "${ZINIT_TMPDIR}/git-process-output.zsh" "$GIT_PROCESS_SCRIPT_URL"
fi
chmod a+x "${ZINIT_TMPDIR}/git-process-output.zsh" 2>/dev/null

echo
if test -d "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME/.git"; then
    cd "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME" || { echo "Failed to cd to $ZINIT_HOME/$ZINIT_BIN_DIR_NAME" >&2; exit 1; }
    echo "[1;34m▓▒░[0m Updating [1;36mZDHARMA-CONTINUUM[1;33m Initiative Plugin Manager[0m to [1;35m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m"
    git pull origin "${ZINIT_BRANCH}"
else
    cd "$ZINIT_HOME" || { echo "Failed to cd to $ZINIT_HOME" >&2; exit 1; }
    echo "[1;34m▓▒░[0m Installing [1;36mZDHARMA-CONTINUUM[1;33m Initiative Plugin Manager[0m to [1;35m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m"
    {
        git clone --progress --branch "$ZINIT_BRANCH" \
            https://github.com/zdharma-continuum/zinit.git \
            "$ZINIT_BIN_DIR_NAME" 2>&1 | {
            "${ZINIT_TMPDIR}/git-process-output.zsh" || cat;
        }
    } 2>/dev/null
    if [ -d "$ZINIT_BIN_DIR_NAME" ]; then
        echo
        echo "[1;34m▓▒░[0m Zinit succesfully installed at [1;32m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m".
        VERSION="$(command git -C "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME" describe --tags 2>/dev/null)"
        echo "[1;34m▓▒░[0m Version: [1;32m$VERSION[0m"
    else
        echo
        echo "[1;31m▓▒░[0m Something went wrong, couldn't install Zinit to [1;33m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m"
    fi
fi

#
# Modify .zshrc
#
THE_ZDOTDIR="${ZDOTDIR:-$HOME}"
RCUPDATE=1
if grep -E '(zinit|zplugin)\.zsh' "$THE_ZDOTDIR/.zshrc" >/dev/null 2>&1; then
    echo "[34m▓▒░[0m .zshrc already contains \`zinit …' commands – not making changes."
    RCUPDATE=0
fi

if [ $RCUPDATE -eq 1 ]; then
    echo "[34m▓▒░[0m Updating $THE_ZDOTDIR/.zshrc (10 lines of code, at the bottom)"
    ZINIT_HOME="$(echo "$ZINIT_HOME" | sed "s|$HOME|\$HOME|")"
    command cat <<-EOF >> "$THE_ZDOTDIR/.zshrc"

### Added by Zinit's installer
if [[ ! -f $ZINIT_HOME/$ZINIT_BIN_DIR_NAME/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$ZINIT_HOME" && command chmod g-rwX "$ZINIT_HOME"
    command git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME" && \\
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \\
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

source "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME/zinit.zsh"
autoload -Uz _zinit
(( \${+_comps} )) && _comps[zinit]=_zinit
EOF
    file="$(mktemp)"
    command cat <<-EOF >>"$file"

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \\
    zdharma-continuum/zinit-annex-rust \\
    zdharma-continuum/zinit-annex-as-monitor \\
    zdharma-continuum/zinit-annex-patch-dl \\
    zdharma-continuum/zinit-annex-bin-gem-node

EOF
echo
echo "[38;5;219m▓▒░[0m Would you like to add 4 useful plugins" \
    "- the most useful annexes (Zinit extensions that add new" \
    "functions-features to the plugin manager) to the zshrc as well?" \
    "It will be the following snippet:"
    command cat "$file"
    printf "[38;5;219m▓▒░[0m Enter y/n and press Return: "
    read -r input
    if [ "$input" = y ] || [ "$input" = Y ]; then
        command cat "$file" >> "$THE_ZDOTDIR"/.zshrc
        echo
        echo "[34m▓▒░[0m Done."
        echo
    else
        echo
        echo "[34m▓▒░[0m Done (skipped the annexes chunk)."
        echo
    fi

    command cat <<-EOF >> "$THE_ZDOTDIR/.zshrc"
### End of Zinit's installer chunk
EOF
fi

command cat <<-EOF

[34m▓▒░[0m A quick intro to Zinit: below are all the available Zinit
[34m▓▒░[0m ice-modifiers, grouped by their role by different colors):
[34m▓▒░[0m
[38;5;219m▓▒░[0m id-as'' as'' from'' [38;5;111mwait'' trigger-load'' load'' unload''
[38;5;219m▓▒░[0m [38;5;51mpick'' src'' multisrc'' [38;5;172mpack'' param'' [0mextract'' [38;5;220matclone''
[38;5;219m▓▒░[0m [38;5;220matpull'' atload'' atinit'' make'' mv'' cp'' reset''
[38;5;219m▓▒░[0m [38;5;220mcountdown'' [38;5;160mcompile'' nocompile'' [0mnocd'' [38;5;177mif'' has''
[38;5;219m▓▒░[0m [38;5;178mcloneopts'' depth'' proto'' [38;5;82mon-update-of'' subscribe''
[38;5;219m▓▒░[0m bpick'' cloneonly'' service'' notify'' wrap-track''
[38;5;219m▓▒░[0m bindmap'' atdelete'' ver''

[34m▓▒░[0m No-value (flag-only) ices:
[38;5;219m▓▒░[0m [38;5;220msvn git [38;5;82msilent lucid [0mlight-mode is-snippet blockf nocompletions
[38;5;219m▓▒░[0m run-atpull reset-prompt trackbinds aliases [38;5;111msh bash ksh csh[0m

For more information see:
- [38;5;226mThe zdharma-continuum[0m GitHub organization, which hosts zinit and all related components
    - https://github.com/zdharma-continuum
- [38;5;226mREADME[0m section on the ice-modifiers:
    - https://github.com/zdharma-continuum/zinit#ice-modifiers
- [38;5;226mAn introduction[0m to Zinit on the wiki:
    - https://zdharma-continuum.github.io/zinit/wiki/INTRODUCTION/
- [38;5;226mFor-Syntax[0m article on the wiki; it is less directly related to the ices but it explains how to use them conveniently:
    - https://zdharma-continuum.github.io/zinit/wiki/For-Syntax/
EOF
