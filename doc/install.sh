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

echo ">>> Downloading zplugin to $ZPLG_HOME/bin"
if test -d "$ZPLG_HOME/bin/.git"; then
    cd "$ZPLG_HOME/bin"
    git pull origin master
else
    cd "$ZPLG_HOME"
    git clone --depth 10 https://github.com/zdharma/zplugin.git bin
fi
echo ">>> Done"

#
# Modify .zshrc
#
THE_ZDOTDIR="${ZDOTDIR:-$HOME}"
if grep zplugin "$THE_ZDOTDIR/.zshrc" >/dev/null 2>&1; then
    echo ">>> .zshrc already updated, not making changes"
    exit 0
fi

echo ">>> Updating $THE_ZDOTDIR/.zshrc (3 lines of code, at the bottom)"
cat <<-EOF >> "$THE_ZDOTDIR/.zshrc"

### Added by Zplugin's installer
source '$ZPLG_HOME/bin/zplugin.zsh'
autoload -Uz _zplugin
(( \${+_comps} )) && _comps[zplugin]=_zplugin
### End of Zplugin's installer chunk
EOF
echo ">>> Done"
