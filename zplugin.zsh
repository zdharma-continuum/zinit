# -*- mode: shell-script -*-
# vim:ft=zsh

#
# Main state variables
#

typeset -gaH ZPLG_REGISTERED_PLUGINS
# Maps plugins to 0, 1 or 2 - not loaded, light loaded, fully loaded
typeset -gAH ZPLG_REGISTERED_STATES
typeset -gAH ZPLG_REPORTS

#
# Common needed values
#

if [ -n "$argv[0]" ]; then
    typeset -gH ZPLG_DIR="${argv[0]:h}"
    typeset -gH ZPLG_NAME="${${argv[0]:t}:r}"
else
    typeset -gH ZPLG_DIR="${0:h}"
    typeset -gH ZPLG_NAME="${${0:t}:r}"
fi

if [ -d "$HOME/.$ZPLG_NAME" ]; then
    # Ignore ZDOTDIR if user manually put Zplugin to $HOME
    typeset -gH ZPLG_HOME="$HOME/.$ZPLG_NAME"
else
    typeset -gH ZPLG_HOME="${ZDOTDIR:-$HOME}/.$ZPLG_NAME"
fi

typeset -gH ZPLG_PLUGINS_DIR="$ZPLG_HOME/plugins"
typeset -gH ZPLG_COMPLETIONS_DIR="$ZPLG_HOME/completions"
typeset -gH ZPLG_HOME_READY
typeset -gaHU ZPLG_ENTER_OPTIONS
typeset -gH ZPLG_EXTENDED_GLOB
typeset -gAH ZPLG_BACKUP_FUNCTIONS
typeset -gAH ZPLG_BACKUP_ALIASES

#
# All to the users - simulate OMZ directory structure (1/3)
#

typeset -gH ZSH="$ZPLG_PLUGINS_DIR"
typeset -gH ZSH_CUSTOM="$ZPLG_PLUGINS_DIR/custom"
export ZSH ZSH_CUSTOM

#
# Nasty variables {{{
# Can be used by any shadowing function to recognize current context
#

typeset -gH ZPLG_CUR_USER=""
typeset -gH ZPLG_CUR_PLUGIN=""
# Concatenated with "---"
typeset -gH ZPLG_CUR_USPL=""
# Concatenated with "/"
typeset -gH ZPLG_CUR_USPL2=""
# If any plugin retains the shadowed function instead of
# original one then this will protect from further reporting
typeset -gH ZPLG_SHADOWING_ACTIVE

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
# Zstyle, bindkey, alias, zle remembering {{{
#

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

# }}}

#
# Init {{{
#

zmodload zsh/zutil || return 1
zmodload zsh/parameter || return 1
zmodload zsh/terminfo 2>/dev/null
zmodload zsh/termcap 2>/dev/null

if [[ ( -n "$terminfo[colors]" || -n "$termcap[Co]" ) && -z "$functions[colors]" ]]; then
    autoload colors
    colors
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
    "uninst" "${fg_bold[blue]}"
)

# }}}

#
# Shadowing-related functions (names of substitute functions start with -) {{{
# Must be resistant to various game-changing options like KSH_ARRAYS
#

--zplugin-reload-and-run () {
    local fpath_prefix="$1" autoload_opts="$2" func="$3"
    shift 3

    # Unfunction caller function (its name is given)
    unfunction "$func"

    local FPATH="$fpath_prefix":"${FPATH}"

    # After this the function exists again
    builtin autoload $=autoload_opts "$func"

    # User wanted to call the function, not only load it
    "$func" "$@"
}

--zplugin-shadow-autoload () {
    # Shadowing guard
    [ "$ZPLG_SHADOWING_ACTIVE" = "1" ] || { builtin autoload "$@"; return $?; }

    local -a opts
    local func

    zparseopts -a opts -D ${(s::):-TUXkmtzw}

    if [ -n "${opts[(r)(-|+)X]}" ]
    then
        -zplugin-add-report "$ZPLG_CUR_USPL2" "Failed autoload $opts $*"
        print -u2 "builtin autoload required for $opts"
        return 1
    fi
    if [ -n "${opts[(r)-w]}" ]
    then
        -zplugin-add-report "$ZPLG_CUR_USPL2" "-w-Autoload $opts $*"
        builtin autoload $opts "$@"
        return
    fi

    # Report ZPLUGIN's "native" autoloads
    local i
    for i in "$@"; do
        local msg="Autoload $i"
        [ -n "$opts" ] && msg+=" with options $opts"
        -zplugin-add-report "$ZPLG_CUR_USPL2" "$msg"
    done

    # Do ZPLUGIN's "native" autoloads
    local PLUGIN_DIR="$ZPLG_PLUGINS_DIR/${ZPLG_CUR_USPL}"
    for func
    do
        eval "function $func {
            --zplugin-reload-and-run ${(q)PLUGIN_DIR} ${(qq)opts} ${(q)func} "'"$@"
        }'
        #functions[$func]="--zplugin-reload-and-run ${(q)PLUGIN_DIR} ${(qq)opts} ${(q)func} "'"$@"'
    done
}

--zplugin-shadow-bindkey() {
    # Shadowing guard
    [ "$ZPLG_SHADOWING_ACTIVE" = "1" ] || { builtin bindkey "$@"; return $?; }

    -zplugin-add-report "$ZPLG_CUR_USPL2" "Bindkey $*"

    # Remember to perform the actual bindkey call
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular bindkey call, i.e.
    # with no options or with -s, plus possible -M
    # option
    local -A optsA
    zparseopts -A optsA -D ${(s::):-lLdDANmrsevaR} "M:"

    local -a opts
    opts=( "${(k)optsA[@]}" )

    if [[ "${#opts[@]}" -eq "0" ||
        ( "${#opts[@]}" -eq "1" && "${opts[(r)-M]}" = "-M" ) ||
        ( "${#opts[@]}" -eq "1" && "${opts[(r)-R]}" = "-R" ) ||
        ( "${#opts[@]}" -eq "1" && "${opts[(r)-s]}" = "-s" ) ||
        ( "${#opts[@]}" -le "2" && "${opts[(r)-M]}" = "-M" && "${opts[(r)-s]}" = "-s" ) ||
        ( "${#opts[@]}" -le "2" && "${opts[(r)-M]}" = "-M" && "${opts[(r)-R]}" = "-R" )
    ]]; then
        local string="${(q)1}" widget="${(q)2}"
        local quoted

        # "-M map" given?
        if [ "${opts[(r)-M]}" = "-M" ]; then
            local Mopt="-M"
            local Marg="${optsA[-M]}"

            Mopt="${(q)Mopt}"
            Marg="${(q)Marg}"

            quoted="$string $widget $Mopt $Marg"
        else
            quoted="$string $widget"
        fi

        # -R given?
        if [ "${opts[(r)-R]}" = "-R" ]; then
            local Ropt="-R"
            Ropt="${(q)Ropt}"

            if [ "${opts[(r)-M]}" = "-M" ]; then
                quoted="$quoted $Ropt"
            else
                # Two empty fields for non-existent -M arg
                local space="_"
                space="${(q)space}"
                quoted="$quoted $space $space $Ropt"
            fi
        fi

        quoted="${(q)quoted}"

        # Remember the zstyle
        ZPLG_BINDKEYS[$ZPLG_CUR_USPL2]+="$quoted "
    else
        -zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: last bindkey used non-typical options: ${opts[*]}"
    fi

    # Actual bindkey
    builtin bindkey "${pos[@]}"
}

--zplugin-shadow-zstyle() {
    # Shadowing guard
    [ "$ZPLG_SHADOWING_ACTIVE" = "1" ] || { builtin zstyle "$@"; return $?; }

    -zplugin-add-report "$ZPLG_CUR_USPL2" "Zstyle $*"

    # Remember to perform the actual zstyle call
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular zstyle call, i.e.
    # with no options or with -e
    local -a opts
    zparseopts -a opts -D ${(s::):-eLdgabsTtm}

    if [[ "${#opts[@]}" -eq 0 || ( "${#opts[@]}" -eq 1 && "${opts[(r)-e]}" = "-e" ) ]]; then
        # Have to quote $1, then $2, then concatenate them, then quote them again
        local pattern="${(q)1}" style="${(q)2}"
        local ps="$pattern $style"
        ps="${(q)ps}"

        # Remember the zstyle
        ZPLG_ZSTYLES[$ZPLG_CUR_USPL2]+="$ps "
    else
        -zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: last zstyle used non-typical options: ${opts[*]}"
    fi

    # Actual zstyle
    builtin zstyle "${pos[@]}"
}

