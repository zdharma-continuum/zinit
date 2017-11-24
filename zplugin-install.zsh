# -*- mode: shell-script -*-
# vim:ft=zsh

builtin source ${ZPLGM[BIN_DIR]}"/zplugin-side.zsh"

# FUNCTION: -zplg-setup-plugin-dir {{{
# Clones given plugin into PLUGIN_DIR. Supports multiple
# sites (respecting `from' and `proto' ice modifiers).
# Invokes compilation of plugin's main file.
#
# $1 - user
# $2 - plugin
-zplg-setup-plugin-dir() {
    setopt localoptions extendedglob typesetsilent

    local user="$1" plugin="$2" remote_url_path="$1/$2" local_path="${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"

    local -A sites
    sites=(
        "github"    "github.com"
        "gh"        "github.com"
        "bitbucket" "bitbucket.org"
        "bb"        "bitbucket.org"
        "gitlab"    "gitlab.com"
        "gl"        "gitlab.com"
        "notabug"   "notabug.org"
        "nb"        "notabug.org"
        "github-rel" "github.com/$remote_url_path/releases"
        "gh-r"      "github.com/$remote_url_path/releases"
    )

    if [[ "$user" = "_local" ]]; then
        print "Warning: no local plugin \`$plugin\'"
        print "(should be located at: $local_path)"
        return 1
    fi

    -zplg-any-colorify-as-uspl2 "$user" "$plugin"
    print "Downloading $REPLY..."

    local site
    [[ -n "${ZPLG_ICE[from]}" ]] && site="${sites[${ZPLG_ICE[from]}]}"

    if [[ "$site" = *"releases" ]]; then
        local url="$site/${ZPLG_ICE[ver]}"
        local -a list list2

        list=( ${(@f)"$( { -zplg-download-file-stdout $url || -zplg-download-file-stdout $url 1 } 2>/dev/null | \
                      command grep -o 'href=./'$remote_url_path'/releases/download/[^"]\+')"} )
        list=( "${list[@]#href=?}" )

        [[ -n "${ZPLG_ICE[bpick]}" ]] && list=( "${(M)list[@]:#(#i)${~ZPLG_ICE[bpick]}}" )

        [[ ${#list} -gt 1 ]] && {
            list2=( "${(M)list[@]:#(#i)*${CPUTYPE#(#i)(x86_|i|amd)}*}" )
            [[ ${#list2} -gt 0 ]] && list=( "${list2[@]}" )
        }

        [[ ${#list} -gt 1 ]] && {
            list2=( "${(M)list[@]:#(#i)*${${OSTYPE%(#i)-gnu}%%[0-9.]##}*}" )
            [[ ${#list2} -gt 0 ]] && list=( "${list2[@]}" )
        }

        [[ ${#list} -eq 0 ]] && {
            print "Didn't find correct Github release-file to download (for \`$remote_url_path'), try adapting bpick-ICE"
            return 1
        }

        command mkdir -p "$local_path"
        [[ -d "$local_path" ]] || return 1

        (
            builtin cd "$local_path" || return 1
            url="https://github.com${list[1]}"
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
    else
        case "${ZPLG_ICE[proto]}" in
            (|https)
                command git clone --recursive ${=ZPLG_ICE[depth]:+--depth $ZPLG_ICE[depth]} "https://${site:-${ZPLG_ICE[from]:-github.com}}/$remote_url_path" "$local_path" || return 1
                ;;
            (git|http|ftp|ftps|rsync|ssh)
                command git clone --recursive ${=ZPLG_ICE[depth]:+--depth $ZPLG_ICE[depth]} "${ZPLG_ICE[proto]}://${site:-${ZPLG_ICE[from]:-github.com}}/$remote_url_path" "$local_path" || return 1
                ;;
            (*)
                print "${ZPLGM[col-error]}Unknown protocol:${ZPLGM[col-rst]} ${ZPLG_ICE[proto]}"
                return 1
        esac
    fi

    if [[ -n "${ZPLG_ICE[mv]}" ]]; then
        local from="${ZPLG_ICE[mv]%%[[:space:]]#->*}" to="${ZPLG_ICE[mv]##*->[[:space:]]#}"
        local -a afr
        ( builtin cd "$local_path" || return 1
          afr=( ${~from}(N) )
          [[ ${#afr} -gt 0 ]] && { command mv -vf "${afr[1]}" "$to"; command mv -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
        )
    fi

    if [[ -n "${ZPLG_ICE[cp]}" ]]; then
        local from="${ZPLG_ICE[cp]%%[[:space:]]#->*}" to="${ZPLG_ICE[cp]##*->[[:space:]]#}"
        local -a afr
        ( builtin cd "$local_path" || return 1
          afr=( ${~from}(N) )
          [[ ${#afr} -gt 0 ]] && { command cp -vf "${afr[1]}" "$to"; command cp -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
        )
    fi

    # Install completions
    -zplg-install-completions "$user" "$plugin" "0"

    if [[ "$site" != *"releases" ]]; then
        # Compile plugin
        -zplg-compile-plugin "$user" "$plugin"
    fi

    if [[ "$3" != "-u" ]]; then
        command mkdir -p "$local_path/._zplugin"
        local key
        for key in proto from as pick bpick mv cp atclone atpull ver; do
            print -r -- "${ZPLG_ICE[$key]}" >! "$local_path/._zplugin/$key"
        done
        # Optional file - create file for make ICE mod
        (( ${+ZPLG_ICE[make]} )) && print -r -- "${ZPLG_ICE[make]}" >! "$local_path/._zplugin/make" || command rm -f "$local_path/._zplugin/make"

        ( (( ${+ZPLG_ICE[atclone]} )) && { builtin cd "$local_path" && eval "${ZPLG_ICE[atclone]}"; }; )
        (( ${+ZPLG_ICE[make]} )) && { command make -C "$local_path" ${(@s; ;)ZPLG_ICE[make]}; }
    fi

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
    local reinstall="${3:-0}"

    builtin setopt localoptions nullglob extendedglob unset

    # Shorthands, little unstandarized
    1="${1/OMZ::/https--github.com--robbyrussell--oh-my-zsh--trunk--}"
    1="${1/\/OMZ//https--github.com--robbyrussell--oh-my-zsh--trunk}"
    1="${1/PZT::/https--github.com--sorin-ionescu--prezto--trunk--}"
    1="${1/\/PZT//https--github.com--sorin-ionescu--prezto--trunk}"

    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"
    -zplg-any-colorify-as-uspl2 "$user" "$plugin"
    local abbrev_pspec="$REPLY"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    # Symlink any completion files included in plugin's directory
    typeset -a completions already_symlinked backup_comps
    local c cfile bkpfile
    [[ "$user" = "%" ]] && completions=( "${plugin}"/**/_[^_.][^.]#~*(_zsh_highlight|/zsdoc/)*(^/) ) || completions=( "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"/**/_[^_.][^.]#~*(_zsh_highlight|/zsdoc/)*(^/) )
    already_symlinked=( "${ZPLGM[COMPLETIONS_DIR]}"/_[^_.][^.]# )
    backup_comps=( "${ZPLGM[COMPLETIONS_DIR]}"/[^_.][^.]# )

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
            print "Symlinking completion ${ZPLGM[col-uname]}$cfile${ZPLGM[col-rst]} to \${ZPLGM[COMPLETIONS_DIR]}"
            command ln -s "$c" "${ZPLGM[COMPLETIONS_DIR]}/$cfile"
            # Make compinit notice the change
            -zplg-forget-completion "$cfile"
        else
            print "Not symlinking completion \`$cfile', it already exists"
            print "${ZPLGM[col-info2]}Use \`${ZPLGM[col-pname]}zplugin creinstall $abbrev_pspec${ZPLGM[col-info2]}' to force install${ZPLGM[col-rst]}"
        fi
    done
} # }}}
# FUNCTION: -zplg-download-file-stdout {{{
# Downloads file to stdout. Supports following backend commands:
# curl, wget, lftp, lynx. Used by snippet loading.
-zplg-download-file-stdout() {
    local url="$1"
    local restart="$2"

    if [[ "$restart" = "1" ]]; then
        path+=( "/usr/local/bin" )
        if (( ${+commands[curl]} )) then
            command curl -fsSL "$url" || return 1
        elif (( ${+commands[wget]} )); then
            command wget -q "$url" -O - || return 1
        elif (( ${+commands[lftp]} )); then
            command lftp -c "cat $url" || return 1
        elif (( ${+commands[lynx]} )) then
            command lynx -source "$url" || return 1
        else
            [[ "${(t)path}" != *unique* ]] && path[-1]=()
            return 2
        fi
        [[ "${(t)path}" != *unique* ]] && path[-1]=()
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
    setopt localoptions extendedglob
    local url="$1" update="$2" directory="$3"

    (( ${+commands[svn]} )) || print -r -- "${ZPLGM[col-error]}Warning:${ZPLGM[col-rst]} Subversion not found, please install it to use \`svn' ice-mod"

    if [[ "$update" = "-t" ]]; then
        (
            cd "$directory"
            local -a out1 out2
            out1=( "${(f@)"$(svn info -r HEAD)"}" )
            out2=( "${(f@)"$(svn info)"}" )

            out1=( "${(M)out1[@]:#Revision:*}" )
            out2=( "${(M)out2[@]:#Revision:*}" )
            [[ "${out1[1]##[^0-9]##}" != "${out2[1]##[^0-9]##}" ]] && return 0
            return 1
        )
        return $?
    fi
    if [[ "$update" = "-u" && -d "$directory" && -d "$directory/.svn" ]]; then
        ( cd "$directory"
          command svn update
          return $? )
    else
        command svn checkout --non-interactive -q "$url"
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
    local f="$1"

    typeset -a commands
    commands=( "${(k@)_comps[(R)$f]}" )

    [[ "${#commands}" -gt 0 ]] && print "Forgetting commands completed by \`$f':"

    local k
    for k in "${commands[@]}"; do
        [[ -n "$k" ]] || continue
        unset "_comps[$k]"
        print "Unsetting $k"
    done

    unfunction -- 2>/dev/null "$f"
} # }}}
# FUNCTION: -zplg-compile-plugin {{{
# Compiles given plugin (its main source file, and also an
# additional "....zsh" file if it exists).
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-compile-plugin() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    # No ICE packing because this command is ran from
    # *load-plugin and it would pack ice twice
    local -A sice
    sice=( "${(z@)ZPLG_SICE[$user/$plugin]:-no op}" )
    [[ -n "${ZPLG_ICE[pick]}" ]] && sice[pick]="${(q)ZPLG_ICE[pick]}"

    if [[ -n "${sice[pick]}" ]]; then
        local pdir_path2="${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"
        local -a list
        list=( $pdir_path2/${(Q)~sice[pick]}(N) )
        [[ ${#list} -eq 0 ]] && {
            print "${ZPLGM[col-error]}No files for compilation found (pick-ice didn't match)${ZPLGM[col-rst]}"
            return 1
        }
        reply=( "$pdir_path2" "${list[1]}" )
    else
        -zplg-first "$1" "$2" || {
            print "${ZPLGM[col-error]}No files for compilation found${ZPLGM[col-rst]}"
            return 1
        }
    fi
    local pdir_path="${reply[-2]}" first="${reply[-1]}"
    local fname="${first#$pdir_path/}"

    print "Compiling ${ZPLGM[col-info]}$fname${ZPLGM[col-rst]}..."
    zcompile "$first" || {
        print "Compilation failed. Don't worry, the plugin will work also without compilation"
        print "Consider submitting an error report to the plugin's author"
    }
    # Try to catch possible additional file
    zcompile "${first%.plugin.zsh}.zsh" 2>/dev/null
} # }}}
# FUNCTION: -zplg-download-snippet {{{
# Downloads snippet – either a file – with curl, wget, lftp or lynx,
# or a directory, with Subversion – when svn-ICE is active. Github
# supports Subversion protocol and allows to clone subdirectories.
# This is used to provide a layer of support for Oh-My-Zsh and Prezto.
-zplg-download-snippet() {
    setopt localoptions extendedglob

    local save_url="$1" url="$2" local_dir="$3" filename0="$4" filename="$5" update="$6"
    integer retval=0
    local sname="$filename0/$filename"

    # Change the url to point to raw github content if it isn't like that
    [[ "$url" = *github.com* && ! "$url" = */raw/* && "${+ZPLG_ICE[svn]}" = "0" ]] && url="${url/\/blob\///raw/}"

    if [[ ! -d "$local_dir${ZPLG_ICE[svn]+/$filename}" || ( ${+ZPLG_ICE[svn]} = 0 && ! -f $local_dir/$filename ) ]]; then
        [[ "$update" != "-u" ]] && print "${ZPLGM[col-info]}Setting up snippet ${ZPLGM[col-p]}${(l:10:: :)}$sname${ZPLGM[col-rst]}"
        command mkdir -p "$local_dir"
    fi

    [[ "$update" = "-u" ]] && echo "${ZPLGM[col-info]}Updating snippet ${ZPLGM[col-p]}$sname${ZPLGM[col-rst]}"

    if [[ "$url" = http://* || "$url" = https://* || "$url" = ftp://* || "$url" = ftps://* || "$url" = scp://* ]]
    then
        # URL
        (
            builtin cd "$local_dir" || return 1
            # command rm -rf "$filename"
            print "Downloading \`$sname'${${ZPLG_ICE[svn]+ \(with Subversion\)}:- \(with wget, curl, lftp\)}..."

            if (( ${+ZPLG_ICE[svn]} )); then
                if [[ "$update" = "-u" ]];then
                    # Test if update available
                    -zplg-mirror-using-svn "$url" "-t" "$filename" || return 2
                    [[ ${${ZPLG_ICE[atpull]}[1]} = *"!"* ]] && ( builtin cd "$filename" && -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; )
                    # Do the update
                    -zplg-mirror-using-svn "$url" "-u" "$filename" || return 1
                else
                    -zplg-mirror-using-svn "$url" "" "$filename" || return 1
                fi
            else
                [[ "$update" = "-u" && ${${ZPLG_ICE[atpull]}[1]} = *"!"* ]] && ( -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; )
                -zplg-download-file-stdout "$url" >! "$filename" || {
                    -zplg-download-file-stdout "$url" 1 >! "$filename" || {
                        command rm -f "$filename"
                        print -r "Download failed. No available download tool? (one of: curl, wget, lftp, lynx)"
                        return 1
                    }
                }
            fi
            return 0
        ) || retval=$?

        if (( ${+ZPLG_ICE[svn]} == 0 )); then
            [[ -e "$local_dir/$filename" ]] && {
                zcompile "$local_dir/$filename" 2>/dev/null || {
                    print -r "Couldn't compile \`$filename', it might be wrongly downloaded"
                    print -r "(snippet URL points to a directory instead of a file?"
                    print -r "to download directory, use preceding: zplugin ice svn)"
                    retval=1
                }
            }
        fi
    else
        [[ "$update" = "-u" && ${${ZPLG_ICE[atpull]}[1]} = *"!"* ]] && ( -zplg-at-eval "${ZPLG_ICE[atpull]#!}" ${ZPLG_ICE[atclone]}; )
        # File
        [[ -f "$local_dir/$filename" ]] && command rm -f "$local_dir/$filename"
        print "Copying $filename..."
        command cp -v "$url" "$local_dir/$filename" || { print -r -- "${ZPLGM[col-error]}An error occured${ZPLGM[col-rst]}"; retval=1; }
    fi

    (( retval == 1 )) && { command rmdir "$local_dir" 2>/dev/null; return $retval; }
    (( retval == 2 )) && { return 0; }

    if [[ "$local_dir${ZPLG_ICE[svn]+/$filename}" != "${ZPLGM[SNIPPETS_DIR]}" ]]; then
        local pfx="$local_dir${ZPLG_ICE[svn]+/$filename}/._zplugin" key
        (( ${+ZPLG_ICE[svn]} == 0 )) && pfx+="_$filename"
        command mkdir -p "$pfx"
        print -r -- "$save_url" >! "$pfx/url"
        print -r -- "${+ZPLG_ICE[svn]}" >! "$pfx/mode"
        for key in proto from as pick bpick mv cp atclone atpull ver; do
            print -r -- "${ZPLG_ICE[$key]}" >! "$pfx/$key"
        done
        # Optional file - create file for make ICE mod
        (( ${+ZPLG_ICE[make]} )) && print -r -- "${ZPLG_ICE[make]}" >! "$pfx/make" || command rm -f "$pfx/make"
    fi

    if [[ -n "${ZPLG_ICE[mv]}" ]]; then
        local from="${ZPLG_ICE[mv]%%[[:space:]]#->*}" to="${ZPLG_ICE[mv]##*->[[:space:]]#}"
        local -a afr
        ( builtin cd "$local_dir${ZPLG_ICE[svn]+/$filename}" || return 1
          afr=( ${~from}(N) )
          [[ ${#afr} -gt 0 ]] && { command mv -vf "${afr[1]}" "$to"; command mv -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
        )
    fi

    if [[ -n "${ZPLG_ICE[cp]}" ]]; then
        local from="${ZPLG_ICE[cp]%%[[:space:]]#->*}" to="${ZPLG_ICE[cp]##*->[[:space:]]#}"
        local -a afr
        ( builtin cd "$local_dir${ZPLG_ICE[svn]+/$filename}" || return 1
          afr=( ${~from}(N) )
          [[ ${#afr} -gt 0 ]] && { command cp -vf "${afr[1]}" "$to"; command cp -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
        )
    fi

    if [[ "$update" = "-u" ]];then
        [[ ${+ZPLG_ICE[atpull]} = 1 && ${${ZPLG_ICE[atpull]}[1]} != *"!"* ]] && ( builtin cd "$local_dir${ZPLG_ICE[svn]+/$filename}" && -zplg-at-eval "${ZPLG_ICE[atpull]}" ${ZPLG_ICE[atclone]}; )
    else
        ( (( ${+ZPLG_ICE[atclone]} )) && { builtin cd "$local_dir${ZPLG_ICE[svn]+/$filename}" && eval "${ZPLG_ICE[atclone]}"; } )
    fi
    (( ${+ZPLG_ICE[make]} )) && { command make -C "$local_dir${ZPLG_ICE[svn]+/$filename}" ${(@s; ;)ZPLG_ICE[make]}; }

    -zplg-install-completions "%" "$local_dir${ZPLG_ICE[svn]+/$filename}"
    return $retval
}
# }}}
# FUNCTION: -zplg-get-latest-gh-r-version {{{
# Gets version string of latest release of given Github
# package. Connects to Github releases page.
-zplg-get-latest-gh-r-version() {
    setopt localoptions extendedglob

    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"

    local url="https://github.com/$user/$plugin/releases/latest"

    local -a list
    list=( ${(@f)"$( { -zplg-download-file-stdout $url || -zplg-download-file-stdout $url 1 } 2>/dev/null | \
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
    setopt localoptions extendedglob

    -zplg-extract-wrapper() {
        local file="$1" fun="$2"
        echo "Extracting files from: \`$file'..."
        $fun
        command rm -f "$file"
    }

    local url="$1" file="$2"

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
    esac

    [[ $(typeset -f + -- -zplg-extract) == "-zplg-extract" ]] && {
        -zplg-extract-wrapper "$file" -zplg-extract
        unfunction -- -zplg-extract
    }
    unfunction -- -zplg-extract-wrapper

    execs=( ${(@f)"$( file **/*(N-.) )"} )
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

    REPLY="${execs[1]}"
    return 0
}
# }}}
# FUNCTION: -zplg-at-eval {{{
-zplg-at-eval() {
    [[ "$1" = "%atclone" ]] && { eval "$2"; ((1)); } || eval "$1"
}
# }}}
