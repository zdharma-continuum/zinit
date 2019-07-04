# -*- mode: shell-script -*-
# vim:ft=zsh

#
# Main state variables
#

typeset -gaH ZPLG_REGISTERED_PLUGINS ZPLG_TASKS ZPLG_RUN
typeset -ga LOADED_PLUGINS
ZPLG_TASKS=( "<no-data>" )
# Snippets loaded, url -> file name
typeset -gAH ZPLGM ZPLG_REGISTERED_STATES ZPLG_SNIPPETS ZPLG_REPORTS ZPLG_ICE ZPLG_SICE ZPLG_CUR_BIND_MAP

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
export ZPFX=${~ZPFX}
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
# Parameters - function diffing {{{
typeset -gAH ZPLG_FUNCTIONS_BEFORE
typeset -gAH ZPLG_FUNCTIONS_AFTER
# Functions computed to be associated with plugin
typeset -gAH ZPLG_FUNCTIONS
#}}}
# Parameters - option diffing {{{
typeset -gAH ZPLG_OPTIONS_BEFORE
typeset -gAH ZPLG_OPTIONS_AFTER
# Concatenated options that changed, hold as they were before plugin load
typeset -gAH ZPLG_OPTIONS
# }}}
# Parameters - environment diffing {{{
typeset -gAH ZPLG_PATH_BEFORE
typeset -gAH ZPLG_PATH_AFTER
# Concatenated new elements of PATH (after diff)
typeset -gAH ZPLG_PATH
typeset -gAH ZPLG_FPATH_BEFORE
typeset -gAH ZPLG_FPATH_AFTER
# Concatenated new elements of FPATH (after diff)
typeset -gAH ZPLG_FPATH
# }}}
# Parameters - parameter diffing {{{
typeset -gAH ZPLG_PARAMETERS_BEFORE
typeset -gAH ZPLG_PARAMETERS_AFTER
# Concatenated *changed* previous elements of $parameters (before)
typeset -gAH ZPLG_PARAMETERS_PRE
# Concatenated *changed* current elements of $parameters (after)
typeset -gAH ZPLG_PARAMETERS_POST
# }}}
# Parameters - zstyle, bindkey, alias, zle remembering {{{
# Holds concatenated Zstyles declared by each plugin
# Concatenated after quoting, so (z)-splittable
typeset -gAH ZPLG_ZSTYLES

# Holds concatenated bindkeys declared by each plugin
typeset -gAH ZPLG_BINDKEYS

# Holds concatenated aliases declared by each plugin
typeset -gAH ZPLG_ALIASES

# Holds concatenated pairs "widget_name save_name" for use with zle -A
typeset -gAH ZPLG_WIDGETS_SAVED

# Holds concatenated names of widgets that should be deleted
typeset -gAH ZPLG_WIDGETS_DELETE

