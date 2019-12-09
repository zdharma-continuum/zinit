# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2019 Sebastian Gniazdowski and contributors

builtin source ${ZPLGM[BIN_DIR]}"/zplugin-side.zsh"

# FUNCTION: -zplg-parse-json {{{
# Retrievies the ice-list from given profile from
# the JSON of the package.json.
-zplg-parse-json() {
    emulate -LR zsh
    setopt extendedglob warncreateglobal typesetsilent

    local -A __pos_to_level __level_to_pos __pair_map \
        __final_pairs __Strings __Counts
    local __input=$1 __workbuf=$1 __key=$2 __varname=$3 \
        __style __quoting
    integer __nest=${4:-1} __idx=0 __pair_idx __level=0 \
        __start __end __sidx=1 __had_quoted_value=0
    local -a match mbegin mend __pair_order

    (( ${(P)+__varname} )) || typeset -gA "$__varname"

    __pair_map=( "{" "}" "[" "]" )
    while [[ $__workbuf = (#b)[^"{}[]\\\"'":,]#((["{[]}\"'":,])|[\\](*))(*) ]]; do
        [[ -n ${match[3]} ]] && {
            __idx+=${mbegin[1]}

            [[ $__quoting = \' ]] && \
                { __workbuf=${match[3]}; } || \
                { __workbuf=${match[3]:1}; (( ++ __idx )); }

        } || {
            __idx+=${mbegin[1]}
            [[ -z $__quoting ]] && {
                if [[ ${match[1]} = ["({["] ]]; then
                    __Strings[$__level/${__Counts[$__level]}]+=" $'\0'--object--$'\0'"
                    __pos_to_level[$__idx]=$(( ++ __level ))
                    __level_to_pos[$__level]=$__idx
                    (( __Counts[$__level] += 1 ))
                    __sidx=__idx+1
                    __had_quoted_value=0
                elif [[ ${match[1]} = ["]})"] ]]; then
                    (( !__had_quoted_value )) && \
                        __Strings[$__level/${__Counts[$__level]}]+=" ${(q)__input[__sidx,__idx-1]//((#s)[[:blank:]]##|([[:blank:]]##(#e)))}"
                    __had_quoted_value=1
                    if (( __level > 0 )); then
                        __pair_idx=${__level_to_pos[$__level]}
                        __pos_to_level[$__idx]=$(( __level -- ))
                        [[ ${__pair_map[${__input[__pair_idx]}]} = ${__input[__idx]} ]] && {
                            __final_pairs[$__idx]=$__pair_idx
                            __final_pairs[$__pair_idx]=$__idx
                            __pair_order+=( $__idx )
                        }
                    else
                        __pos_to_level[$__idx]=-1
                    fi
                fi
            }

            [[ ${match[1]} = \" && $__quoting != \' ]] && \
                if [[ $__quoting = '"' ]]; then
                    __Strings[$__level/${__Counts[$__level]}]+=" ${(q)__input[__sidx,__idx-1]}"
                    __quoting=""
                else
                    __had_quoted_value=1
                    __sidx=__idx+1
                    __quoting='"'
                fi

            [[ ${match[1]} = , && -z $__quoting ]] && \
                {
                    (( !__had_quoted_value )) && \
                        __Strings[$__level/${__Counts[$__level]}]+=" ${(q)__input[__sidx,__idx-1]//((#s)[[:blank:]]##|([[:blank:]]##(#e)))}"
                    __sidx=__idx+1
                    __had_quoted_value=0
                }

            [[ ${match[1]} = : && -z $__quoting ]] && \
                {
                    __had_quoted_value=0
                    __sidx=__idx+1
                }

            [[ ${match[1]} = \' && $__quoting != \" ]] && \
                if [[ $__quoting = "'" ]]; then
                    __Strings[$__level/${__Counts[$__level]}]+=" ${(q)__input[__sidx,__idx-1]}"
                    __quoting=""
                else
                    __had_quoted_value=1
                    __sidx=__idx+1
                    __quoting="'"
                fi

            __workbuf=${match[4]}
        }
    done

    local __text __found
    if (( __nest != 2 )) {
        integer __pair_a __pair_b
        for __pair_a ( "${__pair_order[@]}" ) {
            __pair_b="${__final_pairs[$__pair_a]}"
            __text="${__input[__pair_b,__pair_a]}"
            if [[ $__text = [[:space:]]#\{[[:space:]]#[\"\']${__key}[\"\']* ]]; then
                __found="$__text"
            fi
        }
    }

    if [[ -n $__found && $__nest -lt 2 ]] {
        -zplg-parse-json "$__found" "$__key" "$__varname" 2
    }

    if (( __nest == 2 )) {
        : ${(PAA)__varname::="${(kv)__Strings[@]}"}
    }
}
# }}}
# FUNCTION: -zplg-substitute {{{
-zplg-substitute() {
    local -A __subst_map
    __subst_map=(
        "%ID%"   "${id_as_clean:-$id_as}"
        "%USER%" "$user"
        "%PLUGIN%" "${plugin:-$save_url}"
        "%URL%" "${save_url:-${user:+$user/}$plugin}"
        "%DIR%" "${local_path:-$local_dir${dirname:+/$dirname}}"
        '$ZPFX' "$ZPFX"
        '${ZPFX}' "$ZPFX"
    )

    local __var_name
    for __var_name; do
        local __value=${(P)__var_name}
        __value=${__value//(#m)(${(~j.|.k)__subst_map})/${__subst_map[$MATCH]}}
        : ${(P)__var_name::=$__value}
    done
}
# }}}
# FUNCTION: -zplg-get-package {{{
-zplg-get-package() {
    emulate -LR zsh
    setopt extendedglob warncreateglobal typesetsilent noshortloops rcquotes

    local user="$1" plugin="$2" id_as="$3" dir="$4" profile="$5" \
        local_path="${ZPLGM[PLUGINS_DIR]}/${3//\//---}" pkgjson \
        tmpfile="${$(mktemp):-/tmp/zsh.xYzAbc123}" URL="https://registry.npmjs.org/."

    print -r -- "Downloading ${ZPLGM[col-info2]}package.json${ZPLGM[col-rst]}" \
        "for ${ZPLGM[col-pname]}$plugin${ZPLGM[col-rst]}"

    if [[ $profile != ./* ]]; then
        -zplg-download-file-stdout $URL/zsh-${plugin#zsh-} 2>/dev/null > $tmpfile || \
            { rm -f $tmpfile; -zplg-download-file-stdout $URL/zsh-${plugin#zsh-} 1 2>/dev/null > $tmpfile }
    else
        tmpfile=${profile%:*}
        profile=${${${(M)profile:#*:*}:+${profile#*:}}:-default}
    fi

    pkgjson="$(<$tmpfile)"

    if [[ -z $pkgjson ]]; then
        print -r -- "${ZPLGM[col-error]}Error: the package $id_as couldn't be found"
        return 1
    fi

    print -r -- "Parsing ${ZPLGM[col-info2]}package.json${ZPLGM[col-rst]}..."

    local -A Strings
    -zplg-parse-json "$pkgjson" "plugin-info" Strings

    local -A jsondata1
    jsondata1=( ${(@Q)${(@z)Strings[2/1]}} )
    local user=${jsondata1[user]} plugin=${jsondata1[plugin]} \
        url=${jsondata1[url]} message=${jsondata1[message]} \
        required=${jsondata1[required]:-${jsondata1[requires]}}

    integer pos
    pos=${${(@Q)${(@z)Strings[2/2]}}[(I)$profile]}
    if (( pos )) {
        ZPLG_ICE=( "${(@Q)${(@Q)${(@z)Strings[3/$(( (pos + 1) / 2 ))]}}}" "${(kv)ZPLG_ICE[@]}" id-as "$id_as" )
        [[ ${ZPLG_ICE[as]} = program ]] && ZPLG_ICE[as]=command
        [[ -n ${ZPLG_ICE[on-update-of]} ]] && ZPLG_ICE[subscribe]="${ZPLG_ICE[subscribe]:-${ZPLG_ICE[on-update-of]}}"
        [[ -n ${ZPLG_ICE[pick]} ]] && ZPLG_ICE[pick]="${ZPLG_ICE[pick]//\$ZPFX/${ZPFX%/}}"
    } else {
        print -r -- "${ZPLGM[col-error]}Error: the profile \`$profile' couldn't be found, aborting"
        return 1
    }

    local -a req
    req=( ${(s.;.)${required:-$required\;${ZPLG_ICE[required]}}} )
    for required ( $req ) {
        if [[ $required = bgn ]]; then
            if [[ -z ${(k)ZPLG_EXTS[(r)<-> z-annex-data: z-a-bin-gem-node *]} ]]; then
                print -- "${ZPLGM[col-error]}ERROR: the" \
                    "${${${(MS)ZPLG_ICE[required]##(\;|(#s))$required(\;|(#e))}:+selected profile}:-package}" \
                    "${${${(MS)ZPLG_ICE[required]##(\;|(#s))$required(\;|(#e))}:+\`${ZPLGM[col-pname]}$profile${ZPLGM[col-error]}\'}:-\\b}" \
                    "requires" "Bin-Gem-Node annex" \
                    "(see https://github.com/zplugin/z-a-bin-gem-node)"
                return 1
            fi
        else
            if ! command -v $required &>/dev/null; then
                print -- "${ZPLGM[col-error]}ERROR: the" \
                    "${${${(MS)ZPLG_ICE[required]##(\;|(#s))$required(\;|(#e))}:+selected profile}:-package}" \
                    "${${${(MS)ZPLG_ICE[required]##(\;|(#s))$required(\;|(#e))}:+\`${ZPLGM[col-pname]}$profile${ZPLGM[col-error]}\'}:-\\b}" \
                    "requires" \
                    "\`${ZPLGM[col-pname]}$required${ZPLGM[col-error]}' command"
                return 1
            fi
        fi
    }

    print -r -- "Found the profile \`${ZPLGM[col-pname]}$profile${ZPLGM[col-rst]}'"
    print -n -- \\n${jsondata1[version]:+${ZPLGM[col-pname]}Version: ${ZPLGM[col-info2]}${jsondata1[version]}${ZPLGM[col-rst]}\\n}
    [[ -n ${jsondata1[message]} ]] && \
        print -- "${ZPLGM[col-info]}${jsondata1[message]}${ZPLGM[col-rst]}"

    (( ${+ZPLG_ICE[is-snippet]} )) && {
        reply=( "" "$url" )
        REPLY=snippet
        return 0
    }

    if (( !${+ZPLG_ICE[git]} )) {
        (
            -zplg-parse-json "$pkgjson" "_from" Strings
            local -A jsondata
            jsondata=( "${(@Q)${(@z)Strings[1/1]}}" )

            local URL=${jsondata[_resolved]}
            local fname="${${URL%%\?*}:t}"

            command mkdir -p $dir || {
                print -r -- "${ZPLGM[col-error]}Couldn't create directory: \`$dir', aborting${ZPLGM[col-rst]}"
                return 1
            }
            builtin cd -q $dir || return 1

            print -r -- "Downloading tarball for ${ZPLGM[col-pname]}$plugin${ZPLGM[col-rst]}..."

            -zplg-download-file-stdout "$URL" >! "$fname" || {
                -zplg-download-file-stdout "$URL" 1 >! "$fname" || {
                    command rm -f "$fname"
                    print -r "Download of \`$fname' failed. No available download tool? (one of: cURL, wget, lftp, lynx)"
                    return 1
                }
            }

            -zplg-handle-binary-file "$URL" "$fname" --move
            return 0
        ) && {
            reply=( "$user" "$plugin" )
            REPLY=tarball
        }
    } else {
            reply=( "$user" "$plugin" )
            REPLY=git
    }

    return $?
}
# }}}
# FUNCTION: -zplg-setup-plugin-dir {{{
# Clones given plugin into PLUGIN_DIR. Supports multiple
# sites (respecting `from' and `proto' ice modifiers).
# Invokes compilation of plugin's main file.
#
# $1 - user
# $2 - plugin
-zplg-setup-plugin-dir() {
    emulate -LR zsh
    setopt extendedglob warncreateglobal noshortloops rcquotes

    local user=$1 plugin=$2 id_as=$3 remote_url_path=${1:+$1/}$2 \
        local_path=${ZPLGM[PLUGINS_DIR]}/${3//\//---} tpe=$4

    local -A sites
    sites=(
        github    github.com
        gh        github.com
        bitbucket bitbucket.org
        bb        bitbucket.org
        gitlab    gitlab.com
        gl        gitlab.com
        notabug   notabug.org
        nb        notabug.org
        github-rel github.com/$remote_url_path/releases
        gh-r      github.com/$remote_url_path/releases
    )

    local -A matchstr
    matchstr=(
        i386    "(386|686)"
        i686    "(386|686)"
        x86_64  "(x86_64|amd64|intel)"
        amd64   "(x86_64|amd64|intel)"
        aarch64 "aarch64"
        linux   "(linux|linux-gnu)"
        darwin  "(darwin|macos|mac-os|osx|os-x)"
        cygwin  "(windows|cygwin)"
        windows "(windows|cygwin)"
    )

    local -a arr

    if [[ $user = _local ]]; then
        print "Warning: no local plugin \`$plugin\'"
        print "(should be located at: $local_path)"
        return 1
    fi

    [[ $tpe != tarball ]] && {
        -zplg-any-colorify-as-uspl2 "$user" "$plugin"
        print "\\nDownloading $REPLY...${ZPLG_ICE[id-as]:+ (as ${id_as}...)}"


        local site
        [[ -n ${ZPLG_ICE[from]} ]] && site=${sites[${ZPLG_ICE[from]}]}
        [[ -z $site && ${ZPLG_ICE[from]} = *(gh-r|github-rel)* ]] && {
            site=${ZPLG_ICE[from]/(gh-r|github-re)/${sites[gh-r]}}
        }
    }

    (
        if [[ $site = *releases ]] {
            local url=$site/${ZPLG_ICE[ver]}
            local -a list list2

            list=( ${(@f)"$( { -zplg-download-file-stdout $url || -zplg-download-file-stdout $url 1; } 2>/dev/null | \
                          command grep -o 'href=./'$remote_url_path'/releases/download/[^"]\+')"} )
            list=( ${list[@]#href=?} )

            [[ -n ${ZPLG_ICE[bpick]} ]] && list=( ${(M)list[@]:#(#i)*/${~ZPLG_ICE[bpick]}} )

            [[ ${#list} -gt 1 ]] && {
                list2=( ${(M)list[@]:#(#i)*${~matchstr[$CPUTYPE]:-${CPUTYPE#(#i)(i|amd)}}*} )
                [[ ${#list2} -gt 0 ]] && list=( ${list2[@]} )
            }

            [[ ${#list} -gt 1 ]] && {
                list2=( ${(M)list[@]:#(#i)*${~matchstr[${${OSTYPE%(#i)-gnu}%%(-|)[0-9.]##}]:-${${OSTYPE%(#i)-gnu}%%(-|)[0-9.]##}}*} )
                [[ ${#list2} -gt 0 ]] && list=( ${list2[@]} )
            }

            [[ ${#list} -eq 0 ]] && {
                print "Didn't find correct Github release-file to download (for \`$remote_url_path'), try adapting bpick-ICE"
                return 1
            }

            command mkdir -p "$local_path"
            [[ -d "$local_path" ]] || return 1

            (
                () { setopt localoptions noautopushd; builtin cd -q "$local_path"; } || return 1
                url="https://github.com${list[1]}"
                print "(Requesting \`${list[1]:t}'...)"
                -zplg-download-file-stdout "$url" >! "${list[1]:t}" || {
                    -zplg-download-file-stdout "$url" 1 >! "${list[1]:t}" || {
                        command rm -f "${list[1]:t}"
                        print -r "Download of release for \`$remote_url_path' failed. No available download tool? (one of: curl, wget, lftp, lynx)"
                        print -r "Tried url: $url"
                        return 1
                    }
                }

                command mkdir -p ._zplugin
                print -r -- "$url" >! ._zplugin/url
                print -r -- "${list[1]}" >! ._zplugin/is_release
                -zplg-handle-binary-file "$url" "${list[1]:t}"
                return $?
            ) || {
                return 1
            }
        } elif [[ $tpe = git ]] {
            case "${ZPLG_ICE[proto]}" in
                (|https)
                    command git clone --progress ${=ZPLG_ICE[cloneopts]:---recursive} \
                        ${=ZPLG_ICE[depth]:+--depth ${ZPLG_ICE[depth]}} \
                        "https://${site:-${ZPLG_ICE[from]:-github.com}}/$remote_url_path" \
                        "$local_path" \
                        --config transfer.fsckobjects=false \
                        --config receive.fsckobjects=false \
                        --config fetch.fsckobjects=false \
                            |& { ${ZPLGM[BIN_DIR]}/git-process-output.zsh || cat; }
                    (( pipestatus[1] )) && { print "${ZPLGM[col-error]}Clone failed (code: ${pipestatus[1]})${ZPLGM[col-rst]}"; return 1; }
                    ;;
                (git|http|ftp|ftps|rsync|ssh)
                    command git clone --progress ${=ZPLG_ICE[cloneopts]:---recursive} \
                        ${=ZPLG_ICE[depth]:+--depth ${ZPLG_ICE[depth]}} \
                        "${ZPLG_ICE[proto]}://${site:-${ZPLG_ICE[from]:-github.com}}/$remote_url_path" \
                        "$local_path" \
                        --config transfer.fsckobjects=false \
                        --config receive.fsckobjects=false \
                        --config fetch.fsckobjects=false \
                            |& { ${ZPLGM[BIN_DIR]}/git-process-output.zsh || cat; }
                    (( pipestatus[1] )) && { print "${ZPLGM[col-error]}Clone failed (code: ${pipestatus[1]})${ZPLGM[col-rst]}"; return 1; }
                    ;;
                (*)
                    print "${ZPLGM[col-error]}Unknown protocol:${ZPLGM[col-rst]} ${ZPLG_ICE[proto]}"
                    return 1
            esac

            if [[ -n ${ZPLG_ICE[ver]} ]] {
                command git -C "$local_path" checkout "${ZPLG_ICE[ver]}"
            }
        }

        [[ ${+ZPLG_ICE[make]} = 1 && ${ZPLG_ICE[make]} = "!!"* ]] && -zplg-countdown make && { local make=${ZPLG_ICE[make]}; -zplg-substitute make; command make -C "$local_path" ${(@s; ;)${make#\!\!}}; }

        if [[ -n ${ZPLG_ICE[mv]} ]] {
            local from=${ZPLG_ICE[mv]%%[[:space:]]#->*} to=${ZPLG_ICE[mv]##*->[[:space:]]#}
            -zplg-substitute from to
            local -a afr
            ( () { setopt localoptions noautopushd; builtin cd -q "$local_path"; } || return 1
              afr=( ${~from}(DN) )
              [[ ${#afr} -gt 0 ]] && { command mv -vf "${afr[1]}" "$to"; command mv -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
            )
        }

        if [[ -n ${ZPLG_ICE[cp]} ]] {
            local from=${ZPLG_ICE[cp]%%[[:space:]]#->*} to=${ZPLG_ICE[cp]##*->[[:space:]]#}
            -zplg-substitute from to
            local -a afr
            ( () { setopt localoptions noautopushd; builtin cd -q "$local_path"; } || return 1
              afr=( ${~from}(DN) )
              [[ ${#afr} -gt 0 ]] && { command cp -vf "${afr[1]}" "$to"; command cp -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
            )
        }

        if [[ $site != *releases && ${ZPLG_ICE[nocompile]} != '!' ]] {
            # Compile plugin
            [[ -z ${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]} ]] && {
                -zplg-compile-plugin "$id_as" ""
            }
        }

        if [[ $4 != -u ]] {
            # Store ices at clone of a plugin
            -zplg-store-ices "$local_path/._zplugin" ZPLG_ICE "" "" "" ""

            reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atclone <->]}" )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                "${arr[5]}" "plugin" "$user" "$plugin" "$id_as" "$local_path" \!atclone
            done

            local atclone=${ZPLG_ICE[atclone]}
            [[ -n $atclone ]] && -zplg-substitute atclone

            [[ ${+ZPLG_ICE[make]} = 1 && ${ZPLG_ICE[make]} = ("!"[^\!]*|"!") ]] && -zplg-countdown make && { local make=${ZPLG_ICE[make]}; -zplg-substitute make; command make -C "$local_path" ${(@s; ;)${make#\!}}; }
            (( ${+ZPLG_ICE[atclone]} )) && -zplg-countdown "atclone" && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_path"; } && eval "$atclone"; ((1)); } || eval "$atclone"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }
            [[ ${+ZPLG_ICE[make]} = 1 && ${ZPLG_ICE[make]} != "!"* ]] && -zplg-countdown make && { local make=${ZPLG_ICE[make]}; -zplg-substitute make; command make -C "$local_path" ${(@s; ;)make}; }

            reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:atclone <->]}" )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                "${arr[5]}" "plugin" "$user" "$plugin" "$id_as" "$local_path" atclone
            done
        }

        # After additional executions like atclone'' - install completions (1 - plugins)
        [[ 1 = ${+ZPLG_ICE[nocompletions]} || ${ZPLG_ICE[as]} = null ]] || -zplg-install-completions "$id_as" "" "0" ${ZPLG_ICE[silent]+-q}

        if [[ $site != *releases && ${ZPLG_ICE[nocompile]} = '!' ]] {
            # Compile plugin
            LANG=C sleep 0.3
            [[ -z ${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]} ]] && {
                -zplg-compile-plugin "$id_as" ""
            }
        }
    ) || return $?

    return 0
} # }}}
# FUNCTION: -zplg-install-completions {{{
# Installs all completions of given plugin. After that they are
# visible to `compinit'. Visible completions can be selectively
# disabled and enabled. User can access completion data with
# `clist' or `completions' subcommand.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
# $3 - if 1, then reinstall, otherwise only install completions that aren't there
-zplg-install-completions() {
    builtin setopt localoptions nullglob extendedglob unset nokshglob warncreateglobal

    # $id_as - a /-separated pair if second element
    # is not empty and first is not "%" - then it's
    # just $1 in first case, or $1$2 in second case
    local id_as="$1${2:+${${${(M)1:#%}:+$2}:-/$2}}" reinstall="${3:-0}" quiet="${${4:+1}:-0}"

    -zplg-any-to-user-plugin "$id_as" ""
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"
    -zplg-any-colorify-as-uspl2 "$user" "$plugin"
    local abbrev_pspec="$REPLY"

    -zplg-exists-physically-message "$id_as" "" || return 1

    # Symlink any completion files included in plugin's directory
    typeset -a completions already_symlinked backup_comps
    local c cfile bkpfile
    [[ "$user" = "%" ]] && \
        completions=( "${plugin}"/**/_[^_.]*~*(*.zwc|*.html|*.txt|*.png|*.jpg|*.jpeg|*.js|_zsh_highlight*|/zsdoc/*)(DN^/) ) || \
        completions=( "${ZPLGM[PLUGINS_DIR]}/${id_as//\//---}"/**/_[^_.]*~*(*.zwc|*.html|*.txt|*.png|*.jpg|*.jpeg|*.js|_zsh_highlight*|/zsdoc/*)(DN^/) )
    already_symlinked=( "${ZPLGM[COMPLETIONS_DIR]}"/_[^_.]*~*.zwc(DN) )
    backup_comps=( "${ZPLGM[COMPLETIONS_DIR]}"/[^_.]*~*.zwc(DN) )

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
                command rm -f "${ZPLGM[COMPLETIONS_DIR]}/$cfile"
                command rm -f "${ZPLGM[COMPLETIONS_DIR]}/$bkpfile"
            fi
            (( quiet )) || print "Symlinking completion ${ZPLGM[col-uname]}$cfile${ZPLGM[col-rst]} to completions directory"
            command ln -s "$c" "${ZPLGM[COMPLETIONS_DIR]}/$cfile"
            # Make compinit notice the change
            -zplg-forget-completion "$cfile" "$quiet"
        else
            (( quiet )) || print "Not symlinking completion \`$cfile', it already exists"
            (( quiet )) || print "${ZPLGM[col-info2]}Use \`${ZPLGM[col-pname]}zplugin creinstall $abbrev_pspec${ZPLGM[col-info2]}' to force install${ZPLGM[col-rst]}"
        fi
    done
    -zplg-compinit &>/dev/null
} # }}}
# FUNCTION: -zplg-compinit {{{
# User-exposed `compinit' frontend which first ensures that all
# completions managed by Zplugin are forgotten by Zshell. After
# that it runs normal `compinit', which should more easily detect
# Zplugin's completions.
#
# No arguments.
-zplg-compinit() {
    builtin setopt localoptions nullglob extendedglob nokshglob noksharrays warncreateglobal

    typeset -a symlinked backup_comps
    local c cfile bkpfile action

    symlinked=( "${ZPLGM[COMPLETIONS_DIR]}"/_[^_.]*~*.zwc )
    backup_comps=( "${ZPLGM[COMPLETIONS_DIR]}"/[^_.]*~*.zwc )

    # Delete completions if they are really there, either
    # as completions (_fname) or backups (fname)
    for c in "${symlinked[@]}" "${backup_comps[@]}"; do
        action=0
        cfile="${c:t}"
        cfile="_${cfile#_}"
        bkpfile="${cfile#_}"

        #print "${ZPLGM[col-info]}Processing completion $cfile${ZPLGM[col-rst]}"
        -zplg-forget-completion "$cfile"
    done

    print "Initializing completion (compinit)..."
    command rm -f ${ZPLGM[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump}

    # Workaround for a nasty trick in _vim
    (( ${+functions[_vim_files]} )) && unfunction _vim_files

    builtin autoload -Uz compinit
    compinit -d ${ZPLGM[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZPLGM[COMPINIT_OPTS]}}"
} # }}}
# FUNCTION: -zplg-download-file-stdout {{{
# Downloads file to stdout. Supports following backend commands:
# curl, wget, lftp, lynx. Used by snippet loading.
-zplg-download-file-stdout() {
    local url="$1" restart="$2"

    setopt localoptions localtraps

    if (( restart )); then
        (( ${path[(I)/usr/local/bin]} )) || \
            {
                path+=( "/usr/local/bin" );
                trap "path[-1]=()" EXIT
            }

        if (( ${+commands[curl]} )) then
            command curl -fsSL "$url" || return 1
        elif (( ${+commands[wget]} )); then
            command wget -q "$url" -O - || return 1
        elif (( ${+commands[lftp]} )); then
            command lftp -c "cat $url" || return 1
        elif (( ${+commands[lynx]} )) then
            command lynx -source "$url" || return 1
        else
            return 2
        fi
    else
        if type curl 2>/dev/null 1>&2; then
            command curl -fsSL "$url" || return 1
        elif type wget 2>/dev/null 1>&2; then
            command wget -q "$url" -O - || return 1
        elif type lftp 2>/dev/null 1>&2; then
            command lftp -c "cat $url" || return 1
        else
            -zplg-download-file-stdout "$url" "1"
            return $?
        fi
    fi

    return 0
} # }}}
# FUNCTION: -zplg-mirror-using-svn {{{
# Used to clone subdirectories from Github. If in update mode
# (see $2), then invokes `svn update', in normal mode invokes
# `svn checkout --non-interactive -q <URL>'. In test mode only
# compares remote and local revision and outputs true if update
# is needed.
#
# $1 - URL
# $2 - mode, "" - normal, "-u" - update, "-t" - test
# $3 - subdirectory (not path) with working copy, needed for -t and -u
-zplg-mirror-using-svn() {
    setopt localoptions extendedglob warncreateglobal
    local url="$1" update="$2" directory="$3"

    (( ${+commands[svn]} )) || print -r -- "${ZPLGM[col-error]}Warning:${ZPLGM[col-rst]} Subversion not found, please install it to use \`svn' ice-mod"

    if [[ "$update" = "-t" ]]; then
        (
            () { setopt localoptions noautopushd; builtin cd -q "$directory"; }
            local -a out1 out2
            out1=( "${(f@)"$(LANG=C svn info -r HEAD)"}" )
            out2=( "${(f@)"$(LANG=C svn info)"}" )

            out1=( "${(M)out1[@]:#Revision:*}" )
            out2=( "${(M)out2[@]:#Revision:*}" )
            [[ "${out1[1]##[^0-9]##}" != "${out2[1]##[^0-9]##}" ]] && return 0
            return 1
        )
        return $?
    fi
    if [[ "$update" = "-u" && -d "$directory" && -d "$directory/.svn" ]]; then
        ( () { setopt localoptions noautopushd; builtin cd -q "$directory"; }
          command svn update
          return $? )
    else
        command svn checkout --non-interactive -q "$url" "$directory"
    fi
    return $?
}
# }}}
# FUNCTION: -zplg-forget-completion {{{
# Implements alternation of Zsh state so that already initialized
# completion stops being visible to Zsh.
#
# $1 - completion function name, e.g. "_cp"; can also be "cp"
-zplg-forget-completion() {
    local f="$1" quiet="$2"

    typeset -a commands
    commands=( "${(k@)_comps[(R)$f]}" ) # TODO: "${${(k)_comps[(R)$f]}[@]}" ?

    [[ "${#commands}" -gt 0 ]] && (( quiet == 0 )) && print -n "Forgetting commands completed by \`${ZPLGM[col-pname]}$f${ZPLGM[col-rst]}': "

    local k
    integer first=1
    for k in "${commands[@]}"; do
        [[ -n "$k" ]] || continue
        unset "_comps[$k]"
        (( quiet )) || print -n "${${first:#1}:+, }${ZPLGM[col-info]}$k${ZPLGM[col-rst]}"
        first=0
    done
    (( quiet || first )) || print

    unfunction -- 2>/dev/null "$f"
} # }}}
# FUNCTION: -zplg-compile-plugin {{{
# Compiles given plugin (its main source file, and also an
# additional "....zsh" file if it exists).
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-compile-plugin() {
    # $id_as - a /-separated pair if second element
    # is not empty and first is not "%" - then it's
    # just $1 in first case, or $1$2 in second case
    local id_as="$1${2:+${${${(M)1:#%}:+$2}:-/$2}}" first plugin_dir filename is_snippet
    local -a list

    local -A ICE
    -zplg-compute-ice "$id_as" "pack" \
        ICE plugin_dir filename is_snippet || return 1

    [[ "${ICE[pick]}" = "/dev/null" ]] && return 0

    if [[ ${ICE[as]} != "command" && ( ${+ICE[nocompile]} = "0" || ${ICE[nocompile]} = "!" ) ]]; then
        if [[ -n "${ICE[pick]}" ]]; then
            list=( ${~${(M)ICE[pick]:#/*}:-$plugin_dir/$ICE[pick]}(DN) )
            [[ ${#list} -eq 0 ]] && {
                print "No files for compilation found (pick-ice didn't match)"
                return 1
            }
            reply=( "${list[1]:h}" "${list[1]}" )
        else
            if (( is_snippet )) {
                -zplg-first "%" "$plugin_dir" || {
                    print "No files for compilation found"
                    return 1
                }
            } else {
                -zplg-first "$1" "$2" || {
                    print "No files for compilation found"
                    return 1
                }
            }
        fi
        local pdir_path="${reply[-2]}"
        first="${reply[-1]}"
        local fname="${first#$pdir_path/}"

        print "Compiling ${ZPLGM[col-info]}$fname${ZPLGM[col-rst]}..."
        [[ -z ${ICE[(i)(\!|)(sh|bash|ksh|csh)]} ]] && {
            zcompile "$first" || {
                print "Compilation failed. Don't worry, the plugin will work also without compilation"
                print "Consider submitting an error report to Zplugin or to the plugin's author"
            }
        }
        # Try to catch possible additional file
        zcompile "${${first%.plugin.zsh}%.zsh-theme}.zsh" 2>/dev/null
    fi

    if [[ -n "${ICE[compile]}" ]]; then
        eval "list=( \$plugin_dir/${~ICE[compile]}(DN) )"
        [[ ${#list} -eq 0 ]] && {
            print "Warning: Ice mod compile'' didn't match any files"
        } || {
            for first in "${list[@]}"; do
                zcompile "$first"
            done
            local sep="${ZPLGM[col-pname]},${ZPLGM[col-rst]} "
            print "Compiled following additional files (${ZPLGM[col-pname]}the compile''-ice${ZPLGM[col-rst]}): ${(pj:$sep:)${(@)${list[@]//(#b).([^.\/]##(#e))/.${ZPLGM[col-info]}${match[1]}${ZPLGM[col-rst]}}#$plugin_dir/}}"
        }
    fi

    return 0
} # }}}
# FUNCTION: -zplg-download-snippet {{{
# Downloads snippet – either a file – with curl, wget, lftp or lynx,
# or a directory, with Subversion – when svn-ICE is active. Github
# supports Subversion protocol and allows to clone subdirectories.
# This is used to provide a layer of support for Oh-My-Zsh and Prezto.
-zplg-download-snippet() {
    emulate -LR zsh
    setopt extendedglob warncreateglobal noshortloops

    local save_url="$1" url="$2" id_as="$3" id_as_clean="${3%%\?*}" local_dir="$4" dirname="$5" filename="$6" update="$7"
    local -a list arr
    integer retval=0
    [[ "$id_as" = (http|https|ftp|ftps|scp)://* ]] && {
        local sname="${${id_as_clean:h}:t}/${id_as_clean:t}"
        [[ "$sname" = */trunk* ]] && sname="${${id_as_clean%%/trunk*}:t}/${id_as_clean:t}"
    } || local sname="$id_as_clean"

    # Change the url to point to raw github content if it isn't like that
    [[ "$url" = *github.com* && ! "$url" = */raw/* && "${+ZPLG_ICE[svn]}" = "0" ]] && url="${url/\/blob\///raw/}"

    if [[ ! -d "$local_dir/$dirname" ]]; then
        [[ "$update" != "-u" ]] && print "\n${ZPLGM[col-info]}Setting up snippet ${ZPLGM[col-p]}${(l:10:: :)}$sname${ZPLGM[col-rst]}${ZPLG_ICE[id-as]:+... (as $id_as)}"
        command mkdir -p "$local_dir"
    fi

    [[ "$update" = "-u" && "${ICE_OPTS[opt_-q,--quiet]}" != 1 ]] && print -r -- $'\n'"${ZPLGM[col-info]}Updating snippet ${ZPLGM[col-p]}$sname${ZPLGM[col-rst]}${ZPLG_ICE[id-as]:+... (identified as $id_as)}"

    (
        if [[ "$url" = (http|https|ftp|ftps|scp)://* ]] {
            # URL
            (
                () { setopt localoptions noautopushd; builtin cd -q "$local_dir"; } || return 1

                [[ "${ICE_OPTS[opt_-q,--quiet]}" != 1 ]] && print "Downloading \`$sname'${${ZPLG_ICE[svn]+ \(with Subversion\)}:- \(with curl, wget, lftp\)}..."

                if (( ${+ZPLG_ICE[svn]} )) {
                    local skip_pull=0
                    if [[ "$update" = "-u" ]] {
                        # Test if update available
                        -zplg-mirror-using-svn "$url" "-t" "$dirname" || {
                            (( ${+ZPLG_ICE[run-atpull]} )) && {
                                skip_pull=1
                            } || return 2
                        }

                        (( !skip_pull )) && [[ "${ICE_OPTS[opt_-r,--reset]}" = 1 && -d "$filename/.svn" ]] && {
                            [[ "${ICE_OPTS[opt_-q,--quiet]}" != 1 ]] && print "Resetting the repository (-r/--reset given)..."
                            command svn revert --recursive $filename/.
                        }

                        # Run annexes' atpull hooks (the before atpull-ice ones)
                        [[ ${ZPLG_ICE[atpull][1]} = *"!"* ]] && {
                            reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atpull <->]}" )
                            for key in "${reply[@]}"; do
                                arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                                "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \!atpull

                            done
                        }

                        (( ${+ZPLG_ICE[reset]} )) && (
                            [[ "${ICE_OPTS[opt_-q,--quiet]}" != 1 ]] && print -P "%F{220}reset: running ${ZPLG_ICE[reset]:-svn revert --recursive $filename/.}%f"
                            eval "${ZPLG_ICE[reset]:-command svn revert --recursive $filename/.}"
                        )

                        [[ ${ZPLG_ICE[atpull][1]} = *"!"* ]] && -zplg-countdown "atpull" && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; ((1)); } || -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; };}

                        if (( !skip_pull )) {
                            # Do the update
                            # The condition is reversed on purpose – to show only
                            # the messages on an actual update
                            [[ "${ICE_OPTS[opt_-q,--quiet]}" = 1 ]] && {
                                print -r -- $'\n'"${ZPLGM[col-info]}Updating snippet ${ZPLGM[col-p]}$sname${ZPLGM[col-rst]}${ZPLG_ICE[id-as]:+... (identified as $id_as)}"
                                print "Downloading \`$sname'${${ZPLG_ICE[svn]+ \(with Subversion\)}:- \(with wget, curl, lftp\)}..."
                            }
                            -zplg-mirror-using-svn "$url" "-u" "$dirname" || return 1
                        }
                    } else {
                        -zplg-mirror-using-svn "$url" "" "$dirname" || return 1
                    }

                    # Redundant code, just to compile SVN snippet
                    if [[ ${ZPLG_ICE[as]} != "command" ]]; then
                        if [[ -n ${ZPLG_ICE[pick]} ]]; then
                            list=( ${(M)~ZPLG_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZPLG_ICE[pick]}(DN) )
                        elif [[ -z ${ZPLG_ICE[pick]} ]]; then
                            list=(
                                $local_dir/$dirname/*.plugin.zsh(DN) $local_dir/$dirname/*.zsh-theme(DN) $local_dir/$dirname/init.zsh(DN)
                                $local_dir/$dirname/*.zsh(DN) $local_dir/$dirname/*.sh(DN) $local_dir/$dirname/.zshrc(DN)
                            )
                        fi

                        [[ -e "${list[1]}" && "${list[1]}" != */dev/null && \
                            -z ${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]} ]] && \
                        {
                            (( !${+ZPLG_ICE[nocompile]} )) && {
                                zcompile "${list[1]}" &>/dev/null || {
                                    print -r "Warning: Couldn't compile \`${list[1]}'"
                                }
                            }
                        }
                    fi
                } else {
                    command mkdir -p "$local_dir/$dirname"

                    [[ "${ICE_OPTS[opt_-r,--reset]}" = 1 ]] && {
                        [[ "${ICE_OPTS[opt_-q,--quiet]}" != 1 && -f "$dirname/$filename" ]] && print "Removing the file (-r/--reset given)..."
                        command rm -f "$dirname/$filename"
                    }

                    # Run annexes' atpull hooks (the before atpull-ice ones)
                    [[ "$update" = "-u" && ${ZPLG_ICE[atpull][1]} = *"!"* ]] && {
                        reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atpull <->]}" )
                        for key in "${reply[@]}"; do
                            arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                            "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \!atpull
                        done
                    }

                    [[ "$update" = "-u" && ${ZPLG_ICE[atpull][1]} = *"!"* ]] && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; ((1)); } || -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; };}

                    -zplg-download-file-stdout "$url" >! "$dirname/$filename" || {
                        -zplg-download-file-stdout "$url" 1 >! "$dirname/$filename" || {
                            command rm -f "$dirname/$filename"
                            print -r "Download failed. No available download tool? (one of: curl, wget, lftp, lynx)"
                            return 1
                        }
                    }
                }
                return 0
            ) || retval=$?

            if [[ -n "${ZPLG_ICE[compile]}" ]]; then
                list=( ${(M)~ZPLG_ICE[compile]##/*}(DN) $local_dir/$dirname/${~ZPLG_ICE[compile]}(DN) )
                [[ ${#list} -eq 0 ]] && {
                    print "Warning: Ice-mod compile'' didn't match any files"
                } || {
                    local matched
                    for matched in "${list[@]}"; do
                        builtin zcompile "$matched"
                    done
                    ((1))
                }
            fi

            if [[ $ZPLG_ICE[as] != "command" ]] && (( ${+ZPLG_ICE[svn]} == 0 )); then
                local file_path="$local_dir/$dirname/$filename"
                if [[ -n "${ZPLG_ICE[pick]}" ]]; then
                    list=( ${(M)~ZPLG_ICE[pick]##/*}(DN) $local_dir/$dirname/${~ZPLG_ICE[pick]}(DN) )
                    file_path="${list[1]}"
                fi
                [[ -e $file_path && -z ${ZPLG_ICE[(i)(\!|)(sh|bash|ksh|csh)]} && $file_path != */dev/null ]] && {
                    (( !${+ZPLG_ICE[nocompile]} )) && {
                        zcompile "$file_path" 2>/dev/null || {
                            print -r "Couldn't compile \`${file_path:t}', it MIGHT be wrongly downloaded"
                            print -r "(snippet URL points to a directory instead of a file?"
                            print -r "to download directory, use preceding: zplugin ice svn)"
                            retval=1
                        }
                    }
                }
            fi
        } else {
            # File
            [[ "${ICE_OPTS[opt_-r,--reset]}" = 1 ]] && {
                [[ "${ICE_OPTS[opt_-q,--quiet]}" != 1 && -f "$local_dir/$dirname/$filename" ]] && print "Removing the file (-r/--reset given)..."
                command rm -f "$local_dir/$dirname/$filename"
            }

            # Run annexes' atpull hooks (the before atpull-ice ones)
            [[ "$update" = "-u" && ${ZPLG_ICE[atpull][1]} = *"!"* ]] && {
                reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atpull <->]}" )
                for key in "${reply[@]}"; do
                    arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                    "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \!atpull
                done
            }

            (( ${+ZPLG_ICE[reset]} )) && (
                [[ "${ICE_OPTS[opt_-q,--quiet]}" != 1 ]] && print -P "%F{220}reset: running ${ZPLG_ICE[reset]:-rm -f $local_dir/$dirname/$filename}%f"
                eval "${ZPLG_ICE[reset]:-command rm -f $local_dir/$dirname/$filename}"
            )

            [[ "$update" = "-u" && ${ZPLG_ICE[atpull][1]} = *"!"* ]] && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; ((1)); } || -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; };}

            # Currently redundant, but theoretically it has its place
            [[ -f "$local_dir/$dirname/$filename" ]] && command rm -f "$local_dir/$dirname/$filename"
            command mkdir -p "$local_dir/$dirname"
            print "Copying $filename..."
            command cp -v "$url" "$local_dir/$dirname/$filename" || { print -r -- "${ZPLGM[col-error]}An error occured${ZPLGM[col-rst]}"; retval=1; }
        }

        if [[ "${${:-$local_dir/$dirname}%%/##}" != "${ZPLGM[SNIPPETS_DIR]}" ]]; then
            # Store ices at "clone" and update of snippet, SVN and single-file
            local pfx="$local_dir/$dirname/._zplugin"
            -zplg-store-ices "$pfx" ZPLG_ICE "" "" "$save_url" "${+ZPLG_ICE[svn]}"
        else
            print "${ZPLGM[col-error]}Warning${ZPLGM[col-rst]}: inconsistency #2 occurred - skipped storing ice-mods to"
            print "disk, please report at https://github.com/zdharma/zplugin/issues"
            print "providing the commands \`zplugin ice {...}; zplugin snippet {...}'"
        fi

        (( retval == 1 )) && { command rmdir "$local_dir/$dirname" 2>/dev/null; return $retval; }

        (( retval == 2 )) && {
            # Run annexes' atpull hooks (the `always' after atpull-ice ones)
            reply=( ${(@on)ZPLG_EXTS[(I)z-annex hook:%atpull <->]} )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \%atpull
            done

            if [[ -n ${ZPLG_ICE[ps-on-update]} ]]; then
                (( quiet )) || print -r "Running plugin's provided update code: ${ZPLGM[col-info]}${ZPLG_ICE[ps-on-update][1,50]}${ZPLG_ICE[ps-on-update][51]:+…}${ZPLGM[col-rst]}"
                (
                    builtin cd -q "$local_dir/$dirname";
                    eval "${ZPLG_ICE[ps-on-update]}"
                )
            fi
            return 0;
        }

        [[ ${+ZPLG_ICE[make]} = 1 && ${ZPLG_ICE[make]} = "!!"* ]] && -zplg-countdown make && { local make=${ZPLG_ICE[make]}; -zplg-substitute make; command make -C "$local_dir/$dirname" ${(@s; ;)${make#\!\!}}; }

        if [[ -n "${ZPLG_ICE[mv]}" ]]; then
            local from="${ZPLG_ICE[mv]%%[[:space:]]#->*}" to="${ZPLG_ICE[mv]##*->[[:space:]]#}"
            -zplg-substitute from to
            local -a afr
            ( () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } || return 1
              afr=( ${~from}(DN) )
              [[ ${#afr} -gt 0 ]] && { command mv -vf "${afr[1]}" "$to"; command mv -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
            )
        fi

        if [[ -n "${ZPLG_ICE[cp]}" ]]; then
            local from="${ZPLG_ICE[cp]%%[[:space:]]#->*}" to="${ZPLG_ICE[cp]##*->[[:space:]]#}"
            -zplg-substitute from to
            local -a afr
            ( () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } || return 1
              afr=( ${~from}(DN) )
              [[ ${#afr} -gt 0 ]] && { command cp -vf "${afr[1]}" "$to"; command cp -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
            )
        fi

        [[ ${+ZPLG_ICE[make]} = 1 && ${ZPLG_ICE[make]} = ("!"[^\!]*|"!") ]] && -zplg-countdown make && { local make=${ZPLG_ICE[make]}; -zplg-substitute make; command make -C "$local_dir/$dirname" ${(@s; ;)${make#\!}}; }

        if [[ "$update" = "-u" ]]; then
            # Run annexes' atpull hooks (the before atpull-ice ones)
            [[ ${ZPLG_ICE[atpull][1]} != *"!"* ]] && {
                reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atpull <->]}" )
                for key in "${reply[@]}"; do
                    arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                    "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \!atpull
                done
            }

            [[ -n "${ZPLG_ICE[atpull]}" && ${ZPLG_ICE[atpull][1]} != *"!"* ]] && -zplg-countdown "atpull" && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; ((1)); } || -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; };}
        else
            # Run annexes' atclone hooks (the before atclone-ice ones)
            reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:\\\!atclone <->]}" )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \!atclone
            done

            local atclone=${ZPLG_ICE[atclone]}
            [[ -n $atclone ]] && -zplg-substitute atclone

            (( ${+ZPLG_ICE[atclone]} )) && -zplg-countdown "atclone" && { local __oldcd="$PWD"; (( ${+ZPLG_ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && eval "${ZPLG_ICE[atclone]}"; ((1)); } || eval "${ZPLG_ICE[atclone]}"; () { setopt localoptions noautopushd; builtin cd -q "$__oldcd"; }; }

            # Run annexes' atclone hooks (the after atclone-ice ones)
            reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:atclone <->]}" )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" atclone
            done
        fi

        [[ ${+ZPLG_ICE[make]} = 1 && ${ZPLG_ICE[make]} != "!"* ]] && -zplg-countdown make && { local make=${ZPLG_ICE[make]}; -zplg-substitute make; command make -C "$local_dir/$dirname" ${(@s; ;)make}; }

        # Run annexes' atpull hooks (the after atpull-ice ones)
        [[ "$update" = "-u" ]] && {
            reply=( "${(@on)ZPLG_EXTS[(I)z-annex hook:atpull <->]}" )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" atpull
            done
            # Run annexes' atpull hooks (the `always' after atpull-ice ones)
            reply=( ${(@on)ZPLG_EXTS[(I)z-annex hook:%atpull <->]} )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZPLG_EXTS[$key]}[@]}" )
                "${arr[5]}" "snippet" "$save_url" "$id_as" "$local_dir/$dirname" \%atpull
            done

            if [[ -n ${ZPLG_ICE[ps-on-update]} ]]; then
                (( quiet )) || print -r "Running plugin's provided update code: ${ZPLGM[col-info]}${ZPLG_ICE[ps-on-update][1,50]}${ZPLG_ICE[ps-on-update][51]:+…}${ZPLGM[col-rst]}"
                eval "${ZPLG_ICE[ps-on-update]}"
            fi
        }
        ((1))
    ) || return $?

    # After additional executions like atclone'' - install completions (2 - snippets)
    [[ 1 = ${+ZPLG_ICE[nocompletions]} || ${ZPLG_ICE[as]} = null ]] || -zplg-install-completions "%" "$local_dir/$dirname" 0
    return $retval
}
# }}}
# FUNCTION: -zplg-get-latest-gh-r-version {{{
# Gets version string of latest release of given Github
# package. Connects to Github releases page.
-zplg-get-latest-gh-r-version() {
    setopt localoptions extendedglob warncreateglobal

    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"

    local url="https://github.com/$user/$plugin/releases/latest"

    local -a list
    list=( ${(@f)"$( { -zplg-download-file-stdout $url || -zplg-download-file-stdout $url 1; } 2>/dev/null | \
                  command grep -o 'href=./'$user'/'$plugin'/releases/download/[^"]\+')"} )

    list=( "${(uOn)list[@]/(#b)href=?(\/[^\/]##)(#c4,4)\/([^\/]##)*/${match[2]}}" )
    REPLY="${list[1]}"
}
# }}}
# FUNCTION: -zplg-handle-binary-file {{{
# If the file is an archive, it is extracted by this function.
# Next stage is scanning of files with the common utility `file',
# to detect executables. They are given +x mode. There are also
# messages to the user on performed actions.
#
# $1 - url
# $2 - file
-zplg-handle-binary-file() {
    setopt localoptions extendedglob nokshglob warncreateglobal

    local url="$1" file="$2"
    integer move=${${(M)3:#--move}:+1}

    command mkdir -p ._backup
    command rm -rf ._backup/*(DN)
    command mv -f *~(._zplugin*|.zplugin_lstupd|._backup|.git|$file)(DN) ._backup 2>/dev/null

    -zplg-extract-wrapper() {
        local file="$1" fun="$2" retval
        print "Extracting files from: \`${ZPLGM[col-info2]}$file${ZPLGM[col-rst]}'..."
        $fun; retval=$?
        command rm -f "$file"
        return $retval
    }

    case "$file" in
        (*.zip)
            -zplg-extract() { command unzip "$file"; }
            ;;
        (*.rar)
            -zplg-extract() { command unrar x "$file"; }
            ;;
        (*.tar.bz2|*.tbz2)
            -zplg-extract() { command bzip2 -dc "$file" | command tar -xf -; }
            ;;
        (*.tar.gz|*.tgz)
            -zplg-extract() { command gzip -dc "$file" | command tar -xf -; }
            ;;
        (*.tar.xz|*.txz)
            -zplg-extract() { command xz -dc "$file" | command tar -xf -; }
            ;;
        (*.tar.7z|*.t7z)
            -zplg-extract() { command 7z x -so "$file" | command tar -xf -; }
            ;;
        (*.tar)
            -zplg-extract() { command tar -xf "$file"; }
            ;;
        (*.gz)
            -zplg-extract() { command gunzip "$file"; }
            ;;
    esac

    [[ $(typeset -f + -- -zplg-extract) == "-zplg-extract" ]] && {
        -zplg-extract-wrapper "$file" -zplg-extract || {
            print "Extraction of archive had problems, restoring previous version of the command"
            command mv ._backup/*(D) .
            return 1
        }
        unfunction -- -zplg-extract
    }
    unfunction -- -zplg-extract-wrapper

    local -a execs
    execs=( ${(@f)"$( file **/*~(._zplugin(|/*)|.git(|/*)|._backup(|/*))(DN-.) )"} )
    execs=( "${(M)execs[@]:#[^:]##:*executable*}" )
    execs=( "${execs[@]/(#b)([^:]##):*/${match[1]}}" )

    [[ ${#execs} -gt 0 ]] && {
        command chmod a+x "${execs[@]}"
        if [[ "${execs[1]}" = "$file" ]]; then
            print -r -- "Successfully downloaded and installed the executable: \`$file'."
        else
            print -r -- "Successfully installed executables (\"${(j:", ":)execs}\") contained in \`$file'."
        fi
    }

    (( move )) && {
        command mv -f **/*~(*/*/*|^*/*|._zplugin(|/*)|.git(|/*)|._backup(|/*))(DN) .
    }

    REPLY="${execs[1]}"
    return 0
}
# }}}
# FUNCTION: -zplg-at-eval {{{
-zplg-at-eval() {
    local atclone="$1" atpull="$2"
    -zplg-substitute atclone atpull
    [[ "$atpull" = "%atclone" ]] && { eval "$atclone"; ((1)); } || eval "$atpull"
}
# }}}

# vim:ft=zsh:sw=4:sts=4:et
