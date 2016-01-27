# -*- mode: shell-script -*-
# vim:ft=zsh

#
# Main state variables
#

typeset -gaH ZPLG_REGISTERED_PLUGINS
typeset -gAH ZPLG_REPORTS

#
# Common needed values
#

typeset -gH ZPLG_HOME="$HOME/.zplugin"
typeset -gH ZPLG_PLUGINS_DIR="$ZPLG_HOME/plugins"
typeset -gH ZPLG_COMPLETIONS_DIR="$ZPLG_HOME/completions"
typeset -gH ZPLG_HOME_READY

#
# All to the users - simulate OMZ directory structure (1/3)
#

typeset -gH ZSH="$ZPLG_PLUGINS_DIR"
typeset -gH ZSH_CUSTOM="$ZPLG_PLUGINS_DIR/custom"
export ZSH ZSH_CUSTOM

#
# Nasty variables, can be used by any shadowing function to recognize current context
#

typeset -gH ZPLG_CUR_USER=""
typeset -gH ZPLG_CUR_PLUGIN=""
# Concatenated with "--"
typeset -gH ZPLG_CUR_USPL=""
# Concatenated with "/"
typeset -gH ZPLG_CUR_USPL2=""

#
# Function diffing
#

# Used to hold declared functions existing before loading a plugin
typeset -gAH ZPLG_FUNCTIONS_BEFORE
# Functions existing after loading a plugin. Reporting will do a diff
typeset -gAH ZPLG_FUNCTIONS_AFTER
# Functions computed to be associated with plugin
typeset -gAH ZPLG_FUNCTIONS

#
# Zstyle, bindkey remembering
#

# Holds concatenated Zstyles declared by each plugin
# Concatenated after quoting, so (z)-splittable
typeset -gAH ZPLG_ZSTYLES

# Holds concatenated bindkeys declared by each plugin
typeset -gAH ZPLG_BINDKEYS

# Holds concatenated aliases declared by each plugin
typeset -gAH ZPLG_ALIASES

# Holds concatenated options declared by each plugin
typeset -gAH ZPLG_OPTIONS

#
# End of global variable declarations
#

zmodload zsh/zutil || return 1
zmodload zsh/parameter || return 1
zmodload zsh/terminfo 2>/dev/null
zmodload zsh/termcap 2>/dev/null

if [[ -n "$terminfo[colors]" || "$termcap[Co]" ]]; then
    autoload colors
    colors
fi

typeset -gAH ZPLG_COLORS
ZPLG_COLORS=(
    "title" ""
    "pname" "$fg_bold[yellow]"
    "uname" "$fg_bold[magenta]"
    "keyword" "$fg_bold[green]"
    "error" "$fg_bold[red]"
    "p" "$fg_bold[blue]"
    "bar" "$fg_bold[magenta]"
    "info" "$fg_bold[green]"
)

#
# Shadowing-related functions (names of substitute functions start with -) {{{
#

-zplugin_reload_and_run () {
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

-zplugin-shadow-autoload () {
    local -a opts
    local func

    zparseopts -a opts -D ${(s::):-TUXkmtzw}

    if (( $opts[(I)(-|+)X] ))
    then
        _zplugin-add-report "$ZPLG_CUR_USPL2" "Failed autoload $opts $*"
        print -u2 "builtin autoload required for $opts"
        return 1
    fi
    if (( $opts[(I)-w] ))
    then
        _zplugin-add-report "$ZPLG_CUR_USPL2" "-w-Autoload $opts $*"
        builtin autoload $opts "$@"
        return
    fi

    # Report ZPLUGIN's "native" autoloads
    local i
    for i in "$@"; do
        local msg="Autoload $i"
        [ -n "$opts" ] && msg+=" with options $opts"
        _zplugin-add-report "$ZPLG_CUR_USPL2" "$msg"
    done

    # Do ZPLUGIN's "native" autoloads
    local PLUGIN_DIR="$ZPLG_PLUGINS_DIR/${ZPLG_CUR_USPL}"
    for func
    do
        eval "function $func {
            -zplugin_reload_and_run ${(q)PLUGIN_DIR} ${(qq)opts} ${(q)func} "'"$@"
        }'
        #functions[$func]="-zplugin_reload_and_run ${(q)PLUGIN_DIR} ${(qq)opts} ${(q)func} "'"$@"'
    done
}

