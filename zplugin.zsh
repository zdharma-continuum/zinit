# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2019 Sebastian Gniazdowski and contributors

#
# Main state variables
#

typeset -gaH ZPLG_REGISTERED_PLUGINS ZPLG_TASKS ZPLG_RUN
typeset -ga zsh_loaded_plugins
ZPLG_TASKS=( "<no-data>" )
# Snippets loaded, url -> file name
typeset -gAH ZPLGM ZPLG_REGISTERED_STATES ZPLG_SNIPPETS ZPLG_REPORTS ZPLG_ICES ZPLG_SICE ZPLG_CUR_BIND_MAP ZPLG_EXTS
typeset -gaH ZPLG_COMPDEF_REPLAY

#
# Common needed values
#

[[ ! -e "${ZPLGM[BIN_DIR]}"/zplugin.zsh ]] && ZPLGM[BIN_DIR]=""

ZPLGM[ZERO]="$0"
[[ ! -o "functionargzero" || "${ZPLGM[ZERO]/\//}" = "${ZPLGM[ZERO]}" ]] && ZPLGM[ZERO]="${(%):-%N}"

[[ -z "${ZPLGM[BIN_DIR]}" ]] && ZPLGM[BIN_DIR]="${ZPLGM[ZERO]:h}"
[[ "${ZPLGM[BIN_DIR]}" = \~* ]] && ZPLGM[BIN_DIR]=${~ZPLGM[BIN_DIR]}

