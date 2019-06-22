# -*- mode: shell-script -*-
# vim:ft=zsh

# FUNCTION: -zplg-shands-exp {{{
# Does expansion of currently little unstandarized
# shorthands like "%SNIPPETS", "%HOME", "OMZ::", "PZT::".
-zplg-shands-exp() {
    REPLY="$1$2"
    REPLY="${${${REPLY/\%HOME/$HOME}/\%SNIPPETS/${ZPLGM[SNIPPETS_DIR]}}#%}"
    #REPLY="${REPLY/OMZ::/https--github.com--robbyrussell--oh-my-zsh--trunk--}"
    #REPLY="${REPLY/\/OMZ//https--github.com--robbyrussell--oh-my-zsh--trunk}"
    #REPLY="${REPLY/PZT::/https--github.com--sorin-ionescu--prezto--trunk--}"
    #REPLY="${REPLY/\/PZT//https--github.com--sorin-ionescu--prezto--trunk}"

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
        [[ -d "${ZPLGM[PLUGINS_DIR]}/${reply[-2]:+${reply[-2]}---}${reply[-1]//\//---}" ]] && return 0 || return 1
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
# FUNCTION: -zplg-plgdir {{{
-zplg-get-plg-dir() {
    # There are plugins having ".plugin.zsh"
    # in ${plugin} directory name, also some
    # have ".zsh" there
    local dname="${ZPLGM[alias-map-${user:+${user}/}$plugin]}"
    local pdir="${${${${plugin:t}%.plugin.zsh}%.zsh}%.git}"
    [[ -z "$dname" ]] && {
        [[ "$user" = "%" ]] && dname="$plugin" || \
                dname="${ZPLGM[PLUGINS_DIR]}/${user:+${user}---}${plugin//\//---}"
    }

    reply=( "$dname" "$pdir" )
    return 0
}
# }}}
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

    -zplg-get-plg-dir "$user" "$plugin"
    local dname="${reply[-2]}"

    # Look for file to compile. First look for the most common one
    # (optimization) then for other possibilities
    if [[ ! -e "$dname/${reply[-1]}.plugin.zsh" ]]; then
        -zplg-find-other-matches "$dname" "${reply[-1]}"
    else
        reply=( "$dname/${reply[-1]}.plugin.zsh" )
    fi

    if [[ "${#reply}" -eq "0" ]]; then
        reply=( "$dname" "" )
        return 1
    fi

    # Take first entry (ksharrays resilience)
    reply=( "$dname" "${reply[-${#reply}]}" )
    return 0
} # }}}
# FUNCTION: -zplg-any-colorify-as-uspl2 {{{
# Returns ANSI-colorified "user/plugin" string, from any supported
# plugin spec (user---plugin, user/plugin, user plugin, plugin).
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
    } || REPLY="${user:+${ZPLGM[col-uname]}${user}${ZPLGM[col-rst]}/}${ZPLGM[col-pname]}${plugin}${ZPLGM[col-rst]}"
} # }}}
# FUNCTION: -zplg-two-paths {{{
# Obtains a snippet URL without specification if it is an SVN URL (points to
# directory) or regular URL (points to file), returns 2 possible paths for
# further examination
-zplg-two-paths() {
    setopt localoptions extendedglob nokshglob noksharrays noshwordsplit
    local url="$1" url1 url2 local_dirA svn_dirA local_dirB dirnameA dirnameB
    local -a fileB_there

    # Remove leading whitespace and trailing /
    url="${${url#"${url%%[! $'\t']*}"}%/}"
    url1="$url" url2="$url"

    #url1[1,5]="${ZPLG_1MAP[${url[1,5]}]:-${url[1,5]}}" # svn
    #url2[1,5]="${ZPLG_2MAP[${url[1,5]}]:-${url[1,5]}}" # normal

    dirnameA="${${url1%%\?*}:t}"
    local_dirA="${${${url1%%\?*}:h}/:\/\//--}"
    [[ "$local_dirA" = "." ]] && local_dirA="" || local_dirA="${${${${${local_dirA#/}//\//--}//=/--EQ--}//\?/--QM--}//\&/--AMP--}"
    local_dirA="${ZPLGM[SNIPPETS_DIR]}${local_dirA:+/$local_dirA}"
    [[ -d "$local_dirA/$dirnameA/.svn" ]] && svn_dirA=".svn"

    dirnameB="${${url2%%\?*}:t}"
    local_dirB="${${${url2%%\?*}:h}/:\/\//--}"
    [[ "$local_dirB" = "." ]] && local_dirB="" || local_dirB="${${${${${local_dirB#/}//\//--}//=/--EQ--}//\?/--QM--}//\&/--AMP--}"
    local_dirB="${ZPLGM[SNIPPETS_DIR]}${local_dirB:+/$local_dirB}"
    fileB_there=( "$local_dirB/$dirnameB"/*~*.zwc(.OnN[1]) )

    reply=( "$local_dirA/$dirnameA" "$svn_dirA" "$local_dirB/$dirnameB" "${fileB_there[1]##$local_dirB/$dirnameB/#}" )
}
# }}}
# FUNCTION: -zplg-store-ices {{{
# Saves ice mods in given hash onto disk.
#
# $1 - directory where to create / delete files
# $2 - name of hash that holds values
# $3 - additional keys of hash to store, space separated
# $4 - additional keys of hash to store, empty-meaningful ices, space separated
-zplg-store-ices() {
    local __pfx="$1" __ice_var="$2" __add_ices="$3" __add_ices2="$4" url="$5" mode="$6"

    # Copy from -zplg-recall
    local -a ice_order nval_ices
    ice_order=(
        svn proto from teleid bindmap cloneopts id-as depth if wait load
        unload blockf pick bpick src as ver silent lucid notify mv cp
        atinit atclone atload atpull nocd run-atpull has cloneonly make
        service trackbinds multisrc compile nocompile nocompletions
        reset-prompt
    )
    nval_ices=(
            blockf silent lucid trackbinds cloneonly nocd run-atpull
            nocompletions svn
    )

    command mkdir -p "$__pfx"
    local __key __var_name
    # No nval_ices here
    for __key in ${ice_order[@]:#(${(~j:|:)nval_ices[@]})} ${(s: :)__add_ices[@]}; do
        __var_name="${__ice_var}[$__key]"
        print -r -- "${(P)__var_name}" >! "$__pfx"/$__key
    done

    # Ices that even empty mean something
    for __key in make pick nocompile ${nval_ices[@]} ${(s: :)__add_ices2[@]}; do
        __var_name="${__ice_var}[$__key]"
        (( ${(P)+__var_name} )) && print -r -- "${(P)__var_name}" >! "$__pfx"/$__key || command rm -f "$__pfx"/$__key
    done

    for __key in url mode; do
        [[ -n "${(P)__key}" ]] && print -r -- "${(P)__key}" >! "$__pfx"/$__key
    done
}
# }}}
