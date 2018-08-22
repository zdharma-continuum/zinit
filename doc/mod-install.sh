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

ZPLG_HOME="${ZDOTDIR:-$HOME}/.zplugin"

if ! test -d "$ZPLG_HOME"; then
    mkdir "$ZPLG_HOME"
    chmod g-rwX "$ZPLG_HOME"
fi

echo ">>> Downloading zdharma/zplugin module to $ZPLG_HOME/mod-bin"
if test -d "$ZPLG_HOME/mod-bin/.git"; then
    cd "$ZPLG_HOME/mod-bin"
    git pull origin master
else
    cd "$ZPLG_HOME"
    git clone --depth 10 https://github.com/zdharma/zplugin.git mod-bin
fi
echo ">>> Done"

#
# Build the module
#

cd "$ZPLG_HOME/mod-bin/zmodules"
echo "$col_pname== Building module zdharma/zplugin, running: a make clean, then ./configure and then make ==$col_rst"
echo "$col_pname== The module sources are located at: $ZPLG_HOME/mod-bin/zmodules ==$col_rst"
test -f Makefile && { [ "$1" = "--clean" ] && {
      echo "$col_info2-- make distclean --$col_rst"
      make distclean
      true
  } || {
      echo "$col_info2-- make clean (pass --clean to invoke \`make distclean') --$col_rst"
      make clean
  }
}
echo "$col_info2-- ./configure --$col_rst"
CPPFLAGS=-I/usr/local/include CFLAGS="-g -Wall -O3" LDFLAGS=-L/usr/local/lib ./configure --disable-gdbm && {
  echo "$col_info2-- make --$col_rst"
  make && {
    echo "${col_info}Module has been built correctly.$col_rst"
    echo "To load the module, add following 2 lines to .zshrc, at top:"
    echo "    module_path+=( \"$ZPLG_HOME/mod-bin/zmodules/Src\" )"
    echo "    zmodload zdharma/zplugin"
    echo ""
    echo "After loading, use command \`zpmod' to communicate with the module."
    echo "See \`zpmod -h' for more information. There are two main features,"
    echo "invocation of \`zpmod source-study' which shows \`source' profile"
    echo "data, and guaranteed, automatic compilation of any sourced script"
    echo "while the module is loaded (check with Zsh command \`zmodload')."
  } || {
      echo "${col_error}Module didn't build.$col_rst. You can copy the error messages and submit"
      echo "error-report at: https://github.com/zdharma/zplugin/issues"
  }
}
