#!/usr/bin/env zsh

emulate -LR zsh -o warncreateglobal -o typesetsilent -o extendedglob

# Will generate new answer
[[ -d $PWD/$1/answer ]] && rm -rf $PWD/$1/answer

# Setup paths and load Zplugin
local REPLY
local -a reply
local -A ZPLGM
ZPLGM[BIN_DIR]=$PWD
command mkdir -p $PWD/$1/answer
ZPLGM[HOME_DIR]=$PWD/$1/answer
source ${ZPLGM[BIN_DIR]}/zplugin.zsh

# FUNCTION: internet_mock_git {{{
internet_mock_git() {
    setopt localoptions extendedglob warncreateglobal typesetsilent
    local -A opts
    local -a args
    args=( "$@" )

    builtin zparseopts -E -D -A opts -recursive -depth: || { echo "Incorrect options given to git mock function"; return 1; }
    
    local -A urlmap
    urlmap=( "${(f@)"$(<urlmap)"}" )
    urlmap=( "${(kv@)urlmap//\%PWD/$PWD}" )
    local URL="${2//(http|https|ftp|ftps|scp):\/\//file://}"
    URL="${urlmap[$URL]}"
    local local_dir="$3"

    if [[ "$1" = "clone" ]]; then
        command git clone -q ${opts[--recursive]+--recursive} ${=opts[--depth]+--depth ${opts[--depth]}} "$URL" "$local_dir"
    else
        builtin print "Incorrect command ($1) given to the git mock, the mock exits with error"
        builtin return 1
    fi

    builtin return 0
}
# }}}

builtin cd "$1"
[[ -n "$3" ]] && typeset -g DBG=1                          # $(DEBUG)
[[ -n "$4" ]] && { autoload allopt; allopt > allopt.txt; } # $(OPTDUMP)

command rm -f skip
builtin source ./script

if [[ -n "$2" ]]; then
    : VERBOSE flag
fi

return 0
