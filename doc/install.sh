#!/bin/sh

#
# Clone or pull
#

if [ -z "$ZPLG_HOME" ]; then
    ZPLG_HOME="${ZDOTDIR:-$HOME}/.zplugin"
fi

if ! test -d "$ZPLG_HOME"; then
    mkdir "$ZPLG_HOME"
    chmod g-rwX "$ZPLG_HOME"
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
echo "[1;34m❯❯❯[0m Installing zplugin at [1;35m$ZPLG_HOME/bin[0m"
if test -d "$ZPLG_HOME/bin/.git"; then
    cd "$ZPLG_HOME/bin"
    git pull origin master
else
    cd "$ZPLG_HOME"
    { git clone --progress https://github.com/zdharma/zplugin.git bin \
        2>&1 | { /tmp/zplugin/git-process-output.zsh || cat; } } 2>/dev/null
    if [ -d bin ]; then
        echo
        echo "[1;34m❯❯❯[0m Zplugin succesfully installed at [1;32m$ZPLG_HOME/bin[0m"
    else
        echo
        echo "[1;31m❯❯❯[0m Something went wrong, couldn't install Zplugin at [1;33m$ZPLG_HOME/bin[0m"
    fi
fi

#
# Modify .zshrc
#
THE_ZDOTDIR="${ZDOTDIR:-$HOME}"
if grep zplugin "$THE_ZDOTDIR/.zshrc" >/dev/null 2>&1; then
    echo "[34m❯❯❯[0m .zshrc already updated, not making changes"
    exit 0
fi

echo "[34m❯❯❯[0m Updating $THE_ZDOTDIR/.zshrc (3 lines of code, at the bottom)"
cat <<-EOF >> "$THE_ZDOTDIR/.zshrc"

### Added by Zplugin's installer
source '$ZPLG_HOME/bin/zplugin.zsh'
autoload -Uz _zplugin
(( \${+_comps} )) && _comps[zplugin]=_zplugin
### End of Zplugin installer's chunk
EOF
echo ">>> Done"
