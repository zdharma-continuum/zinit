#!/usr/bin/env zsh

local emul="zsh";
[[ -f ./emulate ]] && emul="$(<./emulate)"
emul="${5:-$emul}"
emulate -LR "$emul" -o warncreateglobal -o typesetsilent -o extendedglob

# Will generate new answer
[[ -d $PWD/$1/answer ]] && rm -rf $PWD/$1/answer
[[ -f $PWD/$1/state ]] && rm -f $PWD/$1/state

# Setup paths and load Zplugin
local REPLY p
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
# FUNCTION: verbosity {{{
tst_verbosity() {
    # 3 can be used for output
    exec 3<&1

    if (( VERBOSE )); then
        : # no redirection
    elif (( DBG )); then
        exec 1>/dev/null
    else
        exec 1>/dev/null
        exec 2>&1
    fi
}
# }}}
# FUNCTION: store_state {{{
store_state() {
    local -A mymap
    mymap=( "${(kv@)ZPLGM}" )
    local -a keys
    local k
    keys=( ${mymap[(I)*(col-)*]} NEW_AUTOLOAD )

    for k in "${keys[@]}"; do
        unset "ZPLGM[$k]"
    done

    keys=( ${(k)mymap[(R)[[:digit:]]##.[[:digit:]]#]} )
    for k in "${keys[@]}"; do
        ZPLGM[$k]="__reset-by-test__"
    done

    ZPLGM=( "${(kv)ZPLGM[@]/${PWD:h}\//}" )
    ZPLGM=( "${(kv)ZPLGM[@]/${${PWD:h}:h}\//}" )

    print -rl -- "${(kv@)ZPLGM}" >! answer/state
}
# }}}

builtin cd "$1"
[[ -n "$2" ]] && typeset -g VERBOSE=1
[[ -n "$3" ]] && typeset -g DBG=1                          # $(DEBUG)
[[ -n "$4" ]] && { autoload allopt; allopt > allopt.txt; } # $(OPTDUMP)

local -a plugins
[[ -f "plugins" ]] && plugins=( "${(@f)"$(<./plugins)"}" )
for p in "${plugins[@]}"; do
    [[ ! -e ../test_plugins/$p/.git ]] && command ln -svf .test_git ../test_plugins/$p/.git
done

command rm -f skip
builtin source ./script

store_state

return 0
