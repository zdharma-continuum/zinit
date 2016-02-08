#!/usr/bin/env zsh

#
# Do some setup
# Script can be run from arbitrary directory under zplugin/ tree
#

emulate sh

# Make it even harder
unsetopt nobadpattern
#unsetopt nobanghist
#unsetopt nobareglobqual
#unsetopt nobgnice
#unsetopt bsdecho
#unsetopt nocheckjobs
#unsetopt cprecedences
#unsetopt noequals
#unsetopt noevallineno
#unsetopt extendedglob
#unsetopt nofunctionargzero
#unsetopt noglobalexport
#unsetopt noglobalexport
#unsetopt globsubst
#unsetopt nohup
#unsetopt interactivecomments
#unsetopt ksharrays
#unsetopt kshautoload
#unsetopt nomultibyte
#unsetopt nomultifuncdef
#unsetopt nomultios
#unsetopt nonomatch
#unsetopt nonotify
#unsetopt octalzeroes
#unsetopt pathscript
#unsetopt posixaliases
#unsetopt posixbuiltins
#unsetopt posixcd
#unsetopt posixidentifiers
#unsetopt posixjobs
#unsetopt posixstrings
#unsetopt posixtraps
#unsetopt nopromptpercent
#unsetopt promptsubst
#unsetopt rmstarsilent
#unsetopt shfileexpansion
#unsetopt shglob
#unsetopt shnullcmd
#unsetopt shoptionletters
#unsetopt noshortloops
#unsetopt shwordsplit
#unsetopt typesetsilent

source "`pwd`/${0:h}/tinclude.zsh" "$0" || exit 1

#
# Start Dtrace
#

---start
zplugin dtrace

###
### Test body
###

MY_VAR="test variable"
MY_VAR2="test variable"
zplugin snippet -f test/a::test::plugin.zsh
my_f() { echo "Hello"; }
fpath+=( /a/b/c )

#
# Stop Dtrace
#

zplugin dstop
---stop

###
### Gather and compare results
###

zplugin dreport > "$___TEST_REPORT_FILE" 2>&1
zplugin dunload > "$___TEST_UNLOAD_FILE" 2>&1
---dumpenv > "$___TEST_ENV_FILE" 2>&1

---compare
---end

