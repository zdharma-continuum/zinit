#!/bin/sh

#
# Clone or pull
#

ZINIT_HOME="${ZINIT_HOME:-$ZPLG_HOME}"
if [ -z "$ZINIT_HOME" ]; then
    ZINIT_HOME="${ZDOTDIR:-$HOME}/.zinit"
fi

ZINIT_BIN_DIR_NAME="${ZINIT_BIN_DIR_NAME:-$ZPLG_BIN_DIR_NAME}"
if [ -z "$ZINIT_BIN_DIR_NAME" ]; then
    ZINIT_BIN_DIR_NAME="bin"
fi

if ! test -d "$ZINIT_HOME"; then
    mkdir "$ZINIT_HOME"
    chmod g-w "$ZINIT_HOME"
    chmod o-w "$ZINIT_HOME"
fi

if ! command -v git >/dev/null 2>&1; then
    echo "[1;31m▓▒░[0m Something went wrong: no [1;32mgit[0m available, cannot proceed."
    exit 1
fi

# Get the download-progress bar tool
if command -v curl >/dev/null 2>&1; then
    mkdir -p /tmp/zinit
    cd /tmp/zinit 
    curl -fsSLO https://raw.githubusercontent.com/zdharma/zinit/master/git-process-output.zsh && \
        chmod a+x /tmp/zinit/git-process-output.zsh
elif command -v wget >/dev/null 2>&1; then
    mkdir -p /tmp/zinit
    cd /tmp/zinit 
    wget -q https://raw.githubusercontent.com/zdharma/zinit/master/git-process-output.zsh && \
        chmod a+x /tmp/zinit/git-process-output.zsh
fi

echo
echo "[1;34m▓▒░[0m Installing [1;33mDHARMA Initiative Plugin Manager[0m at [1;35m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m"
if test -d "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME/.git"; then
    cd "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME"
    git pull origin master
else
    cd "$ZINIT_HOME"
    { git clone --progress https://github.com/zdharma/zinit.git "$ZINIT_BIN_DIR_NAME" \
        2>&1 | { /tmp/zinit/git-process-output.zsh || cat; } } 2>/dev/null
    if [ -d "$ZINIT_BIN_DIR_NAME" ]; then
        echo
        echo "[1;34m▓▒░[0m Zinit succesfully installed at [1;32m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m"
        VERSION="$(command git -C "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME" describe --tags)" 
        echo "[1;34m▓▒░[0m Version: [1;32m$VERSION[0m"
    else
        echo
        echo "[1;31m▓▒░[0m Something went wrong, couldn't install Zinit at [1;33m$ZINIT_HOME/$ZINIT_BIN_DIR_NAME[0m"
    fi
fi

#
# Modify .zshrc
#
THE_ZDOTDIR="${ZDOTDIR:-$HOME}"
if egrep '(zinit|zplugin)\.zsh' "$THE_ZDOTDIR/.zshrc" >/dev/null 2>&1; then
    echo "[34m▓▒░[0m .zshrc already updated, not making changes"
    exit 0
fi

echo "[34m▓▒░[0m Updating $THE_ZDOTDIR/.zshrc (10 lines of code, at the bottom)"
ZINIT_HOME="$(echo $ZINIT_HOME | sed "s|$HOME|\$HOME|")"
command cat <<-EOF >> "$THE_ZDOTDIR/.zshrc"

### Added by Zinit's installer
if [[ ! -f $ZINIT_HOME/$ZINIT_BIN_DIR_NAME/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing DHARMA Initiative Plugin Manager (zdharma/zinit)…%f"
    command mkdir -p "$ZINIT_HOME" && command chmod g-rwX "$ZINIT_HOME"
    command git clone https://github.com/zdharma/zinit "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME" && \\
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \\
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi
source "$ZINIT_HOME/$ZINIT_BIN_DIR_NAME/zinit.zsh"
autoload -Uz _zinit
(( \${+_comps} )) && _comps[zinit]=_zinit
EOF

echo
echo "[38;5;219m▓▒░[0m Would you like to add 3 useful plugins - annexes (Zinit extensions) as well?"
echo -n "[38;5;219m▓▒░[0m Enter y/n and press Return: "

read input
if [ "$input" = y ] || [ "$input" = Y ]; then
    command cat <<-EOF >> "$THE_ZDOTDIR/.zshrc"

zinit light-mode for \\
    zinit-zsh/z-a-patch-dl \\
    zinit-zsh/z-a-as-monitor \\
    zinit-zsh/z-a-bin-gem-node

EOF
    echo
    echo "[34m▓▒░[0m Done."
else
    echo
    echo "[34m▓▒░[0m Done (skipped the annexes chunk)."
fi

command cat <<-EOF >> "$THE_ZDOTDIR/.zshrc"
### End of Zinit's installer chunk
EOF