-zplugin-shadow-bindkey() {
    _zplugin-add-report "$ZPLG_CUR_USPL2" "Bindkey $*"

    # Remember to perform the actual bindkey call
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular bindkey call, i.e.
    # with no options or with -s, plus possible -M
    # option
    local -A optsA
    zparseopts -A optsA -D ${(s::):-lLdDANmrseva} "M:"

    local -a opts
    opts=( "${(k)optsA[@]}" )

    if [[ "$#opts" -eq "0" ||
        ( "$#opts" -eq "1" && ${opts[1]} = "-M" ) ||
        ( "$#opts" -eq "1" && ${opts[1]} = "-s" ) ||
        ( "$#opts" -le "2" && "${opts[(r)-M]}" = "-M" && "${opts[(r)-s]}" = "-s" )
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

        quoted="${(q)quoted}"

        # Remember the zstyle
        ZPLG_BINDKEYS[$ZPLG_CUR_USPL2]+="$quoted "
    else
        _zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: last bindkey used non-typical options $opts[*]"
    fi

    # Actual bindkey
    builtin bindkey "${pos[@]}"
}

-zplugin-shadow-setopt() {
    _zplugin-add-report "$ZPLG_CUR_USPL2" "Setopt $*"

    # Remember to perform the actual setopt call
    typeset -a pos
    pos=( "$@" )

    local opt quoted prefix option
    integer next_is_option=0 was_minus_o=0

    for opt in "$@"; do
        if (( next_is_option > 0 )); then
            next_is_option=0
            prefix=""
            option="$opt"
        else
            prefix="${opt%%(#m)[a-zA-Z0-9_ \t]##}"
            option="$MATCH"
        fi

        if [[ "$prefix" = "-" || "$prefix" = "+" ]]; then
            if [ "$option[1]" = "o" ]; then
                if [ "$#option" -gt 1 ]; then
                    option="${option[2,-1]}"
                    # Store current state of option given right after -o
                    [[ -o "$option" ]] && quoted="$option" || quoted="no$option"
                else
                    # Zsh doesn't support "-o option" after "option" in single setopt call
                    was_minus_o=1
                    [ "$prefix" = "-" ] && next_is_option=1 || next_is_option=2
                    continue
                fi
            else
                # Short option format?
                if [ "$#option" != "1" ]; then
                    # Unsupported option format
                    _zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: unsupported option format ($prefix$option)"
                    continue
                fi

                # Store current state of option given in short format
                [[ -n ${-[(r)$option]} ]] && quoted="-$option" || quoted="+$option"
            fi
        else
            (( was_minus_o )) && _zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: options given in one line"\
                                                                       "in a way setopt doesn't support"
            [ -n "$prefix" ] && _zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: incorrect option ($prefix$option)"
            # Store current state of option
            [[ -o "$option" ]] && quoted="$option" || quoted="no$option"
        fi

        quoted="${quoted//nono/}"
        quoted="${(q)quoted}"
        ZPLG_OPTIONS[$ZPLG_CUR_USPL2]+="$quoted "
    done

    # Actual setopt
    builtin setopt "${pos[@]}"
}

-zplugin-shadow-zstyle() {
    _zplugin-add-report "$ZPLG_CUR_USPL2" "Zstyle $*"

    # Remember to perform the actual zstyle call
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular zstyle call, i.e.
    # with no options or with -e
    local -a opts
    zparseopts -a opts -D ${(s::):-eLdgabsTtm}

    if [[ "$#opts" -eq 0 || ( "$#opts" -eq 1 && ${opts[1]} = "-e" ) ]]; then
        # Have to quote $1, ten $2, then concatenate them, then quote them again
        local pattern="${(q)1}" style="${(q)2}"
        local ps="$pattern $style"
        ps="${(q)ps}"

        # Remember the zstyle
        ZPLG_ZSTYLES[$ZPLG_CUR_USPL2]+="$ps "
    else
        _zplugin-add-report "$ZPLG_CUR_USPL2" "Warning: last zstyle used non-typical options: $opts[*]"
    fi

    # Actual zstyle
    builtin zstyle "${pos[@]}"
}

-zplugin-shadow-alias() {
    _zplugin-add-report "$ZPLG_CUR_USPL2" "Alias $*"

    # Remember to perform the actual alias call
    typeset -a pos
    pos=( "$@" )

    local -a opts
    zparseopts -a opts -D ${(s::):-gs}

    local a quoted tmp
    for a in "$@"; do
        local aname="${a%%=*}"
        local avalue="${a#*=}"

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

-zplugin-shadow-zle() {
    _zplugin-add-report "$ZPLG_CUR_USPL2" "Zle $*"

    # Actual zle
    builtin zle "$@"
}

# Shadowing on
_zplugin-shadow-on() {
    alias autoload=-zplugin-shadow-autoload
    alias bindkey=-zplugin-shadow-bindkey
    alias setopt=-zplugin-shadow-setopt
    alias zstyle=-zplugin-shadow-zstyle
    alias alias=-zplugin-shadow-alias
    alias zle=-zplugin-shadow-zle
}

# Shadowing off
_zplugin-shadow-off() {
    unalias     autoload bindkey setopt zstyle alias zle
}

# }}}

#
# Diff functions {{{
#

# Can remember current $functions twice, and compute the
# difference, storing it in ZPLG_FUNCTIONS, associated
# with given ($1) plugin
_zplugin-diff-functions() {
    local uspl2="$1"
    local cmd="$2"

    if [[ "$cmd" = "begin" || "$cmd" = "end" ]]; then
            typeset -a func
            func=( "${(onk)functions[@]}" )
            func=( "${(q)func[@]}" )
    fi

    REPLY=""

    case "$cmd" in
        begin)
            ZPLG_FUNCTIONS_BEFORE[$uspl2]="$func[*]"
            ;;
        end)
            ZPLG_FUNCTIONS_AFTER[$uspl2]="$func[*]"
            ;;
        diff)
            typeset -A func
            local i

            # This includes new functions
            for i in "${(z)ZPLG_FUNCTIONS_AFTER[$uspl2]}"; do
                func[$i]=1
            done

            # Remove duplicated entries, i.e. existing before
            for i in "${(z)ZPLG_FUNCTIONS_BEFORE[$uspl2]}"; do
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
}

