# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors.

# FUNCTION: :zinit-tmp-subst-source [[[
:zinit-tmp-subst-source() {
    local -a ___substs ___ab
    ___substs=( "${(@s.;.)ICE[subst]}" )
    if [[ -n ${(M)___substs:#*\\(#e)} ]] {
        local ___prev
        ___substs=( ${___substs[@]//(#b)((*)\\(#e)|(*))/${match[3]:+${___prev:+$___prev\;}}${match[3]}${${___prev::=${match[2]:+${___prev:+$___prev\;}}${match[2]}}:+}} )
    }

    # Load the plugin
    if [[ ! -r $1 ]] {
        +zi-log "{error}source: Couldn't read the script {obj}${1}{error}" \
            ", cannot substitute {data}${ICE[subst]}{error}.{rst}"
    }

    local ___data="$(<$1)"

    () {
        builtin emulate -LR zsh -o extendedglob -o interactivecomments ${=${options[xtrace]:#off}:+-o xtrace}
        local ___subst ___tabspc=$'\t'
        for ___subst ( "${___substs[@]}" ) {
            ___ab=( "${(@)${(@)${(@s:->:)___subst}##[[:space:]]##}%%[[:space:]]##}" )
            ___ab[2]=${___ab[2]//(#b)\\([[:digit:]])/\${match[${match[1]}]}}
            builtin eval "___data=\"\${___data//(#b)\${~___ab[1]}/${___ab[2]}}\""
        }
        ___data="() { ${(F)${(@)${(f)___data[@]}:#[$___tabspc]#\#*}} ; } \"\${@[2,-1]}\""
    }

    builtin eval "$___data"
} # ]]]
# FUNCTION: .zinit-service [[[
# Handles given service, i.e. obtains lock, runs it, or waits if no lock
#
# $1 - type "p" or "s" (plugin or snippet)
# $2 - mode - for plugin (light or load)
# $3 - id - URL or plugin ID or alias name (from id-as'')
.zinit-service() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent noshortloops

    local ___tpe="$1" ___mode="$2" ___id="$3" ___fle="${ZINIT[SERVICES_DIR]}/${ICE[service]}.lock" ___fd ___cmd ___tmp ___lckd ___strd=0
    { builtin print -n >! "$___fle"; } 2>/dev/null 1>&2
    [[ ! -e ${___fle:r}.fifo ]] && command mkfifo "${___fle:r}.fifo" 2>/dev/null 1>&2
    [[ ! -e ${___fle:r}.fifo2 ]] && command mkfifo "${___fle:r}.fifo2" 2>/dev/null 1>&2

    typeset -gx ZSRV_WORK_DIR="${ZINIT[SERVICES_DIR]}" ZSRV_ID="${ICE[service]}"  # should be also set by other p-m

    while (( 1 )); do
        (
            while (( 1 )); do
                [[ ! -f ${___fle:r}.stop ]] && if (( ___lckd )) || zsystem 2>/dev/null 1>&2 flock -t 1 -f ___fd -e $___fle; then
                    ___lckd=1
                    if (( ! ___strd )) || [[ $___cmd = RESTART ]]; then
                        [[ $___tpe = p ]] && { ___strd=1
                                                .zinit-load "$___id" "" "$___mode" 0;
                                            }
                        [[ $___tpe = s ]] && { ___strd=1
                                                .zinit-load-snippet "$___id" "" 0;
                                            }
                    fi
                    ___cmd=
                    while (( 1 )); do builtin read -t 32767 ___cmd <>"${___fle:r}.fifo" && break; done
                else
                    return 0
                fi

                [[ $___cmd = (#i)NEXT ]] && { kill -TERM "$ZSRV_PID"; builtin read -t 2 ___tmp <>"${___fle:r}.fifo2"; kill -HUP "$ZSRV_PID"; exec {___fd}>&-; ___lckd=0; ___strd=0; builtin read -t 10 ___tmp <>"${___fle:r}.fifo2"; }
                [[ $___cmd = (#i)STOP ]] && { kill -TERM "$ZSRV_PID"; builtin read -t 2 ___tmp <>"${___fle:r}.fifo2"; kill -HUP "$ZSRV_PID"; ___strd=0; builtin print >! "${___fle:r}.stop"; }
                [[ $___cmd = (#i)QUIT ]] && { kill -HUP ${sysparams[pid]}; return 1; }
                [[ $___cmd != (#i)RESTART ]] && { ___cmd=; builtin read -t 1 ___tmp <>"${___fle:r}.fifo2"; }
            done
        ) || break
        builtin read -t 1 ___tmp <>"${___fle:r}.fifo2"
    done >>! "$ZSRV_WORK_DIR/$ZSRV_ID".log 2>&1
} # ]]]
# FUNCTION: .zinit-wrap-track-functions [[[
.zinit-wrap-track-functions() {
    local user="$1" plugin="$2" id_as="$3" f
    local -a wt
    wt=( ${(@s.;.)ICE[wrap-track]} )
    for f in ${wt[@]}; do
        functions[${f}-zinit-bkp]="${functions[$f]}"
        eval "
function $f {
    ZINIT[CUR_USR]=\"$user\" ZINIT[CUR_PLUGIN]=\"$plugin\" ZINIT[CUR_USPL2]=\"$id_as\"
    .zinit-add-report \"\${ZINIT[CUR_USPL2]}\" \"Note: === Starting to track function: $f ===\"
    .zinit-diff \"\${ZINIT[CUR_USPL2]}\" begin
    .zinit-tmp-subst-on load
    functions[${f}]=\${functions[${f}-zinit-bkp]}
    ${f} \"\$@\"
    .zinit-tmp-subst-off load
    .zinit-diff \"\${ZINIT[CUR_USPL2]}\" end
    .zinit-add-report \"\${ZINIT[CUR_USPL2]}\" \"Note: === Ended tracking function: $f ===\"
    ZINIT[CUR_USR]= ZINIT[CUR_PLUGIN]= ZINIT[CUR_USPL2]=
}"
    done
} # ]]]

#
# debug command
#

# FUNCTION: .zinit-debug-clear [[[
# Clear latest debug report
.zinit-debug-clear() {
    {
        .zinit-clear-report-for _dtrace/_dtrace
        +zi-log '{m} Cleared debug report'
    } || {
        +zi-log '{e} Failed to clear debug report'
        return 1
    }
} # ]]]
# FUNCTION: .zinit-debug-report [[[
# Displays debug report (data recorded in interactive session).
.zinit-debug-report() {
    if [[ ${ZINIT[DTRACE]} = 1 ]]; then
        +zi-log "{e} Debug mode active, stop it first via {cmd}zinit debug stop{rst}"
    else
        (( ${+functions[.zinit-unload]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh" || return 1
        .zinit-show-report "_dtrace/_dtrace"
    fi
} # ]]]
# FUNCTION: .zinit-debug-revert [[[
# Revert changes made during debug mode
.zinit-debug-revert() {
    if [[ ${ZINIT[DTRACE]} = 1 ]]; then
        +zi-log "{e} Debug mode is active. To stop, run {cmd}zinit debug stop{rst}"
    else
        (( ${+functions[.zinit-unload]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh" || return 1
        .zinit-unload _dtrace _dtrace
        +zi-log "{m} Reverted changes detected during debug mode"
    fi
} # ]]]
# FUNCTION: .zinit-debug-start [[[
# Start debug mode
.zinit-debug-start() {
    if [[ $ZINIT[DTRACE] = 1 ]]; then
        +zi-log "{e} Debug mode currently active"
        return 1
    fi
    (){
        ZINIT[DTRACE]=1
        .zinit-diff _dtrace/_dtrace begin
        .zinit-tmp-subst-on dtrace
    }
    if (( $? == 0 )); then
        +zi-log "{i} Started debug mode"
        return 0
    fi
} # ]]]
# FUNCTION: .zinit-debug-status [[[
# Revert changes made during debug mode
.zinit-debug-status() {
    +zi-log -n '{m} Debug mode: '
    (( ZINIT[DTRACE] )) && +zi-log 'running' || +zi-log 'stopped'
} # ]]]
# FUNCTION: .zinit-debug-stop [[[
# Stop debug mode
.zinit-debug-stop() {
    if [[ $ZINIT[DTRACE] = 0 ]]; then
        +zi-log '{e} Debug mode not active'
        return 0
    else
        ZINIT[DTRACE]=0
        (){
            .zinit-tmp-subst-off dtrace     # turn of shadowing
            .zinit-diff _dtrace/_dtrace end # get end data to diff later
        }
        if (( $? == 0 )); then
            +zi-log '{i} Stopped debug mode'
            return 0
        fi
    fi
} # ]]]
# FUNCTION: +zinit-debug [[[
# Debug command entry point
+zinit-debug(){
    emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob noksharrays nokshglob nullglob typesetsilent warncreateglobal
    local o_help cmd
    local -a usage=(
      'Usage:'
      '  zinit debug [options] [command]'
      ' '
      'Options:'
      '  -h, --help     Show list of command-line options'
      ' '
      'Commands:'
      '  clear     Clear debug report'
      '  report    Show debug report'
      '  revert    Revert changes made during debug mode'
      '  start     Start debug mode'
      '  status    Current debug status'
      '  stop      Stop debug mode'
    )
    zmodload zsh/zutil
    zparseopts -D -F -K -- \
        {h,-help}=o_help \
    || return 1

    (( $#o_help )) && {
        print -l -- $usage
        return 0
    }

    cmd="$1"
    if (( ! $+functions[.zinit-debug-${cmd}] )); then
        print -l -- $usage
        return 1
    else
        .zinit-debug-${cmd} "${(@)@:2}"
    fi
} # ]]]

# vim: ft=zsh sw=4 ts=4 et foldmarker=[[[,]]] foldmethod=marker