# Make ZPLGM[BIN_DIR] path absolute
if [[ "${ZPLGM[BIN_DIR]}" != /* ]]; then
    if [[ "${ZPLGM[BIN_DIR]}" = "." ]]; then
        ZPLGM[BIN_DIR]="$PWD"
    else
        ZPLGM[BIN_DIR]="$PWD/${ZPLGM[BIN_DIR]}"
    fi
fi

# Final test of ZPLGM[BIN_DIR]
if [[ ! -e "${ZPLGM[BIN_DIR]}"/zplugin.zsh ]]; then
    print "Could not establish ZPLGM[BIN_DIR] hash field. It should point where Zplugin's git repository is."
    return 1
fi

# User can override ZPLGM[HOME_DIR]
if [[ -z "${ZPLGM[HOME_DIR]}" ]]; then
    # Ignore ZDOTDIR if user manually put Zplugin to $HOME
    if [[ -d "$HOME/.zplugin" ]]; then
        ZPLGM[HOME_DIR]="$HOME/.zplugin"
    else
        ZPLGM[HOME_DIR]="${ZDOTDIR:-$HOME}/.zplugin"
    fi
fi

# Can be customized
: ${ZPLGM[PLUGINS_DIR]:=${ZPLGM[HOME_DIR]}/plugins}
: ${ZPLGM[COMPLETIONS_DIR]:=${ZPLGM[HOME_DIR]}/completions}
: ${ZPLGM[SNIPPETS_DIR]:=${ZPLGM[HOME_DIR]}/snippets}
: ${ZPLGM[SERVICES_DIR]:=${ZPLGM[HOME_DIR]}/services}
typeset -g ZPFX
: ${ZPFX:=${ZPLGM[HOME_DIR]}/polaris}

ZPLGM[PLUGINS_DIR]=${~ZPLGM[PLUGINS_DIR]}
ZPLGM[COMPLETIONS_DIR]=${~ZPLGM[COMPLETIONS_DIR]}
ZPLGM[SNIPPETS_DIR]=${~ZPLGM[SNIPPETS_DIR]}
ZPLGM[SERVICES_DIR]=${~ZPLGM[SERVICES_DIR]}
export ZPFX=${~ZPFX} ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache/zplugin}}"
[[ -n ${path[(re)$ZPFX/bin]} ]] || path=( "$ZPFX/bin" ${path[@]} )

[[ ! -d $ZSH_CACHE_DIR ]] && command mkdir -p "$ZSH_CACHE_DIR"
[[ -n "${ZPLGM[ZCOMPDUMP_PATH]}" ]] && ZPLGM[ZCOMPDUMP_PATH]=${~ZPLGM[ZCOMPDUMP_PATH]}

ZPLGM[UPAR]=";:^[[A;:^[OA;:\\e[A;:\\eOA;:${termcap[ku]/$'\e'/^\[};:${terminfo[kcuu1]/$'\e'/^\[};:"
ZPLGM[DOWNAR]=";:^[[B;:^[OB;:\\e[B;:\\eOB;:${termcap[kd]/$'\e'/^\[};:${terminfo[kcud1]/$'\e'/^\[};:"
ZPLGM[RIGHTAR]=";:^[[C;:^[OC;:\\e[C;:\\eOC;:${termcap[kr]/$'\e'/^\[};:${terminfo[kcuf1]/$'\e'/^\[};:"
ZPLGM[LEFTAR]=";:^[[D;:^[OD;:\\e[D;:\\eOD;:${termcap[kl]/$'\e'/^\[};:${terminfo[kcub1]/$'\e'/^\[};:"

builtin autoload -Uz is-at-least
is-at-least 5.1 && ZPLGM[NEW_AUTOLOAD]=1 || ZPLGM[NEW_AUTOLOAD]=0
#is-at-least 5.4 && ZPLGM[NEW_AUTOLOAD]=2

# Parameters - shadowing {{{
ZPLGM[SHADOWING]="inactive"
ZPLGM[DTRACE]="0"
typeset -gH ZPLG_CUR_PLUGIN=""
# }}}
# Parameters - ICE, {{{
declare -gA ZPLG_1MAP ZPLG_2MAP
ZPLG_1MAP=(
    "OMZ::" "https://github.com/robbyrussell/oh-my-zsh/trunk/"
    "PZT::" "https://github.com/sorin-ionescu/prezto/trunk/"
)
ZPLG_2MAP=(
    "OMZ::" "https://github.com/robbyrussell/oh-my-zsh/raw/master/"
    "PZT::" "https://github.com/sorin-ionescu/prezto/raw/master/"
)
# }}}

# Init {{{
zmodload zsh/zutil || return 1
zmodload zsh/parameter || return 1
zmodload zsh/terminfo 2>/dev/null
zmodload zsh/termcap 2>/dev/null

[[ ( "${+terminfo}" = 1 && -n "${terminfo[colors]}" ) || ( "${+termcap}" = 1 && -n "${termcap[Co]}" ) ]] && {
    ZPLGM+=(
        "col-title"     ""
        "col-pname"     $'\e[33m'
        "col-uname"     $'\e[35m'
        "col-keyword"   $'\e[32m'
        "col-note"      $'\e[33m'
        "col-error"     $'\e[31m'
        "col-p"         $'\e[01m\e[34m'
        "col-bar"       $'\e[01m\e[35m'
        "col-info"      $'\e[32m'
        "col-info2"     $'\e[32m'
        "col-uninst"    $'\e[01m\e[34m'
        "col-success"   $'\e[01m\e[32m'
        "col-failure"   $'\e[31m'
        "col-rst"       $'\e[0m'
        "col-bold"      $'\e[1m'
    )
}

# List of hooks
typeset -gAH ZPLG_ZLE_HOOKS_LIST
ZPLG_ZLE_HOOKS_LIST=(
    zle-line-init "1"
    zle-line-finish "1"
    paste-insert "1"
    zle-isearch-exit "1"
    zle-isearch-update "1"
    zle-history-line-set "1"
    zle-keymap-select "1"
)

builtin setopt noaliases

# }}}

#
# Shadowing-related functions
#

# FUNCTION: --zplg-reload-and-run {{{
# Marks given function ($3) for autoloading, and executes it triggering the
# load. $1 is the fpath dedicated to the function, $2 are autoload options.
# This function replaces "autoload -X", because using that on older Zsh
# versions causes problems with traps.
#
# So basically one creates function stub that calls --zplg-reload-and-run()
# instead of "autoload -X".
#
# $1 - FPATH dedicated to function
# $2 - autoload options
# $3 - function name (one that needs autoloading)
#
# Author: Bart Schaefer
--zplg-reload-and-run () {
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
} # }}}
# FUNCTION: --zplg-shadow-autoload {{{
# Function defined to hijack plugin's calls to `autoload' builtin.
#
# The hijacking is not only to gather report data, but also to
# run custom `autoload' function, that doesn't need FPATH.
--zplg-shadow-autoload () {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    local -a opts
    local func

    zparseopts -D -a opts ${(s::):-RTUXdkmrtWz}

    [[ "$ZPLGM[CUR_USR]" = "%" ]] && \
        local PLUGIN_DIR="$ZPLG_CUR_PLUGIN" || \
        local PLUGIN_DIR="${ZPLGM[PLUGINS_DIR]}/${${ZPLGM[CUR_USR]}:+${ZPLGM[CUR_USR]}---}${ZPLG_CUR_PLUGIN//\//---}"

    if (( ${+opts[(r)-X]} )); then
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: Failed autoload ${(j: :)opts[@]} $*"
        print -u2 "builtin autoload required for ${(j: :)opts[@]}"
        return 1
    fi
    if (( ${+opts[(r)-w]} )); then
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "-w-Autoload ${(j: :)opts[@]} ${(j: :)@}"
        local +h FPATH="$PLUGINS_DIR:$FPATH"
        builtin autoload ${opts[@]} "$@"
        return 0
    fi
    if [[ -n ${(M)@:#+X} ]]; then
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Autoload +X ${opts:+${(j: :)opts[@]} }${(j: :)${@:#+X}}"
        local +h FPATH="$PLUGINS_DIR:$FPATH"
        builtin autoload +X ${opts[@]} "${@:#+X}"
        return 0
    fi
    # Report ZPLUGIN's "native" autoloads
    for func; do
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Autoload $func${opts:+ with options ${(j: :)opts[@]}}"
    done

    local -a fpath_elements
    fpath_elements=( ${fpath[(r)$PLUGIN_DIR/*]} )

    for func; do
        # Real autoload doesn't touch function if it already exists
        # Author of the idea of FPATH-clean autoloading: Bart Schaefer
        if (( ${+functions[$func]} != 1 )); then
            builtin setopt noaliases
            if [[ "${ZPLGM[NEW_AUTOLOAD]}" = "2" ]]; then
                builtin autoload ${opts[@]} "$PLUGIN_DIR/$func"
            elif [[ "${ZPLGM[NEW_AUTOLOAD]}" = "1" ]]; then
                eval "function ${(q)func} {
                    local -a fpath
                    fpath=( ${(qqq)PLUGIN_DIR} ${(qqq@)fpath_elements} ${(qqq@)fpath} )
                    builtin autoload -X ${(j: :)${(q-)opts[@]}}
                }"
            else
                eval "function ${(q)func} {
                    --zplg-reload-and-run ${(qqq)PLUGIN_DIR}"$'\0'"${(pj,\0,)${(qqq)fpath_elements[@]}} ${(qq)opts[*]} ${(q)func} "'"$@"
                }'
            fi
            builtin unsetopt noaliases
        fi
    done

    return 0
} # }}}
# FUNCTION: --zplg-shadow-bindkey {{{
# Function defined to hijack plugin's calls to `bindkey' builtin.
#
# The hijacking is to gather report data (which is used in unload).
--zplg-shadow-bindkey() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    is-at-least 5.3 && \
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Bindkey ${(j: :)${(q+)@}}" || \
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Bindkey ${(j: :)${(q)@}}"

    # Remember to perform the actual bindkey call
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular bindkey call, i.e.
    # with no options or with -s, plus possible -M
    # option
    local -A opts
    zparseopts -A opts -D ${(s::):-lLdDAmrsevaR} "M:" "N:"

    if (( ${#opts} == 0 ||
        ( ${#opts} == 1 && ${+opts[-M]} ) ||
        ( ${#opts} == 1 && ${+opts[-R]} ) ||
        ( ${#opts} == 1 && ${+opts[-s]} ) ||
        ( ${#opts} <= 2 && ${+opts[-M]} && ${+opts[-s]} ) ||
        ( ${#opts} <= 2 && ${+opts[-M]} && ${+opts[-R]} )
    )); then
        local string="${(q)1}" widget="${(q)2}"
        local quoted

        if [[ -n "${ZPLG_ICE[bindmap]}" && ${ZPLG_CUR_BIND_MAP[empty]} -eq 1 ]]; then
            local -a pairs
            pairs=( "${(@s,;,)ZPLG_ICE[bindmap]}" )
            () {
                builtin setopt localoptions extendedglob noksharrays noshwordsplit;
                pairs=( "${(@)${(@)${(@s:->:)pairs}##[[:space:]]##}%%[[:space:]]##}" )
            }
            ZPLG_CUR_BIND_MAP=( empty 0 )
            (( ${#pairs} > 1 && ${#pairs[@]} % 2 == 0 )) && ZPLG_CUR_BIND_MAP+=( "${pairs[@]}" )
        fi

        1="${1#"${1%%[! $'\t']*}"}" # leading whitespace
        1="${1%"${1##*[! $'\t']}"}" # trailing whitespace
        local bmap_val="${ZPLG_CUR_BIND_MAP[${1}]}"
        if [[ -n "$bmap_val" ]]; then
            string="${(q)bmap_val}"
            pos[1]="$bmap_val"
            -zplg-add-report "${ZPLGM[CUR_USPL2]}" ":::Bindkey: combination <$1> changed to <$bmap_val>${${(M)bmap_val:#hold}:+, i.e. ${ZPLGM[col-error]}unmapped${ZPLGM[col-rst]}}"
            (( 1 ))
        elif [[ ( -n ${bmap_val::=${ZPLG_CUR_BIND_MAP[UPAR]}} && -n "${${ZPLGM[UPAR]}[(r);:${(q)1};:]}" ) || \
                ( -n ${bmap_val::=${ZPLG_CUR_BIND_MAP[DOWNAR]}} && -n "${${ZPLGM[DOWNAR]}[(r);:${(q)1};:]}" ) || \
                ( -n ${bmap_val::=${ZPLG_CUR_BIND_MAP[RIGHTAR]}} && -n "${${ZPLGM[RIGHTAR]}[(r);:${(q)1};:]}" ) || \
                ( -n ${bmap_val::=${ZPLG_CUR_BIND_MAP[LEFTAR]}} && -n "${${ZPLGM[LEFTAR]}[(r);:${(q)1};:]}" )
        ]]; then
            string="${(q)bmap_val}"
            pos[1]="$bmap_val"
            -zplg-add-report "${ZPLGM[CUR_USPL2]}" ":::Bindkey: combination <$1> recognized as cursor-key and changed to <${bmap_val}>${${(M)bmap_val:#hold}:+, i.e. ${ZPLGM[col-error]}unmapped${ZPLGM[col-rst]}}"
        fi
        [[ "$bmap_val" = "hold" ]] && return 0

        local prev="${(q)${(s: :)$(builtin bindkey ${(Q)string})}[-1]#undefined-key}"

        # "-M map" given?
        if (( ${+opts[-M]} )); then
            local Mopt="-M"
            local Marg="${opts[-M]}"

            Mopt="${(q)Mopt}"
            Marg="${(q)Marg}"

            quoted="$string $widget $prev $Mopt $Marg"
        else
            quoted="$string $widget $prev"
        fi

        # -R given?
        if (( ${+opts[-R]} )); then
            local Ropt="-R"
            Ropt="${(q)Ropt}"

            if (( ${+opts[-M]} )); then
                quoted="$quoted $Ropt"
            else
                # Two empty fields for non-existent -M arg
                local space="_"
                space="${(q)space}"
                quoted="$quoted $space $space $Ropt"
            fi
        fi

        quoted="${(q)quoted}"

        # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
        [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLGM[BINDKEYS__${ZPLGM[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLGM[BINDKEYS___dtrace/_dtrace]+="$quoted "
    else
        # bindkey -A newkeymap main?
        # Negative indices for KSH_ARRAYS immunity
        if [[ "${#opts}" -eq "1" && "${+opts[-A]}" = "1" && "${#pos}" = "3" && "${pos[-1]}" = "main" && "${pos[-2]}" != "-A" ]]; then
            # Save a copy of main keymap
            (( ZPLGM[BINDKEY_MAIN_IDX] = ${ZPLGM[BINDKEY_MAIN_IDX]:-0} + 1 ))
            local pname="${ZPLG_CUR_PLUGIN:-_dtrace}"
            local name="${(q)pname}-main-${ZPLGM[BINDKEY_MAIN_IDX]}"
            builtin bindkey -N "$name" main

            # Remember occurence of main keymap substitution, to revert on unload
            local keys="_" widget="_" prev="" optA="-A" mapname="${name}" optR="_"
            local quoted="${(q)keys} ${(q)widget} ${(q)prev} ${(q)optA} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
            [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLGM[BINDKEYS__${ZPLGM[CUR_USPL2]}]+="$quoted "
            [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLGM[BINDKEYS___dtrace/_dtrace]+="$quoted "

            -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: keymap \`main' copied to \`${name}' because of \`${pos[-2]}' substitution"
        # bindkey -N newkeymap [other]
        elif [[ "${#opts}" -eq 1 && "${+opts[-N]}" = "1" ]]; then
            local Nopt="-N"
            local Narg="${opts[-N]}"

            local keys="_" widget="_" prev="" optN="-N" mapname="${Narg}" optR="_"
            local quoted="${(q)keys} ${(q)widget} ${(q)prev} ${(q)optN} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
            [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLGM[BINDKEYS__${ZPLGM[CUR_USPL2]}]+="$quoted "
            [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLGM[BINDKEYS___dtrace/_dtrace]+="$quoted "
        else
            -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: last bindkey used non-typical options: ${(kv)opts[*]}"
        fi
    fi

    # Actual bindkey
    builtin bindkey "${pos[@]}"
    return $? # testable
} # }}}
# FUNCTION: --zplg-shadow-zstyle {{{
# Function defined to hijack plugin's calls to `zstyle' builtin.
#
# The hijacking is to gather report data (which is used in unload).
--zplg-shadow-zstyle() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Zstyle $*"

    # Remember to perform the actual zstyle call
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular zstyle call, i.e.
    # with no options or with -e
    local -a opts
    zparseopts -a opts -D ${(s::):-eLdgabsTtm}

    if [[ "${#opts}" -eq 0 || ( "${#opts}" -eq 1 && "${+opts[(r)-e]}" = "1" ) ]]; then
        # Have to quote $1, then $2, then concatenate them, then quote them again
        local pattern="${(q)1}" style="${(q)2}"
        local ps="$pattern $style"
        ps="${(q)ps}"

        # Remember the zstyle, only when load is in progress (it can be dstart that leads execution here)
        [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLGM[ZSTYLES__${ZPLGM[CUR_USPL2]}]+="$ps "
        # Remember for dtrace
        [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLGM[ZSTYLES___dtrace/_dtrace]+="$ps "
    else
        if [[ ! "${#opts[@]}" = "1" && ( "${+opts[(r)-s]}" = "1" || "${+opts[(r)-b]}" = "1" || "${+opts[(r)-a]}" = "1" ||
                                      "${+opts[(r)-t]}" = "1" || "${+opts[(r)-T]}" = "1" || "${+opts[(r)-m]}" = "1" ) ]]
        then
            -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: last zstyle used non-typical options: ${opts[*]}"
        fi
    fi

    # Actual zstyle
    builtin zstyle "${pos[@]}"
    return $? # testable
} # }}}
# FUNCTION: --zplg-shadow-alias {{{
# Function defined to hijack plugin's calls to `alias' builtin.
#
# The hijacking is to gather report data (which is used in unload).
--zplg-shadow-alias() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Alias $*"

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
        (( ${+aliases[$aname]} )) && -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: redefining alias \`${aname}', previous value: ${aliases[$aname]}"

        local bname=${(q)aliases[$aname]}
        aname="${(q)aname}"

        if (( ${+opts[(r)-s]} )); then
            tmp="-s"
            tmp="${(q)tmp}"
            quoted="$aname $bname $tmp"
        elif (( ${+opts[(r)-g]} )); then
            tmp="-g"
            tmp="${(q)tmp}"
            quoted="$aname $bname $tmp"
        else
            quoted="$aname $bname"
        fi

        quoted="${(q)quoted}"

        # Remember the alias, only when load is in progress (it can be dstart that leads execution here)
        [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLGM[ALIASES__${ZPLGM[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLGM[ALIASES___dtrace/_dtrace]+="$quoted "
    done

    # Actual alias
    builtin alias "${pos[@]}"
    return $? # testable
} # }}}
# FUNCTION: --zplg-shadow-zle {{{
# Function defined to hijack plugin's calls to `zle' builtin.
#
# The hijacking is to gather report data (which is used in unload).
--zplg-shadow-zle() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Zle $*"

    # Remember to perform the actual zle call
    typeset -a pos
    pos=( "$@" )

    set -- "${@:#--}"

    # Try to catch game-changing "-N"
    if [[ ( "$1" = "-N" && ( "$#" = "2" || "$#" = "3" ) ) || \
            ( "$1" = "-C" && "$#" = "4" )
    ]]; then
            # Hooks
            if [[ "${ZPLG_ZLE_HOOKS_LIST[$2]}" = "1" ]]; then
                local quoted="$2"
                quoted="${(q)quoted}"
                # Remember only when load is in progress (it can be dstart that leads execution here)
                [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLGM[WIDGETS_DELETE__${ZPLGM[CUR_USPL2]}]+="$quoted "
                # Remember for dtrace
                [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLGM[WIDGETS_DELETE___dtrace/_dtrace]+="$quoted "
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
                [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLGM[WIDGETS_SAVED__${ZPLGM[CUR_USPL2]}]+="$quoted "
                # Remember for dtrace
                [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLGM[WIDGETS_SAVED___dtrace/_dtrace]+="$quoted "
             # These will be deleted
             else
                 -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Note: a new widget created via zle -N: \`$2'"
                 local quoted="$2"
                 quoted="${(q)quoted}"
                 # Remember only when load is in progress (it can be dstart that leads execution here)
                 [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLGM[WIDGETS_DELETE__${ZPLGM[CUR_USPL2]}]+="$quoted "
                 # Remember for dtrace
                 [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLGM[WIDGETS_DELETE___dtrace/_dtrace]+="$quoted "
             fi
    fi

    # Actual zle
    builtin zle "${pos[@]}"
    return $? # testable
} # }}}
# FUNCTION: --zplg-shadow-compdef {{{
# Function defined to hijack plugin's calls to `compdef' function.
# The hijacking is not only for reporting, but also to save compdef
# calls so that `compinit' can be called after loading plugins.
--zplg-shadow-compdef() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Saving \`compdef $*' for replay"
    ZPLG_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" )

    return 0 # testable
} # }}}
# FUNCTION: -zplg-shadow-on {{{
# Turn on shadowing of builtins and functions according to passed
# mode ("load", "light", "light-b" or "compdef"). The shadowing is
# to gather report data, and to hijack `autoload', `bindkey' and
# `compdef' calls.
-zplg-shadow-on() {
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
    [[ "${ZPLGM[SHADOWING]}" != "inactive" ]] && builtin return 0

    ZPLGM[SHADOWING]="$mode"

    # The point about backuping is: does the key exist in functions array
    # If it does exist, then it will also exist as ZPLGM[bkp-*]

    # Defensive code, shouldn't be needed
    builtin unset "ZPLGM[bkp-autoload]" "ZPLGM[bkp-compdef]"  # 0, E.

    if [[ "$mode" != "compdef" ]]; then
        # 0. Used, but not in temporary restoration, which doesn't happen for autoload
        (( ${+functions[autoload]} )) && ZPLGM[bkp-autoload]="${functions[autoload]}"
        functions[autoload]='--zplg-shadow-autoload "$@";'
    fi

    # E. Always shadow compdef
    (( ${+functions[compdef]} )) && ZPLGM[bkp-compdef]="${functions[compdef]}"
    functions[compdef]='--zplg-shadow-compdef "$@";'

    # Light and compdef shadowing stops here. Dtrace and load go on
    [[ ( "$mode" = "light" && ${+ZPLG_ICE[trackbinds]} -eq 0 ) || "$mode" = "compdef" ]] && return 0

    # Defensive code, shouldn't be needed. A, B, C, D
    builtin unset "ZPLGM[bkp-bindkey]" "ZPLGM[bkp-zstyle]" "ZPLGM[bkp-alias]" "ZPLGM[bkp-zle]"

    # A.
    (( ${+functions[bindkey]} )) && ZPLGM[bkp-bindkey]="${functions[bindkey]}"
    functions[bindkey]='--zplg-shadow-bindkey "$@";'

    # B, when `zplugin light -b ...' or when `zplugin ice trackbinds ...; zplugin light ...'
    [[ "$mode" = "light-b" || ( "$mode" = "light" && ${+ZPLG_ICE[trackbinds]} -eq 1 ) ]] && return 0

    # B.
    (( ${+functions[zstyle]} )) && ZPLGM[bkp-zstyle]="${functions[zstyle]}"
    functions[zstyle]='--zplg-shadow-zstyle "$@";'

    # C.
    (( ${+functions[alias]} )) && ZPLGM[bkp-alias]="${functions[alias]}"
    functions[alias]='--zplg-shadow-alias "$@";'

    # D.
    (( ${+functions[zle]} )) && ZPLGM[bkp-zle]="${functions[zle]}"
    functions[zle]='--zplg-shadow-zle "$@";'

    builtin return 0
} # }}}
# FUNCTION: -zplg-shadow-off {{{
# Turn off shadowing completely for a given mode ("load", "light",
# "light-b" (i.e. the `trackbinds' mode) or "compdef").
-zplg-shadow-off() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    local mode="$1"

    # Disable shadowing only once
    # Disable shadowing only the way it was enabled first
    [[ "${ZPLGM[SHADOWING]}" = "inactive" || "${ZPLGM[SHADOWING]}" != "$mode" ]] && return 0

    ZPLGM[SHADOWING]="inactive"

    if [[ "$mode" != "compdef" ]]; then
        # 0. Unfunction "autoload"
        (( ${+ZPLGM[bkp-autoload]} )) && functions[autoload]="${ZPLGM[bkp-autoload]}" || unfunction "autoload"
    fi

    # E. Restore original compdef if it existed
    (( ${+ZPLGM[bkp-compdef]} )) && functions[compdef]="${ZPLGM[bkp-compdef]}" || unfunction "compdef"

    # Light and compdef shadowing stops here
    [[ ( "$mode" = "light" && ${+ZPLG_ICE[trackbinds]} -eq 0 ) || "$mode" = "compdef" ]] && return 0

    # Unfunction shadowing functions

    # A.
    (( ${+ZPLGM[bkp-bindkey]} )) && functions[bindkey]="${ZPLGM[bkp-bindkey]}" || unfunction "bindkey"

    # When `zplugin light -b ...' or when `zplugin ice trackbinds ...; zplugin light ...'
    [[ "$mode" = "light-b" || ( "$mode" = "light" && ${+ZPLG_ICE[trackbinds]} -eq 1 ) ]] && return 0

    # B.
    (( ${+ZPLGM[bkp-zstyle]} )) && functions[zstyle]="${ZPLGM[bkp-zstyle]}" || unfunction "zstyle"
    # C.
    (( ${+ZPLGM[bkp-alias]} )) && functions[alias]="${ZPLGM[bkp-alias]}" || unfunction "alias"
    # D.
    (( ${+ZPLGM[bkp-zle]} )) && functions[zle]="${ZPLGM[bkp-zle]}" || unfunction "zle"

    return 0
} # }}}
# FUNCTION: pmodload {{{
# {function:pmodload} Compatibility with Prezto. Calls can be recursive.
(( ${+functions[pmodload]} )) || pmodload() {
    while (( $# )); do
        if zstyle -t ":prezto:module:$1" loaded 'yes' 'no'; then
            shift
            continue
        else
            [[ -z "${ZPLG_SNIPPETS[PZT::modules/$1${ZPLG_ICE[svn]-/init.zsh}]}" && -z "${ZPLG_SNIPPETS[https://github.com/sorin-ionescu/prezto/trunk/modules/$1${ZPLG_ICE[svn]-/init.zsh}]}" ]] && -zplg-load-snippet PZT::modules/"$1${ZPLG_ICE[svn]-/init.zsh}"
            shift
        fi
    done
}
# }}}
# FUNCTION: -zplg-wrap-track-functions {{{
-zplg-wrap-track-functions() {
    local user="$1" plugin="$2" id_as="$3" f
    local -a wt
    wt=( ${(@s.;.)ZPLG_ICE[wrap-track]} )
    for f in ${wt[@]}; do
        functions[${f}-zplugin-bkp]="${functions[$f]}"
        eval "
function $f {
    ZPLGM[CUR_USR]=\"$user\" ZPLG_CUR_PLUGIN=\"$plugin\" ZPLGM[CUR_USPL2]=\"$id_as\"
    -zplg-add-report \"\${ZPLGM[CUR_USPL2]}\" \"Note: === Starting to track function: $f ===\"
    -zplg-diff \"\${ZPLGM[CUR_USPL2]}\" begin
    -zplg-shadow-on load
    functions[${f}]=\${functions[${f}-zplugin-bkp]}
    ${f} \"\$@\"
    -zplg-shadow-off load
    -zplg-diff \"\${ZPLGM[CUR_USPL2]}\" end
    -zplg-add-report \"\${ZPLGM[CUR_USPL2]}\" \"Note: === Ended tracking function: $f ===\"
    ZPLGM[CUR_USR]="" ZPLG_CUR_PLUGIN="" ZPLGM[CUR_USPL2]=""
}"
    done
}
# }}}

#
# Diff functions
#

# FUNCTION: -zplg-diff-functions {{{
# Implements detection of newly created functions. Performs
# data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
-zplg-diff-functions() {
    local uspl2="$1"
    local cmd="$2"

    [[ "$cmd" = "begin" ]] && \
        { [[ -z "${ZPLGM[FUNCTIONS_BEFORE__$uspl2]}" ]] && \
                ZPLGM[FUNCTIONS_BEFORE__$uspl2]="${(j: :)${(qk)functions[@]}}"
        } || \
        ZPLGM[FUNCTIONS_AFTER__$uspl2]+=" ${(j: :)${(qk)functions[@]}}"
} # }}}
# FUNCTION: -zplg-diff-options {{{
# Implements detection of change in option state. Performs
# data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
-zplg-diff-options() {
    local IFS=" "

    [[ "$2" = "begin" ]] && \
        { [[ -z "${ZPLGM[OPTIONS_BEFORE__$uspl2]}" ]] && \
            ZPLGM[OPTIONS_BEFORE__$1]="${(kv)options[@]}"
        } || \
        ZPLGM[OPTIONS_AFTER__$1]+=" ${(kv)options[@]}"
} # }}}
# FUNCTION: -zplg-diff-env {{{
# Implements detection of change in PATH and FPATH.
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
-zplg-diff-env() {
    typeset -a tmp
    local IFS=" "

    [[ "$2" = "begin" ]] && {
            { [[ -z "${ZPLGM[PATH_BEFORE__$uspl2]}" ]] && \
                tmp=( "${(q)path[@]}" )
                ZPLGM[PATH_BEFORE__$1]="${tmp[*]}"
            }
            { [[ -z "${ZPLGM[FPATH_BEFORE__$uspl2]}" ]] && \
                tmp=( "${(q)fpath[@]}" )
                ZPLGM[FPATH_BEFORE__$1]="${tmp[*]}"
            }
    } || {
            tmp=( "${(q)path[@]}" )
            ZPLGM[PATH_AFTER__$1]+=" ${tmp[*]}"
            tmp=( "${(q)fpath[@]}" )
            ZPLGM[FPATH_AFTER__$1]+=" ${tmp[*]}"
    }
} # }}}
# FUNCTION: -zplg-diff-parameter {{{
# Implements detection of change in any parameter's existence and type.
# Performs data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
-zplg-diff-parameter() {
    typeset -a tmp

    [[ "$2" = "begin" ]] && {
        { [[ -z "${ZPLGM[PARAMETERS_BEFORE__$uspl2]}" ]] && \
            ZPLGM[PARAMETERS_BEFORE__$1]="${(j: :)${(qkv)parameters[@]}}"
        }
    } || {
        ZPLGM[PARAMETERS_AFTER__$1]+=" ${(j: :)${(qkv)parameters[@]}}"
    }
} # }}}
# FUNCTION: -zplg-diff {{{
# Performs diff actions of all types
-zplg-diff() {
    -zplg-diff-functions "$1" "$2"
    -zplg-diff-options "$1" "$2"
    -zplg-diff-env "$1" "$2"
    -zplg-diff-parameter "$1" "$2"
}
# }}}

#
# Utility functions
#

# FUNCTION: -zplg-any-to-user-plugin {{{
# Allows elastic plugin-spec across the code.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
#
# Returns user and plugin in $reply
#
-zplg-any-to-user-plugin() {
    # Two components given?
    # That's a pretty fast track to call this function this way
    if [[ -n "$2" ]];then
        2=${~2}
        reply=( "${1:-${${(M)2#/}:+%}}" "${${${(M)1#%}:+$2}:-${2//---//}}" )
        return 0
    fi

    # Is it absolute path?
    if [[ "$1" = "/"* ]]; then
        reply=( "%" "$1" )
        return 0
    fi

    # Is it absolute path in zplugin format?
    if [[ "$1" = "%"* ]]; then
        reply=( "%" "${${${1/\%HOME/$HOME}/\%SNIPPETS/${ZPLGM[SNIPPETS_DIR]}}#%}" )
        reply[2]=${~reply[2]}
        return 0
    fi

    # Rest is for single component given
    # It doesn't touch $2

    if [[ "$1" = */* ]]; then
        reply=( "${1%%/*}" "${1#*/}" )
        return 0
    fi

    reply=( "${${(M)1#*---}%---}" "${${${1#*---}//---//}:-_unknown}" )

    return 0
} # }}}
# FUNCTION: -zplg-find-other-matches {{{
# Plugin's main source file is in general `name.plugin.zsh'. However,
# there can be different conventions, if that file is not found, then
# this functions examines other conventions in order of most expected
# sanity.
-zplg-find-other-matches() {
    local pdir_path="$1" pbase="$2"

    if [[ -e "$pdir_path/init.zsh" ]]; then
        reply=( "$pdir_path/init.zsh" )
    elif [[ -e "$pdir_path/${pbase}.zsh-theme" ]]; then
        reply=( "$pdir_path/${pbase}.zsh-theme" )
    elif [[ -e "$pdir_path/${pbase}.theme.zsh" ]]; then
        reply=( "$pdir_path/${pbase}.theme.zsh" )
    else
        reply=(
            $pdir_path/*.plugin.zsh(DN) $pdir_path/*.zsh-theme(DN) $pdir_path/init.zsh(DN)
            $pdir_path/*.zsh(DN) $pdir_path/*.sh(DN) $pdir_path/.zshrc(DN)
        )
    fi
} # }}}
# FUNCTION: -zplg-register-plugin {{{
# Adds the plugin to ZPLG_REGISTERED_PLUGINS array and to the
# zsh_loaded_plugins array (managed according to the plugin standard:
# http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html)
-zplg-register-plugin() {
    local uspl2="$1" mode="$2" teleid="$3"
    integer ret=0

    if [[ -z "${ZPLG_REGISTERED_PLUGINS[(r)$uspl2]}" ]]; then
        ZPLG_REGISTERED_PLUGINS+=( "$uspl2" )
    else
        # Allow overwrite-load, however warn about it
        [[ -z "${ZPLGM[TEST]}${${+ZPLG_ICE[wait]}:#0}${ZPLG_ICE[load]}${ZPLG_ICE[subscribe]}" && ${ZPLGM[MUTE_WARNINGS]} != 1 ]] && print "Warning: plugin \`$uspl2' already registered, will overwrite-load"
        ret=1
    fi

    # Support Zsh plugin standard
    zsh_loaded_plugins+=( "$teleid" )

    # Full or light load?
    [[ "$mode" = "light" ]] && ZPLG_REGISTERED_STATES[$uspl2]="1" || ZPLG_REGISTERED_STATES[$uspl2]="2"

    ZPLG_REPORTS[$uspl2]=""            ZPLG_CUR_BIND_MAP=( empty 1 )
    # Functions
    ZPLGM[FUNCTIONS_BEFORE__$uspl2]=""   ZPLGM[FUNCTIONS_AFTER__$uspl2]=""
    ZPLGM[FUNCTIONS__$uspl2]=""
    # Objects
    ZPLGM[ZSTYLES__$uspl2]=""            ZPLGM[BINDKEYS__$uspl2]=""
    ZPLGM[ALIASES__$uspl2]=""
    # Widgets
    ZPLGM[WIDGETS_SAVED__$uspl2]=""      ZPLGM[WIDGETS_DELETE__$uspl2]=""
    # Rest (options and (f)path)
    ZPLGM[OPTIONS__$uspl2]=""            ZPLGM[PATH__$uspl2]=""
    ZPLGM[OPTIONS_BEFORE__$uspl2]=""     ZPLGM[OPTIONS_AFTER__$uspl2]=""
    ZPLGM[FPATH__$uspl2]=""

    return $ret
} # }}}
# FUNCTION: @zplg-register-z-annex {{{
# Registers the z-annex inside Zplugin – i.e. an Zplugin extension
@zplg-register-annex() {
    local name="$1" type="$2" handler="$3" helphandler="$4" icemods="$5" key="z-annex ${(q)2}"
    ZPLG_EXTS[seqno]=$(( ${ZPLG_EXTS[seqno]:-0} + 1 ))
    ZPLG_EXTS[$key${${(M)type#hook:}:+ ${ZPLG_EXTS[seqno]}}]="${ZPLG_EXTS[seqno]} z-annex-data: ${(q)name} ${(q)type} ${(q)handler} ${(q)helphandler} ${(q)icemods}"
    ZPLG_EXTS[ice-mods]="${ZPLG_EXTS[ice-mods]}${icemods:+|}$icemods"
}
# }}}
# FUNCTION: @zsh-plugin-run-on-update {{{
# The Plugin Standard required mechanism, see:
# http://zdharma.org/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html
@zsh-plugin-run-on-unload() {
    ZPLG_ICE[ps-on-unload]="${(j.; .)@}"
    -zplg-pack-ice "$id_as" ""
}
# }}}
# FUNCTION: @zsh-plugin-run-on-update {{{
# The Plugin Standard required mechanism
@zsh-plugin-run-on-update() {
    ZPLG_ICE[ps-on-update]="${(j.; .)@}"
    -zplg-pack-ice "$id_as" ""
}
# }}}

#
# Remaining functions
#

# FUNCTION: -zplg-prepare-home {{{
# Creates all directories needed by Zplugin, first checks if they
# already exist.
-zplg-prepare-home() {
    [[ -n "${ZPLGM[HOME_READY]}" ]] && return
    ZPLGM[HOME_READY]="1"

    [[ ! -d "${ZPLGM[HOME_DIR]}" ]] && {
        command mkdir  -p "${ZPLGM[HOME_DIR]}"
        # For compaudit
        command chmod go-w "${ZPLGM[HOME_DIR]}"
        # Also set up */bin and ZPFX in general
        command mkdir 2>/dev/null -p ${ZPFX}/bin
    }
    [[ ! -d "${ZPLGM[PLUGINS_DIR]}/_local---zplugin" ]] && {
        command mkdir -p "${ZPLGM[PLUGINS_DIR]}/_local---zplugin"
        # For compaudit
        command chmod go-w "${ZPLGM[PLUGINS_DIR]}"

        # Prepare mock-like plugin for Zplugin itself
        command ln -s "${ZPLGM[BIN_DIR]}/_zplugin" "${ZPLGM[PLUGINS_DIR]}/_local---zplugin"

        # Also set up */bin and ZPFX in general
        command mkdir 2>/dev/null -p ${ZPFX}/bin
    }
    [[ ! -d "${ZPLGM[COMPLETIONS_DIR]}" ]] && {
        command mkdir "${ZPLGM[COMPLETIONS_DIR]}"
        # For compaudit
        command chmod go-w "${ZPLGM[COMPLETIONS_DIR]}"

        # Symlink _zplugin completion into _local---zplugin directory
        command ln -s "${ZPLGM[PLUGINS_DIR]}/_local---zplugin/_zplugin" "${ZPLGM[COMPLETIONS_DIR]}"

        # Also set up */bin and ZPFX in general
        command mkdir 2>/dev/null -p ${ZPFX}/bin
    }
    [[ ! -d "${ZPLGM[SNIPPETS_DIR]}" ]] && {
        command mkdir "${ZPLGM[SNIPPETS_DIR]}"
        command chmod go-w "${ZPLGM[SNIPPETS_DIR]}"
        ( cd ${ZPLGM[SNIPPETS_DIR]}; command ln -s "OMZ::plugins" "plugins"; )

        # Also create the SERVICES_DIR
        command mkdir -p "${ZPLGM[SERVICES_DIR]}"
        command chmod go-w "${ZPLGM[SERVICES_DIR]}"

        # Also set up */bin and ZPFX in general
        command mkdir 2>/dev/null -p ${ZPFX}/bin
    }
} # }}}
# FUNCTION: -zplg-load-ices {{{
-zplg-load-ices() {
    local id_as="$1" __key __path
    local -a ice_order
    ice_order=(
        svn proto from teleid bindmap cloneopts id-as depth if wait load
        unload blockf pick bpick src as ver silent lucid notify mv cp
        atinit atclone atload atpull nocd run-atpull has cloneonly make
        service trackbinds multisrc compile nocompile nocompletions
        reset-prompt wrap-track reset sh \!sh bash \!bash ksh \!ksh csh
        \!csh aliases countdown ps-on-unload ps-on-update trigger-load
        light-mode is-snippet atdelete pack git verbose on-update-of
        subscribe
        ${(@us.|.)${ZPLG_EXTS[ice-mods]//\'\'/}}
    )
    __path=${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}/._zplugin
    [[ -d $__path ]] || __path=${ZPLGM[SNIPPETS_DIR]}/$id_as/._zplugin
    for __key in "${ice_order[@]}"; do
        (( ${+ZPLG_ICE[$__key]} )) && continue
        [[ -f "$__path"/"$__key" ]] && ZPLG_ICE[$__key]="$(<$__path/$__key)"
    done
    [[ -n ${ZPLG_ICE[on-update-of]} ]] && ZPLG_ICE[subscribe]="${ZPLG_ICE[subscribe]:-${ZPLG_ICE[on-update-of]}}"
    [[ ${ZPLG_ICE[as]} = program ]] && ZPLG_ICE[as]="command"
    [[ -n ${ZPLG_ICE[pick]} ]] && ZPLG_ICE[pick]="${ZPLG_ICE[pick]//\$ZPFX/${ZPFX%/}}"
    return 0
}
# }}}
# FUNCTION: -zplg-load {{{
# Implements the exposed-to-user action of loading a plugin.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin name, if the third format is used
-zplg-load () {
    typeset -F 3 SECONDS=0
    local mode="$3" rst="0" retval=0 key
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" id_as="${ZPLG_ICE[id-as]:-${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]}}"
    ZPLG_ICE[teleid]="$user${${user:#(%|/)*}:+/}$plugin"

    ZPLG_SICE[$id_as]=""
    -zplg-pack-ice "$id_as"
    if [[ "$user" != "%" && ! -d "${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}" ]]; then
        (( ${+functions[-zplg-setup-plugin-dir]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
        reply=( "$user" "$plugin" ) REPLY=git
        if (( ${+ZPLG_ICE[pack]} )) {
            if ! -zplg-get-package "$user" "$plugin" "$id_as" \
                "${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}" \
                "${ZPLG_ICE[pack]:-default}"
            then
                zle && { print; zle .reset-prompt; }
                return 1
            fi
        }
        user=${reply[-2]} plugin=${reply[-1]}
        [[ $REPLY = snippet ]] && {
            -zplg-load-snippet $plugin
            return $?
        }
        if ! -zplg-setup-plugin-dir "$user" "$plugin" "$id_as" "$REPLY"; then
            zle && { print; zle .reset-prompt; }
            return 1
        fi
        zle && rst=1
    fi

    (( ${+ZPLG_ICE[cloneonly]} )) && return 0

    -zplg-register-plugin "$id_as" "$mode" "${ZPLG_ICE[teleid]}"

    local -a arr
    reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atinit <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
        "${arr[5]}" "plugin" "$user" "$plugin" "$id_as" "${${${(M)user:#%}:+$plugin}:-${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}}" \!atinit
    done

    (( ${+ZPLG_ICE[atinit]} )) && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "${${${(M)user:#%}:+$plugin}:-${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}}"; } && eval "${ZPLG_ICE[atinit]}"; ((1)); } || eval "${ZPLG_ICE[atinit]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:atinit <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
        "${arr[5]}" "plugin" "$user" "$plugin" "$id_as" "${${${(M)user:#%}:+$plugin}:-${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}}" atinit
    done

    -zplg-load-plugin "$user" "$plugin" "$id_as" "$mode" "$rst"; retval=$?
    (( ${+ZPLG_ICE[notify]} == 1 )) && { [[ "$retval" -eq 0 || -n "${(M)ZPLG_ICE[notify]#\!}" ]] && { local msg; eval "msg=\"${ZPLG_ICE[notify]#\!}\""; -zplg-deploy-message @msg "$msg" } || -zplg-deploy-message @msg "notify: Plugin not loaded / loaded with problem, the return code: $retval"; }
    (( ${+ZPLG_ICE[reset-prompt]} == 1 )) && -zplg-deploy-message @rst
    ZPLGM[TIME_INDEX]=$(( ${ZPLGM[TIME_INDEX]:-0} + 1 ))
    ZPLGM[TIME_${ZPLGM[TIME_INDEX]}_${id_as//\//---}]=$SECONDS
    ZPLGM[AT_TIME_${ZPLGM[TIME_INDEX]}_${id_as//\//---}]=$EPOCHREALTIME
    return $retval
} # }}}
# FUNCTION: -zplg-load-snippet {{{
# Implements the exposed-to-user action of loading a snippet.
#
# $1 - url (can be local, absolute path)
-zplg-load-snippet() {
    typeset -F 3 SECONDS=0
    local -a opts tmp ice
    zparseopts -E -D -a opts f -command u i || { print -r -- "Incorrect options (accepted ones: -f, --command)"; return 1; }
    local url="$1"
    integer correct=0 retval=0
    [[ -o ksharrays ]] && correct=1

    [[ -n "${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]}" ]] && \
        local -a precm=(
            emulate
            ${${(M)${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}:+-R}
            ${${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}
            ${${ZPLG_ICE[(i)(\!|)bash]}:+-${(s: :):-o noshglob -o braceexpand -o kshglob}}
            -c
        )
    # Remove leading whitespace and trailing /
    url="${${url#"${url%%[! $'\t']*}"}%/}"
    ZPLG_ICE[teleid]="$url"
    [[ ${ZPLG_ICE[as]} = null ]] && \
        ZPLG_ICE[pick]="${ZPLG_ICE[pick]:-/dev/null}"

    local local_dir dirname filename save_url="$url" id_as="${ZPLG_ICE[id-as]:-$url}"
    [[ -z ${opts[(r)-u]} ]] && -zplg-pack-ice "$id_as" ""

    # Allow things like $OSTYPE in the URL
    eval "url=\"$url\""

    # - case A: called from `update --all', ZPLG_ICE not packed (above), static ice will win
    # - case B: called from `snippet', ZPLG_ICE packed, so it will win
    # - case C: called from `update', ZPLG_ICE packed, so it will win
    tmp=( "${(Q@)${(z@)ZPLG_SICE[$id_as]}}" )
    (( ${#tmp} > 1 && ${#tmp} % 2 == 0 )) && { ice=( "${(kv)ZPLG_ICE[@]}" "${tmp[@]}" ); ZPLG_ICE=( "${ice[@]}" ); }
    tmp=( 1 )
    id_as="${ZPLG_ICE[id-as]:-$id_as}"

    # Oh-My-Zsh, Prezto and manual shorthands
    (( ${+ZPLG_ICE[svn]} )) && {
        [[ "$url" = *(OMZ::|robbyrussell*oh-my-zsh)* ]] && local ZSH="${ZPLGM[SNIPPETS_DIR]}"
        url[1-correct,5-correct]="${ZPLG_1MAP[${url[1-correct,5-correct]}]:-${url[1-correct,5-correct]}}"
    } || {
        url[1-correct,5-correct]="${ZPLG_2MAP[${url[1-correct,5-correct]}]:-${url[1-correct,5-correct]}}"
    }

    # Construct containing directory, extract final directory
    # into handy-variable $dirname
    filename="${${id_as%%\?*}:t}"
    dirname="${${id_as%%\?*}:t}"
    local_dir="${${${id_as%%\?*}:h}/:\/\//--}"
    [[ "$local_dir" = "." ]] && local_dir="" || local_dir="${${${${${local_dir#/}//\//--}//=/--EQ--}//\?/--QM--}//\&/--AMP--}"
    local_dir="${ZPLGM[SNIPPETS_DIR]}${local_dir:+/$local_dir}"

    # Download or copy the file
    if [[ -n "${opts[(r)-f]}" || ! -e "$local_dir/$dirname/._zplugin" ]]; then
        (( ${+functions[-zplg-download-snippet]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
        [[ "$url" = *github.com* && ! "$url" = */raw/* ]] && url="${${url/\/blob\///raw/}/\/tree\///raw/}"
        -zplg-download-snippet "$save_url" "$url" "$id_as" "$local_dir" "$dirname" "$filename" "${opts[(r)-u]}" || tmp=( 0 )
    fi

    (( ${+ZPLG_ICE[cloneonly]} || !tmp[1-correct] )) && return 0

    ZPLG_SNIPPETS[$id_as]="$id_as <${${ZPLG_ICE[svn]+svn}:-single file}>"

    [[ -z "${opts[(r)-u]}" ]] && { ZPLGM[CUR_USPL2]="$id_as"; ZPLG_REPORTS[$id_as]=""; }

    local -a arr
    [[ -n "${opts[(r)-u]}" ]] && {
        reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atinit <->]}" )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
            "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \!atinit
        done
    }

    (( ${+ZPLG_ICE[atinit]} )) && [[ -z "${opts[(r)-u]}" ]] && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && eval "${ZPLG_ICE[atinit]}"; ((1)); } || eval "${ZPLG_ICE[atinit]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    local -a list
    [[ -z "${opts[(r)-u]}" ]] && {
        reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:atinit <->]}" )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
            "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" atinit
        done
    }

    local ZERO
    if [[ -z ${opts[(r)-u]} && -z ${opts[(r)--command]} && ( -z ${ZPLG_ICE[as]} || ${ZPLG_ICE[as]} = null ) ]]; then
        # Source the file with compdef shadowing
        if [[ ${ZPLGM[SHADOWING]} = inactive ]]; then
            # Shadowing code is inlined from -zplg-shadow-on
            (( ${+functions[compdef]} )) && ZPLGM[bkp-compdef]="${functions[compdef]}" || builtin unset "ZPLGM[bkp-compdef]"
            functions[compdef]='--zplg-shadow-compdef "$@";'
            ZPLGM[SHADOWING]="1"
        else
            (( ++ ZPLGM[SHADOWING] ))
        fi

        # Add to fpath
        [[ -d $local_dir/$dirname/functions ]] && {
            [[ -z ${fpath[(r)$local_dir/$dirname/functions]} ]] && fpath+=( "$local_dir/$dirname/functions" )
            () {
                builtin setopt localoptions extendedglob
                autoload $local_dir/$dirname/functions/^([_.]*|prompt_*_setup|README*)(D-.N:t)
            }
        }

        # Source
        if (( ${+ZPLG_ICE[svn]} == 0 )); then
            [[ ${+ZPLG_ICE[pick]} = 0 ]] && list=( "$local_dir/$dirname/$filename" )
            [[ -n ${ZPLG_ICE[pick]} ]] && list=( ${(M)~ZPLG_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZPLG_ICE[pick]}(DN) )
        else
            if [[ -n ${ZPLG_ICE[pick]} ]]; then
                list=( ${(M)~ZPLG_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZPLG_ICE[pick]}(DN) )
            elif (( ${+ZPLG_ICE[pick]} == 0 )); then
                list=(
                    $local_dir/$dirname/*.plugin.zsh(DN) $local_dir/$dirname/*.zsh-theme(DN) $local_dir/$dirname/init.zsh(DN)
                    $local_dir/$dirname/*.zsh(DN) $local_dir/$dirname/*.sh(DN) $local_dir/$dirname/.zshrc(DN)
                )
            fi
        fi

        [[ -f "${list[1-correct]}" ]] && {
            ZERO="${list[1-correct]}"
            (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); }
            (( 0 == retval )) && [[ "$id_as" = PZT::* || "$id_as" = https://github.com/sorin-ionescu/prezto/* ]] && zstyle ":prezto:module:${${id_as%/init.zsh}:t}" loaded 'yes'
            (( 1 ))
        } || { [[ ${+ZPLG_ICE[pick]} = 1 && -z "${ZPLG_ICE[pick]}" || "${ZPLG_ICE[pick]}" = /dev/null ]] || { print -r -- "Snippet not loaded ($id_as)"; retval=1; } }

        [[ -n "${ZPLG_ICE[src]}" ]] && { ZERO="${${(M)ZPLG_ICE[src]##/*}:-$local_dir/$dirname/${ZPLG_ICE[src]}}"; (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); }; }
        [[ -n ${ZPLG_ICE[multisrc]} ]] && { local __oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; }; eval "reply=(${ZPLG_ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$local_dir/$dirname/$fname}"; (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); }; done; }

        # Run the atload hooks right before atload ice
        reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atload <->]}" )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
            "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \!atload
        done

        # Run the functions' wrapping & tracking requests
        [[ -n "${ZPLG_ICE[wrap-track]}" ]] && \
            -zplg-wrap-track-functions "$save_url" "" "$id_as"

        [[ "${ZPLG_ICE[atload][1]}" = "!" ]] && { -zplg-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$local_dir/$dirname/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ZPLG_ICE[atload]#\!}"; (( 1 )); } || eval "${ZPLG_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

        (( -- ZPLGM[SHADOWING] == 0 )) && { ZPLGM[SHADOWING]="inactive"; builtin setopt noaliases; (( ${+ZPLGM[bkp-compdef]} )) && functions[compdef]="${ZPLGM[bkp-compdef]}" || unfunction "compdef"; builtin setopt aliases; }
    elif [[ -n "${opts[(r)--command]}" || "${ZPLG_ICE[as]}" = "command" ]]; then
        # Subversion - directory and multiple files possible
        if (( ${+ZPLG_ICE[svn]} )); then
            if [[ -n ${ZPLG_ICE[pick]} ]]; then
                list=( ${(M)~ZPLG_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZPLG_ICE[pick]}(DN) )
                [[ -n "${list[1-correct]}" ]] && local xpath="${list[1-correct]:h}" xfilepath="${list[1-correct]}"
            else
                local xpath="$local_dir/$dirname"
            fi
        else
            local xpath="$local_dir/$dirname" xfilepath="$local_dir/$dirname/$filename"
            # This doesn't make sense, but users may come up with something
            [[ -n ${ZPLG_ICE[pick]} ]] && {
                list=( ${(M)~ZPLG_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZPLG_ICE[pick]}(DN) )
                [[ -n "${list[1-correct]}" ]] && xpath="${list[1-correct]:h}" xfilepath="${list[1-correct]}"
            }
        fi
        [[ -z "${opts[(r)-u]}" && -n "$xpath" && -z "${path[(er)$xpath]}" ]] && path=( "${xpath%/}" ${path[@]} )
        [[ -n "$xfilepath" && -f "$xfilepath" && ! -x "$xfilepath" ]] && command chmod a+x "$xfilepath" ${list[@]:#$xfilepath}
        [[ -z "${opts[(r)-u]}" && ( -n "${ZPLG_ICE[src]}" || -n "${ZPLG_ICE[multisrc]}" || "${ZPLG_ICE[atload][1]}" = "!" ) ]] && {
            if [[ "${ZPLGM[SHADOWING]}" = "inactive" ]]; then
                # Shadowing code is inlined from -zplg-shadow-on
                (( ${+functions[compdef]} )) && ZPLGM[bkp-compdef]="${functions[compdef]}" || builtin unset "ZPLGM[bkp-compdef]"
                functions[compdef]='--zplg-shadow-compdef "$@";'
                ZPLGM[SHADOWING]="1"
            else
                (( ++ ZPLGM[SHADOWING] ))
            fi
        }

        if [[ -z ${opts[(r)-u]} ]] {
            if [[ -n "${ZPLG_ICE[src]}" ]]; then
                ZERO="${${(M)ZPLG_ICE[src]##/*}:-$local_dir/$dirname/${ZPLG_ICE[src]}}"
                (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); }
            fi
            [[ -n ${ZPLG_ICE[multisrc]} ]] && { local __oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; }; eval "reply=(${ZPLG_ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$local_dir/$dirname/$fname}"; (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); }; done; }

            # Run the atload hooks right before atload ice
            reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atload <->]}" )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \!atload
            done

            # Run the functions' wrapping & tracking requests
            [[ -n "${ZPLG_ICE[wrap-track]}" ]] && \
                -zplg-wrap-track-functions "$save_url" "" "$id_as"

            [[ "${ZPLG_ICE[atload][1]}" = "!" ]] && { -zplg-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$local_dir/$dirname/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ZPLG_ICE[atload]#\!}"; ((1)); } || eval "${ZPLG_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }
        }

        [[ -z "${opts[(r)-u]}" && ( -n "${ZPLG_ICE[src]}" || -n "${ZPLG_ICE[multisrc]}" || "${ZPLG_ICE[atload][1]}" = "!" ) ]] && {
            (( -- ZPLGM[SHADOWING] == 0 )) && { ZPLGM[SHADOWING]="inactive"; builtin setopt noaliases; (( ${+ZPLGM[bkp-compdef]} )) && functions[compdef]="${ZPLGM[bkp-compdef]}" || unfunction "compdef"; builtin setopt aliases; }
        }
    elif [[ "${ZPLG_ICE[as]}" = "completion" ]]; then
        ((1))
    fi

    # Updating – not sourcing, etc.
    [[ -n "${opts[(r)-u]}" ]] && return 0

    (( ${+ZPLG_ICE[atload]} )) && [[ "${ZPLG_ICE[atload][1]}" != "!" ]] && { ZERO="$local_dir/$dirname/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ZPLG_ICE[atload]}"; ((1)); } || eval "${ZPLG_ICE[atload]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:atload <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
        "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" atload
    done

    (( ${+ZPLG_ICE[notify]} == 1 )) && { [[ "$retval" -eq 0 || -n "${(M)ZPLG_ICE[notify]#\!}" ]] && { local msg; eval "msg=\"${ZPLG_ICE[notify]#\!}\""; -zplg-deploy-message @msg "$msg" } || -zplg-deploy-message @msg "notify: Plugin not loaded / loaded with problem, the return code: $retval"; }
    (( ${+ZPLG_ICE[reset-prompt]} == 1 )) && -zplg-deploy-message @rst

    ZPLGM[CUR_USPL2]=""
    ZPLGM[TIME_INDEX]=$(( ${ZPLGM[TIME_INDEX]:-0} + 1 ))
    ZPLGM[TIME_${ZPLGM[TIME_INDEX]}_${id_as}]=$SECONDS
    ZPLGM[AT_TIME_${ZPLGM[TIME_INDEX]}_${id_as}]=$EPOCHREALTIME
    return $retval
} # }}}
# FUNCTION: -zplg-compdef-replay {{{
# Runs gathered compdef calls. This allows to run `compinit'
# after loading plugins.
-zplg-compdef-replay() {
    local quiet="$1"
    typeset -a pos

    # Check if compinit was loaded
    if [[ "${+functions[compdef]}" = "0" ]]; then
        print "Compinit isn't loaded, cannot do compdef replay"
        return 1
    fi

    # In the same order
    local cdf
    for cdf in "${ZPLG_COMPDEF_REPLAY[@]}"; do
        pos=( "${(z)cdf}" )
        # When ZPLG_COMPDEF_REPLAY empty (also when only white spaces)
        [[ "${#pos[@]}" = "1" && -z "${pos[-1]}" ]] && continue
        pos=( "${(Q)pos[@]}" )
        [[ "$quiet" = "-q" ]] || print "Running compdef ${pos[*]}"
        compdef "${pos[@]}"
    done

    return 0
} # }}}
# FUNCTION: -zplg-compdef-clear {{{
# Implements user-exposed functionality to clear gathered compdefs.
-zplg-compdef-clear() {
    local quiet="$1" count="${#ZPLG_COMPDEF_REPLAY}"
    ZPLG_COMPDEF_REPLAY=( )
    [[ "$quiet" = "-q" ]] || print "Compdef-replay cleared (had $count entries)"
} # }}}
# FUNCTION: -zplg-add-report {{{
# Adds a report line for given plugin.
#
# $1 - uspl2, i.e. user/plugin
# $2, ... - the text
-zplg-add-report() {
    # Use zplugin binary module if available
    [[ -n "$1" ]] && { (( ${+builtins[zpmod]} )) && zpmod report-append "$1" "$2"$'\n' || ZPLG_REPORTS[$1]+="$2"$'\n'; }
    [[ "${ZPLGM[DTRACE]}" = "1" ]] && { (( ${+builtins[zpmod]} )) && zpmod report-append "_dtrace/_dtrace" "$2"$'\n' || ZPLG_REPORTS[_dtrace/_dtrace]+="$2"$'\n'; }
    return 0
} # }}}
# FUNCTION: -zplg-load-plugin {{{
# Lower-level function for loading a plugin.
#
# $1 - user
# $2 - plugin
# $3 - mode (light or load)
-zplg-load-plugin() {
    local user="$1" plugin="$2" id_as="$3" mode="$4" correct=0 retval=0
    ZPLGM[CUR_USR]="$user" ZPLG_CUR_PLUGIN="$plugin" ZPLGM[CUR_USPL2]="$id_as"
    [[ -o ksharrays ]] && correct=1

    [[ -n "${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]}" ]] && \
        local -a precm=(
            emulate
            ${${(M)${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}:+-R}
            ${${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}
            ${${ZPLG_ICE[(i)(\!|)bash]}:+-${(s: :):-o noshglob -o braceexpand -o kshglob}}
            -c
        )

    [[ ${ZPLG_ICE[as]} = null ]] && \
        ZPLG_ICE[pick]="${ZPLG_ICE[pick]:-/dev/null}"

    local pbase="${${plugin:t}%(.plugin.zsh|.zsh|.git)}"
    [[ "$user" = "%" ]] && local pdir_path="$plugin" || local pdir_path="${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}"
    local pdir_orig="$pdir_path"

    if [[ "${ZPLG_ICE[as]}" = "command" ]]; then
        reply=()
        if [[ -n "${ZPLG_ICE[pick]}" && "${ZPLG_ICE[pick]}" != "/dev/null" ]]; then
            reply=( ${(M)~ZPLG_ICE[pick]##/*}(DN) $pdir_path/${~ZPLG_ICE[pick]}(DN) )
            [[ -n "${reply[1-correct]}" ]] && pdir_path="${reply[1-correct]:h}"
        fi
        [[ -z "${path[(er)$pdir_path]}" ]] && {
            [[ "$mode" != "light" ]] && -zplg-diff-env "${ZPLGM[CUR_USPL2]}" begin
            path=( "${pdir_path%/}" ${path[@]} )
            [[ "$mode" != "light" ]] && -zplg-diff-env "${ZPLGM[CUR_USPL2]}" end
            -zplg-add-report "${ZPLGM[CUR_USPL2]}" "$ZPLGM[col-info2]$pdir_path$ZPLGM[col-rst] added to \$PATH"
        }
        [[ -n "${reply[1-correct]}" && ! -x "${reply[1-correct]}" ]] && command chmod a+x ${reply[@]}

        [[ -n "${ZPLG_ICE[src]}" || -n "${ZPLG_ICE[multisrc]}" || "${ZPLG_ICE[atload][1]}" = "!" ]] && {
            if [[ "${ZPLGM[SHADOWING]}" = "inactive" ]]; then
                (( ${+functions[compdef]} )) && ZPLGM[bkp-compdef]="${functions[compdef]}" || builtin unset "ZPLGM[bkp-compdef]"
                functions[compdef]='--zplg-shadow-compdef "$@";'
                ZPLGM[SHADOWING]="1"
            else
                (( ++ ZPLGM[SHADOWING] ))
            fi
        }

        local ZERO
        [[ -n ${ZPLG_ICE[src]} ]] && { ZERO="${${(M)ZPLG_ICE[src]##/*}:-$pdir_orig/${ZPLG_ICE[src]}}"; (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); }; }
        [[ -n ${ZPLG_ICE[multisrc]} ]] && { local __oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; }; eval "reply=(${ZPLG_ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$pdir_orig/$fname}"; (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); }; done; }

        # Run the atload hooks right before atload ice
        reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atload <->]}" )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
            "${arr[5]}" "plugin" "$user" "$plugin" "$id_as" "$pdir_orig" \!atload
        done

        # Run the functions' wrapping & tracking requests
        [[ -n "${ZPLG_ICE[wrap-track]}" ]] && \
            -zplg-wrap-track-functions "$user" "$plugin" "$id_as"

        [[ ${ZPLG_ICE[atload][1]} = "!" ]] && { -zplg-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$pdir_orig/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; } && builtin eval "${ZPLG_ICE[atload]#\!}"; } || eval "${ZPLG_ICE[atclone]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

        [[ -n "${ZPLG_ICE[src]}" || -n "${ZPLG_ICE[multisrc]}" || "${ZPLG_ICE[atload][1]}" = "!" ]] && {
            (( -- ZPLGM[SHADOWING] == 0 )) && { ZPLGM[SHADOWING]="inactive"; builtin setopt noaliases; (( ${+ZPLGM[bkp-compdef]} )) && functions[compdef]="${ZPLGM[bkp-compdef]}" || unfunction "compdef"; builtin setopt aliases; }
        }
    elif [[ "${ZPLG_ICE[as]}" = "completion" ]]; then
        ((1))
    else
        if [[ -n ${ZPLG_ICE[pick]} ]]; then
            [[ "${ZPLG_ICE[pick]}" = "/dev/null" ]] && reply=( "/dev/null" ) || reply=( ${(M)~ZPLG_ICE[pick]##/*}(DN) $pdir_path/${~ZPLG_ICE[pick]}(DN) )
        elif [[ -e "$pdir_path/${pbase}.plugin.zsh" ]]; then
            reply=( "$pdir_path/${pbase}.plugin.zsh" )
        else
            # The common file to source isn't there, so:
            -zplg-find-other-matches "$pdir_path" "$pbase"
        fi

        #[[ "${#reply}" -eq "0" ]] && return 1

        # Get first one
        local fname="${reply[1-correct]:t}"
        pdir_path="${reply[1-correct]:h}"

        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Source $fname ${${${(M)mode:#light}:+(no reporting)}:-$ZPLGM[col-info2](reporting enabled)$ZPLGM[col-rst]}"

        # Light and compdef mode doesn't do diffs and shadowing
        [[ "$mode" != (light|light-b) ]] && -zplg-diff "${ZPLGM[CUR_USPL2]}" begin

        -zplg-shadow-on "${mode:-load}"

        # We need some state, but user wants his for his plugins
        (( ${+ZPLG_ICE[blockf]} )) && { local -a fpath_bkp; fpath_bkp=( "${fpath[@]}" ); }
        local ZERO="$pdir_path/$fname"
        (( ${+ZPLG_ICE[aliases]} )) || builtin setopt noaliases
        (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); }
        [[ -n ${ZPLG_ICE[src]} ]] && { ZERO="${${(M)ZPLG_ICE[src]##/*}:-$pdir_orig/${ZPLG_ICE[src]}}"; (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); }; }
        [[ -n ${ZPLG_ICE[multisrc]} ]] && { local __oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; }; eval "reply=(${ZPLG_ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$pdir_orig/$fname}"; (( ${+ZPLG_ICE[silent]} )) && { { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n "$precm" ]] && { builtin ${precm[@]} 'source "$ZERO"'; (( 1 )); } || builtin source "$ZERO" }; (( retval += $? )); } done; }

        # Run the atload hooks right before atload ice
        reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atload <->]}" )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
            "${arr[5]}" "plugin" "$user" "$plugin" "$id_as" "$pdir_orig" \!atload
        done

        # Run the functions' wrapping & tracking requests
        [[ -n "${ZPLG_ICE[wrap-track]}" ]] && \
            -zplg-wrap-track-functions "$user" "$plugin" "$id_as"

        [[ ${ZPLG_ICE[atload][1]} = "!" ]] && { -zplg-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$pdir_orig/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; } && builtin eval "${ZPLG_ICE[atload]#\!}"; ((1)); } || eval "${ZPLG_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }
        (( ${+ZPLG_ICE[aliases]} )) || builtin unsetopt noaliases
        (( ${+ZPLG_ICE[blockf]} )) && { fpath=( "${fpath_bkp[@]}" ); }

        -zplg-shadow-off "${mode:-load}"

        [[ "$mode" != (light|light-b) ]] && -zplg-diff "${ZPLGM[CUR_USPL2]}" end
    fi

    [[ "${+ZPLG_ICE[atload]}" = 1 && "${ZPLG_ICE[atload][1]}" != "!" ]] && { ZERO="$pdir_orig/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; } && builtin eval "${ZPLG_ICE[atload]}"; ((1)); } || eval "${ZPLG_ICE[atload]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:atload <->]}" )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
        "${arr[5]}" "plugin" "$user" "$plugin" "$id_as" "$pdir_orig" atload
    done

    # Mark no load is in progress
    ZPLGM[CUR_USR]="" ZPLG_CUR_PLUGIN="" ZPLGM[CUR_USPL2]=""

    (( $5 )) && { print; zle .reset-prompt; }
    return $retval
} # }}}
# FUNCTION: -zplg-add-fpath {{{
-zplg-add-fpath() {
    [[ "$1" = (-f|--front) ]] && { shift; integer front=1; }
    -zplg-any-to-user-plugin "$1" ""
    local id_as="$1" add_dir="$2" user="${reply[-2]}" plugin="${reply[-1]}"
    (( front )) && \
        fpath[1,0]=${${${(M)user:#%}:+$plugin}:-${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}}${add_dir:+/$add_dir} || \
        fpath+=(
            ${${${(M)user:#%}:+$plugin}:-${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}}${add_dir:+/$add_dir}
        )
}
# }}}
# FUNCTION: -zplg-run {{{
# Run code inside plugin's folder
# It uses the `correct' parameter from upper's scope zplugin()
-zplg-run() {
    if [[ "$1" = (-l|--last) ]]; then
        { set -- "${ZPLGM[last-run-plugin]:-$(<${ZPLGM[BIN_DIR]}/last-run-object.txt)}" "${@[2-correct,-1]}"; } &>/dev/null
        [[ -z "$1" ]] && { print "${ZPLGM[col-error]}Error: No last plugin available, please specify as the first argument${ZPLGM[col-rst]}"; return 1; }
    else
        integer __nolast=1
    fi
    -zplg-any-to-user-plugin "$1" ""
    local __id_as="$1" __user="${reply[-2]}" __plugin="${reply[-1]}" __oldpwd="$PWD"
    () {
        setopt localoptions noautopushd
        builtin cd &>/dev/null -q "${${${(M)__user:#%}:+$__plugin}:-${ZPLGM[PLUGINS_DIR]}/${__id_as//\//---}}"
    }
    if (( $? == 0 )); then
        (( __nolast )) && { print -r "$1" >! ${ZPLGM[BIN_DIR]}/last-run-object.txt; }
        ZPLGM[last-run-plugin]="$1"
        eval "${@[2-correct,-1]}"
        () { setopt localoptions noautopushd; builtin cd -q "$__oldpwd"; }
    else
        print "${ZPLGM[col-error]}Error: no such plugin${ZPLGM[col-rst]}"
    fi
}
# }}}

#
# Dtrace
#

# FUNCTION: -zplg-debug-start {{{
# Starts Dtrace, i.e. session tracking for changes in Zsh state.
-zplg-debug-start() {
    if [[ "${ZPLGM[DTRACE]}" = "1" ]]; then
        print "${ZPLGM[col-error]}Dtrace is already active, stop it first with \`dstop'${ZPLGM[col-rst]}"
        return 1
    fi

    ZPLGM[DTRACE]="1"

    -zplg-diff "_dtrace/_dtrace" begin

    # Full shadowing on
    -zplg-shadow-on "dtrace"
} # }}}
# FUNCTION: -zplg-debug-stop {{{
# Stops Dtrace, i.e. session tracking for changes in Zsh state.
-zplg-debug-stop() {
    ZPLGM[DTRACE]="0"

    # Shadowing fully off
    -zplg-shadow-off "dtrace"

    # Gather end data now, for diffing later
    -zplg-diff "_dtrace/_dtrace" end
} # }}}
# FUNCTION: -zplg-clear-debug-report {{{
# Forgets dtrace repport gathered up to this moment.
-zplg-clear-debug-report() {
    -zplg-clear-report-for "_dtrace/_dtrace"
} # }}}
# FUNCTION: -zplg-debug-unload {{{
# Reverts changes detected by dtrace run.
-zplg-debug-unload() {
    if [[ "${ZPLGM[DTRACE]}" = "1" ]]; then
        print "Dtrace is still active, end it with \`dstop'"
    else
        -zplg-unload "_dtrace" "_dtrace"
    fi
} # }}}

#
# Ice support
#

# FUNCTION: -zplg-ice {{{
# Parses ICE specification (`zplg ice' subcommand), puts the result
# into ZPLG_ICE global hash. The ice-spec is valid for next command
# only (i.e. it "melts"), but it can then stick to plugin and activate
# e.g. at update.
-zplg-ice() {
    builtin setopt localoptions noksharrays extendedglob warncreateglobal typesetsilent noshortloops
    integer retval
    local bit exts="${~ZPLG_EXTS[ice-mods]//\'\'/}"
    for bit; do
        [[ "$bit" = (#b)(--|)(teleid|from|proto|cloneopts|depth|wait|load|\
unload|on-update-of|subscribe|if|has|cloneonly|nocloneonly|blockf|\
svn|nosvn|pick|nopick|src|bpick|as|ver|silent|lucid|mv|cp|atinit|\
atload|atpull|atclone|run-atpull|norun-atpull|make|nomake|notify|\
nonotify|reset-prompt|service|compile|nocompile|nocompletions|multisrc|\
id-as|bindmap|trackbinds|notrackbinds|nocd|once|wrap-track|reset|\
noreset|sh|\!sh|bash|\!bash|ksh|\!ksh|csh|\!csh|aliases|noaliases|\
countdown|nocountdown|trigger-load|light-mode|is-snippet|pack|\
atdelete|git|verbose${~exts})(*)
        ]] && \
            ZPLG_ICES[${match[2]}]+="${ZPLG_ICES[${match[2]}]:+;}${match[3]#(:|=)}" || \
            break
        retval+=1
    done
    [[ ${ZPLG_ICES[as]} = program ]] && ZPLG_ICES[as]="command"
    [[ -n ${ZPLG_ICES[on-update-of]} ]] && ZPLG_ICES[subscribe]="${ZPLG_ICES[subscribe]:-${ZPLG_ICES[on-update-of]}}"
    [[ -n ${ZPLG_ICES[pick]} ]] && ZPLG_ICES[pick]="${ZPLG_ICES[pick]//\$ZPFX/${ZPFX%/}}"
    return $retval
} # }}}
# FUNCTION: -zplg-pack-ice {{{
# Remembers all ice-mods, assigns them to concrete plugin. Ice spec
# is in general forgotten for second-next command (that's why it's
# called "ice" - it melts), however they glue to the object (plugin
# or snippet) mentioned in the next command – for later use with e.g.
# `zplugin update ...'
-zplg-pack-ice() {
    ZPLG_SICE[$1${1:+${2:+/}}$2]+="${(j: :)${(q-kv)ZPLG_ICE[@]}} "
    ZPLG_SICE[$1${1:+${2:+/}}$2]="${ZPLG_SICE[$1${1:+${2:+/}}$2]# }"
    return 0
} # }}}
# FUNCTION: -zplg-service {{{
# Handles given service, i.e. obtains lock, runs it, or waits if no lock
#
# $1 - type "p" or "s" (plugin or snippet)
# $2 - mode - for plugin (light or load)
# $3 - id - URL or plugin ID or alias name (from id-as'')
-zplg-service() {
    local __tpe="$1" __mode="$2" __id="$3" __fle="${ZPLGM[SERVICES_DIR]}/${ZPLG_ICE[service]}.lock" __fd __cmd __tmp __lckd __strd=0
    { builtin print -n >! "$__fle"; } 2>/dev/null 1>&2
    [[ ! -e "${__fle:r}.fifo" ]] && command mkfifo "${__fle:r}.fifo" 2>/dev/null 1>&2
    [[ ! -e "${__fle:r}.fifo2" ]] && command mkfifo "${__fle:r}.fifo2" 2>/dev/null 1>&2

    typeset -g ZSRV_WORK_DIR="${ZPLGM[SERVICES_DIR]}" ZSRV_ID="${ZPLG_ICE[service]}"  # should be also set by other p-m

    while (( 1 )); do
        (
            while (( 1 )); do
                [[ ! -f "${__fle:r}.stop" ]] && if (( __lckd )) || zsystem 2>/dev/null 1>&2 flock -t 1 -f __fd -e "$__fle"; then
                    __lckd=1
                    if (( ! __strd )) || [[ "$__cmd" = "RESTART" ]]; then
                        [[ "$__tpe" = p ]] && { __strd=1; -zplg-load "$__id" "" "$__mode"; }
                        [[ "$__tpe" = s ]] && { __strd=1; -zplg-load-snippet "$__id" ""; }
                    fi
                    __cmd=""
                    while (( 1 )); do builtin read -t 32767 __cmd <>"${__fle:r}.fifo" && break; done
                else
                    return 0
                fi

                [[ "$__cmd" = (#i)"NEXT" ]] && { kill -TERM "$ZSRV_PID"; builtin read -t 2 __tmp <>"${__fle:r}.fifo2"; kill -HUP "$ZSRV_PID"; exec {__fd}>&-; __lckd=0; __strd=0; builtin read -t 10 __tmp <>"${__fle:r}.fifo2"; }
                [[ "$__cmd" = (#i)"STOP" ]] && { kill -TERM "$ZSRV_PID"; builtin read -t 2 __tmp <>"${__fle:r}.fifo2"; kill -HUP "$ZSRV_PID"; __strd=0; builtin print >! "${__fle:r}.stop"; }
                [[ "$__cmd" = (#i)"QUIT" ]] && { kill -HUP ${sysparams[pid]}; return 1; }
                [[ "$__cmd" != (#i)"RESTART" ]] && { __cmd=""; builtin read -t 1 __tmp <>"${__fle:r}.fifo2"; }
            done
        ) || break
        builtin read -t 1 __tmp <>"${__fle:r}.fifo2"
    done >>! "$ZSRV_WORK_DIR"/"$ZSRV_ID".log 2>&1
}
# }}}
# FUNCTION: -zplg-run-task {{{
# A backend, worker function of -zplg-scheduler. It obtains the tasks
# index and a few of its properties (like the type: plugin, snippet,
# service plugin, service snippet) and executes it first checking for
# additional conditions (like non-numeric wait'' ice).
#
# $1 - the pass number, either 1st or 2nd pass
# $2 - the time assigned to the task
# $3 - type: plugin, snippet, service plugin, service snippet
# $4 - task's index in the ZPLGM[WAIT_ICE_...] fields
# $5 - mode: load or light
# $6 - the plugin-spec or snippet URL or alias name (from id-as'')
-zplg-run-task() {
    local __pass="$1" __t="$2" __tpe="$3" __idx="$4" __mode="$5" __id="${(Q)6}" __opt="${(Q)7}" __action __s=1 __retval=0

    local -A ZPLG_ICE
    ZPLG_ICE=( "${(@Q)${(z@)ZPLGM[WAIT_ICE_${__idx}]}}" )

    local __id_as=${ZPLG_ICE[id-as]:-$__id}

    if [[ $__pass = 1 && "${${ZPLG_ICE[wait]#\!}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)}" = <-> ]]; then
        __action="${(M)ZPLG_ICE[wait]#\!}load"
    elif [[ $__pass = 1 && -n "${ZPLG_ICE[wait]#\!}" ]] && { eval "${ZPLG_ICE[wait]#\!}" || [[ $(( __s=0 )) = 1 ]]; }; then
        __action="${(M)ZPLG_ICE[wait]#\!}load"
    elif [[ -n "${ZPLG_ICE[load]#\!}" && -n $(( __s=0 )) && $__pass = 3 && -z "${ZPLG_REGISTERED_PLUGINS[(r)$__id_as]}" ]] && eval "${ZPLG_ICE[load]#\!}"; then
        __action="${(M)ZPLG_ICE[load]#\!}load"
    elif [[ -n "${ZPLG_ICE[unload]#\!}" && -n $(( __s=0 )) && $__pass = 2 && -n "${ZPLG_REGISTERED_PLUGINS[(r)$__id_as]}" ]] && eval "${ZPLG_ICE[unload]#\!}"; then
        __action="${(M)ZPLG_ICE[unload]#\!}remove"
    elif [[ -n "${ZPLG_ICE[subscribe]#\!}" && -n $(( __s=0 )) && "$__pass" = 3 ]] && \
        { local -a fts_arr
          eval "fts_arr=( ${ZPLG_ICE[subscribe]}(DNms-$(( EPOCHSECONDS -
                 ZPLGM[fts-${ZPLG_ICE[subscribe]}] ))) ); (( \${#fts_arr} ))" && \
             { ZPLGM[fts-${ZPLG_ICE[subscribe]}]="$EPOCHSECONDS"; __s=${+ZPLG_ICE[once]}; } || \
             (( 0 ))
        }
    then
        __action="${(M)ZPLG_ICE[subscribe]#\!}load"
    fi

    if [[ "$__action" = *load ]]; then
        if [[ "$__tpe" = "p" ]]; then
            -zplg-load "$__id" "" "$__mode"; (( __retval += $? ))
        elif [[ "$__tpe" = "s" ]]; then
            -zplg-load-snippet $__opt "${(@)=__id}"; (( __retval += $? ))
        elif [[ "$__tpe" = "p1" || "$__tpe" = "s1" ]]; then
            zpty -b "${__id//\//:} / ${ZPLG_ICE[service]}" '-zplg-service '"${(M)__tpe#?}"' "$__mode" "$__id"'
        fi
        (( ${+ZPLG_ICE[silent]} == 0 && ${+ZPLG_ICE[lucid]} == 0 && __retval == 0 )) && zle && zle -M "Loaded $__id"
    elif [[ "$__action" = *remove ]]; then
        (( ${+functions[-zplg-confirm]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-autoload.zsh"
        [[ "$__tpe" = "p" ]] && -zplg-unload "$__id_as" "" "-q"
        (( ${+ZPLG_ICE[silent]} == 0 && ${+ZPLG_ICE[lucid]} == 0 && __retval == 0 )) && zle && zle -M "Unloaded $__id_as"
    fi

    [[ "${REPLY::=$__action}" = \!* ]] && zle && zle .reset-prompt

    return $__s
}
# }}}
# FUNCTION: -zplg-deploy-message {{{
# Deploys a sub-prompt message to be displayed OR a `zle
# .reset-prompt' call to be invoked
-zplg-deploy-message() {
    [[ "$1" = <-> && ( ${#} = 1 || ( "$2" = (hup|nval|err) && ${#} = 2 ) ) ]] && { zle && {
            local alltext text IFS=$'\n' nl=$'\n'
            repeat 25; do read -r -u"$1" text; alltext+="${text:+$text$nl}"; done
            [[ "$alltext" = "@rst$nl" ]] && { builtin zle reset-prompt; ((1)); } || \
                { [[ -n "$alltext" ]] && builtin zle -M "$alltext"; }
        }
        builtin zle -F "$1"; exec {1}<&-
        return 0
    }
    local THEFD="13371337" hasw
    # The expansion is: if there is @sleep: pfx, then use what's after
    # it, otherwise substitute 0
    exec {THEFD} < <(LANG=C sleep $(( 0.01 + ${${${(M)1#@sleep:}:+${1#@sleep:}}:-0} )); print -r -- ${1:#(@msg|@sleep:*)} "${@[2,-1]}"; )
    command true # workaround a Zsh bug, see: http://www.zsh.org/mla/workers/2018/msg00966.html
    builtin zle -F "$THEFD" -zplg-deploy-message
}
# }}}

# FUNCTION: -zplg-submit-turbo {{{
# If `zplugin load`, `zplugin light` or `zplugin snippet`  will be
# preceded with `wait', `load', `unload' or `on-update-of`/`subscribe'
# ice-mods then the plugin or snipped is to be loaded in turbo-mode,
# and this function adds it to internal data structures, so that
# -zplg-scheduler can run (load, unload) this as a task.
-zplg-submit-turbo() {
    local tpe="$1" mode="$2" opt_uspl2="$3" opt_plugin="$4"

    ZPLG_ICE[wait]="${ZPLG_ICE[wait]%%.[0-9]##}"
    ZPLGM[WAIT_IDX]=$(( ${ZPLGM[WAIT_IDX]:-0} + 1 ))
    ZPLGM[WAIT_ICE_${ZPLGM[WAIT_IDX]}]="${(j: :)${(qkv)ZPLG_ICE[@]}}"
    ZPLGM[fts-${ZPLG_ICE[subscribe]}]="${ZPLG_ICE[subscribe]:+$EPOCHSECONDS}"

    [[ $tpe = s* ]] && \
        local id="${${opt_plugin:+$opt_plugin}:-$opt_uspl2}" || \
        local id="${${opt_plugin:+$opt_uspl2${${opt_uspl2:#%*}:+/}$opt_plugin}:-$opt_uspl2}"

    if [[ "${${ZPLG_ICE[wait]}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)}" = (\!|.|)<-> ]]; then
        ZPLG_TASKS+=( "$EPOCHSECONDS+${${ZPLG_ICE[wait]#(\!|.)}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)}+${${${(M)ZPLG_ICE[wait]%a}:+1}:-${${${(M)ZPLG_ICE[wait]%b}:+2}:-${${${(M)ZPLG_ICE[wait]%c}:+3}:-1}}} $tpe ${ZPLGM[WAIT_IDX]} ${mode:-_} ${(q)id} ${opt_plugin:+${(q)opt_uspl2}}" )
    elif [[ -n "${ZPLG_ICE[wait]}${ZPLG_ICE[load]}${ZPLG_ICE[unload]}${ZPLG_ICE[subscribe]}" ]]; then
        ZPLG_TASKS+=( "${${ZPLG_ICE[wait]:+0}:-1}+0+1 $tpe ${ZPLGM[WAIT_IDX]} ${mode:-_} ${(q)id} ${opt_plugin:+${(q)opt_uspl2}}" )
    fi
}
# }}}
# FUNCTION: -zplugin_scheduler_add_sh {{{
# Copies task into ZPLG_RUN array, called when a task timeouts.
# A small function ran from pattern in /-substitution as a math
# function.
-zplugin_scheduler_add_sh() {
    local idx="$1" in_wait="$__ar2" in_abc="$__ar3" ver_wait="$__ar4" ver_abc="$__ar5"
    if [[ ( "$in_wait" = "$ver_wait" || "$in_wait" -ge 4 ) && "$in_abc" = "$ver_abc" ]]; then
        ZPLG_RUN+=( "${ZPLG_TASKS[$idx]}" )
        return 1
    else
        return $idx
    fi
}
# }}}
# FUNCTION: -zplg-scheduler {{{
# Searches for timeout tasks, executes them. There's an array of tasks
# waiting for execution, this scheduler manages them, detects which ones
# should be run at current moment, decides to remove (or not) them from
# the array after execution.
#
# $1 - if "following", then it is non-first (second and more)
#      invocation of the scheduler; this results in chain of `sched'
#      invocations that results in repetitive -zplg-scheduler activity
#
#      if "burst", then all tasks are marked timeout and executed one
#      by one; this is handy if e.g. a docker image starts up and
#      needs to install all turbo-mode plugins without any hesitation
#      (delay), i.e. "burst" allows to run package installations from
#      script, not from prompt
#
-zplg-scheduler() {
    integer __ret="${${ZPLGM[lro-data]%:*}##*:}"
    # lro stands for lastarg-retval-option
    [[ $1 = following ]] && sched +1 'ZPLGM[lro-data]="$_:$?:${options[printexitvalue]}"; -zplg-scheduler following "${ZPLGM[lro-data]%:*:*}"'
    [[ -n "$1" && "$1" != (following*|burst) ]] && { local THEFD="$1"; zle -F "$THEFD"; exec {THEFD}<&-; }
    [[ "$1" = "burst" ]] && local -h EPOCHSECONDS=$(( EPOCHSECONDS+10000 ))
    ZPLGM[START_TIME]="${ZPLGM[START_TIME]:-$EPOCHREALTIME}"

    integer __t=EPOCHSECONDS __i correct=0
    local -a match mbegin mend reply
    local REPLY ANFD

    [[ -o ksharrays ]] && correct=1

    [[ -n "$1" ]] && {
        () {
            builtin emulate -L zsh
            builtin setopt extendedglob
            # Example entry:
            # 1531252764+2+1 p 18 light zdharma/zsh-diff-so-fancy
            #
            # This either doesn't change ZPLG_TASKS entry - when
            # __i is used in the ternary expression, or replaces
            # an entry with "<no-data>", i.e. ZPLG_TASKS[1] entry.
            integer __idx1 __idx2
            local __ar2 __ar3 __ar4 __ar5
            for (( __idx1 = 0; __idx1 <= 4; __idx1 ++ )); do
                for (( __idx2 = 1; __idx2 <= (__idx >= 4 ? 1 : 3); __idx2 ++ )); do
                    # The following substitution could be just (well, 'just'..) this:
                    #
                    # ZPLG_TASKS=( ${ZPLG_TASKS[@]/(#b)([0-9]##)+([0-9]##)+([1-3])(*)/
                    # ${ZPLG_TASKS[$(( (${match[1]}+${match[2]}) <= $__t ?
                    # zplugin_scheduler_add(__i++, ${match[2]},
                    # ${(M)match[3]%[1-3]}, __idx1, __idx2) : __i++ ))]}} )
                    #
                    # However, there's a severe bug in Zsh <= 5.3.1 - use of the period
                    # (,) is impossible inside ${..//$arr[$(( ... ))]}.
                    __i=2

                    ZPLG_TASKS=( ${ZPLG_TASKS[@]/(#b)([0-9]##)+([0-9]##)+([1-3])(*)/${ZPLG_TASKS[
                    $(( (__ar2=${match[2]}+1) ? (
                        (__ar3=${(M)match[3]%[1-3]}) ? (
                        (__ar4=__idx1+1) ? (
                        (__ar5=__idx2) ? (
            (${match[1]}+${match[2]}) <= $__t ?
            zplugin_scheduler_add(__i++) : __i++ )
                        : 1 )
                        : 1 )
                        : 1 )
                        : 1  ))]}} )
                    ZPLG_TASKS=( "<no-data>" ${ZPLG_TASKS[@]:#<no-data>} )
                done
            done
        }
    } || {
        add-zsh-hook -d -- precmd -zplg-scheduler
        add-zsh-hook -- chpwd -zplg-scheduler
        () {
            builtin emulate -L zsh
            builtin setopt extendedglob
            # No "+" in this pattern, it will match only "1531252764"
            # in "1531252764+2" and replace it with current time
            ZPLG_TASKS=( ${ZPLG_TASKS[@]/(#b)([0-9]##)(*)/$(( ${match[1]} <= 1 ? ${match[1]} : __t ))${match[2]}} )
        }
        # There's a bug in Zsh: first sched call would not be issued
        # until a key-press, if "sched +1 ..." would be called inside
        # zle -F handler. So it's done here, in precmd-handle code.
        sched +1 'ZPLGM[lro-data]="$_:$?:${options[printexitvalue]}"; -zplg-scheduler following ${ZPLGM[lro-data]%:*:*}'

        ANFD="13371337" # for older Zsh + noclobber option
        exec {ANFD}< <(LANG=C command sleep 0.002; builtin print run;)
	command true # workaround a Zsh bug, see: http://www.zsh.org/mla/workers/2018/msg00966.html
        zle -F "$ANFD" -zplg-scheduler
    }

    local __task __idx=0 __count=0 __idx2
    # All wait'' objects
    for __task in "${ZPLG_RUN[@]}"; do
        -zplg-run-task 1 "${(@z)__task}" && ZPLG_TASKS+=( "$__task" )
        [[ $(( ++__idx, __count += ${${REPLY:+1}:-0} )) -gt 0 && $1 != burst ]] && \
            {
                ANFD="13371337" # for older Zsh + noclobber option
                exec {ANFD}< <(LANG=C command sleep 0.0002; builtin print run;)
                command true # workaround a Zsh bug, see: http://www.zsh.org/mla/workers/2018/msg00966.html
                # The $? and $_ will be preserved automatically by Zsh
                # – that's how calling the -F handler is implemented
                zle -F "$ANFD" -zplg-scheduler
                break
            }
    done
    # All unload'' objects
    for (( __idx2=1; __idx2 <= __idx; ++ __idx2 )); do
        -zplg-run-task 2 "${(@z)ZPLG_RUN[__idx2-correct]}"
    done
    # All load'' & subscribe'' objects
    for (( __idx2=1; __idx2 <= __idx; ++ __idx2 )); do
        -zplg-run-task 3 "${(@z)ZPLG_RUN[__idx2-correct]}"
    done
    ZPLG_RUN[1-correct,__idx-correct]=()

    [[ ${ZPLGM[lro-data]##*:} = "on" ]] && return 0 || return $__ret
}
# }}}

#
# Exposed functions
#

# FUNCTION: zplugin {{{
# Main function directly exposed to user, obtains subcommand and its
# arguments, has completion.
zplugin() {
    local -A ZPLG_ICE
    ZPLG_ICE=( "${(kv)ZPLG_ICES[@]}" )
    ZPLG_ICES=()

    integer retval=0 correct=0
    local -a match mbegin mend reply
    local MATCH REPLY; integer MBEGIN MEND

    [[ -o ksharrays ]] && correct=1

    local -A opt_map ICE_OPTS
    opt_map=(
       -q       opt_-q,--quiet
       --quiet  opt_-q,--quiet
       -r       opt_-r,--reset
       --reset  opt_-r,--reset
       --all    opt_--all
       --clean  opt_--clean
       --yes    opt_-y,--yes
       -y       opt_-y,--yes
    )

    [[ $1 != (-h|--help|help|man|self-update|times|zstatus|load|light|unload|snippet|ls|ice|\
update|status|report|delete|loaded|list|cd|create|edit|glance|stress|changes|recently|clist|\
completions|cclear|cdisable|cenable|creinstall|cuninstall|csearch|compinit|dtrace|dstart|dstop|\
dunload|dreport|dclear|compile|uncompile|compiled|cdlist|cdreplay|cdclear|srv|recall|\
env-whitelist|bindkeys|module|add-fpath|fpath|run) || $1 = (load|light|snippet) ]] && \
    {
        integer  __is_snippet
        if [[ $1 = (load|light|snippet) ]]; then
            # Classic syntax -> simulate a call through the for-syntax
            () {
                setopt localoptions extendedglob
                : ${@[@]//(#b)([ $'\t']##|(#s))(-b|--command|-f)([ $'\t']##|(#e))/${ICE_OPTS[${match[2]}]::=1}}
            } "$@"
            set -- "${@[@]:#(-b|--command|-f)}"
            [[ $1 = light && -z ${ICE_OPTS[(I)-b]} ]] && ZPLG_ICE[light-mode]=""
            [[ $1 = snippet ]] && ZPLG_ICE[is-snippet]="" || __is_snippet=-1
            shift

            ZPLG_ICES=( "${(kv)ZPLG_ICE[@]}" )
            ZPLG_ICE=()
            1="${1:+@}${1#@}${2:+/$2}"
            (( $# > 1 )) && { shift -p $(( $# - 1 )); }
            [[ -z "$1" ]] && {
               print "Argument needed, try: help"
               return 1
            }
        else
            -zplg-ice "$@"
            shift $?
            if [[ $# -gt 0 && $1 != "for" ]]; then
                print "Unknown command or ice: \`$1' (use \`help' to get usage information)"
                return 1
            fi
            [[ $1 = for ]] && shift
        fi
        integer __retval
        if (( $# )); then
            local -a __ices
            __ices=( "${(kv)ZPLG_ICES[@]}" )
            ZPLG_ICES=()
            while (( $# )) {
                -zplg-ice "$@"
                shift $?
                [[ -z ${ZPLG_ICES[subscribe]} ]] && unset 'ZPLG_ICES[subscribe]'
                if [[ -n $1 ]]; then
                    ZPLG_ICE=( "${__ices[@]}" "${(kv)ZPLG_ICES[@]}" )
                    ZPLG_ICES=()

                    (( ${+ZPLG_ICE[pack]} )) && {
                        -zplg-load-ices "${1#@}"
                        [[ -z ${ZPLG_ICE[wait]} ]] && unset 'ZPLG_ICE[wait]'
                    }

                    [[ ${ZPLG_ICE[id-as]} = auto ]] && ZPLG_ICE[id-as]="${1:t}"

                    [[ $__is_snippet -ge 0 ]] && {
                        [[ -n ${ZPLG_ICE[is-snippet]+1} ||
                          ${1#@} = ((#i)(http(s|)|ftp(s|)):/|((OMZ|PZT)::))*
                        ]] && \
                            __is_snippet=1 || \
                            __is_snippet=0
                    }

                    if [[ -n ${ZPLG_ICE[trigger-load]} ]] {
                        () {
                            setopt localoptions extendedglob
                            local mode
                            (( __is_snippet > 0 )) && mode="snippet" || mode="${${${ZPLG_ICE[light-mode]+light}}:-load}"
                            for MATCH ( ${(s.;.)ZPLG_ICE[trigger-load]} ) {
                                eval "${MATCH#!}() {
                                    ${${(M)MATCH#!}:+unset -f ${MATCH#!}}
                                    local a b; local -a ices
                                    # The wait'' ice is filtered-out
                                    for a b ( ${(qqkv@)${(kv@)ZPLG_ICE[(I)^(trigger-load|wait|light-mode)]}} ) {
                                        ices+=( \"\$a\$b\" )
                                    }
                                    zplugin ice \${ices[@]}; zplugin $mode ${(qqq)${1#@}}
                                    ${${(M)MATCH#!}:+# Forward the call
                                    eval ${MATCH#!} \$@}
                                }"
                            }
                        } "$@"
                        __retval+=$?
                        (( $# )) && shift
                        continue
                    }

                    (( ${+ZPLG_ICE[if]} )) && { eval "${ZPLG_ICE[if]}" || { (( $# )) && shift; continue; }; }
                    (( ${+ZPLG_ICE[has]} )) && { (( ${+commands[${ZPLG_ICE[has]}]} )) || { (( $# )) && shift; continue; }; }

                    ZPLG_ICE[wait]="${${(M)${+ZPLG_ICE[wait]}:#1}:+${${ZPLG_ICE[wait]#!}:-${(M)ZPLG_ICE[wait]#!}0}}"
                    if [[ -n "${ZPLG_ICE[wait]}${ZPLG_ICE[load]}${ZPLG_ICE[unload]}${ZPLG_ICE[service]}${ZPLG_ICE[subscribe]}" ]]; then
                        ZPLG_ICE[wait]="${ZPLG_ICE[wait]:-${ZPLG_ICE[service]:+0}}"
                        if (( __is_snippet > 0 )); then
                            ZPLG_SICE[${${1#@}%%(/|//|///)}]=""
                            -zplg-submit-turbo s${ZPLG_ICE[service]:+1} "" \
                                "${${1#@}%%(/|//|///)}" \
                                "${(k)ICE_OPTS[*]}"
                        else
                            ZPLG_SICE[${${${1#@}#https://github.com/}%%(/|//|///)}]=""
                            -zplg-submit-turbo p${ZPLG_ICE[service]:+1} \
                                "${${${ZPLG_ICE[light-mode]+light}}:-load}" \
                                "${${${1#@}#https://github.com/}%%(/|//|///)}" ""
                        fi
                        __retval+=$?
                    else
                        if (( __is_snippet > 0 )); then
                            -zplg-load-snippet ${(k)ICE_OPTS[@]} "${${1#@}%%(/|//|///)}"
                        else
                            -zplg-load "${${${1#@}#https://github.com/}%%(/|//|///)}" "" \
                                "${${ZPLG_ICE[light-mode]+light}:-${ICE_OPTS[(I)-b]:+light-b}}"
                        fi
                        __retval+=$?
                    fi
                fi
                (( $# )) && shift
            }
        fi
        return __retval
    }

    case "$1" in
       (ice)
           shift
           -zplg-ice "$@"
           ;;
       (cdreplay)
           -zplg-compdef-replay "$2"; retval=$?
           ;;
       (cdclear)
           -zplg-compdef-clear "$2"
           ;;
       (add-fpath|fpath)
           -zplg-add-fpath "${@[2-correct,-1]}"
           ;;
       (run)
           -zplg-run "${@[2-correct,-1]}"
           ;;
       (dstart|dtrace)
           -zplg-debug-start
           ;;
       (dstop)
           -zplg-debug-stop
           ;;
       (man)
           man "${ZPLGM[BIN_DIR]}/doc/zplugin.1"
           ;;
       (env-whitelist)
           shift
           [[ $1 = "-v" ]] && { shift; local verbose=1; }
           [[ $1 = "-h" ]] && { shift; print "Usage: zplugin env-whitelist [-v] VAR1 ...\nSaves names (also patterns) of parameters left unchanged during an unload. -v - verbose."; }
           (( $# == 0 )) && {
               ZPLGM[ENV-WHITELIST]=""
               (( verbose )) && print "Cleared parameter whitelist"
           } || {
               ZPLGM[ENV-WHITELIST]+="${(j: :)${(q-kv)@}} "
               (( verbose )) && print "Extended parameter whitelist"
           }
           ;;
       (*)
           # Check if there is a z-annex registered for the subcommand
           reply=( ${ZPLG_EXTS[z-annex subcommand:${(q)1}]} )
           (( ${#reply} )) && {
               reply=( "${(Q)${(z@)reply[1]}[@]}" )
               (( ${+functions[${reply[5]}]} )) && { "${reply[5]}" "$@"; return $?; } ||
                 { print -r -- "(Couldn't find the subcommand-handler \`${reply[5]}' of the z-annex \`${reply[3]}')"; return 1; }
           }
           (( ${+functions[-zplg-confirm]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-autoload.zsh"
           case "$1" in
               (zstatus)
                   -zplg-show-zstatus
                   ;;
               (times)
                   -zplg-show-times "${@[2-correct,-1]}"
                   ;;
               (self-update)
                   -zplg-self-update
                   ;;
               (unload)
                   (( ${+functions[-zplg-unload]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-autoload.zsh"
                   if [[ -z "$2" && -z "$3" ]]; then
                       print "Argument needed, try: help"; retval=1
                   else
                       [[ "$2" = "-q" ]] && { 5="-q"; shift; }
                       # Unload given plugin. Cloned directory remains intact
                       # so as are completions
                       -zplg-unload "${2%%(/|//|///)}" "${${3:#-q}%%(/|//|///)}" "${${(M)4:#-q}:-${(M)3:#-q}}"; retval=$?
                   fi
                   ;;
               (bindkeys)
                   -zplg-list-bindkeys
                   ;;
               (update)
                   (( ${+ZPLG_ICE[if]} )) && { eval "${ZPLG_ICE[if]}" || return 1; }
                   (( ${+ZPLG_ICE[has]} )) && { (( ${+commands[${ZPLG_ICE[has]}]} )) || return 1; }
                   () {
                       setopt localoptions extendedglob
                       : ${@[@]//(#b)([ $'\t']##|(#s))(--quiet|-q|--reset|-r)([ $'\t']##|(#e))/${ICE_OPTS[${opt_map[${match[2]}]}]::=1}}
                   } "$@"
                   set -- "${@[@]:#(--quiet|-q|--reset|-r)}"
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" && -z ${ZPLG_ICE[teleid]} && -z ${ZPLG_ICE[id-as]} ) ]]; then
                       [[ -z "$2" ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       -zplg-update-or-status-all "update"; retval=$?
                   else
                       -zplg-update-or-status "update" "${${2%%(/|//|///)}:-${ZPLG_ICE[id-as]:-$ZPLG_ICE[teleid]}}" "${3%%(/|//|///)}"; retval=$?
                   fi
                   ;;
               (status)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       -zplg-update-or-status-all "status"; retval=$?
                   else
                       -zplg-update-or-status "status" "${2%%(/|//|///)}" "${3%%(/|//|///)}"; retval=$?
                   fi
                   ;;
               (report)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { print -r -- "Assuming --all is passed"; sleep 3; }
                       -zplg-show-all-reports
                   else
                       -zplg-show-report "${2%%(/|//|///)}" "${3%%(/|//|///)}"; retval=$?
                   fi
                   ;;
               (loaded|list)
                   # Show list of loaded plugins
                   -zplg-show-registered-plugins "$2"
                   ;;
               (clist|completions)
                   # Show installed, enabled or disabled, completions
                   # Detect stray and improper ones
                   -zplg-show-completions "$2"
                   ;;
               (cclear)
                   # Delete stray and improper completions
                   -zplg-clear-completions
                   ;;
               (cdisable)
                   if [[ -z "$2" ]]; then
                       print "Argument needed, try: help"; retval=1
                   else
                       local f="_${2#_}"
                       # Disable completion given by completion function name
                       # with or without leading "_", e.g. "cp", "_cp"
                       if -zplg-cdisable "$f"; then
                           (( ${+functions[-zplg-forget-completion]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                           -zplg-forget-completion "$f"
                           print "Initializing completion system (compinit)..."
                           builtin autoload -Uz compinit
                           compinit -d ${ZPLGM[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZPLGM[COMPINIT_OPTS]}}"
                       else
                           retval=1
                       fi
                   fi
                   ;;
               (cenable)
                   if [[ -z "$2" ]]; then
                       print "Argument needed, try: help"; retval=1
                   else
                       local f="_${2#_}"
                       # Enable completion given by completion function name
                       # with or without leading "_", e.g. "cp", "_cp"
                       if -zplg-cenable "$f"; then
                           (( ${+functions[-zplg-forget-completion]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                           -zplg-forget-completion "$f"
                           print "Initializing completion system (compinit)..."
                           builtin autoload -Uz compinit
                           compinit -d ${ZPLGM[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZPLGM[COMPINIT_OPTS]}}"
                       else
                           retval=1
                       fi
                   fi
                   ;;
               (creinstall)
                   (( ${+functions[-zplg-install-completions]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                   # Installs completions for plugin. Enables them all. It's a
                   # reinstallation, thus every obstacle gets overwritten or removed
                   [[ "$2" = "-q" ]] && { 5="-q"; shift; }
                   -zplg-install-completions "${2%%(/|//|///)}" "${3%%(/|//|///)}" "1" "${(M)4:#-q}"; retval=$?
                   [[ -z "${(M)4:#-q}" ]] && print "Initializing completion (compinit)..."
                   builtin autoload -Uz compinit
                   compinit -d ${ZPLGM[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZPLGM[COMPINIT_OPTS]}}"
                   ;;
               (cuninstall)
                   if [[ -z "$2" && -z "$3" ]]; then
                       print "Argument needed, try: help"; retval=1
                   else
                       (( ${+functions[-zplg-forget-completion]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                       # Uninstalls completions for plugin
                       -zplg-uninstall-completions "${2%%(/|//|///)}" "${3%%(/|//|///)}"; retval=$?
                       print "Initializing completion (compinit)..."
                       builtin autoload -Uz compinit
                       compinit -d ${ZPLGM[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZPLGM[COMPINIT_OPTS]}}"
                   fi
                   ;;
               (csearch)
                   -zplg-search-completions
                   ;;
               (compinit)
                   (( ${+functions[-zplg-forget-completion]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                   -zplg-compinit; retval=$?
                   ;;
               (dreport)
                   -zplg-show-debug-report
                   ;;
               (dclear)
                   -zplg-clear-debug-report
                   ;;
               (dunload)
                   -zplg-debug-unload
                   ;;
               (compile)
                   (( ${+functions[-zplg-compile-plugin]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       -zplg-compile-uncompile-all "1"; retval=$?
                   else
                       -zplg-compile-plugin "${2%%(/|//|///)}" "${3%%(/|//|///)}"; retval=$?
                   fi
                   ;;
               (uncompile)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       -zplg-compile-uncompile-all "0"; retval=$?
                   else
                       -zplg-uncompile-plugin "${2%%(/|//|///)}" "${3%%(/|//|///)}"; retval=$?
                   fi
                   ;;
               (compiled)
                   -zplg-compiled
                   ;;
               (cdlist)
                   -zplg-list-compdef-replay
                   ;;
               (cd|delete|recall|edit|glance|changes|create|stress)
                   -zplg-"$1" "${@[2-correct,-1]%%(/|//|///)}"; retval=$?
                   ;;
               (recently)
                   shift
                   -zplg-recently "$@"; retval=$?
                   ;;
               (-h|--help|help|"")
                   -zplg-help
                   ;;
               (ls)
                   shift
                   -zplg-ls "$@"
                   ;;
               (srv)
                   () { setopt localoptions extendedglob warncreateglobal
                   [[ ! -e ${ZPLGM[SERVICES_DIR]}/"$2".fifo ]] && { print "No such service: $2"; } ||
                       { [[ "$3" = (#i)(next|stop|quit|restart) ]] &&
                           { print "${(U)3}" >>! ${ZPLGM[SERVICES_DIR]}/"$2".fifo || print "Service $2 inactive"; retval=1; } ||
                               { [[ "$3" = (#i)start ]] && rm -f ${ZPLGM[SERVICES_DIR]}/"$2".stop ||
                                   { print "Unknown service-command: $3"; retval=1; }
                               }
                       }
                   } "$@"
                   ;;
               (module)
                   -zplg-module "${@[2-correct,-1]}"; retval=$?
                   ;;
               (*)
                   print "Unknown command \`$1' (use \`help' to get usage information)"
                   retval=1
                   ;;
            esac
            ;;
    esac

    return $retval
} # }}}
# FUNCTION: zpcdreplay {{{
# A function that can be invoked from within `atinit', `atload', etc.
# ice-mod.  It works like `zplugin cdreplay', which cannot be invoked
# from such hook ices.
zpcdreplay() { -zplg-compdef-replay -q; }
# }}}
# FUNCTION: zpcdclear {{{
# A wrapper for `zplugin cdclear -q' which can be called from hook
# ices like the atinit'', atload'', etc. ices.
zpcdclear() { -zplg-compdef-clear -q; }
# }}}
# FUNCTION: zpcompinit {{{
# A function that can be invoked from within `atinit', `atload', etc.
# ice-mod.  It runs `autoload compinit; compinit' and respects
# ZPLGM[ZCOMPDUMP_PATH] and ZPLGM[COMPINIT_OPTS].
zpcompinit() { autoload -Uz compinit; compinit -d ${ZPLGM[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZPLGM[COMPINIT_OPTS]}}"; }
# }}}
# FUNCTION: zpcompdef {{{
# Stores compdef for a replay with `zpcdreplay' (turbo mode) or
# with `zplugin cdreplay' (normal mode). An utility functton of
# an undefined use case.
zpcompdef() { ZPLG_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" ); }
# }}}

#
# Source-executed code
#

autoload add-zsh-hook
zmodload zsh/datetime && add-zsh-hook -- precmd -zplg-scheduler  # zsh/datetime required for wait/load/unload ice-mods
functions -M -- zplugin_scheduler_add 1 1 -zplugin_scheduler_add_sh 2>/dev/null
zmodload zsh/zpty zsh/system 2>/dev/null

# code {{{
builtin unsetopt noaliases
builtin alias zpl=zplugin zplg=zplugin

-zplg-prepare-home

# Simulate existence of _local/zplugin plugin
# This will allow to cuninstall of its completion
ZPLG_REGISTERED_PLUGINS=( "_local/zplugin" "${(u)ZPLG_REGISTERED_PLUGINS[@]:#_local/zplugin}" )
ZPLG_REGISTERED_STATES[_local/zplugin]="1"

# Add completions directory to fpath
fpath=( "${ZPLGM[COMPLETIONS_DIR]}" "${fpath[@]}" )

# Inform Prezto that the compdef function is available
zstyle ':prezto:module:completion' loaded 1

# Colorize completions for commands unload, report, creinstall, cuninstall
zstyle ':completion:*:zplugin:argument-rest:plugins' list-colors '=(#b)(*)/(*)==1;35=1;33'
zstyle ':completion:*:zplugin:argument-rest:plugins' matcher 'r:|=** l:|=*'
zstyle ':completion:*:*:zplugin:*' group-name ""
# }}}

# vim:ft=zsh:sw=4:sts=4:et
