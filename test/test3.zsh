#!/bin/zsh

#
# Common test suite code
#

source "`pwd`/${0:h}/tinclude.zsh" "$0" || exit 1

#
# Start Dtrace
#

---start
zplugin dtrace

###
### Test body
###

typeset -U path
PATH="$PATH:/component/nr1"
path+="/component/nr2"
# Intentional nr2
PATH="/component/nr2:$PATH"
declare -p path

echo

FPATH="$FPATH:/fcomp/nr1"
fpath+="/fcomp/nr2"
# Intentional nr2
FPATH="/fcomp/nr2:$FPATH"
declare -p fpath

echo

MY_VAR="test variable1"
MY_VAR2="test variable2"

my_f() { echo "Hello from test3"; MY_VAR3="test variable 3"; typeset -A my_hash }
my_f

typeset -A my_hash2

typeset -a my_array
my_array=( 1 )

setopt menucomplete

alias test3alias1="echo Hello"
alias -g test3alias2="echo Hello"
alias -s jpg="iv"

my_f2() { echo "Short lived"; }
my_f2
unfunction "my_f2"

#
# Stop Dtrace
#

zplugin dstop
---stop

###
### Gather and compare results
###

zplugin dreport > "$___TEST_REPORT_FILE"
zplugin dunload > "$___TEST_UNLOAD_FILE"

# A look at hopefully cleaned up variables
declare -p path
declare -p fpath
---mark

---compare
