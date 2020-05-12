# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors

# FUNCTION: .zinit-shands-exp [[[
# Does expansion of currently little unstandarized
# shorthands like "%SNIPPETS", "%HOME", "OMZ::", "PZT::".
.zinit-shands-exp() {
    REPLY="$1$2"
    REPLY="${${${REPLY/\%HOME/$HOME}/\%SNIPPETS/${ZINIT[SNIPPETS_DIR]}}#%}"
    #REPLY="${REPLY/OMZ::/https--github.com--robbyrussell--oh-my-zsh--trunk--}"
    #REPLY="${REPLY/\/OMZ//https--github.com--robbyrussell--oh-my-zsh--trunk}"
    #REPLY="${REPLY/PZT::/https--github.com--sorin-ionescu--prezto--trunk--}"
    #REPLY="${REPLY/\/PZT//https--github.com--sorin-ionescu--prezto--trunk}"

    # Testable
    [[ "$REPLY" != "$1$2" ]]
}
# ]]]
# FUNCTION: .zinit-exists-physically [[[
# Checks if directory of given plugin exists in PLUGIN_DIR.
#
# Testable.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-exists-physically() {
    .zinit-any-to-user-plugin "$1" "$2"
    if [[ "${reply[-2]}" = "%" ]]; then
        # Shorthands, little unstandarized
        .zinit-shands-exp "$1" "$2" && {
            [[ -d "$REPLY" ]] && return 0 || return 1
        } || {
            [[ -d "${reply[-1]}" ]] && return 0 || return 1
        }
    else
        [[ -d "${ZINIT[PLUGINS_DIR]}/${reply[-2]:+${reply[-2]}---}${reply[-1]//\//---}" ]] && return 0 || return 1
    fi
} # ]]]
# FUNCTION: .zinit-exists-physically-message [[[
# Checks if directory of given plugin exists in PLUGIN_DIR,
# and outputs error message if it doesn't.
#
# Testable.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-exists-physically-message() {
    if ! .zinit-exists-physically "$1" "$2"; then
        .zinit-any-colorify-as-uspl2 "$1" "$2"
        local spec="$REPLY"

        .zinit-shands-exp "$1" "$2" && REPLY="${REPLY/$HOME/~}"

        print -r -- "${ZINIT[col-error]}No such (plugin or snippet) directory${ZINIT[col-rst]}: $spec"
        [[ "$REPLY" != "$1$2" ]] && print -r -- "(expands to: $REPLY)"
        return 1
    fi
    return 0
} # ]]]
# FUNCTION: .zinit-plgdir [[[
.zinit-get-plg-dir() {
    # There are plugins having ".plugin.zsh"
    # in ${plugin} directory name, also some
    # have ".zsh" there
    local dname="${ZINIT[alias-map-${user:+${user}/}$plugin]}"
    local pdir="${${${${plugin:t}%.plugin.zsh}%.zsh}%.git}"
    [[ -z "$dname" ]] && {
        [[ "$user" = "%" ]] && \
            dname="$plugin" || \
            dname="${ZINIT[PLUGINS_DIR]}/${user:+${user}---}${plugin//\//---}"
    }

    reply=( "$dname" "$pdir" )
    return 0
}
# ]]]
# FUNCTION: .zinit-first [[[
# Finds the main file of plugin. There are multiple file name
# formats, they are ordered in order starting from more correct
# ones, and matched. .zinit-load-plugin() has similar code parts
# and doesn't call .zinit-first() – for performance. Obscure matching
# is done in .zinit-find-other-matches, here and in .zinit-load().
# Obscure = non-standard main-file naming convention.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-first() {
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    .zinit-get-plg-dir "$user" "$plugin"
    local dname="${reply[-2]}"

    # Look for file to compile. First look for the most common one
    # (optimization) then for other possibilities
    if [[ ! -e "$dname/${reply[-1]}.plugin.zsh" ]]; then
        .zinit-find-other-matches "$dname" "${reply[-1]}"
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
} # ]]]
# FUNCTION: .zinit-any-colorify-as-uspl2 [[[
# Returns ANSI-colorified "user/plugin" string, from any supported
# plugin spec (user---plugin, user/plugin, user plugin, plugin).
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
# $REPLY = ANSI-colorified "user/plugin" string
.zinit-any-colorify-as-uspl2() {
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"
    if [[ "$user" = "%" ]] {
        plugin="${plugin/${ZINIT[SNIPPETS_DIR]}/SNIPPETS}"
        plugin="${plugin/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--plugins--/OMZP::}"
        plugin="${plugin/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--plugins/OMZP}"
        plugin="${plugin/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--lib--/OMZL::}"
        plugin="${plugin/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--lib/OMZL}"
        plugin="${plugin/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--themes--/OMZT::}"
        plugin="${plugin/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--themes/OMZT}"
        plugin="${plugin/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk--/OMZ::}"
        plugin="${plugin/https--github.com--(robbyrussell--oh-my-zsh|ohmyzsh--ohmyzsh)--trunk/OMZ}"
        plugin="${plugin/https--github.com--sorin-ionescu--prezto--trunk--modules--/PZTM::}"
        plugin="${plugin/https--github.com--sorin-ionescu--prezto--trunk--modules/PZTM}"
        plugin="${plugin/https--github.com--sorin-ionescu--prezto--trunk--/PZT::}"
        plugin="${plugin/https--github.com--sorin-ionescu--prezto--trunk/PZT}"
        plugin="${plugin/$HOME/HOME}"
        REPLY="${ZINIT[col-uname]}%${ZINIT[col-rst]}${ZINIT[col-pname]}${plugin}${ZINIT[col-rst]}"
    } else {
        REPLY="${user:+${ZINIT[col-uname]}${user}${ZINIT[col-rst]}/}${ZINIT[col-pname]}${plugin}${ZINIT[col-rst]}"
    }
} # ]]]
# FUNCTION: .zinit-two-paths [[[
# Obtains a snippet URL without specification if it is an SVN URL (points to
# directory) or regular URL (points to file), returns 2 possible paths for
# further examination
.zinit-two-paths() {
    emulate -LR zsh
    setopt extendedglob typesetsilent warncreateglobal noshortloops

    local url=$1 url1 url2 local_dirA dirnameA svn_dirA \
            local_dirB dirnameB
    local -a fileB_there

    # Remove leading whitespace and trailing /
    url="${${url#"${url%%[! $'\t']*}"}%/}"
    url1=$url url2=$url

    .zinit-get-object-path snippet "$url1"
    local_dirA=$reply[-3] dirnameA=$reply[-2]
    [[ -d "$local_dirA/$dirnameA/.svn" ]] && svn_dirA=".svn"

    .zinit-get-object-path snippet "$url2"
    local_dirB=$reply[-3] dirnameB=$reply[-2]
    fileB_there=( "$local_dirB/$dirnameB"/*~*.zwc(.-DOnN[1]) )

    reply=( "$local_dirA/$dirnameA" "$svn_dirA" "$local_dirB/$dirnameB" "${fileB_there[1]##$local_dirB/$dirnameB/#}" )
}
# ]]]
# FUNCTION: .zinit-compute-ice [[[
# Computes ZINIT_ICE array (default, it can be specified via $3) from a) input
# ZINIT_ICE, b) static ice, c) saved ice, taking priorities into account. Also
# returns path to snippet directory and optional name of snippet file (only
# valid if ZINIT_ICE[svn] is not set).
#
# Can also pack resulting ices into ZINIT_SICE (see $2).
#
# $1 - URL (also plugin-spec)
# $2 - "pack" or "nopack" or "pack-nf" - packing means ZINIT_ICE
#      wins with static ice; "pack-nf" means that disk-ices will
#      be ignored (no-file?)
# $3 - name of output associative array, "ZINIT_ICE" is the default
# $4 - name of output string parameter, to hold path to directory ("local_dir")
# $5 - name of output string parameter, to hold filename ("filename")
# $6 - name of output string parameter, to hold is-snippet 0/1-bool ("is_snippet")
.zinit-compute-ice() {
    emulate -LR zsh
    setopt extendedglob typesetsilent warncreateglobal noshortloops

    local ___URL="${1%/}" ___pack="$2" ___is_snippet=0
    local ___var_name1="${3:-ZINIT_ICE}" ___var_name2="${4:-local_dir}" \
        ___var_name3="${5:-filename}" ___var_name4="${6:-is_snippet}"

    # Copy from .zinit-recall
    local -a ice_order nval_ices
    ice_order=(
        ${(s.|.)ZINIT[ice-list]}

        # Include all additional ices – after
        # stripping them from the possible: ''
        ${(@us.|.)${ZINIT_EXTS[ice-mods]//\'\'/}}
    )
    nval_ices=(
            ${(s.|.)ZINIT[nval-ice-list]}

            # Include only those additional ices,
            # don't have the '' in their name, i.e.
            # aren't designed to hold value
            ${(@)${(@s.|.)ZINIT_EXTS[ice-mods]}:#*\'\'*}

            # Must be last
            svn
    )

    # Remove whitespace from beginning of URL
    ___URL="${${___URL#"${___URL%%[! $'\t']*}"}%/}"

    # Snippet?
    .zinit-two-paths "$___URL"
    local ___s_path="${reply[-4]}" ___s_svn="${reply[-3]}" ___path="${reply[-2]}" ___filename="${reply[-1]}" ___local_dir
    if [[ -d "$___s_path" || -d "$___path" ]]; then
        ___is_snippet=1
    else
        # Plugin
        .zinit-shands-exp "$___URL" && ___URL="$REPLY"
        .zinit-any-to-user-plugin "$___URL" ""
        local ___user="${reply[-2]}" ___plugin="${reply[-1]}"
        ___s_path="" ___filename=""
        [[ "$___user" = "%" ]] && ___path="$___plugin" || ___path="${ZINIT[PLUGINS_DIR]}/${___user:+${___user}---}${___plugin//\//---}"
        .zinit-exists-physically-message "$___user" "$___plugin" || return 1
    fi

    [[ $___pack = pack* ]] && (( ${#ZINIT_ICE} > 0 )) && \
        .zinit-pack-ice "${___user-$___URL}" "$___plugin"

    local -A ___sice
    local -a ___tmp
    ___tmp=( "${(z@)ZINIT_SICE[$___user${${___user:#(%|/)*}:+/}$___plugin]}" )
    (( ${#___tmp[@]} > 1 && ${#___tmp[@]} % 2 == 0 )) && ___sice=( "${(Q)___tmp[@]}" )

    if [[ "${+___sice[svn]}" = "1" || -n "$___s_svn" ]]; then
        if (( !___is_snippet && ${+___sice[svn]} == 1 )); then
            print -r -- "The \`svn' ice is given, but the argument ($___URL) is a plugin"
            print -r -- "(\`svn' can be used only with snippets)"
            return 1
        elif (( !___is_snippet )); then
            print -r -- "Undefined behavior #1 occurred, please report at https://github.com/zdharma/zinit/issues"
            return 1
        fi
        if [[ -e "$___s_path" && -n "$___s_svn" ]]; then
            ___sice[svn]=""
            ___local_dir="$___s_path"
        else
            [[ ! -e "$___path" ]] && { print -r -- "No such snippet, looked at paths (1): $___s_path, and: $___path"; return 1; }
            unset '___sice[svn]'
            ___local_dir="$___path"
        fi
    else
        if [[ -e "$___path" ]]; then
            unset '___sice[svn]'
            ___local_dir="$___path"
        else
            print -r -- "No such snippet, looked at paths (2): $___s_path, and: $___path"
            return 1
        fi
    fi

    local ___zinit_path="$___local_dir/._zinit"

    # Zplugin -> Zinit rename upgrade code
    if [[ ! -d $___zinit_path && -d $___local_dir/._zplugin ]]; then
        (
            print -Pr -- "${ZINIT[col-pre]}UPGRADING THE DIRECTORY STRUCTURE" \
                "FOR THE ZPLUGIN -> ZINIT RENAME…%f"
            builtin cd -q ${ZINIT[PLUGINS_DIR]} || return 1
            autoload -Uz zmv
            ( zmv -W '**/._zplugin' '**/._zinit' ) &>/dev/null
            builtin cd -q ${ZINIT[SNIPPETS_DIR]} || return 1
            ( zmv -W '**/._zplugin' '**/._zinit' ) &>/dev/null
            print -Pr -- "${ZINIT[col-obj]}THE UPGRADE SUCCEDED!%f"
        ) || print -Pr -- "${ZINIT[col-error]}THE UPGRADE FAILED!%f"
    fi

    # Read disk-Ice
    local -A ___mdata
    local ___key
    { for ___key in mode url is_release{,2..5} ${ice_order[@]}; do
        [[ -f "$___zinit_path/$___key" ]] && ___mdata[$___key]="$(<$___zinit_path/$___key)"
      done
      [[ "${___mdata[mode]}" = "1" ]] && ___mdata[svn]=""
    } 2>/dev/null

    # Handle flag-Ices; svn must be last
    for ___key in ${ice_order[@]}; do
        (( 0 == ${+ZINIT_ICE[no$___key]} && 0 == ${+___sice[no$___key]} )) && continue
        # "If there is such ice currently, and there's no no* ice given,
        # and there's the no* ice in the static ice" – skip, don't unset.
        # With conjunction with the previous line this has the proper
        # meaning: uset if at least in one – current or static – ice
        # there's the no* ice, but not if it's only in the static ice
        # (unless there's on such ice "anyway").
        (( 1 == ${+ZINIT_ICE[$___key]} && 0 == ${+ZINIT_ICE[no$___key]} && \
            1 == ${+___sice[no$___key]} )) && continue

        if [[ "$___key" = "svn" ]]; then
            command print -r -- "0" >! "$___zinit_path/mode"
            ___mdata[mode]=0
        else
            command rm -f -- "$___zinit_path/$___key"
        fi
        unset "___mdata[$___key]" "___sice[$___key]" "ZINIT_ICE[$___key]"
    done

    # Final decision, static ice vs. saved ice
    local -A ___MY_ICE
    for ___key in mode url is_release ${ice_order[@]}; do
        (( ${+___sice[$___key]} + ${${${___pack:#pack-nf*}:+${+___mdata[$___key]}}:-0} )) && ___MY_ICE[$___key]="${___sice[$___key]-${___mdata[$___key]}}"
    done
    # One more round for the special case – update, which ALWAYS
    # needs the tleid from the disk or static ice
    ___key=teleid; [[ "$___pack" = pack-nftid ]] && {
        (( ${+___sice[$___key]} + ${+___mdata[$___key]} )) && ___MY_ICE[$___key]="${___sice[$___key]-${___mdata[$___key]}}"
    }

    : ${(PA)___var_name1::="${(kv)___MY_ICE[@]}"}
    : ${(P)___var_name2::=$___local_dir}
    : ${(P)___var_name3::=$___filename}
    : ${(P)___var_name4::=$___is_snippet}

    return 0
}
# ]]]
# FUNCTION: .zinit-store-ices [[[
# Saves ice mods in given hash onto disk.
#
# $1 - directory where to create / delete files
# $2 - name of hash that holds values
# $3 - additional keys of hash to store, space separated
# $4 - additional keys of hash to store, empty-meaningful ices, space separated
# $5 – the URL, if applicable
# $6 – the mode (1 - svn, 0 - single file), if applicable
.zinit-store-ices() {
    local ___pfx="$1" ___ice_var="$2" \
          ___add_ices="$3" ___add_ices2="$4" \
          url="$5" mode="$6"

    # Copy from .zinit-recall
    local -a ice_order nval_ices
    ice_order=(
        ${(s.|.)ZINIT[ice-list]}
        # Include all additional ices – after
        # stripping them from the possible: ''
        ${(@s.|.)${ZINIT_EXTS[ice-mods]//\'\'/}}
    )
    nval_ices=(
            ${(s.|.)ZINIT[nval-ice-list]}

            # Include only those additional ices,
            # don't have the '' in their name, i.e.
            # aren't designed to hold value
            ${(@)${(@s.|.)ZINIT_EXTS[ice-mods]}:#*\'\'*}

            # Must be last
            svn
    )

    command mkdir -p "$___pfx"
    local ___key ___var_name
    # No nval_ices here
    for ___key in ${ice_order[@]:#(${(~j:|:)nval_ices[@]})} ${(s: :)___add_ices[@]}; do
        ___var_name="${___ice_var}[$___key]"
        (( ${(P)+___var_name} )) && \
            print -r -- "${(P)___var_name}" >! "$___pfx"/"$___key"
    done

    # Ices that even empty mean something
    for ___key in make pick nocompile reset ${nval_ices[@]} ${(s: :)___add_ices2[@]}; do
        ___var_name="${___ice_var}[$___key]"
        if (( ${(P)+___var_name} )) {
            print -r -- "${(P)___var_name}" >! "$___pfx"/"$___key"
        } else {
            command rm -f "$___pfx"/"$___key"
        }
    done

    # url and mode are declared at the beginning of the body
    for ___key in url mode; do
        [[ -n "${(P)___key}" ]] && print -r -- "${(P)___key}" >! "$___pfx"/"$___key"
    done
}
# ]]]
# FUNCTION: .zinit-countdown [[[
# Displays a countdown 5...4... etc. and returns 0 if it
# sucessfully reaches 0, or 1 if Ctrl-C will be pressed.
.zinit-countdown() {
    (( !${+ZINIT_ICE[countdown]} )) && return 0

    emulate -L zsh
    trap "print \"${ZINIT[col-pname]}ABORTING, the ice not ran${ZINIT[col-rst]}\"; return 1" INT
    local count=5 tpe="$1" ice
    ice="${ZINIT_ICE[$tpe]}"
    [[ $tpe = "atpull" && $ice = "%atclone" ]] && ice="${ZINIT_ICE[atclone]}"
    ice="$tpe:$ice"
    print -nr "${ZINIT[col-pname]}Running ${ZINIT[col-bold]}${ZINIT[col-uname]}$ice${ZINIT[col-rst]}${ZINIT[col-pname]} ice in...${ZINIT[col-rst]} "
    while (( -- count + 1 )) {
        print -nr -- "${ZINIT[col-bold]}${ZINIT[col-error]}"$(( count + 1 ))..."${ZINIT[col-rst]}"
        sleep 1
    }
    print -r -- "${ZINIT[col-bold]}${ZINIT[col-error]}0 <running now>...${ZINIT[col-rst]}"
    return 0
}
# ]]]

# vim:ft=zsh:sw=4:sts=4:et:foldmarker=[[[,]]]:foldmethod=marker
