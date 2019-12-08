# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2019 Sebastian Gniazdowski and contributors

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
    fileB_there=( "$local_dirB/$dirnameB"/*~*.zwc(.DOnN[1]) )

    reply=( "$local_dirA/$dirnameA" "$svn_dirA" "$local_dirB/$dirnameB" "${fileB_there[1]##$local_dirB/$dirnameB/#}" )
}
# }}}
# FUNCTION: -zplg-compute-ice {{{
# Computes ZPLG_ICE array (default, it can be specified via $3) from a) input
# ZPLG_ICE, b) static ice, c) saved ice, taking priorities into account. Also
# returns path to snippet directory and optional name of snippet file (only
# valid if ZPLG_ICE[svn] is not set).
#
# Can also pack resulting ices into ZPLG_SICE (see $2).
#
# $1 - URL (also plugin-spec)
# $2 - "pack" or "nopack" or "pack-nf" - packing means ZPLG_ICE
#      wins with static ice; "pack-nf" means that disk-ices will
#      be ignored (no-file?)
# $3 - name of output associative array, "ZPLG_ICE" is the default
# $4 - name of output string parameter, to hold path to directory ("local_dir")
# $5 - name of output string parameter, to hold filename ("filename")
# $6 - name of output string parameter, to hold is-snippet 0/1-bool ("is_snippet")
-zplg-compute-ice() {
    setopt localoptions extendedglob nokshglob noksharrays

    local __URL="${1%/}" __pack="$2" __is_snippet=0
    local __var_name1="${3:-ZPLG_ICE}" __var_name2="${4:-local_dir}" \
        __var_name3="${5:-filename}" __var_name4="${6:-is_snippet}"

    # Copy from -zplg-recall
    local -a ice_order nval_ices
    ice_order=(
        svn proto from teleid bindmap cloneopts id-as depth if wait load
        unload blockf pick bpick src as ver silent lucid notify mv cp
        atinit atclone atload atpull nocd run-atpull has cloneonly make
        service trackbinds multisrc compile nocompile nocompletions
        reset-prompt wrap-track reset sh \!sh bash \!bash ksh \!ksh csh
        \!csh aliases countdown ps-on-unload ps-on-update trigger-load
        light-mode is-snippet atdelete pack git verbose on-update-of
        subscribe
        # Include all additional ices – after
        # stripping them from the possible: ''
        ${(@us.|.)${ZPLG_EXTS[ice-mods]//\'\'/}}
    )
    nval_ices=(
            blockf silent lucid trackbinds cloneonly nocd run-atpull
            nocompletions sh \!sh bash \!bash ksh \!ksh csh \!csh
            aliases countdown light-mode is-snippet git verbose

            # Include only those additional ices,
            # don't have the '' in their name, i.e.
            # aren't designed to hold value
            ${(@)${(@s.|.)ZPLG_EXTS[ice-mods]}:#*\'\'*}

            # Must be last
            svn
    )

    # Remove whitespace from beginning of URL
    __URL="${${__URL#"${__URL%%[! $'\t']*}"}%/}"

    # Snippet?
    -zplg-two-paths "$__URL"
    local __s_path="${reply[-4]}" __s_svn="${reply[-3]}" ___path="${reply[-2]}" __filename="${reply[-1]}" __local_dir
    if [[ -d "$__s_path" || -d "$___path" ]]; then
        __is_snippet=1
    else
        # Plugin
        -zplg-shands-exp "$__URL" && __URL="$REPLY"
        -zplg-any-to-user-plugin "$__URL" ""
        local __user="${reply[-2]}" __plugin="${reply[-1]}"
        __s_path="" __filename=""
        [[ "$__user" = "%" ]] && ___path="$__plugin" || ___path="${ZPLGM[PLUGINS_DIR]}/${__user:+${__user}---}${__plugin//\//---}"
        -zplg-exists-physically-message "$__user" "$__plugin" || return 1
    fi

    [[ $__pack = pack* ]] && (( ${#ZPLG_ICE} > 0 )) && \
        -zplg-pack-ice "${__user-$__URL}" "$__plugin"

    local -A __sice
    local -a __tmp
    __tmp=( "${(z@)ZPLG_SICE[$__user${${__user:#(%|/)*}:+/}$__plugin]}" )
    (( ${#__tmp[@]} > 1 && ${#__tmp[@]} % 2 == 0 )) && __sice=( "${(Q)__tmp[@]}" )

    if [[ "${+__sice[svn]}" = "1" || -n "$__s_svn" ]]; then
        if (( !__is_snippet && ${+__sice[svn]} == 1 )); then
            print -r -- "The \`svn' ice is given, but the argument ($__URL) is a plugin"
            print -r -- "(\`svn' can be used only with snippets)"
            return 1
        elif (( !__is_snippet )); then
            print -r -- "Undefined behavior #1 occurred, please report at https://github.com/zdharma/zplugin/issues"
            return 1
        fi
        if [[ -e "$__s_path" && -n "$__s_svn" ]]; then
            __sice[svn]=""
            __local_dir="$__s_path"
        else
            [[ ! -e "$___path" ]] && { print -r -- "No such snippet, looked at paths (1): $__s_path, and: $___path"; return 1; }
            unset '__sice[svn]'
            __local_dir="$___path"
        fi
    else
        if [[ -e "$___path" ]]; then
            unset '__sice[svn]'
            __local_dir="$___path"
        else
            print -r -- "No such snippet, looked at paths (2): $__s_path, and: $___path"
            return 1
        fi
    fi

    local __zplugin_path="$__local_dir/._zplugin"

    # Read disk-Ice
    local -A __mdata
    local __key
    { for __key in mode url is_release ${ice_order[@]}; do
        [[ -f "$__zplugin_path/$__key" ]] && __mdata[$__key]="$(<$__zplugin_path/$__key)"
      done
      [[ "${__mdata[mode]}" = "1" ]] && __mdata[svn]=""
    } 2>/dev/null

    # Handle flag-Ices; svn must be last
    for __key in ${ice_order[@]}; do
        (( 0 == ${+ZPLG_ICE[no$__key]} && 0 == ${+__sice[no$__key]} )) && continue
        # "If there is such ice currently, and there's no no* ice given,
        # and there's the no* ice in the static ice" – skip, don't unset.
        # With conjunction with the previous line this has the proper
        # meaning: uset if at least in one – current or static – ice
        # there's the no* ice, but not if it's only in the static ice
        # (unless there's on such ice "anyway").
        (( 1 == ${+ZPLG_ICE[$__key]} && 0 == ${+ZPLG_ICE[no$__key]} && \
            1 == ${+__sice[no$__key]} )) && continue

        if [[ "$__key" = "svn" ]]; then
            command print -r -- "0" >! "$__zplugin_path/mode"
            __mdata[mode]=0
        else
            command rm -f -- "$__zplugin_path/$__key"
        fi
        unset "__mdata[$__key]" "__sice[$__key]" "ZPLG_ICE[$__key]"
    done

    # Final decision, static ice vs. saved ice
    local -A __MY_ICE
    for __key in mode url is_release ${ice_order[@]}; do
        (( ${+__sice[$__key]} + ${${${__pack:#pack-nf*}:+${+__mdata[$__key]}}:-0} )) && __MY_ICE[$__key]="${__sice[$__key]-${__mdata[$__key]}}"
    done
    # One more round for the special case – update, which ALWAYS
    # needs the tleid from the disk or static ice
    __key=teleid; [[ "$__pack" = pack-nftid ]] && {
        (( ${+__sice[$__key]} + ${+__mdata[$__key]} )) && __MY_ICE[$__key]="${__sice[$__key]-${__mdata[$__key]}}"
    }

    : ${(PA)__var_name1::="${(kv)__MY_ICE[@]}"}
    : ${(P)__var_name2::=$__local_dir}
    : ${(P)__var_name3::=$__filename}
    : ${(P)__var_name4::=$__is_snippet}

    return 0
}
# }}}
# FUNCTION: -zplg-store-ices {{{
# Saves ice mods in given hash onto disk.
#
# $1 - directory where to create / delete files
# $2 - name of hash that holds values
# $3 - additional keys of hash to store, space separated
# $4 - additional keys of hash to store, empty-meaningful ices, space separated
# $5 – the URL, if applicable
# $6 – the mode (1 - svn, 0 - single file), if applicable
-zplg-store-ices() {
    local __pfx="$1" __ice_var="$2" \
          __add_ices="$3" __add_ices2="$4" \
          url="$5" mode="$6"

    # Copy from -zplg-recall
    local -a ice_order nval_ices
    ice_order=(
        svn proto from teleid bindmap cloneopts id-as depth if wait load
        unload blockf pick bpick src as ver silent lucid notify mv cp
        atinit atclone atload atpull nocd run-atpull has cloneonly make
        service trackbinds multisrc compile nocompile nocompletions
        reset-prompt wrap-track reset sh \!sh bash \!bash ksh \!ksh csh
        \!csh aliases countdown ps-on-unload ps-on-update trigger-load
        light-mode is-snippet atdelete pack git verbose on-update-of
        subscribe
        # Include all additional ices – after
        # stripping them from the possible: ''
        ${(@s.|.)${ZPLG_EXTS[ice-mods]//\'\'/}}
    )
    nval_ices=(
            blockf silent lucid trackbinds cloneonly nocd run-atpull
            nocompletions sh \!sh bash \!bash ksh \!ksh csh \!csh
            aliases countdown light-mode is-snippet git verbose

            # Include only those additional ices,
            # don't have the '' in their name, i.e.
            # aren't designed to hold value
            ${(@)${(@s.|.)ZPLG_EXTS[ice-mods]}:#*\'\'*}

            # Must be last
            svn
    )

    command mkdir -p "$__pfx"
    local __key __var_name
    # No nval_ices here
    for __key in ${ice_order[@]:#(${(~j:|:)nval_ices[@]})} ${(s: :)__add_ices[@]}; do
        __var_name="${__ice_var}[$__key]"
        (( ${(P)+__var_name} )) && \
            print -r -- "${(P)__var_name}" >! "$__pfx"/"$__key"
    done

    # Ices that even empty mean something
    for __key in make pick nocompile reset ${nval_ices[@]} ${(s: :)__add_ices2[@]}; do
        __var_name="${__ice_var}[$__key]"
        if (( ${(P)+__var_name} )) {
            print -r -- "${(P)__var_name}" >! "$__pfx"/"$__key"
        } else {
            command rm -f "$__pfx"/"$__key"
        }
    done

    # url and mode are declared at the beginning of the body
    for __key in url mode; do
        [[ -n "${(P)__key}" ]] && print -r -- "${(P)__key}" >! "$__pfx"/"$__key"
    done
}
# }}}
# FUNCTION: -zplg-countdown {{{
# Displays a countdown 5...4... etc. and returns 0 if it
# sucessfully reaches 0, or 1 if Ctrl-C will be pressed.
-zplg-countdown() {
    (( !${+ZPLG_ICE[countdown]} )) && return 0

    emulate -L zsh
    trap "print \"${ZPLGM[col-pname]}ABORTING, the ice not ran${ZPLGM[col-rst]}\"; return 1" INT
    local count=5 tpe="$1" ice
    ice="${ZPLG_ICE[$tpe]}"
    [[ $tpe = "atpull" && $ice = "%atclone" ]] && ice="${ZPLG_ICE[atclone]}"
    ice="$tpe:$ice"
    print -nr "${ZPLGM[col-pname]}Running ${ZPLGM[col-bold]}${ZPLGM[col-uname]}$ice${ZPLGM[col-rst]}${ZPLGM[col-pname]} ice in...${ZPLGM[col-rst]} "
    while (( -- count + 1 )) {
        print -nr -- "${ZPLGM[col-bold]}${ZPLGM[col-error]}"$(( count + 1 ))..."${ZPLGM[col-rst]}"
        sleep 1
    }
    print -r -- "${ZPLGM[col-bold]}${ZPLGM[col-error]}0 <running now>...${ZPLGM[col-rst]}"
    return 0
}
# }}}

# vim:ft=zsh:sw=4:sts=4:et
