# FUNCTION: -zplg-exists-physically {{{
-zplg-exists-physically() {
    -zplg-any-to-user-plugin "$1" "$2"
    [[ -d "$ZPLG_PLUGINS_DIR/${reply[-2]}---${reply[-1]}" ]] && return 0 || return 1
} # }}}
# FUNCTION: -zplg-exists-physically-message {{{
-zplg-exists-physically-message() {
    if ! -zplg-exists-physically "$1" "$2"; then
        -zplg-any-colorify-as-uspl2 "$1" "$2"
        print "${ZPLG_COL[error]}No such plugin directory${ZPLG_COL[rst]} $REPLY"
        return 1
    fi
    return 0
} # }}}

# FUNCTION: -zplg-setup-plugin-dir {{{
-zplg-setup-plugin-dir() {
    local user="$1" plugin="$2" remote_url_path="$1/$2"
    if [[ ! -d "$ZPLG_PLUGINS_DIR/${user}---${plugin}" ]]; then
        local -A sites
        sites=(
            "github"    "github.com"
            "gh"        "github.com"
            "bitbucket" "bitbucket.org"
            "bb"        "bitbucket.org"
            "notabug"   "notabug.org"
            "nb"        "notabug.org"
        )
        if [[ "$user" = "_local" ]]; then
            print "Warning: no local plugin \`$plugin\'"
            print "(looked in $ZPLG_PLUGINS_DIR/${user}---${plugin})"
            return 1
        fi
        -zplg-any-colorify-as-uspl2 "$user" "$plugin"
        print "Downloading $REPLY..."

        # Return with error when any problem
        local site
        [[ -n "${ZPLG_ICE[from]}" ]] && site="${sites[${ZPLG_ICE[from]}]}"
        git clone --recursive https://${site:-github.com}/"$remote_url_path" "$ZPLG_PLUGINS_DIR/${user}---${plugin}" || return 1

        # Install completions
        -zplg-install-completions "$user" "$plugin" "0"

        # Compile plugin
        -zplg-compile-plugin "$user" "$plugin"
    fi

    return 0
} # }}}
# FUNCTION: -zplg-install-completions {{{
# $1 - user---plugin, user/plugin, user (if $2 given), or plugin (if $2 empty)
# $2 - plugin (if $1 - user - given)
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
    completions=( "$ZPLG_PLUGINS_DIR/${user}---${plugin}"/_[^_]* )
    already_symlinked=( "$ZPLG_COMPLETIONS_DIR"/_[^_]* )
    backup_comps=( "$ZPLG_COMPLETIONS_DIR"/[^_]* )

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
                command rm -f "$ZPLG_COMPLETIONS_DIR/$cfile"
                command rm -f "$ZPLG_COMPLETIONS_DIR/$bkpfile"
            fi
            print "${ZPLG_COL[info]}Symlinking completion \`$cfile' to $ZPLG_COMPLETIONS_DIR${ZPLG_COL[rst]}"
            command ln -s "$c" "$ZPLG_COMPLETIONS_DIR/$cfile"
            # Make compinit notice the change
            -zplg-forget-completion "$cfile"
        else
            print "${ZPLG_COL[error]}Not symlinking completion \`$cfile', it already exists${ZPLG_COL[rst]}"
            print "${ZPLG_COL[error]}Use \`creinstall {plugin-name}' to force install${ZPLG_COL[rst]}"
        fi
    done
} # }}}
# FUNCTION: -zplg-download-file-stdout {{{
-zplg-download-file-stdout() {
    local url="$1"
    local restart="$2"

    if [[ "$restart" = "1" ]]; then
        path+=( "/usr/local/bin" )
        if (( ${+commands[curl]} )) then
            curl -fsSL "$url"
        elif (( ${+commands[wget]} )); then
            wget -q "$url" -O -
        elif (( ${+commands[lftp]} )); then
            lftp -c "cat $url"
        elif (( ${+commands[lynx]} )) then
            lynx -dump "$url"
        else
            [[ "${(t)path}" != *unique* ]] && path[-1]=()
            return 1
        fi
        [[ "${(t)path}" != *unique* ]] && path[-1]=()
    else
        if ! type curl 2>/dev/null 1>&2; then
            curl -fsSL "$url" || -zplg-download-file-stdout "$url" "1"
        elif type wget 2>/dev/null 1>&2; then
            wget -q "$url" -O - || -zplg-download-file-stdout "$url" "1"
        elif type lftp 2>/dev/null 1>&2; then
            lftp -c "cat $url" || -zplg-download-file-stdout "$url" "1"
        else
            -zplg-download-file-stdout "$url" "1"
        fi
    fi

    return 0
} # }}}
# FUNCTION: -zplg-forget-completion {{{
# $1 - completion function name, e.g. "_cp"
-zplg-forget-completion() {
    local f="$1"

    typeset -a commands
    commands=( "${(k@)_comps[(R)$f]}" )

    [[ "${#commands[@]}" -gt 0 ]] && print "Forgetting commands completed by \`$f':"

    local k
    for k in "${commands[@]}"; do
        [[ -n "$k" ]] || continue
        unset "_comps[$k]"
        print "Unsetting $k"
    done

    print "${ZPLG_COL[info]}Forgetting completion \`$f'...${ZPLG_COL[rst]}"
    print
    unfunction -- 2>/dev/null "$f"
} # }}}
# FUNCTION: -zplg-compile-plugin {{{
-zplg-compile-plugin() {
    -zplg-first "$1" "$2" || {
        print "${ZPLG_COL[error]}No files for compilation found${ZPLG_COL[rst]}"
        return 1
    }
    local dname="${reply[-2]}" first="${reply[-1]}"
    local fname="${first#$dname/}"

    print "Compiling ${ZPLG_COL[info]}$fname${ZPLG_COL[rst]}..."
    zcompile "$first" || {
        print "Compilation failed. Don't worry, the plugin will work also without compilation"
        print "Consider submitting an error report to the plugin's author"
    }
} # }}}

# -*- mode: shell-script -*-
# vim:ft=zsh