# Creates a one or two columns text with functions
# belonging to given ($1) plugin
_zplugin-format-functions() {
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
                answer+=`print -n "${(r:longest_left+1:: :)f}"`
            else
                answer+=`print -n "$f"`$'\n'
            fi
        else
            answer+="$f"$'\n'
        fi
    done
    REPLY="$answer"
    (( COLUMNS >= longest && count % 2 == 0 )) && REPLY="$REPLY"$'\n'
}

# }}}

#
# Report functions {{{
#

_zplugin-add-report() {
    local uspl2="$1"
    shift
    local txt="$*"

    local keyword="${txt%% *}"
    if [[ "$keyword" = "Failed" || "$keyword" = "Warning:" ]]; then
        keyword="$ZPLG_COLORS[error]$keyword$reset_color"
    else
        keyword="$ZPLG_COLORS[keyword]$keyword$reset_color"
    fi

    ZPLG_REPORTS[$uspl2]+="$keyword ${txt#* }"$'\n'
}

# }}}

#
# ZPlugin internal functions {{{
#

_zplugin-prepare-home() {
    [ -n "$ZPLG_HOME_READY" ] && return
    ZPLG_HOME_READY="1"

    [ ! -d "$ZPLG_HOME" ] && mkdir 2>/dev/null "$ZPLG_HOME"
    [ ! -d "$ZPLG_PLUGINS_DIR" ] && {
        mkdir 2>/dev/null "$ZPLG_PLUGINS_DIR"
        # For compaudit
        chmod g-w "$ZPLG_HOME"
    }
    [ ! -d "$ZPLG_COMPLETIONS_DIR" ] && {
        mkdir 2>/dev/null "$ZPLG_COMPLETIONS_DIR"
        # For comaudit
        chmod g-w "$ZPLG_COMPLETIONS_DIR"
    }

    # All to the users - simulate OMZ directory structure (2/3)
    [ ! -d "$ZPLG_PLUGINS_DIR/custom" ] && mkdir 2>/dev/null "$ZPLG_PLUGINS_DIR/custom" 
    [ ! -d "$ZPLG_PLUGINS_DIR/custom/plugins" ] && mkdir 2>/dev/null "$ZPLG_PLUGINS_DIR/custom/plugins" 
}

