# -*- mode: shell-script -*-
# vim:ft=zsh

#
# Main state variables
#

typeset -gaH ZPLG_REGISTERED_PLUGINS
# Maps plugins to 0, 1 or 2 - not loaded, light loaded, fully loaded
typeset -gAH ZPLG_REGISTERED_STATES
# Snippets loaded, url -> file name
typeset -gAH ZPLG_SNIPPETS
typeset -gAH ZPLG_REPORTS
typeset -gAH ZPLG_MAIN

#
# Common needed values
#

# User can override ZPLG_DIR. Misleading? Reset
[[ ! -e "$ZPLG_DIR"/zplugin.zsh ]] && typeset -gH ZPLG_DIR=""

# Problematic function_argzero
[[ ! -o "functionargzero" ]] && 0="${(%):-%N}" # this gives immunity to functionargzero being unset

[[ -z "$ZPLG_DIR" ]] && typeset -gH ZPLG_DIR="${0:h}"

# Make ZPLG_DIR path absolute
if [[ "$ZPLG_DIR" != /* ]]; then
    if [[ "$ZPLG_DIR" = "." ]]; then
        ZPLG_DIR="$PWD"
    else
        ZPLG_DIR="$PWD/$ZPLG_DIR"
    fi
fi

# Final test of ZPLG_DIR
if [[ ! -e "$ZPLG_DIR"/zplugin.zsh ]]; then
    print "Could not establish ZPLG_DIR variable. Set it to where Zplugin's git repository is."
    return 1
fi

# User can override ZPLG_HOME
if [[ -z "$ZPLG_HOME" ]]; then
    # Ignore ZDOTDIR if user manually put Zplugin to $HOME
    if [[ -d "$HOME/.zplugin" ]]; then
        typeset -gH ZPLG_HOME="$HOME/.zplugin"
    else
        typeset -gH ZPLG_HOME="${ZDOTDIR:-$HOME}/.zplugin"
    fi
fi

typeset -gH ZPLG_PLUGINS_DIR="$ZPLG_HOME/plugins"
# Can be customized, e.g. for multi-user environment
typeset -gH ZPLG_COMPLETIONS_DIR
: ${ZPLG_COMPLETIONS_DIR:=$ZPLG_HOME/completions}
typeset -gH ZPLG_SNIPPETS_DIR="$ZPLG_HOME/snippets"
typeset -gH ZPLG_EXTENDED_GLOB
typeset -gAH ZPLG_BACKUP_FUNCTIONS
typeset -gAH ZPLG_BACKUP_ALIASES
typeset -ga ZPLG_STRESS_TEST_OPTIONS
ZPLG_STRESS_TEST_OPTIONS=( "NO_SHORT_LOOPS" "IGNORE_BRACES" "IGNORE_CLOSE_BRACES" "SH_GLOB" "CSH_JUNKIE_QUOTES" "NO_MULTI_FUNC_DEF" )
typeset -gH ZPLG_NEW_AUTOLOAD=0

builtin autoload -Uz is-at-least
is-at-least 5.1 && ZPLG_NEW_AUTOLOAD=1

#
# Shadowing variables {{{
# Can be used by any shadowing function to recognize current context
#

ZPLG_MAIN[SHADOWING]="inactive"
ZPLG_MAIN[DTRACE]="0"
typeset -gH ZPLG_CUR_PLUGIN=""
# }}}

#
# Function diffing {{{
#

# Used to hold declared functions existing before loading a plugin
typeset -gAH ZPLG_FUNCTIONS_BEFORE
# Functions existing after loading a plugin. Reporting will do a diff
typeset -gAH ZPLG_FUNCTIONS_AFTER
# Functions computed to be associated with plugin
typeset -gAH ZPLG_FUNCTIONS
# Was the function diff already ran?
typeset -gAH ZPLG_FUNCTIONS_DIFF_RAN

#}}}

#
# Option diffing {{{
#

# Concatenated state of options before loading a plugin
typeset -gAH ZPLG_OPTIONS_BEFORE

# Concatenated state of options after loading a plugin
typeset -gAH ZPLG_OPTIONS_AFTER

# Concatenated options that changed, hold as they were before plugin load
typeset -gAH ZPLG_OPTIONS

# Was the option diff already ran?
typeset -gAH ZPLG_OPTIONS_DIFF_RAN

# }}}

#
# Environment diffing {{{
#

# Concatenated state of PATH before loading a plugin
typeset -gAH ZPLG_PATH_BEFORE

# Concatenated state of PATH after loading a plugin
typeset -gAH ZPLG_PATH_AFTER

# Concatenated new elements of PATH (after diff)
typeset -gAH ZPLG_PATH

# Concatenated state of FPATH before loading a plugin
typeset -gAH ZPLG_FPATH_BEFORE

# Concatenated state of FPATH after loading a plugin
typeset -gAH ZPLG_FPATH_AFTER

# Concatenated new elements of FPATH (after diff)
typeset -gAH ZPLG_FPATH

# Was the environment diff already ran?
typeset -gHA ZPLG_ENV_DIFF_RAN
# }}}

#
# Parameter diffing {{{
#

# Concatenated state of PARAMETERS before loading a plugin
typeset -gAH ZPLG_PARAMETERS_BEFORE

# Concatenated state of PARAMETERS after loading a plugin
typeset -gAH ZPLG_PARAMETERS_AFTER

# Concatenated *changed* previous elements of $parameters (before)
typeset -gAH ZPLG_PARAMETERS_PRE

# Concatenated *changed* current elements of $parameters (after)
typeset -gAH ZPLG_PARAMETERS_POST

# Was the environment diff already ran?
typeset -gHA ZPLG_PARAMETERS_DIFF_RAN

# }}}

#
# Zstyle, bindkey, alias, zle remembering {{{
#

# Holds concatenated Zstyles declared by each plugin
# Concatenated after quoting, so (z)-splittable
typeset -gAH ZPLG_ZSTYLES

# Holds concatenated bindkeys declared by each plugin
typeset -gAH ZPLG_BINDKEYS
# Holds counter used for main keymap saves
typeset -giH ZPLG_BINDKEY_MAIN_IDX

# Holds concatenated aliases declared by each plugin
typeset -gAH ZPLG_ALIASES

# Holds concatenated pairs "widget_name save_name" for use with zle -A
typeset -gAH ZPLG_WIDGETS_SAVED

# Holds concatenated names of widgets that should be deleted
typeset -gAH ZPLG_WIDGETS_DELETE

# Holds compdef calls (i.e. "${(j: :)${(q)@}}" of each call)
typeset -gaH ZPLG_COMPDEF_REPLAY
# }}}

#
# Init {{{
#

zmodload zsh/zutil || return 1
zmodload zsh/parameter || return 1
zmodload zsh/terminfo 2>/dev/null
zmodload zsh/termcap 2>/dev/null

if [[ ( -n "${terminfo[colors]}" || -n "${termcap[Co]}" ) && -z "${functions[colors]}" ]]; then
    [[ -z "${fg_bold[green]}" ]] && {
        builtin autoload -Uz colors
        colors
    }
fi

typeset -gAH ZPLG_COL
ZPLG_COL=(
    "title" ""
    "pname" "${fg_bold[yellow]}"
    "uname" "${fg_bold[magenta]}"
    "keyword" "${fg_bold[green]}"
    "error" "${fg_bold[red]}"
    "p" "${fg_bold[blue]}"
    "bar" "${fg_bold[magenta]}"
    "info" "${fg_bold[green]}"
    "info2" "${fg[green]}"
    "uninst" "${fg_bold[blue]}"
    "success" "${fg_bold[green]}"
    "failure" "${fg_bold[red]}"
    "rst" "$reset_color"
)

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
# }}}

#
# The one noaliases setopt that will protect all
# Zplugin's functions from disruption via aliases,
# including global ones
#
builtin setopt noaliases

#
# Shadowing-related functions (names of substitute functions start with --) {{{
# Must be resistant to various game-changing options like KSH_ARRAYS
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
}

--zplg-shadow-autoload () {
    local -a opts
    local func

    zparseopts -a opts -D ${(s::):-TUXkmtzw}

    # TODO: +X
    if (( ${+opts[(r)-X]} ))
    then
        -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Failed autoload $opts $*"
        print -u2 "builtin autoload required for $opts"
        return 1 # Testable
    fi
    if (( ${+opts[(r)-w]} ))
    then
        -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "-w-Autoload $opts $*"
        builtin autoload $opts "$@"
        return # Testable
    fi

    # Report ZPLUGIN's "native" autoloads
    local i
    for i in "$@"; do
        local msg="Autoload $i"
        [[ -n "$opts" ]] && msg+=" with options ${opts[@]}"
        -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "$msg"
    done

    # Do ZPLUGIN's "native" autoloads
    local PLUGIN_DIR="$ZPLG_PLUGINS_DIR/${ZPLG_MAIN[CUR_USPL]}"
    for func
    do
        # Real autoload doesn't touch function if it already exists
        # Author of the idea of FPATH-clean autoloading: Bart Schaefer
        if (( ${+functions[$func]} != 1 )); then
            builtin setopt noaliases
            if [[ "$ZPLG_NEW_AUTOLOAD" = "1" ]]; then
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
}

--zplg-shadow-bindkey() {
    -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Bindkey $*"

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
        [[ -n "${ZPLG_MAIN[CUR_USPL2]}" ]] && ZPLG_BINDKEYS[${ZPLG_MAIN[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]] && ZPLG_BINDKEYS[_dtrace/_dtrace]+="$quoted "
    else
        # bindkey -A newkeymap main?
        # Negative indices for KSH_ARRAYS immunity
        if [[ "${#opts[@]}" -eq "1" && "${+opts[(r)-A]}" = "1" && "${#pos[@]}" = "3" && "${pos[-1]}" = "main" && "${pos[-2]}" != "-A" ]]; then
            # Save a copy of main keymap
            (( ZPLG_BINDKEY_MAIN_IDX ++ ))
            local pname="${ZPLG_CUR_PLUGIN:-_dtrace}"
            local name="${(q)pname}-main-$ZPLG_BINDKEY_MAIN_IDX"
            builtin bindkey -N "${name}" main

            # Remember occurence of main keymap substitution, to revert on unload
            local keys="_" widget="_" optA="-A" mapname="${name}" optR="_"
            local quoted="${(q)keys} ${(q)widget} ${(q)optA} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
            [[ -n "${ZPLG_MAIN[CUR_USPL2]}" ]] && ZPLG_BINDKEYS[${ZPLG_MAIN[CUR_USPL2]}]+="$quoted "
            [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]] && ZPLG_BINDKEYS[_dtrace/_dtrace]+="$quoted "

            -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Warning: keymap \`main' copied to \`${name}' because of \`${pos[-2]}' substitution"
        # bindkey -N newkeymap [other]
        elif [[ "${#opts[@]}" -eq 1 && "${+opts[(r)-N]}" = "1" ]]; then
            local Nopt="-N"
            local Narg="${optsA[-N]}"

            local keys="_" widget="_" optN="-N" mapname="${Narg}" optR="_"
            local quoted="${(q)keys} ${(q)widget} ${(q)optN} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here)
            [[ -n "${ZPLG_MAIN[CUR_USPL2]}" ]] && ZPLG_BINDKEYS[${ZPLG_MAIN[CUR_USPL2]}]+="$quoted "
            [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]] && ZPLG_BINDKEYS[_dtrace/_dtrace]+="$quoted "
        else
            -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Warning: last bindkey used non-typical options: ${opts[*]}"
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
}

--zplg-shadow-zstyle() {
    -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Zstyle $*"

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
        [[ -n "${ZPLG_MAIN[CUR_USPL2]}" ]] && ZPLG_ZSTYLES[${ZPLG_MAIN[CUR_USPL2]}]+="$ps "
        # Remember for dtrace
        [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]] && ZPLG_ZSTYLES[_dtrace/_dtrace]+="$ps "
    else
        if [[ ! "${#opts[@]}" = "1" && ( "${+opts[(r)-s]}" = "1" || "${+opts[(r)-b]}" = "1" || "${+opts[(r)-a]}" = "1" ||
                                      "${+opts[(r)-t]}" = "1" || "${+opts[(r)-T]}" = "1" || "${+opts[(r)-m]}" = "1" ) ]]
        then
            -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Warning: last zstyle used non-typical options: ${opts[*]}"
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
}

--zplg-shadow-alias() {
    -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Alias $*"

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
        (( ${+aliases[$aname]} )) && -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Warning: redefining alias \`${aname}', previous value: ${avalue}"

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
        [[ -n "${ZPLG_MAIN[CUR_USPL2]}" ]] && ZPLG_ALIASES[${ZPLG_MAIN[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]] && ZPLG_ALIASES[_dtrace/_dtrace]+="$quoted "
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
}

--zplg-shadow-zle() {
    -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Zle $*"

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
                [[ -n "${ZPLG_MAIN[CUR_USPL2]}" ]] && ZPLG_WIDGETS_DELETE[${ZPLG_MAIN[CUR_USPL2]}]+="$quoted "
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
                [[ -n "${ZPLG_MAIN[CUR_USPL2]}" ]] && ZPLG_WIDGETS_SAVED[${ZPLG_MAIN[CUR_USPL2]}]+="$quoted "
                # Remember for dtrace
                [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]] && ZPLG_WIDGETS_SAVED[_dtrace/_dtrace]+="$quoted "
             # These will be deleted
             else
                 -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Warning: unknown widget replaced/taken via zle -N: \`$2', it is set to be deleted"
                 local quoted="$2"
                 quoted="${(q)quoted}"
                 # Remember only when load is in progress (it can be dstart that leads execution here)
                 [[ -n "${ZPLG_MAIN[CUR_USPL2]}" ]] && ZPLG_WIDGETS_DELETE[${ZPLG_MAIN[CUR_USPL2]}]+="$quoted "
                 # Remember for dtrace
                 [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]] && ZPLG_WIDGETS_DELETE[_dtrace/_dtrace]+="$quoted "
             fi
    # Creation of new widgets. They will be removed on unload
    elif [[ "$1" = "-N" && "$#" = "2" ]]; then
        local quoted="$2"
        quoted="${(q)quoted}"
        # Remember only when load is in progress (it can be dstart that leads execution here)
        [[ -n "${ZPLG_MAIN[CUR_USPL2]}" ]] && ZPLG_WIDGETS_DELETE[${ZPLG_MAIN[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace
        [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]] && ZPLG_WIDGETS_DELETE[_dtrace/_dtrace]+="$quoted "
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
}

--zplg-shadow-compdef() {
    -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Saving \`compdef $*' for replay"
    ZPLG_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" )

    return 0 # testable
}

# Shadowing on completely for a given mode ("load", "light" or "compdef")
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
    [[ "${ZPLG_MAIN[SHADOWING]}" != "inactive" ]] && builtin return 0

    ZPLG_MAIN[SHADOWING]="$mode"

    # The point about backuping is: does the key exist in functions array
    # If it does exist, then it will also exist in ZPLG_BACKUP_FUNCTIONS

    # Defensive code, shouldn't be needed
    builtin unset "ZPLG_BACKUP_FUNCTIONS[autoload]" # 0.
    builtin unset "ZPLG_BACKUP_FUNCTIONS[compdef]"  # E.

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

    # Defensive code, shouldn't be needed
    builtin unset "ZPLG_BACKUP_FUNCTIONS[bindkey]"  # A.
    builtin unset "ZPLG_BACKUP_FUNCTIONS[zstyle]"   # B.
    builtin unset "ZPLG_BACKUP_FUNCTIONS[alias]"    # C.
    builtin unset "ZPLG_BACKUP_FUNCTIONS[zle]"      # D.

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
}

# Shadowing off completely for a given mode "load", "light" or "compdef"
-zplg-shadow-off() {
    builtin setopt localoptions noaliases
    local mode="$1"

    # Disable shadowing only once
    # Disable shadowing only the way it was enabled first
    [[ "${ZPLG_MAIN[SHADOWING]}" = "inactive" || "${ZPLG_MAIN[SHADOWING]}" != "$mode" ]] && return 0

    ZPLG_MAIN[SHADOWING]="inactive"

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
}

# }}}

#
# Function diff functions {{{
#

# Can remember current $functions twice, and compute the
# difference, storing it in ZPLG_FUNCTIONS, associated
# with given ($1) plugin
-zplg-diff-functions() {
    local uspl2="$1"
    local cmd="$2"

    case "$cmd" in
        begin)
            ZPLG_FUNCTIONS_BEFORE[$uspl2]="${(j: :)${(qk)functions[@]}}"
            ZPLG_FUNCTIONS[$uspl2]=""
            ZPLG_FUNCTIONS_DIFF_RAN[$uspl2]="0"
            ;;
        end)
            ZPLG_FUNCTIONS_AFTER[$uspl2]="${(j: :)${(qk)functions[@]}}"
            ZPLG_FUNCTIONS[$uspl2]=""
            ZPLG_FUNCTIONS_DIFF_RAN[$uspl2]="0"
            ;;
        diff)
            # Run diff once, `begin' or `end' is needed to be run again for a new diff
            [[ "${ZPLG_FUNCTIONS_DIFF_RAN[$uspl2]}" = "1" ]] && return 0
            ZPLG_FUNCTIONS_DIFF_RAN[$uspl2]="1"

            # Cannot run diff if *_BEFORE or *_AFTER variable is not set
            # Following is paranoid for *_BEFORE and *_AFTER being only spaces

            builtin setopt localoptions extendedglob
            [[ "${ZPLG_FUNCTIONS_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_FUNCTIONS_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1

            typeset -A func
            local i

            # This includes new functions. Quoting is kept (i.e. no i=${(Q)i})
            for i in "${(z)ZPLG_FUNCTIONS_AFTER[$uspl2]}"; do
                func[$i]=1
            done

            # Remove duplicated entries, i.e. existing before. Quoting is kept
            for i in "${(z)ZPLG_FUNCTIONS_BEFORE[$uspl2]}"; do
                # if would do unset, then: func[opp+a\[]: invalid parameter name
                func[$i]=0
            done

            # Store the functions, associating them with plugin ($uspl2)
            for i in "${(onk)func[@]}"; do
                [[ "${func[$i]}" = "1" ]] && ZPLG_FUNCTIONS[$uspl2]+="$i "
            done
            ;;
        *)
            return 1
    esac

    return 0
}
# }}}

#
# Option diff functions {{{
#

# Can remember current $options twice. After that can
# detect any change between the two saves. Changed
# options are appended as they were in first save to
# ZPLG_OPTIONS, all associated with given ($1) plugin
-zplg-diff-options() {
    local uspl2="$1"
    local cmd="$2"

    case "$cmd" in
        begin)
            local bIFS="$IFS"; IFS=" "
            ZPLG_OPTIONS_BEFORE[$uspl2]="${(kv)options[@]}"
            IFS="$bIFS"
            ZPLG_OPTIONS[$uspl2]=""
            ZPLG_OPTIONS_DIFF_RAN[$uspl2]="0"
            ;;
        end)
            local bIFS="$IFS"; IFS=" "
            ZPLG_OPTIONS_AFTER[$uspl2]="${(kv)options[@]}"
            IFS="$bIFS"
            ZPLG_OPTIONS[$uspl2]=""
            ZPLG_OPTIONS_DIFF_RAN[$uspl2]="0"
            ;;
        diff)
            # Run diff once, `begin' or `end' is needed to be run again for a new diff
            [[ "${ZPLG_OPTIONS_DIFF_RAN[$uspl2]}" = "1" ]] && return 0
            ZPLG_OPTIONS_DIFF_RAN[$uspl2]="1"

            # Cannot run diff if *_BEFORE or *_AFTER variable is not set
            # Following is paranoid for *_BEFORE and *_AFTER being only spaces
            builtin setopt localoptions extendedglob
            [[ "${ZPLG_OPTIONS_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_OPTIONS_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1

            typeset -A opts_before opts_after opts
            opts_before=( "${(z)ZPLG_OPTIONS_BEFORE[$uspl2]}" )
            opts_after=( "${(z)ZPLG_OPTIONS_AFTER[$uspl2]}" )
            opts=( )

            # Iterate through first array (keys the same
            # on both of them though) and test for a change
            local key
            for key in "${(k)opts_before[@]}"; do
                if [[ "${opts_before[$key]}" != "${opts_after[$key]}" ]]; then
                    opts[$key]="${opts_before[$key]}"
                fi
            done

            # Serialize for reporting
            local bIFS="$IFS"; IFS=" "
            ZPLG_OPTIONS[$uspl2]="${(kv)opts[@]}"
            IFS="$bIFS"
            ;;
        *)
            return 1
    esac

    return 0
}
# }}}

#
# Environment diff functions {{{
#

-zplg-diff-env() {
    local uspl2="$1"
    local cmd="$2"
    typeset -a tmp

    case "$cmd" in
        begin)
            local bIFS="$IFS"; IFS=" "
            tmp=( "${(q)path[@]}" )
            ZPLG_PATH_BEFORE[$uspl2]="${tmp[*]}"
            tmp=( "${(q)fpath[@]}" )
            ZPLG_FPATH_BEFORE[$uspl2]="${tmp[*]}"
            IFS="$bIFS"

            # Reset diffing
            ZPLG_PATH[$uspl2]=""
            ZPLG_FPATH[$uspl2]=""
            ZPLG_ENV_DIFF_RAN[$uspl2]="0"
            ;;
        end)
            local bIFS="$IFS"; IFS=" "
            tmp=( "${(q)path[@]}" )
            ZPLG_PATH_AFTER[$uspl2]="${tmp[*]}"
            tmp=( "${(q)fpath[@]}" )
            ZPLG_FPATH_AFTER[$uspl2]="${tmp[*]}"
            IFS="$bIFS"

            # Reset diffing
            ZPLG_PATH[$uspl2]=""
            ZPLG_FPATH[$uspl2]=""
            ZPLG_ENV_DIFF_RAN[$uspl2]="0"
            ;;
        diff)
            # Run diff once, `begin' or `end' is needed to be run again for a new diff
            [[ "${ZPLG_ENV_DIFF_RAN[$uspl2]}" = "1" ]] && return 0
            ZPLG_ENV_DIFF_RAN[$uspl2]="1"

            # Cannot run diff if *_BEFORE or *_AFTER variable is not set
            # Following is paranoid for *_BEFORE and *_AFTER being only spaces
            builtin setopt localoptions extendedglob
            [[ "${ZPLG_PATH_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_PATH_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1
            [[ "${ZPLG_FPATH_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_FPATH_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1

            typeset -A path_state fpath_state
            local i

            #
            # PATH processing
            #

            # This includes new path elements
            for i in "${(z)ZPLG_PATH_AFTER[$uspl2]}"; do
                path_state[$i]=1
            done

            # Remove duplicated entries, i.e. existing before
            for i in "${(z)ZPLG_PATH_BEFORE[$uspl2]}"; do
                unset "path_state[$i]"
            done

            # Store the path elements, associating them with plugin ($uspl2)
            for i in "${(onk)path_state[@]}"; do
                ZPLG_PATH[$uspl2]+="$i "
            done

            #
            # FPATH processing
            #

            # This includes new path elements
            for i in "${(z)ZPLG_FPATH_AFTER[$uspl2]}"; do
                fpath_state[$i]=1
            done

            # Remove duplicated entries, i.e. existing before
            for i in "${(z)ZPLG_FPATH_BEFORE[$uspl2]}"; do
                unset "fpath_state[$i]"
            done

            # Store the path elements, associating them with plugin ($uspl2)
            for i in "${(onk)fpath_state[@]}"; do
                ZPLG_FPATH[$uspl2]+="$i "
            done
            ;;
        *)
            return 1
    esac

    return 0
}
# }}}

#
# Parameter diff functions {{{
#

-zplg-diff-parameter() {
    local uspl2="$1"
    local cmd="$2"
    typeset -a tmp

    case "$cmd" in
        begin)
            ZPLG_PARAMETERS_BEFORE[$uspl2]="${(j: :)${(qkv)parameters[@]}}"

            # Reset diffing
            ZPLG_PARAMETERS_PRE[$uspl2]=""
            ZPLG_PARAMETERS_POST[$uspl2]=""
            ZPLG_PARAMETERS_DIFF_RAN[$uspl2]="0"
            ;;
        end)
            ZPLG_PARAMETERS_AFTER[$uspl2]="${(j: :)${(qkv)parameters[@]}}"

            # Reset diffing
            ZPLG_PARAMETERS_PRE[$uspl2]=""
            ZPLG_PARAMETERS_POST[$uspl2]=""
            ZPLG_PARAMETERS_DIFF_RAN[$uspl2]="0"
            ;;
        diff)
            # Run diff once, `begin' or `end' is needed to be run again for a new diff
            [[ "${ZPLG_PARAMETERS_DIFF_RAN[$uspl2]}" = "1" ]] && return 0
            ZPLG_PARAMETERS_DIFF_RAN[$uspl2]="1"

            # Cannot run diff if *_BEFORE or *_AFTER variable is not set
            # Following is paranoid for *_BEFORE and *_AFTER being only spaces
            builtin setopt localoptions extendedglob
            [[ "${ZPLG_PARAMETERS_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_PARAMETERS_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1

            # Un-concatenated parameters from moment of diff start and of diff end
            typeset -A params_before params_after
            params_before=( "${(z)ZPLG_PARAMETERS_BEFORE[$uspl2]}" )
            params_after=( "${(z)ZPLG_PARAMETERS_AFTER[$uspl2]}" )

            # The parameters that changed, with save of what
            # parameter was when diff started or when diff ended
            typeset -A params_pre params_post
            params_pre=( )
            params_post=( )

            # Iterate through all existing keys, before or after diff,
            # i.e. after all variables that were somehow live across
            # the diffing process
            local key
            typeset -aU keys
            keys=( "${(k)params_after[@]}" );
            keys=( "${keys[@]}" "${(k)params_before[@]}" );
            for key in "${keys[@]}"; do
                key="${(Q)key}"
                if [[ "${params_after[$key]}" != "${params_before[$key]}" ]]; then
                    # Empty for a new param, a type otherwise
                    [[ -z "${params_before[$key]}" ]] && params_before[$key]="\"\""
                    params_pre[$key]="${params_before[$key]}"

                    # Current type, can also be empty, when plugin
                    # unsets a parameter
                    [[ -z "${params_after[$key]}" ]] && params_after[$key]="\"\""
                    params_post[$key]="${params_after[$key]}"
                fi
            done

            # Serialize for reporting
            ZPLG_PARAMETERS_PRE[$uspl2]="${(j: :)${(qkv)params_pre[@]}}"
            ZPLG_PARAMETERS_POST[$uspl2]="${(j: :)${(qkv)params_post[@]}}"
            ;;
        *)
            return 1
    esac

    return 0
}
# }}}

#
# Report functions {{{
#

-zplg-add-report() {
    local uspl2="$1"
    shift
    local txt="$*"

    local keyword="${txt%% *}"
    if [[ "$keyword" = "Failed" || "$keyword" = "Warning:" ]]; then
        keyword="${ZPLG_COL[error]}$keyword${ZPLG_COL[rst]}"
    else
        keyword="${ZPLG_COL[keyword]}$keyword${ZPLG_COL[rst]}"
    fi

    # Don't report to any user/plugin if there is no plugin load in progress
    if [[ -n "$uspl2" ]]; then
        ZPLG_REPORTS[$uspl2]+="$keyword ${txt#* }"$'\n'
    fi

    # This is nasty, if debug is on, report everything
    # to special debug user
    [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]] && ZPLG_REPORTS[_dtrace/_dtrace]+="$keyword ${txt#* }"$'\n'
}

# }}}

#
# Helper functions {{{
#

# Crucial helper function A
# Allows elastic use of "$1" and "$2" across the code
#
# $1 - user---plugin, user/plugin, user (if $2 given), or plugin (if $2 empty)
# $2 - plugin (if $1 - user - given)
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
}

# Crucial helper function B
# Converts to format that's used in keys for hash tables
#
# Supports all four formats
-zplg-any-to-uspl2() {
    -zplg-any-to-user-plugin "$1" "$2"
    REPLY="${reply[-2]}/${reply[-1]}"
}

# Checks for a plugin existence, all four formats
# of the plugin specification supported
-zplg-exists() {
    -zplg-any-to-uspl2 "$1" "$2"
    if [[ -z "${ZPLG_REGISTERED_PLUGINS[(r)$REPLY]}" ]]; then
        return 1
    fi
    return 0
}

# Checks for a plugin existence and outputs a message
-zplg-exists-message() {
    if ! -zplg-exists "$1" "$2"; then
        -zplg-any-colorify-as-uspl2 "$1" "$2"
        print "${ZPLG_COL[error]}No such plugin${ZPLG_COL[rst]} $REPLY"
        return 1
    fi
    return 0
}

# Checks for a plugin existence, all four formats
# of the plugin specification supported
-zplg-exists-physically() {
    -zplg-any-to-user-plugin "$1" "$2"
    [[ -d "$ZPLG_PLUGINS_DIR/${reply[-2]}---${reply[-1]}" ]] && return 0 || return 1
}

# Checks for a plugin existence and outputs a message
-zplg-exists-physically-message() {
    if ! -zplg-exists-physically "$1" "$2"; then
        -zplg-any-colorify-as-uspl2 "$1" "$2"
        print "${ZPLG_COL[error]}No such plugin directory${ZPLG_COL[rst]} $REPLY"
        return 1
    fi
    return 0
}

# Will take uspl, uspl2, or just plugin name,
# and return colored text
-zplg-any-colorify-as-uspl2() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"
    local ucol="${ZPLG_COL[uname]}" pcol="${ZPLG_COL[pname]}"
    REPLY="${ucol}${user}${ZPLG_COL[rst]}/${pcol}${plugin}${ZPLG_COL[rst]}"
}

# Prepare readlink command, used e.g. for
# establishing completion's owner
-zplg-prepare-readlink() {
    REPLY=":"
    if type readlink 2>/dev/null 1>&2; then
        REPLY="readlink"
    fi
}

# For shortening of code
# $1 - completion file
# $2 - readline command
-zplg-get-completion-owner-uspl2col() {
    # "cpath" "readline_cmd"
    -zplg-get-completion-owner "$1" "$2"
    -zplg-any-colorify-as-uspl2 "$REPLY"
}

-zplg-already-function-warning-uspl2() {
    (( $1 )) && -zplg-add-report "$2" "Warning: there already was $3() function defined, possibly in zshrc"
}

-zplg-download-file-stdout() {
    local url="$1"
    local restart="$2"

    if [[ "$restart" = "1" ]]; then
        path+=( "/usr/local/bin" )
        if (( ${+commands[curl]} )) then
            curl -fsSL "$url"
        elif (( ${+commands[wget]} )); then
            wget -q "$url" -O -
        elif (( ${+commands[lftp]} )); then
            lftp -c "cat $url"
        elif (( ${+commands[lynx]} )) then
            lynx -dump "$url"
        else
            [[ "${(t)path}" != *unique* ]] && path[-1]=()
            return 1
        fi
        [[ "${(t)path}" != *unique* ]] && path[-1]=()
    else
        if ! type curl 2>/dev/null 1>&2; then
            curl -fsSL "$url" || -zplg-download-file-stdout "$url" "1"
        elif type wget 2>/dev/null 1>&2; then
            wget -q "$url" -O - || -zplg-download-file-stdout "$url" "1"
        elif type lftp 2>/dev/null 1>&2; then
            lftp -c "cat $url" || -zplg-download-file-stdout "$url" "1"
        else
            -zplg-download-file-stdout "$url" "1"
        fi
    fi

    return 0
}

# Doesn't look for the most common $pname.plugin.zsh
# file but for alternatives
-zplg-find-other-matches() {
    local dname="$1" pdir="$2"

    builtin setopt localoptions nullglob

    if [[ -e "$dname/$pdir/init.zsh" ]]; then
        reply=( "$dname/$pdir/init.zsh" )
    elif [[ -e "$dname/${pdir}.zsh-theme" ]]; then
        reply=( "$dname/${pdir}.zsh-theme" )
    elif [[ -e "$dname/${pdir}.theme.zsh" ]]; then
        reply=( "$dname/${pdir}.theme.zsh" )
    elif [[ -e "$dname/${pdir}.zshplugin" ]]; then
        reply=( "$dname/${pdir}.zshplugin" )
    elif [[ -e "$dname/${pdir}.zsh.plugin" ]]; then
        reply=( "$dname/${pdir}.zsh.plugin" )
    else
        reply=(
            $dname/*.plugin.zsh $dname/*.zsh $dname/*.sh
            $dname/*.zsh-theme $dname/.zshrc(N)
        )
    fi
}

# Get first file that looks like main plugin's file
-zplg-first() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    # There are plugins having ".plugin.zsh"
    # in ${plugin} directory name, also some
    # have ".zsh" there
    local pdir="${${plugin%.plugin.zsh}%.zsh}"
    local dname="$ZPLG_PLUGINS_DIR/${user}---${plugin}"

    # Look for file to compile. First look for the most common one
    # (optimization) then for other possibilities
    if [[ ! -e "$dname/${pdir}.plugin.zsh" ]]; then
        -zplg-find-other-matches "$dname" "$pdir"
    else
        reply=( "$dname/${pdir}.plugin.zsh" )
    fi

    if [[ "${#reply[@]}" -eq "0" ]]; then
        reply=( "$dname" "" )
        return 1
    fi

    # Take first entry
    integer correct=0
    [[ -o "KSH_ARRAYS" ]] && correct=1
    local first="${reply[1-correct]}"

    reply=( "$dname" "$first" )
    return 0
}

# }}}

#
# State restoration functions {{{
# Currently unused
#

-zplg-save-set-extendedglob() {
    [[ -o "extendedglob" ]] && ZPLG_EXTENDED_GLOB="1" || ZPLG_EXTENDED_GLOB="0"
    builtin setopt extendedglob
}

-zplg-restore-extendedglob() {
    [[ "$ZPLG_EXTENDED_GLOB" = "1" ]] && builtin setopt extendedglob
    [[ "$ZPLG_EXTENDED_GLOB" = "0" ]] && builtin unsetopt extendedglob
}
# }}}

#
# ZPlugin internal functions {{{
#

-zplg-unregister-plugin() {
    -zplg-any-to-user-plugin "$1" "$2"
    local uspl2="${reply[-2]}/${reply[-1]}"

    # If not found, idx will be length+1
    local idx="${ZPLG_REGISTERED_PLUGINS[(i)$uspl2]}"
    ZPLG_REGISTERED_PLUGINS[$idx]=()
    ZPLG_REGISTERED_STATES[$uspl2]="0"
}

-zplg-prepare-home() {
    [[ -n "${ZPLG_MAIN[HOME_READY]}" ]] && return
    ZPLG_MAIN[HOME_READY]="1"

    [[ ! -d "$ZPLG_HOME" ]] && {
        command mkdir 2>/dev/null "$ZPLG_HOME"
        # For compaudit
        command chmod go-w "$ZPLG_HOME"
    }
    [[ ! -d "$ZPLG_PLUGINS_DIR" ]] && {
        command mkdir "$ZPLG_PLUGINS_DIR"
        # For compaudit
        command chmod go-w "$ZPLG_PLUGINS_DIR"

        # Prepare mock-like plugin for Zplugin itself
        command mkdir "$ZPLG_PLUGINS_DIR/_local---zplugin"
        command ln -s "$ZPLG_DIR/_zplugin" "$ZPLG_PLUGINS_DIR/_local---zplugin"
    }
    [[ ! -d "$ZPLG_COMPLETIONS_DIR" ]] && {
        command mkdir "$ZPLG_COMPLETIONS_DIR"
        # For compaudit
        command chmod go-w "$ZPLG_COMPLETIONS_DIR"

        # Symlink _zplugin completion into _local---zplugin directory
        command ln -s "$ZPLG_PLUGINS_DIR/_local---zplugin/_zplugin" "$ZPLG_COMPLETIONS_DIR"
    }
    [[ ! -d "$ZPLG_SNIPPETS_DIR" ]] && {
        command mkdir "$ZPLG_SNIPPETS_DIR"
        command chmod go-w "$ZPLG_SNIPPETS_DIR"
    }
}

# Forget given completions. Done before calling compinit
# $1 - completion function name, e.g. "_cp"
-zplg-forget-completion() {
    local f="$1"

    typeset -a commands
    commands=( "${(k@)_comps[(R)$f]}" )

    [[ "${#commands[@]}" -gt 0 ]] && print "Forgetting commands completed by \`$f':"

    local k
    for k in "${commands[@]}"; do
        [[ -n "$k" ]] || continue
        unset "_comps[$k]"
        print "Unsetting $k"
    done

    print "${ZPLG_COL[info]}Forgetting completion \`$f'...${ZPLG_COL[rst]}"
    print
    unfunction -- 2>/dev/null "$f"
}

# $1 - user---plugin, user/plugin, user (if $2 given), or plugin (if $2 empty)
# $2 - plugin (if $1 - user - given)
# $3 - if 1, then reinstall, otherwise only install completions that aren't there
-zplg-install-completions() {
    local reinstall="${3:-0}"

    builtin setopt localoptions nullglob extendedglob unset

    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    # Symlink any completion files included in plugin's directory
    typeset -a completions already_symlinked backup_comps
    local c cfile bkpfile
    completions=( "$ZPLG_PLUGINS_DIR/${user}---${plugin}"/_[^_]* )
    already_symlinked=( "$ZPLG_COMPLETIONS_DIR"/_[^_]* )
    backup_comps=( "$ZPLG_COMPLETIONS_DIR"/[^_]* )

    # Symlink completions if they are not already there
    # either as completions (_fname) or as backups (fname)
    # OR - if it's a reinstall
    for c in "${completions[@]}"; do
        cfile="${c:t}"
        bkpfile="${cfile#_}"
        if [[ -z "${already_symlinked[(r)*/$cfile]}" &&
              -z "${backup_comps[(r)*/$bkpfile]}" ||
              "$reinstall" = "1"
        ]]; then
            if [[ "$reinstall" = "1" ]]; then
                # Remove old files
                command rm -f "$ZPLG_COMPLETIONS_DIR/$cfile"
                command rm -f "$ZPLG_COMPLETIONS_DIR/$bkpfile"
            fi
            print "${ZPLG_COL[info]}Symlinking completion \`$cfile' to $ZPLG_COMPLETIONS_DIR${ZPLG_COL[rst]}"
            command ln -s "$c" "$ZPLG_COMPLETIONS_DIR/$cfile"
            # Make compinit notice the change
            -zplg-forget-completion "$cfile"
        else
            print "${ZPLG_COL[error]}Not symlinking completion \`$cfile', it already exists${ZPLG_COL[rst]}"
            print "${ZPLG_COL[error]}Use \`creinstall {plugin-name}' to force install${ZPLG_COL[rst]}"
        fi
    done
}