# Holds compdef calls (i.e. "${(j: :)${(q)@}}" of each call)
typeset -gaH ZPLG_COMPDEF_REPLAY
# }}}
# Parameters - ICE, swiss-knife {{{
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
        "col-error"     $'\e[31m'
        "col-p"         $'\e[01m\e[34m'
        "col-bar"       $'\e[01m\e[35m'
        "col-info"      $'\e[32m'
        "col-info2"     $'\e[32m'
        "col-uninst"    $'\e[01m\e[34m'
        "col-success"   $'\e[01m\e[32m'
        "col-failure"   $'\e[31m'
        "col-rst"       $'\e[0m'
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

    [[ "$FPATH" != *$fpath_prefix* ]] && local +h FPATH="$fpath_prefix:$FPATH"

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
    local -a opts
    local func

    # TODO: +X
    zparseopts -D -a opts ${(s::):-RTUXdkmrtWz}

    if (( ${+opts[(r)-X]} )); then
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: Failed autoload ${(j: :)opts[@]} $*"
        print -u2 "builtin autoload required for ${(j: :)opts[@]}"
        return 1
    fi
    if (( ${+opts[(r)-w]} )); then
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "-w-Autoload ${(j: :)opts[@]} ${(j: :)@}"
        builtin autoload ${opts[@]} "$@"
        return 0
    fi
    if [[ -n ${(M)@:#+X} ]]; then
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Autoload +X ${opts:+${(j: :)opts[@]} }${(j: :)${@:#+X}}"
        builtin autoload +X ${opts[@]} "${@:#+X}"
        return 0
    fi
    # Report ZPLUGIN's "native" autoloads
    for func; do
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Autoload $func${opts:+ with options ${(j: :)opts[@]}}"
    done

    # Do ZPLUGIN's "native" autoloads
    if [[ "$ZPLGM[CUR_USR]" = "%" ]] && local PLUGIN_DIR="$ZPLG_CUR_PLUGIN" || local PLUGIN_DIR="${ZPLGM[PLUGINS_DIR]}/${${ZPLGM[CUR_USR]}:+${ZPLGM[CUR_USR]}---}${ZPLG_CUR_PLUGIN//\//---}"
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
                    fpath=( ${(qqq)PLUGIN_DIR} ${(qqq@)fpath} )
                    builtin autoload -X ${(j: :)${(q-)opts[@]}}
                }"
            else
                eval "function ${(q)func} {
                    --zplg-reload-and-run ${(q)PLUGIN_DIR} ${(qq)opts[*]} ${(q)func} "'"$@"
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
    -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Bindkey $*"

    # Remember to perform the actual bindkey call
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular bindkey call, i.e.
    # with no options or with -s, plus possible -M
    # option
    local -A optsA
    zparseopts -A optsA -D ${(s::):-lLdDAmrsevaR} "M:" "N:"

    local -a opts
    opts=( "${(k)optsA[@]}" )

    if [[ "${#opts}" -eq "0" ||
        ( "${#opts}" -eq "1" && "${+opts[(r)-M]}" = "1" ) ||
        ( "${#opts}" -eq "1" && "${+opts[(r)-R]}" = "1" ) ||
        ( "${#opts}" -eq "1" && "${+opts[(r)-s]}" = "1" ) ||
        ( "${#opts}" -le "2" && "${+opts[(r)-M]}" = "1" && "${+opts[(r)-s]}" = "1" ) ||
        ( "${#opts}" -le "2" && "${+opts[(r)-M]}" = "1" && "${+opts[(r)-R]}" = "1" )
    ]]; then
        local string="${(q)1}" widget="${(q)2}"
        local quoted

        if [[ -n "${ZPLG_ICE[bindmap]}" && ${ZPLG_CUR_BIND_MAP[empty]} -eq 1 ]]; then
            local -a pairs
            pairs=( "${(@s,;,)ZPLG_ICE[bindmap]}" )
            () {
                setopt localoptions extendedglob noksharrays noshwordsplit;
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

        # "-M map" given?
        if (( ${+opts[(r)-M]} )); then
            local Mopt="-M"
            local Marg="${optsA[-M]}"

            Mopt="${(q)Mopt}"
            Marg="${(q)Marg}"

            quoted="$string $widget $Mopt $Marg"
        else
            quoted="$string $widget"
        fi

        # -R given?
        if (( ${+opts[(r)-R]} )); then
            local Ropt="-R"
            Ropt="${(q)Ropt}"

            if (( ${+opts[(r)-M]} )); then
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
        [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLG_BINDKEYS[${ZPLGM[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLG_BINDKEYS[_dtrace/_dtrace]+="$quoted "
    else
        # bindkey -A newkeymap main?
        # Negative indices for KSH_ARRAYS immunity
        if [[ "${#opts[@]}" -eq "1" && "${+opts[(r)-A]}" = "1" && "${#pos[@]}" = "3" && "${pos[-1]}" = "main" && "${pos[-2]}" != "-A" ]]; then
            # Save a copy of main keymap
            (( ZPLGM[BINDKEY_MAIN_IDX] = ${ZPLGM[BINDKEY_MAIN_IDX]:-0} + 1 ))
            local pname="${ZPLG_CUR_PLUGIN:-_dtrace}"
            local name="${(q)pname}-main-${ZPLGM[BINDKEY_MAIN_IDX]}"
            builtin bindkey -N "$name" main

            # Remember occurence of main keymap substitution, to revert on unload
            local keys="_" widget="_" optA="-A" mapname="${name}" optR="_"
            local quoted="${(q)keys} ${(q)widget} ${(q)optA} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
            [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLG_BINDKEYS[${ZPLGM[CUR_USPL2]}]+="$quoted "
            [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLG_BINDKEYS[_dtrace/_dtrace]+="$quoted "

            -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: keymap \`main' copied to \`${name}' because of \`${pos[-2]}' substitution"
        # bindkey -N newkeymap [other]
        elif [[ "${#opts[@]}" -eq 1 && "${+opts[(r)-N]}" = "1" ]]; then
            local Nopt="-N"
            local Narg="${optsA[-N]}"

            local keys="_" widget="_" optN="-N" mapname="${Narg}" optR="_"
            local quoted="${(q)keys} ${(q)widget} ${(q)optN} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
            [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLG_BINDKEYS[${ZPLGM[CUR_USPL2]}]+="$quoted "
            [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLG_BINDKEYS[_dtrace/_dtrace]+="$quoted "
        else
            -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: last bindkey used non-typical options: ${opts[*]}"
        fi
    fi

    # A. Shadow off. Unfunction bindkey
    # 0.autoload, A.bindkey, B.zstyle, C.alias, D.zle, E.compdef
    (( ${+ZPLGM[bkp-bindkey]} )) && functions[bindkey]="${ZPLGM[bkp-bindkey]}" || unfunction "bindkey"

    # Actual bindkey
    builtin bindkey "${pos[@]}"
    integer ret=$?

    # A. Shadow on. Custom function could unfunction itself
    (( ${+functions[bindkey]} )) && ZPLGM[bkp-bindkey]="${functions[bindkey]}" || unset "ZPLGM[bkp-bindkey]"
    functions[bindkey]='--zplg-shadow-bindkey "$@";'

    return $ret # testable
} # }}}
# FUNCTION: --zplg-shadow-zstyle {{{
# Function defined to hijack plugin's calls to `zstyle' builtin.
#
# The hijacking is to gather report data (which is used in unload).
--zplg-shadow-zstyle() {
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
        [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLG_ZSTYLES[${ZPLGM[CUR_USPL2]}]+="$ps "
        # Remember for dtrace
        [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLG_ZSTYLES[_dtrace/_dtrace]+="$ps "
    else
        if [[ ! "${#opts[@]}" = "1" && ( "${+opts[(r)-s]}" = "1" || "${+opts[(r)-b]}" = "1" || "${+opts[(r)-a]}" = "1" ||
                                      "${+opts[(r)-t]}" = "1" || "${+opts[(r)-T]}" = "1" || "${+opts[(r)-m]}" = "1" ) ]]
        then
            -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: last zstyle used non-typical options: ${opts[*]}"
        fi
    fi

    # B. Shadow off. Unfunction zstyle
    # 0.autoload, A.bindkey, B.zstyle, C.alias, D.zle, E.compdef
    (( ${+ZPLGM[bkp-zstyle]} )) && functions[zstyle]="${ZPLGM[bkp-zstyle]}" || unfunction "zstyle"

    # Actual zstyle
    zstyle "${pos[@]}"
    integer ret=$?

    # B. Shadow on. Custom function could unfunction itself
    (( ${+functions[zstyle]} )) && ZPLGM[bkp-zstyle]="${functions[zstyle]}" || unset "ZPLGM[bkp-zstyle]"
    functions[zstyle]='--zplg-shadow-zstyle "$@";'

    return $ret # testable
} # }}}
# FUNCTION: --zplg-shadow-alias {{{
# Function defined to hijack plugin's calls to `alias' builtin.
#
# The hijacking is to gather report data (which is used in unload).
--zplg-shadow-alias() {
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
        [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLG_ALIASES[${ZPLGM[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLG_ALIASES[_dtrace/_dtrace]+="$quoted "
    done

    # C. Shadow off. Unfunction alias
    # 0.autoload, A.bindkey, B.zstyle, C.alias, D.zle, E.compdef
    (( ${+ZPLGM[bkp-alias]} )) && functions[alias]="${ZPLGM[bkp-alias]}" || unfunction "alias"

    # Actual alias
    alias "${pos[@]}"
    integer ret=$?

    # C. Shadow on. Custom function could unfunction itself
    (( ${+functions[alias]} )) && ZPLGM[bkp-alias]="${functions[alias]}" || unset "ZPLGM[bkp-alias]"
    functions[alias]='--zplg-shadow-alias "$@";'

    return $ret # testable
} # }}}
# FUNCTION: --zplg-shadow-zle {{{
# Function defined to hijack plugin's calls to `zle' builtin.
#
# The hijacking is to gather report data (which is used in unload).
--zplg-shadow-zle() {
    -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Zle $*"

    # Remember to perform the actual zle call
    typeset -a pos
    pos=( "$@" )

    set -- "${@:#--}"

    # Try to catch game-changing "-N"
    if [[ "$1" = "-N" && "$#" = "3" ]]; then
            # Hooks
            if [[ "${ZPLG_ZLE_HOOKS_LIST[$2]}" = "1" ]]; then
                local quoted="$2"
                quoted="${(q)quoted}"
                # Remember only when load is in progress (it can be dstart that leads execution here)
                [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLG_WIDGETS_DELETE[${ZPLGM[CUR_USPL2]}]+="$quoted "
            # These will be saved and restored
            elif (( ${+widgets[$2]} )); then
                # Have to remember original widget "$2" and
                # the copy that it's going to be done
                local widname="$2" saved_widname="zplugin-saved-$2"
                builtin zle -A -- "$widname" "$saved_widname"

                widname="${(q)widname}"
                saved_widname="${(q)saved_widname}"
                local quoted="$widname $saved_widname"
                quoted="${(q)quoted}"
                # Remember only when load is in progress (it can be dstart that leads execution here)
                [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLG_WIDGETS_SAVED[${ZPLGM[CUR_USPL2]}]+="$quoted "
                # Remember for dtrace
                [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLG_WIDGETS_SAVED[_dtrace/_dtrace]+="$quoted "
             # These will be deleted
             else
                 -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: unknown widget replaced/taken via zle -N: \`$2', it is set to be deleted"
                 local quoted="$2"
                 quoted="${(q)quoted}"
                 # Remember only when load is in progress (it can be dstart that leads execution here)
                 [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLG_WIDGETS_DELETE[${ZPLGM[CUR_USPL2]}]+="$quoted "
                 # Remember for dtrace
                 [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLG_WIDGETS_DELETE[_dtrace/_dtrace]+="$quoted "
             fi
    # Creation of new widgets. They will be removed on unload
    elif [[ "$1" = "-N" && "$#" = "2" ]]; then
        local quoted="$2"
        quoted="${(q)quoted}"
        # Remember only when load is in progress (it can be dstart that leads execution here)
        [[ -n "${ZPLGM[CUR_USPL2]}" ]] && ZPLG_WIDGETS_DELETE[${ZPLGM[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLG_WIDGETS_DELETE[_dtrace/_dtrace]+="$quoted "
    fi

    # D. Shadow off. Unfunction zle
    # 0.autoload, A.bindkey, B.zstyle, C.alias, D.zle, E.compdef
    (( ${+ZPLGM[bkp-zle]} )) && functions[zle]="${ZPLGM[bkp-zle]}" || unfunction "zle"

    # Actual zle
    zle "${pos[@]}"
    integer ret=$?

    # D. Shadow on. Custom function could unfunction itself
    (( ${+functions[zle]} )) && ZPLGM[bkp-zle]="${functions[zle]}" || unset "ZPLGM[bkp-zle]"
    functions[zle]='--zplg-shadow-zle "$@";'

    return $ret # testable
} # }}}
# FUNCTION: --zplg-shadow-compdef {{{
# Function defined to hijack plugin's calls to `compdef' function.
# The hijacking is not only for reporting, but also to save compdef
# calls so that `compinit' can be called after loading plugins.
--zplg-shadow-compdef() {
    -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Saving \`compdef $*' for replay"
    ZPLG_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" )

    return 0 # testable
} # }}}
# FUNCTION: -zplg-shadow-on {{{
# Turn on shadowing of builtins and functions according to passed
# mode ("load", "light" or "compdef"). The shadowing is to gather
# report data, and to hijack `autoload' and `compdef' calls.
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
# Turn off shadowing completely for a given mode ("load", "light"
# or "compdef").
-zplg-shadow-off() {
    builtin setopt localoptions noaliases
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
# Compatibility with Prezto. Calls can be recursive.
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

    ZPLG_FUNCTIONS[$uspl2]=""
    [[ "$cmd" = "begin" ]] && ZPLG_FUNCTIONS_BEFORE[$uspl2]="${(j: :)${(qk)functions[@]}}" || ZPLG_FUNCTIONS_AFTER[$uspl2]="${(j: :)${(qk)functions[@]}}"
} # }}}
# FUNCTION: -zplg-diff-options {{{
# Implements detection of change in option state. Performs
# data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
-zplg-diff-options() {
    local IFS=" "

    [[ "$2" = "begin" ]] && ZPLG_OPTIONS_BEFORE[$1]="${(kv)options[@]}" || ZPLG_OPTIONS_AFTER[$1]="${(kv)options[@]}"

    ZPLG_OPTIONS[$1]=""
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
            tmp=( "${(q)path[@]}" )
            ZPLG_PATH_BEFORE[$1]="${tmp[*]}"
            tmp=( "${(q)fpath[@]}" )
            ZPLG_FPATH_BEFORE[$1]="${tmp[*]}"
    } || {
            tmp=( "${(q)path[@]}" )
            ZPLG_PATH_AFTER[$1]="${tmp[*]}"
            tmp=( "${(q)fpath[@]}" )
            ZPLG_FPATH_AFTER[$1]="${tmp[*]}"
    }

    ZPLG_PATH[$1]=""
    ZPLG_FPATH[$1]=""
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
        ZPLG_PARAMETERS_BEFORE[$1]="${(j: :)${(qkv)parameters[@]}}" # RPROMPT ${(q)RPROMPT} RPS1 ${(q)RPS1} RPS2 ${(q)RPS2} PROMPT ${(q)PROMPT} PS1 ${(q)PS1}"
    } || {
        ZPLG_PARAMETERS_AFTER[$1]="${(j: :)${(qkv)parameters[@]}}"
    }

    ZPLG_PARAMETERS_PRE[$1]=""
    ZPLG_PARAMETERS_POST[$1]=""
} # }}}

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
            $pdir_path/*.plugin.zsh(N) $pdir_path/*.zsh-theme(N)
            $pdir_path/*.zsh(N) $pdir_path/*.sh(N) $pdir_path/.zshrc(N)
        )
    fi
} # }}}
# FUNCTION: -zplg-register-plugin {{{
-zplg-register-plugin() {
    local uspl2="$1" mode="$2"
    integer ret=0

    if [[ -z "${ZPLG_REGISTERED_PLUGINS[(r)$uspl2]}" ]]; then
        ZPLG_REGISTERED_PLUGINS+=( "$uspl2" )
        # Support Zsh plugin standard
        LOADED_PLUGINS+=( "$uspl2" )
    else
        # Allow overwrite-load, however warn about it
        [[ -z "${ZPLGM[TEST]}${ZPLG_ICE[wait]}${ZPLG_ICE[load]}${ZPLG_ICE[subscribe]}" && ${ZPLGM[MUTE_WARNINGS]} != 1 ]] && print "Warning: plugin \`$uspl2' already registered, will overwrite-load"
        ret=1
    fi

    # Full or light load?
    [[ "$mode" = "light" ]] && ZPLG_REGISTERED_STATES[$uspl2]="1" || ZPLG_REGISTERED_STATES[$uspl2]="2"

    ZPLG_REPORTS[$uspl2]=""          ZPLG_CUR_BIND_MAP=( empty 1 )
    # Functions
    ZPLG_FUNCTIONS_BEFORE[$uspl2]="" ZPLG_FUNCTIONS_AFTER[$uspl2]="" ZPLG_FUNCTIONS[$uspl2]=""
    # Objects
    ZPLG_ZSTYLES[$uspl2]=""          ZPLG_BINDKEYS[$uspl2]=""        ZPLG_ALIASES[$uspl2]=""
    # Widgets
    ZPLG_WIDGETS_SAVED[$uspl2]=""    ZPLG_WIDGETS_DELETE[$uspl2]=""
    # Rest (options and (f)path)
    ZPLG_OPTIONS[$uspl2]=""          ZPLG_PATH[$uspl2]=""            ZPLG_FPATH[$uspl2]=""

    return $ret
} # }}}
# FUNCTION: -zplg-unregister-plugin {{{
-zplg-unregister-plugin() {
    -zplg-any-to-user-plugin "$1" "$2"
    local uspl2="${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]}"

    # If not found, the index will be length+1
    ZPLG_REGISTERED_PLUGINS[${ZPLG_REGISTERED_PLUGINS[(i)$uspl2]}]=()
    # Support Zsh plugin standard
    LOADED_PLUGINS[${LOADED_PLUGINS[(i)$uspl2]}]=()
    ZPLG_REGISTERED_STATES[$uspl2]="0"
} # }}}

#
# Remaining functions
#

# FUNCTION: -zplg-prepare-home {{{
# Creates all directories needed by Zplugin, first checks
# if they already exist.
-zplg-prepare-home() {
    [[ -n "${ZPLGM[HOME_READY]}" ]] && return
    ZPLGM[HOME_READY]="1"

    [[ ! -d "${ZPLGM[HOME_DIR]}" ]] && {
        command mkdir 2>/dev/null "${ZPLGM[HOME_DIR]}"
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
    }
    [[ ! -d "${ZPLGM[COMPLETIONS_DIR]}" ]] && {
        command mkdir "${ZPLGM[COMPLETIONS_DIR]}"
        # For compaudit
        command chmod go-w "${ZPLGM[COMPLETIONS_DIR]}"

        # Symlink _zplugin completion into _local---zplugin directory
        command ln -s "${ZPLGM[PLUGINS_DIR]}/_local---zplugin/_zplugin" "${ZPLGM[COMPLETIONS_DIR]}"
    }
    [[ ! -d "${ZPLGM[SNIPPETS_DIR]}" ]] && {
        command mkdir "${ZPLGM[SNIPPETS_DIR]}"
        command chmod go-w "${ZPLGM[SNIPPETS_DIR]}"
        ( cd ${ZPLGM[SNIPPETS_DIR]}; command ln -s "OMZ::plugins" "plugins"; )
    }
    [[ ! -d "${ZPLGM[SERVICES_DIR]}" ]] && {
        command mkdir "${ZPLGM[SERVICES_DIR]}"
        command chmod go-w "${ZPLGM[SERVICES_DIR]}"
    }
} # }}}
# FUNCTION: -zplg-load {{{
# Implements the exposed-to-user action of loading a plugin.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin name, if the third format is used
-zplg-load () {
    typeset -F 3 SECONDS=0
    local mode="$3" rst="0" retval=0
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" id_as="${ZPLG_ICE[id-as]:-${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]}}"
    ZPLG_ICE[teleid]="$user${${user:#(%|/)*}:+/}$plugin"

    ZPLG_SICE[$id_as]=""
    -zplg-pack-ice "$id_as"
    if [[ "$user" != "%" && ! -d "${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}" ]]; then
        (( ${+functions[-zplg-setup-plugin-dir]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
        if ! -zplg-setup-plugin-dir "$user" "$plugin" "$id_as"; then
            zle && { print; zle .reset-prompt; }
            return 1
        fi
        zle && rst=1
    fi

    (( ${+ZPLG_ICE[cloneonly]} )) && return 0

    -zplg-register-plugin "$id_as" "$mode"

    (( ${+ZPLG_ICE[atinit]} )) && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "${${${(M)user:#%}:+$plugin}:-${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}}"; } && eval "${ZPLG_ICE[atinit]}"; ((1)); } || eval "${ZPLG_ICE[atinit]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    -zplg-load-plugin "$user" "$plugin" "$id_as" "$mode" "$rst"; retval=$?
    (( ${+ZPLG_ICE[notify]} == 1 )) && { [[ "$retval" -eq 0 || -n "${(M)ZPLG_ICE[notify]#\!}" ]] && { local msg; eval "msg=\"${ZPLG_ICE[notify]#\!}\""; -zplg-deploy-message @msg "$msg" } || -zplg-deploy-message @msg "notify: Plugin not loaded / loaded with problem, the return code: $retval"; }
    (( ${+ZPLG_ICE[reset-prompt]} == 1 )) && -zplg-deploy-message @rst
    ZPLGM[TIME_INDEX]=$(( ${ZPLGM[TIME_INDEX]:-0} + 1 ))
    ZPLGM[TIME_${ZPLGM[TIME_INDEX]}_${id_as//\//---}]=$SECONDS
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
    local url="$1" correct=0 retval=0
    [[ -o ksharrays ]] && correct=1

    # Remove leading whitespace and trailing /
    url="${${url#"${url%%[! $'\t']*}"}%/}"
    ZPLG_ICE[teleid]="$url"
    (( ${+ZPLG_ICE[pick]} )) && ZPLG_ICE[pick]="${ZPLG_ICE[pick]:#/dev/null}"

    local local_dir dirname filename save_url="$url" id_as="${ZPLG_ICE[id-as]:-$url}"
    [[ -z "${opts[(r)-i]}" ]] && -zplg-pack-ice "$id_as" ""

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

    (( ${+ZPLG_ICE[cloneonly]} )) && return 0

    ZPLG_SNIPPETS[$id_as]="$dirname <${${ZPLG_ICE[svn]+svn}:-file}>"

    (( ${+ZPLG_ICE[atinit]} && tmp[1-correct] )) && [[ -z "${opts[(r)-u]}" ]] && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && eval "${ZPLG_ICE[atinit]}"; ((1)); } || eval "${ZPLG_ICE[atinit]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    local -a list
    local ZERO
    if [[ -z "${opts[(r)-u]}" && -z "${opts[(r)--command]}" && -z "${ZPLG_ICE[as]}" ]]; then
        # Source the file with compdef shadowing
        if [[ "${ZPLGM[SHADOWING]}" = "inactive" ]]; then
            # Shadowing code is inlined from -zplg-shadow-on
            (( ${+functions[compdef]} )) && ZPLGM[bkp-compdef]="${functions[compdef]}" || builtin unset "ZPLGM[bkp-compdef]"
            functions[compdef]='--zplg-shadow-compdef "$@";'
            ZPLGM[SHADOWING]="1"
        else
            (( ++ ZPLGM[SHADOWING] ))
        fi

        # Add to fpath
        [[ -d "$local_dir/$dirname/functions" ]] && {
            [[ -z "${fpath[(r)$local_dir/$dirname/functions]}" ]] && fpath+=( "$local_dir/$dirname/functions" )
            () {
                setopt localoptions extendedglob
                autoload $local_dir/$dirname/functions/^([_.]*|prompt_*_setup|README*)(-.N:t)
            }
        }

        # Source
        if (( ${+ZPLG_ICE[svn]} == 0 )); then
            [[ ${tmp[1-correct]} = 1 && ${+ZPLG_ICE[pick]} = 0 ]] && list=( "$local_dir/$dirname/$filename" )
            [[ -n ${ZPLG_ICE[pick]} ]] && list=( ${(M)~ZPLG_ICE[pick]##/*}(N) $local_dir/$dirname/${~ZPLG_ICE[pick]}(N) )
        else
            if [[ -n ${ZPLG_ICE[pick]} ]]; then
                list=( ${(M)~ZPLG_ICE[pick]##/*}(N) $local_dir/$dirname/${~ZPLG_ICE[pick]}(N) )
            elif (( ${+ZPLG_ICE[pick]} == 0 )); then
                list=( $local_dir/$dirname/*.plugin.zsh(N) $local_dir/$dirname/init.zsh(N)
                       $local_dir/$dirname/*.zsh-theme(N) )
            fi
        fi

        [[ -f "${list[1-correct]}" ]] && {
            ZERO="${list[1-correct]}"
            (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); }
            (( 0 == retval )) && [[ "$id_as" = PZT::* || "$id_as" = https://github.com/sorin-ionescu/prezto/* ]] && zstyle ":prezto:module:${${id_as%/init.zsh}:t}" loaded 'yes'
            (( 1 ))
        } || { [[ ${+ZPLG_ICE[pick]} = 1 && -z "${ZPLG_ICE[pick]}" ]] || print -r -- "Snippet not loaded ($id_as)"; }

        [[ -n "${ZPLG_ICE[src]}" ]] && { ZERO="${${(M)ZPLG_ICE[src]##/*}:-$local_dir/$dirname/${ZPLG_ICE[src]}}"; (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); }; }
        [[ -n ${ZPLG_ICE[multisrc]} ]] && { eval "reply=( ${ZPLG_ICE[multisrc]} )"; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$local_dir/$dirname/$fname}"; (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); }; done; }
        (( ${+ZPLG_ICE[atload]} && tmp[1-correct] )) && [[ "${ZPLG_ICE[atload][1]}" = "!" ]] && { ZERO="$local_dir/$dirname/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ZPLG_ICE[atload]#\!}"; (( 1 )); } || eval "${ZPLG_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

        (( -- ZPLGM[SHADOWING] == 0 )) && { ZPLGM[SHADOWING]="inactive"; builtin setopt noaliases; (( ${+ZPLGM[bkp-compdef]} )) && functions[compdef]="${ZPLGM[bkp-compdef]}" || unfunction "compdef"; builtin setopt aliases; }
    elif [[ -n "${opts[(r)--command]}" || "${ZPLG_ICE[as]}" = "command" ]]; then
        # Subversion - directory and multiple files possible
        if (( ${+ZPLG_ICE[svn]} )); then
            if [[ -n ${ZPLG_ICE[pick]} ]]; then
                list=( ${(M)~ZPLG_ICE[pick]##/*}(N) $local_dir/$dirname/${~ZPLG_ICE[pick]}(N) )
                [[ -n "${list[1-correct]}" ]] && local xpath="${list[1-correct]:h}" xfilepath="${list[1-correct]}"
            else
                local xpath="$local_dir/$dirname"
            fi
        else
            local xpath="$local_dir/$dirname" xfilepath="$local_dir/$dirname/$filename"
            # This doesn't make sense, but users may come up with something
            [[ -n ${ZPLG_ICE[pick]} ]] && {
                list=( ${(M)~ZPLG_ICE[pick]##/*}(N) $local_dir/$dirname/${~ZPLG_ICE[pick]}(N) )
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
            if [[ -n "${ZPLG_ICE[src]}" ]]; then
                ZERO="${${(M)ZPLG_ICE[src]##/*}:-$local_dir/$dirname/${ZPLG_ICE[src]}}"
                (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); }
            fi
            [[ -n ${ZPLG_ICE[multisrc]} ]] && { eval "reply=( ${ZPLG_ICE[multisrc]} )"; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$local_dir/$dirname/$fname}"; (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); }; done; }
            (( ${+ZPLG_ICE[atload]} && tmp[1-correct] )) && [[ "${ZPLG_ICE[atload][1]}" = "!" ]] && { ZERO="$local_dir/$dirname/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ZPLG_ICE[atload]#\!}"; ((1)); } || eval "${ZPLG_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }
            (( -- ZPLGM[SHADOWING] == 0 )) && { ZPLGM[SHADOWING]="inactive"; builtin setopt noaliases; (( ${+ZPLGM[bkp-compdef]} )) && functions[compdef]="${ZPLGM[bkp-compdef]}" || unfunction "compdef"; builtin setopt aliases; }
        }
    elif [[ "${ZPLG_ICE[as]}" = "completion" ]]; then
        ((1))
    fi

    # Updating – not sourcing, etc.
    [[ -n "${opts[(r)-u]}" ]] && return 0

    (( ${+ZPLG_ICE[atload]} && tmp[1-correct] )) && [[ "${ZPLG_ICE[atload][1]}" != "!" ]] && { ZERO="$local_dir/$dirname/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ZPLG_ICE[atload]}"; ((1)); } || eval "${ZPLG_ICE[atload]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    (( ${+ZPLG_ICE[notify]} == 1 )) && { [[ "$retval" -eq 0 || -n "${(M)ZPLG_ICE[notify]#\!}" ]] && { local msg; eval "msg=\"${ZPLG_ICE[notify]#\!}\""; -zplg-deploy-message @msg "$msg" } || -zplg-deploy-message @msg "notify: Plugin not loaded / loaded with problem, the return code: $retval"; }
    (( ${+ZPLG_ICE[reset-prompt]} == 1 )) && -zplg-deploy-message @rst

    ZPLGM[TIME_INDEX]=$(( ${ZPLGM[TIME_INDEX]:-0} + 1 ))
    ZPLGM[TIME_${ZPLGM[TIME_INDEX]}_${id_as}]=$SECONDS
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
    [[ "${ZPLGM[DTRACE]}" = "1" ]] && { (( ${+builtins[zpmod]} )) && zpmod report-append "$1" "$2"$'\n' || ZPLG_REPORTS[_dtrace/_dtrace]+="$2"$'\n'; }
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

    local pbase="${${plugin:t}%(.plugin.zsh|.zsh|.git)}"
    [[ "$user" = "%" ]] && local pdir_path="$plugin" || local pdir_path="${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}"
    local pdir_orig="$pdir_path"

    if [[ "${ZPLG_ICE[as]}" = "command" ]]; then
        reply=()
        if [[ -n "${ZPLG_ICE[pick]}" && "${ZPLG_ICE[pick]}" != "/dev/null" ]]; then
            reply=( ${(M)~ZPLG_ICE[pick]##/*}(N) $pdir_path/${~ZPLG_ICE[pick]}(N) )
            [[ -n "${reply[1-correct]}" ]] && pdir_path="${reply[1-correct]:h}"
        fi
        [[ -z "${path[(er)$pdir_path]}" ]] && {
            [[ "$mode" != "light" ]] && -zplg-diff-env "${ZPLGM[CUR_USPL2]}" begin
            path=( "${pdir_path%/}" ${path[@]} )
            [[ "$mode" != "light" ]] && -zplg-diff-env "${ZPLGM[CUR_USPL2]}" end
            -zplg-add-report "${ZPLGM[CUR_USPL2]}" "$ZPLGM[col-info2]$pdir_path$ZPLGM[col-rst] added to \$PATH"
        }
        [[ -n "${reply[1-correct]}" && ! -x "${reply[1-correct]}" ]] && command chmod a+x ${reply[@]}

        local ZERO
        [[ -n ${ZPLG_ICE[src]} ]] && { ZERO="${${(M)ZPLG_ICE[src]##/*}:-$pdir_orig/${ZPLG_ICE[src]}}"; (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); }; }
        [[ -n ${ZPLG_ICE[multisrc]} ]] && { eval "reply=( ${ZPLG_ICE[multisrc]} )"; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$pdir_orig/$fname}"; (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); }; done; }
        [[ ${ZPLG_ICE[atload][1]} = "!" ]] && { ZERO="$pdir_orig/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; } && builtin eval "${ZPLG_ICE[atload]#\!}"; } || eval "${ZPLG_ICE[atclone]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }
    elif [[ "${ZPLG_ICE[as]}" = "completion" ]]; then
        ((1))
    else
        if [[ -n ${ZPLG_ICE[pick]} ]]; then
            [[ "${ZPLG_ICE[pick]}" = "/dev/null" ]] && reply=( "/dev/null" ) || reply=( ${(M)~ZPLG_ICE[pick]##/*}(N) $pdir_path/${~ZPLG_ICE[pick]}(N) )
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
        if [[ "$mode" != (light|light-b) ]]; then
            -zplg-diff-functions "${ZPLGM[CUR_USPL2]}" begin
            -zplg-diff-options "${ZPLGM[CUR_USPL2]}" begin
            -zplg-diff-env "${ZPLGM[CUR_USPL2]}" begin
            -zplg-diff-parameter "${ZPLGM[CUR_USPL2]}" begin
        fi

        -zplg-shadow-on "${mode:-load}"

        # We need some state, but user wants his for his plugins
        (( ${+ZPLG_ICE[blockf]} )) && { local -a fpath_bkp; fpath_bkp=( "${fpath[@]}" ); }
        local ZERO="$pdir_path/$fname"
        builtin setopt noaliases
        (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); }
        [[ -n ${ZPLG_ICE[src]} ]] && { ZERO="${${(M)ZPLG_ICE[src]##/*}:-$pdir_orig/${ZPLG_ICE[src]}}"; (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); }; }
        [[ -n ${ZPLG_ICE[multisrc]} ]] && { eval "reply=( ${ZPLG_ICE[multisrc]} )"; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$pdir_orig/$fname}"; (( ${+ZPLG_ICE[silent]} )) && { builtin source "$ZERO" 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { builtin source "$ZERO"; (( retval += $? )); } done; }
        [[ ${ZPLG_ICE[atload][1]} = "!" ]] && { ZERO="$pdir_orig/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; } && builtin eval "${ZPLG_ICE[atload]#\!}"; ((1)); } || eval "${ZPLG_ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }
        builtin unsetopt noaliases
        (( ${+ZPLG_ICE[blockf]} )) && { fpath=( "${fpath_bkp[@]}" ); }

        -zplg-shadow-off "${mode:-load}"

        if [[ "$mode" != (light|light-b) ]]; then
            -zplg-diff-parameter "${ZPLGM[CUR_USPL2]}" end
            -zplg-diff-env "${ZPLGM[CUR_USPL2]}" end
            -zplg-diff-options "${ZPLGM[CUR_USPL2]}" end
            -zplg-diff-functions "${ZPLGM[CUR_USPL2]}" end
        fi
    fi

    (( ${+ZPLG_ICE[atload]} )) && [[ "${ZPLG_ICE[atload][1]}" != "!" ]] && { ZERO="$pdir_orig/-atload-"; local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$pdir_orig"; } && builtin eval "${ZPLG_ICE[atload]}"; ((1)); } || eval "${ZPLG_ICE[atload]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

    # Mark no load is in progress
    ZPLGM[CUR_USR]="" ZPLG_CUR_PLUGIN="" ZPLGM[CUR_USPL2]=""

    (( $5 )) && { print; zle .reset-prompt; }
    return $retval
} # }}}

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

    -zplg-diff-functions "_dtrace/_dtrace" begin
    -zplg-diff-options "_dtrace/_dtrace" begin
    -zplg-diff-env "_dtrace/_dtrace" begin
    -zplg-diff-parameter "_dtrace/_dtrace" begin

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
    -zplg-diff-parameter "_dtrace/_dtrace" end
    -zplg-diff-env "_dtrace/_dtrace" end
    -zplg-diff-options "_dtrace/_dtrace" end
    -zplg-diff-functions "_dtrace/_dtrace" end
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
# Parses ICE specification (`zplg ice' subcommand), puts
# the result into ZPLG_ICE global hash. The ice-spec is
# valid for next command only (i.e. it "melts"), but it
# can then stick to plugin and activate e.g. at update.
-zplg-ice() {
    setopt localoptions extendedglob noksharrays
    local bit
    for bit; do
        [[ "$bit" = (#b)(teleid|from|proto|cloneopts|depth|wait|load|\
unload|on-update-of|subscribe|if|has|cloneonly|blockf|svn|pick|\
nopick|src|bpick|as|ver|silent|lucid|mv|cp|atinit|atload|atpull|\
atclone|run-atpull|make|nomake|notify|reset-prompt|nosvn|service|\
compile|nocompletions|nocompile|multisrc|id-as|bindmap|trackbinds|\
nocd|once)(*) ]] && ZPLG_ICE[${match[1]}]="${match[2]#(:|=)}"
    done
    [[ "${ZPLG_ICE[as]}" = "program" ]] && ZPLG_ICE[as]="command"
    ZPLG_ICE[subscribe]="${ZPLG_ICE[subscribe]:-${ZPLG_ICE[on-update-of]}}"
    [[ -n "${ZPLG_ICE[pick]}" ]] && ZPLG_ICE[pick]="${ZPLG_ICE[pick]//\$ZPFX/${ZPFX%/}}"
} # }}}
# FUNCTION: -zplg-pack-ice {{{
# Remembers long-live ICE specs, assigns them to concrete plugin.
# Ice spec is in general forgotten for second-next command (that's
# why it's called "ice" - it melts), however some ice modifiers can
# glue to plugin mentioned in the next command.
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
# $3 - id - URL or plugin ID
-zplg-service() {
    local __tpe="$1" __mode="$2" __id="$3" __fle="${ZPLGM[SERVICES_DIR]}/${ZPLG_ICE[service]}.lock" __fd __cmd __tmp __lckd __strd=0
    { builtin echo -n >! "$__fle"; } 2>/dev/null 1>&2
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
                [[ "$__cmd" = (#i)"STOP" ]] && { kill -TERM "$ZSRV_PID"; builtin read -t 2 __tmp <>"${__fle:r}.fifo2"; kill -HUP "$ZSRV_PID"; __strd=0; builtin echo >! "${__fle:r}.stop"; }
                [[ "$__cmd" = (#i)"QUIT" ]] && { kill -HUP ${sysparams[pid]}; return 1; }
                [[ "$__cmd" != (#i)"RESTART" ]] && { __cmd=""; builtin read -t 1 __tmp <>"${__fle:r}.fifo2"; }
            done
        ) || break
        builtin read -t 1 __tmp <>"${__fle:r}.fifo2"
    done >>! "$ZSRV_WORK_DIR"/"$ZSRV_ID".log 2>&1
}
# }}}
# FUNCTION: -zplg-run-task {{{
-zplg-run-task() {
    local __pass="$1" __t="$2" __tpe="$3" __idx="$4" __mode="$5" __id="${(Q)6}" __action __s=1 __retval=0

    local -A ZPLG_ICE
    ZPLG_ICE=( "${(@Q)${(z@)ZPLGM[WAIT_ICE_${__idx}]}}" )

    if [[ $__pass = 1 && "${${ZPLG_ICE[wait]#\!}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)}" = <-> ]]; then
        __action="${(M)ZPLG_ICE[wait]#\!}load"
    elif [[ $__pass = 1 && -n "${ZPLG_ICE[wait]#\!}" ]] && { eval "${ZPLG_ICE[wait]#\!}" || [[ $(( __s=0 )) = 1 ]]; }; then
        __action="${(M)ZPLG_ICE[wait]#\!}load"
    elif [[ -n "${ZPLG_ICE[load]#\!}" && -n $(( __s=0 )) && $__pass = 2 && -z "${ZPLG_REGISTERED_PLUGINS[(r)$__id]}" ]] && eval "${ZPLG_ICE[load]#\!}"; then
        __action="${(M)ZPLG_ICE[load]#\!}load"
    elif [[ -n "${ZPLG_ICE[unload]#\!}" && -n $(( __s=0 )) && $__pass = 1 && -n "${ZPLG_REGISTERED_PLUGINS[(r)$__id]}" ]] && eval "${ZPLG_ICE[unload]#\!}"; then
        __action="${(M)ZPLG_ICE[unload]#\!}remove"
    elif [[ -n "${ZPLG_ICE[subscribe]#\!}" && $(( __s=0 )) && "$__pass" = 2 ]] && \
        { local -a fts_arr
          eval "fts_arr=( ${ZPLG_ICE[subscribe]}(Nms-$(( EPOCHSECONDS -
                 ZPLGM[fts-${ZPLG_ICE[subscribe]}] ))) ); (( \${#fts_arr} ))" && \
                 { ZPLGM[fts-${ZPLG_ICE[subscribe]}]="$EPOCHSECONDS"; __s=${+ZPLG_ICE[once]}; } || (( 0 ))
        }
    then
        __action="${(M)ZPLG_ICE[subscribe]#\!}load"
    fi

    if [[ "$__action" = *load ]]; then
        if [[ "$__tpe" = "p" ]]; then
            -zplg-load "$__id" "" "$__mode"; (( __retval += $? ))
        elif [[ "$__tpe" = "s" ]]; then
            -zplg-load-snippet "$__id" ""; (( __retval += $? ))
        elif [[ "$__tpe" = "p1" || "$__tpe" = "s1" ]]; then
            zpty -b "${__id//\//:}" '-zplg-service '"${(M)__tpe#?}"' "$__mode" "$__id"'
        fi
        (( ${+ZPLG_ICE[silent]} == 0 && ${+ZPLG_ICE[lucid]} == 0 && __retval == 0 )) && zle && zle -M "Loaded $__id"
    elif [[ "$__action" = *remove ]]; then
        (( ${+functions[-zplg-format-functions]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-autoload.zsh"
        [[ "$__tpe" = "p" ]] && -zplg-unload "$__id" "" "-q"
    fi

    [[ "${REPLY::=$__action}" = \!* ]] && zle && zle .reset-prompt

    return $__s
}
# }}}
# FUNCTION: -zplg-deploy-message {{{
# Deploys a sub-prompt message to be displayed
-zplg-deploy-message() {
    [[ "$1" = <-> && ${#} -eq 1 ]] && { zle && {
            local alltext text IFS=$'\n' nl=$'\n'
            repeat 25; do read -u"$1" text; alltext+="${text:+$text$nl}"; done
            [[ "$alltext" = "@rst$nl" ]] && zle .reset-prompt || { [[ -n "$alltext" ]] && zle -M "$alltext"; }
        }
        zle -F "$1"; exec {1}<&-
        return 0
    }
    local THEFD
    # The expansion is: if there is @sleep: pfx, then use what's after
    # it, otherwise substitute 0
    exec {THEFD} < <(LANG=C sleep $(( 0.01 + ${${${(M)1#@sleep:}:+${1#@sleep:}}:-0} )); print -r -- ${1:#(@msg|@sleep:*)} "${@[2,-1]}")
    zle -F "$THEFD" -zplg-deploy-message
}
# }}}

# FUNCTION: -zplg-submit-turbo {{{
# If `zplugin load`, `zplugin light` or `zplugin snippet`  will be
# preceded with `wait', `load' or `unload' ice-mods then the plugin
# or snipped is to be loaded in turbo-mode, and this function adds
# it to internal data structures, so that -zplg-scheduler can run
# (load, unload) this as a task.
-zplg-submit-turbo() {
    local tpe="$1" mode="$2" opt_uspl2="$3" opt_plugin="$4"

    ZPLG_ICE[wait]="${ZPLG_ICE[wait]%%.[0-9]##}"
    ZPLGM[WAIT_IDX]=$(( ${ZPLGM[WAIT_IDX]:-0} + 1 ))
    ZPLGM[WAIT_ICE_${ZPLGM[WAIT_IDX]}]="${(j: :)${(qkv)ZPLG_ICE[@]}}"
    ZPLGM[fts-${ZPLG_ICE[subscribe]}]="${ZPLG_ICE[subscribe]:+$EPOCHSECONDS}"

    local id="${${opt_plugin:+$opt_uspl2${${opt_uspl2:#%*}:+/}$opt_plugin}:-$opt_uspl2}"

    if [[ "${${ZPLG_ICE[wait]}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)}" = (\!|.|)<-> ]]; then
        ZPLG_TASKS+=( "$EPOCHSECONDS+${${ZPLG_ICE[wait]#(\!|.)}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)}+${${${(M)ZPLG_ICE[wait]%a}:+1}:-${${${(M)ZPLG_ICE[wait]%b}:+2}:-${${${(M)ZPLG_ICE[wait]%c}:+3}:-1}}} $tpe ${ZPLGM[WAIT_IDX]} ${mode:-_} ${(q)id}" )
    elif [[ -n "${ZPLG_ICE[wait]}${ZPLG_ICE[load]}${ZPLG_ICE[unload]}${ZPLG_ICE[subscribe]}" ]]; then
        ZPLG_TASKS+=( "${${ZPLG_ICE[wait]:+0}:-1}+0+1 $tpe ${ZPLGM[WAIT_IDX]} ${mode:-_} ${(q)id}" )
    fi
}
# }}}
# FUNCTION: -zplugin_scheduler_add_sh {{{
# Copies task into ZPLG_RUN array, called when a task timeouts.
# A small function ran from pattern in /-substitution.
-zplugin_scheduler_add_sh() {
    local idx="$1" in_wait="$__ar2" in_abc="$__ar3" ver_wait="$__ar4" ver_abc="$__ar5"
    if [[ ( "$in_wait" = "$ver_wait" || "$in_wait" -ge 10 ) && "$in_abc" = "$ver_abc" ]]; then
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
# $1 - if "following", then it is non-first (second and more) invocation
#      of the scheduler; this results in chain of `sched' invocations that
#      results in repetitive -zplg-scheduler activity;
#
#      if "burst", then all tasks are marked timeout and executed one by one;
#      this is handy if e.g. a docker image starts up and needs to install
#      all turbo-mode plugins without any hesitation (delay), i.e. "burst"
#      allows to run package installations from script, not from prompt
#
-zplg-scheduler() {
    integer __ret=$?
    [[ "$1" = "following" ]] && sched +1 "-zplg-scheduler following"
    [[ -n "$1" && "$1" != (following*|burst) ]] && { local THEFD="$1"; zle -F "$THEFD"; exec {THEFD}<&-; }
    [[ "$1" = "burst" ]] && local -h EPOCHSECONDS=$(( EPOCHSECONDS+10000 ))

    integer __t=EPOCHSECONDS __i correct=0
    local -a match mbegin mend reply
    local REPLY

    [[ -o ksharrays ]] && correct=1

    [[ -n "$1" ]] && {
        () {
            emulate -L zsh
            setopt extendedglob
            # Example entry:
            # 1531252764+2+1 p 18 light zdharma/zsh-diff-so-fancy
            #
            # This either doesn't change ZPLG_TASKS entry - when
            # __i is used in the ternary expression, or replaces
            # an entry with "<no-data>", i.e. ZPLG_TASKS[1] entry.
            integer __idx1 __idx2
            local __ar2 __ar3 __ar4 __ar5
            for (( __idx1 = 0; __idx1 <= 10; __idx1 ++ )); do
                for (( __idx2 = 1; __idx2 <= 3; __idx2 ++ )); do
                    # The following substitution could be just (well, 'just'..) this:
                    #
                    # ZPLG_TASKS=( ${ZPLG_TASKS[@]/(#b)([0-9]##)+([0-9]##)+([1-3])(*)/
                    # ${ZPLG_TASKS[$(( (${match[1-correct]}+${match[2-correct]}) <= $__t ?
                    # zplugin_scheduler_add(__i++ - correct, ${match[2-correct]},
                    # ${(M)match[3-correct]%[1-3]}, __idx1, __idx2) : __i++ ))]}} )
                    #
                    # However, there's a severe bug in Zsh <= 5.3.1 - use of the period
                    # (,) is impossible inside ${..//$arr[$(( ... ))]}.
                    __i=2

                    ZPLG_TASKS=( ${ZPLG_TASKS[@]/(#b)([0-9]##)+([0-9]##)+([1-3])(*)/${ZPLG_TASKS[
                    $(( (__ar2=${match[2-correct]}+1) ? (
                        (__ar3=${(M)match[3-correct]%[1-3]}) ? (
                        (__ar4=__idx1+1) ? (
                        (__ar5=__idx2) ? (
            (${match[1-correct]}+${match[2-correct]}) <= $__t ?
            zplugin_scheduler_add(__i++ - correct) : __i++ )
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
        () {
            emulate -L zsh
            setopt extendedglob
            # No "+" in this pattern, it will match only "1531252764"
            # in "1531252764+2" and replace it with current time
            ZPLG_TASKS=( ${ZPLG_TASKS[@]/(#b)([0-9]##)(*)/$(( ${match[1-correct]} <= 1 ? ${match[1-correct]} : __t ))${match[2-correct]}} )
        }
        # There's a bug in Zsh: first sched call would not be issued
        # until a key-press, if "sched +1 ..." would be called inside
        # zle -F handler. So it's done here, in precmd-handle code.
        sched +1 "-zplg-scheduler following"

        local ANFD="13371337" # for older Zsh + noclobber option
        exec {ANFD}< <(builtin echo run;)
        zle -F "$ANFD" -zplg-scheduler
    }

    local __task __idx=0 __count=0 __idx2
    for __task in "${ZPLG_RUN[@]}"; do
        -zplg-run-task 1 "${(@z)__task}" && ZPLG_TASKS+=( "$__task" )
        [[ $(( ++__idx, __count += ${${REPLY:+1}:-0} )) -gt 5 && "$1" != "burst" ]] && { sched +0 -zplg-scheduler following-additional; break; }
    done
    for (( __idx2=1; __idx2 <= __idx; ++ __idx2 )); do
        -zplg-run-task 2 "${(@z)ZPLG_RUN[__idx2-correct]}"
    done
    ZPLG_RUN[1-correct,__idx-correct]=()

    return $__ret
}
# }}}

#
# Exposed functions
#

# FUNCTION: zplugin {{{
# Main function directly exposed to user, obtains subcommand
# and its arguments, has completion.
zplugin() {
    [[ "$1" != "ice" ]] && {
        local -A ice ICE_OPTS

        ice=( "${(kv)ZPLG_ICE[@]}" )
        ZPLG_ICE=()

        local -A ZPLG_ICE
        () {
            setopt localoptions extendedglob
            ZPLG_ICE=( "${(kv@)ice[(I)^opt_*]}" )
            ICE_OPTS=( "${(kv@)ice[(I)opt_*]}" )
        }
    }

    local -a match mbegin mend reply
    local MATCH REPLY; integer MBEGIN MEND

    case "$1" in
       (load|light)
           (( ${+ZPLG_ICE[if]} )) && { eval "${ZPLG_ICE[if]}" || return 0; }
           (( ${+ZPLG_ICE[has]} )) && { (( ${+commands[${ZPLG_ICE[has]}]} )) || return 0; }
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
           else
               if [[ -n "${ZPLG_ICE[wait]}${ZPLG_ICE[load]}${ZPLG_ICE[unload]}${ZPLG_ICE[service]}${ZPLG_ICE[subscribe]}" ]]; then
                   ZPLG_ICE[wait]="${ZPLG_ICE[wait]:-${ZPLG_ICE[service]:+0}}"
                   [[ "$2" = "-b" && "$1" = "light" ]] && { shift; 1="light-b"; }
                   -zplg-submit-turbo p${ZPLG_ICE[service]:+1} "$1" "${${2#https://github.com/}%%(/|//|///)}" "${3%%(/|//|///)}"
               else
                   [[ "$2" = "-b" && "$1" = "light" ]] && { shift; 1="light-b"; }
                   -zplg-load "${${2#https://github.com/}%%(/|//|///)}" "${3%%(/|//|///)}" "${1/load/}"
               fi
           fi
           ;;
       (snippet)
           (( ${+ZPLG_ICE[if]} )) && { eval "${ZPLG_ICE[if]}" || return 0; }
           (( ${+ZPLG_ICE[has]} )) && { (( ${+commands[${ZPLG_ICE[has]}]} )) || return 0; }
           if [[ -n "${ZPLG_ICE[wait]}${ZPLG_ICE[load]}${ZPLG_ICE[unload]}${ZPLG_ICE[service]}${ZPLG_ICE[subscribe]}" ]]; then
               ZPLG_ICE[wait]="${ZPLG_ICE[wait]:-${ZPLG_ICE[service]:+0}}"
               -zplg-submit-turbo s${ZPLG_ICE[service]:+1} "" "${2%%(/|//|///)}" "$3"
           else
               ZPLG_SICE[${2%%(/|//|///)}]=""
               -zplg-load-snippet "${2%%(/|//|///)}" "$3"
           fi
           ;;
       (ice)
           shift
           -zplg-ice "$@"
           ;;
       (cdreplay)
           -zplg-compdef-replay "$2"
           ;;
       (cdclear)
           -zplg-compdef-clear "$2"
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
           (( ${+functions[-zplg-format-functions]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-autoload.zsh"
           case "$1" in
               (zstatus)
                   -zplg-show-zstatus
                   ;;
               (times)
                   -zplg-show-times "${@[2,-1]}"
                   ;;
               (self-update)
                   -zplg-self-update
                   ;;
               (unload)
                   (( ${+functions[-zplg-unload]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-autoload.zsh"
                   if [[ -z "$2" && -z "$3" ]]; then
                       print "Argument needed, try help"
                   else
                       [[ "$2" = "-q" ]] && { 5="-q"; shift; }
                       # Unload given plugin. Cloned directory remains intact
                       # so as are completions
                       -zplg-unload "${2%%(/|//|///)}" "${${3:#-q}%%(/|//|///)}" "${${(M)4:#-q}:-${(M)3:#-q}}"
                   fi
                   ;;
               (bindkeys)
                   -zplg-list-bindkeys
                   ;;
               (update)
                   (( ${+ZPLG_ICE[if]} )) && { eval "${ZPLG_ICE[if]}" || return 0; }
                   (( ${+ZPLG_ICE[has]} )) && { (( ${+commands[${ZPLG_ICE[has]}]} )) || return 0; }
                   local -A map
                   map=(
                       -q       opt_-q,--quiet
                       --quiet  opt_-q,--quiet
                       -r       opt_-r,--reset
                       --reset  opt_-r,--reset
                   )
                   : ${@[@]//(#b)(--quiet|-q|--reset|-r)/${ICE_OPTS[${map[${match[1]}]}]::=1}}
                   set -- "${@[@]:#(--quiet|-q|--reset|-r)}"
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       -zplg-update-or-status-all "update"
                   else
                       -zplg-update-or-status "update" "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   fi
                   ;;
               (status)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       -zplg-update-or-status-all "status"
                   else
                       -zplg-update-or-status "status" "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   fi
                   ;;
               (report)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { print -r -- "Assuming --all is passed"; sleep 3; }
                       -zplg-show-all-reports
                   else
                       -zplg-show-report "${2%%(/|//|///)}" "${3%%(/|//|///)}"
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
                       print "Argument needed, try help"
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
                       fi
                   fi
                   ;;
               (cenable)
                   if [[ -z "$2" ]]; then
                       print "Argument needed, try help"
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
                       fi
                   fi
                   ;;
               (creinstall)
                   (( ${+functions[-zplg-install-completions]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                   # Installs completions for plugin. Enables them all. It's a
                   # reinstallation, thus every obstacle gets overwritten or removed
                   [[ "$2" = "-q" ]] && { 5="-q"; shift; }
                   -zplg-install-completions "${2%%(/|//|///)}" "${3%%(/|//|///)}" "1" "${(M)4:#-q}"
                   [[ -z "${(M)4:#-q}" ]] && print "Initializing completion (compinit)..."
                   builtin autoload -Uz compinit
                   compinit -d ${ZPLGM[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZPLGM[COMPINIT_OPTS]}}"
                   ;;
               (cuninstall)
                   if [[ -z "$2" && -z "$3" ]]; then
                       print "Argument needed, try help"
                   else
                       (( ${+functions[-zplg-forget-completion]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                       # Uninstalls completions for plugin
                       -zplg-uninstall-completions "${2%%(/|//|///)}" "${3%%(/|//|///)}"
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
                   -zplg-compinit
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
                       -zplg-compile-uncompile-all "1"
                   else
                       -zplg-compile-plugin "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   fi
                   ;;
               (uncompile)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { print -r -- "Assuming --all is passed"; sleep 2; }
                       -zplg-compile-uncompile-all "0"
                   else
                       -zplg-uncompile-plugin "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   fi
                   ;;
               (compiled)
                   -zplg-compiled
                   ;;
               (cdlist)
                   -zplg-list-compdef-replay
                   ;;
               (cd)
                   -zplg-cd "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   ;;
               (delete)
                   -zplg-delete "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   ;;
               (recall)
                   -zplg-recall "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   ;;
               (edit)
                   -zplg-edit "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   ;;
               (glance)
                   -zplg-glance "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   ;;
               (changes)
                   -zplg-changes "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   ;;
               (recently)
                   shift
                   -zplg-recently "$@"
                   ;;
               (create)
                   -zplg-create "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   ;;
               (stress)
                   -zplg-stress "${2%%(/|//|///)}" "${3%%(/|//|///)}"
                   ;;
               (-h|--help|help|"")
                   -zplg-help
                   ;;
               (ls)
                   shift
                   -zplg-ls "$@"
                   ;;
               (srv)
                   () { setopt localoptions extendedglob
                   [[ ! -e ${ZPLGM[SERVICES_DIR]}/"$2".fifo ]] && { print "No such service: $2"; } ||
                       { [[ "$3" = (#i)(next|stop|quit|restart) ]] &&
                           { print "${(U)3}" >>! ${ZPLGM[SERVICES_DIR]}/"$2".fifo || print "Service $2 inactive"; ((1)); } ||
                               { [[ "$3" = (#i)start ]] && rm -f ${ZPLGM[SERVICES_DIR]}/"$2".stop ||
                                   { print "Unknown service-command: $3"; }
                               }
                       }
                   } "$@"
                   ;;
               (module)
                   -zplg-module "${@[2,-1]}"
                   ;;
               (*)
                   print "Unknown command \`$1' (use \`help' to get usage information)"
                   ;;
            esac
            ;;
    esac
} # }}}
# FUNCTION: zpcdreplay {{{
# A function that can be invoked from within `atinit', `atload', etc. ice-mod.
# It works like `zplugin cdreplay', which cannot be invoked from hook ices.
zpcdreplay() { -zplg-compdef-replay -q; }
# }}}
zpcdclear() { -zplg-compdef-clear -q; }
# FUNCTION: zpcompinit {{{
# A function that can be invoked from within `atinit', `atload', etc. ice-mod.
# It runs `autoload compinit; compinit' and respects ZPLGM[ZCOMPDUMP_PATH].
zpcompinit() { autoload -Uz compinit; compinit -d ${ZPLGM[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZPLGM[COMPINIT_OPTS]}}"; }
# }}}
# FUNCTION: zpcompdef {{{
# Stores compdef for a replay with `zpcdreplay' (turbo
# mode) or with `zplugin cdreplay' (normal mode)
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
ZPLG_REGISTERED_PLUGINS+=( "_local/zplugin" )
ZPLG_REGISTERED_PLUGINS=( "${(u)ZPLG_REGISTERED_PLUGINS[@]}" )
ZPLG_REGISTERED_STATES[_local/zplugin]="1"

# Add completions directory to fpath
fpath=( "${ZPLGM[COMPLETIONS_DIR]}" "${fpath[@]}" )

# Colorize completions for commands unload, report, creinstall, cuninstall
zstyle ':completion:*:zplugin:argument-rest:plugins' list-colors '=(#b)(*)/(*)==1;35=1;33'
zstyle ':completion:*:zplugin:argument-rest:plugins' matcher 'r:|=** l:|=*'
# }}}