_zplugin-setup-plugin-dir() {
    local user="$1" plugin="$2" github_path="$1/$2"
    if [ ! -d "$ZPLG_PLUGINS_DIR/${user}--${plugin}" ]; then
        git clone https://github.com/"$github_path" "$ZPLG_PLUGINS_DIR/${user}--${plugin}"
    fi

    # Simlink any completion files included in plugin's directory
    typeset -a completions already_simlinked backup_comps c cfile bkpfile
    completions=( "$ZPLG_PLUGINS_DIR/${user}--${plugin}"/_*(N) )
    already_simlinked=( "$ZPLG_COMPLETIONS_DIR"/_*(N) )
    backup_comps=( "$ZPLG_COMPLETIONS_DIR"/[^_]*(N) )

    # Simlink completions if they are not already there
    # either as completions (_fname) or as backups (fname)
    for c in "${completions[@]}"; do
        cfile="${c:t}"
        bkpfile="${cfile#_}"
        if [[ -z "${already_simlinked[(r)*/$cfile]}" && -z "${backup_comps[(r)*/$bkpfile]}" ]]; then
            echo "Simlinking completion $cfile to $ZPLG_COMPLETIONS_DIR"
            ln -s "$c" "$ZPLG_COMPLETIONS_DIR/$cfile"
        fi
    done

    # All to the users - simulate OMZ directory structure (3/3)
    if [ ! -d "$ZPLG_PLUGINS_DIR/custom/plugins/${plugin}" ]; then
        ln -s "../../${user}--${plugin}" "$ZPLG_PLUGINS_DIR/custom/plugins/${plugin}"
    fi
}

# TODO detect second autoload?
_zplugin-register-plugin() {
    [ -z "ZPLG_REPORTS[${user}/${plugin}]" ] && ZPLG_REPORTS[${user}/${plugin}]=""
    ZPLG_REGISTERED_PLUGINS+="${1}/${2}"
}

_zplugin_exists() {
    local uspl2="$1"
    if [ "${ZPLG_REGISTERED_PLUGINS[(r)$uspl2]}" != "$uspl2" ]; then
        return 1
    fi
    return 0
}

_zplugin_exists_message() {
    local uspl2="$1"
    if ! _zplugin_exists "$uspl2"; then
        local user="${1%%/*}" plugin="${1#*/}"
        local ucol="$ZPLG_COLORS[uname]" pcol="$ZPLG_COLORS[pname]"
        local uspl2col="${ucol}${user}$reset_color/${pcol}${plugin}$reset_color"

        echo "$ZPLG_COLORS[error]No such plugin$reset_color $uspl2col"
        return 1
    fi
    return 0
}

