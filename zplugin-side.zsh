# -*- mode: shell-script -*-
# vim:ft=zsh

# FUNCTION: -zplg-shands-exp {{{
# Does expansion of currently little unstandarized
# shorthands like "%SNIPPETS", "%HOME", "OMZ::", "PZT::".
-zplg-shands-exp() {
    REPLY="$1$2"
    REPLY="${${${REPLY/\%HOME/$HOME}/\%SNIPPETS/${ZPLGM[SNIPPETS_DIR]}}#%}"
    REPLY="${REPLY/OMZ::/https--github.com--robbyrussell--oh-my-zsh--trunk--}"
    REPLY="${REPLY/\/OMZ//https--github.com--robbyrussell--oh-my-zsh--trunk}"
    REPLY="${REPLY/PZT::/https--github.com--sorin-ionescu--prezto--trunk--}"
    REPLY="${REPLY/\/PZT//https--github.com--sorin-ionescu--prezto--trunk}"

    # Testable
    [[ "$REPLY" != "$1$2" ]]
}
# }}}
# FUNCTION: -zplg-exists-physically {{{
# Checks if directory of given plugin exists in PLUGIN_DIR.
#
# Testable.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-exists-physically() {
    -zplg-any-to-user-plugin "$1" "$2"
    if [[ "${reply[-2]}" = "%" ]]; then
        # Shorthands, little unstandarized
        -zplg-shands-exp "$1" "$2" && {
            [[ -d "$REPLY" ]] && return 0 || return 1
        } || {
            [[ -d "${reply[-1]}" ]] && return 0 || return 1
        }
    else
        [[ -d "${ZPLGM[PLUGINS_DIR]}/${reply[-2]}---${reply[-1]}" ]] && return 0 || return 1
    fi
} # }}}
# FUNCTION: -zplg-exists-physically-message {{{
# Checks if directory of given plugin exists in PLUGIN_DIR,
# and outputs error message if it doesn't.
#
# Testable.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-exists-physically-message() {
    if ! -zplg-exists-physically "$1" "$2"; then
        -zplg-any-colorify-as-uspl2 "$1" "$2"
        local spec="$REPLY"

        -zplg-shands-exp "$1" "$2" && REPLY="${REPLY/$HOME/~}"

        print -r -- "${ZPLGM[col-error]}No such (plugin or snippet) directory${ZPLGM[col-rst]}: $spec"
        [[ "$REPLY" != "$1$2" ]] && print -r -- "(expands to: $REPLY)"
        return 1
    fi
    return 0
} # }}}
# FUNCTION: -zplg-first {{{
# Finds the main file of plugin. There are multiple file name
# formats, they are ordered in order starting from more correct
# ones, and matched. -zplg-load-plugin() has similar code parts
# and doesn't call -zplg-first() – for performance. Obscure matching
# is done in -zplg-find-other-matches, here and in -zplg-load().
# Obscure = non-standard main-file naming convention.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-first() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    # There are plugins having ".plugin.zsh"
    # in ${plugin} directory name, also some
    # have ".zsh" there
    if [[ "$user" = "%" ]]; then
        local pdir="${${${${plugin:t}%.plugin.zsh}%.zsh}%.git}"
        local dname="$plugin"
    else
        local pdir="${${${plugin%.plugin.zsh}%.zsh}%.git}"
        local dname="${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"
    fi

    # Look for file to compile. First look for the most common one
    # (optimization) then for other possibilities
    if [[ ! -e "$dname/${pdir}.plugin.zsh" ]]; then
        -zplg-find-other-matches "$dname" "$pdir"
    else
        reply=( "$dname/${pdir}.plugin.zsh" )
    fi

    if [[ "${#reply}" -eq "0" ]]; then
        reply=( "$dname" "" )
        return 1
    fi

    # Take first entry
    integer correct=0
    [[ -o "KSH_ARRAYS" ]] && correct=1
    local first="${reply[1-correct]}"

    reply=( "$dname" "$first" )
    return 0
} # }}}
# FUNCTION: -zplg-any-colorify-as-uspl2 {{{
# Returns ANSI-colorified "user/plugin" string, from any supported
# plugin spec (user--plugin, user/plugin, user plugin, plugin).
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
# $REPLY = ANSI-colorified "user/plugin" string
-zplg-any-colorify-as-uspl2() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"
    [[ "$user" = "%" ]] && {
        plugin="${plugin/${ZPLGM[SNIPPETS_DIR]}/SNIPPETS}"
        plugin="${plugin/https--github.com--robbyrussell--oh-my-zsh--trunk--/OMZ::}"
        plugin="${plugin/https--github.com--robbyrussell--oh-my-zsh--trunk/OMZ}"
        plugin="${plugin/https--github.com--sorin-ionescu--prezto--trunk--/PZT::}"
        plugin="${plugin/https--github.com--sorin-ionescu--prezto--trunk/PZT}"
        plugin="${plugin/$HOME/HOME}"
        REPLY="${ZPLGM[col-uname]}%${ZPLGM[col-rst]}${ZPLGM[col-pname]}${plugin}${ZPLGM[col-rst]}"
    } || REPLY="${ZPLGM[col-uname]}${user}${ZPLGM[col-rst]}/${ZPLGM[col-pname]}${plugin}${ZPLGM[col-rst]}"
} # }}}
# FUNCTION: -zplg-two-paths()
# Obtains a snippet URL without specification if it is an SVN URL (points to
# directory) or regular URL (points to file), returns 2 possible paths for
# further examination
-zplg-two-paths() {
    setopt localoptions extendedglob nokshglob noksharrays
    integer MBEGIN MEND
    local url="$1" url1 url2 filenameA filenameB filename0A filename0B local_dirA local_dirB MATCH

    # Remove leading whitespace and trailing /
    url="${${url#"${url%%[! $'\t']*}"}%/}"
    url1="$url" url2="$url"

    url1[1,5]="${ZPLG_1MAP[${url[1,5]}]:-${url[1,5]}}" # svn
    url2[1,5]="${ZPLG_2MAP[${url[1,5]}]:-${url[1,5]}}" # normal

    filenameA="${${url1%%\?*}:t}"
    filename0A="${${${url1%%\?*}:h}:t}"
    filenameB="${${url2%%\?*}:t}"
    filename0B="${${${url2%%\?*}:h}:t}"

    # Construct a local directory name from what's in url
    local_dirA="${${url1%/*}//(#m)(http|https|ftp|ftps|scp):\/\//${MATCH%???}--}"
    local_dirA="${${${${local_dirA//\//--}//=/--EQ--}//\?/--QM--}//\&/--AMP--}"
    local_dirA="${ZPLGM[SNIPPETS_DIR]}/$local_dirA"

    local_dirB="${${url2%/*}//(#m)(http|https|ftp|ftps|scp):\/\//${MATCH%???}--}"
    local_dirB="${${${${local_dirB//\//--}//=/--EQ--}//\?/--QM--}//\&/--AMP--}"
    local_dirB="${ZPLGM[SNIPPETS_DIR]}/${local_dirB%--$filename0B}/$filename0B"

    reply=( "$local_dirA/$filenameA" "$local_dirB" "$filenameB" )
}
