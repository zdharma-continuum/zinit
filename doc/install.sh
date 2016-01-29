#!/bin/sh

#
# Clone or pull
#

if ! test -d "$HOME/.zplugin"; then
    mkdir "$HOME/.zplugin"
fi

echo ">>> Downloading zplugin to ~/.zplugin/bin"
if test -d ~/.zplugin/bin/.git; then
    cd ~/.zplugin/bin
    git pull origin master
else
    cd ~/.zplugin
    git clone https://github.com/psprint/zplugin.git bin
fi
echo ">>> Done"

#
# Modify .zshrc
#

echo ">>> Updating .zshrc (with one line)"
if ! grep zplugin ~/.zshrc >/dev/null 2>&1; then
    echo >> ~/.zshrc
    echo "### Added by Zplugin installer" >> ~/.zshrc
    echo "source $HOME/.zplugin/bin/zplugin.zsh" >> ~/.zshrc
    echo ">>> Done"
else
    echo ">>> .zshrc already updated, not making changes"
fi