# Convert plugin name from "user--plugin" to "user/plugin"
_zplugin-uspl-to-uspl2() {
    local user="${1%%--*}" plugin="${1#*--}"
    if [ "$user" = "$plugin" ]; then
        REPLY="$plugin"
    else
        REPLY="$user/$plugin"
    fi
}

_zplugin-colorify-uspl2() {
    local user="${1%%/*}" plugin="${1#*/}"
    local ucol="$ZPLG_COLORS[uname]" pcol="$ZPLG_COLORS[pname]"
    local uspl2col

    if [ "$user" = "$plugin" ]; then
        uspl2col="${pcol}${plugin}$reset_color"
    else
        uspl2col="${ucol}${user}$reset_color/${pcol}${plugin}$reset_color"
    fi

    REPLY="$uspl2col"
}

# Prepare readlink command, used e.g. for
# establishing completion's owner
_zplugin-prepare-readline() {
    REPLY=":"
    if type readlink 2>/dev/null 1>&2; then
        REPLY="readlink"
    fi
}

# Both :A and readlink will be used, then readlink's output if
# results differ. This allows to simlink git repositories
# into .zplugin/plugins and have username properly resolved
# (:A will read the link "twice" and give the final repository
# directory, possibly without username in the uspl format;
# readlink will read the link "once")
_zplugin-get-completion-owner() {
    local cpath="$1"
    local readlink_cmd="$2"
    local in_plugin_path tmp

    # Try to go not too deep into resolving the simlink,
    # to have the name as it is in .zplugin/plugins
    # :A goes deep, descends fully to origin directory
    # Readlink just reads what simlink points to
    in_plugin_path="${cpath:A}"
    tmp=$( "$readlink_cmd" "$cpath" )
    [ -n "$tmp" ] && in_plugin_path="$tmp"

    if [ "$in_plugin_path" != "$cpath" ]; then
        # Get the user--plugin part of path -
        # it's right before completion file name
        in_plugin_path="${in_plugin_path:h}"
        in_plugin_path="${in_plugin_path:t}"
    else
        # readlink and :A have nothing
        in_plugin_path="[unknown]"
    fi

    REPLY="$in_plugin_path"
}

