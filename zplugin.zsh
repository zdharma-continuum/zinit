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

#
# End of global variable declarations
#

zmodload zsh/zutil || return 1
zmodload zsh/parameter || return 1

autoload colors
colors

typeset -gAH ZPLG_COLORS
ZPLG_COLORS=(
    "title" ""
    "pname" $fg_bold[yellow]
    "uname" $fg_bold[magenta]
    "keyword" $fg_bold[green]
    "error" $fg_bold[red]
    "p" $fg_bold[blue]
    "bar" $fg_bold[magenta]
)

#
# Shadowing-related functions (names of substitute functions start with -)
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
    local PLUGIN_DIR="$ZPLG_HOME/plugins/${ZPLG_CUR_USPL}"
    for func
    do
        functions[$func]="-zplugin_reload_and_run ${(q)PLUGIN_DIR} ${(qq)opts} $func "'"$@"'
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

    # Actual setopt
    builtin setopt "$@"
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

    # Actual alias
    builtin alias "$@"
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

#
# Diff functions
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

    # Get length of longest string
    integer longest=0
    local f
    for f in "${func[@]}"; do
        f="${(Q)f}"
        [ "$#f" -gt "$longest" ] && longest="$#f"
    done

    # Test for printf bug
    # Left justified for zsh >= 5.1, which doesn't have the bug
    integer left=0 right=0
    f=`printf "%-2s" "1"`
    [ "$f" = " 1" ] && right=1 || left=1

    # Output in one or two columns
    local answer=""
    integer count=1
    for f in "${(on)func[@]}"; do
        if (( COLUMNS >= (longest+1)*2-1 )); then
            if (( count ++ % 2 == 0 )); then
                answer+=`printf "%-$(( longest + right ))s" "${(Q)f}"`$'\n'
            else
                answer+=`printf "%-$(( longest + left ))s" "${(Q)f}"`
            fi
        else
            answer+="$f"$'\n'
        fi
    done
    REPLY="$answer"
    (( COLUMNS >= (longest+1)*2-1 && count % 2 == 0 )) && REPLY="$REPLY"$'\n'
}

#
# Report functions
#

_zplugin-add-report() {
    local uspl2="$1"
    local txt="$2"

    local keyword="${txt%% *}"
    if [[ "$keyword" = "Failed" || "$keyword" = "Warning:" ]]; then
        keyword="$ZPLG_COLORS[error]$keyword$reset_color"
    else
        keyword="$ZPLG_COLORS[keyword]$keyword$reset_color"
    fi

    ZPLG_REPORTS[$uspl2]+="$keyword ${txt#* }"$'\n'
}

#
# ZPlugin internal functions
#

_zplugin-prepare-home() {
    [ -n "$ZPLG_HOME_READY" ] && return
    ZPLG_HOME_READY="1"

    [ ! -d "$ZPLG_HOME" ] && mkdir 2>/dev/null "$ZPLG_HOME"
    [ ! -d "$ZPLG_PLUGINS_DIR" ] && mkdir 2>/dev/null "$ZPLG_PLUGINS_DIR"

    # All to the users - simulate OMZ directory structure (2/3)
    [ ! -d "$ZPLG_PLUGINS_DIR/custom" ] && mkdir 2>/dev/null "$ZPLG_PLUGINS_DIR/custom" 
    [ ! -d "$ZPLG_PLUGINS_DIR/custom/plugins" ] && mkdir 2>/dev/null "$ZPLG_PLUGINS_DIR/custom/plugins" 
}

_zplugin-setup-plugin-dir() {
    local user="$1" plugin="$2" github_path="$1/$2"
    if [ ! -d "$ZPLG_PLUGINS_DIR/${user}--${plugin}" ]; then
        git clone https://github.com/"$github_path" "$ZPLG_PLUGINS_DIR/${user}--${plugin}"
    fi

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

#
# User-exposed functions
#

zplugin-show-report() {
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

zplugin-show-all-reports() {
    local i
    for i in "${ZPLG_REGISTERED_PLUGINS[@]}"; do
        local user="${i%%/*}" plugin="${i#*/}"
        zplugin-show-report "$user" "$plugin"
    done
}

zplugin-show-registered-plugins() {
    for i in "${ZPLG_REGISTERED_PLUGINS[@]}"; do
        local user="${i%%/*}" plugin="${i#*/}"
        printf "%s/%s\n" $ZPLG_COLORS[uname]$user$reset_color $ZPLG_COLORS[pname]$plugin$reset_color
    done
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
    #zplugin-show-report "$user" "$plugin"
}

# $1 - user/plugin (i.e. uspl2 format, not uspl which is user--plugin)
#
# 1. Unfunction functions created by plugin
# 2. Delete bindkeys
# 3. Delete created Zstyles
# 4. Restore options TODO
# 5. Restore (or just unalias?) aliases TODO
# 6. Forget the plugin
_zplugin-unload() {
    local uspl2="$1" user="${1%%/*}" plugin="${1#*/}"
    local ucol="$ZPLG_COLORS[uname]" pcol="$ZPLG_COLORS[pname]"
    local uspl2col="${ucol}${user}$reset_color/${pcol}${plugin}$reset_color"

    _zplugin_exists_message "$uspl2" || return 1

    #
    # 1. Unfunction
    #

    typeset -a func
    func=( "${(z)ZPLG_FUNCTIONS[$uspl2]}" )
    local f
    for f in "${(on)func[@]}"; do
        [ -z "$f" ] && continue
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
    # 6. Forget the plugin
    #

    echo "Unregistering plugin $uspl2col"
    local idx="${ZPLG_REGISTERED_PLUGINS[(i)$uspl2]}"
    ZPLG_REGISTERED_PLUGINS[$idx]=()
}

# Main function with subcommands:
# - load
# - unload
zplugin() {
    _zplugin-prepare-home

    case "$1" in
       (load)
           _zplugin-load "$2"
           ;;
       (unload)
           _zplugin-unload "$2"
           ;;
       (*)
           ;;
    esac

}
