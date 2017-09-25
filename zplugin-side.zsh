# -*- mode: shell-script -*-
# vim:ft=zsh

# FUNCTION: -zplg-exists-physically {{{
# Checks if given plugin directory exists in PLUGIN_DIR.
# Testable.
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-exists-physically() {
    -zplg-any-to-user-plugin "$1" "$2"
    if [[ "${reply[-2]}" = "%" ]]; then
        [[ -d "${reply[-1]}" ]] && return 0 || return 1
    else
        [[ -d "${ZPLGM[PLUGINS_DIR]}/${reply[-2]}---${reply[-1]}" ]] && return 0 || return 1
    fi
} # }}}
# FUNCTION: -zplg-exists-physically-message {{{
# Checks if given plugin directory exists in PLUGIN_DIR,
# and outputs error message if it doesn't. Testable.
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-exists-physically-message() {
    if ! -zplg-exists-physically "$1" "$2"; then
        -zplg-any-colorify-as-uspl2 "$1" "$2"
        print "${ZPLGM[col-error]}No such plugin directory${ZPLGM[col-rst]} $REPLY"
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
# Returns (REPLY) ANSI-colorified "user/plugin" string, from any
# supported spec (user--plugin, user/plugin, plugin).
# Double-defined, in *install and *autoload.
-zplg-any-colorify-as-uspl2() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"
    [[ "$user" = "%" ]] && {
        plugin="${plugin/$HOME/HOME}"
        REPLY="${ZPLGM[col-uname]}%${ZPLGM[col-rst]}${ZPLGM[col-pname]}${plugin}${ZPLGM[col-rst]}"
    } || REPLY="${ZPLGM[col-uname]}${user}${ZPLGM[col-rst]}/${ZPLGM[col-pname]}${plugin}${ZPLGM[col-rst]}"
} # }}}
