# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors.

# FUNCTION: :zi::tmp-subst-source [[[
:zi::tmp-subst-source() {
    local -a ___substs ___ab
    ___substs=( "${(@s.;.)ICE[subst]}" )
    if [[ -n ${(M)___substs:#*\\(#e)} ]] {
        local ___prev
        ___substs=( ${___substs[@]//(#b)((*)\\(#e)|(*))/${match[3]:+${___prev:+$___prev\;}}${match[3]}${${___prev::=${match[2]:+${___prev:+$___prev\;}}${match[2]}}:+}} )
    }

    # Load the plugin
    if [[ ! -r $1 ]] {
        +zi::message "{error}source: Couldn't read the script {obj}${1}{error}" \
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
# FUNCTION: zi::service [[[
# Handles given service, i.e. obtains lock, runs it, or waits if no lock
#
# $1 - type "p" or "s" (plugin or snippet)
# $2 - mode - for plugin (light or load)
# $3 - id - URL or plugin ID or alias name (from id-as'')
zi::service() {
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
                                                zi::load "$___id" "" "$___mode" 0;
                                            }
                        [[ $___tpe = s ]] && { ___strd=1
                                                zi::load-snippet "$___id" "" 0;
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
# FUNCTION: zi::wrap-track-functions [[[
zi::wrap-track-functions() {
    local user="$1" plugin="$2" id_as="$3" f
    local -a wt
    wt=( ${(@s.;.)ICE[wrap-track]} )
    for f in ${wt[@]}; do
        functions[${f}-zinit-bkp]="${functions[$f]}"
        eval "
function $f {
    ZINIT[CUR_USR]=\"$user\" ZINIT[CUR_PLUGIN]=\"$plugin\" ZINIT[CUR_USPL2]=\"$id_as\"
    zi::add-report \"\${ZINIT[CUR_USPL2]}\" \"Note: === Starting to track function: $f ===\"
    zi::diff \"\${ZINIT[CUR_USPL2]}\" begin
    zi::tmp-subst-on load
    functions[${f}]=\${functions[${f}-zinit-bkp]}
    ${f} \"\$@\"
    zi::tmp-subst-off load
    zi::diff \"\${ZINIT[CUR_USPL2]}\" end
    zi::add-report \"\${ZINIT[CUR_USPL2]}\" \"Note: === Ended tracking function: $f ===\"
    ZINIT[CUR_USR]= ZINIT[CUR_PLUGIN]= ZINIT[CUR_USPL2]=
}"
    done
} # ]]]

#
# Dtrace
#

# FUNCTION: zi::clear-debug-report [[[
# Forgets dtrace repport gathered up to this moment.
zi::clear-debug-report() {
    zi::clear-report-for _dtrace/_dtrace
} # ]]]
# FUNCTION: zi::debug-start [[[
# Starts Dtrace, i.e. session tracking for changes in Zsh state.
zi::debug-start() {
    if [[ ${ZINIT[DTRACE]} = 1 ]]; then
        +zi::message "{error}Dtrace is already active, stop it first with \`dstop'{rst}"
        return 1
    fi

    ZINIT[DTRACE]=1

    zi::diff _dtrace/_dtrace begin

    # Full shadeing on
    zi::tmp-subst-on dtrace
} # ]]]
# FUNCTION: zi::debug-stop [[[
# Stops Dtrace (i.e., session tracking for changes in Zsh state).
zi::debug-stop() {
    ZINIT[DTRACE]=0

    # Shadowing fully off
    zi::tmp-subst-off dtrace

    # Gather end data now, for diffing later
    zi::diff _dtrace/_dtrace end
} # ]]]
# FUNCTION: zi::debug-unload [[[
# Reverts changes detected by dtrace run.
zi::debug-unload() {
    (( ${+functions[zi::unload]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh" || return 1
    if [[ ${ZINIT[DTRACE]} = 1 ]]; then
        +zi::message "{error}Dtrace is still active, stop it first with \`dstop'{rst}"
    else
        zi::unload _dtrace _dtrace
    fi
} # ]]]

# vim: set fenc=utf8 ffs=unix foldmarker=[[[,]]] foldmethod=marker ft=zsh list noet sw=2 ts=2 tw=72:
