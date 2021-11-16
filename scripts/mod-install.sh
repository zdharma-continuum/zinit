#!/bin/sh

col_pname="[33m"
col_error="[31m"
col_info="[32m"
col_info2="[32m"
col_rst="[0m"

echo "${col_info}Re-run this script to update (from Github) and rebuild the module.$col_rst"

#
# Clone or pull
#

ZINIT_HOME="${ZDOTDIR:-$HOME}/.zinit"

if ! test -d "$ZINIT_HOME"; then
  mkdir "$ZINIT_HOME"
  chmod g-rwX "$ZINIT_HOME"
fi

echo ">>> Downloading zdharma-continuum/zinit module to $ZINIT_HOME/mod-bin"
if test -d "$ZINIT_HOME/mod-bin/.git"; then
  cd "$ZINIT_HOME/mod-bin"  || exit 9
  git pull origin master
else
  cd "$ZINIT_HOME" || exit 9
  git clone --depth 10 https://github.com/zdharma-continuum/zinit.git mod-bin
fi
echo ">>> Done"

#
# Build the module
#

cd "$ZINIT_HOME/mod-bin/zmodules" || exit 9
echo "$col_pname== Building module zdharma-continuum/zinit, running: a make clean, then ./configure and then make ==$col_rst"
echo "$col_pname== The module sources are located at: $ZINIT_HOME/mod-bin/zmodules ==$col_rst"
if test -f Makefile; then
  if [ "$1" = "--clean" ]; then
    echo "$col_info2-- make distclean --$col_rst"
    make distclean
    true
  else
    echo "$col_info2-- make clean (pass --clean to invoke \`make distclean') --$col_rst"
    make clean
  fi
fi

echo "$col_info2-- ./configure --$col_rst"
if CPPFLAGS=-I/usr/local/include CFLAGS="-g -Wall -O3" LDFLAGS=-L/usr/local/lib \
    ./configure --disable-gdbm --without-tcsetpgrp; then
  echo "$col_info2-- make --$col_rst"
  if make; then
    echo "${col_info}Module has been built correctly.$col_rst"
    echo "To load the module, add following 2 lines to .zshrc, at top:"
    echo "  module_path+=( \"$ZINIT_HOME/mod-bin/zmodules/Src\" )"
    echo "  zmodload zdharma-continuum/zinit"
    echo ""
    echo "After loading, use command \`zpmod' to communicate with the module."
    echo "See \`zpmod -h' for more information. There are two main features,"
    echo "invocation of \`zpmod source-study' which shows \`source' profile"
    echo "data, and guaranteed, automatic compilation of any sourced script"
    echo "while the module is loaded (check with Zsh command \`zmodload')."
  else
    echo "${col_error}Module didn't build.$col_rst. You can copy the error messages and submit"
    echo "error-report at: https://github.com/zdharma-continuum/zinit/issues"
  fi
fi

# vim: set ft=sh et ts=2 sw=2 :
