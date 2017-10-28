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
    local user="$1" plugin="$2" remote_url_path="$1/$2"

    [[ -d "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}" ]] && return 0

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
    )

    if [[ "$user" = "_local" ]]; then
        print "Warning: no local plugin \`$plugin\'"
        print "(should be located at ${ZPLGM[PLUGINS_DIR]}/${user}---${plugin})"
        return 1
    fi

    -zplg-any-colorify-as-uspl2 "$user" "$plugin"
    print "Downloading $REPLY..."

    local site
    [[ -n "${ZPLG_ICE[from]}" ]] && site="${sites[${ZPLG_ICE[from]}]}"

    case "${ZPLG_ICE[proto]}" in
        (|https)
            git clone --recursive ${=ZPLG_ICE[depth]:+--depth $ZPLG_ICE[depth]} "https://${site:-${ZPLG_ICE[from]:-github.com}}/$remote_url_path" "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}" || return 1
            ;;
        (git|http|ftp|ftps|rsync|ssh)
            git clone --recursive ${=ZPLG_ICE[depth]:+--depth $ZPLG_ICE[depth]} "${ZPLG_ICE[proto]}://${site:-${ZPLG_ICE[from]:-github.com}}/$remote_url_path" "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}" || return 1
            ;;
        (*)
            print "${ZPLGM[col-error]}Unknown protocol:${ZPLGM[col-rst]} ${ZPLG_ICE[proto]}"
            return 1
    esac

    # Install completions
    -zplg-install-completions "$user" "$plugin" "0"

    # Compile plugin
    -zplg-compile-plugin "$user" "$plugin"

    ( (( ${+ZPLG_ICE[atclone]} )) && { cd "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"; eval "${ZPLG_ICE[atclone]}" } )

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

    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    # Symlink any completion files included in plugin's directory
    typeset -a completions already_symlinked backup_comps
    local c cfile bkpfile
    [[ "$user" = "%" ]] && completions=( "${plugin}"/**/_[^_.][^.]#~*(zplg_functions|/zsdoc/)* ) || completions=( "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"/**/_[^_.][^.]#~*(zplg_functions|/zsdoc/)* )
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
            print "${ZPLGM[col-info2]}Symlinking completion \`$cfile' to ${ZPLGM[COMPLETIONS_DIR]}${ZPLGM[col-rst]}"
            command ln -s "$c" "${ZPLGM[COMPLETIONS_DIR]}/$cfile"
            # Make compinit notice the change
            -zplg-forget-completion "$cfile"
        else
            print "${ZPLGM[col-error]}Not symlinking completion \`$cfile', it already exists${ZPLGM[col-rst]}"
            print "${ZPLGM[col-error]}Use \`creinstall {plugin-name}' to force install${ZPLGM[col-rst]}"
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
-zplg-mirror-using-svn() {
    local url="$1"
    svn checkout --non-interactive -q "$url"
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

    print "${ZPLGM[col-info2]}Forgetting completion \`$f'...${ZPLGM[col-rst]}"
    print
    unfunction -- 2>/dev/null "$f"
} # }}}
# FUNCTION: -zplg-compile-plugin {{{
# Compiles given plugin (its main source file, and also an
# additional "....zsh" file if it exists).
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-compile-plugin() {
    -zplg-first "$1" "$2" || {
        print "${ZPLGM[col-error]}No files for compilation found${ZPLGM[col-rst]}"
        return 1
    }
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
-zplg-download-snippet() {
    local save_url="$1" url="$2" local_dir="$3" filename0="$4" filename="$5" update="$6"
    integer retval=0

    [[ "$filename" = (init.zsh|trunk) ]] && local sname="$filename0" || local sname="$filename"

    # Change the url to point to raw github content if it isn't like that
    [[ "$url" = *github.com* && ! "$url" = */raw/* && "${+ZPLG_ICE[svn]}" = "0" ]] && url="${url/\/blob\///raw/}"

    if [[ ! -d "$local_dir" ]]; then
        print "${ZPLGM[col-info]}Setting up snippet ${ZPLGM[col-p]}${(l:10:: :)}$sname${ZPLGM[col-rst]}"
        command mkdir -p "$local_dir"
    fi

    [[ "$update" = "-u" ]] && echo "${ZPLGM[col-info]}Updating snippet ${ZPLGM[col-p]}$sname${ZPLGM[col-rst]}"

    if [[ "$url" = http://* || "$url" = https://* || "$url" = ftp://* || "$url" = ftps://* || "$url" = scp://* ]]
    then
        # URL
        (
            cd "$local_dir"
            command rm -rf "$filename"
            print "Downloading \`$sname'${${ZPLG_ICE[svn]+ \(with Subversion\)}:- \(with wget, curl, lftp\)}..."

            if (( ${+ZPLG_ICE[svn]} )); then
                -zplg-mirror-using-svn "$url"
            else
                -zplg-download-file-stdout "$url" >! "$filename" || {
                    -zplg-download-file-stdout "$url" 1 >! "$filename" || {
                        echo "Download failed. No available download tool? (one of: curl, wget, lftp, lynx)"
                    }
                }
            fi
        )

        if (( ${+ZPLG_ICE[svn]} == 0 )); then
            zcompile "$local_dir/$filename" 2>/dev/null || {
                print -r "Couldn't compile \`$filename', it might be wrongly downloaded"
                print -r "(snippet URL points to a directory instead of a file?"
                print -r "to download directory, use preceding: zplugin ice svn)"
                retval=1
            }
        fi
    else
        # File
        [[ -f "$local_dir/$filename" ]] && command rm -f "$local_dir/$filename"
        print "Copying $filename..."
        command cp -v "$url" "$local_dir/$filename"
    fi

    print -r "$save_url" >! "$local_dir${ZPLG_ICE[svn]+/$filename}/.zplugin_url"
    print -r "${+ZPLG_ICE[svn]}" >! "$local_dir${ZPLG_ICE[svn]+/$filename}/.zplugin_mode"

    return $retval
}