_zplugin-load-plugin() {
    local user="$1" plugin="$2"
    ZPLG_CUR_USER="$user"
    ZPLG_CUR_PLUGIN="$plugin"
    ZPLG_CUR_USPL="${user}--${plugin}"
    ZPLG_CUR_USPL2="${user}/${plugin}"

    # There are plugins having ".plugin.zsh"
    # in ${plugin} directory name, also some
    # have ".zsh" there
    local pdir="${${plugin%.plugin.zsh}%.zsh}"
    local dname="$ZPLG_PLUGINS_DIR/${user}--${plugin}"

    # Look for a file to source
    typeset -a matches
    matches=(
        $dname/$pdir/init.zsh(N) $dname/${pdir}.plugin.zsh(N)
        $dname/${pdir}.zsh-theme(N) $dname/${pdir}.theme.zsh(N)
        $dname/${pdir}.zshplugin(N) $dname/${pdir}.zsh.plugin(N)
        $dname/*.plugin.zsh(N) $dname/*.zsh(N) $dname/*.sh(N)
    )
    [ "$#matches" -eq "0" ] && return 1
    local fname="${matches[1]#$dname/}"

    _zplugin-add-report "$ZPLG_CUR_USPL2" "Source $fname"

    _zplugin-diff-functions "$ZPLG_CUR_USPL2" begin
    _zplugin-shadow-on
    source "$dname/$fname"
    _zplugin-shadow-off
    _zplugin-diff-functions "$ZPLG_CUR_USPL2" end
    _zplugin-diff-functions "$user/$plugin" diff
}

# }}}

#
# User-exposed functions {{{
#

_zplugin-show-completions() {
    typeset -a completions
    completions=( "$ZPLG_COMPLETIONS_DIR"/_*(N) )

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
        c="${c#_}"

        # Is completion disabled? (i.e. zero size file)
        if [ ! -s "$cpath" ]; then
            disabled=1
            # We have to change "cpath" to point to the
            # completion's backup file (without "_" in name)
            # to be able to resolve user and plugin
            [ -f "${cpath:h}/$c" ] && cpath="${cpath:h}/$c"
        else
            disabled=0
        fi

        # Prepare readlink command for establishing
        # completion's owner
        _zplugin-prepare-readline

        # This will resolve completion's simlink to obtain
        # information about the repository it comes from,
        # i.e. about uspl - user--plugin named directory
        _zplugin-get-completion-owner "$cpath" "$REPLY"

        # Convert user--plugin into user/plugin
        _zplugin-uspl-to-uspl2 "$REPLY"
        _zplugin-colorify-uspl2 "$REPLY"

        # Output line of text
        print -n "${(r:longest+1:: :)c} $REPLY"
        (( disabled )) && print -n " $ZPLG_COLORS[error][disabled]$reset_color"
        print
    done
}

_zplugin-show-report() {
    local user="$1" plugin="$2"
    [ -z "$2" ] && { user="$1:h"; plugin="$1:t" }

    _zplugin_exists_message "$user/$plugin" || return 1

    # Print title
    printf "$ZPLG_COLORS[title]Plugin report for$reset_color %s/%s\n"\
            "$ZPLG_COLORS[uname]$user$reset_color"\
            "$ZPLG_COLORS[pname]$plugin$reset_color"

    # Print "----------"
    local msg="Plugin report for $user/$plugin"
    echo $ZPLG_COLORS[bar]"${(r:$#msg::-:)tmp__}"$reset_color

    # Print report gathered via shadowing
    print $ZPLG_REPORTS[${user}/${plugin}]

    # Print report gathered via $functions-diffing
    _zplugin-format-functions "$user/$plugin"
    echo $ZPLG_COLORS[p]"Functions created:$reset_color"$'\n'"$REPLY"
}

_zplugin-show-all-reports() {
    local i
    for i in "${ZPLG_REGISTERED_PLUGINS[@]}"; do
        local user="${i%%/*}" plugin="${i#*/}"
        _zplugin-show-report "$user" "$plugin"
    done
}

_zplugin-show-registered-plugins() {
    for i in "${ZPLG_REGISTERED_PLUGINS[@]}"; do
        local user="${i%%/*}" plugin="${i#*/}"
        printf "%s/%s\n" $ZPLG_COLORS[uname]$user$reset_color $ZPLG_COLORS[pname]$plugin$reset_color
    done
}

_zplugin-cenable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZPLG_COMPLETIONS_DIR}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        echo "$ZPLG_COLORS[error]No such completion \`$c'$reset_color"
        return 1
    fi

    # Check if completion is already enabled
    # Existence of "$cfile" says that
    if [ -e "$cfile" ]; then
        echo "Completion $ZPLG_COLORS[info]$c$reset_color already enabled"

        # Verify correctness of cfile, bkpfile
        integer error=0

        # cfile must be a simlink
        if [ ! -L "$cfile" ]; then
            echo "$ZPLG_COLORS[error]Warning: completion file \`${cfile:t}' isn't a simlink$reset_color"
            error=1
        fi

        # Backup file shouldn't exist if a completion is enabled
        if [ -e "$bkpfile" ]; then
            echo "$ZPLG_COLORS[error]Warning: completion's backup file \`${bkpfile:t}' exists$reset_color"
            # If it is there, then at least it should be a simlink
            if [ ! -L "$bkpfile" ]; then
                echo "$ZPLG_COLORS[error]Warning: and it isn't a simlink$reset_color"
            fi
            error=1
        fi

        # Tell user that he can manually modify
        # but should do it right
        (( error )) && echo "$ZPLG_COLORS[error]Manual edit of $ZPLG_COMPLETIONS_DIR occured?$reset_color"

        return 0
    fi

    # Enable
    mv >/dev/null "$bkpfile" "$cfile" # move completion's backup file created when disabling

    # Prepare readlink command for establishing completion's owner
    _zplugin-prepare-readline
    # Get completion's owning plugin
    _zplugin-get-completion-owner "$cfile" "$REPLY"
    # Convert user--plugin into user/plugin
    _zplugin-uspl-to-uspl2 "$REPLY"
    # Colorify user/plugin
    _zplugin-colorify-uspl2 "$REPLY"

    echo "Enabled $ZPLG_COLORS[info]$c$reset_color completion belonging to $REPLY"
}

