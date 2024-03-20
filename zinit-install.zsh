# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4;
# -*-
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors.

builtin source "${ZINIT[BIN_DIR]}/zinit-side.zsh" || {
    builtin print -P "${ZINIT[col-error]}ERROR:%f%b Couldn't find ${ZINIT[col-obj]}zinit-side.zsh%f%b."
    return 1
}

# FUNCTION: .zinit-jq-check [[[
# Check if jq is available and outputs an error message with instructions if
# that's not the case
.zinit-jq-check() {
    command -v jq >/dev/null && return 0

    +zi-log "{error}❌ ERROR: jq binary not found" \
        "{nl}{u-warn}Please install jq:{rst}" \
        "https://github.com/jqlang/jq" \
        "{nl}{u-warn}To do so with zinit, please refer to:{rst}" \
        "https://github.com/zdharma-continuum/zinit/wiki/%F0%9F%A7%8A-Recommended-ices#jq"
    return 1
} # ]]]
# FUNCTION: .zinit-json-get-value [[[
# Wrapper around jq that return the value of a property
#
# $1: JSON structure
# $2: jq path
.zinit-json-get-value() {
    .zinit-jq-check || return 1

    local jsonstr=$1 jqpath=$2
    jq -er ".${jqpath}" <<< "$jsonstr"
} # ]]]
# FUNCTION: .zinit-json-to-array [[[
# Wrapper around jq that sets key/values of an associative array, replicating
# the structure of a given JSON object
#
# $1: JSON structure
# $2: jq path
# $3: name of the associative array to store the key/value pairs in
.zinit-json-to-array() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt localoptions noglob

    .zinit-jq-check || return 1

    local jsonstr=$1 jqpath=$2 varname=$3

    (( ${(P)+varname} )) || typeset -gA "$varname"

    # NOTE We're not using @sh for the keys on purpose. Associative
    # array keys are used verbatim by zsh:
    # typeset -A a; a[key]=one; a['key']=two; echo ${(k)a}
    # 'key' key
    local evalstr=$(command jq -er --arg varname $varname \
        '.'${jqpath}' | to_entries |
        map($varname + "[\(.key)]=\(.value | @sh);")[]' \
        <<< "$jsonstr")
    eval "$evalstr"
} # ]]]
# FUNCTION: .zinit-get-package [[[
.zinit-get-package() {
    .zinit-jq-check || return 1

    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent noshortloops rcquotes

    local user=$1 pkg=$2 plugin=$2 id_as=$3 dir=$4 profile=$5 \
        ver=${ICE[ver]} local_path=${ZINIT[PLUGINS_DIR]}/${3//\//---} \
        pkgjson tmpfile=${$(mktemp):-${TMPDIR:-/tmp}/zsh.xYzAbc123}
    local URL=https://raw.githubusercontent.com/${ZINIT[PACKAGES_REPO]}/${ver:-${ZINIT[PACKAGES_BRANCH]}}/${pkg}/package.json

    # Consume (i.e., delete) the ver ice to avoid being consumed again at git-clone time
    [[ -n "$ver" ]] && unset 'ICE[ver]'

    local pro_sep="{rst}, {profile}" epro_sep="{error}, {profile}" \
        tool_sep="{rst}, {cmd}" \
        lhi_hl="{lhi}" profile_hl="{profile}"

    trap "rmdir ${(qqq)local_path} 2>/dev/null; return 1" INT TERM QUIT HUP
    trap "rmdir ${(qqq)local_path} 2>/dev/null" EXIT

    # Check if we were provided with a local path to a package.json
    # as in:
    # zinit pack'/zp/firefox-dev/package.json:default' for firefox-dev
    if [[ $profile == ./* || $profile == /* ]] {
        local localpkg=1
        # FIXME below only works if there are no ':' in the path
        tmpfile=${profile%:*}
        profile=${${${(M)profile:#*:*}:+${profile#*:}}:-default}
    } elif { ! .zinit-download-file-stdout $URL 0 1 2>/dev/null > $tmpfile } {
        # retry
        command rm -f $tmpfile
        .zinit-download-file-stdout $URL 1 1 2>/dev/null >1 $tmpfile
    }

    # load json from file
    [[ -e $tmpfile ]] && pkgjson="$(<$tmpfile)"

    # Set package name (used later in the output)
    local pkgname=${${id_as##_unknown}:-${pkg:-${plugin}}}
    [[ -n "$localpkg" ]] && pkgname="{pid}$pkgname{rst} {note}[$tmpfile]{rst}"

    if [[ -z $pkgjson ]] {
        +zi-log "{error}❌ Error: the package {hi}${pkgname}" \
                       "{error}couldn't be found.{rst}"
        return 1
    }

    # root field, where the relevant data is stored
    local json_root='["zsh-data"]'
    local json_ices="${json_root}[\"zinit-ices\"]"
    local json_meta="${json_root}[\"plugin-info\"]"

    local -a profiles
    profiles=("${(@f)$(.zinit-json-get-value "$pkgjson" "${json_ices} | keys[]")}") \
        || return 1

    # Check if user requested an unknown profile
    if ! (( ${profiles[(I)${profile}]} )) {
        # Assumption: the default profile is the first in the table (-> different color).
        +zi-log "{u-warn}Error{b-warn}:{error} the profile {apo}\`{hi}$profile{apo}\`" \
            "{error}couldn't be found, aborting. Available profiles are:" \
            "{lhi}${(pj:$epro_sep:)profiles[@]}{error}.{rst}"
        return 1
    }
    local json_profile="${json_ices}[\"${profile}\"]"

    local -A metadata
    .zinit-json-to-array "$pkgjson" "$json_meta" metadata
    if [[ "$?" -ne 0 || -z "$metadata" ]] {
        +zi-log '{error}❌ ERROR: Failed to retrieve metadata from package.json'
        return 1
    }

    local user=${metadata[user]} plugin=${metadata[plugin]} \
        message=${metadata[message]} url=${metadata[url]}

    .zinit-json-to-array "$pkgjson" "$json_profile" ICE
    local -a requirements

    # FIXME requires shouldn't be stored under zinit-ices...
    if [[ -n "$ICE[requires]" ]] {
        # split requirements on ';'
        requirements=(${(s.;.)${ICE[requires]}})
        unset 'ICE[requires]'
    }

    [[ ${ICE[as]} == program ]] && ICE[as]="command"
    [[ -n ${ICE[on-update-of]} ]] && ICE[subscribe]="${ICE[subscribe]:-${ICE[on-update-of]}}"
    [[ -n ${ICE[pick]} ]] && ICE[pick]="${ICE[pick]//\$ZPFX/${ZPFX%/}}"

    # FIXME Do we even need that? If yes, we may want to do that in
    # .zinit-json-to-array
    if [[ -n ${ICE[id-as]} ]] {
        @zinit-substitute 'ICE[id-as]'
        local -A map
        map=( "\"" "\\\"" "\\" "\\" )
        eval "ICE[id-as]=\"${ICE[id-as]//(#m)[\"\\]/${map[$MATCH]}}\""
    }

    +zi-log "{info3}Package{ehi}:{rst} ${pkgname}. Selected" \
        "profile{ehi}:{rst} {hi}$profile{rst}. Available" \
        "profiles:${${${(M)profile:#default}:+$lhi_hl}:-$profile_hl}" \
        "${(pj:$pro_sep:)profiles[@]}{rst}."

    if [[ $profile != *bgn* && -n ${(M)profiles[@]:#*bgn*} ]] {
        +zi-log "{note}Note:{rst} The {apo}\`{profile}bgn{glob}*{apo}\`{rst}" \
            "profiles (if any are available) are the recommended ones (the reason" \
            "is that they expose the binaries provided by the package without" \
            "altering (i.e.: {slight}cluttering{rst}{…}) the {var}\$PATH{rst}" \
            "environment variable)."
    }

    local required
    for required ( $requirements ) {
        if [[ $required == (bgn|dl|monitor) ]]; then
            if [[ ( $required == bgn && -z ${(k)ZINIT_EXTS[(r)<-> z-annex-data: zinit-annex-bin-gem-node *]} ) || \
                ( $required == dl && -z ${(k)ZINIT_EXTS[(r)<-> z-annex-data: zinit-annex-patch-dl *]} ) || \
                ( $required == monitor && -z ${(k)ZINIT_EXTS[(r)<-> z-annex-data: zinit-annex-readurl *]} )
            ]]; then
                local -A namemap
                namemap=( bgn bin-gem-node dl patch-dl monitor readurl )
                +zi-log -n "{u-warn}ERROR{b-warn}: {error}the "
                if [[ -z ${(MS)ICE[requires]##(\;|(#s))$required(\;|(#e))} ]]; then
                    +zi-log -n "{error}requested profile {apo}\`{hi}$profile{apo}\`{error} "
                else
                    +zi-log -n "{error}package {pid}$pkg{error} "
                fi
                +zi-log '{error}requires the {apo}`{annex}'${namemap[$required]}'{apo}`' \
                    "{error}annex, which is currently not installed." \
                    "{nl}{nl}If you'd like to install it, you can visit its homepage:" \
                    "{nl}– {url}https://github.com/zdharma-continuum/zinit-annex-${(L)namemap[$required]}{rst}" \
                    "{nl}for instructions."
                (( ${#profiles[@]:#$profile} > 0 )) && \
                    +zi-log "{nl}Other available profiles are:" \
"{profile}${(pj:$pro_sep:)${profiles[@]:#$profile}}{rst}."

                return 1
            fi
        else
            if ! command -v $required &>/dev/null; then
                +zi-log -n "{u-warn}ERROR{b-warn}: {error}the "
                if [[ -n ${(MS)ICE[requires]##(\;|(#s))$required(\;|(#e))} ]]; then
                    +zi-log -n "{error}requested profile {apo}\`{hi}$profile{apo}\`{error} "
                else
                    +zi-log -n "{error}package {pid}$pkg{error} "
                fi
                +zi-log '{error}requires a {apo}`{cmd}'$required'{apo}`{error}' \
                    "command to be available in {var}\$PATH{error}.{rst}" \
                    "{nl}{error}The package cannot be installed unless the" \
                    "command will be available."
                (( ${#profiles[@]:#$profile} > 0 )) && \
                    +zi-log "{nl}Other available profiles are:" \
                        "{profile}${(pj:$pro_sep:)${profiles[@]:#$profile}}{rst}."
                return 1
            fi
        fi
    }

    if [[ -n ${ICE[dl]} && -z ${(k)ZINIT_EXTS[(r)<-> z-annex-data: zinit-annex-patch-dl *]} ]] {
        +zi-log "{nl}{u-warn}WARNING{b-warn}:{rst} the profile uses" \
            "{ice}dl''{rst} ice however there's currently no {annex}zinit-annex-patch-dl{rst}" \
            "annex loaded, which provides it."
        +zi-log "The ice will be inactive, i.e.: no additional" \
            "files will become downloaded (the ice downloads the given URLs)." \
            "The package should still work, as it doesn't indicate to" \
            "{u}{slight}require{rst} the annex."
        +zi-log "{nl}You can download the" \
            "annex from its homepage at {url}https://github.com/zdharma-continuum/zinit-annex-patch-dl{rst}."
    }

    [[ -n ${message} ]] && +zi-log "{info}${message}{rst}"

    if (( ${+ICE[is-snippet]} )) {
        reply=( "" "$url" )
        REPLY=snippet
        return 0
    }

    # FIXME This part below is a bit odd since it essentially replicates what
    # the dl ice supposed to be doing.
    # TL;DR below downloads whatever url is stored in the "_resolved" field
    if (( !${+ICE[git]} && !${+ICE[from]} )) {
        (
            local -A jsondata
            local URL=$(.zinit-json-get-value "$pkgjson" "_resolved")
            local fname="${${URL%%\?*}:t}"

            command mkdir -p $dir || {
                +zi-log "{u-warn}Error{b-warn}:{error} Couldn't create directory:" \
                    "{dir}$dir{error}, aborting.{rst}"
                return 1
            }
            builtin cd -q $dir || return 1

            +zi-log "Downloading tarball for {pid}$plugin{rst}{…}"

            if { ! .zinit-download-file-stdout "$URL" 0 1 >! "$fname" } {
                if { ! .zinit-download-file-stdout "$URL" 1 1 >! "$fname" } {
                    command rm -f "$fname"
                    +zi-log "Download of the file {apo}\`{file}$fname{apo}\`{rst}" \
                        "failed. No available download tool? One of:" \
                        "{cmd}${(pj:$tool_sep:)${=:-curl wget lftp lynx}}{rst}."

                    return 1
                }
            }

            # --move is default (or as explicit, when extract'!…' is given)
            # Also possible is --move2 when extract'!!…' given
            ziextract "$fname" ${ICE[extract]---move} ${${(M)ICE[extract]:#!([^!]|(#e))*}:+--move} ${${(M)ICE[extract]:#!!*}:+--move2}
            return 0
        ) && {
            reply=( "$user" "$plugin" )
            REPLY=tarball
        }
    } else {
            reply=( "${ICE[user]:-$user}" "${ICE[plugin]:-$plugin}" )
            if [[ ${ICE[from]} = (|gh-r|github-rel) ]]; then
                REPLY=github
            else
                REPLY=unknown
            fi
    }

    return $?
} # ]]]
# FUNCTION: .zinit-setup-plugin-dir [[[
# Clones given plugin into PLUGIN_DIR. Supports multiple
# sites (respecting `from' and `proto' ice modifiers).
# Invokes compilation of plugin's main file.
#
# $1 - user
# $2 - plugin
.zinit-setup-plugin-dir() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal noshortloops rcquotes

    local user=$1 plugin=$2 id_as=$3 remote_url_path=${1:+$1/}$2 \
        local_path tpe=$4 update=$5 version=$6

    if .zinit-get-object-path plugin "$id_as" && [[ -z $update ]] {
        +zi-log "{u-warn}ERROR{b-warn}:{error} A plugin named {pid}$id_as{error}" \
                "already exists, aborting."
        return 1
    }
    local_path=$REPLY

    trap "rmdir ${(qqq)local_path}/._zinit ${(qqq)local_path} 2>/dev/null" EXIT
    trap "rmdir ${(qqq)local_path}/._zinit ${(qqq)local_path} 2>/dev/null; return 1" INT TERM QUIT HUP

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
        cygwin    cygwin
    )

    ZINIT[annex-multi-flag:pull-active]=${${${(M)update:#-u}:+${ZINIT[annex-multi-flag:pull-active]}}:-2}

    local -a arr

    if [[ $user = _local ]]; then
        builtin print "Warning: no local plugin \`$plugin\'."
        builtin print "(should be located at: $local_path)"
        return 1
    fi

    command rm -f ${TMPDIR:-/tmp}/zinit-execs.$$.lst ${TMPDIR:-/tmp}/zinit.installed_comps.$$.lst \
                  ${TMPDIR:-/tmp}/zinit.skipped_comps.$$.lst ${TMPDIR:-/tmp}/zinit.compiled.$$.lst

    if [[ $tpe != tarball ]] {
        if [[ -z $update ]] {
            .zinit-any-colorify-as-uspl2 "$user" "$plugin"
            local pid_hl='{pid}' id_msg_part=" (at label: {id-as}$id_as{rst})"
            +zi-log "{nl}{i} Downloading {b}{file}$user${user:+/}$plugin{rst} ${${${id_as:#$user/$plugin}}:+$id_msg_part}{rst}"
        }

        local site
        [[ -n ${ICE[from]} ]] && site=${sites[${ICE[from]}]}
        if [[ -z $site && ${ICE[from]} = *(gh-r|github-rel)* ]] {
            site=${ICE[from]/(gh-r|github-re)/${sites[gh-r]}}
        }
    }

    (
        if [[ $site = */releases ]] {
            local tag_version=${ICE[ver]}
            if [[ -z $tag_version ]]; then
                tag_version="$({.zinit-download-file-stdout $site/latest || .zinit-download-file-stdout $site/latest 1;} 2>/dev/null | command grep -i -m 1 -o 'href=./'$user'/'$plugin'/releases/tag/[^"]\+')"
                tag_version=${tag_version##*/}
            fi
            local url=$site/expanded_assets/$tag_version

            .zinit-get-latest-gh-r-url-part "$user" "$plugin" "$url" || return $?

            command mkdir -p "$local_path"
            [[ -d "$local_path" ]] || return 1

            (
                () { setopt localoptions noautopushd; builtin cd -q "$local_path"; } || return 1
                integer count

                for REPLY ( $reply ) {
                    count+=1
                    url="https://github.com${REPLY}"
                    if [[ -d $local_path/._zinit ]] {
                        { local old_version="$(<$local_path/._zinit/is_release${count:#1})"; } 2>/dev/null
                        old_version=${old_version/(#b)(\/[^\/]##)(#c4,4)\/([^\/]##)*/${match[2]}}
                    }
                    +zi-log "{m} Requesting ${REPLY:t} ${version:+, version $version} ${old_version:+ Current version: $old_version.}{rst}"
                    if { ! .zinit-download-file-stdout "$url" 0 1 >! "${REPLY:t}" } {
                        if { ! .zinit-download-file-stdout "$url" 1 1 >! "${REPLY:t}" } {
                            command rm -f "${REPLY:t}"
                            +zi-log "Download of release for \`$remote_url_path' " \
                                "failed.{nl}Tried url: $url."
                            return 1
                        }
                    }
                    if .zinit-download-file-stdout "$url.sig" 2>/dev/null >! "${REPLY:t}.sig"; then
                        :
                    else
                        command rm -f "${REPLY:t}.sig"
                    fi

                    command mkdir -p ._zinit && echo '*' > ._zinit/.gitignore
                    [[ -d ._zinit ]] || return 2
                    builtin print -r -- $url >! ._zinit/url || return 3
                    builtin print -r -- ${REPLY} >! ._zinit/is_release${count:#1} || return 4
                    ziextract ${REPLY:t} ${${${#reply}:#1}:+--nobkp} ${${(M)ICE[extract]:#!([^!]|(#e))*}:+--move} ${${(M)ICE[extract]:#!!*}:+--move2}
                }
                return $?
            ) || {
                return 1
            }
        } elif [[ $site = cygwin ]] {
            command mkdir -p "$local_path/._zinit" && echo '*' > "$local_path/._zinit/.gitignore"
            [[ -d "$local_path" ]] || return 1

            (
                () { setopt localoptions noautopushd; builtin cd -q "$local_path"; } || return 1
                .zinit-get-cygwin-package "$remote_url_path" || return 1
                builtin print -r -- $REPLY >! ._zinit/is_release
                ziextract "$REPLY"
            ) || return $?
        } elif [[ $tpe = github ]] {
            case ${ICE[proto]} in
                (|ftp(|s)|git|http(|s)|rsync|ssh)
                    :zinit-git-clone() {
                        command git clone --progress ${(s: :)ICE[cloneopts]---recursive} \
                            ${(s: :)ICE[depth]:+--depth ${ICE[depth]}} \
                            "${ICE[proto]:-https}://${site:-${ICE[from]:-github.com}}/$remote_url_path" \
                            "$local_path" \
                            --config transfer.fsckobjects=false \
                            --config receive.fsckobjects=false \
                            --config fetch.fsckobjects=false \
                            --config pull.rebase=false
                            integer retval=$?
                            unfunction :zinit-git-clone
                            return $retval
                    }
                    :zinit-git-clone |& { command ${ZINIT[BIN_DIR]}/share/git-process-output.zsh || cat; }
                    if (( pipestatus[1] == 141 )) {
                        :zinit-git-clone
                        integer retval=$?
                        if (( retval )) {
                            builtin print -Pr -- "$ZINIT[col-error]Clone failed (code: $ZINIT[col-obj]$retval$ZINIT[col-error]).%f%b"
                            return 1
                        }
                    } elif (( pipestatus[1] )) {
                        builtin print -Pr -- "$ZINIT[col-error]Clone failed (code: $ZINIT[col-obj]$pipestatus[1]$ZINIT[col-error]).%f%b"
                        return 1
                    }
                    ;;
                (*)
                    builtin print -Pr "${ZINIT[col-error]}Unknown protocol:%f%b ${ICE[proto]}."
                    return 1
            esac

            if [[ -n ${ICE[ver]} ]] {
                command git -C "$local_path" checkout "${ICE[ver]}"
            }
        }

        if [[ $update != -u ]] {
            hook_rc=0
            # Store ices at clone of a plugin
            .zinit-store-ices "$local_path/._zinit" ICE "" "" "" ""
            reply=(
                ${(on)ZINIT_EXTS2[(I)zinit hook:\!atclone-pre <->]}
                ${(on)ZINIT_EXTS[(I)z-annex hook:\!atclone-<-> <->]}
                ${(on)ZINIT_EXTS2[(I)zinit hook:\!atclone-post <->]}
            )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                # Functions calls
                "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$local_path" "${${key##(zinit|z-annex) hook:}%% <->}" load
                hook_rc=$?
                [[ "$hook_rc" -ne 0 ]] && {
                    # note: this will effectively return the last != 0 rc
                    retval="$hook_rc"
                    builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                }
            done

            # Run annexes' atclone hooks (the after atclone-ice ones)
            reply=(
                ${(on)ZINIT_EXTS2[(I)zinit hook:atclone-pre <->]}
                ${(on)ZINIT_EXTS[(I)z-annex hook:atclone-<-> <->]}
                ${(on)ZINIT_EXTS2[(I)zinit hook:atclone-post <->]}
            )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$local_path" "${${key##(zinit|z-annex) hook:}%% <->}"
                hook_rc=$?
                [[ "$hook_rc" -ne 0 ]] && {
                    retval="$hook_rc"
                    builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                }
            done
        }

        return "$retval"
    ) || return $?

    typeset -ga INSTALLED_EXECS
    { INSTALLED_EXECS=( "${(@f)$(<${TMPDIR:-/tmp}/zinit-execs.$$.lst)}" ) } 2>/dev/null

    # After additional executions like atclone'' - install completions (1 - plugins)
    local -A OPTS
    OPTS[opt_-q,--quiet]=1
    [[ (0 = ${+ICE[nocompletions]} && ${ICE[as]} != null && ${+ICE[null]} -eq 0) || 0 != ${+ICE[completions]} ]] && \
        .zinit-install-completions "$id_as" "" "0"

    if [[ -e ${TMPDIR:-/tmp}/zinit.skipped_comps.$$.lst || -e ${TMPDIR:-/tmp}/zinit.installed_comps.$$.lst ]] {
        typeset -ga INSTALLED_COMPS SKIPPED_COMPS
        { INSTALLED_COMPS=( "${(@f)$(<${TMPDIR:-/tmp}/zinit.installed_comps.$$.lst)}" ) } 2>/dev/null
        { SKIPPED_COMPS=( "${(@f)$(<${TMPDIR:-/tmp}/zinit.skipped_comps.$$.lst)}" ) } 2>/dev/null
    }

    if [[ -e ${TMPDIR:-/tmp}/zinit.compiled.$$.lst ]] {
        typeset -ga ADD_COMPILED
        { ADD_COMPILED=( "${(@f)$(<${TMPDIR:-/tmp}/zinit.compiled.$$.lst)}" ) } 2>/dev/null
    }

    # After any download – rehash the command table
    # This will however miss the as"program" binaries
    # as their PATH gets extended - and it is done
    # later. It will however work for sbin'' ice.
    (( !OPTS[opt_-p,--parallel] )) && rehash

    return 0
} # ]]]
# FUNCTION: .zinit-install-completions [[[
# Installs all completions of given plugin. After that they are visible to
# 'compinit'. Visible completions can be selectively disabled and enabled. User
# can access completion data with 'completions' subcommand.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin if $1 (i.e., user) given
# $3 - if 1, then reinstall, otherwise only install completions that are not present
.zinit-install-completions() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt nullglob extendedglob warncreateglobal typesetsilent noshortloops

    local id_as=$1${2:+${${${(M)1:#%}:+$2}:-/$2}}
    local reinstall=${3:-0} quiet=${${4:+1}:-0}
    (( OPTS[opt_-q,--quiet] )) && quiet=1
    [[ $4 = -Q ]] && quiet=2
    typeset -ga INSTALLED_COMPS SKIPPED_COMPS
    INSTALLED_COMPS=() SKIPPED_COMPS=()

    .zinit-any-to-user-plugin "$id_as" ""
    local user=${reply[-2]}
    local plugin=${reply[-1]}
    .zinit-any-colorify-as-uspl2 "$user" "$plugin"
    local abbrev_pspec=$REPLY

    .zinit-exists-physically-message "$id_as" "" || return 1

    # Symlink any completion files included in the plugin directory
    typeset -a completions already_symlinked backup_comps
    local c cfile bkpfile
    # The plugin == . is a semi-hack/trick to handle 'creinstall .' properly
    [[ $user == % || ( -z $user && $plugin == . ) ]] && \
        completions=( "${plugin}"/**/_[^_.]*~*(*.zwc|*.html|*.txt|*.png|*.jpg|*.jpeg|*.js|*.md|*.yml|*.yaml|*.py|*.ri|_zsh_highlight*|/zsdoc/*|*.ps1)(DN^/) ) || \
        completions=( "${ZINIT[PLUGINS_DIR]}/${id_as//\//---}"/**/_[^_.]*~*(*.zwc|*.html|*.txt|*.png|*.jpg|*.jpeg|*.js|*.md|*.yml|*.yaml|*.py|*.ri|_zsh_highlight*|/zsdoc/*|*.ps1)(DN^/) )
    already_symlinked=( "${ZINIT[COMPLETIONS_DIR]}"/_[^_.]*~*.zwc(DN) )
    backup_comps=( "${ZINIT[COMPLETIONS_DIR]}"/[^_.]*~*.zwc(DN) )

    # Symlink completions if they are not already there
    # either as completions (_fname) or as backups (fname)
    # OR - if its a reinstall
    for c in "${completions[@]:A}"; do
        cfile="${c:t}"
        bkpfile="${cfile#_}"
        if [[ ( -z ${already_symlinked[(r)*/$cfile]} || $reinstall = 1 ) &&
              -z ${backup_comps[(r)*/$bkpfile]}
        ]]; then
            if [[ $reinstall = 1 ]]; then
                # Remove old files
                command rm -f "${ZINIT[COMPLETIONS_DIR]}/$cfile" "${ZINIT[COMPLETIONS_DIR]}/$bkpfile"
            fi
            INSTALLED_COMPS+=( $cfile )
            (( quiet )) || builtin print -Pr "Symlinking completion ${ZINIT[col-uname]}$cfile%f%b to completions directory."
            command ln -fs "$c" "${ZINIT[COMPLETIONS_DIR]}/$cfile"
            # Make compinit notice the change
            .zinit-forget-completion "$cfile" "$quiet"
        else
            SKIPPED_COMPS+=( $cfile )
            (( quiet )) || builtin print -Pr "Not symlinking completion \`${ZINIT[col-obj]}$cfile%f%b', it already exists."
            (( quiet )) || builtin print -Pr "${ZINIT[col-info2]}Use \`${ZINIT[col-pname]}zinit creinstall $abbrev_pspec${ZINIT[col-info2]}' to force install.%f%b"
        fi
    done

    local comps msg
    local -A comp_types=(\$INSTALLED_COMPS 'Installed' \$SKIPPED_COMPS 'Skipped re-installing')
    for comps msg in ${(kv)comp_types}; do
        local comps_num=${#${(e)comps}}
        if (( comps_num > 0 )); then
            +zi-log "{m} ${msg} {num}$comps_num{rst} completion${=${comps_num:#1}:+s}"
            if (( quiet == 0 )); then
                +zi-log "{m} Added $comps_num completion${=${comps_num:#1}:+s} to {var}$comps{rst} array"
            fi
        fi
    done

    if (( ZSH_SUBSHELL )) {
        builtin print -rl -- $INSTALLED_COMPS >! ${TMPDIR:-/tmp}/zinit.installed_comps.$$.lst
        builtin print -rl -- $SKIPPED_COMPS >! ${TMPDIR:-/tmp}/zinit.skipped_comps.$$.lst
    }

    .zinit-compinit 1 1 &>/dev/null
} # ]]]
# FUNCTION: .zinit-compinit [[[
# User-exposed `compinit' frontend which first ensures that all
# completions managed by Zinit are forgotten by Zshell. After
# that it runs normal `compinit', which should more easily detect
# Zinit's completions.
#
# No arguments.
.zinit-compinit() {
    # This might be called during sourcing when setting up the plugins dir, so check that OPTS is actually existing
    [[ -n $OPTS && -n ${OPTS[opt_-p,--parallel]} && $1 != 1 ]] && return

    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    builtin setopt nullglob extendedglob warncreateglobal typesetsilent

    integer use_C=$2

    typeset -a symlinked backup_comps
    local c cfile bkpfile action

    symlinked=( "${ZINIT[COMPLETIONS_DIR]}"/_[^_.]*~*.zwc )
    backup_comps=( "${ZINIT[COMPLETIONS_DIR]}"/[^_.]*~*.zwc )

    # Delete completions if they are really there, either
    # as completions (_fname) or backups (fname)
    for c in "${symlinked[@]}" "${backup_comps[@]}"; do
        action=0
        cfile="${c:t}"
        cfile="_${cfile#_}"
        bkpfile="${cfile#_}"

        #print -Pr "${ZINIT[col-info]}Processing completion $cfile%f%b"
        .zinit-forget-completion "$cfile"
    done

    +zi-log "Initializing completion ({func}compinit{rst}){…}"
    command rm -f ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump}

    # Workaround for a nasty trick in _vim
    (( ${+functions[_vim_files]} )) && unfunction _vim_files

    builtin autoload -Uz compinit
    compinit ${${(M)use_C:#1}:+-C} -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
} # ]]]
# FUNCTION: .zinit-download-file-stdout [[[
# Downloads file to stdout. Supports following backend commands:
# curl, wget, lftp, lynx. Used by snippet loading.
.zinit-download-file-stdout() {
    local url="$1" restart="$2" progress="${(M)3:#1}"

    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt localtraps extendedglob

    # Return file directly for file:// urls, wget doesn't support this schema
    if [[ "$url" =~ ^file:// ]] {
        local filepath=${url##file://}
        <"$filepath"
        return "$?"
    }

    if (( restart )) {
        (( ${path[(I)/usr/local/bin]} )) || \
            {
                path+=( "/usr/local/bin" );
                trap "path[-1]=()" EXIT
            }

        if (( ${+commands[curl]} )); then
            if [[ -n $progress ]]; then
                command curl --progress-bar -fSL "$url" 2> >(.zinit-single-line >&2) || return 1
            else
                command curl -fsSL "$url" || return 1
            fi
        elif (( ${+commands[wget]} )); then
            command wget ${${progress:--q}:#1} "$url" -O - || return 1
        elif (( ${+commands[lftp]} )); then
            command lftp -c "cat $url" || return 1
        elif (( ${+commands[lynx]} )); then
            command lynx -source "$url" || return 1
        else
            +zi-log "{u-warn}ERROR{b-warn}:{rst}No download tool detected" \
                "(one of: {cmd}curl{rst}, {cmd}wget{rst}, {cmd}lftp{rst}," \
                "{cmd}lynx{rst})."
            return 2
        fi
    } else {
        if type curl 2>/dev/null 1>&2; then
            if [[ -n $progress ]]; then
                command curl --progress-bar -fSL "$url" 2> >(.zinit-single-line >&2) || return 1
            else
                command curl -fsSL "$url" || return 1
            fi
        elif type wget 2>/dev/null 1>&2; then
            command wget ${${progress:--q}:#1} "$url" -O - || return 1
        elif type lftp 2>/dev/null 1>&2; then
            command lftp -c "cat $url" || return 1
        else
            .zinit-download-file-stdout "$url" "1" "$progress"
            return $?
        fi
    }

    return 0
} # ]]]
# FUNCTION: .zinit-get-url-mtime [[[
# For the given URL returns the date in the Last-Modified
# header as a time stamp
.zinit-get-url-mtime() {
    local url="$1" IFS line header
    local -a cmd

    setopt localoptions localtraps

    (( !${path[(I)/usr/local/bin]} )) && \
        {
            path+=( "/usr/local/bin" );
            trap "path[-1]=()" EXIT
        }

    if (( ${+commands[curl]} )) || type curl 2>/dev/null 1>&2; then
        cmd=(command curl -sIL "$url")
    elif (( ${+commands[wget]} )) || type wget 2>/dev/null 1>&2; then
        cmd=(command wget --server-response --spider -q "$url" -O -)
    else
        REPLY=$(( $(date +"%s") ))
        return 2
    fi

    "${cmd[@]}" |& command grep -i Last-Modified: | while read -r line; do
        header="${${line#*, }//$'\r'}"
    done

    if [[ -z $header ]] {
        REPLY=$(( $(date +"%s") ))
        return 3
    }

    LANG=C TZ=UTC strftime -r -s REPLY "%d %b %Y %H:%M:%S GMT" "$header" &>/dev/null || {
        REPLY=$(( $(date +"%s") ))
        return 4
    }

    return 0
} # ]]]
# FUNCTION: .zinit-mirror-using-svn [[[
# Used to clone subdirectories from Github. If in update mode
# (see $2), then invokes `svn update', in normal mode invokes
# `svn checkout --non-interactive -q <URL>'. In test mode only
# compares remote and local revision and outputs true if update
# is needed.
#
# $1 - URL
# $2 - mode, "" - normal, "-u" - update, "-t" - test
# $3 - subdirectory (not path) with working copy, needed for -t and -u
.zinit-mirror-using-svn() {
    setopt localoptions extendedglob warncreateglobal
    local url="$1" update="$2" directory="$3"

    (( ${+commands[svn]} )) || \
        builtin print -Pr -- "${ZINIT[col-error]}Warning:%f%b Subversion not found" \
            ", please install it to use \`${ZINIT[col-obj]}svn%f%b' ice."

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
} # ]]]
# FUNCTION: .zinit-forget-completion [[[
# Implements alternation of Zsh state so that already initialized
# completion stops being visible to Zsh.
#
# $1 - completion function name, e.g. "_cp"; can also be "cp"
.zinit-forget-completion() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob typesetsilent warncreateglobal

    local f="$1" quiet="$2"

    typeset -a commands
    commands=( ${(k)_comps[(Re)$f]} )

    [[ "${#commands}" -gt 0 ]] && (( quiet == 0 )) && builtin print -Prn "Forgetting commands completed by \`${ZINIT[col-obj]}$f%f%b': "

    local k
    integer first=1
    for k ( $commands ) {
        unset "_comps[$k]"
        (( quiet )) || builtin print -Prn "${${first:#1}:+, }${ZINIT[col-info]}$k%f%b"
        first=0
    }
    (( quiet || first )) || builtin print

    unfunction -- 2>/dev/null "$f"
} # ]]]
# FUNCTION: .zinit-download-snippet [[[
# Downloads snippet
#   file – with curl, wget, lftp or lynx,
#   directory, with Subversion – when svn-ICE is active.
#
#   Github supports Subversion protocol and allows to clone subdirectories.
#   This is used to provide a layer of support for Oh-My-Zsh and Prezto.
.zinit-download-snippet() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent

    local save_url=$1 url=$2 id_as=$3 local_dir=$4 dirname=$5 filename=$6 update=$7

    trap "command rmdir ${(qqq)local_dir}/${(qqq)dirname} 2>/dev/null; return 1;" INT TERM QUIT HUP

    local -a list arr
    integer retval=0 hook_rc=0
    local teleid_clean=${ICE[teleid]%%\?*}
    [[ $teleid_clean == *://* ]] && \
        local sname=${(M)teleid_clean##*://[^/]##(/[^/]##)(#c0,4)} || \
        local sname=${${teleid_clean:h}:t}/${teleid_clean:t}
    [[ $sname = */trunk* ]] && sname=${${ICE[teleid]%%/trunk*}:t}/${ICE[teleid]:t}
    sname=${sname#./}

    if (( ${+ICE[svn]} )) {
        [[ $url = *(${(~kj.|.)${(Mk)ZINIT_1MAP:#OMZ*}}|robbyrussell*oh-my-zsh|ohmyzsh/ohmyzsh)* ]] && local ZSH=${ZINIT[SNIPPETS_DIR]}
        url=${url/(#s)(#m)(${(~kj.|.)ZINIT_1MAP})/$ZINIT_1MAP[$MATCH]}
    } else {
        url=${url/(#s)(#m)(${(~kj.|.)ZINIT_2MAP})/$ZINIT_2MAP[$MATCH]}
        if [[ $save_url == (${(~kj.|.)${(Mk)ZINIT_1MAP:#OMZ*}})* ]] {
            if [[ $url != *.zsh(|-theme) && $url != */_[^/]## ]] {
                if [[ $save_url == OMZT::* ]] {
                    url+=.zsh-theme
                } else {
                    url+=/${${url#*::}:t}.plugin.zsh
                }
            }
        } elif [[ $save_url = (${(~kj.|.)${(kM)ZINIT_1MAP:#PZT*}})* ]] {
            if [[ $url != *.zsh && $url != */_[^/]## ]] {
                url+=/init.zsh
            }
        }
    }

    # Change the url to point to raw github content if it isn't like that
    if [[ "$url" = *github.com* && ! "$url" = */raw/* && "${+ICE[svn]}" = "0" ]] {
        url="${${url/\/blob\///raw/}/\/tree\///raw/}"
    }

    command rm -f ${TMPDIR:-/tmp}/zinit-execs.$$.lst ${TMPDIR:-/tmp}/zinit.installed_comps.$$.lst \
                  ${TMPDIR:-/tmp}/zinit.skipped_comps.$$.lst ${TMPDIR:-/tmp}/zinit.compiled.$$.lst

    if [[ ! -d $local_dir/$dirname ]]; then
        local id_msg_part="{…} (at label{ehi}:{rst} {id-as}$id_as{rst})"
        [[ $update != -u ]] && +zi-log "{nl}{info}Setting up snippet:" \
                                    "{url}$sname{rst}${ICE[id-as]:+$id_msg_part}"
        command mkdir -p "$local_dir"
    fi

    if [[ $update = -u && ${OPTS[opt_-q,--quiet]} != 1 ]]; then
        local id_msg_part="{…} (identified as{ehi}:{rst} {id-as}$id_as{rst})"
        +zi-log "{nl}{info2}Updating snippet: {url}$sname{rst}${ICE[id-as]:+$id_msg_part}"
    fi

    # A flag for the annexes. 0 – no new commits, 1 - run-atpull mode,
    # 2 – full update/there are new commits to download, 3 - full but
    # a forced download (i.e.: the medium doesn't allow to peek update)
    #
    # The below inherits the flag if it's an update call (i.e.: -u given),
    # otherwise it sets it to 2 – a new download is treated like a full
    # update.
    ZINIT[annex-multi-flag:pull-active]=${${${(M)update:#-u}:+${ZINIT[annex-multi-flag:pull-active]}}:-2}

    (
        if [[ $url = (ftp(|s)|http(|s)|scp)://* ]] {
            (
                () { setopt localoptions noautopushd; builtin cd -q "$local_dir"; } || return 4

                (( !OPTS[opt_-q,--quiet] )) && +zi-log "{i} Downloading {file}$sname{rst} ${${ICE[svn]+" (with Subversion)"}:-" (with curl, wget, lftp)"}{rst}"

                if (( ${+ICE[svn]} )) {
                    if [[ $update = -u ]] {
                        # Test if update available
                        if ! .zinit-mirror-using-svn "$url" "-t" "$dirname"; then
                            if (( ${+ICE[run-atpull]} || OPTS[opt_-u,--urge] )) {
                                ZINIT[annex-multi-flag:pull-active]=1
                            } else { return 0; } # Will return when no updates so atpull''
                                                 # code below doesn't need any checks.
                                                 # This return 0 statement also sets the
                                                 # pull-active flag outside this subshell.
                        else
                            ZINIT[annex-multi-flag:pull-active]=2
                        fi

                        # Run annexes' atpull hooks (the before atpull-ice ones).
                        # The SVN block.
                        reply=(
                            ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-pre <->]}
                            ${${(M)ICE[atpull]#\!}:+${(on)ZINIT_EXTS[(I)z-annex hook:\!atpull-<-> <->]}}
                            ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-post <->]}
                        )
                        for key in "${reply[@]}"; do
                            arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                            "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" update:svn
                            hook_rc=$?
                            [[ "$hook_rc" -ne 0 ]] && {
                                retval="$hook_rc"
                                builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                            }
                        done

                        if (( ZINIT[annex-multi-flag:pull-active] == 2 )) {
                            # Do the update
                            # The condition is reversed on purpose – to show only
                            # the messages on an actual update
                            if (( OPTS[opt_-q,--quiet] )); then
                                local id_msg_part="{…} (identified as{ehi}: {id-as}$id_as{rst})"
                                +zi-log "{nl}{info2}Updating snippet {url}${sname}{rst}${ICE[id-as]:+$id_msg_part}"
                                +zi-log "Downloading {apo}\`{rst}$sname{apo}\`{rst} (with Subversion){…}"
                            fi
                            .zinit-mirror-using-svn "$url" "-u" "$dirname" || return 4
                        }
                    } else {
                        .zinit-mirror-using-svn "$url" "" "$dirname" || return 4
                    }

                    # Redundant code, just to compile SVN snippet
                    if [[ ${ICE[as]} != command ]]; then
                        if [[ -n ${ICE[pick]} ]]; then
                            list=( ${(M)~ICE[pick]##/*}(DN) $local_dir/$dirname/${~ICE[pick]}(DN) )
                        elif [[ -z ${ICE[pick]} ]]; then
                            list=(
                                $local_dir/$dirname/*.plugin.zsh(DN) $local_dir/$dirname/*.zsh-theme(DN) $local_dir/$dirname/init.zsh(DN)
                                $local_dir/$dirname/*.zsh(DN) $local_dir/$dirname/*.sh(DN) $local_dir/$dirname/.zshrc(DN)
                            )
                        fi

                        if [[ -e ${list[1]} && ${list[1]} != */dev/null && \
                            -z ${ICE[(i)(\!|)(sh|bash|ksh|csh)]} && \
                            ${+ICE[nocompile]} -eq 0
                        ]] {
                            () {
                                builtin emulate -LR zsh -o extendedglob ${=${options[xtrace]:#off}:+-o xtrace}
                                zcompile -U "${list[1]}" &>/dev/null || \
                                    +zi-log "{u-warn}Warning{b-warn}:{rst} couldn't compile {apo}\`{file}${list[1]}{apo}\`{rst}."
                            }
                        }
                    fi

                    return $ZINIT[annex-multi-flag:pull-active]
                } else {
                    command mkdir -p "$local_dir/$dirname"

                    if (( !OPTS[opt_-f,--force] )) {
                        .zinit-get-url-mtime "$url"
                    } else {
                        REPLY=$EPOCHSECONDS
                    }

                    # Returned is: modification time of the remote file.
                    # Thus, EPOCHSECONDS - REPLY is: allowed window for the
                    # local file to be modified in. ms-$secs is: files accessed
                    # within last $secs seconds. Thus, if there's no match, the
                    # local file is out of date.

                    local secs=$(( EPOCHSECONDS - REPLY ))
                    # Guard so that it's positive
                    (( $secs >= 0 )) || secs=0
                    integer skip_dl
                    local -a matched
                    matched=( $local_dir/$dirname/$filename(DNms-$secs) )
                    if (( ${#matched} )) {
                        +zi-log "{info}Already up to date.{rst}"
                        # Empty-update return-short path – it also decides the
                        # pull-active flag after the return from this sub-shell
                        (( ${+ICE[run-atpull]} || OPTS[opt_-u,--urge] )) && skip_dl=1 || return 0
                    }

                    if [[ ! -f $local_dir/$dirname/$filename ]] {
                        ZINIT[annex-multi-flag:pull-active]=2
                    } else {
                        # secs > 1 → the file is outdated, then:
                        #   - if true, then the mode is 2 minus run-atpull-activation,
                        #   - if false, then mode is 3 → a forced download (no remote mtime found).
                        ZINIT[annex-multi-flag:pull-active]=$(( secs > 1 ? (2 - skip_dl) : 3 ))
                    }

                    # Run annexes' atpull hooks (the before atpull-ice ones).
                    # The URL-snippet block.
                    if [[ $update = -u && $ZINIT[annex-multi-flag:pull-active] -ge 1 ]] {
                        reply=(
                            ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-pre <->]}
                            ${${ICE[atpull]#\!}:+${(on)ZINIT_EXTS[(I)z-annex hook:\!atpull-<-> <->]}}
                            ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-post <->]}
                        )
                        for key in "${reply[@]}"; do
                            arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                            "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" update:url
                            hook_rc="$?"
                            [[ "$hook_rc" -ne 0 ]] && {
                                retval="$hook_rc"
                                builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                            }
                        done
                    }

                    if (( !skip_dl )) {
                        if { ! .zinit-download-file-stdout "$url" 0 1 >! "$dirname/$filename" } {
                            if { ! .zinit-download-file-stdout "$url" 1 1 >! "$dirname/$filename" } {
                                command rm -f "$dirname/$filename"
                                +zi-log "{u-warn}ERROR{b-warn}:{rst} Download failed."
                                return 4
                            }
                        }
                    }
                    return $ZINIT[annex-multi-flag:pull-active]
                }
            )
            retval=$?

            # Overestimate the pull-level to 2 also in error situations
            # – no hooks will be run anyway because of the error
            ZINIT[annex-multi-flag:pull-active]=$retval

            if [[ $ICE[as] != command && ${+ICE[svn]} -eq 0 ]] {
                local file_path=$local_dir/$dirname/$filename
                if [[ -n ${ICE[pick]} ]]; then
                    list=( ${(M)~ICE[pick]##/*}(DN) $local_dir/$dirname/${~ICE[pick]}(DN) )
                    file_path=${list[1]}
                fi
                if [[ -e $file_path && -z ${ICE[(i)(\!|)(sh|bash|ksh|csh)]} && \
                        $file_path != */dev/null && ${+ICE[nocompile]} -eq 0
                ]] {
                    () {
                        builtin emulate -LR zsh -o extendedglob ${=${options[xtrace]:#off}:+-o xtrace}
                        if ! zcompile -U "$file_path" 2>/dev/null; then
                            builtin print -r "Couldn't compile \`${file_path:t}', it MIGHT be wrongly downloaded"
                            builtin print -r "(snippet URL points to a directory instead of a file?"
                            builtin print -r "to download directory, use preceding: zinit ice svn)."
                            retval=4
                        fi
                    }
                }
            }
        } else { # Local-file snippet branch
            # Local files are (yet…) forcefully copied.
            ZINIT[annex-multi-flag:pull-active]=3 retval=3
            # Run annexes' atpull hooks (the before atpull-ice ones).
            # The local-file snippets block.
            if [[ $update = -u ]] {
                reply=(
                    ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-pre <->]}
                    ${${(M)ICE[atpull]#\!}:+${(on)ZINIT_EXTS[(I)z-annex hook:\!atpull-<-> <->]}}
                    ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-post <->]}
                )
                for key in "${reply[@]}"; do
                    arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                    "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" update:file
                    hook_rc="$?"
                    [[ "$hook_rc" -ne 0 ]] && {
                        retval="$hook_rc"
                        builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                    }
                done
            }

            command mkdir -p "$local_dir/$dirname"
            if [[ ! -e $url ]] {
                (( !OPTS[opt_-q,--quiet] )) && +zi-log "{ehi}ERROR:{error} The source file {file}$url{error} doesn't exist.{rst}"
                retval=4
            }
            if [[ -e $url && ! -f $url && $url != /dev/null ]] {
                (( !OPTS[opt_-q,--quiet] )) && +zi-log "{ehi}ERROR:{error} The source {file}$url{error} isn't a regular file.{rst}"
                retval=4
            }
            if [[ -e $url && ! -r $url && $url != /dev/null ]] {
                (( !OPTS[opt_-q,--quiet] )) && +zi-log "{ehi}ERROR:{error} The source {file}$url{error} isn't" \
                    "accessible (wrong permissions).{rst}"
                retval=4
            }
            if ! (( ${+ICE[link]} )) {
                if (( !OPTS[opt_-q,--quiet] )) && [[ $url != /dev/null ]] {
                    +zi-log "{msg}Copying {file}$filename{msg}{…}{rst}"
                    command cp -vf "$url" "$local_dir/$dirname/$filename" || \
                        { +zi-log "{ehi}ERROR:{error} The file copying has been unsuccessful.{rst}"; retval=4; }
                } else {
                    command cp -f "$url" "$local_dir/$dirname/$filename" &>/dev/null || \
                        { +zi-log "{ehi}ERROR:{error} The copying of {file}$filename{error} has been unsuccessful"\
    "${${(M)OPTS[opt_-q,--quiet]:#1}:+, skip the -q/--quiet option for more information}.{rst}"; retval=4; }
                }
            } else {
                if (( $+commands[realpath] )) {
                    local rpv="$(realpath --version | head -n1 | sed -E 's/realpath (\(.*\))?//g')"
                    if is-at-least 8.23 $rpv; then
                        rel_url="$(realpath --relative-to="$local_dir/$dirname" "$url")" && \
                            { url="$rel_url" }
                    fi
                }
                if (( !OPTS[opt_-q,--quiet] )) && [[ $url != /dev/null ]] {
                    +zi-log "{msg}Linking {file}$filename{msg}{…}{rst}"
                    command ln -svf "$url" "$local_dir/$dirname/$filename" || \
                        { +zi-log "{ehi}ERROR:{error} The file linking has been unsuccessful.{rst}"; retval=4; }
                } else {
                    command ln -sf "$url" "$local_dir/$dirname/$filename" &>/dev/null || \
                        { +zi-log "{ehi}ERROR:{error} The link of {file}$filename{error} has been unsuccessful"\
    "${${(M)OPTS[opt_-q,--quiet]:#1}:+, skip the -q/--quiet option for more information}.{rst}"; retval=4; }
                }
            }
        }

        (( retval == 4 )) && { command rmdir "$local_dir/$dirname" 2>/dev/null; return $retval; }

        if [[ ${${:-$local_dir/$dirname}%%/##} != ${ZINIT[SNIPPETS_DIR]} ]] {
            # Store ices at "clone" and update of snippet, SVN and single-file
            local pfx=$local_dir/$dirname/._zinit
            .zinit-store-ices "$pfx" ICE url_rsvd "" "$save_url" "${+ICE[svn]}"
        } elif [[ -n $id_as ]] {
            +zi-log "{u-warn}Warning{b-warn}:{rst} the snippet {url}$id_as{rst} isn't" \
                "fully downloaded – you should remove it with {apo}\`{cmd}zinit delete $id_as{apo}\`{rst}."
        }

        # Empty update short-path
        if (( ZINIT[annex-multi-flag:pull-active] == 0 )) {
            # Run annexes' atpull hooks (the `always' after atpull-ice ones)
            reply=(
                ${(on)ZINIT_EXTS2[(I)zinit hook:%atpull-pre <->]}
                ${(on)ZINIT_EXTS[(I)z-annex hook:%atpull-<-> <->]}
                ${(on)ZINIT_EXTS2[(I)zinit hook:%atpull-post <->]}
            )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" update:0
                hook_rc="$?"
                [[ "$hook_rc" -ne 0 ]] && {
                    retval="$hook_rc"
                    builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                }
            done

            return $retval;
        }

        if [[ $update = -u ]] {
            # Run annexes' atpull hooks (the before atpull-ice ones).
            # The block is common to all 3 snippet types.
            reply=(
                ${(on)ZINIT_EXTS2[(I)zinit hook:no-e-\!atpull-pre <->]}
                ${${ICE[atpull]:#\!*}:+${(on)ZINIT_EXTS[(I)z-annex hook:\!atpull-<-> <->]}}
                ${(on)ZINIT_EXTS2[(I)zinit hook:no-e-\!atpull-post <->]}
            )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" update
                hook_rc=$?
                [[ "$hook_rc" -ne 0 ]] && {
                    retval="$hook_rc"
                    builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                }
            done
        } else {
            # Run annexes' atclone hooks (the before atclone-ice ones)
            # The block is common to all 3 snippet types.
            reply=(
                ${(on)ZINIT_EXTS2[(I)zinit hook:\!atclone-pre <->]}
                ${(on)ZINIT_EXTS[(I)z-annex hook:\!atclone-<-> <->]}
                ${(on)ZINIT_EXTS2[(I)zinit hook:\!atclone-post <->]}
            )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" load
            done

            reply=(
                ${(on)ZINIT_EXTS2[(I)zinit hook:atclone-pre <->]}
                ${(on)ZINIT_EXTS[(I)z-annex hook:atclone-<-> <->]}
                ${(on)ZINIT_EXTS2[(I)zinit hook:atclone-post <->]}
            )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" load
            done
        }

        # Run annexes' atpull hooks (the after atpull-ice ones)
        # The block is common to all 3 snippet types.
        if [[ $update = -u ]] {
            if (( ZINIT[annex-multi-flag:pull-active] > 0 )) {
                reply=(
                    ${(on)ZINIT_EXTS2[(I)zinit hook:atpull-pre <->]}
                    ${(on)ZINIT_EXTS[(I)z-annex hook:atpull-<-> <->]}
                    ${(on)ZINIT_EXTS2[(I)zinit hook:atpull-post <->]}
                )
                for key in "${reply[@]}"; do
                    arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                    "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" update
                    hook_rc=$?
                    [[ "$hook_rc" -ne 0 ]] && {
                        retval="$hook_rc"
                        builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                    }
                done
            }

            # Run annexes' atpull hooks (the `always' after atpull-ice ones)
            # The block is common to all 3 snippet types.
            reply=(
                ${(on)ZINIT_EXTS2[(I)zinit hook:%atpull-pre <->]}
                ${(on)ZINIT_EXTS[(I)z-annex hook:%atpull-<-> <->]}
                ${(on)ZINIT_EXTS2[(I)zinit hook:%atpull-post <->]}
            )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" update:$ZINIT[annex-multi-flag:pull-active]
                hook_rc=$?
                [[ "$hook_rc" -ne 0 ]] && {
                    retval="$hook_rc"
                    builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                }
            done
        }
    ) || return $?

    typeset -ga INSTALLED_EXECS
    { INSTALLED_EXECS=( "${(@f)$(<${TMPDIR:-/tmp}/zinit-execs.$$.lst)}" ) } 2>/dev/null

    # After additional executions like atclone'' - install completions (2 - snippets)
    local -A OPTS
    OPTS[opt_-q,--quiet]=1
    [[ (0 = ${+ICE[nocompletions]} && ${ICE[as]} != null && ${+ICE[null]} -eq 0) || 0 != ${+ICE[completions]} ]] && \
        .zinit-install-completions "%" "$local_dir/$dirname" 0

    if [[ -e ${TMPDIR:-/tmp}/zinit.skipped_comps.$$.lst || -e ${TMPDIR:-/tmp}/zinit.installed_comps.$$.lst ]] {
        typeset -ga INSTALLED_COMPS SKIPPED_COMPS
        { INSTALLED_COMPS=( "${(@f)$(<${TMPDIR:-/tmp}/zinit.installed_comps.$$.lst)}" ) } 2>/dev/null
        { SKIPPED_COMPS=( "${(@f)$(<${TMPDIR:-/tmp}/zinit.skipped_comps.$$.lst)}" ) } 2>/dev/null
    }

    if [[ -e ${TMPDIR:-/tmp}/zinit.compiled.$$.lst ]] {
        typeset -ga ADD_COMPILED
        { ADD_COMPILED=( "${(@f)$(<${TMPDIR:-/tmp}/zinit.compiled.$$.lst)}" ) } 2>/dev/null
    }

    # After any download – rehash the command table
    # This will however miss the as"program" binaries
    # as their PATH gets extended - and it is done
    # later. It will however work for sbin'' ice.
    (( !OPTS[opt_-p,--parallel] )) && rehash

    return $retval
} # ]]]
# FUNCTION: .zinit-update-snippet [[[
.zinit-update-snippet() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent noshortloops rcquotes

    local -a tmp opts
    local url=$1
    integer correct=0
    [[ -o ksharrays ]] && correct=1
    opts=( -u ) # for zinit-annex-readurl

    # Create a local copy of OPTS, basically
    # for zinit-annex-readurl annex
    local -A ice_opts
    ice_opts=( "${(kv)OPTS[@]}" )
    local -A OPTS
    OPTS=( "${(kv)ice_opts[@]}" )

    ZINIT[annex-multi-flag:pull-active]=0 ZINIT[-r/--reset-opt-hook-has-been-run]=0

    # Remove leading whitespace and trailing /
    url=${${url#${url%%[! $'\t']*}}%/}
    ICE[teleid]=${ICE[teleid]:-$url}
    [[ ${ICE[as]} = null || ${+ICE[null]} -eq 1 || ${+ICE[binary]} -eq 1 ]] && \
        ICE[pick]=${ICE[pick]:-/dev/null}

    local local_dir dirname filename save_url=$url \
        id_as=${ICE[id-as]:-$url}

    .zinit-pack-ice "$id_as" ""

    # Allow things like $OSTYPE in the URL
    eval "url=\"$url\""

    # - case A: called from `update --all', ICE empty, static ice will win
    # - case B: called from `update', ICE packed, so it will win
    tmp=( "${(Q@)${(z@)ZINIT_SICE[$id_as]}}" )
    if (( ${#tmp} > 1 && ${#tmp} % 2 == 0 )) {
        ICE=( "${(kv)ICE[@]}" "${tmp[@]}" )
    } elif [[ -n ${ZINIT_SICE[$id_as]} ]] {
        +zi-log "{error}WARNING:{msg2} Inconsistency #3" \
            "occurred, please report the string: \`{obj}${ZINIT_SICE[$id_as]}{msg2}' to the" \
            "GitHub issues page: {obj}https://github.com/zdharma-continuum/zinit/issues/{msg2}.{rst}"
    }
    id_as=${ICE[id-as]:-$id_as}

    # Oh-My-Zsh, Prezto and manual shorthands
    if (( ${+ICE[svn]} )) {
        [[ $url = *(${(~kj.|.)${(Mk)ZINIT_1MAP:#OMZ*}}|robbyrussell*oh-my-zsh|ohmyzsh/ohmyzsh)* ]] && local ZSH=${ZINIT[SNIPPETS_DIR]}
        url=${url/(#s)(#m)(${(~kj.|.)ZINIT_1MAP})/$ZINIT_1MAP[$MATCH]}
    } else {
        url=${url/(#s)(#m)(${(~kj.|.)ZINIT_2MAP})/$ZINIT_2MAP[$MATCH]}
        if [[ $save_url == (${(~kj.|.)${(Mk)ZINIT_1MAP:#OMZ*}})* ]] {
            if [[ $url != *.zsh(|-theme) && $url != */_[^/]## ]] {
                if [[ $save_url == OMZT::* ]] {
                    url+=.zsh-theme
                } else {
                    url+=/${${url#*::}:t}.plugin.zsh
                }
            }
        } elif [[ $save_url = (${(~kj.|.)${(kM)ZINIT_1MAP:#PZT*}})* ]] {
            if [[ $url != *.zsh ]] {
                url+=/init.zsh
            }
        }
    }

    if { ! .zinit-get-object-path snippet "$id_as" } {
        +zi-log "{msg2}Error: the snippet \`{obj}$id_as{msg2}'" \
                "doesn't exist, aborting the update.{rst}"
            return 1
    }
    filename=$reply[-2] dirname=$reply[-2] local_dir=$reply[-3]

    local -a arr
    local key
    reply=(
        ${(on)ZINIT_EXTS2[(I)zinit hook:preinit-pre <->]}
        ${(on)ZINIT_EXTS[(I)z-annex hook:preinit-<-> <->]}
        ${(on)ZINIT_EXTS2[(I)zinit hook:preinit-post <->]}
    )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
        "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" ${${key##(zinit|z-annex) hook:}%% <->} update || \
            return $(( 10 - $? ))
    done

    # Download or copy the file
    [[ $url = *github.com* && $url != */raw/* ]] && url=${url/\/(blob|tree)\///raw/}
    .zinit-download-snippet "$save_url" "$url" "$id_as" "$local_dir" "$dirname" "$filename" "-u"

    return $?
} # ]]]
# FUNCTION: .zinit-single-line [[[
# Display cURL progress bar on a single line
.zinit-single-line() {
    emulate -LR zsh
    setopt extendedglob noshortloops nowarncreateglobal rcquotes typesetsilent
    local IFS= n=$'\n' r=$'\r' zero=$'\0'

    {
      command perl -pe 'BEGIN { $|++; $/ = \1 }; tr/\r\n/\n\0/' \
        || gstdbuf -o0 gtr '\r\n' '\n\0' \
        || stdbuf -o0 tr '\r\n' '\n\0';
      print
    } 2>/dev/null | while read -r line;

    do
      if [[ $line == *$zero* ]]; then
        # cURL doesn't add a newline to progress bars
        # print -nr -- "${r}${(l:COLUMNS:: :):-}${r}${line##*${zero}}"
        print -nr -- "${r}${(l:COLUMNS:: :):-}${r}${line%${zero}}"
      else
        print -nr -- "${r}${(l:COLUMNS:: :):-}${r}${${line//[${r}${n}]/}%\%*}${${(M)line%\%}:+%}"
      fi
    done

    print
} # ]]]
# FUNCTION: .zi::get-architecture [[[
.zi::get-architecture () {
  emulate -L zsh
  setopt extendedglob noshortloops nowarncreateglobal rcquotes
  local _clib="gnu" _cpu="$(uname -m)" _os="$(uname -s)" _sys=""
  case "$_os" in
    (Darwin)
      _sys='(apple|darwin|apple-darwin|dmg|mac((-|)os|)|os(-|64|)x)'
      arch -x86_64 /usr/bin/true 2> /dev/null
      if [[ $? -eq 0 ]] && [[ $_cpu != "arm64" ]]; then
        _os=$_sys*~*((aarch|arm)64)
      fi
      ;;
    (Linux)
      _sys='(musl|gnu)*~^*(unknown|)linux*'
      ;;
    (MINGW* | MSYS* | CYGWIN* | Windows_NT)
      _sys='pc-windows-gnu'
      ;;
    (*)
      +zi-log "{e} {b}gh-r{rst}Unsupported OS: {obj}$_os{rst}"
      ;;
  esac
  case "$_cpu" in
    (aarch64 | arm64)
      _cpu='(arm|aarch)64'
      ;;
    (amd64 | i386 | i486 | i686| i786 | x64 | x86 | x86-64 | x86_64)
      _cpu='(amd64|x86_64|x64)'
      ;;
    (armv6l)
      _os=${_os}eabihf
      ;;
    (armv7l | armv8l)
      _os=${_os}eabihf
      ;;
    (*)
      +zi-log "{e} {b}gh-r{rst}Unsupported CPU: {obj}$_cpu{rst}"
      ;;
  esac
  echo "${_sys};${_cpu};${_os}"
} # ]]]
# FUNCTION: .zinit-get-latest-gh-r-url-part [[[
# Gets version string of latest release of given Github
# package. Connects to Github releases page.
.zinit-get-latest-gh-r-url-part () {
  builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
  setopt extendedglob nowarncreateglobal typesetsilent noshortloops
  REPLY=
  local plugin="$2" urlpart="$3" user="$1"
  local -a bpicks filtered init_list list parts
  parts=(${(@s:;:)$(.zi::get-architecture)})
  if [[ -z $urlpart ]]; then
    local tag_version=${ICE[ver]}
    if [[ -z $tag_version ]]; then
      local releases_url=https://github.com/$user/$plugin/releases/latest
      tag_version="$( { .zinit-download-file-stdout $releases_url || .zinit-download-file-stdout $releases_url 1; } 2>/dev/null | command grep -m1 -o 'href=./'$user'/'$plugin'/releases/tag/[^"]\+' )"
      tag_version=${tag_version##*/}
    fi
    local url=https://github.com/$user/$plugin/releases/expanded_assets/$tag_version
  else
    local url=https://$urlpart
  fi
  init_list=( ${(@f)"$( { .zinit-download-file-stdout $url || .zinit-download-file-stdout $url 1; } 2>/dev/null | command grep -i -o 'href=./'$user'/'$plugin'/releases/download/[^"]\+')"} )
  init_list=(${(L)init_list[@]#href=?})
  bpicks=(${(s.;.)ICE[bpick]})
  [[ -z $bpicks ]] && bpicks=("")
  local bpick bpick_error=""
  reply=()
  for bpick in "${bpicks[@]}"; do
    list=($init_list)
    if [[ -n $bpick ]]; then
      list=( ${(M)list[@]:#(#i)*/$~bpick} )
      if (( !$#list )); then
        +zi-log "{e} {b}gh-r{rst}: {ice}bpick{rst} ice found no release assets To fix, modify the {ice}bpick{rst} glob pattern {glob}$bpick{rst}"
      fi
    else
      local junk='*((s(ha256|ig|um)|386|asc|md5|txt|vsix)*|(apk|b3|deb|json|pkg|rpm|sh|zst)(#e))';
      # print -l ${${(m@)list:#${~junk}}:t}
      filtered=( ${(m@)list:#(#i)${~junk}} ) && (( $#filtered > 0 )) && list=( ${filtered[@]} )
    fi

    local -a array=( $(print -rm "*(${MACHTYPE}|${VENDOR}|)*~^*(${parts[1]}|${(L)$(uname)})*" $list[@]) )
    (( ${#array} > 0 )) && list=( ${array[@]} )

    for part in "${parts[@]}"; do
      if (( $#list > 1 )); then
        filtered=( ${(M)list[@]:#(#i)*${~part}*} ) && (( $#filtered > 0 )) && list=( ${filtered[@]} )
      else
        break
      fi
    done

    if (( $#list > 1 )) { filtered=( ${list[@]:#(#i)*.(sha[[:digit:]]#|asc)} ) && (( $#filtered > 0 )) && list=( ${filtered[@]} ); }

    if (( !$#list )); then
      +zi-log "{e} {b}gh-r{rst}: No GitHub release assets found for {glob}$tag_version{rst}"
      return 1
    fi
    reply+=( "${list[1]}" )
  done
  [[ -n $reply ]]
} # ]]]
# FUNCTION: ziextract [[[
# If the file is an archive, it is extracted by this function.
# Next stage is scanning of files with the common utility file
# to detect executables. They are given +x mode. There are also
# messages to the user on performed actions.
#
# $1 - url
# $2 - file
ziextract() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob typesetsilent noshortloops # warncreateglobal

    local -aU opt_move opt_move2 opt_norm opt_auto opt_nobkp
    zparseopts -D -E -move=opt_move -move2=opt_move2 -norm=opt_norm \
            -auto=opt_auto -nobkp=opt_nobkp || \
        { +zi-log "{info}[{pre}ziextract{info}]{error} Incorrect options given to" \
                  "\`{pre}ziextract{msg2}' (available are: {meta}--auto{msg2}," \
                  "{meta}--move{msg2}, {meta}--move2{msg2}, {meta}--norm{msg2}," \
                  "{meta}--nobkp{msg2}).{rst}"; return 1; }

    local file="$1" ext="$2"
    integer move=${${${(M)${#opt_move}:#0}:+0}:-1} \
            move2=${${${(M)${#opt_move2}:#0}:+0}:-1} \
            norm=${${${(M)${#opt_norm}:#0}:+0}:-1} \
            auto=${${${(M)${#opt_auto}:#0}:+0}:-1} \
            nobkp=${${${(M)${#opt_nobkp}:#0}:+0}:-1}

    if (( auto )) {
        # First try known file extensions
        local -aU files
        integer ret_val
        files=( (#i)**/*.(zip|rar|7z|tgz|tbz|tbz2|tar.gz|tar.bz2|tar.7z|txz|tar.xz|gz|xz|tar|dmg|exe)~(*/*|.(_backup|git))/*(-.DN) )
        for file ( $files ) {
            ziextract "$file" $opt_move $opt_move2 $opt_norm $opt_nobkp ${${${#files}:#1}:+--nobkp}
            ret_val+=$?
        }
        # Second, try to find the archive via `file' tool
        if (( !${#files} )) {
            local -aU output infiles stage2_processed archives
            infiles=( **/*~(._zinit*|._backup|.git)(|/*)~*/*/*(-.DN) )
            output=( ${(@f)"$(command file -- $infiles 2>&1)"} )
            archives=( ${(M)output[@]:#(#i)(* |(#s))(zip|rar|xz|7-zip|gzip|bzip2|tar|exe|PE32) *} )
            for file ( $archives ) {
                local fname=${(M)file#(${(~j:|:)infiles}): } desc=${file#(${(~j:|:)infiles}): } type
                fname=${fname%%??}
                [[ -z $fname || -n ${stage2_processed[(r)$fname]} ]] && continue
                type=${(L)desc/(#b)(#i)(* |(#s))(zip|rar|xz|7-zip|gzip|bzip2|tar|exe|PE32) */$match[2]}
                if [[ $type = (zip|rar|xz|7-zip|gzip|bzip2|tar|exe|pe32) ]] {
                    (( !OPTS[opt_-q,--quiet] )) && \
                        +zi-log "{info}[{pre}ziextract{info}]{msg2} detected a {meta}$type{rst} archive in the file {file}$fname{rst}."
                    ziextract "$fname" "$type" $opt_move $opt_move2 $opt_norm --norm ${${${#archives}:#1}:+--nobkp}
                    integer iret_val=$?
                    ret_val+=iret_val

                    (( iret_val )) && continue

                    # Support nested tar.(bz2|gz|…) archives
                    local infname=$fname
                    [[ -f $fname.out ]] && fname=$fname.out
                    files=( *.tar(ND) )
                    if [[ -f $fname || -f ${fname:r} ]] {
                        local -aU output2 archives2
                        output2=( ${(@f)"$(command file -- "$fname"(N) "${fname:r}"(N) $files[1](N) 2>&1)"} )
                        archives2=( ${(M)output2[@]:#(#i)(* |(#s))(zip|rar|xz|7-zip|gzip|bzip2|tar|exe|PE32) *} )
                        local file2
                        for file2 ( $archives2 ) {
                            fname=${file2%:*} desc=${file2##*:}
                            local type2=${(L)desc/(#b)(#i)(* |(#s))(zip|rar|xz|7-zip|gzip|bzip2|tar|exe|PE32) */$match[2]}
                            if [[ $type != $type2 && \
                                $type2 = (zip|rar|xz|7-zip|gzip|bzip2|tar)
                            ]] {
                                # TODO: if multiple archives are really in the archive,
                                # this might delete too soon… However, it's unusual case.
                                [[ $fname != $infname && $norm -eq 0 ]] && command rm -f "$infname"
                                (( !OPTS[opt_-q,--quiet] )) && \
                                    +zi-log "{info}[{pre}ziextract{info}]{msg2} detected a {obj}${type2}{rst} archive in the file {file}${fname}{rst}."
                                ziextract "$fname" "$type2" $opt_move $opt_move2 $opt_norm ${${${#archives}:#1}:+--nobkp}
                                ret_val+=$?
                                stage2_processed+=( $fname )
                                if [[ $fname == *.out ]] {
                                    [[ -f $fname ]] && command mv -f "$fname" "${fname%.out}"
                                    stage2_processed+=( ${fname%.out} )
                                }
                            }
                        }
                    }
                }
            }
        }
        return $ret_val
    }

    if [[ -z $file ]] {
        +zi-log "{info}[{pre}ziextract{info}]{error} argument needed (the file to extract) or the {meta}--auto{msg} option."
        return 1
    }
    if [[ ! -e $file ]] {
        +zi-log "{info}[{pre}ziextract{info}]{error} ERROR:{msg} the file \`{meta}${file}{msg}' doesn't exist.{rst}"
        return 1
    }
    if (( !nobkp )) {
        command mkdir -p ._backup
        command rm -rf ._backup/*(DN)
        command mv -f *~(._zinit*|._backup|.git|.svn|.hg|$file)(DN) ._backup 2>/dev/null
    }

    .zinit-extract-wrapper() {
        local file="$1" fun="$2" retval
        (( !OPTS[opt_-q,--quiet] )) && \
            +zi-log "{info}[{pre}ziextract{info}]{rst} Unpacking the files from: \`{obj}$file{msg}'{…}{rst}"
        $fun; retval=$?
        if (( retval == 0 )) {
            local -a files
            files=( *~(._zinit*|._backup|.git|.svn|.hg|$file)(DN) )
            (( ${#files} && !norm )) && command rm -f "$file"
        }
        return $retval
    }

    →zinit-check() { (( ${+commands[$1]} )) || \
        +zi-log "{info}[{pre}ziextract{info}]{error} Error:{msg} No command {data}$1{msg}, it is required to unpack {file}$2{rst}."
    }

    case "${${ext:+.$ext}:-$file}" in
        ((#i)*.zip)
            →zinit-extract() { →zinit-check unzip "$file" || return 1; command unzip -qq -o "$file"; }
            ;;
        ((#i)*.rar)
            →zinit-extract() { →zinit-check unrar "$file" || return 1; command unrar x "$file"; }
            ;;
        ((#i)*.tar.bz2|(#i)*.tbz|(#i)*.tbz2)
            →zinit-extract() { →zinit-check bzip2 "$file" || return 1; command bzip2 -dc "$file" | command tar --no-same-owner -xf -; }
            ;;
        ((#i)*.tar.gz|(#i)*.tgz)
            →zinit-extract() { →zinit-check gzip "$file" || return 1; command gzip -dc "$file" | command tar --no-same-owner -xf -; }
            ;;
        ((#i)*.tar.xz|(#i)*.txz)
            →zinit-extract() { →zinit-check xz "$file" || return 1; command xz -dc "$file" | command tar --no-same-owner -xf -; }
            ;;
        ((#i)*.tar.7z|(#i)*.t7z)
            →zinit-extract() { →zinit-check 7z "$file" || return 1; command 7z x -so "$file" | command tar --no-same-owner -xf -; }
            ;;
        ((#i)*.tar)
            →zinit-extract() { →zinit-check tar "$file" || return 1; command tar --no-same-owner -xf "$file"; }
            ;;
        ((#i)*.gz|(#i)*.gzip)
            if [[ $file != (#i)*.gz ]] {
                command mv $file $file.gz
                file=$file.gz
                integer zi_was_renamed=1
            }
            →zinit-extract() {
                →zinit-check gunzip "$file" || return 1
                .zinit-get-mtime-into "$file" 'ZINIT[tmp]'
                command gunzip "$file" |& command grep -E -v '.out$'
                integer ret=$pipestatus[1]
                command touch -t "$(strftime %Y%m%d%H%M.%S $ZINIT[tmp])" "$file"
                return ret
            }
            ;;
        ((#i)*.bz2|(#i)*.bzip2)
            # Rename file if its extension does not match "bz2". bunzip2 refuses
            # to operate on files that are not named correctly.
            # See https://github.com/zdharma-continuum/zinit/issues/105
            if [[ $file != (#i)*.bz2 ]] {
                command mv $file $file.bz2
                file=$file.bz2
            }
            →zinit-extract() { →zinit-check bunzip2 "$file" || return 1
                .zinit-get-mtime-into "$file" 'ZINIT[tmp]'
                command bunzip2 "$file" |& command grep -E -v '.out$'
                integer ret=$pipestatus[1]
                command touch -t "$(strftime %Y%m%d%H%M.%S $ZINIT[tmp])" "$file"
                return ret
            }
            ;;
        ((#i)*.xz)
            if [[ $file != (#i)*.xz ]] {
                command mv $file $file.xz
                file=$file.xz
            }
            →zinit-extract() { →zinit-check xz "$file" || return 1
                .zinit-get-mtime-into "$file" 'ZINIT[tmp]'
                command xz -d "$file"
                integer ret=$?
                command touch -t "$(strftime %Y%m%d%H%M.%S $ZINIT[tmp])" "$file"
                return ret
             }
            ;;
        ((#i)*.7z|(#i)*.7-zip)
            →zinit-extract() { →zinit-check 7z "$file" || return 1; command 7z x "$file" >/dev/null;  }
            ;;
        ((#i)*.dmg)
            →zinit-extract() {
                local prog
                for prog ( hdiutil cp ) { →zinit-check $prog "$file" || return 1; }

                integer retval
                local attached_vol="$( command hdiutil attach "$file" | \
                           command tail -n1 | command cut -f 3 )"

                command cp -Rf ${attached_vol:-${TMPDIR:-/tmp}/acb321GEF}/*(D) .
                retval=$?
                command hdiutil detach $attached_vol

                if (( retval )) {
                    +zi-log "{info}[{pre}ziextract{info}]{error} Error:{msg} problem occurred when attempted to copy the files" \
                            "from the mounted image: \`{obj}${file}{msg}'.{rst}"
                }
                return $retval
            }
            ;;
        ((#i)*.deb)
            →zinit-extract() { →zinit-check dpkg-deb "$file" || return 1; command dpkg-deb -R "$file" .; }
            ;;
        ((#i)*.rpm)
            →zinit-extract() { →zinit-check cpio "$file" || return 1; $ZINIT[BIN_DIR]/share/rpm2cpio.zsh "$file" | command cpio -imd --no-absolute-filenames; }
            ;;
        ((#i)*.exe|(#i)*.pe32)
            →zinit-extract() {
                command chmod a+x -- ./$file
                ./$file /S /D="`cygpath -w $PWD`"
            }
            ;;
    esac

    if [[ $(typeset -f + →zinit-extract) == "→zinit-extract" ]] {
        .zinit-extract-wrapper "$file" →zinit-extract || {
            +zi-log -n "{info}[{pre}ziextract{info}]{error} Error:{msg} extraction of the archive \`{file}${file}{msg}' had problems"
            local -a bfiles
            bfiles=( ._backup/*(DN) )
            if (( ${#bfiles} && !nobkp )) {
                +zi-log -n ", restoring the previous version of the plugin/snippet"
                command mv ._backup/*(DN) . 2>/dev/null
            }
            +zi-log ".{rst}"
            unfunction -- →zinit-extract →zinit-check 2>/dev/null
            return 1
        }
        unfunction -- →zinit-extract →zinit-check
    } else {
        integer warning=1
    }
    unfunction -- .zinit-extract-wrapper

    local -aU execs
    execs=( **/*~(._zinit(|/*)|.git(|/*)|.svn(|/*)|.hg(|/*)|._backup(|/*))(DN-.) )
    if [[ ${#execs} -gt 0 && -n $execs ]] {
        execs=( ${(@f)"$( file ${execs[@]} )"} )
        execs=( "${(M)execs[@]:#[^(:]##:*executable*}" )
        execs=( "${execs[@]/(#b)([^(:]##):*/${match[1]}}" )
    }

    builtin print -rl -- ${execs[@]} >! ${TMPDIR:-/tmp}/zinit-execs.$$.lst
    if [[ ${#execs} -gt 0 ]] {
        command chmod a+x "${execs[@]}"
        if (( !OPTS[opt_-q,--quiet] )) {
            if (( ${#execs} == 1 )); then
                    +zi-log "{info}[{pre}ziextract{info}]{rst} Successfully extracted and assigned +x chmod to the file: {obj}${execs[1]}{rst}."
            else
                local sep="$ZINIT[col-rst],$ZINIT[col-obj] "
                if (( ${#execs} > 7 )) {
                    +zi-log "{info}[{pre}ziextract{info}]{rst} Successfully" \
                        "extracted and marked executable the appropriate files" \
                        "({obj}${(pj:$sep:)${(@)execs[1,5]:t}},…{rst}) contained" \
                        "in \`{file}$file{rst}'. All the extracted" \
                        "{obj}${#execs}{rst} executables are" \
                        "available in the {msg2}INSTALLED_EXECS{rst}" \
                        "array."
                } else {
                    +zi-log "{info}[{pre}ziextract{info}]{rst} Successfully" \
                        "extracted and marked {obj}${#execs}{rst} executable the appropriate files" \
                        "({obj}${(pj:$sep:)${execs[@]:t}}{rst}) contained" \
                        "in \`{file}$file{rst}'."
                }
            fi
        }
    } elif (( warning )) {
        +zi-log "{info}[{pre}ziextract{info}]{error} Error:{msg} didn't recognize archive type of {obj}${file}{msg} ${ext:+/ {obj2}${ext}{msg} } (no extraction has been done).{rst}"
    }

    if (( move | move2 )) {
        local -a files
        files=( *~(._zinit|.git|._backup|.tmp231ABC)(DN/) )
        if (( ${#files} )) {
            command mkdir -p .tmp231ABC
            command mv -f *~(._zinit|.git|._backup|.tmp231ABC)(D) .tmp231ABC
            if (( !move2 )) {
                command mv -f **/*~(*/*~*/*/*|*/*/*/*|^*/*|._zinit(|/*)|.git(|/*)|._backup(|/*))(DN) .
            } else {
                command mv -f **/*~(*/*~*/*/*/*|*/*/*/*/*|^*/*|._zinit(|/*)|.git(|/*)|._backup(|/*))(DN) .
            }

            command mv .tmp231ABC/$file . &>/dev/null
            command rm -rf .tmp231ABC
        }
        REPLY="${${execs[1]:h}:h}/${execs[1]:t}"
    } else {
        REPLY="${execs[1]}"
    }
    return 0
} # ]]]
# FUNCTION: .zinit-extract [[[
.zinit-extract() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent
    local tpe=$1 extract=$2 local_dir=$3
    (
        builtin cd -q "$local_dir" || \
            { +zi-log "{error}ERROR:{msg2} The path of the $tpe" \
                      "(\`{file}$local_dir{msg2}') isn't accessible.{rst}"
                return 1
            }
        local -aU files
        files=( ${(@)${(@s: :)${extract##(\!-|-\!|\!|-)}}//(#b)(((#s)|([^\\])[\\]([\\][\\])#)|((#s)|([^\\])([\\][\\])#)) /${match[2]:+$match[3]$match[4] }${match[5]:+$match[6]${(l:${#match[7]}/2::\\:):-} }} )
        if [[ ${#files} -eq 0 && -n ${extract##(\!-|-\!|\!|-)} ]] {
                +zi-log "{error}ERROR:{msg2} The files" \
                        "(\`{file}${extract##(\!-|-\!|\!|-)}{msg2}')" \
                        "not found, cannot extract.{rst}"
                return 1
        } else {
            (( !${#files} )) && files=( "" )
        }
        local file
        for file ( "${files[@]}" ) {
            [[ -z $extract ]] && local auto2=--auto
            ziextract ${${(M)extract:#(\!|-)##}:+--auto} \
                $auto2 $file \
                ${${(MS)extract[1,2]##-}:+--norm} \
                ${${(MS)extract[1,2]##\!}:+--move} \
                ${${(MS)extract[1,2]##\!\!}:+--move2} \
                ${${${#files}:#1}:+--nobkp}
        }
    )
} # ]]]
# FUNCTION: .zinit-at-eval [[[
.zinit-at-eval() {
    local atpull="$1" atclone="$2"
    integer retval
    @zinit-substitute atclone atpull

    local cmd="$atpull"
    [[ $atpull == "%atclone" ]] && cmd="$atclone"

    eval "$cmd"
    return "$?"
} # ]]]
# FUNCTION: .zinit-get-cygwin-package [[[
.zinit-get-cygwin-package() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent noshortloops rcquotes

    REPLY=

    local pkg=$1 nl=$'\n'
    integer retry=3

    #
    # Download mirrors.lst
    #

    +zi-log "{info}Downloading{ehi}: {obj}mirrors.lst{info}{…}{rst}"
    local mlst="$(mktemp)"
    while (( retry -- )) {
        if ! .zinit-download-file-stdout https://cygwin.com/mirrors.lst 0 > $mlst; then
            .zinit-download-file-stdout https://cygwin.com/mirrors.lst 1 > $mlst
        fi

        local -a mlist
        mlist=( "${(@f)$(<$mlst)}" )

        local mirror=${${mlist[ RANDOM % (${#mlist} + 1) ]}%%;*}
        [[ -n $mirror ]] && break
    }

    if [[ -z $mirror ]] {
        +zi-log "{error}Couldn't download{error}: {obj}mirrors.lst {error}."
        return 1
    }

    mirror=http://ftp.eq.uc.pt/software/pc/prog/cygwin/

    #
    # Download setup.ini.bz2
    #

    +zi-log "{info2}Selected mirror is{error}: {url}${mirror}{rst}"
    +zi-log "{info}Downloading{ehi}: {file}setup.ini.bz2{info}{…}{rst}"
    local setup="$(mktemp -u)"
    retry=3
    while (( retry -- )) {
        if ! .zinit-download-file-stdout ${mirror}x86_64/setup.bz2 0 1 > $setup.bz2; then
            .zinit-download-file-stdout ${mirror}x86_64/setup.bz2 1 1 > $setup.bz2
        fi

        command bunzip2 "$setup.bz2" 2>/dev/null
        [[ -s $setup ]] && break
        mirror=${${mlist[ RANDOM % (${#mlist} + 1) ]}%%;*}
        +zi-log "{pre}Retrying{error}: {meta}#{obj}$(( 3 - $retry ))/3, {pre}with mirror{error}: {url}${mirror}{rst}"
    }
    local setup_contents="$(command grep -A 26 "@ $pkg\$" "$setup")"
    local urlpart=${${(S)setup_contents/(#b)*@ $pkg${nl}*install: (*)$nl*/$match[1]}%% *}
    if [[ -z $urlpart ]] {
        +zi-log "{error}Couldn't find package{error}: {data2}\`{data}${pkg}{data2}'{error}.{rst}"
        return 2
    }
    local url=$mirror/$urlpart outfile=${TMPDIR:-${TMPDIR:-/tmp}}/${urlpart:t}

    #
    # Download the package
    #

    +zi-log "{nl}{i} Downloading {b}{file}${url:t}{rst}"
    retry=2
    while (( retry -- )) {
        integer retval=0
        if ! .zinit-download-file-stdout $url 0 1 > $outfile; then
            if ! .zinit-download-file-stdout $url 1 1 > $outfile; then
                +zi-log "{error}Couldn't download{error}: {url}${url}{error}."
                retval=1
                mirror=${${mlist[ RANDOM % (${#mlist} + 1) ]}%%;*}
                url=$mirror/$urlpart outfile=${TMPDIR:-${TMPDIR:-/tmp}}/${urlpart:t}
                if (( retry )) {
                    +zi-log "{info2}Retrying, with mirror{error}: {url}${mirror}{info2}{…}{rst}"
                    continue
                }
            fi
        fi
        break
    }
    REPLY=$outfile
} # ]]]
# FUNCTION: zicp [[[
zicp() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent noshortloops rcquotes

    local -a mbegin mend match

    local cmd=cp
    if [[ $1 = (-m|--mv) ]] { cmd=mv; shift; }

    local dir
    if [[ $1 = (-d|--dir)  ]] { dir=$2; shift 2; }

    local arg
    arg=${${(j: :)@}//(#b)(([[:space:]]~ )#(([^[:space:]]| )##)([[:space:]]~ )#(#B)(->|=>|→)(#B)([[:space:]]~ )#(#b)(([^[:space:]]| )##)|(#B)([[:space:]]~ )#(#b)(([^[:space:]]| )##))/${match[3]:+$match[3] $match[6]\;}${match[8]:+$match[8] $match[8]\;}}

    (
        if [[ -n $dir ]] { cd $dir || return 1; }
        local a b var
        integer retval
        for a b ( "${(s: :)${${(@s.;.)${arg%\;}}:-* .}}" ) {
            for var ( a b ) {
                : ${(P)var::=${(P)var//(#b)(((#s)|([^\\])[\\]([\\][\\])#)|((#s)|([^\\])([\\][\\])#)) /${match[2]:+$match[3]$match[4] }${match[5]:+$match[6]${(l:${#match[7]}/2::\\:):-} }}}
            }
            if [[ $a != *\** ]] { a=${a%%/##}"/*" }
            command mkdir -p ${~${(M)b:#/*}:-$ZPFX/$b}
            command $cmd -f ${${(M)cmd:#cp}:+-R} $~a ${~${(M)b:#/*}:-$ZPFX/$b}
            retval+=$?
        }
        return $retval
    )
    return
} # ]]]
# FUNCTION: zimv [[[
zimv() {
    local dir
    if [[ $1 = (-d|--dir) ]] { dir=$2; shift 2; }
    zicp --mv ${dir:+--dir} $dir "$@"
} # ]]]
# FUNCTION: ∞zinit-reset-hook [[[
∞zinit-reset-hook() {
    # File
    if [[ "$1" = plugin ]] {
        local type="$1" user="$2" plugin="$3" id_as="$4" dir="${5#%}" hook="$6"
    } else {
        local type="$1" url="$2" id_as="$3" dir="${4#%}" hook="$5"
    }
    if (( ( OPTS[opt_-r,--reset] && ZINIT[-r/--reset-opt-hook-has-been-run] == 0 ) || \
        ( ${+ICE[reset]} && ZINIT[-r/--reset-opt-hook-has-been-run] == 1 )
    )) {
        if (( ZINIT[-r/--reset-opt-hook-has-been-run] )) {
            local msg_bit="{meta}reset{msg2} ice given{pre}" option=
        } else {
            local msg_bit="{meta2}-r/--reset{msg2} given to \`{meta}update{pre}'" option=1
        }
        if [[ $type == snippet ]] {
            if (( $+ICE[svn] )) {
                if [[ $skip_pull -eq 0 && -d $filename/.svn ]] {
                    (( !OPTS[opt_-q,--quiet] )) && +zi-log "{pre}reset ($msg_bit): {msg2}Resetting the repository ($msg_bit) with command: {rst}svn revert --recursive {…}/{file}$filename/.{rst} {…}"
                    command svn revert --recursive $filename/.
                }
            } else {
                if (( ZINIT[annex-multi-flag:pull-active] >= 2 )) {
                    if (( !OPTS[opt_-q,--quiet] )) {
                        if [[ -f $local_dir/$dirname/$filename ]] {
                            if [[ -n $option || -z $ICE[reset] ]] {
                                +zi-log "{pre}reset ($msg_bit):{msg2} Removing the snippet-file: {file}$filename{msg2} {…}{rst}"
                            } else {
                                +zi-log "{pre}reset ($msg_bit):{msg2} Removing the snippet-file: {file}$filename{msg2}," \
                                    "with the supplied code: {data2}$ICE[reset]{msg2} {…}{rst}"
                            }
                            if (( option )) {
                                command rm -f "$local_dir/$dirname/$filename"
                            } else {
                                eval "${ICE[reset]:-rm -f \"$local_dir/$dirname/$filename\"}"
                            }
                        } else {
                            +zi-log "{pre}reset ($msg_bit):{msg2} The file {file}$filename{msg2} is already deleted {…}{rst}"
                            if [[ -n $ICE[reset] && ! -n $option ]] {
                                +zi-log "{pre}reset ($msg_bit):{msg2} (skipped running the provided reset-code:" \
                                    "{data2}$ICE[reset]{msg2}){rst}"
                            }
                        }
                    }
                } else {
                        [[ -f $local_dir/$dirname/$filename ]] && \
                            +zi-log "{pre}reset ($msg_bit): {msg2}Skipping the removal of {file}$filename{msg2}" \
                                 "as there is no new copy scheduled for download.{rst}" || \
                            +zi-log "{pre}reset ($msg_bit): {msg2}The file {file}$filename{msg2} is already deleted" \
                                "and {ehi}no new download is being scheduled.{rst}"
                }
            }
        } elif [[ $type == plugin ]] {
            if (( is_release && !skip_pull )) {
                if (( option )) {
                    (( !OPTS[opt_-q,--quiet] )) && +zi-log "{pre}reset ($msg_bit): {msg2}running: {rst}rm -rf ${${ZINIT[PLUGINS_DIR]:#[/[:space:]]##}:-${TMPDIR:-/tmp}/xyzabc312}/${${(M)${local_dir##${ZINIT[PLUGINS_DIR]}[/[:space:]]#}:#[^/]*}:-${TMPDIR:-/tmp}/xyzabc312-zinit-protection-triggered}/*"
                    builtin eval command rm -rf ${${ZINIT[PLUGINS_DIR]:#[/[:space:]]##}:-${TMPDIR:-/tmp}/xyzabc312}/"${${(M)${local_dir##${ZINIT[PLUGINS_DIR]}[/[:space:]]#}:#[^/]*}:-${TMPDIR:-/tmp}/xyzabc312-zinit-protection-triggered}"/*(ND)
                } else {
                    (( !OPTS[opt_-q,--quiet] )) && +zi-log "{pre}reset ($msg_bit): {msg2}running: {rst}${ICE[reset]:-rm -rf ${${ZINIT[PLUGINS_DIR]:#[/[:space:]]##}:-${TMPDIR:-/tmp}/xyzabc312}/${${(M)${local_dir##${ZINIT[PLUGINS_DIR]}[/[:space:]]#}:#[^/]*}:-${TMPDIR:-/tmp}/xyzabc312-zinit-protection-triggered}/*}"
                    builtin eval ${ICE[reset]:-command rm -rf ${${ZINIT[PLUGINS_DIR]:#[/[:space:]]##}:-${TMPDIR:-/tmp}/xyzabc312}/"${${(M)${local_dir##${ZINIT[PLUGINS_DIR]}[/[:space:]]#}:#[^/]*}:-${TMPDIR:-/tmp}/xyzabc312-zinit-protection-triggered}"/*(ND)}
                }
            } elif (( !skip_pull )) {
                if (( option )) {
                    +zi-log "{pre}reset ($msg_bit): {msg2}Resetting the repository with command:{rst} git reset --hard HEAD {…}"
                    command git reset --hard HEAD
                } else {
                    +zi-log "{pre}reset ($msg_bit): {msg2}Resetting the repository with command:{rst} ${ICE[reset]:-git reset --hard HEAD} {…}"
                    builtin eval "${ICE[reset]:-git reset --hard HEAD}"
                }
            }
        }
    }

    if (( OPTS[opt_-r,--reset] )) {
        if (( ZINIT[-r/--reset-opt-hook-has-been-run] == 1 )) {
            ZINIT[-r/--reset-opt-hook-has-been-run]=0
        } else {
            ZINIT[-r/--reset-opt-hook-has-been-run]=1
        }
    } else {
        # If theres no -r/--reset, pretend that it already has been served.
        ZINIT[-r/--reset-opt-hook-has-been-run]=1
    }
} # ]]]
# FUNCTION: ∞zinit-configure-base-hook [[[
# A base common implementation of the configure ice
∞zinit-configure-base-hook () {
    emulate -L zsh
    setopt extendedglob
    if [[ "$1" = plugin ]]; then
        local dir="${5#%}" hook="$6" subtype="$7" ex="$8"
    else
        local dir="${4#%}" hook="$5" subtype="$6" ex="$7"
    fi
    local flags configure eflags aflags ice='{b}configure{rst}:'
    configure=${ICE[configure]}
    @zinit-substitute configure
    (( ${+ICE[configure]} )) || return 0
    flags=${(M)configure##[smc0\!\#]##}
    configure=${configure##$flags([[:space:]]##|(#e))}
    eflags=${(SM)flags##[\!]##}
    aflags=${(SM)flags##[smc0]##}
    [[ $eflags == $ex ]] || return 0
    typeset -aU configure_opt=(${(@s; ;)configure})
    configure_opt+=("--prefix=${ZPFX:-${ZINIT[HOME_DIR]}/polaris}")
    {
        builtin cd -- "$dir" || return 1
        if [[ -n *(#i)makefile(#qN) ]]; then
            return 0
        elif [[ -z *(#i)configure(#qN) ]]; then
            +zi-log "{m} ${ice} Attempting to generate configure script... "
            local c
            for c in "[[ -e autogen.sh ]] && sh ./autogen.sh" "[[ -n *.a[mc](#qN.) ]] && autoreconf -ifm" "git clean -fxd; aclocal --force; autoconf --force; automake --add-missing --copy --force-missing"; do
                +zi-log -PrD "{dbg} ${ice} {faint}${c}{rst}"
                {
                    eval "${c}" 2> /dev/null >&2
                } always {
                    [[ -n *(#i)configure(#qN) ]] && break
                    (( TRY_BLOCK_ERROR = 0 ))
                }
            done
        fi
        +zi-log "{m} ${ice} Generating Makefile"
        +zi-log "{dbg} ${ice} {faint}./configure $(builtin print -PDn -- ${(Ds; ;)configure_opt[@]//prefix /prefix=}){rst}"
        eval "./configure ${(S)configure_opt[@]//prefix /prefix=}" 2> /dev/null >&2
        if [[ -n *(#i)makefile(#qN) ]]; then
            +zi-log "{m} ${ice} Successfully generated Makefile"
            return 0
        else
            +zi-log "{e} ${ice} Failed project configuration"
            return 1
        fi
    }
} # ]]]
# FUNCTION: ∞zinit-configure-e-hook [[[
∞zinit-configure-e-hook() {
    ∞zinit-configure-base-hook "$@" "!"
} # ]]]
# FUNCTION: ∞zinit-configure-hook [[[
# The non-! version of configure'' ice. Runs in between
# of make'!' and make''. Configure script naturally runs
# before make.
∞zinit-configure-hook() {
    ∞zinit-configure-base-hook "$@" ""
} # ]]]

# FUNCTION: ∞zinit-make-base-hook [[[
# A base common implementation of the make ice
∞zinit-make-base-hook () {
    emulate -L zsh
    setopt extendedglob
    [[ -z $ICE[make] ]] && return 0
    if [[ "$1" = plugin ]]; then
        local dir="${5#%}" hook="$6" subtype="$7" ex="$8"
    else
        local dir="${4#%}" hook="$5" subtype="$6" ex="$7"
    fi
    local make=${ICE[make]} ice='{b}make{rst}:'
    @zinit-substitute make
    (( ${+ICE[make]} )) || return 0
    local eflags=${(M)make##[\!]##}
    make=${make##$eflags}
    [[ $ex == $eflags ]] || return 0
    local make_prefix='prefix'
    if grep -w -- "PREFIX =" ${dir}/[Mm]akefile >/dev/null; then
        make_prefix="PREFIX"
    fi

    local src=($dir/[Cc][Mm]ake*(N.om[1]))
    if (( $#src )); then
      +zi-log "{m} ${ice} Detected Cmake project, using CMAKE_INSTALL_PREFIX={file}\$ZPFX{rst}"
      make_prefix="CMAKE_INSTALL_PREFIX"
    else
      +zi-log -ru2 -- "{dbg} ${dir:t}: No Cmake files found in ${dir}"
    fi
    local prefix="${ZINIT[ZPFX]}"
    if [[ -n OPTS[opt_-q,--quiet] || -n ${ZINIT[DEBUG]:#1} ]]; then
        +zi-log "{dbg} ${ice} setting quiet mode"
        local quiet='2>/dev/null 1>&2'
    fi
    local -i ret=0
    {
        build="make -C ${dir} --jobs 4"
        +zi-log "{m} ${ice} Building..."
        # +zi-log "{m} ${ice} {faint}${(Ds; ;)build} $make_prefix=$(builtin print -Pnf '%s' ${(D)ZINIT[ZPFX]}){rst}"
        +zi-log "{dbg} ${ice} eval ${build} $make_prefix=$prefix 2>/dev/null 1>&2"
        eval "${build} $make_prefix=$prefix" 2>/dev/null 1>&2
        ret=$?
    } always {
        if (( ret )); then
            +zi-log "{w} ${ice} Build returned {num}${ret}{rst}"
        fi
        (( TRY_BLOCK_ERROR = 0 ))
    }
    {
        install="${build} ${make}"
        # +zi-log "{m} ${ice} {faint}${(Ds; ;)build} $make_prefix=$(builtin print -Pnf '%s' ${ZINIT[POLARIS]}) ${make} {rst}"
        +zi-log "{m} ${ice} Installing in ${(D)ZINIT[ZPFX]}"
        +zi-log "{dbg} ${ice} eval ${build} $make_prefix=$prefix ${make} 2>/dev/null 1>&2"
        eval "${(s; ;)install} $make_prefix=$prefix" 2>/dev/null 1>&2
        ret=$?
    } always {
        if (( ret )); then
            +zi-log "{w} ${ice} Install returned {num}${ret}{rst}"
        fi
        (( TRY_BLOCK_ERROR = 0 ))
    }
    return $ret
} # ]]]
# FUNCTION: ∞zinit-make-e-hook [[[
∞zinit-make-e-hook() {
    ∞zinit-make-base-hook "$@" "!"
} # ]]]
# FUNCTION: ∞zinit-make-ee-hook [[[
∞zinit-make-ee-hook() {
    ∞zinit-make-base-hook "$@" "!!"
} # ]]]
# FUNCTION: ∞zinit-make-hook [[[
∞zinit-make-hook() {
    ∞zinit-make-base-hook "$@" ""
} # ]]]

# FUNCTION: __zinit-cmake-base-hook [[[
# A base common implementation of the cmake ice
__zinit-cmake-base-hook () {
    emulate -L zsh
    setopt extended_glob
    (( ${+ICE[cmake]} )) || return 0
    if (( ! ${+commands[cmake]} )); then
        +zi-log "{e} {cmd}cmake{rst} required to use {ice}cmake{rst} ice"
        return 0
    fi
    if [[ "$1" = plugin ]]; then
        local dir="${5#%}" hook="$6" subtype="$7" ex="$8"
    else
        local dir="${4#%}" hook="$5" subtype="$6" ex="$7"
    fi
    (( OPTS[opt_-q,--quiet] || ZINIT[DEBUG] )) && local QUIET='2>/dev/null 1>&2'
    local c ret=0 ice='{b}cmake{rst}:'
    for c in "-S ${dir} -B ${dir}/build -DCMAKE_BUILD_TYPE=Release --install-prefix ${ZINIT[ZPFX]} ${QUIET}" "--build ${dir}/build --parallel $(nproc) ${QUIET}" "--install ${dir}/build ${QUIET}"; do
      +zi-log "{m} ${ice} {faint}cmake ${(Ds; ;)c} {rst}"
        eval "cmake ${c}" 2> /dev/null >&2
        if (( $? )); then
            +zi-log "{e} ${ice} Failure cmake ${c}{rst}"
            ret=$?
        fi
    done
    return $?
} # ]]]
# FUNCTION: +zinit-cmake-hook [[[
+zinit-cmake-hook() {
    __zinit-cmake-base-hook "$@"
} # ]]]

# FUNCTION: ∞zinit-atclone-hook [[[
∞zinit-atclone-hook() {
    [[ "$1" = plugin ]] && \
        local dir="${5#%}" hook="$6" subtype="$7" || \
        local dir="${4#%}" hook="$5" subtype="$6"

    local atclone=${ICE[atclone]}
    @zinit-substitute atclone
    (( ${+ICE[atclone]} )) || return 0

    local rc=0
    [[ -n $atclone ]] && .zinit-countdown atclone && {
        local ___oldcd=$PWD

        (( ${+ICE[nocd]} == 0 )) && {
            () {
                setopt localoptions noautopushd
                builtin cd -q "$dir"
            }
        }

        eval "$atclone"
        rc="$?"

        () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }
    }

    return "$rc"
} # ]]]
# FUNCTION: ∞zinit-extract-hook [[[
∞zinit-extract-hook() {
    [[ "$1" = plugin ]] && \
        local dir="${5#%}" hook="$6" subtype="$7" || \
        local dir="${4#%}" hook="$5" subtype="$6"

    local extract=${ICE[extract]}
    @zinit-substitute extract

    (( ${+ICE[extract]} )) || return 0

    .zinit-extract plugin "$extract" "$dir"
} # ]]]
# FUNCTION: ∞zinit-mv-hook [[[
∞zinit-mv-hook() {
    [[ -z $ICE[mv] ]] && return 0

    [[ "$1" = plugin ]] && \
        local dir="${5#%}" hook="$6" subtype="$7" || \
        local dir="${4#%}" hook="$5" subtype="$6"

    if [[ $ICE[mv] == *("->"|"→")* ]] {
        local from=${ICE[mv]%%[[:space:]]#(->|→)*} to=${ICE[mv]##*(->|→)[[:space:]]#} || \
    } else {
        local from=${ICE[mv]%%[[:space:]]##*} to=${ICE[mv]##*[[:space:]]##}
    }

    @zinit-substitute from to

    local -a mv_args=("-f")
    local -a afr

    (
        () { setopt localoptions noautopushd; builtin cd -q "$dir"; } || return 1
        afr=( ${~from}(DN) )

        if (( ! ${#afr} )) {
            +zi-log "{warn}Warning: mv ice didn't match any file. [{error}$ICE[mv]{warn}]" \
                           "{nl}{warn}Available files:{nl}{obj}$(ls -1)"
            return 1
        }
        if (( !OPTS[opt_-q,--quiet] )) {
            mv_args+=("-v")
        }

        command mv "${mv_args[@]}" "${afr[1]}" "$to"
        local retval=$?
        command mv "${mv_args[@]}" "${afr[1]}".zwc "$to".zwc 2>/dev/null
        return $retval
    )
} # ]]]
# FUNCTION: ∞zinit-cp-hook [[[
∞zinit-cp-hook() {
    [[ -z $ICE[cp] ]] && return

    [[ "$1" = plugin ]] && \
        local dir="${5#%}" hook="$6" subtype="$7" || \
        local dir="${4#%}" hook="$5" subtype="$6"

    if [[ $ICE[cp] == *("->"|"→")* ]] {
        local from=${ICE[cp]%%[[:space:]]#(->|→)*} to=${ICE[cp]##*(->|→)[[:space:]]#} || \
    } else {
        local from=${ICE[cp]%%[[:space:]]##*} to=${ICE[cp]##*[[:space:]]##}
    }

    @zinit-substitute from to

    local -a afr retval
    ( () { setopt localoptions noautopushd; builtin cd -q "$dir"; } || return 1
      afr=( ${~from}(DN) )
      if (( ${#afr} )) {
          if (( !OPTS[opt_-q,--quiet] )) {
              command cp -vf "${afr[1]}" "$to"
              retval=$?
              # ignore errors if no compiled file is found
              command cp -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null
          } else {
              command cp -f "${afr[1]}" "$to"
              retval=$?
              # ignore errors if no compiled file is found
              command cp -f "${afr[1]}".zwc "$to".zwc 2>/dev/null
          }
      }
      return $retval
    )
} # ]]]
# FUNCTION: ∞zinit-compile-plugin-hook [[[
∞zinit-compile-plugin-hook () {
    if [[ "$1" = plugin ]]; then
        local dir="${5#%}" hook="$6" subtype="$7"
    else
        local dir="${4#%}" hook="$5" subtype="$6"
    fi
    if ! [[ ( $hook = *\!at(clone|pull)* && ${+ICE[nocompile]} -eq 0 ) || ( $hook = at(clone|pull)* && $ICE[nocompile] = '!' ) ]]; then
        return 0
    fi
    if [[ -z $ICE[(i)(\!|)(sh|bash|ksh|csh)] ]]; then
        () {
            builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh" || return 1
            setopt local_options extended_glob warn_create_global
            local quiet=1
            if [[ $tpe == snippet ]]; then
                .zinit-compile-plugin "%$dir"
            else
                .zinit-compile-plugin "$id_as"
            fi
        }
    fi
} # ]]]
# FUNCTION: ∞zinit-atpull-e-hook [[[
∞zinit-atpull-e-hook() {
    (( ${+ICE[atpull]} )) || return 0
    [[ -n ${ICE[atpull]} ]] || return 0
    # Only process atpull"!cmd"
    [[ $ICE[atpull] == "!"* ]] || return 0

    [[ "$1" = plugin ]] && \
        local dir="${5#%}" hook="$6" subtype="$7" || \
        local dir="${4#%}" hook="$5" subtype="$6"

    local atpull=${ICE[atpull]#\!}
    local rc=0

    .zinit-countdown atpull && {
        local ___oldcd=$PWD
        (( ${+ICE[nocd]} == 0 )) && {
            () { setopt localoptions noautopushd; builtin cd -q "$dir"; }
        }
        .zinit-at-eval "$atpull" "$ICE[atclone]"
        rc="$?"
        () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; };
    }

    return "$rc"
} # ]]]
# FUNCTION: ∞zinit-atpull-hook [[[
∞zinit-atpull-hook() {
    (( ${+ICE[atpull]} )) || return 0
    [[ -n ${ICE[atpull]} ]] || return 0
    # Exit early if atpull"!cmd" -> this is done by zinit-atpull-e-hook
    [[ $ICE[atpull] == "!"* ]] && return 0

    [[ "$1" == plugin ]] && \
        local dir="${5#%}" hook="$6" subtype="$7" || \
        local dir="${4#%}" hook="$5" subtype="$6"

    local atpull=${ICE[atpull]}
    local rc=0

    .zinit-countdown atpull && {
        local ___oldcd=$PWD
        (( ${+ICE[nocd]} == 0 )) && {
            () { setopt localoptions noautopushd; builtin cd -q "$dir"; }
        }
        .zinit-at-eval "$atpull" $ICE[atclone]
        rc="$?"
        () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; };
    }

    return "$rc"
} # ]]]
# FUNCTION: ∞zinit-ps-on-update-hook [[[
∞zinit-ps-on-update-hook() {
    [[ -z $ICE[ps-on-update] ]] && return 0

    [[ "$1" = plugin ]] && \
        local tpe="$1" dir="${5#%}" hook="$6" subtype="$7" || \
        local tpe="$1" dir="${4#%}" hook="$5" subtype="$6"

    if (( !OPTS[opt_-q,--quiet] )) {
        +zi-log "Running $tpe's provided update code: {info}${ICE[ps-on-update][1,50]}${ICE[ps-on-update][51]:+…}{rst}"
        (
            builtin cd -q "$dir" || return 1
            eval "$ICE[ps-on-update]"
        )
    } else {
        (
            builtin cd -q "$dir" || return 1
            eval "$ICE[ps-on-update]" &> /dev/null
        )
    }
} # ]]]

# vim: ft=zsh sw=2 ts=2 et foldmarker=[[[,]]] foldmethod=marker
