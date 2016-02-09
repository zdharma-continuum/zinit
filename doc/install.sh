#!/bin/sh

#
# Clone or pull
#

ZPLG_HOME="${ZDOTDIR:-$HOME}/.zplugin"

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
    git clone https://github.com/psprint/zplugin.git bin
fi
echo ">>> Done"

#
# Modify .zshrc
#

echo ">>> Updating .zshrc (3 lines of code, at the bottom)"
if ! grep zplugin "$ZPLG_HOME/../.zshrc" >/dev/null 2>&1; then
    echo >> "$ZPLG_HOME/../.zshrc"
    echo "### Added by Zplugin's installer"             >> "$ZPLG_HOME/../.zshrc"
    echo "source '$ZPLG_HOME/bin/zplugin.zsh'"          >> "$ZPLG_HOME/../.zshrc"
    echo "autoload -Uz _zplugin"                        >> "$ZPLG_HOME/../.zshrc"
    echo "(( ${+_comps} )) && _comps[zplugin]=_zplugin" >> "$ZPLG_HOME/../.zshrc"
    echo "### End of Zplugin's installer chunk"         >> "$ZPLG_HOME/../.zshrc"
    echo ">>> Done"
else
    echo ">>> .zshrc already updated, not making changes"
fi
