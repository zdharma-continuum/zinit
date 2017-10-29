# -*- mode: shell-script -*-
# vim:ft=zsh

#
# Main state variables
#

typeset -gaH ZPLG_REGISTERED_PLUGINS
# Snippets loaded, url -> file name
typeset -gAH ZPLGM ZPLG_REGISTERED_STATES ZPLG_SNIPPETS ZPLG_REPORTS ZPLG_ICE ZPLG_SICE

#
# Common needed values
#

[[ ! -e "${ZPLGM[BIN_DIR]}"/zplugin.zsh ]] && ZPLGM[BIN_DIR]=""

ZPLGM[ZERO]="$0"
[[ ! -o "functionargzero" ]] && ZPLGM[ZERO]="${(%):-%N}" # this gives immunity to functionargzero being unset

[[ -z "${ZPLGM[BIN_DIR]}" ]] && ZPLGM[BIN_DIR]="${ZPLGM[ZERO]:h}"

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

typeset -gAH ZPLG_BACKUP_FUNCTIONS

builtin autoload -Uz is-at-least
is-at-least 5.1 && ZPLGM[NEW_AUTOLOAD]=1 || ZPLGM[NEW_AUTOLOAD]=0

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
local -A ZPLG_1MAP ZPLG_2MAP
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

    local FPATH="$fpath_prefix":"${FPATH}"

    # After this the function exists again
    local IFS=" "
    builtin autoload $=autoload_opts -- "$func"

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

    zparseopts -a opts -D ${(s::):-TUXkmtzw}

    # TODO: +X
    if (( ${+opts[(r)-X]} ))
    then
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Failed autoload $opts $*"
        print -u2 "builtin autoload required for $opts"
        return 1 # Testable
    fi
    if (( ${+opts[(r)-w]} ))
    then
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "-w-Autoload $opts $*"
        builtin autoload $opts "$@"
        return 0 # Testable
    fi

    # Report ZPLUGIN's "native" autoloads
    local i
    for i in "$@"; do
        local msg="Autoload $i"
        [[ -n "$opts" ]] && msg+=" with options ${opts[@]}"
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "$msg"
    done

    # Do ZPLUGIN's "native" autoloads
    if [[ "$ZPLGM[CUR_USR]" = "%" ]] && local PLUGIN_DIR="$ZPLG_CUR_PLUGIN" || local PLUGIN_DIR="${ZPLGM[PLUGINS_DIR]}/${ZPLGM[CUR_USPL]}"
    for func
    do
        # Real autoload doesn't touch function if it already exists
        # Author of the idea of FPATH-clean autoloading: Bart Schaefer
        if (( ${+functions[$func]} != 1 )); then
            builtin setopt noaliases
            if [[ "${ZPLGM[NEW_AUTOLOAD]}" = "1" ]]; then
                eval "function ${(q)func} {
                    local FPATH=${(qqq)PLUGIN_DIR}:${(qqq)FPATH}
                    builtin autoload -X ${(q-)opts[@]}
                }"
            else
                eval "function ${(q)func} {
                    --zplg-reload-and-run ${(q)PLUGIN_DIR} ${(qq)opts[*]} ${(q)func} "'"$@"
                }'
            fi
            #functions[$func]="--zplg-reload-and-run ${(q)PLUGIN_DIR} ${(qq)opts[*]} ${(q)func} "'"$@"'
            builtin unsetopt noaliases
        fi
    done

    # Testable
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

    if [[ "${#opts[@]}" -eq "0" ||
        ( "${#opts[@]}" -eq "1" && "${+opts[(r)-M]}" = "1" ) ||
        ( "${#opts[@]}" -eq "1" && "${+opts[(r)-R]}" = "1" ) ||
        ( "${#opts[@]}" -eq "1" && "${+opts[(r)-s]}" = "1" ) ||
        ( "${#opts[@]}" -le "2" && "${+opts[(r)-M]}" = "1" && "${+opts[(r)-s]}" = "1" ) ||
        ( "${#opts[@]}" -le "2" && "${+opts[(r)-M]}" = "1" && "${+opts[(r)-R]}" = "1" )
    ]]; then
        local string="${(q)1}" widget="${(q)2}"
        local quoted

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
    (( ${+ZPLG_BACKUP_FUNCTIONS[bindkey]} )) && functions[bindkey]="${ZPLG_BACKUP_FUNCTIONS[bindkey]}" || unfunction "bindkey"

    # Actual bindkey
    bindkey "${pos[@]}"
    integer ret=$?

    # A. Shadow on. Custom function could unfunction itself
    (( ${+functions[bindkey]} )) && ZPLG_BACKUP_FUNCTIONS[bindkey]="${functions[bindkey]}" || unset "ZPLG_BACKUP_FUNCTIONS[bindkey]"
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

    if [[ "${#opts[@]}" -eq 0 || ( "${#opts[@]}" -eq 1 && "${+opts[(r)-e]}" = "1" ) ]]; then
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
    (( ${+ZPLG_BACKUP_FUNCTIONS[zstyle]} )) && functions[zstyle]="${ZPLG_BACKUP_FUNCTIONS[zstyle]}" || unfunction "zstyle"

    # Actual zstyle
    zstyle "${pos[@]}"
    integer ret=$?

    # B. Shadow on. Custom function could unfunction itself
    (( ${+functions[zstyle]} )) && ZPLG_BACKUP_FUNCTIONS[zstyle]="${functions[zstyle]}" || unset "ZPLG_BACKUP_FUNCTIONS[zstyle]"
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
        (( ${+aliases[$aname]} )) && -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Warning: redefining alias \`${aname}', previous value: ${avalue}"

        aname="${(q)aname}"
        local bname="${(q)avalue}"

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
    (( ${+ZPLG_BACKUP_FUNCTIONS[alias]} )) && functions[alias]="${ZPLG_BACKUP_FUNCTIONS[alias]}" || unfunction "alias"

    # Actual alias
    alias "${pos[@]}"
    integer ret=$?

    # C. Shadow on. Custom function could unfunction itself
    (( ${+functions[alias]} )) && ZPLG_BACKUP_FUNCTIONS[alias]="${functions[alias]}" || unset "ZPLG_BACKUP_FUNCTIONS[alias]"
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
                builtin zle -A "$widname" "$saved_widname"

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
    (( ${+ZPLG_BACKUP_FUNCTIONS[zle]} )) && functions[zle]="${ZPLG_BACKUP_FUNCTIONS[zle]}" || unfunction "zle"

    # Actual zle
    zle "${pos[@]}"
    integer ret=$?

    # D. Shadow on. Custom function could unfunction itself
    (( ${+functions[zle]} )) && ZPLG_BACKUP_FUNCTIONS[zle]="${functions[zle]}" || unset "ZPLG_BACKUP_FUNCTIONS[zle]"
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
    # If it does exist, then it will also exist in ZPLG_BACKUP_FUNCTIONS

    # Defensive code, shouldn't be needed
    builtin unset "ZPLG_BACKUP_FUNCTIONS[autoload]" "ZPLG_BACKUP_FUNCTIONS[compdef]"  # 0, E.

    if [[ "$mode" != "compdef" ]]; then
        # 0. Used, but not in temporary restoration, which doesn't happen for autoload
        (( ${+functions[autoload]} )) && ZPLG_BACKUP_FUNCTIONS[autoload]="${functions[autoload]}"
        functions[autoload]='--zplg-shadow-autoload "$@";'
    fi

    # E. Always shadow compdef
    (( ${+functions[compdef]} )) && ZPLG_BACKUP_FUNCTIONS[compdef]="${functions[compdef]}"
    functions[compdef]='--zplg-shadow-compdef "$@";'

    # Light and compdef shadowing stops here. Dtrace and load go on
    [[ "$mode" = "light" || "$mode" = "compdef" ]] && return 0

    # Defensive code, shouldn't be needed. A, B, C, D
    builtin unset "ZPLG_BACKUP_FUNCTIONS[bindkey]" "ZPLG_BACKUP_FUNCTIONS[zstyle]" "ZPLG_BACKUP_FUNCTIONS[alias]" "ZPLG_BACKUP_FUNCTIONS[zle]"

    # A.
    (( ${+functions[bindkey]} )) && ZPLG_BACKUP_FUNCTIONS[bindkey]="${functions[bindkey]}"
    functions[bindkey]='--zplg-shadow-bindkey "$@";'

    # B.
    (( ${+functions[zstyle]} )) && ZPLG_BACKUP_FUNCTIONS[zstyle]="${functions[zstyle]}"
    functions[zstyle]='--zplg-shadow-zstyle "$@";'

    # C.
    (( ${+functions[alias]} )) && ZPLG_BACKUP_FUNCTIONS[alias]="${functions[alias]}"
    functions[alias]='--zplg-shadow-alias "$@";'

    # D.
    (( ${+functions[zle]} )) && ZPLG_BACKUP_FUNCTIONS[zle]="${functions[zle]}"
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
    (( ${+ZPLG_BACKUP_FUNCTIONS[autoload]} )) && functions[autoload]="${ZPLG_BACKUP_FUNCTIONS[autoload]}" || unfunction "autoload"
    fi

    # E. Restore original compdef if it existed
    (( ${+ZPLG_BACKUP_FUNCTIONS[compdef]} )) && functions[compdef]="${ZPLG_BACKUP_FUNCTIONS[compdef]}" || unfunction "compdef"

    # Light and comdef shadowing stops here
    [[ "$mode" = "light" || "$mode" = "compdef" ]] && return 0

    # Unfunction shadowing functions

    # A.
    (( ${+ZPLG_BACKUP_FUNCTIONS[bindkey]} )) && functions[bindkey]="${ZPLG_BACKUP_FUNCTIONS[bindkey]}" || unfunction "bindkey"
    # B.
    (( ${+ZPLG_BACKUP_FUNCTIONS[zstyle]} )) && functions[zstyle]="${ZPLG_BACKUP_FUNCTIONS[zstyle]}" || unfunction "zstyle"
    # C.
    (( ${+ZPLG_BACKUP_FUNCTIONS[alias]} )) && functions[alias]="${ZPLG_BACKUP_FUNCTIONS[alias]}" || unfunction "alias"
    # D.
    (( ${+ZPLG_BACKUP_FUNCTIONS[zle]} )) && functions[zle]="${ZPLG_BACKUP_FUNCTIONS[zle]}" || unfunction "zle"

    return 0
} # }}}
# FUNCTION: pmodload {{{
# Compatibility with Prezto. Calls can be recursive.
pmodload() {
    while (( $# )); do
        [[ -z "${ZPLG_SNIPPETS[PZT::modules/$1${ZPLG_ICE[svn]-/init.zsh}]}" ]] && -zplg-load-snippet PZT::modules/"$1${ZPLG_ICE[svn]-/init.zsh}"
        shift
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
    local bIFS="$IFS"; IFS=" "

    [[ "$2" = "begin" ]] && ZPLG_OPTIONS_BEFORE[$1]="${(kv)options[@]}" || ZPLG_OPTIONS_AFTER[$1]="${(kv)options[@]}"

    IFS="$bIFS"
    ZPLG_OPTIONS[$1]=""
} # }}}
# FUNCTION: -zplg-diff-env {{{
# Implements detection of change in PATH and FPATH.
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
-zplg-diff-env() {
    typeset -a tmp
    local bIFS="$IFS"; IFS=" "

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

    IFS="$bIFS"
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

    [[ "$2" = "begin" ]] && ZPLG_PARAMETERS_BEFORE[$1]="${(j: :)${(qkv)parameters[@]}}" || ZPLG_PARAMETERS_AFTER[$1]="${(j: :)${(qkv)parameters[@]}}"

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
        # But user name is empty?
        [[ -z "$1" ]] && 1="_local"

        reply=( "$1" "$2" )
        return 0
    fi

    # Is it absolute path?
    if [[ "${1[1]}" = "/" ]]; then
        reply=( "%" "$1" )
        return 0
    fi

    # Is it absolute path in zplugin format?
    if [[ "${1[1]}" = "%" ]]; then
        reply=( "%" "${${${1/\%HOME/$HOME}/\%\//}#%}" )
        [[ "${${reply[2]}[1]}" != "/" ]] && reply[2]="/${reply[2]}"
        return 0
    fi

    # Rest is for single component given
    # It doesn't touch $2

    local user="${1%%/*}" plugin="${1#*/}"
    if [[ "$user" = "$plugin" ]]; then
        # Is it really the same plugin and user name?
        if [[ "$user/$plugin" = "$1" ]]; then
            reply=( "$user" "$plugin" )
            return 0
        fi

        user="${1%%---*}"
        plugin="${1#*---}"
    fi

    if [[ "$user" = "$plugin" ]]; then
        # Is it really the same plugin and user name?
        if [[ "${user}---${plugin}" = "$1" ]]; then
            reply=( "$user" "$plugin" )
            return 0
        fi
        user="_local"
    fi

    if [[ -z "$user" ]]; then
        user="_local"
    fi

    if [[ -z "$plugin" ]]; then
        plugin="_unknown"
    fi

    reply=( "$user" "$plugin" )
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
            $pdir_path/*.plugin.zsh(N) $pdir_path/*.zsh(N) $pdir_path/*.sh(N)
            $pdir_path/*.zsh-theme(N) $pdir_path/.zshrc(N)
        )
    fi
} # }}}
# FUNCTION: -zplg-register-plugin {{{
-zplg-register-plugin() {
    local uspl2="$1" mode="$2"
    integer ret=0

    if [[ -z "${ZPLG_REGISTERED_PLUGINS[(r)$uspl2]}" ]]; then
        ZPLG_REGISTERED_PLUGINS+=( "$uspl2" )
    else
        # Allow overwrite-load, however warn about it
        print "Warning: plugin \`$uspl2' already registered, will overwrite-load"
        ret=1
    fi

    # Full or light load?
    [[ "$mode" = "light" ]] && ZPLG_REGISTERED_STATES[$uspl2]="1" || ZPLG_REGISTERED_STATES[$uspl2]="2"

    ZPLG_REPORTS[$uspl2]=""
    ZPLG_FUNCTIONS_BEFORE[$uspl2]=""
    ZPLG_FUNCTIONS_AFTER[$uspl2]=""
    ZPLG_FUNCTIONS[$uspl2]=""
    ZPLG_ZSTYLES[$uspl2]=""
    ZPLG_BINDKEYS[$uspl2]=""
    ZPLG_ALIASES[$uspl2]=""
    ZPLG_WIDGETS_SAVED[$uspl2]=""
    ZPLG_WIDGETS_DELETE[$uspl2]=""
    ZPLG_OPTIONS[$uspl2]=""
    ZPLG_PATH[$uspl2]=""
    ZPLG_FPATH[$uspl2]=""

    return $ret
} # }}}
# FUNCTION: -zplg-unregister-plugin {{{
-zplg-unregister-plugin() {
    -zplg-any-to-user-plugin "$1" "$2"
    local uspl2="${reply[-2]}/${reply[-1]}"

    # If not found, the index will be length+1
    ZPLG_REGISTERED_PLUGINS[${ZPLG_REGISTERED_PLUGINS[(i)$uspl2]}]=()
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
    }
    [[ ! -d "${ZPLGM[PLUGINS_DIR]}" ]] && {
        command mkdir "${ZPLGM[PLUGINS_DIR]}"
        # For compaudit
        command chmod go-w "${ZPLGM[PLUGINS_DIR]}"

        # Prepare mock-like plugin for Zplugin itself
        command mkdir "${ZPLGM[PLUGINS_DIR]}/_local---zplugin"
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
    }
} # }}}
# FUNCTION: -zplg-load {{{
# Implements the exposed-to-user action of loading a plugin.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin name, if the third format is used
-zplg-load () {
    typeset -F 3 SECONDS=0
    local mode="$3"
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-pack-ice "$user" "$plugin"
    -zplg-register-plugin "$user/$plugin" "$mode"
    if [[ "$user" != "%" && ! -d "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}" ]]; then
        (( ${+functions[-zplg-setup-plugin-dir]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
        if ! -zplg-setup-plugin-dir "$user" "$plugin"; then
            -zplg-unregister-plugin "$user" "$plugin"
            return
        fi
    fi

    -zplg-load-plugin "$user" "$plugin" "$mode"
    ZPLGM[TIME_INDEX]=$(( ${ZPLGM[TIME_INDEX]:-0} + 1 ))
    ZPLGM[TIME_${ZPLGM[TIME_INDEX]}_${user}---${plugin}]=$SECONDS
} # }}}
# FUNCTION: -zplg-load-snippet {{{
# Implements the exposed-to-user action of loading a snippet.
#
# $1 - url (can be local, absolute path)
# $2 - "--command" if that option given
# $3 - "--force" if that option given
# $4 - "-u" if invoked by Zplugin to only update snippet
-zplg-load-snippet() {
    typeset -F 3 SECONDS=0
    local -a opts
    zparseopts -E -D -a opts f -command u || { echo "Incorrect options (accepted ones: -f, --command)"; return 1; }
    local url="$1"

    # Remove leading whitespace
    url="${url#"${url%%[! $'\t']*}"}"

    local filename filename0 local_dir save_url="$url"
    -zplg-pack-ice "$url" ""

    # Prepare SICE
    local -a tmp
    tmp=( "${(Q@)${(z@)ZPLG_SICE[$save_url/]}}" )
    (( ${#tmp} > 1 && ${#tmp} % 2 == 0 )) && ZPLG_ICE+=( "${tmp[@]}" )
    tmp=( 1 )

    # Oh-My-Zsh, Prezto and manual shorthands
    (( ${+ZPLG_ICE[svn]} )) && url[1,5]="${ZPLG_1MAP[${url[1,5]}]:-$url[1,5]}" || url[1,5]="${ZPLG_2MAP[${url[1,5]}]:-$url[1,5]}"

    filename="${${url%%\?*}:t}"
    filename0="${${${url%%\?*}:h}:t}"
    local_dir="${url:h}"

    # Check if it's URL
    [[ "$url" = http://* || "$url" = https://* || "$url" = ftp://* || "$url" = ftps://* || "$url" = scp://* ]] && {
        local_dir="${local_dir/:\/\//--}"
    }

    # Construct a local directory name from what's in url
    local_dir="${${${${local_dir//\//--S--}//=/--EQ--}//\?/--QM--}//\&/--AMP--}"
    local_dir="${ZPLGM[SNIPPETS_DIR]}/${local_dir%${ZPLG_ICE[svn]---S--$filename0}}${ZPLG_ICE[svn]-/$filename0}"

    ZPLG_SNIPPETS[$save_url]="$filename <${${ZPLG_ICE[svn]+1}:-0}>"

    # Download or copy the file
    if [[ -n "${opts[(r)-f]}" || ! -e "$local_dir/$filename" ]]; then
        (( ${+functions[-zplg-download-snippet]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
        -zplg-download-snippet "$save_url" "$url" "$local_dir" "$filename0" "$filename" "${opts[(r)-u]}" || tmp=( 0 )
    fi

    # Updating – no sourcing or setup
    [[ -n "${opts[(r)-u]}" ]] && return 0

    local -a list
    if [[ -z "${opts[(r)--command]}" && "${ZPLG_ICE[as]}" != "command" ]]; then
        # Source the file with compdef shadowing
        if [[ "${ZPLGM[SHADOWING]}" = "inactive" ]]; then
            # Shadowing code is inlined from -zplg-shadow-on
            (( ${+functions[compdef]} )) && ZPLG_BACKUP_FUNCTIONS[compdef]="${functions[compdef]}" || builtin unset "ZPLG_BACKUP_FUNCTIONS[compdef]"
            functions[compdef]='--zplg-shadow-compdef "$@";'
            ZPLGM[SHADOWING]="1"
        else
            (( ++ ZPLGM[SHADOWING] ))
        fi

        # Add to fpath
        [[ -d "$local_dir/$filename/functions" ]] && {
            [[ -z "${fpath[(r)$local_dir/$filename/functions]}" ]] && fpath+=( "$local_dir/$filename/functions" )
        }

        # Source
        if (( ${+ZPLG_ICE[svn]} == 0 )); then
            (( tmp[1] )) && list=( "$local_dir/$filename" )
            (( ${+ZPLG_ICE[pick]} )) && list=( $local_dir/${~ZPLG_ICE[pick]}(N) )
        else
            if (( ${+ZPLG_ICE[pick]} )); then
                list=( $local_dir/$filename/${~ZPLG_ICE[pick]}(N) )
            else
                list=( $local_dir/$filename/*.plugin.zsh(N) $local_dir/$filename/init.zsh(N)
                       $local_dir/$filename/*.zsh-theme(N) )
            fi
        fi

        [[ -f "${list[1]}" ]] && { builtin source "${list[1]}"; ((1)); } || echo "Snippet not loaded ($save_url)"

        (( -- ZPLGM[SHADOWING] == 0 )) && { ZPLGM[SHADOWING]="inactive"; (( ${+ZPLG_BACKUP_FUNCTIONS[compdef]} )) && functions[compdef]="${ZPLG_BACKUP_FUNCTIONS[compdef]}" || unfunction "compdef"; }
    else
        # Subversion - directory and multiple files possible
        if (( ${+ZPLG_ICE[svn]} )); then
            if (( ${+ZPLG_ICE[pick]} )); then
                list=( $local_dir/$filename/${~ZPLG_ICE[pick]}(N) )
                [[ -n "${list[1]}" ]] && local xpath="${list[1]:h}" xfilepath="${list[1]}"
            else
                local xpath="$local_dir/$filename"
            fi
        else
            local xpath="$local_dir" xfilepath="$local_dir/$filename"
            # This doesn't make sense, but users may come up with something
            (( ${+ZPLG_ICE[pick]} )) && { list=( $local_dir/${~ZPLG_ICE[pick]}(N) ); xfilepath="${list[1]}"; }
        fi
        [[ -n "$xpath" && -z "${path[(er)$xpath]}" ]] && path+=( "$xpath" )
        [[ -n "$xfilepath" && ! -x "$xfilepath" ]] && command chmod a+x "${list[@]:#$xfilepath}" "$xfilepath"
    fi

    ZPLGM[TIME_INDEX]=$(( ${ZPLGM[TIME_INDEX]:-0} + 1 ))
    ZPLGM[TIME_${ZPLGM[TIME_INDEX]}_${save_url}]=$SECONDS
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
    local uspl2="$1"
    shift
    local txt="$*"

    local keyword="${txt%% *}"
    if [[ "$keyword" = "Failed" || "$keyword" = "Warning:" ]]; then
        keyword="${ZPLGM[col-error]}$keyword${ZPLGM[col-rst]}"
    else
        keyword="${ZPLGM[col-keyword]}$keyword${ZPLGM[col-rst]}"
    fi

    # Don't report to any user/plugin if there is no plugin load in progress
    if [[ -n "$uspl2" ]]; then
        ZPLG_REPORTS[$uspl2]+="$keyword ${txt#* }"$'\n'
    fi

    # This is nasty, if debug is on, report everything
    # to special debug user
    [[ "${ZPLGM[DTRACE]}" = "1" ]] && ZPLG_REPORTS[_dtrace/_dtrace]+="$keyword ${txt#* }"$'\n'
} # }}}
# FUNCTION: -zplg-load-plugin {{{
# Lower-level function for loading a plugin.
#
# $1 - user
# $2 - plugin
# $3 - mode (light or load)
-zplg-load-plugin() {
    local user="$1" plugin="$2" mode="$3"
    ZPLGM[CUR_USR]="$user" ZPLG_CUR_PLUGIN="$plugin"
    ZPLGM[CUR_USPL]="${user}---${plugin}" ZPLGM[CUR_USPL2]="${user}/${plugin}"

    if [[ "$user" = "%" ]]; then
        local pbase="${${${${plugin:t}%.plugin.zsh}%.zsh}%.git}"
        local pdir_path="$plugin"
    else
        local pbase="${${${plugin%.plugin.zsh}%.zsh}%.git}"
        local pdir_path="${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"
    fi

    if [[ "${ZPLG_ICE[as]}" = "command" ]]; then
        reply=()
        if (( ${+ZPLG_ICE[pick]} )); then
            reply=( $pdir_path/${~ZPLG_ICE[pick]}(N) )
            [[ -n "${reply[1]}" ]] && pdir_path="${reply[1]:h}"
        fi
        [[ -z "${path[(er)$pdir_path]}" ]] && path+=( "$pdir_path" )
        [[ -n "${reply[1]}" && ! -x "${reply[1]}" ]] && command chmod a+x ${reply[@]}
        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "$ZPLGM[col-info2]$pdir_path$ZPLGM[col-rst] added to \$PATH"
    else
        if (( ${+ZPLG_ICE[pick]} )); then
            reply=( $pdir_path/${~ZPLG_ICE[pick]}(N) )
        elif [[ -e "$pdir_path/${pbase}.plugin.zsh" ]]; then
            reply=( "$pdir_path/${pbase}.plugin.zsh" )
        else
            # The common file to source isn't there, so:
            -zplg-find-other-matches "$pdir_path" "$pbase"
        fi

        [[ "${#reply}" -eq "0" ]] && return 1

        # Get first one
        local fname="${${${(@Oa)reply}[-1]}#$pdir_path/}"

        -zplg-add-report "${ZPLGM[CUR_USPL2]}" "Source $fname${mode:+ $ZPLGM[col-info2]($mode load)$ZPLGM[col-rst]}"

        # Light and compdef mode doesn't do diffs and shadowing
        if [[ "$mode" != "light" ]]; then
            -zplg-diff-functions "${ZPLGM[CUR_USPL2]}" begin
            -zplg-diff-options "${ZPLGM[CUR_USPL2]}" begin
            -zplg-diff-env "${ZPLGM[CUR_USPL2]}" begin
            -zplg-diff-parameter "${ZPLGM[CUR_USPL2]}" begin
        fi

        -zplg-shadow-on "${mode:-load}"

        # We need some state, but user wants his for his plugins
        (( ${+ZPLG_ICE[blockf]} )) && { local -a fpath_bkp; fpath_bkp=( "${fpath[@]}" ); }
        builtin setopt noaliases
        builtin source "$pdir_path/$fname"
        builtin unsetopt noaliases
        (( ${+ZPLG_ICE[blockf]} )) && { fpath=( "${fpath_bkp[@]}" ); }

        -zplg-shadow-off "${mode:-load}"

        if [[ "$mode" != "light" ]]; then
            -zplg-diff-parameter "${ZPLGM[CUR_USPL2]}" end
            -zplg-diff-env "${ZPLGM[CUR_USPL2]}" end
            -zplg-diff-options "${ZPLGM[CUR_USPL2]}" end
            -zplg-diff-functions "${ZPLGM[CUR_USPL2]}" end
        fi
    fi

    (( ${+ZPLG_ICE[atload]} )) && { local oldcd="$PWD"; cd "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"; eval "${ZPLG_ICE[atload]}"; cd "$oldcd"; }

    # Mark no load is in progress
    ZPLGM[CUR_USR]="" ZPLG_CUR_PLUGIN="" ZPLGM[CUR_USPL]="" ZPLGM[CUR_USPL2]=""
    return 0
} # }}}

#
# Dtrace
#

# FUNCTION: -zplg-debug-start {{{
# Starts Dtrace, i.e. session tracking for changes in Zsh state.
-zplg-debug-start() {
    if [[ "${ZPLGM[DTRACE]}" = "1" ]]; then
        print "${ZPLGM[col-error]}Dtrace is already active, stop it first with \`dstop'$reset_color"
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
    setopt localoptions extendedglob
    local bit
    for bit; do
        [[ "$bit" = (#b)(from|proto|depth|blockf|svn|pick|as|atload|atpull|atclone|if)(*) ]] && ZPLG_ICE[${match[1]}]="${match[2]}"
    done
} # }}}
# FUNCTION: -zplg-pack-ice {{{
# Remembers long-live ICE specs, assigns them to concrete plugin.
# Ice spec is in general forgotten for second-next command (that's
# why it's called "ice" - it melts), however some ice modifiers can
# glue to plugin mentioned in the next command.
-zplg-pack-ice() {
    (( ${+ZPLG_ICE[atpull]} )) && ZPLG_SICE[$1/$2]+="atpull ${(q)ZPLG_ICE[atpull]} "
    (( ${+ZPLG_ICE[svn]} )) && ZPLG_SICE[$1/$2]+="svn ${(q)ZPLG_ICE[svn]} "
} # }}}

#
# Main function with subcommands
#

# FUNCTION: zplugin {{{
# Main function directly exposed to user, obtains subcommand
# and its arguments, has completion.
zplugin() {
    # All functions from now on will not change these values
    # globally. Functions that don't do "source" of plugin
    # will be able to setopt localoptions extendedglob
    local -a match mbegin mend
    local MATCH; integer MBEGIN MEND

    -zplg-prepare-home

    # Simulate existence of _local/zplugin module
    # This will allow to cuninstall of its completion
    ZPLG_REGISTERED_PLUGINS+=( "_local/zplugin" )
    ZPLG_REGISTERED_PLUGINS=( "${(u)ZPLG_REGISTERED_PLUGINS[@]}" )
    # _zplugin module is loaded lightly
    ZPLG_REGISTERED_STATES[_local/zplugin]="1"

    case "$1" in
       (load)
           (( ${+ZPLG_ICE[if]} )) && { eval "${ZPLG_ICE[if]}" || { ZPLG_ICE=(); return 0; }; }
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
           else
               # Load plugin given in uspl2 or "user plugin" format
               # Possibly clone from github, and install completions
               -zplg-load "$2" "$3" ""
           fi
           ;;
       (light)
           (( ${+ZPLG_ICE[if]} )) && { eval "${ZPLG_ICE[if]}" || { ZPLG_ICE=(); return 0; }; }
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
           else
               # This is light load, without tracking, only with
               # clean FPATH (autoload is still being shadowed)
               -zplg-load "$2" "$3" "light"
           fi
           ;;
       (snippet)
           (( ${+ZPLG_ICE[if]} )) && { eval "${ZPLG_ICE[if]}" || { ZPLG_ICE=(); return 0; }; }
           -zplg-load-snippet "$2" "$3" "$4" "$5" "$6"
           ;;
       (ice)
           -zplg-ice "${@[2,-1]}"
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
       (*)
           (( ${+functions[-zplg-format-functions]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-autoload.zsh"
           case "$1" in
               (zstatus)
                   -zplg-show-zstatus
                   ;;
               (times)
                   -zplg-show-times
                   ;;
               (self-update)
                   -zplg-self-update
                   ;;
               (unload)
                   if [[ -z "$2" && -z "$3" ]]; then
                       print "Argument needed, try help"
                   else
                       # Unload given plugin. Cloned directory remains intact
                       # so as are completions
                       -zplg-unload "$2" "$3"
                   fi
                   ;;
               (update)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 2; }
                       -zplg-update-or-status-all "update"
                   else
                       -zplg-update-or-status "update" "$2" "$3"
                   fi
                   ;;
               (status)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 2; }
                       -zplg-update-or-status-all "status"
                   else
                       -zplg-update-or-status "status" "$2" "$3"
                   fi
                   ;;
               (report)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 3; }
                       -zplg-show-all-reports
                   else
                       -zplg-show-report "$2" "$3"
                   fi
                   ;;
               (loaded|list)
                   # Show list of loaded plugins
                   -zplg-show-registered-plugins "$2"
                   ;;
               (clist|completions)
                   # Show installed, enabled or disabled, completions
                   # Detect stray and improper ones
                   -zplg-show-completions
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
                           compinit
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
                           compinit
                       fi
                   fi
                   ;;
               (creinstall)
                   (( ${+functions[-zplg-install-completions]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                   # Installs completions for plugin. Enables them all. It's a
                   # reinstallation, thus every obstacle gets overwritten or removed
                   -zplg-install-completions "$2" "$3" "1"
                   print "Initializing completion (compinit)..."
                   builtin autoload -Uz compinit
                   compinit
                   ;;
               (cuninstall)
                   if [[ -z "$2" && -z "$3" ]]; then
                       print "Argument needed, try help"
                   else
                       (( ${+functions[-zplg-forget-completion]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
                       # Uninstalls completions for plugin
                       -zplg-uninstall-completions "$2" "$3"
                       print "Initializing completion (compinit)..."
                       builtin autoload -Uz compinit
                       compinit
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
                       [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 2; }
                       -zplg-compile-uncompile-all "1"
                   else
                       -zplg-compile-plugin "$2" "$3"
                   fi
                   ;;
               (uncompile)
                   if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
                       [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 2; }
                       -zplg-compile-uncompile-all "0"
                   else
                       -zplg-uncompile-plugin "$2" "$3"
                   fi
                   ;;
               (compiled)
                   -zplg-compiled
                   ;;
               (cdlist)
                   -zplg-list-compdef-replay
                   ;;
               (cd)
                   -zplg-cd "$2" "$3"
                   ;;
               (edit)
                   -zplg-edit "$2" "$3"
                   ;;
               (glance)
                   -zplg-glance "$2" "$3"
                   ;;
               (changes)
                   -zplg-changes "$2" "$3"
                   ;;
               (recently)
                   shift
                   -zplg-recently "$@"
                   ;;
               (create)
                   -zplg-create "$2" "$3"
                   ;;
               (stress)
                   -zplg-stress "$2" "$3"
                   ;;
               (-h|--help|help|"")
                   -zplg-help
                   ;;
               (*)
                   print "Unknown command \`$1' (use \`help' to get usage information)"
                   ;;
            esac
            ;;
    esac

    [[ "$1" != "ice" ]] && ZPLG_ICE=()
} # }}}

#
# Source-executed code
#

# code {{{
builtin unsetopt noaliases
builtin alias zpl=zplugin zplg=zplugin

-zplg-prepare-home

# Add completions directory to fpath
fpath=( "${ZPLGM[COMPLETIONS_DIR]}" "${fpath[@]}" )

# Colorize completions for commands unload, report, creinstall, cuninstall
zstyle ':completion:*:zplugin:argument-rest:plugins' list-colors '=(#b)(*)/(*)==1;35=1;33'
zstyle ':completion:*:zplugin:argument-rest:plugins' matcher 'r:|=** l:|=*'
# }}}
