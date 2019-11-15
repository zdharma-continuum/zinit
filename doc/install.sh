#!/bin/sh

#
# Clone or pull
#

if [ -z "$ZPLG_HOME" ]; then
    ZPLG_HOME="${ZDOTDIR:-$HOME}/.zplugin"
fi

if [ -z "$ZPLG_BIN_DIR_NAME" ]; then
    ZPLG_BIN_DIR_NAME="bin"
fi

if ! test -d "$ZPLG_HOME"; then
    mkdir "$ZPLG_HOME"
    chmod g-rwX "$ZPLG_HOME"
fi

if ! command -v git >/dev/null 2>&1; then
    echo "[1;31m▓▒░[0m Something went wrong: no [1;32mgit[0m available, cannot proceed"
    exit 1
fi

# Get the download-progress bar tool
if command -v curl >/dev/null 2>&1; then
    mkdir -p /tmp/zplugin
    cd /tmp/zplugin 
    curl -fsSLO https://raw.githubusercontent.com/zdharma/zplugin/master/git-process-output.zsh && \
        chmod +x /tmp/zplugin/git-process-output.zsh
elif command -v wget >/dev/null 2>&1; then
    mkdir -p /tmp/zplugin
    cd /tmp/zplugin 
    wget -q https://raw.githubusercontent.com/zdharma/zplugin/master/git-process-output.zsh && \
        chmod +x /tmp/zplugin/git-process-output.zsh
fi

echo
echo "[1;34m▓▒░[0m Installing zplugin at [1;35m$ZPLG_HOME/$ZPLG_BIN_DIR_NAME[0m"
if test -d "$ZPLG_HOME/$ZPLG_BIN_DIR_NAME/.git"; then
    cd "$ZPLG_HOME/$ZPLG_BIN_DIR_NAME"
    git pull origin master
else
    cd "$ZPLG_HOME"
    { git clone --progress https://github.com/zdharma/zplugin.git "$ZPLG_BIN_DIR_NAME" \
        2>&1 | { /tmp/zplugin/git-process-output.zsh || cat; } } 2>/dev/null
    if [ -d "$ZPLG_BIN_DIR_NAME" ]; then
        echo
        echo "[1;34m▓▒░[0m Zplugin succesfully installed at [1;32m$ZPLG_HOME/$ZPLG_BIN_DIR_NAME[0m"
        VERSION="$(cat "$ZPLG_HOME/$ZPLG_BIN_DIR_NAME/.git/refs/heads/master" | cut -c1-10)"
        echo "[1;34m▓▒░[0m Version: [1;32m$VERSION[0m"
    else
        echo
        echo "[1;31m▓▒░[0m Something went wrong, couldn't install Zplugin at [1;33m$ZPLG_HOME/$ZPLG_BIN_DIR_NAME[0m"
    fi
fi

#
# Modify .zshrc
#
THE_ZDOTDIR="${ZDOTDIR:-$HOME}"
if grep zplugin "$THE_ZDOTDIR/.zshrc" >/dev/null 2>&1; then
    echo "[34m▓▒░[0m .zshrc already updated, not making changes"
    exit 0
fi

echo "[34m▓▒░[0m Updating $THE_ZDOTDIR/.zshrc (3 lines of code, at the bottom)"
ZPLG_HOME="$(echo $ZPLG_HOME | sed "s|$HOME|\$HOME|")"
cat <<-EOF >> "$THE_ZDOTDIR/.zshrc"

### Added by Zplugin's installer
source "$ZPLG_HOME/$ZPLG_BIN_DIR_NAME/zplugin.zsh"
autoload -Uz _zplugin
(( \${+_comps} )) && _comps[zplugin]=_zplugin
### End of Zplugin installer's chunk
EOF
echo "[34m▓▒░[0m Done"