--zplugin-shadow-alias() {
    # Shadowing guard
    [ "$ZPLG_SHADOWING_ACTIVE" = "1" ] || { builtin alias "$@"; return $?; }

    -zplugin-add-report "$ZPLG_CUR_USPL2" "Alias $*"

    # Remember to perform the actual alias call
    typeset -a pos
    pos=( "$@" )

    local -a opts
    zparseopts -a opts -D ${(s::):-gs}

    local a quoted tmp
    for a in "$@"; do
        local aname="${a%%=*}"
        local avalue="${a#*=}"

        # Check if alias is to be redefined
        (( ${+aliases[$aname]} )) && -zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: redefining alias \`${aname}', previous value: ${avalue}"

        aname="${(q)aname}"
        bname="${(q)avalue}"

        if [ "${opts[(r)-s]}" = "-s" ]; then
            tmp="-s"
            tmp="${(q)tmp}"
            quoted="$aname $bname $tmp"
        elif [ "${opts[(r)-g]}" = "-g" ]; then
            tmp="-g"
            tmp="${(q)tmp}"
            quoted="$aname $bname $tmp"
        else
            quoted="$aname $bname"
        fi

        quoted="${(q)quoted}"

        ZPLG_ALIASES[$ZPLG_CUR_USPL2]+="$quoted "
    done

    # Actual alias
    builtin alias "${pos[@]}"
}

--zplugin-shadow-zle() {
    # Shadowing guard
    [ "$ZPLG_SHADOWING_ACTIVE" = "1" ] || { builtin zle "$@"; return $?; }

    -zplugin-add-report "$ZPLG_CUR_USPL2" "Zle $*"

    # Remember to perform the actual zle call
    typeset -a pos
    pos=( "$@" )

    # Try to catch game-changing "-N"
    if [[ "$1" = "-N" && "$#" = "3" ]]; then
        case "$2" in
            # Hooks will be just deleted
            zle-line-init|zle-line-finish|paste-insert)
                local quoted="$2"
                quoted="${(q)quoted}"
                ZPLG_WIDGETS_DELETE[$ZPLG_CUR_USPL2]+="$quoted "
                ;;
            # These will be saved and restored
            self-insert|backward-delete-char|delete-char)
                # Have to remember original widget "$2" and
                # the copy that it's going to be done
                local widname="$2" saved_widname="zplugin-saved-$2"
                builtin zle -A "$widname" "$saved_widname"

                widname="${(q)widname}"
                saved_widname="${(q)saved_widname}"
                quoted="$widname $saved_widname"
                quoted="${(q)quoted}"
                ZPLG_WIDGETS_SAVED[$ZPLG_CUR_USPL2]+="$quoted "
                ;;
            *)
                -zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: unsupported widget replaced/taken via zle -N: \`$2'"
                ;;
        esac
    fi

    # Actual zle
    builtin zle "${pos[@]}"
}

--zplugin-shadow-compdef() {
    # Shadowing guard
    [ "$ZPLG_SHADOWING_ACTIVE" = "1" ] || { \compdef "$@"; return $?; }

    # Check if that function exists
    if (( ${+functions[compdef]} == 0 )); then
        -zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: running \`compdef $*' and \`compdef' doesn't exist"
    else
        -zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: running \`compdef $*' and \'compdef' exists"\
                                                "(you might be running compinit twice; this is probably required"\
                                                "for this plugin's completion to work)"
    fi

    # Actual zle
    \compdef 2>/dev/null "$@"
}

# Shadowing on
-zplugin-shadow-on() {
    local light="$1"

    ZPLG_SHADOWING_ACTIVE=1

    (( ${+aliases[autoload]} )) && -zplugin-already-alias-warning-uspl2 "$ZPLG_CUR_USPL2" "autoload"
    ZPLG_BACKUP_ALIASES[autoload]="$aliases[autoload]"
    builtin alias autoload=--zplugin-shadow-autoload

    # Light loading stops here
    [ "$light" = "light" ] && return 0

    (( ${+functions[bindkey]} )) && -zplugin-already-function-warning-uspl2 "$ZPLG_CUR_USPL2" "bindkey"
    ZPLG_BACKUP_FUNCTIONS[bindkey]="$functions[bindkey]"
    function bindkey {
        --zplugin-shadow-bindkey "$@"
    }

    (( ${+functions[zstyle]} )) && -zplugin-already-function-warning-uspl2 "$ZPLG_CUR_USPL2" "zstyle"
    ZPLG_BACKUP_FUNCTIONS[zstyle]="$functions[zstyle]"
    function zstyle {
        --zplugin-shadow-zstyle "$@"
    }

    (( ${+aliases[compdef]} )) && -zplugin-already-alias-warning-uspl2 "$ZPLG_CUR_USPL2" "compdef"
    ZPLG_BACKUP_ALIASES[compdef]="$aliases[compdef]"
    builtin alias compdef=--zplugin-shadow-compdef

    (( ${+functions[alias]} )) && -zplugin-already-function-warning-uspl2 "$ZPLG_CUR_USPL2" "alias"
    ZPLG_BACKUP_FUNCTIONS[alias]="$functions[alias]"
    function alias {
        --zplugin-shadow-alias "$@"
    }

    (( ${+functions[zle]} )) && -zplugin-already-function-warning-uspl2 "$ZPLG_CUR_USPL2" "zle"
    ZPLG_BACKUP_FUNCTIONS[zle]="$functions[zle]"
    function zle {
        --zplugin-shadow-zle "$@"
    }

    return 0
}

# Shadowing off
-zplugin-shadow-off() {
    local light="$1"

    ZPLG_SHADOWING_ACTIVE=0

    -zplugin-trim-backup-vars

    # Unalias "autoload"
    [ -n "$ZPLG_BACKUP_ALIASES[autoload]" ] && aliases[autoload]="$ZPLG_BACKUP_ALIASES[autoload]" || unalias "autoload"

    # Light loading stops here
    [ "$light" = "light" ] && return 0

    # Unfunction shadowing functions
    [ -n "$ZPLG_BACKUP_FUNCTIONS[bindkey]" ] && functions[bindkey]="$ZPLG_BACKUP_FUNCTIONS[bindkey]" || unfunction "bindkey"
    [ -n "$ZPLG_BACKUP_FUNCTIONS[zstyle]" ] && functions[zstyle]="$ZPLG_BACKUP_FUNCTIONS[zstyle]" || unfunction "zstyle"
    [ -n "$ZPLG_BACKUP_FUNCTIONS[alias]" ] && functions[alias]="$ZPLG_BACKUP_FUNCTIONS[alias]" || unfunction "alias"
    [ -n "$ZPLG_BACKUP_FUNCTIONS[zle]" ] && functions[zle]="$ZPLG_BACKUP_FUNCTIONS[zle]" || unfunction "zle"

    # Unalias "compdef"
    [ -n "$ZPLG_BACKUP_ALIASES[compdef]" ] && aliases[compdef]="$ZPLG_BACKUP_ALIASES[compdef]" || unalias "compdef"

    return 0
}

# }}}

#
# Function diff functions {{{
#

# Can remember current $functions twice, and compute the
# difference, storing it in ZPLG_FUNCTIONS, associated
# with given ($1) plugin
-zplugin-diff-functions() {
    local uspl2="$1"
    local cmd="$2"

    if [[ "$cmd" = "begin" || "$cmd" = "end" ]]; then
            typeset -a func
            func=( "${(onk)functions[@]}" )
            func=( "${(q)func[@]}" )
    fi

    case "$cmd" in
        begin)
            ZPLG_FUNCTIONS_BEFORE[$uspl2]="$func[*]"
            ZPLG_FUNCTIONS[$uspl2]=""
            ZPLG_FUNCTIONS_DIFF_RAN[$uspl2]="0"
            ;;
        end)
            ZPLG_FUNCTIONS_AFTER[$uspl2]="$func[*]"
            ZPLG_FUNCTIONS[$uspl2]=""
            ZPLG_FUNCTIONS_DIFF_RAN[$uspl2]="0"
            ;;
        diff)
            # Run diff once, `begin' or `end' is needed to be run again for a new diff
            [ "$ZPLG_FUNCTIONS_DIFF_RAN[$uspl2]" = "1" ] && return 0
            ZPLG_FUNCTIONS_DIFF_RAN[$uspl2]="1"

            # Cannot run diff if *_BEFORE or *_AFTER variable is not set
            # Following is paranoid for *_BEFORE and *_AFTER being only spaces
            integer error=0
            -zplugin-save-set-extendedglob
            [[ "${ZPLG_FUNCTIONS_BEFORE[$uspl2]}" = ( |$'\t')# || "${ZPLG_FUNCTIONS_AFTER[$uspl2]}" = ( |$'\t')# ]] && error=1
            -zplugin-restore-extendedglob
            (( error )) && return 1

            typeset -A func
            local i

            # This includes new functions
            for i in "${(z)ZPLG_FUNCTIONS_AFTER[$uspl2]}"; do
                i="${(Q)i}"
                func[$i]=1
            done

            # Remove duplicated entries, i.e. existing before
            for i in "${(z)ZPLG_FUNCTIONS_BEFORE[$uspl2]}"; do
                i="${(Q)i}"
                unset "func[$i]"
            done

            # Store the functions, associating them with plugin ($uspl2)
            for i in "${(onk)func[@]}"; do
                ZPLG_FUNCTIONS[$uspl2]+="$i "
            done
            ;;
        *)
            return 1
    esac

    return 0
}

# Creates a one or two columns text with functions
# belonging to given ($1) plugin
-zplugin-format-functions() {
    local uspl2="$1"

    typeset -a func
    func=( "${(z)ZPLG_FUNCTIONS[$uspl2]}" )

    # Get length of longest left-right string pair,
    # and length of longest left string
    integer longest=0 longest_left=0 cur_left_len=0 count=1
    local f
    for f in "${(on)func[@]}"; do
        [ -z "$f" ] && continue
        f="${(Q)f}"

        # Compute for elements in left column,
        # ones that will be paded with spaces 
        if (( count ++ % 2 != 0 )); then
            [ "$#f" -gt "$longest_left" ] && longest_left="$#f"
            cur_left_len="$#f"
        else
            cur_left_len+="$#f"
            cur_left_len+=1 # For separating space
            [ "$cur_left_len" -gt "$longest" ] && longest="$cur_left_len"
        fi
    done

    # Output in one or two columns
    local answer=""
    count=1
    for f in "${(on)func[@]}"; do
        [ -z "$f" ] && continue
        f="${(Q)f}"

        if (( COLUMNS >= longest )); then
            if (( count ++ % 2 != 0 )); then
                answer+="${(r:longest_left+1:: :)f}"
            else
                answer+="$f"$'\n'
            fi
        else
            answer+="$f"$'\n'
        fi
    done
    REPLY="$answer"
    # == 0 is: next element would have newline (postfix addition in "count ++")
    (( COLUMNS >= longest && count % 2 == 0 )) && REPLY="$REPLY"$'\n'
}

# }}}

#
# Option diff functions {{{
#

# Can remember current $options twice. After that can
# detect any change between the two saves. Changed
# options are appended as they were in first save to
# ZPLG_OPTIONS, all associated with given ($1) plugin
-zplugin-diff-options() {
    local uspl2="$1"
    local cmd="$2"

    case "$cmd" in
        begin)
            ZPLG_OPTIONS_BEFORE[$uspl2]="${(kv)options}"
            ZPLG_OPTIONS[$uspl2]=""
            ZPLG_OPTIONS_DIFF_RAN[$uspl2]="0"
            ;;
        end)
            ZPLG_OPTIONS_AFTER[$uspl2]="${(kv)options}"
            ZPLG_OPTIONS[$uspl2]=""
            ZPLG_OPTIONS_DIFF_RAN[$uspl2]="0"
            ;;
        diff)
            # Run diff once, `begin' or `end' is needed to be run again for a new diff
            [ "$ZPLG_OPTIONS_DIFF_RAN[$uspl2]" = "1" ] && return 0
            ZPLG_OPTIONS_DIFF_RAN[$uspl2]="1"

            # Cannot run diff if *_BEFORE or *_AFTER variable is not set
            # Following is paranoid for *_BEFORE and *_AFTER being only spaces
            integer error=0
            -zplugin-save-set-extendedglob
            [[ "${ZPLG_OPTIONS_BEFORE[$uspl2]}" = ( |$'\t')# || "${ZPLG_OPTIONS_AFTER[$uspl2]}" = ( |$'\t')# ]] && error=1
            -zplugin-restore-extendedglob
            (( error )) && return 1

            typeset -A opts_before opts_after opts
            opts_before=( "${(z)ZPLG_OPTIONS_BEFORE[$uspl2]}" )
            opts_after=( "${(z)ZPLG_OPTIONS_AFTER[$uspl2]}" )
            opts=( )

            # Iterate through first array (keys the same
            # on both of them though) and thest for a change
            local key
            for key in "${(k)opts_before[@]}"; do
                if [ "$opts_before[$key]" != "$opts_after[$key]" ]; then
                    opts[$key]="${opts_before[$key]}"
                fi
            done

            # Serialize for reporting
            ZPLG_OPTIONS[$uspl2]="${(kv)opts}"
            ;;
        *)
            return 1
    esac

    return 0
}