-zplg-setup-plugin-dir() {
    local user="$1" plugin="$2" github_path="$1/$2"
    if [[ ! -d "$ZPLG_PLUGINS_DIR/${user}---${plugin}" ]]; then
        if [[ "$user" = "_local" ]]; then
            print "Warning: no local plugin \`$plugin\'"
            print "(looked in $ZPLG_PLUGINS_DIR/${user}---${plugin})"
            return 1
        fi
        -zplg-any-colorify-as-uspl2 "$user" "$plugin"
        print "Downloading $REPLY..."

        # Return with error when any problem
        git clone --recursive https://github.com/"$github_path" "$ZPLG_PLUGINS_DIR/${user}---${plugin}" || return 1

        # Install completions
        -zplg-install-completions "$user" "$plugin" "0"

        # Compile plugin
        -zplg-compile-plugin "$user" "$plugin"
    fi

    return 0
}

# TODO detect second autoload?
-zplg-register-plugin() {
    local mode="$3"
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" uspl2="${reply[-2]}/${reply[-1]}"
    integer ret=0

    if ! -zplg-exists "$user" "$plugin"; then
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
}

-zplg-load-plugin() {
    local user="$1" plugin="$2" mode="$3"
    ZPLG_MAIN[CUR_USR]="$user"
    ZPLG_CUR_PLUGIN="$plugin"
    ZPLG_MAIN[CUR_USPL]="${user}---${plugin}"
    ZPLG_MAIN[CUR_USPL2]="${user}/${plugin}"

    # There are plugins having ".plugin.zsh"
    # in ${plugin} directory name, also some
    # have ".zsh" there
    local pdir="${${plugin%.plugin.zsh}%.zsh}"
    local dname="$ZPLG_PLUGINS_DIR/${user}---${plugin}"

    # Look for a file to source. First look for the most
    # common one (optimization) then for other possibilities
    if [[ ! -e "$dname/${pdir}.plugin.zsh" ]]; then
        -zplg-find-other-matches "$dname" "$pdir"
    else
        reply=( "$dname/${pdir}.plugin.zsh" )
    fi
    [[ "${#reply[@]}" -eq "0" ]] && return 1

    # Get first one
    integer correct=0
    [[ -o "KSH_ARRAYS" ]] && correct=1
    local fname="${reply[1-correct]#$dname/}"

    -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Source $fname"
    [[ "$mode" = "light" ]] && -zplg-add-report "${ZPLG_MAIN[CUR_USPL2]}" "Light load"

    # Light and compdef mode doesn't do diffs and shadowing
    if [[ "$mode" = "load" ]]; then
        -zplg-diff-functions "${ZPLG_MAIN[CUR_USPL2]}" begin
        -zplg-diff-options "${ZPLG_MAIN[CUR_USPL2]}" begin
        -zplg-diff-env "${ZPLG_MAIN[CUR_USPL2]}" begin
        -zplg-diff-parameter "${ZPLG_MAIN[CUR_USPL2]}" begin
    fi

    # Warn about user having his own shadows in place. Check
    # every possible shadow regardless of "$mode" setting
    -zplg-already-function-warning-uspl2 $(( ${+functions[autoload]} )) "${ZPLG_MAIN[CUR_USPL2]}" "autoload"
    -zplg-already-function-warning-uspl2 $(( ${+functions[bindkey]} )) "${ZPLG_MAIN[CUR_USPL2]}" "bindkey"
    -zplg-already-function-warning-uspl2 $(( ${+functions[zstyle]} )) "${ZPLG_MAIN[CUR_USPL2]}" "zstyle"
    -zplg-already-function-warning-uspl2 $(( ${+functions[alias]} )) "${ZPLG_MAIN[CUR_USPL2]}" "alias"
    -zplg-already-function-warning-uspl2 $(( ${+functions[zle]} )) "${ZPLG_MAIN[CUR_USPL2]}" "zle"

    -zplg-shadow-on "$mode"

    # We need some state, but user wants his for his plugins
    builtin setopt noaliases
    builtin source "$dname/$fname"
    builtin unsetopt noaliases

    -zplg-shadow-off "$mode"
    if [[ "$mode" = "load" ]]; then
        -zplg-diff-parameter "${ZPLG_MAIN[CUR_USPL2]}" end
        -zplg-diff-env "${ZPLG_MAIN[CUR_USPL2]}" end
        -zplg-diff-options "${ZPLG_MAIN[CUR_USPL2]}" end
        -zplg-diff-functions "${ZPLG_MAIN[CUR_USPL2]}" end
    fi

    # Mark no load is in progress
    ZPLG_MAIN[CUR_USR]=""
    ZPLG_CUR_PLUGIN=""
    ZPLG_MAIN[CUR_USPL]=""
    ZPLG_MAIN[CUR_USPL2]=""
}

