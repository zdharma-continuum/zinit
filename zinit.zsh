# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors

#
# Main state variables
#

typeset -gaH ZINIT_REGISTERED_PLUGINS ZINIT_TASKS ZINIT_RUN
typeset -ga zsh_loaded_plugins
ZINIT_TASKS=( "<no-data>" )
# Snippets loaded, url -> file name
typeset -gAH ZINIT ZINIT_REGISTERED_STATES ZINIT_SNIPPETS ZINIT_REPORTS ZINIT_ICES ZINIT_SICE ZINIT_CUR_BIND_MAP ZINIT_EXTS
typeset -gaH ZINIT_COMPDEF_REPLAY

# Compatibility with pre-rename project (Zplugin)
typeset -gAH ZPLGM
ZINIT=( "${(kv)ZPLGM[@]}" "${(kv)ZINIT[@]}" )
unset ZPLGM

#
# Common needed values
#

[[ ! -e ${ZINIT[BIN_DIR]}/zinit.zsh ]] && ZINIT[BIN_DIR]=

ZINIT[ZERO]="$0"
[[ ! -o functionargzero || -o posixargzero || ${ZINIT[ZERO]} != */* ]] && ZINIT[ZERO]="${(%):-%N}"

: ${ZINIT[BIN_DIR]:="${ZINIT[ZERO]:h}"}
[[ ${ZINIT[BIN_DIR]} = \~* ]] && ZINIT[BIN_DIR]=${~ZINIT[BIN_DIR]}

# Make ZINIT[BIN_DIR] path absolute
ZINIT[BIN_DIR]="${${(M)ZINIT[BIN_DIR]:#/*}:-$PWD/${ZINIT[BIN_DIR]}}"

# Final test of ZINIT[BIN_DIR]
if [[ ! -e ${ZINIT[BIN_DIR]}/zinit.zsh ]]; then
    print -P "%F{196}Could not establish ZINIT[BIN_DIR] hash field. It should point where Zinit's Git repository is.%f"
    return 1
fi

# User can override ZINIT[HOME_DIR]
if [[ -z ${ZINIT[HOME_DIR]} ]]; then
    # Ignore ZDOTDIR if user manually put Zinit to $HOME
    if [[ -d $HOME/.zinit ]]; then
        ZINIT[HOME_DIR]="$HOME/.zinit"
    elif [[ -d $HOME/.zplugin ]]; then
        ZINIT[HOME_DIR]="$HOME/.zplugin"
    elif [[ -d ${ZDOTDIR:-$HOME}/.zplugin ]]; then
        ZINIT[HOME_DIR]="${ZDOTDIR:-$HOME}/.zplugin"
    else
        ZINIT[HOME_DIR]="${ZDOTDIR:-$HOME}/.zinit"
    fi
fi

ZINIT[ice-list]="svn|proto|from|teleid|bindmap|cloneopts|id-as|depth|if|wait|load|\
unload|blockf|pick|bpick|src|as|ver|silent|lucid|notify|mv|cp|\
atinit|atclone|atload|atpull|nocd|run-atpull|has|cloneonly|make|\
service|trackbinds|multisrc|compile|nocompile|nocompletions|\
reset-prompt|wrap-track|reset|sh|\!sh|bash|\!bash|ksh|\!ksh|csh|\
\!csh|aliases|countdown|ps-on-unload|ps-on-update|trigger-load|\
light-mode|is-snippet|atdelete|pack|git|verbose|on-update-of|\
subscribe|extract|param"
ZINIT[nval-ice-list]="blockf|silent|lucid|trackbinds|cloneonly|nocd|run-atpull|\
nocompletions|sh|\!sh|bash|\!bash|ksh|\!ksh|csh|\!csh|\
aliases|countdown|light-mode|is-snippet|git|verbose"

# Can be customized
: ${ZINIT[PLUGINS_DIR]:=${ZINIT[HOME_DIR]}/plugins}
: ${ZINIT[COMPLETIONS_DIR]:=${ZINIT[HOME_DIR]}/completions}
: ${ZINIT[SNIPPETS_DIR]:=${ZINIT[HOME_DIR]}/snippets}
: ${ZINIT[SERVICES_DIR]:=${ZINIT[HOME_DIR]}/services}
typeset -g ZPFX
: ${ZPFX:=${ZINIT[HOME_DIR]}/polaris}
: ${ZINIT[ALIASES_OPT]::=${${options[aliases]:#off}:+1}}

ZINIT[PLUGINS_DIR]=${~ZINIT[PLUGINS_DIR]}   ZINIT[COMPLETIONS_DIR]=${~ZINIT[COMPLETIONS_DIR]}
ZINIT[SNIPPETS_DIR]=${~ZINIT[SNIPPETS_DIR]} ZINIT[SERVICES_DIR]=${~ZINIT[SERVICES_DIR]}
export ZPFX=${~ZPFX} ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache/zinit}}" \
    PMSPEC=0uUpiPsf
[[ -z ${path[(re)$ZPFX/bin]} ]] && path=( "$ZPFX/bin" "${path[@]}" )

# Add completions directory to fpath
[[ -z ${fpath[(re)${ZINIT[COMPLETIONS_DIR]}]} ]] && fpath=( "${ZINIT[COMPLETIONS_DIR]}" "${fpath[@]}" )

[[ ! -d $ZSH_CACHE_DIR ]] && command mkdir -p "$ZSH_CACHE_DIR"
[[ -n ${ZINIT[ZCOMPDUMP_PATH]} ]] && ZINIT[ZCOMPDUMP_PATH]=${~ZINIT[ZCOMPDUMP_PATH]}

ZINIT[UPAR]=";:^[[A;:^[OA;:\\e[A;:\\eOA;:${termcap[ku]/$'\e'/^\[};:${terminfo[kcuu1]/$'\e'/^\[};:"
ZINIT[DOWNAR]=";:^[[B;:^[OB;:\\e[B;:\\eOB;:${termcap[kd]/$'\e'/^\[};:${terminfo[kcud1]/$'\e'/^\[};:"
ZINIT[RIGHTAR]=";:^[[C;:^[OC;:\\e[C;:\\eOC;:${termcap[kr]/$'\e'/^\[};:${terminfo[kcuf1]/$'\e'/^\[};:"
ZINIT[LEFTAR]=";:^[[D;:^[OD;:\\e[D;:\\eOD;:${termcap[kl]/$'\e'/^\[};:${terminfo[kcub1]/$'\e'/^\[};:"

builtin autoload -Uz is-at-least
is-at-least 5.1 && ZINIT[NEW_AUTOLOAD]=1 || ZINIT[NEW_AUTOLOAD]=0
#is-at-least 5.4 && ZINIT[NEW_AUTOLOAD]=2

# Parameters - shadowing [[[
ZINIT[SHADOWING]=inactive   ZINIT[DTRACE]=0    ZINIT[CUR_PLUGIN]=
# ]]]
# Parameters - ICE [[[
declare -gA ZINIT_1MAP ZINIT_2MAP
ZINIT_1MAP=(
    OMZ:: https://github.com/ohmyzsh/ohmyzsh/trunk/
    PZT:: https://github.com/sorin-ionescu/prezto/trunk/
)
ZINIT_2MAP=(
    OMZ:: https://github.com/ohmyzsh/ohmyzsh/raw/master/
    PZT:: https://github.com/sorin-ionescu/prezto/raw/master/
)
# ]]]

# Init [[[
zmodload zsh/zutil || { print -P "%F{196}zsh/zutil module is required, aborting Zinit set up.%f"; return 1; }
zmodload zsh/parameter || { print -P "%F{196}zsh/parameter module is required, aborting Zinit set up.%f"; return 1; }
zmodload zsh/terminfo 2>/dev/null
zmodload zsh/termcap 2>/dev/null

[[ ( ${+terminfo} = 1 && -n ${terminfo[colors]} ) || ( ${+termcap} = 1 && -n ${termcap[Co]} ) ]] && {
    ZINIT+=(
        col-title     ""
        col-pname     $'\e[33m'
        col-uname     $'\e[35m'
        col-keyword   $'\e[32m'
        col-note      $'\e[33m'
        col-error     $'\e[31m'
        col-p         $'\e[01m\e[34m'
        col-bar       $'\e[01m\e[35m'
        col-info      $'\e[32m'
        col-info2     $'\e[32m'
        col-uninst    $'\e[01m\e[34m'
        col-success   $'\e[01m\e[32m'
        col-failure   $'\e[31m'
        col-rst       $'\e[0m'
        col-bold      $'\e[1m'

        col-pre    $'\e[38;5;141m'
        col-msg1   $'\e[0m'
        col-msg2   $'\e[38;5;172m'
        col-obj    $'\e[38;5;221m'
        col-obj2   $'\e[38;5;140m'
        col-file   $'\e[38;5;117m'
    )
}

# List of hooks
typeset -gAH ZINIT_ZLE_HOOKS_LIST
ZINIT_ZLE_HOOKS_LIST=(
    zle-line-init 1
    zle-line-finish 1
    paste-insert 1
    zle-isearch-exit 1
    zle-isearch-update 1
    zle-history-line-set 1
    zle-keymap-select 1
)

builtin setopt noaliases

# ]]]

#
# Shadowing-related functions
#

# FUNCTION: :zinit-reload-and-run [[[
# Marks given function ($3) for autoloading, and executes it triggering the
# load. $1 is the fpath dedicated to the function, $2 are autoload options.
# This function replaces "autoload -X", because using that on older Zsh
# versions causes problems with traps.
#
# So basically one creates function stub that calls :zinit-reload-and-run()
# instead of "autoload -X".
#
# $1 - FPATH dedicated to function
# $2 - autoload options
# $3 - function name (one that needs autoloading)
#
# Author: Bart Schaefer
:zinit-reload-and-run () {
    local fpath_prefix="$1" autoload_opts="$2" func="$3"
    shift 3

    # Unfunction caller function (its name is given)
    unfunction -- "$func"

    local -a __fpath
    __fpath=( ${fpath[@]} )
    local -a +h fpath
    # See #127
    [[ $FPATH != *${${(@0)fpath_prefix}[1]}* ]] && \
        fpath=( ${(@0)fpath_prefix} ${__fpath[@]} )

    # After this the function exists again
    builtin autoload ${(s: :)autoload_opts} -- "$func"

    # User wanted to call the function, not only load it
    "$func" "$@"
} # ]]]
# FUNCTION: :zinit-shadow-autoload [[[
# Function defined to hijack plugin's calls to `autoload' builtin.
#
# The hijacking is not only to gather report data, but also to
# run custom `autoload' function, that doesn't need FPATH.
:zinit-shadow-autoload () {
    emulate -LR zsh
    builtin setopt extendedglob warncreateglobal typesetsilent noshortloops
    local -a opts
    local func

    zparseopts -D -a opts ${(s::):-RTUXdkmrtWz}

    [[ $ZINIT[CUR_USR] = % ]] && \
        local PLUGIN_DIR="$ZINIT[CUR_PLUGIN]" || \
        local PLUGIN_DIR="${ZINIT[PLUGINS_DIR]}/${${ZINIT[CUR_USR]}:+${ZINIT[CUR_USR]}---}${ZINIT[CUR_PLUGIN]//\//---}"

    if (( ${+opts[(r)-X]} )); then
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: Failed autoload ${(j: :)opts[@]} $*"
        print -u2 "builtin autoload required for ${(j: :)opts[@]}"
        return 1
    fi
    if (( ${+opts[(r)-w]} )); then
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "-w-Autoload ${(j: :)opts[@]} ${(j: :)@}"
        local +h FPATH="$PLUGINS_DIR:$FPATH"
        builtin autoload ${opts[@]} "$@"
        return 0
    fi
    if [[ -n ${(M)@:#+X} ]]; then
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Autoload +X ${opts:+${(j: :)opts[@]} }${(j: :)${@:#+X}}"
        local +h FPATH="$PLUGINS_DIR:$FPATH"
        builtin autoload +X ${opts[@]} "${@:#+X}"
        return 0
    fi
    # Report ZPLUGIN's "native" autoloads
    for func; do
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Autoload $func${opts:+ with options ${(j: :)opts[@]}}"
    done

    local -a fpath_elements
    fpath_elements=( ${fpath[(r)$PLUGIN_DIR/*]} )

    [[ -d $PLUGIN_DIR/functions ]] && fpath_elements+=( "$PLUGIN_DIR"/functions )

    for func; do
        # Real autoload doesn't touch function if it already exists
        # Author of the idea of FPATH-clean autoloading: Bart Schaefer
        if (( ${+functions[$func]} != 1 )); then
            builtin setopt noaliases
            if [[ ${ZINIT[NEW_AUTOLOAD]} = 2 ]]; then
                builtin autoload ${opts[@]} "$PLUGIN_DIR/$func"
            elif [[ ${ZINIT[NEW_AUTOLOAD]} = 1 ]]; then
                eval "function ${(q)func} {
                    local -a fpath
                    fpath=( ${(qqq)PLUGIN_DIR} ${(qqq@)fpath_elements} ${(qqq@)fpath} )
                    builtin autoload -X ${(j: :)${(q-)opts[@]}}
                }"
            else
                eval "function ${(q)func} {
                    :zinit-reload-and-run ${(qqq)PLUGIN_DIR}"$'\0'"${(pj,\0,)${(qqq)fpath_elements[@]}} ${(qq)opts[*]} ${(q)func} "'"$@"
                }'
            fi
            (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases
        fi
    done

    return 0
} # ]]]
# FUNCTION: :zinit-shadow-bindkey [[[
# Function defined to hijack plugin's calls to `bindkey' builtin.
#
# The hijacking is to gather report data (which is used in unload).
:zinit-shadow-bindkey() {
    emulate -LR zsh
    builtin setopt extendedglob warncreateglobal typesetsilent noshortloops

    is-at-least 5.3 && \
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Bindkey ${(j: :)${(q+)@}}" || \
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Bindkey ${(j: :)${(q)@}}"

    # Remember to perform the actual bindkey call
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular bindkey call, i.e.
    # with no options or with -s, plus possible -M
    # option
    local -A opts
    zparseopts -A opts -D ${(s::):-lLdDAmrsevaR} M: N:

    if (( ${#opts} == 0 ||
        ( ${#opts} == 1 && ${+opts[-M]} ) ||
        ( ${#opts} == 1 && ${+opts[-R]} ) ||
        ( ${#opts} == 1 && ${+opts[-s]} ) ||
        ( ${#opts} <= 2 && ${+opts[-M]} && ${+opts[-s]} ) ||
        ( ${#opts} <= 2 && ${+opts[-M]} && ${+opts[-R]} )
    )); then
        local string="${(q)1}" widget="${(q)2}"
        local quoted

        if [[ -n ${ZINIT_ICE[bindmap]} && ${ZINIT_CUR_BIND_MAP[empty]} -eq 1 ]]; then
            local -a pairs
            pairs=( "${(@s,;,)ZINIT_ICE[bindmap]}" )
            () {
                builtin setopt localoptions extendedglob noksharrays noshwordsplit;
                pairs=( "${(@)${(@)${(@s:->:)pairs}##[[:space:]]##}%%[[:space:]]##}" )
            }
            ZINIT_CUR_BIND_MAP=( empty 0 )
            (( ${#pairs} > 1 && ${#pairs[@]} % 2 == 0 )) && ZINIT_CUR_BIND_MAP+=( "${pairs[@]}" )
        fi

        local bmap_val="${ZINIT_CUR_BIND_MAP[${1}]}"
        [[ -z $bmap_val ]] && bmap_val="${ZINIT_CUR_BIND_MAP[${(qqq)1}]}"
        [[ -z $bmap_val ]] && bmap_val="${ZINIT_CUR_BIND_MAP[${(qqq)${(Q)1}}]}"
        [[ -z $bmap_val ]] && { bmap_val="${ZINIT_CUR_BIND_MAP[!${(qqq)1}]}"; integer val=1; }
        [[ -z $bmap_val ]] && bmap_val="${ZINIT_CUR_BIND_MAP[!${(qqq)${(Q)1}}]}"
        if [[ -n $bmap_val ]]; then
            string="${(q)bmap_val}"
            if (( val )) {
                [[ ${pos[1]} = "-M" ]] && pos[4]="$bmap_val" || pos[2]="$bmap_val"
            } else {
                [[ ${pos[1]} = "-M" ]] && pos[3]="${(Q)bmap_val}" || pos[1]="${(Q)bmap_val}"
            }
            .zinit-add-report "${ZINIT[CUR_USPL2]}" ":::Bindkey: combination <$1> changed to <$bmap_val>${${(M)bmap_val:#hold}:+, i.e. ${ZINIT[col-error]}unmapped${ZINIT[col-rst]}}"
            ((1))
        elif [[ ( -n ${bmap_val::=${ZINIT_CUR_BIND_MAP[UPAR]}} && -n ${${ZINIT[UPAR]}[(r);:${(q)1};:]} ) || \
                ( -n ${bmap_val::=${ZINIT_CUR_BIND_MAP[DOWNAR]}} && -n ${${ZINIT[DOWNAR]}[(r);:${(q)1};:]} ) || \
                ( -n ${bmap_val::=${ZINIT_CUR_BIND_MAP[RIGHTAR]}} && -n ${${ZINIT[RIGHTAR]}[(r);:${(q)1};:]} ) || \
                ( -n ${bmap_val::=${ZINIT_CUR_BIND_MAP[LEFTAR]}} && -n ${${ZINIT[LEFTAR]}[(r);:${(q)1};:]} )
        ]]; then
            string="${(q)bmap_val}"
            if (( val )) {
                [[ ${pos[1]} = "-M" ]] && pos[4]="$bmap_val" || pos[2]="$bmap_val"
            } else {
                [[ ${pos[1]} = "-M" ]] && pos[3]="${(Q)bmap_val}" || pos[1]="${(Q)bmap_val}"
            }
            .zinit-add-report "${ZINIT[CUR_USPL2]}" ":::Bindkey: combination <$1> recognized as cursor-key and changed to <${bmap_val}>${${(M)bmap_val:#hold}:+, i.e. ${ZINIT[col-error]}unmapped${ZINIT[col-rst]}}"
        fi
        [[ $bmap_val = hold ]] && return 0

        local prev="${(q)${(s: :)$(builtin bindkey ${(Q)string})}[-1]#undefined-key}"

        # "-M map" given?
        if (( ${+opts[-M]} )); then
            local Mopt=-M
            local Marg="${opts[-M]}"

            Mopt="${(q)Mopt}"
            Marg="${(q)Marg}"

            quoted="$string $widget $prev $Mopt $Marg"
        else
            quoted="$string $widget $prev"
        fi

        # -R given?
        if (( ${+opts[-R]} )); then
            local Ropt=-R
            Ropt="${(q)Ropt}"

            if (( ${+opts[-M]} )); then
                quoted="$quoted $Ropt"
            else
                # Two empty fields for non-existent -M arg
                local space=_
                space="${(q)space}"
                quoted="$quoted $space $space $Ropt"
            fi
        fi

        quoted="${(q)quoted}"

        # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
        [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[BINDKEYS__${ZINIT[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[BINDKEYS___dtrace/_dtrace]+="$quoted "
    else
        # bindkey -A newkeymap main?
        # Negative indices for KSH_ARRAYS immunity
        if [[ ${#opts} -eq 1 && ${+opts[-A]} = 1 && ${#pos} = 3 && ${pos[-1]} = main && ${pos[-2]} != -A ]]; then
            # Save a copy of main keymap
            (( ZINIT[BINDKEY_MAIN_IDX] = ${ZINIT[BINDKEY_MAIN_IDX]:-0} + 1 ))
            local pname="${ZINIT[CUR_PLUGIN]:-_dtrace}"
            local name="${(q)pname}-main-${ZINIT[BINDKEY_MAIN_IDX]}"
            builtin bindkey -N "$name" main

            # Remember occurence of main keymap substitution, to revert on unload
            local keys=_ widget=_ prev= optA=-A mapname="${name}" optR=_
            local quoted="${(q)keys} ${(q)widget} ${(q)prev} ${(q)optA} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
            [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[BINDKEYS__${ZINIT[CUR_USPL2]}]+="$quoted "
            [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[BINDKEYS___dtrace/_dtrace]+="$quoted "

            .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: keymap \`main' copied to \`${name}' because of \`${pos[-2]}' substitution"
        # bindkey -N newkeymap [other]
        elif [[ ${#opts} -eq 1 && ${+opts[-N]} = 1 ]]; then
            local Nopt=-N
            local Narg="${opts[-N]}"

            local keys=_ widget=_ prev= optN=-N mapname="${Narg}" optR=_
            local quoted="${(q)keys} ${(q)widget} ${(q)prev} ${(q)optN} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
            [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[BINDKEYS__${ZINIT[CUR_USPL2]}]+="$quoted "
            [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[BINDKEYS___dtrace/_dtrace]+="$quoted "
        else
            .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: last bindkey used non-typical options: ${(kv)opts[*]}"
        fi
    fi

    # Actual bindkey
    builtin bindkey "${pos[@]}"
    return $? # testable
} # ]]]
# FUNCTION: :zinit-shadow-zstyle [[[
# Function defined to hijack plugin's calls to `zstyle' builtin.
#
# The hijacking is to gather report data (which is used in unload).
:zinit-shadow-zstyle() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob nowarncreateglobal \
        typesetsilent noshortloops unset
    .zinit-add-report "${ZINIT[CUR_USPL2]}" "Zstyle $*"

    # Remember to perform the actual zstyle call
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular zstyle call, i.e.
    # with no options or with -e
    local -a opts
    zparseopts -a opts -D ${(s::):-eLdgabsTtm}

    if [[ ${#opts} -eq 0 || ( ${#opts} -eq 1 && ${+opts[(r)-e]} = 1 ) ]]; then
        # Have to quote $1, then $2, then concatenate them, then quote them again
        local pattern="${(q)1}" style="${(q)2}"
        local ps="$pattern $style"
        ps="${(q)ps}"

        # Remember the zstyle, only when load is in progress (it can be dstart that leads execution here)
        [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[ZSTYLES__${ZINIT[CUR_USPL2]}]+="$ps "
        # Remember for dtrace
        [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[ZSTYLES___dtrace/_dtrace]+=$ps
    else
        if [[ ! ${#opts[@]} = 1 && ( ${+opts[(r)-s]} = 1 || ${+opts[(r)-b]} = 1 || ${+opts[(r)-a]} = 1 ||
              ${+opts[(r)-t]} = 1 || ${+opts[(r)-T]} = 1 || ${+opts[(r)-m]} = 1 )
        ]]; then
            .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: last zstyle used non-typical options: ${opts[*]}"
        fi
    fi

    # Actual zstyle
    builtin zstyle "${pos[@]}"
    return $? # testable
} # ]]]
# FUNCTION: :zinit-shadow-alias [[[
# Function defined to hijack plugin's calls to `alias' builtin.
#
# The hijacking is to gather report data (which is used in unload).
:zinit-shadow-alias() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    .zinit-add-report "${ZINIT[CUR_USPL2]}" "Alias $*"

    # Remember to perform the actual alias call
    typeset -a pos
    pos=( "$@" )

    local -a opts
    zparseopts -a opts -D ${(s::):-gs}

    local a quoted tmp
    for a in "$@"; do
        local aname="${a%%[=]*}"
        local avalue="${a#*=}"

        # Check if alias is to be redefined
        (( ${+aliases[$aname]} )) && .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: redefining alias \`${aname}', previous value: ${aliases[$aname]}"

        local bname=${(q)aliases[$aname]}
        aname="${(q)aname}"

        if (( ${+opts[(r)-s]} )); then
            tmp=-s
            tmp="${(q)tmp}"
            quoted="$aname $bname $tmp"
        elif (( ${+opts[(r)-g]} )); then
            tmp=-g
            tmp="${(q)tmp}"
            quoted="$aname $bname $tmp"
        else
            quoted="$aname $bname"
        fi

        quoted="${(q)quoted}"

        # Remember the alias, only when load is in progress (it can be dstart that leads execution here)
        [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[ALIASES__${ZINIT[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[ALIASES___dtrace/_dtrace]+="$quoted "
    done

    # Actual alias
    builtin alias "${pos[@]}"
    return $? # testable
} # ]]]
# FUNCTION: :zinit-shadow-zle [[[
# Function defined to hijack plugin's calls to `zle' builtin.
#
# The hijacking is to gather report data (which is used in unload).
:zinit-shadow-zle() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    .zinit-add-report "${ZINIT[CUR_USPL2]}" "Zle $*"

    # Remember to perform the actual zle call
    typeset -a pos
    pos=( "$@" )

    set -- "${@:#--}"

    # Try to catch game-changing "-N"
    if [[ ( $1 = -N && ( $# = 2 || $# = 3 ) ) || ( $1 = -C && $# = 4 ) ]]; then
            # Hooks
            if [[ ${ZINIT_ZLE_HOOKS_LIST[$2]} = 1 ]]; then
                local quoted="$2"
                quoted="${(q)quoted}"
                # Remember only when load is in progress (it can be dstart that leads execution here)
                [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[WIDGETS_DELETE__${ZINIT[CUR_USPL2]}]+="$quoted "
                # Remember for dtrace
                [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[WIDGETS_DELETE___dtrace/_dtrace]+="$quoted "
            # These will be saved and restored
            elif (( ${+widgets[$2]} )); then
                # Have to remember original widget "$2" and
                # the copy that it's going to be done
                local widname="$2" targetfun="${${${(M)1:#-C}:+$4}:-$3}"
                local completion_widget="${${(M)1:#-C}:+$3}"
                local saved_widcontents="${widgets[$widname]}"

                widname="${(q)widname}"
                completion_widget="${(q)completion_widget}"
                targetfun="${(q)targetfun}"
                saved_widcontents="${(q)saved_widcontents}"
                local quoted="$1 $widname $completion_widget $targetfun $saved_widcontents"
                quoted="${(q)quoted}"
                # Remember only when load is in progress (it can be dstart that leads execution here)
                [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[WIDGETS_SAVED__${ZINIT[CUR_USPL2]}]+="$quoted "
                # Remember for dtrace
                [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[WIDGETS_SAVED___dtrace/_dtrace]+="$quoted "
             # These will be deleted
             else
                 .zinit-add-report "${ZINIT[CUR_USPL2]}" "Note: a new widget created via zle -N: \`$2'"
                 local quoted="$2"
                 quoted="${(q)quoted}"
                 # Remember only when load is in progress (it can be dstart that leads execution here)
                 [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[WIDGETS_DELETE__${ZINIT[CUR_USPL2]}]+="$quoted "
                 # Remember for dtrace
                 [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[WIDGETS_DELETE___dtrace/_dtrace]+="$quoted "
             fi
    fi

    # Actual zle
    builtin zle "${pos[@]}"
    return $? # testable
} # ]]]
# FUNCTION: :zinit-shadow-compdef [[[
# Function defined to hijack plugin's calls to `compdef' function.
# The hijacking is not only for reporting, but also to save compdef
# calls so that `compinit' can be called after loading plugins.
:zinit-shadow-compdef() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    .zinit-add-report "${ZINIT[CUR_USPL2]}" "Saving \`compdef $*' for replay"
    ZINIT_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" )

    return 0 # testable
} # ]]]
# FUNCTION: .zinit-shadow-on [[[
# Turn on shadowing of builtins and functions according to passed
# mode ("load", "light", "light-b" or "compdef"). The shadowing is
# to gather report data, and to hijack `autoload', `bindkey' and
# `compdef' calls.
.zinit-shadow-on() {
    local mode="$1"

    # Enable shadowing only once
    #
    # One could expect possibility of widening of shadowing, however
    # such sequence doesn't exist, e.g. "light" then "load"/"dtrace",
    # "compdef" then "load"/"dtrace", "light" then "compdef",
    # "compdef" then "light"
    #
    # It is always "dtrace" then "load" (i.e. dtrace then load)
    # "dtrace" then "light" (i.e. dtrace then light load)
    # "dtrace" then "compdef" (i.e. dtrace then snippet)
    [[ ${ZINIT[SHADOWING]} != inactive ]] && builtin return 0

    ZINIT[SHADOWING]="$mode"

    # The point about backuping is: does the key exist in functions array
    # If it does exist, then it will also exist as ZINIT[bkp-*]

    # Defensive code, shouldn't be needed
    builtin unset "ZINIT[bkp-autoload]" "ZINIT[bkp-compdef]"  # 0, E.

    if [[ $mode != compdef ]]; then
        # 0. Used, but not in temporary restoration, which doesn't happen for autoload
        (( ${+functions[autoload]} )) && ZINIT[bkp-autoload]="${functions[autoload]}"
        functions[autoload]=':zinit-shadow-autoload "$@";'
    fi

    # E. Always shadow compdef
    (( ${+functions[compdef]} )) && ZINIT[bkp-compdef]="${functions[compdef]}"
    functions[compdef]=':zinit-shadow-compdef "$@";'

    # Light and compdef shadowing stops here. Dtrace and load go on
    [[ ( $mode = light && ${+ZINIT_ICE[trackbinds]} -eq 0 ) || $mode = compdef ]] && return 0

    # Defensive code, shouldn't be needed. A, B, C, D
    builtin unset "ZINIT[bkp-bindkey]" "ZINIT[bkp-zstyle]" "ZINIT[bkp-alias]" "ZINIT[bkp-zle]"

    # A.
    (( ${+functions[bindkey]} )) && ZINIT[bkp-bindkey]="${functions[bindkey]}"
    functions[bindkey]=':zinit-shadow-bindkey "$@";'

    # B, when `zinit light -b ...' or when `zinit ice trackbinds ...; zinit light ...'
    [[ $mode = light-b || ( $mode = light && ${+ZINIT_ICE[trackbinds]} -eq 1 ) ]] && return 0

    # B.
    (( ${+functions[zstyle]} )) && ZINIT[bkp-zstyle]="${functions[zstyle]}"
    functions[zstyle]=':zinit-shadow-zstyle "$@";'

    # C.
    (( ${+functions[alias]} )) && ZINIT[bkp-alias]="${functions[alias]}"
    functions[alias]=':zinit-shadow-alias "$@";'

    # D.
    (( ${+functions[zle]} )) && ZINIT[bkp-zle]="${functions[zle]}"
    functions[zle]=':zinit-shadow-zle "$@";'

    builtin return 0
} # ]]]
# FUNCTION: .zinit-shadow-off [[[
# Turn off shadowing completely for a given mode ("load", "light",
# "light-b" (i.e. the `trackbinds' mode) or "compdef").
.zinit-shadow-off() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset noaliases
    local mode="$1"

    # Disable shadowing only once
    # Disable shadowing only the way it was enabled first
    [[ ${ZINIT[SHADOWING]} = inactive || ${ZINIT[SHADOWING]} != $mode ]] && return 0

    ZINIT[SHADOWING]=inactive

    if [[ $mode != compdef ]]; then
        # 0. Unfunction autoload
        (( ${+ZINIT[bkp-autoload]} )) && functions[autoload]="${ZINIT[bkp-autoload]}" || unfunction autoload
    fi

    # E. Restore original compdef if it existed
    (( ${+ZINIT[bkp-compdef]} )) && functions[compdef]="${ZINIT[bkp-compdef]}" || unfunction compdef

    # Light and compdef shadowing stops here
    [[ ( $mode = light && ${+ZINIT_ICE[trackbinds]} -eq 0 ) || $mode = compdef ]] && return 0

    # Unfunction shadowing functions

    # A.
    (( ${+ZINIT[bkp-bindkey]} )) && functions[bindkey]="${ZINIT[bkp-bindkey]}" || unfunction bindkey

    # When `zinit light -b ...' or when `zinit ice trackbinds ...; zinit light ...'
    [[ $mode = light-b || ( $mode = light && ${+ZINIT_ICE[trackbinds]} -eq 1 ) ]] && return 0

    # B.
    (( ${+ZINIT[bkp-zstyle]} )) && functions[zstyle]="${ZINIT[bkp-zstyle]}" || unfunction zstyle
    # C.
    (( ${+ZINIT[bkp-alias]} )) && functions[alias]="${ZINIT[bkp-alias]}" || unfunction alias
    # D.
    (( ${+ZINIT[bkp-zle]} )) && functions[zle]="${ZINIT[bkp-zle]}" || unfunction zle

    return 0
} # ]]]
# FUNCTION: pmodload [[[
# {function:pmodload} Compatibility with Prezto. Calls can be recursive.
(( ${+functions[pmodload]} )) || pmodload() {
    while (( $# )); do
        if zstyle -t ":prezto:module:$1" loaded 'yes' 'no'; then
            shift
            continue
        else
            [[ -z ${ZINIT_SNIPPETS[PZT::modules/$1${ZINIT_ICE[svn]-/init.zsh}]} && -z ${ZINIT_SNIPPETS[https://github.com/sorin-ionescu/prezto/trunk/modules/$1${ZINIT_ICE[svn]-/init.zsh}]} ]] && .zinit-load-snippet PZT::modules/"$1${ZINIT_ICE[svn]-/init.zsh}"
            shift
        fi
    done
}
# ]]]
# FUNCTION: .zinit-wrap-track-functions [[[
.zinit-wrap-track-functions() {
    local user="$1" plugin="$2" id_as="$3" f
    local -a wt
    wt=( ${(@s.;.)ZINIT_ICE[wrap-track]} )
    for f in ${wt[@]}; do
        functions[${f}-zinit-bkp]="${functions[$f]}"
        eval "
function $f {
    ZINIT[CUR_USR]=\"$user\" ZINIT[CUR_PLUGIN]=\"$plugin\" ZINIT[CUR_USPL2]=\"$id_as\"
    .zinit-add-report \"\${ZINIT[CUR_USPL2]}\" \"Note: === Starting to track function: $f ===\"
    .zinit-diff \"\${ZINIT[CUR_USPL2]}\" begin
    .zinit-shadow-on load
    functions[${f}]=\${functions[${f}-zinit-bkp]}
    ${f} \"\$@\"
    .zinit-shadow-off load
    .zinit-diff \"\${ZINIT[CUR_USPL2]}\" end
    .zinit-add-report \"\${ZINIT[CUR_USPL2]}\" \"Note: === Ended tracking function: $f ===\"
    ZINIT[CUR_USR]= ZINIT[CUR_PLUGIN]= ZINIT[CUR_USPL2]=
}"
    done
}
# ]]]

#
# Diff functions
#

# FUNCTION: .zinit-diff-functions [[[
# Implements detection of newly created functions. Performs
# data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
.zinit-diff-functions() {
    local uspl2="$1"
    local cmd="$2"

    [[ $cmd = begin ]] && \
        { [[ -z ${ZINIT[FUNCTIONS_BEFORE__$uspl2]} ]] && \
                ZINIT[FUNCTIONS_BEFORE__$uspl2]="${(j: :)${(qk)functions[@]}}"
        } || \
        ZINIT[FUNCTIONS_AFTER__$uspl2]+=" ${(j: :)${(qk)functions[@]}}"
} # ]]]
# FUNCTION: .zinit-diff-options [[[
# Implements detection of change in option state. Performs
# data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
.zinit-diff-options() {
    local IFS=" "

    [[ $2 = begin ]] && \
        { [[ -z ${ZINIT[OPTIONS_BEFORE__$uspl2]} ]] && \
            ZINIT[OPTIONS_BEFORE__$1]="${(kv)options[@]}"
        } || \
        ZINIT[OPTIONS_AFTER__$1]+=" ${(kv)options[@]}"
} # ]]]
# FUNCTION: .zinit-diff-env [[[
# Implements detection of change in PATH and FPATH.
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
.zinit-diff-env() {
    typeset -a tmp
    local IFS=" "

    [[ $2 = begin ]] && {
            { [[ -z ${ZINIT[PATH_BEFORE__$uspl2]} ]] && \
                tmp=( "${(q)path[@]}" )
                ZINIT[PATH_BEFORE__$1]="${tmp[*]}"
            }
            { [[ -z ${ZINIT[FPATH_BEFORE__$uspl2]} ]] && \
                tmp=( "${(q)fpath[@]}" )
                ZINIT[FPATH_BEFORE__$1]="${tmp[*]}"
            }
    } || {
            tmp=( "${(q)path[@]}" )
            ZINIT[PATH_AFTER__$1]+=" ${tmp[*]}"
            tmp=( "${(q)fpath[@]}" )
            ZINIT[FPATH_AFTER__$1]+=" ${tmp[*]}"
    }
} # ]]]
# FUNCTION: .zinit-diff-parameter [[[
# Implements detection of change in any parameter's existence and type.
# Performs data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
.zinit-diff-parameter() {
    typeset -a tmp

    [[ $2 = begin ]] && {
        { [[ -z ${ZINIT[PARAMETERS_BEFORE__$uspl2]} ]] && \
            ZINIT[PARAMETERS_BEFORE__$1]="${(j: :)${(qkv)parameters[@]}}"
        }
    } || {
        ZINIT[PARAMETERS_AFTER__$1]+=" ${(j: :)${(qkv)parameters[@]}}"
    }
} # ]]]
# FUNCTION: .zinit-diff [[[
# Performs diff actions of all types
.zinit-diff() {
    .zinit-diff-functions "$1" "$2"
    .zinit-diff-options "$1" "$2"
    .zinit-diff-env "$1" "$2"
    .zinit-diff-parameter "$1" "$2"
}
# ]]]

#
# Utility functions
#

# FUNCTION: .zinit-get-mtime-into [[[
.zinit-get-mtime-into() {
    if (( ZINIT[HAVE_ZSTAT] )) {
        local -a arr
        { zstat +mtime -A arr "$1"; } 2>/dev/null
        : ${(P)2::="${arr[1]}"}
    } else {
        { : ${(P)2::="$(stat -c %Y "$1")"}; } 2>/dev/null
    }
} # ]]]
# FUNCTION: @zinit-substitute [[[
@zinit-substitute() {
    emulate -LR zsh
    setopt extendedglob warncreateglobal typesetsilent noshortloops

    local -A __subst_map
    __subst_map=(
        "%ID%"   "${id_as_clean:-$id_as}"
        "%USER%" "$user"
        "%PLUGIN%" "${plugin:-$save_url}"
        "%URL%" "${save_url:-${user:+$user/}$plugin}"
        "%DIR%" "${local_path:-$local_dir${dirname:+/$dirname}}"
        '$ZPFX' "$ZPFX"
        '${ZPFX}' "$ZPFX"
        '%OS%' "${OSTYPE%(-gnu|[0-9]##)}" '%MACH%' "$MACHTYPE" '%CPU%' "$CPUTYPE"
        '%VENDOR%' "$VENDOR" '%HOST%' "$HOST" '%UID%' "$UID" '%GID%' "$GID"
    )
    if [[ -n ${ZINIT_ICE[param]} && ${ZINIT[SUBST_DONE_FOR]} != ${ZINIT_ICE[param]} ]] {
        ZINIT[SUBST_DONE_FOR]=${ZINIT_ICE[param]}
        ZINIT[PARAM_SUBST]=
        local -a __params
        __params=( ${(s.;.)ZINIT_ICE[param]} )
        local __param __from __to
        for __param ( ${__params[@]} ) {
            local __from=${${__param%%([[:space:]]|)(->|→)*}##[[:space:]]##} \
                __to=${${__param#*(->|→)([[:space:]]|)}%[[:space:]]}
            __from=${__from//((#s)[[:space:]]##|[[:space:]]##(#e))/}
            __to=${__to//((#s)[[:space:]]##|[[:space:]]##(#e))/}
            ZINIT[PARAM_SUBST]+="%${(q)__from}% ${(q)__to} "
        }
    }

    local -a __add
    __add=( "${ZINIT_ICE[param]:+${(@Q)${(@z)ZINIT[PARAM_SUBST]}}}" )
    (( ${#__add} % 2 == 0 )) && __subst_map+=( "${__add[@]}" )

    local __var_name
    for __var_name; do
        local __value=${(P)__var_name}
        __value=${__value//(#m)(%[a-zA-Z0-9]##%|\$ZPFX|\$\{ZPFX\})/${__subst_map[$MATCH]}}
        : ${(P)__var_name::=$__value}
    done
}
# ]]]
# FUNCTION: .zinit-any-to-user-plugin [[[
# Allows elastic plugin-spec across the code.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
#
# Returns user and plugin in $reply
#
.zinit-any-to-user-plugin() {
    # Two components given?
    # That's a pretty fast track to call this function this way
    if [[ -n $2 ]];then
        2=${~2}
        reply=( "${1:-${${(M)2#/}:+%}}" "${${${(M)1#%}:+$2}:-${2//---//}}" )
        return 0
    fi

    # Is it absolute path?
    if [[ $1 = /* ]]; then
        reply=( "%" "$1" )
        return 0
    fi

    # Is it absolute path in zinit format?
    if [[ $1 = %* ]]; then
        reply=( "%" "${${${1/\%HOME/$HOME}/\%SNIPPETS/${ZINIT[SNIPPETS_DIR]}}#%}" )
        reply[2]=${~reply[2]}
        return 0
    fi

    # Rest is for single component given
    # It doesn't touch $2

    1="${1//---//}"
    if [[ $1 = */* ]]; then
        reply=( "${1%%/*}" "${1#*/}" )
        return 0
    fi

    reply=( "" "${1:-_unknown}" )

    return 0
} # ]]]
# FUNCTION: .zinit-find-other-matches [[[
# Plugin's main source file is in general `name.plugin.zsh'. However,
# there can be different conventions, if that file is not found, then
# this functions examines other conventions in the most sane order.
.zinit-find-other-matches() {
    local pdir_path="$1" pbase="$2"

    if [[ -e $pdir_path/init.zsh ]] {
        reply=( "$pdir_path"/init.zsh )
    } elif [[ -e $pdir_path/$pbase.zsh-theme ]] {
        reply=( "$pdir_path/$pbase".zsh-theme )
    } elif [[ -e $pdir_path/$pbase.theme.zsh ]] {
        reply=( "$pdir_path/$pbase".theme.zsh )
    } else {
        reply=(
            "$pdir_path"/*.plugin.zsh(DN) "$pdir_path"/*.zsh-theme(DN) "$pdir_path"/*.lib.zsh(DN)
            "$pdir_path"/*.zsh(DN) "$pdir_path"/*.sh(DN) "$pdir_path"/.zshrc(DN)
        )
    }
    reply=( "${(u)reply[@]}" )

    return $(( ${#reply} > 0 ? 0 : 1 ))
} # ]]]
# FUNCTION: .zinit-register-plugin [[[
# Adds the plugin to ZINIT_REGISTERED_PLUGINS array and to the
# zsh_loaded_plugins array (managed according to the plugin standard:
# http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html)
.zinit-register-plugin() {
    local uspl2="$1" mode="$2" teleid="$3"
    integer ret=0

    if [[ -z ${ZINIT_REGISTERED_PLUGINS[(r)$uspl2]} ]]; then
        ZINIT_REGISTERED_PLUGINS+=( "$uspl2" )
    else
        # Allow overwrite-load, however warn about it
        [[ -z ${ZINIT[TEST]}${${+ZINIT_ICE[wait]}:#0}${ZINIT_ICE[load]}${ZINIT_ICE[subscribe]} && ${ZINIT[MUTE_WARNINGS]} != 1 ]] && print "Warning: plugin \`$uspl2' already registered, will overwrite-load"
        ret=1
    fi

    # Support Zsh plugin standard
    zsh_loaded_plugins+=( "$teleid" )

    # Full or light load?
    [[ $mode == light ]] && ZINIT_REGISTERED_STATES[$uspl2]=1 || ZINIT_REGISTERED_STATES[$uspl2]=2

    ZINIT_REPORTS[$uspl2]=             ZINIT_CUR_BIND_MAP=( empty 1 )
    # Functions
    ZINIT[FUNCTIONS_BEFORE__$uspl2]=  ZINIT[FUNCTIONS_AFTER__$uspl2]=
    ZINIT[FUNCTIONS__$uspl2]=
    # Objects
    ZINIT[ZSTYLES__$uspl2]=           ZINIT[BINDKEYS__$uspl2]=
    ZINIT[ALIASES__$uspl2]=
    # Widgets
    ZINIT[WIDGETS_SAVED__$uspl2]=     ZINIT[WIDGETS_DELETE__$uspl2]=
    # Rest (options and (f)path)
    ZINIT[OPTIONS__$uspl2]=           ZINIT[PATH__$uspl2]=
    ZINIT[OPTIONS_BEFORE__$uspl2]=    ZINIT[OPTIONS_AFTER__$uspl2]=
    ZINIT[FPATH__$uspl2]=

    return $ret
} # ]]]
# FUNCTION: @zinit-register-z-annex [[[
# Registers the z-annex inside Zinit – i.e. an Zinit extension
@zinit-register-annex() {
    local name="$1" type="$2" handler="$3" helphandler="$4" icemods="$5" key="z-annex ${(q)2}"
    ZINIT_EXTS[seqno]=$(( ${ZINIT_EXTS[seqno]:-0} + 1 ))
    ZINIT_EXTS[$key${${(M)type#hook:}:+ ${ZINIT_EXTS[seqno]}}]="${ZINIT_EXTS[seqno]} z-annex-data: ${(q)name} ${(q)type} ${(q)handler} ${(q)helphandler} ${(q)icemods}"
    ZINIT_EXTS[ice-mods]="${ZINIT_EXTS[ice-mods]}${icemods:+|}$icemods"
}
# ]]]
# FUNCTION: @zsh-plugin-run-on-update [[[
# The Plugin Standard required mechanism, see:
# http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html
@zsh-plugin-run-on-unload() {
    ZINIT_ICE[ps-on-unload]="${(j.; .)@}"
    .zinit-pack-ice "$id_as" ""
}
# ]]]
# FUNCTION: @zsh-plugin-run-on-update [[[
# The Plugin Standard required mechanism
@zsh-plugin-run-on-update() {
    ZINIT_ICE[ps-on-update]="${(j.; .)@}"
    .zinit-pack-ice "$id_as" ""
}
# ]]]
# FUNCTION: .zinit-get-object-path [[[
.zinit-get-object-path() {
    local type="$1" id_as="$2" local_dir dirname
    integer exists

    id_as="${ZINIT_ICE[id-as]:-$id_as}"

    # Remove leading whitespace and trailing /
    id_as="${${id_as#"${id_as%%[! $'\t']*}"}%/}"

    if [[ $type == snippet ]] {
        dirname="${${id_as%%\?*}:t}"
        local_dir="${${${id_as%%\?*}/:\/\//--}:h}"
        [[ $local_dir = . ]] && local_dir= || local_dir="${${${${${local_dir#/}//\//--}//=/-EQ-}//\?/-QM-}//\&/-AMP-}"
        local_dir="${ZINIT[SNIPPETS_DIR]}${local_dir:+/$local_dir}"

    } else {
        local_dir=${${${(M)id_as#%}:+${id_as#%}}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}
        [[ $id_as == _local/* && -d $local_dir && ! -d $local_dir/._zinit ]] && command mkdir -p "$local_dir"/._zinit
    }

    [[ -e $local_dir/${dirname:+$dirname/}._zinit || \
        -e $local_dir/${dirname:+$dirname/}._zplugin ]] && exists=1

    reply=( "$local_dir" "$dirname" "$exists" )

    return $(( 1 - exists ))
}
# ]]]

#
# Remaining functions
#

# FUNCTION: .zinit-prepare-home [[[
# Creates all directories needed by Zinit, first checks if they
# already exist.
.zinit-prepare-home() {
    [[ -n ${ZINIT[HOME_READY]} ]] && return
    ZINIT[HOME_READY]=1

    [[ ! -d ${ZINIT[HOME_DIR]} ]] && {
        command mkdir  -p "${ZINIT[HOME_DIR]}"
        # For compaudit
        command chmod go-w "${ZINIT[HOME_DIR]}"
        # Also set up */bin and ZPFX in general
        command mkdir 2>/dev/null -p $ZPFX/bin
    }
    [[ ! -d ${ZINIT[PLUGINS_DIR]}/_local---zinit ]] && {
        command rm -rf "${ZINIT[PLUGINS_DIR]:-/tmp/132bcaCAB}/_local---zplugin"
        command mkdir -p "${ZINIT[PLUGINS_DIR]}/_local---zinit"
        command chmod go-w "${ZINIT[PLUGINS_DIR]}"
        command ln -s "${ZINIT[BIN_DIR]}/_zinit" "${ZINIT[PLUGINS_DIR]}/_local---zinit"

        # Also set up */bin and ZPFX in general
        command mkdir 2>/dev/null -p $ZPFX/bin

        (( ${+functions[.zinit-setup-plugin-dir]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
        (( ${+functions[.zinit-confirm]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh"
        .zinit-clear-completions &>/dev/null
        .zinit-compinit &>/dev/null
    }
    [[ ! -d ${ZINIT[COMPLETIONS_DIR]} ]] && {
        command mkdir "${ZINIT[COMPLETIONS_DIR]}"
        # For compaudit
        command chmod go-w "${ZINIT[COMPLETIONS_DIR]}"

        # Symlink _zinit completion into _local---zinit directory
        command ln -s "${ZINIT[PLUGINS_DIR]}/_local---zinit/_zinit" "${ZINIT[COMPLETIONS_DIR]}"

        # Also set up */bin and ZPFX in general
        command mkdir 2>/dev/null -p $ZPFX/bin

        (( ${+functions[.zinit-setup-plugin-dir]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
        .zinit-compinit &>/dev/null
    }
    [[ ! -d ${ZINIT[SNIPPETS_DIR]} ]] && {
        command mkdir -p "${ZINIT[SNIPPETS_DIR]}/OMZ::plugins"
        command chmod go-w "${ZINIT[SNIPPETS_DIR]}"
        ( builtin cd ${ZINIT[SNIPPETS_DIR]}; command ln -s OMZ::plugins plugins; )

        # Also create the SERVICES_DIR
        command mkdir -p "${ZINIT[SERVICES_DIR]}"
        command chmod go-w "${ZINIT[SERVICES_DIR]}"

        # Also set up */bin and ZPFX in general
        command mkdir 2>/dev/null -p $ZPFX/bin
    }
} # ]]]
# FUNCTION: .zinit-load-ices [[[
.zinit-load-ices() {
    local id_as="$1" __key __path
    local -a ice_order
    ice_order=(
        ${(As:|:)ZINIT[ice-list]}
        ${(@us.|.)${ZINIT_EXTS[ice-mods]//\'\'/}}
    )
    __path="${ZINIT[PLUGINS_DIR]}/${id_as//\//---}"/._zinit
    # TODO snippet's dir computation…
    if [[ ! -d $__path ]] {
        if ! .zinit-get-object-path snippet "$id_as"; then
            return 1
        fi
        __path="${reply[-3]%/}/${reply[-2]}"/._zinit
    }
    for __key ( "${ice_order[@]}" ) {
        (( ${+ZINIT_ICE[$__key]} )) && [[ ${ZINIT_ICE[$__key]} != +* ]] && continue
        [[ -f $__path/$__key ]] && ZINIT_ICE[$__key]="$(<$__path/$__key)"
    }
    [[ -n ${ZINIT_ICE[on-update-of]} ]] && ZINIT_ICE[subscribe]="${ZINIT_ICE[subscribe]:-${ZINIT_ICE[on-update-of]}}"
    [[ ${ZINIT_ICE[as]} = program ]] && ZINIT_ICE[as]=command
    [[ -n ${ZINIT_ICE[pick]} ]] && ZINIT_ICE[pick]="${ZINIT_ICE[pick]//\$ZPFX/${ZPFX%/}}"

    return 0
}
# ]]]
# FUNCTION: .zinit-load [[[
# Implements the exposed-to-user action of loading a plugin.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin name, if the third format is used
.zinit-load () {
    typeset -F 3 SECONDS=0
    local mode="$3" rst=0 retval=0 key
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" id_as="${ZINIT_ICE[id-as]:-${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]}}"
    ZINIT_ICE[teleid]="${ZINIT_ICE[teleid]:-$user${${user:#(%|/)*}:+/}$plugin}"

    local -a arr
    reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:preinit <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" plugin "$user" "$plugin" "$id_as" "${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}" preinit || \
            return $(( 10 - $? ))
    done

    if [[ $user != % && ! -d ${ZINIT[PLUGINS_DIR]}/${id_as//\//---} ]] {
        (( ${+functions[.zinit-setup-plugin-dir]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
        reply=( "$user" "$plugin" ) REPLY=github
        if (( ${+ZINIT_ICE[pack]} )) {
            if ! .zinit-get-package "$user" "$plugin" "$id_as" \
                "${ZINIT[PLUGINS_DIR]}/${id_as//\//---}" \
                "${ZINIT_ICE[pack]:-default}"
            then
                zle && { print; zle .reset-prompt; }
                return 1
            fi
            id_as="${ZINIT_ICE[id-as]:-${user}${${user:#(%|/)*}:+/}$plugin}"
        }
        user="${reply[-2]}" plugin="${reply[-1]}"
        ZINIT_ICE[teleid]="$user${${user:#(%|/)*}:+/}$plugin"
        [[ $REPLY = snippet ]] && {
            ZINIT_ICE[id-as]="${ZINIT_ICE[id-as]:-$id_as}"
            .zinit-load-snippet $plugin && return
            zle && { print; zle .reset-prompt; }
            return 1
        }
        if ! .zinit-setup-plugin-dir "$user" "$plugin" "$id_as" "$REPLY"; then
            zle && { print; zle .reset-prompt; }
            return 1
        fi
        zle && rst=1
    }

    ZINIT_SICE[$id_as]=
    .zinit-pack-ice "$id_as"

    (( ${+ZINIT_ICE[cloneonly]} )) && return 0

    .zinit-register-plugin "$id_as" "$mode" "${ZINIT_ICE[teleid]}"

    reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:\\\!atinit <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" plugin "$user" "$plugin" "$id_as" "${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}" \!atinit || \
            return $(( 10 - $? ))
    done

    [[ ${+ZINIT_ICE[atinit]} = 1 && $ZINIT_ICE[atinit] != '!'*   ]] && { local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}"; } && eval "${ZINIT_ICE[atinit]}"; ((1)); } || eval "${ZINIT_ICE[atinit]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:atinit <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" plugin "$user" "$plugin" "$id_as" "${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}" atinit || \
            return $(( 10 - $? ))
    done

    .zinit-load-plugin "$user" "$plugin" "$id_as" "$mode" "$rst"; retval=$?
    (( ${+ZINIT_ICE[notify]} == 1 )) && { [[ $retval -eq 0 || -n ${(M)ZINIT_ICE[notify]#\!} ]] && { local msg; eval "msg=\"${ZINIT_ICE[notify]#\!}\""; .zinit-deploy-message @msg "$msg" } || .zinit-deploy-message @msg "notify: Plugin not loaded / loaded with problem, the return code: $retval"; }
    (( ${+ZINIT_ICE[reset-prompt]} == 1 )) && .zinit-deploy-message @rst
    ZINIT[TIME_INDEX]=$(( ${ZINIT[TIME_INDEX]:-0} + 1 ))
    ZINIT[TIME_${ZINIT[TIME_INDEX]}_${id_as//\//---}]=$SECONDS
    ZINIT[AT_TIME_${ZINIT[TIME_INDEX]}_${id_as//\//---}]=$EPOCHREALTIME
    return $retval
} # ]]]
# FUNCTION: .zinit-load-snippet [[[
# Implements the exposed-to-user action of loading a snippet.
#
# $1 - url (can be local, absolute path)
.zinit-load-snippet() {
    typeset -F 3 SECONDS=0
    local -a opts
    zparseopts -E -D -a opts f -command || { print -r -- "Incorrect options (accepted ones: -f, --command)"; return 1; }
    local url="$1"
    integer correct retval exists
    [[ -o ksharrays ]] && correct=1

    [[ -n ${ZINIT_ICE[(i)(\!|)(sh|bash|ksh|csh)]} ]] && {
        local -a precm
        precm=(
            emulate
            ${${(M)${ZINIT_ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}:+-R}
            ${${ZINIT_ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}
            ${${ZINIT_ICE[(i)(\!|)bash]}:+-${(s: :):-o noshglob -o braceexpand -o kshglob}}
            -c
        )
    }
    # Remove leading whitespace and trailing /
    url="${${url#"${url%%[! $'\t']*}"}%/}"
    ZINIT_ICE[teleid]="$url"
    [[ ${ZINIT_ICE[as]} = null ]] && \
        ZINIT_ICE[pick]="${ZINIT_ICE[pick]:-/dev/null}"

    local local_dir dirname filename save_url="$url"

    # Allow things like $OSTYPE in the URL
    eval "url=\"$url\""

    local id_as="${ZINIT_ICE[id-as]:-$url}"

    # Set up param'' objects (parameters)
    .zinit-setup-params && \
        for REPLY ( ${reply[@]} ) {
            local ${REPLY%%=*}=${REPLY#*=} 
        }

    .zinit-pack-ice "$id_as" ""

    # Oh-My-Zsh, Prezto and manual shorthands
    [[ $url = *(OMZ::|robbyrussell*oh-my-zsh|ohmyzsh/ohmyzsh)* ]] && local ZSH="${ZINIT[SNIPPETS_DIR]}"
    (( ${+ZINIT_ICE[svn]} )) && {
        url[1-correct,5-correct]="${ZINIT_1MAP[${url[1-correct,5-correct]}]:-${url[1-correct,5-correct]}}"
    } || {
        url[1-correct,5-correct]="${ZINIT_2MAP[${url[1-correct,5-correct]}]:-${url[1-correct,5-correct]}}"
    }

    # Construct containing directory, extract final directory
    # into handy-variable $dirname
    .zinit-get-object-path snippet "$id_as"
    filename="${reply[-2]}" dirname="${reply[-2]}"
    local_dir="${reply[-3]}" exists=${reply[-1]}

    local -a arr
    local key
    reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:preinit <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" preinit || \
            return $(( 10 - $? ))
    done

    # Download or copy the file
    if [[ -n ${opts[(r)-f]} || $exists -eq 0 ]] {
        (( ${+functions[.zinit-download-snippet]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
        [[ $url = *github.com* && $url != */raw/* ]] && url="${${url/\/blob\///raw/}/\/tree\///raw/}"
        .zinit-download-snippet "$save_url" "$url" "$id_as" "$local_dir" "$dirname" "$filename"
        retval=$?
    }

    (( ${+ZINIT_ICE[cloneonly]} || retval )) && return 0

    ZINIT_SNIPPETS[$id_as]="$id_as <${${ZINIT_ICE[svn]+svn}:-single file}>"

    ZINIT[CUR_USPL2]="$id_as" ZINIT_REPORTS[$id_as]=

    reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:\\\!atinit <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" \!atinit || \
            return $(( 10 - $? ))
    done

    (( ${+ZINIT_ICE[atinit]} )) && { local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && eval "${ZINIT_ICE[atinit]}"; ((1)); } || eval "${ZINIT_ICE[atinit]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:atinit <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" atinit || \
            return $(( 10 - $? ))
    done

    local -a list
    local ZERO

    if [[ -z ${opts[(r)--command]} && ( -z ${ZINIT_ICE[as]} || ${ZINIT_ICE[as]} = null ) ]]; then
        # Source the file with compdef shadowing
        if [[ ${ZINIT[SHADOWING]} = inactive ]]; then
            # Shadowing code is inlined from .zinit-shadow-on
            (( ${+functions[compdef]} )) && ZINIT[bkp-compdef]="${functions[compdef]}" || builtin unset "ZINIT[bkp-compdef]"
            functions[compdef]=':zinit-shadow-compdef "$@";'
            ZINIT[SHADOWING]=1
        else
            (( ++ ZINIT[SHADOWING] ))
        fi

        # Add to fpath
        if [[ -d $local_dir/$dirname/functions ]] {
            [[ -z ${fpath[(r)$local_dir/$dirname/functions]} ]] && fpath+=( "$local_dir/$dirname/functions" )
            () {
                builtin setopt localoptions extendedglob
                autoload $local_dir/$dirname/functions/^([_.]*|prompt_*_setup|README*)(D-.N:t)
            }
        }

        # Source
        if (( ${+ZINIT_ICE[svn]} == 0 )) {
            [[ ${+ZINIT_ICE[pick]} = 0 ]] && list=( "$local_dir/$dirname/$filename" )
            [[ -n ${ZINIT_ICE[pick]} ]] && list=( ${(M)~ZINIT_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZINIT_ICE[pick]}(DN) )
        } else {
            if [[ -n ${ZINIT_ICE[pick]} ]]; then
                list=( ${(M)~ZINIT_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZINIT_ICE[pick]}(DN) )
            elif (( ${+ZINIT_ICE[pick]} == 0 )); then
                .zinit-find-other-matches "$local_dir/$dirname" "$filename"
                list=( ${reply[@]} )
            fi
        }

        if [[ -f ${list[1-correct]} ]] {
            ZERO="${list[1-correct]}"
            (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }
            (( 0 == retval )) && [[ $url = PZT::* || $url = https://github.com/sorin-ionescu/prezto/* ]] && zstyle ":prezto:module:${${id_as%/init.zsh}:t}" loaded 'yes'
        } else { [[ ${+ZINIT_ICE[pick]} = 1 && -z ${ZINIT_ICE[pick]} || ${ZINIT_ICE[pick]} = /dev/null ]] || { +zinit-message "Snippet not loaded ([info2]$id_as[rst])"; retval=1; } }

        [[ -n ${ZINIT_ICE[src]} ]] && { ZERO="${${(M)ZINIT_ICE[src]##/*}:-$local_dir/$dirname/${ZINIT_ICE[src]}}"; (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }; }
        [[ -n ${ZINIT_ICE[multisrc]} ]] && { local __oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; }; eval "reply=(${ZINIT_ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$local_dir/$dirname/$fname}"; (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }; done; }

        # Run the atload hooks right before atload ice
        reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:\\\!atload <->]}" )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
            "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" \!atload
        done

        # Run the functions' wrapping & tracking requests
        [[ -n ${ZINIT_ICE[wrap-track]} ]] && \
            .zinit-wrap-track-functions "$save_url" "" "$id_as"

        [[ ${ZINIT_ICE[atload][1]} = "!" ]] && { .zinit-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$local_dir/$dirname/-atload-"; local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ZINIT_ICE[atload]#\!}"; ((1)); } || eval "${ZINIT_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

        (( -- ZINIT[SHADOWING] == 0 )) && { ZINIT[SHADOWING]=inactive; builtin setopt noaliases; (( ${+ZINIT[bkp-compdef]} )) && functions[compdef]="${ZINIT[bkp-compdef]}" || unfunction compdef; (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases; }
    elif [[ -n ${opts[(r)--command]} || ${ZINIT_ICE[as]} = command ]]; then
        [[ ${+ZINIT_ICE[pick]} = 1 && -z ${ZINIT_ICE[pick]} ]] && \
            ZINIT_ICE[pick]="${id_as:t}"
        # Subversion - directory and multiple files possible
        if (( ${+ZINIT_ICE[svn]} )); then
            if [[ -n ${ZINIT_ICE[pick]} ]]; then
                list=( ${(M)~ZINIT_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZINIT_ICE[pick]}(DN) )
                [[ -n ${list[1-correct]} ]] && local xpath="${list[1-correct]:h}" xfilepath="${list[1-correct]}"
            else
                local xpath="$local_dir/$dirname"
            fi
        else
            local xpath="$local_dir/$dirname" xfilepath="$local_dir/$dirname/$filename"
            # This doesn't make sense, but users may come up with something
            [[ -n ${ZINIT_ICE[pick]} ]] && {
                list=( ${(M)~ZINIT_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZINIT_ICE[pick]}(DN) )
                [[ -n ${list[1-correct]} ]] && xpath="${list[1-correct]:h}" xfilepath="${list[1-correct]}"
            }
        fi
        [[ -n $xpath && -z ${path[(er)$xpath]} ]] && path=( "${xpath%/}" ${path[@]} )
        [[ -n $xfilepath && -f $xfilepath && ! -x "$xfilepath" ]] && command chmod a+x "$xfilepath" ${list[@]:#$xfilepath}
        [[ -n ${ZINIT_ICE[src]} || -n ${ZINIT_ICE[multisrc]} || ${ZINIT_ICE[atload][1]} = "!" ]] && {
            if [[ ${ZINIT[SHADOWING]} = inactive ]]; then
                # Shadowing code is inlined from .zinit-shadow-on
                (( ${+functions[compdef]} )) && ZINIT[bkp-compdef]="${functions[compdef]}" || builtin unset "ZINIT[bkp-compdef]"
                functions[compdef]=':zinit-shadow-compdef "$@";'
                ZINIT[SHADOWING]=1
            else
                (( ++ ZINIT[SHADOWING] ))
            fi
        }

        if [[ -n ${ZINIT_ICE[src]} ]]; then
            ZERO="${${(M)ZINIT_ICE[src]##/*}:-$local_dir/$dirname/${ZINIT_ICE[src]}}"
            (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }
        fi
        [[ -n ${ZINIT_ICE[multisrc]} ]] && { local __oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; }; eval "reply=(${ZINIT_ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$local_dir/$dirname/$fname}"; (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }; done; }

        # Run the atload hooks right before atload ice
        reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:\\\!atload <->]}" )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
            "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" \!atload
        done

        # Run the functions' wrapping & tracking requests
        [[ -n ${ZINIT_ICE[wrap-track]} ]] && \
            .zinit-wrap-track-functions "$save_url" "" "$id_as"

        [[ ${ZINIT_ICE[atload][1]} = "!" ]] && { .zinit-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$local_dir/$dirname/-atload-"; local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ZINIT_ICE[atload]#\!}"; ((1)); } || eval "${ZINIT_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

        [[ -n ${ZINIT_ICE[src]} || -n ${ZINIT_ICE[multisrc]} || ${ZINIT_ICE[atload][1]} = "!" ]] && {
            (( -- ZINIT[SHADOWING] == 0 )) && { ZINIT[SHADOWING]=inactive; builtin setopt noaliases; (( ${+ZINIT[bkp-compdef]} )) && functions[compdef]="${ZINIT[bkp-compdef]}" || unfunction compdef; (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases; }
        }
    elif [[ ${ZINIT_ICE[as]} = completion ]]; then
        ((1))
    fi

    (( ${+ZINIT_ICE[atload]} )) && [[ ${ZINIT_ICE[atload][1]} != "!" ]] && { ZERO="$local_dir/$dirname/-atload-"; local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ZINIT_ICE[atload]}"; ((1)); } || eval "${ZINIT_ICE[atload]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:atload <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" atload
    done

    (( ${+ZINIT_ICE[notify]} == 1 )) && { [[ $retval -eq 0 || -n ${(M)ZINIT_ICE[notify]#\!} ]] && { local msg; eval "msg=\"${ZINIT_ICE[notify]#\!}\""; .zinit-deploy-message @msg "$msg" } || .zinit-deploy-message @msg "notify: Plugin not loaded / loaded with problem, the return code: $retval"; }
    (( ${+ZINIT_ICE[reset-prompt]} == 1 )) && .zinit-deploy-message @rst

    ZINIT[CUR_USPL2]=
    ZINIT[TIME_INDEX]=$(( ${ZINIT[TIME_INDEX]:-0} + 1 ))
    ZINIT[TIME_${ZINIT[TIME_INDEX]}_${id_as}]=$SECONDS
    ZINIT[AT_TIME_${ZINIT[TIME_INDEX]}_${id_as}]=$EPOCHREALTIME
    return $retval
} # ]]]
# FUNCTION: .zinit-compdef-replay [[[
# Runs gathered compdef calls. This allows to run `compinit'
# after loading plugins.
.zinit-compdef-replay() {
    local quiet="$1"
    typeset -a pos

    # Check if compinit was loaded
    if [[ ${+functions[compdef]} = 0 ]]; then
        +zinit-message "Compinit isn't loaded, cannot do compdef replay"
        return 1
    fi

    # In the same order
    local cdf
    for cdf in "${ZINIT_COMPDEF_REPLAY[@]}"; do
        pos=( "${(z)cdf}" )
        # When ZINIT_COMPDEF_REPLAY empty (also when only white spaces)
        [[ ${#pos[@]} = 1 && -z ${pos[-1]} ]] && continue
        pos=( "${(Q)pos[@]}" )
        [[ $quiet = -q ]] || +zinit-message "Running compdef: [obj]${pos[*]}[rst]"
        compdef "${pos[@]}"
    done

    return 0
} # ]]]
# FUNCTION: .zinit-compdef-clear [[[
# Implements user-exposed functionality to clear gathered compdefs.
.zinit-compdef-clear() {
    local quiet="$1" count="${#ZINIT_COMPDEF_REPLAY}"
    ZINIT_COMPDEF_REPLAY=( )
    [[ $quiet = -q ]] || +zinit-message "Compdef-replay cleared (had [obj]${count}[rst] entries)"
} # ]]]
# FUNCTION: .zinit-add-report [[[
# Adds a report line for given plugin.
#
# $1 - uspl2, i.e. user/plugin
# $2, ... - the text
.zinit-add-report() {
    # Use zinit binary module if available
    [[ -n $1 ]] && { (( ${+builtins[zpmod]} && 0 )) && zpmod report-append "$1" "$2"$'\n' || ZINIT_REPORTS[$1]+="$2"$'\n'; }
    [[ ${ZINIT[DTRACE]} = 1 ]] && { (( ${+builtins[zpmod]} )) && zpmod report-append _dtrace/_dtrace "$2"$'\n' || ZINIT_REPORTS[_dtrace/_dtrace]+="$2"$'\n'; }
    return 0
} # ]]]
# FUNCTION: .zinit-load-plugin [[[
# Lower-level function for loading a plugin.
#
# $1 - user
# $2 - plugin
# $3 - mode (light or load)
.zinit-load-plugin() {
    local user="$1" plugin="$2" id_as="$3" mode="$4" correct=0 retval=0
    ZINIT[CUR_USR]="$user" ZINIT[CUR_PLUGIN]="$plugin" ZINIT[CUR_USPL2]="$id_as"
    [[ -o ksharrays ]] && correct=1

    [[ -n ${ZINIT_ICE[(i)(\!|)(sh|bash|ksh|csh)]} ]] && {
        local -a precm
        precm=(
            emulate
            ${${(M)${ZINIT_ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}:+-R}
            ${${ZINIT_ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}
            ${${ZINIT_ICE[(i)(\!|)bash]}:+-${(s: :):-o noshglob -o braceexpand -o kshglob}}
            -c
        )
    }

    [[ ${ZINIT_ICE[as]} = null ]] && \
        ZINIT_ICE[pick]="${ZINIT_ICE[pick]:-/dev/null}"

    local pbase="${${plugin:t}%(.plugin.zsh|.zsh|.git)}"
    [[ $user = % ]] && local pdir_path="$plugin" || local pdir_path="${ZINIT[PLUGINS_DIR]}/${id_as//\//---}"
    local pdir_orig="$pdir_path" key

    # Set up param'' objects (parameters)
    .zinit-setup-params && \
        for REPLY ( ${reply[@]} ) {
            local ${REPLY%%=*}=${REPLY#*=} 
        }

    if [[ ${ZINIT_ICE[as]} = command ]]; then
        [[ ${+ZINIT_ICE[pick]} = 1 && -z ${ZINIT_ICE[pick]} ]] && \
            ZINIT_ICE[pick]="${id_as:t}"
        reply=()
        if [[ -n ${ZINIT_ICE[pick]} && ${ZINIT_ICE[pick]} != /dev/null ]]; then
            reply=( ${(M)~ZINIT_ICE[pick]##/*}(DN) $pdir_path/${~ZINIT_ICE[pick]}(DN) )
            [[ -n ${reply[1-correct]} ]] && pdir_path="${reply[1-correct]:h}"
        fi
        [[ -z ${path[(er)$pdir_path]} ]] && {
            [[ $mode != light ]] && .zinit-diff-env "${ZINIT[CUR_USPL2]}" begin
            path=( "${pdir_path%/}" ${path[@]} )
            [[ $mode != light ]] && .zinit-diff-env "${ZINIT[CUR_USPL2]}" end
            .zinit-add-report "${ZINIT[CUR_USPL2]}" "$ZINIT[col-info2]$pdir_path$ZINIT[col-rst] added to \$PATH"
        }
        [[ -n ${reply[1-correct]} && ! -x ${reply[1-correct]} ]] && command chmod a+x ${reply[@]}

        [[ ${ZINIT_ICE[atinit]} = '!'* || -n ${ZINIT_ICE[src]} || -n ${ZINIT_ICE[multisrc]} || ${ZINIT_ICE[atload][1]} = "!" ]] && {
            if [[ ${ZINIT[SHADOWING]} = inactive ]]; then
                (( ${+functions[compdef]} )) && ZINIT[bkp-compdef]="${functions[compdef]}" || builtin unset "ZINIT[bkp-compdef]"
                functions[compdef]=':zinit-shadow-compdef "$@";'
                ZINIT[SHADOWING]=1
            else
                (( ++ ZINIT[SHADOWING] ))
            fi
        }

        local ZERO
        [[ $ZINIT_ICE[atinit] = '!'* ]] && { local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}"; } && eval "${ZINIT_ICE[atinit#!]}"; ((1)); } || eval "${ZINIT_ICE[atinit]#!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }
        [[ -n ${ZINIT_ICE[src]} ]] && { ZERO="${${(M)ZINIT_ICE[src]##/*}:-$pdir_orig/${ZINIT_ICE[src]}}"; (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }; }
        [[ -n ${ZINIT_ICE[multisrc]} ]] && { local __oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; }; eval "reply=(${ZINIT_ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$pdir_orig/$fname}"; (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }; done; }

        # Run the atload hooks right before atload ice
        reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:\\\!atload <->]}" )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
            "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$pdir_orig" \!atload
        done

        # Run the functions' wrapping & tracking requests
        [[ -n ${ZINIT_ICE[wrap-track]} ]] && \
            .zinit-wrap-track-functions "$user" "$plugin" "$id_as"

        [[ ${ZINIT_ICE[atload][1]} = "!" ]] && { .zinit-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$pdir_orig/-atload-"; local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; } && builtin eval "${ZINIT_ICE[atload]#\!}"; } || eval "${ZINIT_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

        [[ -n ${ZINIT_ICE[src]} || -n ${ZINIT_ICE[multisrc]} || ${ZINIT_ICE[atload][1]} = "!" ]] && {
            (( -- ZINIT[SHADOWING] == 0 )) && { ZINIT[SHADOWING]=inactive; builtin setopt noaliases; (( ${+ZINIT[bkp-compdef]} )) && functions[compdef]="${ZINIT[bkp-compdef]}" || unfunction compdef; (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases; }
        }
    elif [[ ${ZINIT_ICE[as]} = completion ]]; then
        ((1))
    else
        if [[ -n ${ZINIT_ICE[pick]} ]]; then
            [[ ${ZINIT_ICE[pick]} = /dev/null ]] && reply=( /dev/null ) || reply=( ${(M)~ZINIT_ICE[pick]##/*}(DN) $pdir_path/${~ZINIT_ICE[pick]}(DN) )
        elif [[ -e $pdir_path/$pbase.plugin.zsh ]]; then
            reply=( "$pdir_path/$pbase".plugin.zsh )
        else
            .zinit-find-other-matches "$pdir_path" "$pbase"
        fi

        #[[ ${#reply} -eq 0 ]] && return 1

        # Get first one
        local fname="${reply[1-correct]:t}"
        pdir_path="${reply[1-correct]:h}"

        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Source $fname ${${${(M)mode:#light}:+(no reporting)}:-$ZINIT[col-info2](reporting enabled)$ZINIT[col-rst]}"

        # Light and compdef mode doesn't do diffs and shadowing
        [[ $mode != light(|-b) ]] && .zinit-diff "${ZINIT[CUR_USPL2]}" begin

        .zinit-shadow-on "${mode:-load}"

        # We need some state, but user wants his for his plugins
        (( ${+ZINIT_ICE[blockf]} )) && { local -a fpath_bkp; fpath_bkp=( "${fpath[@]}" ); }
        local ZERO="$pdir_path/$fname"
        (( ${+ZINIT_ICE[aliases]} )) || builtin setopt noaliases
        [[ $ZINIT_ICE[atinit] = '!'* ]] && { local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}"; } && eval "${ZINIT_ICE[atinit]#!}"; ((1)); } || eval "${ZINIT_ICE[atinit]#1}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }
        (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }
        [[ -n ${ZINIT_ICE[src]} ]] && { ZERO="${${(M)ZINIT_ICE[src]##/*}:-$pdir_orig/${ZINIT_ICE[src]}}"; (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }; }
        [[ -n ${ZINIT_ICE[multisrc]} ]] && { local __oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; }; eval "reply=(${ZINIT_ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$pdir_orig/$fname}"; (( ${+ZINIT_ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); } done; }

        # Run the atload hooks right before atload ice
        reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:\\\!atload <->]}" )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
            "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$pdir_orig" \!atload
        done

        # Run the functions' wrapping & tracking requests
        [[ -n ${ZINIT_ICE[wrap-track]} ]] && \
            .zinit-wrap-track-functions "$user" "$plugin" "$id_as"

        [[ ${ZINIT_ICE[atload][1]} = "!" ]] && { .zinit-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$pdir_orig/-atload-"; local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; } && builtin eval "${ZINIT_ICE[atload]#\!}"; ((1)); } || eval "${ZINIT_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }
        (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases
        (( ${+ZINIT_ICE[blockf]} )) && { fpath=( "${fpath_bkp[@]}" ); }

        .zinit-shadow-off "${mode:-load}"

        [[ $mode != light(|-b) ]] && .zinit-diff "${ZINIT[CUR_USPL2]}" end
    fi

    [[ ${+ZINIT_ICE[atload]} = 1 && ${ZINIT_ICE[atload][1]} != "!" ]] && { ZERO="$pdir_orig/-atload-"; local __oldcd="$PWD"; (( ${+ZINIT_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; } && builtin eval "${ZINIT_ICE[atload]}"; ((1)); } || eval "${ZINIT_ICE[atload]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    reply=( "${(@on)ZINIT_EXTS[(I)z-annex hook:atload <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$pdir_orig" atload
    done

    # Mark no load is in progress
    ZINIT[CUR_USR]= ZINIT[CUR_PLUGIN]= ZINIT[CUR_USPL2]=

    (( $5 )) && { print; zle .reset-prompt; }
    return $retval
} # ]]]
# FUNCTION: .zinit-add-fpath [[[
.zinit-add-fpath() {
    [[ $1 = (-f|--front) ]] && { shift; integer front=1; }
    .zinit-any-to-user-plugin "$1" ""
    local id_as="$1" add_dir="$2" user="${reply[-2]}" plugin="${reply[-1]}"
    (( front )) && \
        fpath[1,0]=${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}${add_dir:+/$add_dir} || \
        fpath+=(
            ${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}${add_dir:+/$add_dir}
        )
}
# ]]]
# FUNCTION: .zinit-run [[[
# Run code inside plugin's folder
# It uses the `correct' parameter from upper's scope zinit()
.zinit-run() {
    if [[ $1 = (-l|--last) ]]; then
        { set -- "${ZINIT[last-run-plugin]:-$(<${ZINIT[BIN_DIR]}/last-run-object.txt)}" "${@[2-correct,-1]}"; } &>/dev/null
        [[ -z $1 ]] && { +zinit-message "[error]Error: No last plugin available, please specify as the first argument.[rst]"; return 1; }
    else
        integer __nolast=1
    fi
    .zinit-any-to-user-plugin "$1" ""
    local __id_as="$1" __user="${reply[-2]}" __plugin="${reply[-1]}" __oldpwd="$PWD"
    () {
        emulate -LR zsh
        builtin cd &>/dev/null -q ${${${(M)__user:#%}:+$__plugin}:-${ZINIT[PLUGINS_DIR]}/${__id_as//\//---}} || {
            .zinit-get-object-path snippet "$__id_as"
            builtin cd &>/dev/null -q ${reply[-3]}/${reply[-2]}
        }
    }
    if (( $? == 0 )); then
        (( __nolast )) && { print -r "$1" >! ${ZINIT[BIN_DIR]}/last-run-object.txt; }
        ZINIT[last-run-plugin]="$1"
        eval "${@[2-correct,-1]}"
        () { setopt localoptions noautopushd; builtin cd -q "$__oldpwd"; }
    else
        +zinit-message "[error]Error: no such plugin or snippet.[rst]"
    fi
}
# ]]]

#
# Dtrace
#

# FUNCTION: .zinit-debug-start [[[
# Starts Dtrace, i.e. session tracking for changes in Zsh state.
.zinit-debug-start() {
    if [[ ${ZINIT[DTRACE]} = 1 ]]; then
        +zinit-message "[error]Dtrace is already active, stop it first with \`dstop'[rst]"
        return 1
    fi

    ZINIT[DTRACE]=1

    .zinit-diff _dtrace/_dtrace begin

    # Full shadowing on
    .zinit-shadow-on dtrace
} # ]]]
# FUNCTION: .zinit-debug-stop [[[
# Stops Dtrace, i.e. session tracking for changes in Zsh state.
.zinit-debug-stop() {
    ZINIT[DTRACE]=0

    # Shadowing fully off
    .zinit-shadow-off dtrace

    # Gather end data now, for diffing later
    .zinit-diff _dtrace/_dtrace end
} # ]]]
# FUNCTION: .zinit-clear-debug-report [[[
# Forgets dtrace repport gathered up to this moment.
.zinit-clear-debug-report() {
    .zinit-clear-report-for _dtrace/_dtrace
} # ]]]
# FUNCTION: .zinit-debug-unload [[[
# Reverts changes detected by dtrace run.
.zinit-debug-unload() {
    if [[ ${ZINIT[DTRACE]} = 1 ]]; then
        +zinit-message "[error]Dtrace is still active, stop it first with \`dstop'[rst]"
    else
        .zinit-unload _dtrace _dtrace
    fi
} # ]]]

#
# Ice support
#

# FUNCTION: .zinit-ice [[[
# Parses ICE specification, puts the result into ZINIT_ICE global hash.
# The ice-spec is valid for next command only (i.e. it "melts"), but
# it can then stick to plugin and activate e.g. at update.
.zinit-ice() {
    builtin setopt localoptions noksharrays extendedglob warncreateglobal typesetsilent noshortloops
    integer retval
    local bit exts="${~ZINIT_EXTS[ice-mods]//\'\'/}"
    for bit; do
        [[ $bit = (#b)(--|)(${~ZINIT[ice-list]}${~exts})(*) ]] && \
            ZINIT_ICES[${match[2]}]+="${ZINIT_ICES[${match[2]}]:+;}${match[3]#(:|=)}" || \
            break
        retval+=1
    done
    [[ ${ZINIT_ICES[as]} = program ]] && ZINIT_ICES[as]=command
    [[ -n ${ZINIT_ICES[on-update-of]} ]] && ZINIT_ICES[subscribe]="${ZINIT_ICES[subscribe]:-${ZINIT_ICES[on-update-of]}}"
    [[ -n ${ZINIT_ICES[pick]} ]] && ZINIT_ICES[pick]="${ZINIT_ICES[pick]//\$ZPFX/${ZPFX%/}}"
    return $retval
} # ]]]
# FUNCTION: .zinit-pack-ice [[[
# Remembers all ice-mods, assigns them to concrete plugin. Ice spec
# is in general forgotten for second-next command (that's why it's
# called "ice" - it melts), however they glue to the object (plugin
# or snippet) mentioned in the next command – for later use with e.g.
# `zinit update ...'
.zinit-pack-ice() {
    ZINIT_SICE[$1${1:+${2:+/}}$2]+="${(j: :)${(qkv)ZINIT_ICE[@]}} "
    ZINIT_SICE[$1${1:+${2:+/}}$2]="${ZINIT_SICE[$1${1:+${2:+/}}$2]# }"
    return 0
} # ]]]
# FUNCTION: .zinit-service [[[
# Handles given service, i.e. obtains lock, runs it, or waits if no lock
#
# $1 - type "p" or "s" (plugin or snippet)
# $2 - mode - for plugin (light or load)
# $3 - id - URL or plugin ID or alias name (from id-as'')
.zinit-service() {
    emulate -LR zsh
    setopt extendedglob warncreateglobal typesetsilent noshortloops

    local __tpe="$1" __mode="$2" __id="$3" __fle="${ZINIT[SERVICES_DIR]}/${ZINIT_ICE[service]}.lock" __fd __cmd __tmp __lckd __strd=0
    { builtin print -n >! "$__fle"; } 2>/dev/null 1>&2
    [[ ! -e ${__fle:r}.fifo ]] && command mkfifo "${__fle:r}.fifo" 2>/dev/null 1>&2
    [[ ! -e ${__fle:r}.fifo2 ]] && command mkfifo "${__fle:r}.fifo2" 2>/dev/null 1>&2

    typeset -g ZSRV_WORK_DIR="${ZINIT[SERVICES_DIR]}" ZSRV_ID="${ZINIT_ICE[service]}"  # should be also set by other p-m

    while (( 1 )); do
        (
            while (( 1 )); do
                [[ ! -f ${__fle:r}.stop ]] && if (( __lckd )) || zsystem 2>/dev/null 1>&2 flock -t 1 -f __fd -e $__fle; then
                    __lckd=1
                    if (( ! __strd )) || [[ $__cmd = RESTART ]]; then
                        [[ $__tpe = p ]] && { __strd=1; .zinit-load "$__id" "" "$__mode"; }
                        [[ $__tpe = s ]] && { __strd=1; .zinit-load-snippet "$__id" ""; }
                    fi
                    __cmd=
                    while (( 1 )); do builtin read -t 32767 __cmd <>"${__fle:r}.fifo" && break; done
                else
                    return 0
                fi

                [[ $__cmd = (#i)NEXT ]] && { kill -TERM "$ZSRV_PID"; builtin read -t 2 __tmp <>"${__fle:r}.fifo2"; kill -HUP "$ZSRV_PID"; exec {__fd}>&-; __lckd=0; __strd=0; builtin read -t 10 __tmp <>"${__fle:r}.fifo2"; }
                [[ $__cmd = (#i)STOP ]] && { kill -TERM "$ZSRV_PID"; builtin read -t 2 __tmp <>"${__fle:r}.fifo2"; kill -HUP "$ZSRV_PID"; __strd=0; builtin print >! "${__fle:r}.stop"; }
                [[ $__cmd = (#i)QUIT ]] && { kill -HUP ${sysparams[pid]}; return 1; }
                [[ $__cmd != (#i)RESTART ]] && { __cmd=; builtin read -t 1 __tmp <>"${__fle:r}.fifo2"; }
            done
        ) || break
        builtin read -t 1 __tmp <>"${__fle:r}.fifo2"
    done >>! "$ZSRV_WORK_DIR/$ZSRV_ID".log 2>&1
}
# ]]]
# FUNCTION: .zinit-run-task [[[
# A backend, worker function of .zinit-scheduler. It obtains the tasks
# index and a few of its properties (like the type: plugin, snippet,
# service plugin, service snippet) and executes it first checking for
# additional conditions (like non-numeric wait'' ice).
#
# $1 - the pass number, either 1st or 2nd pass
# $2 - the time assigned to the task
# $3 - type: plugin, snippet, service plugin, service snippet
# $4 - task's index in the ZINIT[WAIT_ICE_...] fields
# $5 - mode: load or light
# $6 - the plugin-spec or snippet URL or alias name (from id-as'')
.zinit-run-task() {
    local __pass="$1" __t="$2" __tpe="$3" __idx="$4" __mode="$5" __id="${(Q)6}" __opt="${(Q)7}" __action __s=1 __retval=0

    local -A ZINIT_ICE
    ZINIT_ICE=( "${(@Q)${(z@)ZINIT[WAIT_ICE_${__idx}]}}" )

    local __id_as=${ZINIT_ICE[id-as]:-$__id}

    if [[ $__pass = 1 && ${${ZINIT_ICE[wait]#\!}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)} = <-> ]]; then
        __action="${(M)ZINIT_ICE[wait]#\!}load"
    elif [[ $__pass = 1 && -n ${ZINIT_ICE[wait]#\!} ]] && { eval "${ZINIT_ICE[wait]#\!}" || [[ $(( __s=0 )) = 1 ]]; }; then
        __action="${(M)ZINIT_ICE[wait]#\!}load"
    elif [[ -n ${ZINIT_ICE[load]#\!} && -n $(( __s=0 )) && $__pass = 3 && -z ${ZINIT_REGISTERED_PLUGINS[(r)$__id_as]} ]] && eval "${ZINIT_ICE[load]#\!}"; then
        __action="${(M)ZINIT_ICE[load]#\!}load"
    elif [[ -n ${ZINIT_ICE[unload]#\!} && -n $(( __s=0 )) && $__pass = 2 && -n ${ZINIT_REGISTERED_PLUGINS[(r)$__id_as]} ]] && eval "${ZINIT_ICE[unload]#\!}"; then
        __action="${(M)ZINIT_ICE[unload]#\!}remove"
    elif [[ -n ${ZINIT_ICE[subscribe]#\!} && -n $(( __s=0 )) && $__pass = 3 ]] && \
        { local -a fts_arr
          eval "fts_arr=( ${ZINIT_ICE[subscribe]}(DNms-$(( EPOCHSECONDS -
                 ZINIT[fts-${ZINIT_ICE[subscribe]}] ))) ); (( \${#fts_arr} ))" && \
             { ZINIT[fts-${ZINIT_ICE[subscribe]}]="$EPOCHSECONDS"; __s=${+ZINIT_ICE[once]}; } || \
             (( 0 ))
        }
    then
        __action="${(M)ZINIT_ICE[subscribe]#\!}load"
    fi

    if [[ $__action = *load ]]; then
        if [[ $__tpe = p ]]; then
            .zinit-load "$__id" "" "$__mode"; (( __retval += $? ))
        elif [[ $__tpe = s ]]; then
            .zinit-load-snippet $__opt "${(@)=__id}"; (( __retval += $? ))
        elif [[ $__tpe = p1 || $__tpe = s1 ]]; then
            zpty -b "${__id//\//:} / ${ZINIT_ICE[service]}" '.zinit-service '"${(M)__tpe#?}"' "$__mode" "$__id"'
        fi
        (( ${+ZINIT_ICE[silent]} == 0 && ${+ZINIT_ICE[lucid]} == 0 && __retval == 0 )) && zle && zle -M "Loaded $__id"
    elif [[ $__action = *remove ]]; then
        (( ${+functions[.zinit-confirm]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh"
        [[ $__tpe = p ]] && .zinit-unload "$__id_as" "" -q
        (( ${+ZINIT_ICE[silent]} == 0 && ${+ZINIT_ICE[lucid]} == 0 && __retval == 0 )) && zle && zle -M "Unloaded $__id_as"
    fi

    [[ ${REPLY::=$__action} = \!* ]] && zle && zle .reset-prompt

    return $__s
}
# ]]]
# FUNCTION: .zinit-deploy-message [[[
# Deploys a sub-prompt message to be displayed OR a `zle
# .reset-prompt' call to be invoked
.zinit-deploy-message() {
    [[ $1 = <-> && ( ${#} = 1 || ( $2 = (hup|nval|err) && ${#} = 2 ) ) ]] && { zle && {
            local alltext text IFS=$'\n' nl=$'\n'
            repeat 25; do read -r -u"$1" text; alltext+="${text:+$text$nl}"; done
            [[ $alltext = @rst$nl ]] && { builtin zle reset-prompt; ((1)); } || \
                { [[ -n $alltext ]] && builtin zle -M "$alltext"; }
        }
        builtin zle -F "$1"; exec {1}<&-
        return 0
    }
    local THEFD=13371337 hasw
    # The expansion is: if there is @sleep: pfx, then use what's after
    # it, otherwise substitute 0
    exec {THEFD} < <(LANG=C sleep $(( 0.01 + ${${${(M)1#@sleep:}:+${1#@sleep:}}:-0} )); print -r -- ${1:#(@msg|@sleep:*)} "${@[2,-1]}"; )
    command true # workaround a Zsh bug, see: http://www.zsh.org/mla/workers/2018/msg00966.html
    builtin zle -F "$THEFD" .zinit-deploy-message
}
# ]]]

# FUNCTION: .zinit-submit-turbo [[[
# If `zinit load`, `zinit light` or `zinit snippet`  will be
# preceded with `wait', `load', `unload' or `on-update-of`/`subscribe'
# ice-mods then the plugin or snipped is to be loaded in turbo-mode,
# and this function adds it to internal data structures, so that
# @zinit-scheduler can run (load, unload) this as a task.
.zinit-submit-turbo() {
    local tpe="$1" mode="$2" opt_uspl2="$3" opt_plugin="$4"

    ZINIT_ICE[wait]="${ZINIT_ICE[wait]%%.[0-9]##}"
    ZINIT[WAIT_IDX]=$(( ${ZINIT[WAIT_IDX]:-0} + 1 ))
    ZINIT[WAIT_ICE_${ZINIT[WAIT_IDX]}]="${(j: :)${(qkv)ZINIT_ICE[@]}}"
    ZINIT[fts-${ZINIT_ICE[subscribe]}]="${ZINIT_ICE[subscribe]:+$EPOCHSECONDS}"

    [[ $tpe = s* ]] && \
        local id="${${opt_plugin:+$opt_plugin}:-$opt_uspl2}" || \
        local id="${${opt_plugin:+$opt_uspl2${${opt_uspl2:#%*}:+/}$opt_plugin}:-$opt_uspl2}"

    if [[ ${${ZINIT_ICE[wait]}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)} = (\!|.|)<-> ]]; then
        ZINIT_TASKS+=( "$EPOCHSECONDS+${${ZINIT_ICE[wait]#(\!|.)}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)}+${${${(M)ZINIT_ICE[wait]%a}:+1}:-${${${(M)ZINIT_ICE[wait]%b}:+2}:-${${${(M)ZINIT_ICE[wait]%c}:+3}:-1}}} $tpe ${ZINIT[WAIT_IDX]} ${mode:-_} ${(q)id} ${opt_plugin:+${(q)opt_uspl2}}" )
    elif [[ -n ${ZINIT_ICE[wait]}${ZINIT_ICE[load]}${ZINIT_ICE[unload]}${ZINIT_ICE[subscribe]} ]]; then
        ZINIT_TASKS+=( "${${ZINIT_ICE[wait]:+0}:-1}+0+1 $tpe ${ZINIT[WAIT_IDX]} ${mode:-_} ${(q)id} ${opt_plugin:+${(q)opt_uspl2}}" )
    fi
}
# ]]]
# FUNCTION: -zinit_scheduler_add_sh [[[
# Copies task into ZINIT_RUN array, called when a task timeouts.
# A small function ran from pattern in /-substitution as a math
# function.
-zinit_scheduler_add_sh() {
    local idx="$1" in_wait="$__ar2" in_abc="$__ar3" ver_wait="$__ar4" ver_abc="$__ar5"
    if [[ ( $in_wait = $ver_wait || $in_wait -ge 4 ) && $in_abc = $ver_abc ]]; then
        ZINIT_RUN+=( "${ZINIT_TASKS[$idx]}" )
        return 1
    else
        return $idx
    fi
}
# ]]]
# FUNCTION: @zinit-scheduler [[[
# Searches for timeout tasks, executes them. There's an array of tasks
# waiting for execution, this scheduler manages them, detects which ones
# should be run at current moment, decides to remove (or not) them from
# the array after execution.
#
# $1 - if "following", then it is non-first (second and more)
#      invocation of the scheduler; this results in chain of `sched'
#      invocations that results in repetitive @zinit-scheduler activity
#
#      if "burst", then all tasks are marked timeout and executed one
#      by one; this is handy if e.g. a docker image starts up and
#      needs to install all turbo-mode plugins without any hesitation
#      (delay), i.e. "burst" allows to run package installations from
#      script, not from prompt
#
@zinit-scheduler() {
    integer __ret="${${ZINIT[lro-data]%:*}##*:}"
    # lro stands for lastarg-retval-option
    [[ $1 = following ]] && sched +1 'ZINIT[lro-data]="$_:$?:${options[printexitvalue]}"; @zinit-scheduler following "${ZINIT[lro-data]%:*:*}"'
    [[ -n $1 && $1 != (following*|burst) ]] && { local THEFD="$1"; zle -F "$THEFD"; exec {THEFD}<&-; }
    [[ $1 = burst ]] && local -h EPOCHSECONDS=$(( EPOCHSECONDS+10000 ))
    ZINIT[START_TIME]="${ZINIT[START_TIME]:-$EPOCHREALTIME}"

    integer __t=EPOCHSECONDS __i correct
    local -a match mbegin mend reply
    local REPLY AFD

    [[ -o ksharrays ]] && correct=1

    if [[ -n $1 ]] {
        if [[ ${#ZINIT_RUN} -le 1 || $1 = following ]]  {
            () {
                builtin emulate -L zsh
                builtin setopt extendedglob
                # Example entry:
                # 1531252764+2+1 p 18 light zdharma/zsh-diff-so-fancy
                #
                # This either doesn't change ZINIT_TASKS entry - when
                # __i is used in the ternary expression, or replaces
                # an entry with "<no-data>", i.e. ZINIT_TASKS[1] entry.
                integer __idx1 __idx2
                local __ar2 __ar3 __ar4 __ar5
                for (( __idx1 = 0; __idx1 <= 4; __idx1 ++ )) {
                    for (( __idx2 = 1; __idx2 <= (__idx >= 4 ? 1 : 3); __idx2 ++ )) {
                        # The following substitution could be just (well, 'just'..) this:
                        #
                        # ZINIT_TASKS=( ${ZINIT_TASKS[@]/(#b)([0-9]##)+([0-9]##)+([1-3])(*)/
                        # ${ZINIT_TASKS[$(( (${match[1]}+${match[2]}) <= $__t ?
                        # zinit_scheduler_add(__i++, ${match[2]},
                        # ${(M)match[3]%[1-3]}, __idx1, __idx2) : __i++ ))]}} )
                        #
                        # However, there's a severe bug in Zsh <= 5.3.1 - use of the period
                        # (,) is impossible inside ${..//$arr[$(( ... ))]}.
                        __i=2

                        ZINIT_TASKS=( ${ZINIT_TASKS[@]/(#b)([0-9]##)+([0-9]##)+([1-3])(*)/${ZINIT_TASKS[
                        $(( (__ar2=${match[2]}+1) ? (
                            (__ar3=${(M)match[3]%[1-3]}) ? (
                            (__ar4=__idx1+1) ? (
                            (__ar5=__idx2) ? (
                (${match[1]}+${match[2]}) <= $__t ?
                zinit_scheduler_add(__i++) : __i++ )
                            : 1 )
                            : 1 )
                            : 1 )
                            : 1  ))]}} )
                        ZINIT_TASKS=( "<no-data>" ${ZINIT_TASKS[@]:#<no-data>} )
                    }
                }
            }
        }
    } else {
        add-zsh-hook -d -- precmd @zinit-scheduler
        add-zsh-hook -- chpwd @zinit-scheduler
        () {
            builtin emulate -L zsh
            builtin setopt extendedglob
            # No "+" in this pattern, it will match only "1531252764"
            # in "1531252764+2" and replace it with current time
            ZINIT_TASKS=( ${ZINIT_TASKS[@]/(#b)([0-9]##)(*)/$(( ${match[1]} <= 1 ? ${match[1]} : __t ))${match[2]}} )
        }
        # There's a bug in Zsh: first sched call would not be issued
        # until a key-press, if "sched +1 ..." would be called inside
        # zle -F handler. So it's done here, in precmd-handle code.
        sched +1 'ZINIT[lro-data]="$_:$?:${options[printexitvalue]}"; @zinit-scheduler following ${ZINIT[lro-data]%:*:*}'

        AFD=13371337 # for older Zsh + noclobber option
        exec {AFD}< <(LANG=C command sleep 0.002; builtin print run;)
	command true # workaround a Zsh bug, see: http://www.zsh.org/mla/workers/2018/msg00966.html
        zle -F "$AFD" @zinit-scheduler
    }

    local __task __idx=0 __count=0 __idx2
    # All wait'' objects
    for __task ( "${ZINIT_RUN[@]}" ) {
        .zinit-run-task 1 "${(@z)__task}" && ZINIT_TASKS+=( "$__task" )
        if [[ $(( ++__idx, __count += ${${REPLY:+1}:-0} )) -gt 0 && $1 != burst ]] {
            AFD=13371337 # for older Zsh + noclobber option
            exec {AFD}< <(LANG=C command sleep 0.0002; builtin print run;)
            command true
            # The $? and $_ will be left unchanged automatically by Zsh
            zle -F "$AFD" @zinit-scheduler
            break
        }
    }
    # All unload'' objects
    for (( __idx2=1; __idx2 <= __idx; ++ __idx2 )) {
        .zinit-run-task 2 "${(@z)ZINIT_RUN[__idx2-correct]}"
    }
    # All load'' & subscribe'' objects
    for (( __idx2=1; __idx2 <= __idx; ++ __idx2 )) {
        .zinit-run-task 3 "${(@z)ZINIT_RUN[__idx2-correct]}"
    }
    ZINIT_RUN[1-correct,__idx-correct]=()

    [[ ${ZINIT[lro-data]##*:} = on ]] && return 0 || return $__ret
}
# ]]]
# FUNCTION: +zinit-message [[[
+zinit-message() {
    builtin emulate -LR zsh -o extendedglob 
    [[ $1 = -n ]] && { local n="-n"; shift }
    local msg=${(j: :)${@//(#b)\[([^\]]##)\]/${ZINIT[col-$match[1]]-\[$match[1]\]}}}
    builtin print -Pr $n -- $msg
}
# ]]]
# FUNCTION: .zinit-setup-params [[[
.zinit-setup-params() {
    emulate -LR zsh -o extendedglob
    local -a params param_to_value
    params=( ${(s.;.)ZINIT_ICE[param]} ) reply=( )
    local param
    for param ( ${params[@]} ) {
        param_to_value=( "${param%%(-\>|→)*}" "${${(MS)param##*(-\>|→)}:+${param##*(-\>|→)}}" )
        param_to_value=( "${param_to_value[@]//((#s)[[:space:]]##|[[:space:]]##(#e))/}" )
        reply+=( "${param_to_value[1]}=${param_to_value[2]}" )
    }
    (( ${#params} )) && return 0 || return 2
}
# ]]]

#
# Exposed functions
#

# FUNCTION: zinit [[[
# Main function directly exposed to user, obtains subcommand and its
# arguments, has completion.
zinit() {
    local -A ZINIT_ICE
    ZINIT_ICE=( "${(kv)ZINIT_ICES[@]}" )
    ZINIT_ICES=()

    integer retval=0 correct=0
    local -a match mbegin mend reply
    local MATCH REPLY __q="\`" __q2="'"; integer MBEGIN MEND
                

    [[ -o ksharrays ]] && correct=1

    local -A opt_map ICE_OPTS
    opt_map=(
       -q         opt_-q,--quiet
       --quiet    opt_-q,--quiet
       -r         opt_-r,--reset
       --reset    opt_-r,--reset
       --all      opt_--all
       --clean    opt_--clean
       --yes      opt_-y,--yes
       -y         opt_-y,--yes
       -f         opt_-f,--force
       --force    opt_-f,--force
       -p         opt_-p,--parallel
       --parallel opt_-p,--parallel
    )


    reply=( ${ZINIT_EXTS[(I)z-annex subcommand:*]} )

    [[ $1 != (-h|--help|help|man|self-update|times|zstatus|load|light|unload|snippet|ls|ice|\
update|status|report|delete|loaded|list|cd|create|edit|glance|stress|changes|recently|clist|\
completions|cclear|cdisable|cenable|creinstall|cuninstall|csearch|compinit|dtrace|dstart|dstop|\
dunload|dreport|dclear|compile|uncompile|compiled|cdlist|cdreplay|cdclear|srv|recall|\
env-whitelist|bindkeys|module|add-fpath|fpath|run${reply:+|${(~j:|:)"${reply[@]#z-annex subcommand:}"}}) || $1 = (load|light|snippet) ]] && \
    {
        integer error
        if [[ $1 = (load|light|snippet) ]] {
            integer  __is_snippet
            # Classic syntax -> simulate a call through the for-syntax
            () {
                setopt localoptions extendedglob
                : ${@[@]//(#b)([ $'\t']##|(#s))(-b|--command|-f)([ $'\t']##|(#e))/${ICE_OPTS[${match[2]}]::=1}}
            } "$@"
            set -- "${@[@]:#(-b|--command|-f)}"
            [[ $1 = light && -z ${ICE_OPTS[(I)-b]} ]] && ZINIT_ICE[light-mode]=
            [[ $1 = snippet ]] && ZINIT_ICE[is-snippet]= || __is_snippet=-1
            shift

            ZINIT_ICES=( "${(kv)ZINIT_ICE[@]}" )
            ZINIT_ICE=()
            1="${1:+@}${1#@}${2:+/$2}"
            (( $# > 1 )) && { shift -p $(( $# - 1 )); }
            [[ -z $1 ]] && {
               +zinit-message "Argument needed, try: [obj]help[rst]."
               return 1
            }
        } else {
            .zinit-ice "$@"
            integer retval=$?
            local last_ice=${@[retval]}
            shift $retval
            if [[ $# -gt 0 && $1 != for ]] {
                +zinit-message "[error]Unknown command or ice: ${__q}[obj]${1}[error]'" \
                    "(use ${__q}[info2]help[error]' to get usage information).[rst]"
                return 1
            } elif (( $# == 0 )) {
                error=1
            } else {
                shift
            }
        }
        integer __retval __had_wait
        if (( $# )) {
            local -a __ices
            __ices=( "${(kv)ZINIT_ICES[@]}" )
            ZINIT_ICES=()
            while (( $# )) {
                .zinit-ice "$@"
                integer retval=$?
                local last_ice=${@[retval]}
                shift $retval
                [[ -z ${ZINIT_ICES[subscribe]} ]] && unset 'ZINIT_ICES[subscribe]'
                if [[ -n $1 ]] {
                    ZINIT_ICE=( "${__ices[@]}" "${(kv)ZINIT_ICES[@]}" )
                    ZINIT_ICES=()

                    (( ${+ZINIT_ICE[pack]} )) && {
                        __had_wait=${+ZINIT_ICE[wait]}
                        .zinit-load-ices "${1#@}"
                        [[ -z ${ZINIT_ICE[wait]} && $__had_wait == 0 ]] && \
                            unset 'ZINIT_ICE[wait]'
                    }

                    [[ ${ZINIT_ICE[id-as]} = auto ]] && ZINIT_ICE[id-as]="${1:t}"

                    integer  __is_snippet=${${(M)__is_snippet:#-1}:-0}
                    () {
                        setopt localoptions extendedglob
                        if [[ $__is_snippet -ge 0 && ( -n ${ZINIT_ICE[is-snippet]+1} || ${1#@} = ((#i)(http(s|)|ftp(s|)):/|((OMZ|PZT)::))* ) ]] {
                            __is_snippet=1
                        }
                    } "$@"

                    if [[ -n ${ZINIT_ICE[trigger-load]} || \
                          ( ${+ZINIT_ICE[wait]} == 1 &&
                              ${ZINIT_ICE[wait]} = (\!|)(<->(a|b|c|)|) )
                       ]] && (( !ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]
                    )) {
                        if (( __is_snippet > 0 )) {
                            .zinit-get-object-path snippet "${${1#@}%%(///|//|/)}"
                        } else {
                            .zinit-get-object-path plugin "${${${1#@}#https://github.com/}%%(///|//|/)}"
                        }
                    } else {
                        reply=( 1 )
                    }

                    if [[ ${reply[-1]} -eq 1 && -n ${ZINIT_ICE[trigger-load]} ]] {
                        () {
                            setopt localoptions extendedglob
                            local mode
                            (( __is_snippet > 0 )) && mode=snippet || mode="${${${ZINIT_ICE[light-mode]+light}}:-load}"
                            for MATCH ( ${(s.;.)ZINIT_ICE[trigger-load]} ) {
                                eval "${MATCH#!}() {
                                    ${${(M)MATCH#!}:+unset -f ${MATCH#!}}
                                    local a b; local -a ices
                                    # The wait'' ice is filtered-out
                                    for a b ( ${(qqkv@)${(kv@)ZINIT_ICE[(I)^(trigger-load|wait|light-mode)]}} ) {
                                        ices+=( \"\$a\$b\" )
                                    }
                                    zinit ice \${ices[@]}; zinit $mode ${(qqq)${1#@}}
                                    ${${(M)MATCH#!}:+# Forward the call
                                    eval ${MATCH#!} \$@}
                                }"
                            }
                        } "$@"
                        __retval+=$?
                        (( $# )) && shift
                        continue
                    }

                    (( ${+ZINIT_ICE[if]} )) && { eval "${ZINIT_ICE[if]}" || { (( $# )) && shift; continue; }; }
                    (( ${+ZINIT_ICE[has]} )) && { (( ${+commands[${ZINIT_ICE[has]}]} )) || { (( $# )) && shift; continue; }; }

                    ZINIT_ICE[wait]="${${(M)${+ZINIT_ICE[wait]}:#1}:+${(M)ZINIT_ICE[wait]#!}${${ZINIT_ICE[wait]#!}:-0}}"
                    if [[ ( ${reply[-1]} = 1 && ${ZINIT_ICE[wait]} = (\!|)<->(a|b|c|) ) || \
                        ( -n ${ZINIT_ICE[wait]} && ${ZINIT_ICE[wait]} != (\!|)<->(a|b|c|) ) || \
                        -n ${ZINIT_ICE[load]}${ZINIT_ICE[unload]}${ZINIT_ICE[service]}${ZINIT_ICE[subscribe]}
                    ]] {
                        ZINIT_ICE[wait]="${ZINIT_ICE[wait]:-${ZINIT_ICE[service]:+0}}"
                        if (( __is_snippet > 0 )); then
                            ZINIT_SICE[${${1#@}%%(///|//|/)}]=
                            .zinit-submit-turbo s${ZINIT_ICE[service]:+1} "" \
                                "${${1#@}%%(///|//|/)}" \
                                "${(k)ICE_OPTS[*]}"
                        else
                            ZINIT_SICE[${${${1#@}#https://github.com/}%%(///|//|/)}]=
                            .zinit-submit-turbo p${ZINIT_ICE[service]:+1} \
                                "${${${ZINIT_ICE[light-mode]+light}}:-load}" \
                                "${${${1#@}#https://github.com/}%%(///|//|/)}" ""
                        fi
                        __retval+=$?
                    } else {
                        if (( __is_snippet > 0 )); then
                            .zinit-load-snippet ${(k)ICE_OPTS[@]} "${${1#@}%%(///|//|/)}"
                        else
                            .zinit-load "${${${1#@}#https://github.com/}%%(///|//|/)}" "" \
                                "${${ZINIT_ICE[light-mode]+light}:-${ICE_OPTS[(I)-b]:+light-b}}"
                        fi
                        __retval+=$? __is_snippet=0
                    }
                } else {
                    error=1
                }
                (( $# )) && shift
            }
        } else {
            error=1
        }
        
        if (( error )) {
            () {
                emulate -LR zsh -o extendedglob
                +zinit-message -n "[error]Error: No plugin or snippet ID given"
                if [[ -n $last_ice ]] {
                    +zinit-message "(the last recognized ice was: [obj]"\
"${last_ice/(#m)(${~ZINIT[ice-list]})/[obj]$MATCH${__q2}[file]}[obj]'[error]).
You can try to prepend ${__q}[obj]@[error]' if the last ice is in fact a plugin.[rst]"
                } else {
                    +zinit-message ".[rst]"
                }
            }
            return 2
       } elif (( ! $# )) {
           return 2
       }
    }

    case "$1" in
       (ice)
           shift
           .zinit-ice "$@"
           ;;
       (cdreplay)
           .zinit-compdef-replay "$2"; retval=$?
           ;;
       (cdclear)
           .zinit-compdef-clear "$2"
           ;;
       (add-fpath|fpath)
           .zinit-add-fpath "${@[2-correct,-1]}"
           ;;
       (run)
           .zinit-run "${@[2-correct,-1]}"
           ;;
       (dstart|dtrace)
           .zinit-debug-start
           ;;
       (dstop)
           .zinit-debug-stop
           ;;
       (man)
           man "${ZINIT[BIN_DIR]}/doc/zinit.1"
           ;;
       (env-whitelist)
           shift
           [[ $1 = -v ]] && { shift; local verbose=1; }
           [[ $1 = -h ]] && { shift; +zinit-message "[info2]Usage:[rst] zinit env-whitelist [-v] VAR1 ...\nSaves names (also patterns) of parameters left unchanged during an unload. -v - verbose."; }
           (( $# == 0 )) && {
               ZINIT[ENV-WHITELIST]=
               (( verbose )) && +zinit-message "Cleared parameter whitelist"
           } || {
               ZINIT[ENV-WHITELIST]+="${(j: :)${(q-kv)@}} "
               (( verbose )) && +zinit-message "Extended parameter whitelist"
           }
           ;;
       (*)
           # Check if there is a z-annex registered for the subcommand
           reply=( ${ZINIT_EXTS[z-annex subcommand:${(q)1}]} )
           (( ${#reply} )) && {
               reply=( "${(Q)${(z@)reply[1]}[@]}" )
               (( ${+functions[${reply[5]}]} )) && \
                   { "${reply[5]}" "$@"; return $?; } || \
                   { +zinit-message "([error]Couldn't find the subcommand-handler \`[obj]${reply[5]}[error]' of the z-annex \`[file]${reply[3]}[error]')"; return 1; }
           }
           (( ${+functions[.zinit-confirm]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh"
           case "$1" in
               (zstatus)
                   .zinit-show-zstatus
                   ;;
               (times)
                   .zinit-show-times "${@[2-correct,-1]}"
                   ;;
               (self-update)
                   .zinit-self-update
                   ;;
               (unload)
                   (( ${+functions[.zinit-unload]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh"
                   if [[ -z $2 && -z $3 ]]; then
                       print "Argument needed, try: help"; retval=1
                   else
                       [[ $2 = -q ]] && { 5=-q; shift; }
                       # Unload given plugin. Cloned directory remains intact
                       # so as are completions
                       .zinit-unload "${2%%(///|//|/)}" "${${3:#-q}%%(///|//|/)}" "${${(M)4:#-q}:-${(M)3:#-q}}"; retval=$?
                   fi
                   ;;
               (bindkeys)
                   .zinit-list-bindkeys
                   ;;
               (update)
                   (( ${+ZINIT_ICE[if]} )) && { eval "${ZINIT_ICE[if]}" || return 1; }
                   (( ${+ZINIT_ICE[has]} )) && { (( ${+commands[${ZINIT_ICE[has]}]} )) || return 1; }
                   () {
                       setopt localoptions extendedglob
                       : ${@[@]//(#b)([ $'\t']##|(#s))(-q|--quiet|-r|--reset|-f|--force|-p|--parallel)([ $'\t']##|(#e))/${ICE_OPTS[${opt_map[${match[2]}]}]::=1}}
                   } "$@"
                   set -- "${@[@]:#(--quiet|-q|--reset|-r|-f|--force|-p|--parallel)}"
                   if [[ $2 = --all || ${ICE_OPTS[opt_-p,--parallel]} = 1 || ( -z $2 && -z $3 && -z ${ZINIT_ICE[teleid]} && -z ${ZINIT_ICE[id-as]} ) ]]; then
                       [[ -z $2 && ${ICE_OPTS[opt_-p,--parallel]} != 1 ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       [[ ${ICE_OPTS[opt_-p,--parallel]} = 1 ]] && \
                           ICE_OPTS[value]=${${${${${(M)2:#--all}:+$3}:-$2}:#--all}:-15}
                       .zinit-update-or-status-all update; retval=$?
                   else
                       .zinit-update-or-status update "${${2%%(///|//|/)}:-${ZINIT_ICE[id-as]:-$ZINIT_ICE[teleid]}}" "${3%%(///|//|/)}"; retval=$?
                   fi
                   ;;
               (status)
                   if [[ $2 = --all || ( -z $2 && -z $3 ) ]]; then
                       [[ -z $2 ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       .zinit-update-or-status-all status; retval=$?
                   else
                       .zinit-update-or-status status "${2%%(///|//|/)}" "${3%%(///|//|/)}"; retval=$?
                   fi
                   ;;
               (report)
                   if [[ $2 = --all || ( -z $2 && -z $3 ) ]]; then
                       [[ -z $2 ]] && { print -r -- "Assuming --all is passed"; sleep 3; }
                       .zinit-show-all-reports
                   else
                       .zinit-show-report "${2%%(///|//|/)}" "${3%%(///|//|/)}"; retval=$?
                   fi
                   ;;
               (loaded|list)
                   # Show list of loaded plugins
                   .zinit-show-registered-plugins "$2"
                   ;;
               (clist|completions)
                   # Show installed, enabled or disabled, completions
                   # Detect stray and improper ones
                   .zinit-show-completions "$2"
                   ;;
               (cclear)
                   # Delete stray and improper completions
                   .zinit-clear-completions
                   ;;
               (cdisable)
                   if [[ -z $2 ]]; then
                       print "Argument needed, try: help"; retval=1
                   else
                       local f="_${2#_}"
                       # Disable completion given by completion function name
                       # with or without leading _, e.g. cp, _cp
                       if .zinit-cdisable "$f"; then
                           (( ${+functions[.zinit-forget-completion]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
                           .zinit-forget-completion "$f"
                           print "Initializing completion system (compinit)..."
                           builtin autoload -Uz compinit
                           compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
                       else
                           retval=1
                       fi
                   fi
                   ;;
               (cenable)
                   if [[ -z $2 ]]; then
                       print "Argument needed, try: help"; retval=1
                   else
                       local f="_${2#_}"
                       # Enable completion given by completion function name
                       # with or without leading _, e.g. cp, _cp
                       if .zinit-cenable "$f"; then
                           (( ${+functions[.zinit-forget-completion]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
                           .zinit-forget-completion "$f"
                           print "Initializing completion system (compinit)..."
                           builtin autoload -Uz compinit
                           compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
                       else
                           retval=1
                       fi
                   fi
                   ;;
               (creinstall)
                   (( ${+functions[.zinit-install-completions]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
                   # Installs completions for plugin. Enables them all. It's a
                   # reinstallation, thus every obstacle gets overwritten or removed
                   [[ $2 = -q ]] && { 5=-q; shift; }
                   .zinit-install-completions "${2%%(///|//|/)}" "${3%%(///|//|/)}" 1 "${(M)4:#-q}"; retval=$?
                   [[ -z ${(M)4:#-q} ]] && print "Initializing completion (compinit)..."
                   builtin autoload -Uz compinit
                   compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
                   ;;
               (cuninstall)
                   if [[ -z $2 && -z $3 ]]; then
                       print "Argument needed, try: help"; retval=1
                   else
                       (( ${+functions[.zinit-forget-completion]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
                       # Uninstalls completions for plugin
                       .zinit-uninstall-completions "${2%%(///|//|/)}" "${3%%(///|//|/)}"; retval=$?
                       print "Initializing completion (compinit)..."
                       builtin autoload -Uz compinit
                       compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
                   fi
                   ;;
               (csearch)
                   .zinit-search-completions
                   ;;
               (compinit)
                   (( ${+functions[.zinit-forget-completion]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
                   .zinit-compinit; retval=$?
                   ;;
               (dreport)
                   .zinit-show-debug-report
                   ;;
               (dclear)
                   .zinit-clear-debug-report
                   ;;
               (dunload)
                   .zinit-debug-unload
                   ;;
               (compile)
                   (( ${+functions[.zinit-compile-plugin]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh"
                   if [[ $2 = --all || ( -z $2 && -z $3 ) ]]; then
                       [[ -z $2 ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       .zinit-compile-uncompile-all 1; retval=$?
                   else
                       .zinit-compile-plugin "${2%%(///|//|/)}" "${3%%(///|//|/)}"; retval=$?
                   fi
                   ;;
               (uncompile)
                   if [[ $2 = --all || ( -z $2 && -z $3 ) ]]; then
                       [[ -z $2 ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       .zinit-compile-uncompile-all 0; retval=$?
                   else
                       .zinit-uncompile-plugin "${2%%(///|//|/)}" "${3%%(///|//|/)}"; retval=$?
                   fi
                   ;;
               (compiled)
                   .zinit-compiled
                   ;;
               (cdlist)
                   .zinit-list-compdef-replay
                   ;;
               (cd|delete|recall|edit|glance|changes|create|stress)
                   .zinit-"$1" "${@[2-correct,-1]%%(///|//|/)}"; retval=$?
                   ;;
               (recently)
                   shift
                   .zinit-recently "$@"; retval=$?
                   ;;
               (-h|--help|help)
                   .zinit-help
                   ;;
               (ls)
                   shift
                   .zinit-ls "$@"
                   ;;
               (srv)
                   () { setopt localoptions extendedglob warncreateglobal
                   [[ ! -e ${ZINIT[SERVICES_DIR]}/"$2".fifo ]] && { print "No such service: $2"; } ||
                       { [[ $3 = (#i)(next|stop|quit|restart) ]] &&
                           { print "${(U)3}" >>! ${ZINIT[SERVICES_DIR]}/"$2".fifo || print "Service $2 inactive"; retval=1; } ||
                               { [[ $3 = (#i)start ]] && rm -f ${ZINIT[SERVICES_DIR]}/"$2".stop ||
                                   { print "Unknown service-command: $3"; retval=1; }
                               }
                       }
                   } "$@"
                   ;;
               (module)
                   .zinit-module "${@[2-correct,-1]}"; retval=$?
                   ;;
               (*)
                   +zinit-message "[error]Unknown command ${__q}[obj]${1}[error]'" \
                       "(use ${__q}[obj]help[error]' to get usage information).[rst]"
                   retval=1
                   ;;
            esac
            ;;
    esac

    return $retval
} # ]]]
# FUNCTION: zicdreplay [[[
# A function that can be invoked from within `atinit', `atload', etc.
# ice-mod.  It works like `zinit cdreplay', which cannot be invoked
# from such hook ices.
zicdreplay() { .zinit-compdef-replay -q; }
# ]]]
# FUNCTION: zicdclear [[[
# A wrapper for `zinit cdclear -q' which can be called from hook
# ices like the atinit'', atload'', etc. ices.
zicdclear() { .zinit-compdef-clear -q; }
# ]]]
# FUNCTION: zicompinit [[[
# A function that can be invoked from within `atinit', `atload', etc.
# ice-mod.  It runs `autoload compinit; compinit' and respects
# ZINIT[ZCOMPDUMP_PATH] and ZINIT[COMPINIT_OPTS].
zicompinit() { autoload -Uz compinit; compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"; }
# ]]]
# FUNCTION: zicompdef [[[
# Stores compdef for a replay with `zicdreplay' (turbo mode) or
# with `zinit cdreplay' (normal mode). An utility functton of
# an undefined use case.
zicompdef() { ZINIT_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" ); }
# ]]]

# Compatibility functions [[[
zplugin() { zinit "$@"; }
zpcdreplay() { .zinit-compdef-replay -q; }
zpcdclear() { .zinit-compdef-clear -q; }
zpcompinit() { autoload -Uz compinit; compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"; }
zpcompdef() { ZINIT_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" ); }
# ]]]

#
# Source-executed code
#

(( ZINIT[ALIASES_OPT] )) && builtin setopt aliases
(( ZINIT[SOURCED] ++ )) && return

autoload add-zsh-hook
zmodload zsh/datetime && add-zsh-hook -- precmd @zinit-scheduler  # zsh/datetime required for wait/load/unload ice-mods
functions -M -- zinit_scheduler_add 1 1 -zinit_scheduler_add_sh 2>/dev/null
zmodload zsh/zpty zsh/system 2>/dev/null
zmodload -F zsh/stat b:zstat 2>/dev/null && ZINIT[HAVE_ZSTAT]=1

# code [[[
builtin alias zpl=zinit zplg=zinit zi=zinit zini=zinit

.zinit-prepare-home

# Remember source's timestamps for the automatic-reload feature
typeset -g ZINIT_TMP
for ZINIT_TMP ( "" -side -install -autoload ) {
    .zinit-get-mtime-into "${ZINIT[BIN_DIR]}/zinit$ZINIT_TMP.zsh" "ZINIT[mtime$ZINIT_TMP]"
}

# Simulate existence of _local/zinit plugin
# This will allow to cuninstall of its completion
ZINIT_REGISTERED_PLUGINS=( _local/zinit "${(u)ZINIT_REGISTERED_PLUGINS[@]:#_local/zinit}" )
ZINIT_REGISTERED_STATES[_local/zinit]=1

# Inform Prezto that the compdef function is available
zstyle ':prezto:module:completion' loaded 1

# Colorize completions for commands unload, report, creinstall, cuninstall
zstyle ':completion:*:zinit:argument-rest:plugins' list-colors '=(#b)(*)/(*)==1;35=1;33'
zstyle ':completion:*:zinit:argument-rest:plugins' matcher 'r:|=** l:|=*'
zstyle ':completion:*:*:zinit:*' group-name ""
# ]]]

# module recompilation for the project rename [[[
if [[ -e ${${ZINIT[BIN_DIR]}}/zmodules/Src/zdharma/zplugin.so ]] {
    if [[ ! -f ${${ZINIT[BIN_DIR]}}/zmodules/COMPILED_AT || ( ${${ZINIT[BIN_DIR]}}/zmodules/COMPILED_AT -ot ${${ZINIT[BIN_DIR]}}/zmodules/RECOMPILE_REQUEST ) ]] {
        # Don't trust access times and verify hard stored values
        [[ -e ${${ZINIT[BIN_DIR]}}/module/COMPILED_AT ]] && local compiled_at_ts="$(<${${ZINIT[BIN_DIR]}}/module/COMPILED_AT)"
        [[ -e ${${ZINIT[BIN_DIR]}}/module/RECOMPILE_REQUEST ]] && local recompile_request_ts="$(<${${ZINIT[BIN_DIR]}}/module/RECOMPILE_REQUEST)"

        if [[ ${recompile_request_ts:-1} -gt ${compiled_at_ts:-0} ]] {
            +zinit-message "[error]WARNING:[rst][msg1]A [obj]recompilation[rst]" \
                "of the Zinit module has been requested… [obj]Building[rst]…"
            (( ${+functions[.zinit-confirm]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh"
            command make -C "${ZINIT[BIN_DIR]}/zmodules" distclean &>/dev/null
            .zinit-module build &>/dev/null
            if command make -C "${ZINIT[BIN_DIR]}/zmodules" &>/dev/null; then
                +zinit-message "[pre]Build successful![rst]"
            else
                print -r -- "${ZINIT[col-error]}Compilation failed.${ZINIT[col-rst]}" \
                     "${ZINIT[col-pre]}You can enter the following command:${ZINIT[col-rst]}" \
                     'make -C "${ZINIT[BIN_DIR]}/zmodules' \
                     "${ZINIT[col-pre]}to see the error messages and e.g.: report an issue" \
                     "at GitHub${ZINIT[col-rst]}"
            fi

            command date '+%s' >! "${ZINIT[BIN_DIR]}/zmodules/COMPILED_AT"
        }
    }
}
# ]]]

# vim:ft=zsh:sw=4:sts=4:et:foldmarker=[[[,]]]