# Creates a text about options that changed when loaded plugin "$1"
-zplugin-format-options() {
    local uspl2="$1"

    REPLY=""

    # Paranoid, don't want bad key/value pair error
    integer empty=0
    -zplugin-save-set-extendedglob
    [[ "${ZPLG_OPTIONS[$uspl2]}" = ( |$'\t')# ]] && empty=1
    -zplugin-restore-extendedglob
    (( empty )) && return 0

    typeset -A opts
    opts=( "${(z)ZPLG_OPTIONS[$uspl2]}" )

    # Get length of longest option
    integer longest=0
    local k
    for k in "${(kon)opts[@]}"; do
        [ "$#k" -gt "$longest" ] && longest="$#k"
    done

    # Output in one column
    local txt
    for k in "${(kon)opts[@]}"; do
        [ "${opts[$k]}" = "on" ] && txt="was unset" || txt="was set"
        REPLY+="${(r:longest+1:: :)k}$txt"$'\n'
    done
}
# }}}

#
# Environment diff functions {{{
#

-zplugin-diff-env() {
    local uspl2="$1"
    local cmd="$2"
    typeset -a tmp

    case "$cmd" in
        begin)
            tmp=( "${(q)path[@]}" )
            ZPLG_PATH_BEFORE[$uspl2]="$tmp[*]"
            tmp=( "${(q)fpath[@]}" )
            ZPLG_FPATH_BEFORE[$uspl2]="$tmp[*]"

            # Reset diffing
            ZPLG_PATH[$uspl2]=""
            ZPLG_FPATH[$uspl2]=""
            ZPLG_ENV_DIFF_RAN[$uspl2]="0"
            ;;
        end)
            tmp=( "${(q)path[@]}" )
            ZPLG_PATH_AFTER[$uspl2]="$tmp[*]"
            tmp=( "${(q)fpath[@]}" )
            ZPLG_FPATH_AFTER[$uspl2]="$tmp[*]"

            # Reset diffing
            ZPLG_PATH[$uspl2]=""
            ZPLG_FPATH[$uspl2]=""
            ZPLG_ENV_DIFF_RAN[$uspl2]="0"
            ;;
        diff)
            # Run diff once, `begin' or `end' is needed to be run again for a new diff
            [ "$ZPLG_ENV_DIFF_RAN[$uspl2]" = "1" ] && return 0
            ZPLG_ENV_DIFF_RAN[$uspl2]="1"

            # Cannot run diff if *_BEFORE or *_AFTER variable is not set
            # Following is paranoid for *_BEFORE and *_AFTER being only spaces
            integer error=0
            -zplugin-save-set-extendedglob
            [[ "${ZPLG_PATH_BEFORE[$uspl2]}" = ( |$'\t')# || "${ZPLG_PATH_AFTER[$uspl2]}" = ( |$'\t')# ]] && error=1
            [[ "${ZPLG_FPATH_BEFORE[$uspl2]}" = ( |$'\t')# || "${ZPLG_FPATH_AFTER[$uspl2]}" = ( |$'\t')# ]] && error=1
            -zplugin-restore-extendedglob
            (( error )) && return 1

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

-zplugin-format-env() {
    local uspl2="$1" which="$2"

    # Format PATH?
    if [ "$which" = "1" ]; then
        typeset -a elem
        elem=( "${(z)ZPLG_PATH[$uspl2]}" )
    elif [ "$which" = "2" ]; then
        typeset -a elem
        elem=( "${(z)ZPLG_FPATH[$uspl2]}" )
    fi

    # Enumerate elements added
    local answer="" e
    for e in "${elem[@]}"; do
        [ -z "$e" ] && continue
        e="${(Q)e}"
        answer+="$e"$'\n'
    done

    [ -n "$answer" ] && REPLY="$answer"
}

# }}}

#
# Report functions {{{
#

-zplugin-add-report() {
    local uspl2="$1"
    shift
    local txt="$*"

    local keyword="${txt%% *}"
    if [[ "$keyword" = "Failed" || "$keyword" = "Warning:" ]]; then
        keyword="${ZPLG_COL[error]}$keyword$reset_color"
    else
        keyword="${ZPLG_COL[keyword]}$keyword$reset_color"
    fi

    ZPLG_REPORTS[$uspl2]+="$keyword ${txt#* }"$'\n'
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
-zplugin-any-to-user-plugin() {
    # Two components given?
    if [ -n "$2" ];then
        # But user name is empty?
        [ -z "$1" ] && 1="_local"

        reply=( "$1" "$2" )
        return 0
    fi

    # Rest is for single component given
    # It doesn't touch $2

    local user="${1%%/*}" plugin="${1#*/}"
    if [ "$user" = "$plugin" ]; then
        user="${1%%---*}"
        plugin="${1#*---}"
    fi

    if [[ "$user" = "$plugin" || -z "$user" ]]; then
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
-zplugin-any-to-uspl2() {
    -zplugin-any-to-user-plugin "$1" "$2"
    REPLY="$reply[1]/$reply[2]"
}

# Checks for a plugin existence, all four formats
# of the plugin specification supported
-zplugin-exists() {
    -zplugin-any-to-uspl2 "$1" "$2"
    if [ -z "${ZPLG_REGISTERED_PLUGINS[(r)$REPLY]}" ]; then
        return 1
    fi
    return 0
}

# Checks for a plugin existence and outputs a message
-zplugin-exists-message() {
    if ! -zplugin-exists "$1" "$2"; then
        -zplugin-any-colorify-as-uspl2 "$1" "$2"
        print "$ZPLG_COL[error]No such plugin$reset_color $REPLY"
        return 1
    fi
    return 0
}

# Checks for a plugin existence, all four formats
# of the plugin specification supported
-zplugin-exists-physically() {
    -zplugin-any-to-user-plugin "$1" "$2"
    [ -d "$ZPLG_PLUGINS_DIR/${reply[1]}---${reply[2]}" ] && return 0 || return 1
}

# Checks for a plugin existence and outputs a message
-zplugin-exists-physically-message() {
    if ! -zplugin-exists-physically "$1" "$2"; then
        -zplugin-any-colorify-as-uspl2 "$1" "$2"
        print "$ZPLG_COL[error]No such plugin directory$reset_color $REPLY"
        return 1
    fi
    return 0
}

# Will take uspl, uspl2, or just plugin name,
# and return colored text
-zplugin-any-colorify-as-uspl2() {
    -zplugin-any-to-user-plugin "$1" "$2"
    local user="$reply[1]" plugin="$reply[2]"
    local ucol="$ZPLG_COL[uname]" pcol="$ZPLG_COL[pname]"
    REPLY="${ucol}${user}$reset_color/${pcol}${plugin}$reset_color"
}

# Prepare readlink command, used e.g. for
# establishing completion's owner
-zplugin-prepare-readline() {
    REPLY=":"
    if type readlink 2>/dev/null 1>&2; then
        REPLY="readlink"
    fi
}

# Both :A and readlink will be used, then readlink's output if
# results differ. This allows to symlink git repositories
# into .zplugin/plugins and have username properly resolved
# (:A will read the link "twice" and give the final repository
# directory, possibly without username in the uspl format;
# readlink will read the link "once")
-zplugin-get-completion-owner() {
    local cpath="$1"
    local readlink_cmd="$2"
    local in_plugin_path tmp

    # Try to go not too deep into resolving the symlink,
    # to have the name as it is in .zplugin/plugins
    # :A goes deep, descends fully to origin directory
    # Readlink just reads what symlink points to
    in_plugin_path="${cpath:A}"
    tmp=$( "$readlink_cmd" "$cpath" )
    [ -n "$tmp" ] && in_plugin_path="$tmp"

    if [ "$in_plugin_path" != "$cpath" ]; then
        # Get the user---plugin part of path -
        # it's right before completion file name
        in_plugin_path="${in_plugin_path:h}"
        in_plugin_path="${in_plugin_path:t}"
    else
        # readlink and :A have nothing
        in_plugin_path="[unknown]"
    fi

    REPLY="$in_plugin_path"
}

# For shortening of code
# $1 - completion file
# $2 - readline command
-zplugin-get-completion-owner-uspl2col() {
    # "cpath" "readline_cmd"
    -zplugin-get-completion-owner "$1" "$2"
    -zplugin-any-colorify-as-uspl2 "$REPLY"
}

# Forget given completions. Done before calling compinit
# $1 - completion function name, e.g. "_cp"
-zplugin-forget-completion() {
    local f="$1"

    typeset -a commands
    commands=( "${(k@)_comps[(R)$f]}" )

    [ "$#commands" -gt 0 ] && print "Forgetting commands completed by \`$f':"

    local k
    for k in "${commands[@]}"; do
        unset "_comps[$k]"
        echo "Unsetting $k"
    done

    print "${ZPLG_COL[info]}Forgetting completion \`$f'...$reset_color"
    print
    unfunction 2>/dev/null "$f"
}

-zplugin-check-comp-consistency() {
    local cfile="$1" bkpfile="$2"
    integer error="$3"

    # bkpfile must be a symlink
    if [[ -e "$bkpfile" && ! -L "$bkpfile" ]]; then
        print "$ZPLG_COL[error]Warning: completion's backup file \`${bkpfile:t}' isn't a symlink$reset_color"
        error=1
    fi

    # cfile must be a symlink
    if [[ -e "$cfile" && ! -L "$cfile" ]]; then
        print "$ZPLG_COL[error]Warning: completion file \`${cfile:t}' isn't a symlink$reset_color"
        error=1
    fi

    # Tell user that he can manually modify but should do it right
    (( error )) && print "$ZPLG_COL[error]Manual edit of $ZPLG_COMPLETIONS_DIR occured?$reset_color"
}

# Searches for completions owned by given plugin
# Returns them in reply array
-zplugin-find-completions-of-plugin() {
    -zplugin-any-to-user-plugin "$1" "$2"
    local user="$reply[1]" plugin="$reply[2]" uspl="${1}---${2}"

    reply=( "$ZPLG_PLUGINS_DIR/$uspl"/_*(N) )
}

# For each positional parameter that each should
# be path to completion within a plugin's dir, it
# checks whether that completion is installed -
# returns 0 or 1 on corresponding positions in reply
-zplugin-check-which-completions-are-installed() {
    local i cfile bkpfile
    reply=( )
    for i in "$@"; do
        cfile="${i:t}"
        bkpfile="${cfile#_}"

        if [[ -e "$ZPLG_COMPLETIONS_DIR"/"$cfile" || -e "$ZPLG_COMPLETIONS_DIR"/"$bkpfile" ]]; then
            reply+=( "1" )
        else
            reply+=( "0" )
        fi
    done
}

# For each positional parameter that each should
# be path to completion within a plugin's dir, it
# checks whether that completion is disabled -
# returns 0 or 1 on corresponding positions in reply
#
# Uninstalled completions will be reported as "0"
# - i.e. disabled
-zplugin-check-which-completions-are-enabled() {
    local i cfile
    reply=( )
    for i in "$@"; do
        cfile="${i:t}"

        if [[ -e "$ZPLG_COMPLETIONS_DIR"/"$cfile" ]]; then
            reply+=( "1" )
        else
            reply+=( "0" )
        fi
    done
}

# Trim the values, taken from $functions or $aliases can be e.g. a single tab
-zplugin-trim-backup-vars() {
    -zplugin-save-set-extendedglob
    [[ "${ZPLG_BACKUP_FUNCTIONS[bindkey]}" = ( |$'\t')# ]] && ZPLG_BACKUP_FUNCTIONS[bindkey]=""
    [[ "${ZPLG_BACKUP_FUNCTIONS[zstyle]}" = ( |$'\t')# ]] && ZPLG_BACKUP_FUNCTIONS[zstyle]=""
    [[ "${ZPLG_BACKUP_FUNCTIONS[alias]}" = ( |$'\t')# ]] && ZPLG_BACKUP_FUNCTIONS[alias]=""
    [[ "${ZPLG_BACKUP_FUNCTIONS[zle]}" = ( |$'\t')# ]] && ZPLG_BACKUP_FUNCTIONS[zle]=""
    [[ "${ZPLG_BACKUP_ALIASES[autoload]}" = ( |$'\t')# ]] && ZPLG_BACKUP_ALIASES[autoload]=""
    [[ "${ZPLG_BACKUP_ALIASES[compdef]}" = ( |$'\t')# ]] && ZPLG_BACKUP_ALIASES[compdef]=""
    -zplugin-restore-extendedglob
}

-zplugin-already-alias-warning-uspl2() {
    -zplugin-add-report "$1" "Warning: there already was \`$2' alias defined, possibly in zshrc"
}

-zplugin-already-function-warning-uspl2() {
    -zplugin-add-report "$1" "Warning: there already was $2() function defined, possibly in zshrc"
}

# }}}

#
# State restoration functions {{{
#

# Saves options
-zplugin-save-enter-state() {
    ZPLG_ENTER_OPTIONS=( )
    [[ -o "KSH_ARRAYS" ]] && ZPLG_ENTER_OPTIONS+=( "KSH_ARRAYS" )
    [[ -o "RC_EXPAND_PARAM" ]] && ZPLG_ENTER_OPTIONS+=( "RC_EXPAND_PARAM" )
    [[ -o "SH_WORD_SPLIT" ]] && ZPLG_ENTER_OPTIONS+=( "SH_WORD_SPLIT" )
    [[ -o "SHORT_LOOPS" ]] && ZPLG_ENTER_OPTIONS+=( "SHORT_LOOPS" )
}

# Restores options
-zplugin-restore-enter-state() {
    for i in "${ZPLG_ENTER_OPTIONS[@]}"; do
        builtin setopt "$i"
    done
}

# Sets state needed by this code
-zplugin-set-desired-shell-state() {
    builtin setopt NO_KSH_ARRAYS
    builtin setopt NO_RC_EXPAND_PARAM
    builtin setopt NO_SH_WORD_SPLIT
    builtin setopt NO_SHORT_LOOPS
}

-zplugin-save-extendedglob() {
    [[ -o "extendedglob" ]] && ZPLG_EXTENDED_GLOB="1" || ZPLG_EXTENDED_GLOB="0"
}

-zplugin-save-set-extendedglob() {
    [[ -o "extendedglob" ]] && ZPLG_EXTENDED_GLOB="1" || ZPLG_EXTENDED_GLOB="0"
    builtin setopt extendedglob
}

-zplugin-restore-extendedglob() {
    [ "$ZPLG_EXTENDED_GLOB" = "1" ] && builtin setopt extendedglob
    [ "$ZPLG_EXTENDED_GLOB" = "0" ] && builtin unsetopt extendedglob
}
# }}}

#
# ZPlugin internal functions {{{
#

-zplugin-prepare-home() {
    [ -n "$ZPLG_HOME_READY" ] && return
    ZPLG_HOME_READY="1"

    [ ! -d "$ZPLG_HOME" ] && command mkdir 2>/dev/null "$ZPLG_HOME"
    [ ! -d "$ZPLG_PLUGINS_DIR" ] && {
        command mkdir "$ZPLG_PLUGINS_DIR"
        # For compaudit
        command chmod g-w "$ZPLG_HOME"
    }
    [ ! -d "$ZPLG_COMPLETIONS_DIR" ] && {
        command mkdir "$ZPLG_COMPLETIONS_DIR"
        # For comaudit
        command chmod g-w "$ZPLG_COMPLETIONS_DIR"

        # Symlink _zplugin completion into _local---zplugin directory
        command mkdir "$ZPLG_PLUGINS_DIR/_local---zplugin"
        command cp "$ZPLG_DIR/_zplugin" "$ZPLG_PLUGINS_DIR/_local---zplugin"
        command ln -s "$ZPLG_PLUGINS_DIR/_local---zplugin/_zplugin" "$ZPLG_COMPLETIONS_DIR"
    }

    # All to the users - simulate OMZ directory structure (2/3)
    [ ! -d "$ZPLG_PLUGINS_DIR/custom" ] && command mkdir "$ZPLG_PLUGINS_DIR/custom" 
    [ ! -d "$ZPLG_PLUGINS_DIR/custom/plugins" ] && command mkdir "$ZPLG_PLUGINS_DIR/custom/plugins" 
}

# $1 - user---plugin, user/plugin, user (if $2 given), or plugin (if $2 empty)
# $2 - plugin (if $1 - user - given)
# $3 - if 1, then reinstall, otherwise only install completions that aren't there
-zplugin-install-completions() {
    local reinstall="${3:-0}"

    -zplugin-any-to-user-plugin "$1" "$2"
    local user="$reply[1]"
    local plugin="$reply[2]"

    -zplugin-exists-physically-message "$user" "$plugin" || return 1

    # Symlink any completion files included in plugin's directory
    typeset -a completions already_symlinked backup_comps
    local c cfile bkpfile
    completions=( "$ZPLG_PLUGINS_DIR/${user}---${plugin}"/_*(N) )
    already_symlinked=( "$ZPLG_COMPLETIONS_DIR"/_*(N) )
    backup_comps=( "$ZPLG_COMPLETIONS_DIR"/[^_]*(N) )

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
            if [ "$reinstall" = "1" ]; then
                # Remove old files
                command rm -f "$ZPLG_COMPLETIONS_DIR/$cfile"
                command rm -f "$ZPLG_COMPLETIONS_DIR/$bkpfile"
            fi
            print "$ZPLG_COL[info]Symlinking completion \`$cfile' to $ZPLG_COMPLETIONS_DIR$reset_color"
            command ln -s "$c" "$ZPLG_COMPLETIONS_DIR/$cfile"
            # Make compinit notice the change
            -zplugin-forget-completion "$cfile"
        else
            print "$ZPLG_COL[error]Not symlinking completion \`$cfile', it already exists$reset_color"
            print "$ZPLG_COL[error]Use \`creinstall' {plugin-name} to force install$reset_color"
        fi
    done
}

# $1 - user---plugin, user/plugin, user (if $2 given), or plugin (if $2 empty)
# $2 - plugin (if $1 - user - given)
-zplugin-uninstall-completions() {
    -zplugin-any-to-user-plugin "$1" "$2"
    local user="$reply[1]"
    local plugin="$reply[2]"

    -zplugin-exists-physically-message "$user" "$plugin" || return 1

    typeset -a completions symlinked backup_comps
    local c cfile bkpfile
    integer action global_action=0

    completions=( "$ZPLG_PLUGINS_DIR/${user}---${plugin}"/_*(N) )
    symlinked=( "$ZPLG_COMPLETIONS_DIR"/_*(N) )
    backup_comps=( "$ZPLG_COMPLETIONS_DIR"/[^_]*(N) )

    # Delete completions if they are really there, either
    # as completions (_fname) or backups (fname)
    for c in "${completions[@]}"; do
        action=0
        cfile="${c:t}"
        bkpfile="${cfile#_}"

        # Remove symlink to completion
        if [[ -n "${symlinked[(r)*/$cfile]}" ]]; then
            command rm -f "$ZPLG_COMPLETIONS_DIR/$cfile"
            action=1
        fi

        # Remove backup symlink (created by cdisable)
        if [[ -n "${backup_comps[(r)*/$bkpfile]}" ]]; then
            command rm -f "$ZPLG_COMPLETIONS_DIR/$bkpfile"
            action=1
        fi

        if (( action )); then
            print "$ZPLG_COL[info]Uninstalling completion \`$cfile'$reset_color"
            # Make compinit notice the change
            -zplugin-forget-completion "$cfile"
            (( global_action ++ ))
        else
            print "$ZPLG_COL[info]Completion \`$cfile' not installed$reset_color"
        fi
    done

    if (( global_action > 0 )); then
        print "$ZPLG_COL[info]Uninstalled $global_action completions$reset_color"
    fi
}

-zplugin-compinit() {
    typeset -a symlinked backup_comps
    local c cfile bkpfile 

    symlinked=( "$ZPLG_COMPLETIONS_DIR"/_*(N) )
    backup_comps=( "$ZPLG_COMPLETIONS_DIR"/[^_]*(N) )

    # Delete completions if they are really there, either
    # as completions (_fname) or backups (fname)
    for c in "${symlinked[@]}" "${backup_comps[@]}"; do
        action=0
        cfile="${c:t}"
        cfile="_${cfile#_}"
        bkpfile="${cfile#_}"

        print "$ZPLG_COL[info]Processing completion $cfile$reset_color"
        -zplugin-forget-completion "$cfile"
    done

    print "Initializing completion (compinit)..."
    compinit
}

-zplugin-setup-plugin-dir() {
    local user="$1" plugin="$2" github_path="$1/$2"
    if [ ! -d "$ZPLG_PLUGINS_DIR/${user}---${plugin}" ]; then
        # Return with error when any problem
        git clone --recursive https://github.com/"$github_path" "$ZPLG_PLUGINS_DIR/${user}---${plugin}" || return 1

        # Install completions
        -zplugin-install-completions "$user" "$plugin" "0"
    fi

    # All to the users - simulate OMZ directory structure (3/3)
    # For now, this will be done every time setup plugin dir is
    # being run, to migrate old setup
    if [ ! -d "$ZPLG_PLUGINS_DIR/custom/plugins/${plugin}" ]; then
        # Remove in case of broken symlink
        command rm -f "$ZPLG_PLUGINS_DIR/custom/plugins/${plugin}"
        command ln -s "../../${user}---${plugin}" "$ZPLG_PLUGINS_DIR/custom/plugins/${plugin}"
    fi

    return 0
}

# TODO detect second autoload?
-zplugin-register-plugin() {
    local light="$3"
    -zplugin-any-to-user-plugin "$1" "$2"
    local user="$reply[1]" plugin="$reply[2]" uspl2="$reply[1]/$reply[2]"
    integer ret=0

    if ! -zplugin-exists "$user" "$plugin"; then
        ZPLG_REGISTERED_PLUGINS+="$uspl2"
    else
        # Allow overwrite-load, however warn about it
        print "Warning: plugin \`$uspl2' already registered, will overwrite-load"
        ret=1
    fi

    # Full or light load?
    [ "$light" = "light" ] && ZPLG_REGISTERED_STATES[$uspl2]="1" || ZPLG_REGISTERED_STATES[$uspl2]="2"

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

-zplugin-unregister-plugin() {
    -zplugin-any-to-user-plugin "$1" "$2"
    local uspl2="$reply[1]/$reply[2]"

    # If not found, idx will be length+1
    local idx="${ZPLG_REGISTERED_PLUGINS[(i)$uspl2]}"
    ZPLG_REGISTERED_PLUGINS[$idx]=()
    ZPLG_REGISTERED_STATES[$uspl2]="0"
}

-zplugin-load-plugin() {
    local user="$1" plugin="$2" light="$3"
    ZPLG_CUR_USER="$user"
    ZPLG_CUR_PLUGIN="$plugin"
    ZPLG_CUR_USPL="${user}---${plugin}"
    ZPLG_CUR_USPL2="${user}/${plugin}"

    # There are plugins having ".plugin.zsh"
    # in ${plugin} directory name, also some
    # have ".zsh" there
    local pdir="${${plugin%.plugin.zsh}%.zsh}"
    local dname="$ZPLG_PLUGINS_DIR/${user}---${plugin}"

    # Look for a file to source
    typeset -a matches
    matches=(
        $dname/$pdir/init.zsh(N) $dname/${pdir}.plugin.zsh(N)
        $dname/${pdir}.zsh-theme(N) $dname/${pdir}.theme.zsh(N)
        $dname/${pdir}.zshplugin(N) $dname/${pdir}.zsh.plugin(N)
        $dname/*.plugin.zsh(N) $dname/*.zsh(N) $dname/*.sh(N)
        $dname/*.zsh-theme(N)
    )
    [ "$#matches" -eq "0" ] && return 1
    local fname="${matches[1]#$dname/}"

    -zplugin-add-report "$ZPLG_CUR_USPL2" "Source $fname"

    # Light load doesn't do diffs and shadowing
    if [ "$light" != "light" ]; then
        -zplugin-diff-functions "$ZPLG_CUR_USPL2" begin
        -zplugin-diff-options "$ZPLG_CUR_USPL2" begin
        -zplugin-diff-env "$ZPLG_CUR_USPL2" begin
    fi
    -zplugin-shadow-on "$light"

    # We need some state, but user wants his for his plugins
    -zplugin-restore-enter-state 
    builtin source "$dname/$fname"
    # Restore our desired state for our operation
    -zplugin-set-desired-shell-state

    -zplugin-shadow-off "$light"
    if [ "$light" != "light" ]; then
        -zplugin-diff-env "$ZPLG_CUR_USPL2" end
        -zplugin-diff-options "$ZPLG_CUR_USPL2" end
        -zplugin-diff-functions "$ZPLG_CUR_USPL2" end
    fi
}

# }}}

#
# User-exposed functions {{{
#

-zplugin-show-completions() {
    typeset -a completions
    completions=( "$ZPLG_COMPLETIONS_DIR"/_*(N) "$ZPLG_COMPLETIONS_DIR"/[^_]*(N) )

    # Find longest completion name
    local cpath c
    integer longest=0
    for cpath in "${completions[@]}"; do
        c="${cpath:t}"
        c="${c#_}"
        [ "$#c" -gt "$longest" ] && longest="$#c"
    done

    #
    # Display - resolves owner of each completion,
    # detects if completion is disabled 
    #

    integer disabled
    for cpath in "${completions[@]}"; do
        c="${cpath:t}"
        [ "${c#_}" = "${c}" ] && disabled=1 || disabled=0
        c="${c#_}"

        # Prepare readlink command for establishing
        # completion's owner
        -zplugin-prepare-readline

        # This will resolve completion's symlink to obtain
        # information about the repository it comes from, i.e.
        # about user and plugin, taken from directory name
        -zplugin-get-completion-owner-uspl2col "$cpath" "$REPLY"

        # Output line of text
        print -n "${(r:longest+1:: :)c} $REPLY"
        (( disabled )) && print -n " $ZPLG_COL[error][disabled]$reset_color"
        print
    done
}

# While -zplugin-show-completions shows what completions are installed,
# this functions searches through all plugin directories showing what's available
-zplugin-search-completions() {
    typeset -a plugin_paths
    plugin_paths=( "$ZPLG_PLUGINS_DIR"/*---* )

    # Find longest plugin name. Things are ran twice here, first pass
    # is to get longest name of plugin which is having any completions
    integer longest=0
    typeset -a completions
    local pp
    for pp in "${plugin_paths[@]}"; do
        completions=( "$pp"/_*(N) )
        if [ "$#completions" -gt 0 ]; then
            local pd="${pp:t}"
            [ "${#pd}" -gt "$longest" ] && longest="${#pd}"
        fi
    done

    for pp in "${plugin_paths[@]}"; do
        completions=( "$pp"/_*(N) )

        if [ "$#completions" -gt 0 ]; then
            # Array of completions, e.g. ( _cp _xauth )
            completions=( "${completions[@]:t}" )
            # Convert directory name to colorified $user/$plugin
            -zplugin-any-colorify-as-uspl2 "${pp:t}"

            # Adjust for escape code (nasty, utilizes fact that
            # $reset_color is used twice, so as a $ZPLG_COL)
            integer adjust_ec=$(( ${#reset_color} * 2 + ${#ZPLG_COL[uname]} + ${#ZPLG_COL[pname]} ))

            print "${(r:longest+adjust_ec:: :)REPLY} ${(j:, :)completions}"
        fi
    done
}

-zplugin-show-report() {
    -zplugin-any-to-user-plugin "$1" "$2"
    local user="$reply[1]"
    local plugin="$reply[2]"

    -zplugin-exists-message "$user" "$plugin" || return 1

    # Print title
    printf "$ZPLG_COL[title]Plugin report for$reset_color %s/%s\n"\
            "$ZPLG_COL[uname]$user$reset_color"\
            "$ZPLG_COL[pname]$plugin$reset_color"

    # Print "----------"
    local msg="Plugin report for $user/$plugin"
    print $ZPLG_COL[bar]"${(r:$#msg::-:)tmp__}"$reset_color

    # Print report gathered via shadowing
    print $ZPLG_REPORTS[${user}/${plugin}]

    # Print report gathered via $functions-diffing
    REPLY=""
    -zplugin-diff-functions "$user/$plugin" diff
    -zplugin-format-functions "$user/$plugin"
    [ -n "$REPLY" ] && print $ZPLG_COL[p]"Functions created:$reset_color"$'\n'"$REPLY"

    # Print report gathered via $options-diffing
    REPLY=""
    -zplugin-diff-options "$user/$plugin" diff
    -zplugin-format-options "$user/$plugin"
    [ -n "$REPLY" ] && print $ZPLG_COL[p]"Options changed:$reset_color"$'\n'"$REPLY"

    # Print report gathered via environment diffing
    REPLY=""
    -zplugin-diff-env "$user/$plugin" diff
    -zplugin-format-env "$user/$plugin" "1"
    [ -n "$REPLY" ] && print $ZPLG_COL[p]"PATH elements added:$reset_color"$'\n'"$REPLY"

    REPLY=""
    -zplugin-format-env "$user/$plugin" "2"
    [ -n "$REPLY" ] && print $ZPLG_COL[p]"FPATH elements added:$reset_color"$'\n'"$REPLY"

    # Print what completions plugin has
    -zplugin-find-completions-of-plugin "$user" "$plugin"
    typeset -a completions
    completions=( "${reply[@]}" )

    if [ "$#completions" -ge "1" ]; then
        print "${ZPLG_COL[p]}Completions:$reset_color"
        -zplugin-check-which-completions-are-installed "${completions[@]}"
        typeset -a installed
        installed=( "${reply[@]}" )

        -zplugin-check-which-completions-are-enabled "${completions[@]}"
        typeset -a enabled
        enabled=( "${reply[@]}" )

        integer count="$#completions" idx
        for (( idx=1; idx <= count; idx ++ )); do
            print -n "${completions[idx]:t}"
            if [ "${installed[idx]}" != "1" ]; then
                print -n " ${ZPLG_COL[uninst]}[not installed]$reset_color"
            else
                if [ "${enabled[idx]}" = "1" ]; then
                    print -n " ${ZPLG_COL[info]}[enabled]$reset_color"
                else
                    print -n " ${ZPLG_COL[error]}[disabled]$reset_color"
                fi
            fi
            print
        done
        print
    fi
}

-zplugin-show-all-reports() {
    local i
    for i in "${ZPLG_REGISTERED_PLUGINS[@]}"; do
        [ "$i" = "_local/$ZPLG_NAME" ] && continue
        -zplugin-show-report "$i"
    done
}

-zplugin-show-registered-plugins() {
    typeset -a filtered
    local keyword="$1"

    -zplugin-save-set-extendedglob
    keyword="${keyword## ##}"
    keyword="${keyword%% ##}"
    if [ -n "$keyword" ]; then
        echo "Installed plugins matching $ZPLG_COL[info]$keyword$reset_color:"
        filtered=( "${(M)ZPLG_REGISTERED_PLUGINS[@]:#*$keyword*}" )
    else
        filtered=( "${ZPLG_REGISTERED_PLUGINS[@]}" )
    fi
    -zplugin-restore-extendedglob

    local i
    for i in "${filtered[@]}"; do
        # Skip _local/psprint
        [ "$i" = "_local/zplugin" ] && continue
        -zplugin-any-colorify-as-uspl2 "$i"
        # Mark light loads
        [ "${ZPLG_REGISTERED_STATES[$i]}" = "1" ] && REPLY="$REPLY ${ZPLG_COL[info]}*$reset_color"
        print "$REPLY"
    done
}

-zplugin-cenable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZPLG_COMPLETIONS_DIR}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        print "$ZPLG_COL[error]No such completion \`$c'$reset_color"
        return 1
    fi

    # Check if there is no backup file
    # This is treated as if the completion is already enabled
    if [ ! -e "$bkpfile" ]; then
        print "Completion $ZPLG_COL[info]$c$reset_color already enabled"

        -zplugin-check-comp-consistency "$cfile" "$bkpfile" 0
        return 1
    fi

    # Disabled, but completion file already exists?
    if [ -e "$cfile" ]; then
        print "$ZPLG_COL[error]Warning: completion's file \`${cfile:t}' exists, will overwrite$reset_color"
        print "$ZPLG_COL[error]Completion is actually enabled and will re-enable it again$reset_color"
        -zplugin-check-comp-consistency "$cfile" "$bkpfile" 1
        command rm -f "$cfile"
    else
        -zplugin-check-comp-consistency "$cfile" "$bkpfile" 0
    fi

    # Enable
    command mv "$bkpfile" "$cfile" # move completion's backup file created when disabling

    # Prepare readlink command for establishing completion's owner
    -zplugin-prepare-readline
    # Get completion's owning plugin
    -zplugin-get-completion-owner-uspl2col "$cfile" "$REPLY"

    print "Enabled $ZPLG_COL[info]$c$reset_color completion belonging to $REPLY"

    return 0
}

-zplugin-cdisable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZPLG_COMPLETIONS_DIR}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        print "$ZPLG_COL[error]No such completion \`$c'$reset_color"
        return 1
    fi

    # Check if it's already disabled
    # Not existing "$cfile" says that
    if [[ ! -e "$cfile" ]]; then
        print "Completion $ZPLG_COL[info]$c$reset_color already disabled"

        -zplugin-check-comp-consistency "$cfile" "$bkpfile" 0
        return 1
    fi

    # No disable, but bkpfile exists?
    if [ -e "$bkpfile" ]; then
        print "$ZPLG_COL[error]Warning: completion's backup file \`${bkpfile:t}' already exists, will overwrite$reset_color"
        -zplugin-check-comp-consistency "$cfile" "$bkpfile" 1
        command rm -f "$bkpfile"
    else
        -zplugin-check-comp-consistency "$cfile" "$bkpfile" 0
    fi

    # Disable
    command mv "$cfile" "$bkpfile"

    # Prepare readlink command for establishing completion's owner
    -zplugin-prepare-readline
    # Get completion's owning plugin
    -zplugin-get-completion-owner-uspl2col "$bkpfile" "$REPLY"

    print "Disabled $ZPLG_COL[info]$c$reset_color completion belonging to $REPLY"

    return 0
}

# $1 - plugin name, possibly github path
-zplugin-load () {
    -zplugin-any-to-user-plugin "$1" "$2"
    local user="$reply[1]" plugin="$reply[2]"
    local light="$3"

    -zplugin-register-plugin "$user" "$plugin" "$light"
    if ! -zplugin-setup-plugin-dir "$user" "$plugin"; then
        -zplugin-unregister-plugin "$user" "$plugin"
    else
        -zplugin-load-plugin "$user" "$plugin" "$light"
    fi
}

# $1 - user---plugin, user/plugin, user (if $2 given), or plugin (if $2 empty)
# $2 - plugin (if $1 - user - given)
#
# 1. Unfunction functions created by plugin
# 2. Delete bindkeys
# 3. Delete created Zstyles
# 4. Restore options
# 5. Restore (or just unalias?) aliases
# 6. Restore Zle state
# 7. Clean up FPATH and PATH
# 8. Forget the plugin
-zplugin-unload() {
    -zplugin-exists-message "$1" "$2" || return 1

    -zplugin-any-to-user-plugin "$1" "$2"
    local uspl2="$reply[1]/$reply[2]" user="$reply[1]" plugin="$reply[2]"

    -zplugin-any-colorify-as-uspl2 "$1" "$2"
    local uspl2col="$REPLY"

    # Store report of the plugin in variable LASTREPORT
    LASTREPORT=`-zplugin-show-report "$1" "$2"`

    #
    # 1. Unfunction
    #

    -zplugin-diff-functions "$uspl2" diff
    typeset -a func
    func=( "${(z)ZPLG_FUNCTIONS[$uspl2]}" )
    local f
    for f in "${(on)func[@]}"; do
        [ -z "$f" ] && continue
        f="${(Q)f}"
        print "Deleting function $f"
        unfunction "$f"
    done

    #
    # 2. Delete done bindkeys
    #

    typeset -a string_widget
    string_widget=( "${(z)ZPLG_BINDKEYS[$uspl2]}" )
    local sw
    for sw in "${(on)string_widget[@]}"; do
        [ -z "$sw" ] && continue
        # Remove one level of quoting to split using (z)
        sw="${(Q)sw}"
        typeset -a sw_arr
        sw_arr=( "${(z)sw}" )

        # Remove one level of quoting to pass to bindkey
        sw_arr[1]="${(Q)sw_arr[1]}" # Keys
        sw_arr[2]="${(Q)sw_arr[2]}" # Widget
        sw_arr[3]="${(Q)sw_arr[3]}" # Optional -M
        sw_arr[4]="${(Q)sw_arr[4]}" # Optional map name
        sw_arr[5]="${(Q)sw_arr[5]}" # Optional -R

        if [[ "${sw_arr[3]}" = "-M" && "${sw_arr[5]}" != "-R" ]]; then
            print "Deleting bindkey ${sw_arr[1]} ${sw_arr[2]} ${ZPLG_COL[info]}mapped to ${sw_arr[4]}$reset_color"
            bindkey -M "${sw_arr[4]}" -r "${sw_arr[1]}"
        elif [[ "${sw_arr[3]}" = "-M" && "${sw_arr[5]}" = "-R" ]]; then
            print "Deleting ${ZPLG_COL[info]}range$reset_color bindkey ${sw_arr[1]} ${sw_arr[2]} ${ZPLG_COL[info]}mapped to ${sw_arr[4]}$reset_color"
            bindkey -M "${sw_arr[4]}" -Rr "${sw_arr[1]}"
        elif [[ "${sw_arr[3]}" != "-M" && "${sw_arr[5]}" = "-R" ]]; then
            print "Deleting ${ZPLG_COL[info]}range$reset_color bindkey ${sw_arr[1]} ${sw_arr[2]}" 
            bindkey -Rr "${sw_arr[1]}"
        else
            print "Deleting bindkey ${sw_arr[1]} ${sw_arr[2]}"
            bindkey -r "${sw_arr[1]}"
        fi
    done

    #
    # 3. Delete created Zstyles
    #

    typeset -a pattern_style
    pattern_style=( "${(z)ZPLG_ZSTYLES[$uspl2]}" )
    local ps
    for ps in "${(on)pattern_style[@]}"; do
        [ -z "$ps" ] && continue
        # Remove one level of quoting to split using (z)
        ps="${(Q)ps}"
        typeset -a ps_arr
        ps_arr=( "${(z)ps}" )

        # Remove one level of quoting to pass to zstyle
        ps_arr[1]="${(Q)ps_arr[1]}"
        ps_arr[2]="${(Q)ps_arr[2]}"

        print "Deleting zstyle ${ps_arr[1]} ${ps_arr[2]}"

        zstyle -d "${ps_arr[1]}" "${ps_arr[2]}"
    done

    #
    # 4. Restore changed options
    #

    # Paranoid, don't want bad key/value pair error
    -zplugin-diff-options "$uspl2" diff
    integer empty=0
    -zplugin-save-set-extendedglob
    [[ "${ZPLG_OPTIONS[$uspl2]}" = ( |$'\t')# ]] && empty=1
    -zplugin-restore-extendedglob

    if (( empty != 1 )); then
        typeset -A opts
        opts=( "${(z)ZPLG_OPTIONS[$uspl2]}" )
        local k
        for k in "${(kon)opts[@]}"; do
            # Internal options
            [ "$k" = "physical" ] && continue

            if [ "${opts[$k]}" = "on" ]; then
                print "Setting option $k"
                setopt "$k"
            else
                print "Unsetting option $k"
                unsetopt "$k"
            fi
        done
    fi

    #
    # 5. Delete aliases
    #

    typeset -a aname_avalue
    aname_avalue=( "${(z)ZPLG_ALIASES[$uspl2]}" )
    local nv
    for nv in "${(on)aname_avalue[@]}"; do
        [ -z "$nv" ] && continue
        # Remove one level of quoting to split using (z)
        nv="${(Q)nv}"
        typeset -a nv_arr
        nv_arr=( "${(z)nv}" )

        # Remove one level of quoting to pass to unalias
        nv_arr[1]="${(Q)nv_arr[1]}"
        nv_arr[2]="${(Q)nv_arr[2]}"
        nv_arr[3]="${(Q)nv_arr[3]}"

        if [ "${nv_arr[3]}" = "-s" ]; then
            print "Removing ${ZPLG_COL[info]}suffix$reset_color alias ${nv_arr[1]}=${nv_arr[2]}"
            unalias -s "${nv_arr[1]}"
        elif [ "${nv_arr[3]}" = "-g" ]; then
            print "Removing ${ZPLG_COL[info]}global$reset_color alias ${nv_arr[1]}=${nv_arr[2]}"
            unalias "${(q)nv_arr[1]}"
        else
            print "Removing alias ${nv_arr[1]}=${nv_arr[2]}"
            unalias "${nv_arr[1]}"
        fi
    done

    #
    # 6. Restore Zle state
    #

    typeset -a delete_widgets
    delete_widgets=( "${(z)ZPLG_WIDGETS_DELETE[$uspl2]}" )
    local wid
    for wid in "${(on)delete_widgets[@]}"; do
        [ -z "$wid" ] && continue
        wid="${(Q)wid}"
        print "Removing Zle hook $wid"
        zle -D "$wid"
    done

    typeset -a restore_widgets
    restore_widgets=( "${(z)ZPLG_WIDGETS_SAVED[$uspl2]}" )
    for wid in "${(on)restore_widgets[@]}"; do
        [ -z "$wid" ] && continue
        wid="${(Q)wid}"
        typeset -a orig_saved
        orig_saved=( "${(z)wid}" )
        orig_saved[1]="${(Q)orig_saved[1]}" # Original widget
        orig_saved[2]="${(Q)orig_saved[2]}" # Saved widget

        print "Restoring Zle widget ${orig_saved[1]}"
        zle -A "${orig_saved[2]}" "${orig_saved[1]}"
        zle -D "${orig_saved[2]}"
    done

    #
    # 7. Clean up FPATH and PATH
    #

    -zplugin-diff-env "$uspl2" diff

    # Have to iterate over $path elements and
    # skip those that were added by the plugin
    typeset -a new elem p
    elem=( "${(z)ZPLG_PATH[$uspl2]}" )
    for p in "${path[@]}"; do
        [ -z "${elem[(r)$p]}" ] && new+=( "$p" ) || print "Removing PATH element $ZPLG_COL[info]$p$reset_color"
    done
    path=( "${new[@]}" )

    # The same for $fpath
    elem=( "${(z)ZPLG_FPATH[$uspl2]}" )
    new=( )
    for p in "${fpath[@]}"; do
        [ -z "${elem[(r)$p]}" ] && new+=( "$p" ) || print "Removing FPATH element $ZPLG_COL[info]$p$reset_color"
    done
    fpath=( "${new[@]}" )

    #
    # 8. Forget the plugin
    #

    print "Unregistering plugin $uspl2col"
    -zplugin-unregister-plugin "$user" "$plugin"

    print "Plugin's report saved to \$LASTREPORT"
}

# Updates given plugin
-zplugin-update-or-status() {
    local st="$1"
    -zplugin-any-to-user-plugin "$2" "$3"
    local user="$reply[1]" plugin="$reply[2]"

    -zplugin-exists-physically-message "$user" "$plugin" || return 1

    if [ "$st" = "status" ]; then
        ( cd "$ZPLG_PLUGINS_DIR/${user}---${plugin}" ; git status )
    else
        ( cd "$ZPLG_PLUGINS_DIR/${user}---${plugin}" ; git pull )
    fi
}

-zplugin-update-or-status-all() {
    local st="$1"
    local repo pd user plugin

    if [ "$st" = "status" ]; then
        echo "${ZPLG_COL[error]}Warning:$reset_color status done also for unloaded plugins"
    else
        echo "${ZPLG_COL[error]}Warning:$reset_color updating also unloaded plugins"
    fi

    for repo in "$ZPLG_PLUGINS_DIR"/*(N); do
        pd="${repo:t}"

        # Two special cases
        [ "$pd" = "_local---zplugin" ] && continue
        [ "$pd" = "custom" ] && continue

        -zplugin-any-colorify-as-uspl2 "$pd"

        # Must be a git repository
        if [ ! -d "$repo/.git" ]; then
            print "\n$REPLY not a git repository"
            continue
        fi

        if [ "$st" = "status" ]; then
            print "\nStatus for plugin $REPLY"
            ( cd "$repo"; git status )
        else
            print "\nUpdating plugin $REPLY"
            ( cd "$repo"; git pull )
        fi
    done
}

# Updates Zplugin
-zplugin-self-update() {
    ( cd "$ZPLG_DIR" ; git pull )
}

# }}}

alias zpl=zplugin zplg=zplugin

# Main function with subcommands
zplugin() {
    -zplugin-save-enter-state

    # Restore user's options on any exit
    trap 'return 1' INT TERM
    trap '-zplugin-restore-enter-state' EXIT

    -zplugin-set-desired-shell-state

    -zplugin-prepare-home

    # Simulate existence of _local/zplugin module
    # This will allow to cuninstall of its completion
    ZPLG_REGISTERED_PLUGINS+="_local/$ZPLG_NAME"
    ZPLG_REGISTERED_PLUGINS=( "${(u)ZPLG_REGISTERED_PLUGINS[@]}" )
    # _zplugin module is loaded lightly
    ZPLG_REGISTERED_STATES[_local/$ZPLG_NAME]="1"

    # Add completions directory to fpath
    fpath=( "$ZPLG_COMPLETIONS_DIR" "${fpath[@]}" )
    # Uniquify
    fpath=( "${(u)fpath[@]}" )

    case "$1" in
       (self-update)
           -zplugin-self-update
           ;;
       (load)
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # Load plugin given in uspl2 or "user plugin" format
           # Possibly clone from github, and install completions
           -zplugin-load "$2" "$3"
           ;;
       (light)
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # This is light load, without tracking, only with
           # clean FPATH (autoload is still being shadowed)
           -zplugin-load "$2" "$3" "light"
           ;;
       (unload)
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # Unload given plugin. Cloned directory remains intact
           # so as are completions
           -zplugin-unload "$2" "$3"
           ;;
       (update)
           -zplugin-update-or-status "update" "$2" "$3"
           ;;
       (update-all)
           -zplugin-update-or-status-all "update"
           ;;
       (status)
           -zplugin-update-or-status "status" "$2" "$3"
           ;;
       (status-all)
           -zplugin-update-or-status-all "status"
           ;;
       (report)
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # Display report of given plugin
           -zplugin-show-report "$2" "$3"
           ;;
       (all-reports)
           # Display reports of all plugins
           -zplugin-show-all-reports
           ;;
       (loaded|list)
           # Show list of loaded plugins
           -zplugin-show-registered-plugins "$2"
           ;;
       (clist|completions)
           # Show installed, enabled or disabled, completions
           -zplugin-show-completions
           ;;
       (cdisable)
           if [[ -z "$2" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           local f="_${2#_}"
           # Disable completion given by completion function name
           # with or without leading "_", e.g. "cp", "_cp"
           if -zplugin-cdisable "$f"; then
               -zplugin-forget-completion "$f"
               print "Initializing completion system (compinit)..."
               compinit
           fi
           ;;
       (cenable)
           if [[ -z "$2" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           local f="_${2#_}"
           # Enable completion given by completion function name
           # with or without leading "_", e.g. "cp", "_cp"
           if -zplugin-cenable "$f"; then
               -zplugin-forget-completion "$f"
               print "Initializing completion system (compinit)..."
               compinit
           fi
           ;;
       (creinstall)
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # Installs completions for plugin. Enables them all. It's a
           # reinstallation, thus every obstacle gets overwritten or removed
           -zplugin-install-completions "$2" "$3" "1"
           print "Initializing completion (compinit)..."
           compinit
           ;;
       (cuninstall)
           if [[ -z "$2" && -z "$3" ]]; then
               print "Argument needed, try help"
               return 1
           fi
           # Uninstalls completions for plugin
           -zplugin-uninstall-completions "$2" "$3"
           print "Initializing completion (compinit)..."
           compinit
           ;;
       (csearch)
           -zplugin-search-completions
           ;;
       (compinit)
           # Runs compinit in a way that ensures
           # reload of plugins' completions
           -zplugin-compinit
           ;;

       (-h|--help|help|)
           print "$ZPLG_COL[p]Usage$reset_color:
-h|--help|help           - usage information
self-update              - updates Zplugin
load $ZPLG_COL[pname]{plugin-name}$reset_color       - load plugin
light $ZPLG_COL[pname]{plugin-name}$reset_color      - light plugin load, without reporting
unload $ZPLG_COL[pname]{plugin-name}$reset_color     - unload plugin
update $ZPLG_COL[pname]{plugin-name}$reset_color     - update plugin (Git)
update-all               - update all plugins (Git)
status $ZPLG_COL[pname]{plugin-name}$reset_color     - status for plugin (Git)
status-all               - status for all plugins (Git)
report $ZPLG_COL[pname]{plugin-name}$reset_color     - show plugin's report
all-reports              - show all plugin reports
loaded|list [keyword]    - show what plugins are loaded (filter with \'keyword')
clist|completions        - list completions in use
cdisable $ZPLG_COL[info]{cname}$reset_color         - disable completion \`cname'
cenable  $ZPLG_COL[info]{cname}$reset_color         - enable completion \`cname'
creinstall $ZPLG_COL[pname]{plugin-name}$reset_color - install completions for plugin
cuninstall $ZPLG_COL[pname]{plugin-name}$reset_color - uninstall completions for plugin
csearch                  - search for available completions from any plugin
compinit                 - refresh installed completions"
           ;;
       (*)
           print "Unknown command \`$1' (try \`help' to get usage information)"
           ;;
    esac
}

# Colorize completions for commands unload, report, creinstall, cuninstall
zstyle ':completion:*:zplugin:*:argument-rest' list-colors '=(#b)(*)/(*)==1;35=1;33'