# Compiles plugin
-zplg-compile-plugin() {
    -zplg-first "$1" "$2" || {
        print "${ZPLG_COL[error]}No files for compilation found${ZPLG_COL[rst]}"
        return 1
    }
    local dname="${reply[-2]}" first="${reply[-1]}"
    local fname="${first#$dname/}"

    print "Compiling ${ZPLG_COL[info]}$fname${ZPLG_COL[rst]}..."
    zcompile "$first" || {
        print "Compilation failed. Don't worry, the plugin will work also without compilation"
        print "Consider submitting an error report to the plugin's author"
    }
}
# }}}


# $1 - plugin name, possibly github path
-zplg-load () {
    local mode="$3"
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-register-plugin "$user" "$plugin" "$mode"
    if ! -zplg-setup-plugin-dir "$user" "$plugin"; then
        -zplg-unregister-plugin "$user" "$plugin"
    else
        -zplg-load-plugin "$user" "$plugin" "$mode"
    fi
}

# Downloads and sources a single file
# If url is detected to be github.com, then conversion to "raw" url may occur
-zplg-load-snippet() {
    local url="$1" cmd="$2" force="$3" update="$4"

    if [[ "$url" = "-f" || "$url" == "--command" ]]; then
        local tmp
        tmp="$url"
        [[ "$cmd" != -* ]] && { url="$cmd"; cmd="$tmp"; } || { url="$force"; force="$tmp"; }
    fi

    [[ "$cmd" != --* && -n "$cmd" ]] && { local tmp="$cmd"; cmd="$force"; force="$tmp"; }

    # Check for no-raw github url and for url at all
    integer is_no_raw_github=0 is_url
    local filename local_dir
    () {
        local -a match mbegin mend
        local MATCH; integer MBEGIN MEND
        builtin setopt localoptions extendedglob

        # Remove leading whitespace
        url="${url#"${url%%[! $'\t']*}"}"

        [[ "$url" = *github.com* && ! "$url" = */raw/* ]] && is_no_raw_github=1
        [[ "$url" = http:* || "$url" = https:* || "$url" = ftp:* || "$url" = ftps:* || "$url" = scp:* ]] && is_url=1

        # Construct a local directory name from what's in url
        filename="${url:t}"
        filename="${filename%%\?*}"
        local_dir="$url"
        local_dir="${local_dir//(#b)(http|https|ftp|ftps|scp):\/\//${match[1]}--}"
        local_dir="${local_dir/./--DOT--}"
        local_dir="${local_dir//\//--SLASH--}"
        local_dir="${local_dir//\?/--QMRK--}"
        local_dir="${local_dir//\&/--AMP--}"
        local_dir="${local_dir//=/--EQ--}"
    }

    local save_url="$url"

    # Change the url to point to raw github content if it isn't like that
    if (( is_no_raw_github )); then
        url="${url/\/blob\///raw/}"
        [[ "$url" = *\?* ]] && url="${url}&raw=1" || url="${url}?raw=1"
    fi

    ZPLG_SNIPPETS[$url]="$filename"

    # Download or copy the file
    if [[ ! -f "$ZPLG_SNIPPETS_DIR/$local_dir/$filename" || "$force" = "-f" ]]
    then
        if [[ ! -d "$ZPLG_SNIPPETS_DIR/$local_dir" ]]; then
            print "${ZPLG_COL[info]}Setting up snippet ${ZPLG_COL[p]}$filename${ZPLG_COL[rst]}"
            command mkdir -p "$ZPLG_SNIPPETS_DIR/$local_dir"
        fi

        [[ "$update" = "-u" ]] && echo "${ZPLG_COL[info]}Updating snippet ${ZPLG_COL[p]}$filename${ZPLG_COL[rst]}"

        if (( is_url ))
        then
            # URL
        (
            cd "$ZPLG_SNIPPETS_DIR/$local_dir"
            command rm -f "$filename"
            print "Downloading $filename..."
            -zplg-download-file-stdout "$url" >! "$filename" || echo "No available download tool (curl,wget,lftp,lynx)"
        )
        else
            # File
            command rm -f "$ZPLG_SNIPPETS_DIR/$local_dir/$filename"
            print "Copying $filename..."
            command cp -v "$url" "$ZPLG_SNIPPETS_DIR/$local_dir/$filename"
        fi

        echo "$save_url" >! "$ZPLG_SNIPPETS_DIR/$local_dir/.zplugin_url"
    fi

    # Updating – no sourcing or setup
    [[ "$update" = "-u" ]] && return 0

    if [[ "$cmd" != "--command" ]]; then
        # Source the file with compdef shadowing
        -zplg-shadow-on "compdef"
        builtin source "$ZPLG_SNIPPETS_DIR/$local_dir/$filename"
        -zplg-shadow-off "compdef"
    else
        [[ ! -x "$ZPLG_SNIPPETS_DIR/$local_dir/$filename" ]] && command chmod a+x "$ZPLG_SNIPPETS_DIR/$local_dir/$filename"
        [[ -z "${path[(er)$ZPLG_SNIPPETS_DIR/$local_dir]}" ]] && path+=( "$ZPLG_SNIPPETS_DIR/$local_dir" )
    fi
}

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
}

-zplg-compdef-clear() {
    local quiet="$1"
    ZPLG_COMPDEF_REPLAY=( )
    [[ "$quiet" = "-q" ]] || print "Compdef replay cleared"
}

-zplg-cd() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    cd "$ZPLG_PLUGINS_DIR/${user}---${plugin}"
}

#
# Debug reporting functions, user exposed {{{
#

# Starts debug reporting, diffing
-zplg-debug-start() {
    if [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]]; then
        print "${ZPLG_COL[error]}Dtrace is already active, stop it first with \`dstop'$reset_color"
        return 1
    fi

    ZPLG_MAIN[DTRACE]="1"

    -zplg-diff-functions "_dtrace/_dtrace" begin
    -zplg-diff-options "_dtrace/_dtrace" begin
    -zplg-diff-env "_dtrace/_dtrace" begin
    -zplg-diff-parameter "_dtrace/_dtrace" begin

    # Full shadowing on
    -zplg-shadow-on "dtrace"
}

# Ends debug reporting, diffing
-zplg-debug-stop() {
    ZPLG_MAIN[DTRACE]="0"

    # Shadowing fully off
    -zplg-shadow-off "dtrace"

    # Gather end data now, for diffing later
    -zplg-diff-parameter "_dtrace/_dtrace" end
    -zplg-diff-env "_dtrace/_dtrace" end
    -zplg-diff-options "_dtrace/_dtrace" end
    -zplg-diff-functions "_dtrace/_dtrace" end
}

-zplg-clear-debug-report() {
    -zplg-clear-report-for "_dtrace/_dtrace"
}

# Reverts changes recorded through dtrace
-zplg-debug-unload() {
    if [[ "${ZPLG_MAIN[DTRACE]}" = "1" ]]; then
        print "Dtrace is still active, end it with \`dstop'"
    else
        -zplg-unload "_dtrace" "_dtrace"
    fi
}
# }}}

-zplg-load-user-functions() {
    (( ${+functions[-zplg-format-functions]} )) || builtin source $ZPLG_DIR"/zplugin-autoload.zsh"
}

# Main function with subcommands
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
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # Load plugin given in uspl2 or "user plugin" format
           # Possibly clone from github, and install completions
           -zplg-load "$2" "$3" "load"
           ;;
       (light)
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # This is light load, without tracking, only with
           # clean FPATH (autoload is still being shadowed)
           -zplg-load "$2" "$3" "light"
           ;;
       (cdreplay)
           -zplg-compdef-replay "$2"
           ;;
       (cdclear)
           -zplg-compdef-clear "$2"
           ;;
       (man)
           man "$ZPLG_DIR/doc/zplugin.1"
           ;;
       (zstatus)
           -zplg-load-user-functions
           -zplg-show-zstatus
           ;;
       (self-update)
           -zplg-load-user-functions
           -zplg-self-update
           ;;
       (unload)
           -zplg-load-user-functions
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # Unload given plugin. Cloned directory remains intact
           # so as are completions
           -zplg-unload "$2" "$3"
           ;;
       (snippet)
           -zplg-load-snippet "$2" "$3" "$4"
           ;;
       (update)
           -zplg-load-user-functions
           if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
               [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 2; }
               -zplg-update-or-status-all "update"
           else
               -zplg-update-or-status "update" "$2" "$3"
           fi
           ;;
       (status)
           -zplg-load-user-functions
           if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
               [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 2; }
               -zplg-update-or-status-all "status"
           else
               -zplg-update-or-status "status" "$2" "$3"
           fi
           ;;
       (report)
           -zplg-load-user-functions
           if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
               [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 3; }
               -zplg-show-all-reports
           else
               -zplg-show-report "$2" "$3"
           fi
           ;;
       (loaded|list)
           -zplg-load-user-functions
           # Show list of loaded plugins
           -zplg-show-registered-plugins "$2"
           ;;
       (clist|completions)
           -zplg-load-user-functions
           # Show installed, enabled or disabled, completions
           # Detect stray and improper ones
           -zplg-show-completions
           ;;
       (cclear)
           -zplg-load-user-functions
           # Delete stray and improper completions
           -zplg-clear-completions
           ;;
       (cdisable)
           -zplg-load-user-functions
           if [[ -z "$2" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           local f="_${2#_}"
           # Disable completion given by completion function name
           # with or without leading "_", e.g. "cp", "_cp"
           if -zplg-cdisable "$f"; then
               -zplg-forget-completion "$f"
               print "Initializing completion system (compinit)..."
               builtin autoload -Uz compinit
               compinit
           fi
           ;;
       (cenable)
           -zplg-load-user-functions
           if [[ -z "$2" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           local f="_${2#_}"
           # Enable completion given by completion function name
           # with or without leading "_", e.g. "cp", "_cp"
           if -zplg-cenable "$f"; then
               -zplg-forget-completion "$f"
               print "Initializing completion system (compinit)..."
               builtin autoload -Uz compinit
               compinit
           fi
           ;;
       (creinstall)
           -zplg-load-user-functions
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # Installs completions for plugin. Enables them all. It's a
           # reinstallation, thus every obstacle gets overwritten or removed
           -zplg-install-completions "$2" "$3" "1"
           print "Initializing completion (compinit)..."
           builtin autoload -Uz compinit
           compinit
           ;;
       (cuninstall)
           -zplg-load-user-functions
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # Uninstalls completions for plugin
           -zplg-uninstall-completions "$2" "$3"
           print "Initializing completion (compinit)..."
           builtin autoload -Uz compinit
           compinit
           ;;
       (csearch)
           -zplg-load-user-functions
           -zplg-search-completions
           ;;
       (compinit)
           -zplg-load-user-functions
           # Runs compinit in a way that ensures
           # reload of plugins' completions
           -zplg-compinit
           ;;
       (dstart|dtrace)
           -zplg-debug-start
           ;;
       (dstop)
           -zplg-debug-stop
           ;;
       (dreport)
           -zplg-load-user-functions
           -zplg-show-debug-report
           ;;
       (dclear)
           -zplg-load-user-functions
           -zplg-clear-debug-report
           ;;
       (dunload)
           -zplg-load-user-functions
           -zplg-debug-unload
           ;;
       (compile)
           if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
               [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 2; }
               -zplg-load-user-functions
               -zplg-compile-uncompile-all "1"
           else
               -zplg-compile-plugin "$2" "$3"
           fi
           ;;
       (uncompile)
           -zplg-load-user-functions
           if [[ "$2" = "--all" || ( -z "$2" && -z "$3" ) ]]; then
               [[ -z "$2" ]] && { echo "Assuming --all is passed"; sleep 2; }
               -zplg-compile-uncompile-all "0"
           else
               -zplg-uncompile-plugin "$2" "$3"
           fi
           ;;
       (compiled)
           -zplg-load-user-functions
           -zplg-compiled
           ;;
       (cdlist)
           -zplg-load-user-functions
           -zplg-list-compdef-replay
           ;;
       (cd)
           -zplg-load-user-functions
           -zplg-cd "$2" "$3"
           ;;
       (edit)
           -zplg-load-user-functions
           -zplg-edit "$2" "$3"
           ;;
       (glance)
           -zplg-load-user-functions
           -zplg-glance "$2" "$3"
           ;;
       (changes)
           -zplg-load-user-functions
           -zplg-changes "$2" "$3"
           ;;
       (recently)
           -zplg-load-user-functions
           shift
           -zplg-recently "$@"
           ;;
       (create)
           -zplg-load-user-functions
           -zplg-create "$2" "$3"
           ;;
       (stress)
           -zplg-load-user-functions
           -zplg-stress "$2" "$3"
           ;;
       (-h|--help|help|"")
           -zplg-load-user-functions
           -zplg-help
           ;;
       (*)
           print "Unknown command \`$1' (use \`help' to get usage information)"
           ;;
    esac
}

builtin unsetopt noaliases
builtin alias zpl=zplugin zplg=zplugin

-zplg-prepare-home

# Add completions directory to fpath
fpath=( "$ZPLG_COMPLETIONS_DIR" "${fpath[@]}" )

# Colorize completions for commands unload, report, creinstall, cuninstall
zstyle ':completion:*:zplugin:argument-rest:plugins' list-colors '=(#b)(*)/(*)==1;35=1;33'
zstyle ':completion:*:zplugin:argument-rest:plugins' matcher 'r:|=** l:|=*'