_zplugin-cdisable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZPLG_COMPLETIONS_DIR}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        echo "$ZPLG_COLORS[error]No such completion \`$c'$reset_color"
        return 1
    fi

    # Check if it's already disabled
    # Not existing "$cfile" says that
    if [[ ! -e "$cfile" ]]; then
        echo "Completion $ZPLG_COLORS[info]$c$reset_color already disabled"

        # Verify correctness of bkpfile
        if [ ! -L "$bkpfile" ]; then
            echo "$ZPLG_COLORS[error]Warning: completion's backup file \`${bkpfile:t}' isn't a simlink$reset_color"
            echo "$ZPLG_COLORS[error]Manual edit of $ZPLG_COMPLETIONS_DIR occured?$reset_color"
        fi
        return 0
    fi

    # No disable, but bkpfile exists?
    if [ -e "$bkpfile" ]; then
        echo "$ZPLG_COLORS[error]Warning: completion's backup file \`${bkpfile:t}' already exists, will overwrite$reset_color"
        echo "$ZPLG_COLORS[error]Manual edit of $ZPLG_COMPLETIONS_DIR occured?$reset_color"
        rm >/dev/null -f "$bkpfile"
    fi

    # Disable
    mv >/dev/null "$cfile" "$bkpfile" # backup completion's file

    # Prepare readlink command for establishing completion's owner
    _zplugin-prepare-readline
    # Get completion's owning plugin
    _zplugin-get-completion-owner "$bkpfile" "$REPLY"
    # Convert user--plugin into user/plugin
    _zplugin-uspl-to-uspl2 "$REPLY"
    # Colorify user/plugin
    _zplugin-colorify-uspl2 "$REPLY"

    echo "Disabled $ZPLG_COLORS[info]$c$reset_color completion belonging to $REPLY"
}

# $1 - plugin name, possibly github path
_zplugin-load () {
    local github_path="$1"

    local user="$1:h"
    local plugin="$1:t"

    # Name only? User can place a plugin
    # in plugins directory himself
    if [ "$user" = "$plugin" ]; then
        user="_local"
    fi

    _zplugin-setup-plugin-dir "$user" "$plugin"
    # Instead of fpath entries, there
    # are entries in ZPLG_REGISTERED_PLUGINS array
    _zplugin-register-plugin "$user" "$plugin"
    _zplugin-load-plugin "$user" "$plugin"
    #_zplugin-show-report "$user" "$plugin"
}

