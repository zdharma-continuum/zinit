#!/usr/bin/env zsh

local emul="zsh";
[[ -f ./emulate ]] && emul="$(<./emulate)"
emul="${5:-$emul}"
emulate -LR "$emul" -o warncreateglobal -o typesetsilent -o extendedglob

# Will generate new answer
[[ -d $PWD/$1/answer ]] && rm -rf $PWD/$1/answer
[[ -f $PWD/$1/state ]] && rm -f $PWD/$1/state

# Discard per-setup (e.g. per-version) PATH and FPATH entries
builtin autoload +X is-at-least
builtin autoload +X allopt
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin
FPATH=/usr/share/zsh/site-functions:/usr/local/share/zsh/functions:/usr/local/share/zsh/site-functions

# Setup paths and load Zplugin
local REPLY p
local -a reply
local -A ZPLGM
ZPLGM[BIN_DIR]=$PWD
command mkdir -p $PWD/$1/answer
ZPLGM[HOME_DIR]=$PWD/$1/answer
builtin source "${ZPLGM[BIN_DIR]}/zplugin.zsh"

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
    (( ${+functions[-zplg-diff-env-compute]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-autoload.zsh"

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

    print -rl -- "${(kv@)ZPLGM}" "---" >! answer/state

    print -r -- "ERRORS" >! answer/errors

    # Normalize PATH and FPATH
    path=( "${path/${PWD:h}\//}" )
    path=( "${path/${${PWD:h}:h}\//}" )
    fpath=( "${fpath/${PWD:h}\//}" )
    fpath=( "${fpath/${${PWD:h}:h}\//}" )
    ZPLG_PATH_BEFORE=( "${(kv@)ZPLG_PATH_BEFORE/${PWD:h}\//}" )
    ZPLG_PATH_BEFORE=( "${(kv@)ZPLG_PATH_BEFORE/${${PWD:h}:h}\//}" )
    ZPLG_PATH_AFTER=( "${(kv@)ZPLG_PATH_AFTER/${PWD:h}\//}" )
    ZPLG_PATH_AFTER=( "${(kv@)ZPLG_PATH_AFTER/${${PWD:h}:h}\//}" )
    ZPLG_FPATH_BEFORE=( "${(kv@)ZPLG_FPATH_BEFORE/${PWD:h}\//}" )
    ZPLG_FPATH_BEFORE=( "${(kv@)ZPLG_FPATH_BEFORE/${${PWD:h}:h}\//}" )
    ZPLG_FPATH_AFTER=( "${(kv@)ZPLG_FPATH_AFTER/${PWD:h}\//}" )
    ZPLG_FPATH_AFTER=( "${(kv@)ZPLG_FPATH_AFTER/${${PWD:h}:h}\//}" )

    for k in "${ZPLG_REGISTERED_PLUGINS[@]}"; do
        -zplg-diff-functions-compute "$k" || print -r -- "Failed: -zplg-diff-functions-compute for $k" >>! answer/errors
        -zplg-diff-options-compute "$k"   || print -r -- "Failed: -zplg-diff-options-compute for $k" >>! answer/errors
        -zplg-diff-env-compute "$k"       || print -r -- "Failed: -zplg-diff-env-compute $k" >>! answer/errors
        -zplg-diff-parameter-compute "$k" || print -r -- "Failed: -zplg-diff-parameter-compute $k" >>! answer/errors
    done

    keys=( ZPLG_REGISTERED_PLUGINS ZPLG_REGISTERED_STATES ZPLG_SNIPPETS
           ZPLG_SICE ZPLG_FUNCTIONS ZPLG_OPTIONS ZPLG_PATH ZPLG_FPATH
           ZPLG_PARAMETERS_PRE ZPLG_PARAMETERS_POST ZPLG_ZSTYLES ZPLG_BINDKEYS
           ZPLG_ALIASES ZPLG_WIDGETS_SAVED ZPLG_WIDGETS_DELETE ZPLG_COMPDEF_REPLAY
           ZPLG_CUR_PLUGIN
    )
    for k in "${keys[@]}"; do
        print -r -- "$k: ${(qq@)${(Pkv@)k}}" >>! answer/state
    done

    print -rl -- "---" "Parameter module: ${+modules[zsh/parameter]}" >>! answer/state
}
# }}}

builtin cd "$1"
[[ -n "$2" ]] && typeset -g VERBOSE=1     # $(VERBOSE)
[[ -n "$3" ]] && typeset -g DBG=1         # $(DEBUG)
[[ -n "$4" ]] && { allopt > allopt.txt; } # $(OPTDUMP)

local -a plugins
[[ -f "plugins" ]] && plugins=( "${(@f)"$(<./plugins)"}" )
for p in "${plugins[@]}"; do
    [[ ! -e ../test_plugins/$p/.git ]] && command ln -svf .test_git ../test_plugins/$p/.git
done

command rm -f skip
builtin source ./script

store_state

return 0