# $1 - user/plugin (i.e. uspl2 format, not uspl which is user--plugin)
#
# 1. Unfunction functions created by plugin
# 2. Delete bindkeys
# 3. Delete created Zstyles
# 4. Restore options
# 5. Restore (or just unalias?) aliases
# 6. Forget the plugin
_zplugin-unload() {
    local uspl2="$1" user="${1%%/*}" plugin="${1#*/}"
    local ucol="$ZPLG_COLORS[uname]" pcol="$ZPLG_COLORS[pname]"
    local uspl2col="${ucol}${user}$reset_color/${pcol}${plugin}$reset_color"

    _zplugin_exists_message "$uspl2" || return 1

    # Store report of the plugin in variable LASTREPORT
    LASTREPORT=`_zplugin-show-report "$uspl2"`

    #
    # 1. Unfunction
    #

    typeset -a func
    func=( "${(z)ZPLG_FUNCTIONS[$uspl2]}" )
    local f
    for f in "${(on)func[@]}"; do
        [ -z "$f" ] && continue
        f="${(Q)f}"
        echo "Deleting function $f"
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
        sw_arr[1]="${(Q)sw_arr[1]}"
        sw_arr[2]="${(Q)sw_arr[2]}"
        sw_arr[3]="${(Q)sw_arr[3]}"
        sw_arr[4]="${(Q)sw_arr[4]}"

        if [ "${sw_arr[3]}" = "-M" ]; then
            echo "Deleting bindkey ${sw_arr[1]} ${sw_arr[2]} mapped to ${sw_arr[4]}"
            bindkey -M "${sw_arr[4]}" -r "${sw_arr[1]}"
        else
            echo "Deleting bindkey ${sw_arr[1]} ${sw_arr[2]}"
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

        echo "Deleting zstyle ${ps_arr[1]} ${ps_arr[2]}"

        zstyle -d "${ps_arr[1]}" "${ps_arr[2]}"
    done

    #
    # 4. Restore options
    #

    typeset -a options
    options=( "${(z)ZPLG_OPTIONS[$uspl2]}" )
    local opt
    for opt in "${(on)options[@]}"; do
        [ -z "$opt" ] && continue
        # Remove one level of quoting added when concatenating
        opt="${(Q)opt}"

        echo "Setting option ${(U)opt}"
        setopt "$opt"
    done

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
            echo "Removing suffix alias ${nv_arr[1]}=${nv_arr[2]}"
            unalias -s "${nv_arr[1]}"
        elif [ "${nv_arr[3]}" = "-g" ]; then
            echo "Removing global alias ${nv_arr[1]}=${nv_arr[2]}"
            unalias "${(q)nv_arr[1]}"
        else
            echo "Removing alias ${nv_arr[1]}=${nv_arr[2]}"
            unalias "${nv_arr[1]}"
        fi
    done

    #
    # 6. Forget the plugin
    #

    echo "Unregistering plugin $uspl2col"
    local idx="${ZPLG_REGISTERED_PLUGINS[(i)$uspl2]}"
    ZPLG_REGISTERED_PLUGINS[$idx]=()

    echo "Plugin's report saved to \$LASTREPORT"
}

# }}}

# Main function with subcommands
alias zpl=zplugin
zplugin() {
    _zplugin-prepare-home

    # Add completions directory to fpath
    fpath=( "$ZPLG_COMPLETIONS_DIR" "${fpath[@]}" )
    # Uniquify
    fpath=( "${(u)fpath[@]}" )

    case "$1" in
       (load)
           _zplugin-load "$2"
           ;;
       (unload)
           _zplugin-unload "$2"
           ;;
       (report)
           _zplugin-show-report "$2"
           ;;
       (all-reports)
           _zplugin-show-all-reports
           ;;
       (loaded|registered)
           _zplugin-show-registered-plugins
           ;;
       (comp|comps|completions)
           _zplugin-show-completions
           ;;
       (cdisable)
           _zplugin-cdisable "$2"
           ;;
       (cenable)
           _zplugin-cenable "$2"
           ;;
       (-h|--help|help)
           echo "$ZPLG_COLORS[p]Usage$reset_color:
load $ZPLG_COLORS[pname]{plugin-name}$reset_color   - load plugin
unload $ZPLG_COLORS[pname]{plugin-name}$reset_color - unload plugin
report $ZPLG_COLORS[pname]{plugin-name}$reset_color - show plugin's report
all-reports          - show all plugin reports
loaded|registered    - show what plugins are loaded
comp[s]|completions  - list completions in use
cdisable             - disable completion
cenable              - enable completion"
           ;;
       (*)
           echo "Unknown command \`$1' (try \`help' to get usage information)"
           ;;
    esac

}
