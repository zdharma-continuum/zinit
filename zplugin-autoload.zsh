# -*- mode: shell-script -*-
# vim:ft=zsh

# Creates a one or two columns text with functions
# belonging to given ($1) plugin
-zplg-format-functions() {
    local uspl2="$1"

    typeset -a func
    func=( "${(z)ZPLG_FUNCTIONS[$uspl2]}" )

    # Get length of longest left-right string pair,
    # and length of longest left string
    integer longest=0 longest_left=0 cur_left_len=0 count=1
    local f
    for f in "${(on)func[@]}"; do
        [[ -z "${#f}" ]] && continue
        f="${(Q)f}"

        # Compute for elements in left column,
        # ones that will be paded with spaces 
        if (( count ++ % 2 != 0 )); then
            [[ "${#f}" -gt "$longest_left" ]] && longest_left="${#f}"
            cur_left_len="${#f}"
        else
            cur_left_len+="${#f}"
            cur_left_len+=1 # For separating space
            [[ "$cur_left_len" -gt "$longest" ]] && longest="$cur_left_len"
        fi
    done

    # Output in one or two columns
    local answer=""
    count=1
    for f in "${(on)func[@]}"; do
        [[ -z "$f" ]] && continue
        f="${(Q)f}"

        if (( COLUMNS >= longest )); then
            if (( count ++ % 2 != 0 )); then
                answer+="${(r:longest_left+1:: :)f}"
            else
                answer+="$f"$'\n'
            fi
        else
            answer+="$f"$'\n'
        fi
    done
    REPLY="$answer"
    # == 0 is: next element would have newline (postfix addition in "count ++")
    (( COLUMNS >= longest && count % 2 == 0 )) && REPLY="$REPLY"$'\n'
}

# Creates a text about options that changed when loaded plugin "$1"
-zplg-format-options() {
    local uspl2="$1"

    REPLY=""

    # Paranoid, don't want bad key/value pair error
    integer empty=0
    -zplg-save-set-extendedglob
    [[ "${ZPLG_OPTIONS[$uspl2]}" != *[$'! \t']* ]] && empty=1
    -zplg-restore-extendedglob
    (( empty )) && return 0

    typeset -A opts
    opts=( "${(z)ZPLG_OPTIONS[$uspl2]}" )

    # Get length of longest option
    integer longest=0
    local k
    for k in "${(kon)opts[@]}"; do
        [[ "${#k}" -gt "$longest" ]] && longest="${#k}"
    done

    # Output in one column
    local txt
    for k in "${(kon)opts[@]}"; do
        [[ "${opts[$k]}" = "on" ]] && txt="was unset" || txt="was set"
        REPLY+="${(r:longest+1:: :)k}$txt"$'\n'
    done
}

-zplg-format-env() {
    local uspl2="$1" which="$2"

    # Format PATH?
    if [[ "$which" = "1" ]]; then
        typeset -a elem
        elem=( "${(z)ZPLG_PATH[$uspl2]}" )
    elif [[ "$which" = "2" ]]; then
        typeset -a elem
        elem=( "${(z)ZPLG_FPATH[$uspl2]}" )
    fi

    # Enumerate elements added
    local answer="" e
    for e in "${elem[@]}"; do
        [[ -z "$e" ]] && continue
        e="${(Q)e}"
        answer+="$e"$'\n'
    done

    [[ -n "$answer" ]] && REPLY="$answer"
}

-zplg-format-parameter() {
    local uspl2="$1" infoc="${ZPLG_COL[info]}"

    # Paranoid for type of empty value,
    # i.e. include white spaces as empty
    builtin setopt localoptions extendedglob
    REPLY=""
    [[ "${ZPLG_PARAMETERS_PRE[$uspl2]}" != *[$'! \t']* || "${ZPLG_PARAMETERS_POST[$uspl2]}" != *[$'! \t']* ]] && return 0

    typeset -A elem_pre elem_post
    elem_pre=( "${(z)ZPLG_PARAMETERS_PRE[$uspl2]}" )
    elem_post=( "${(z)ZPLG_PARAMETERS_POST[$uspl2]}" )

    # Find longest key and longest value
    integer longest=0 vlongest1=0 vlongest2=0
    for k in "${(k)elem_post[@]}"; do
        k="${(Q)k}"
        [[ "${#k}" -gt "$longest" ]] && longest="${#k}"

        v1="${(Q)elem_pre[$k]}"
        v2="${(Q)elem_post[$k]}"
        [[ "${#v1}" -gt "$vlongest1" ]] && vlongest1="${#v1}"
        [[ "${#v2}" -gt "$vlongest2" ]] && vlongest2="${#v2}"
    done

    # Enumerate parameters that changed. A key
    # always exists in both of the arrays
    local answer="" k v1 v2
    for k in "${(k)elem_post[@]}"; do
        v1="${(Q)elem_pre[$k]}"
        v2="${(Q)elem_post[$k]}"
        k="${(Q)k}"

        k="${(r:longest+1:: :)k}"
        v1="${(l:vlongest1+1:: :)v1}"
        v2="${(r:vlongest2+1:: :)v2}"
        answer+="$k ${infoc}[$v1 -> $v2]${ZPLG_COL[rst]}"$'\n'
    done

    [[ -n "$answer" ]] && REPLY="$answer"

    return 0
}

# Both :A and readlink will be used, then readlink's output if
# results differ. This allows to symlink git repositories
# into .zplugin/plugins and have username properly resolved
# (:A will read the link "twice" and give the final repository
# directory, possibly without username in the uspl format;
# readlink will read the link "once")
-zplg-get-completion-owner() {
    local cpath="$1"
    local readlink_cmd="$2"
    local in_plugin_path tmp

    # Try to go not too deep into resolving the symlink,
    # to have the name as it is in .zplugin/plugins
    # :A goes deep, descends fully to origin directory
    # Readlink just reads what symlink points to
    in_plugin_path="${cpath:A}"
    tmp=$( "$readlink_cmd" "$cpath" )
    # This in effect works as: "if different, then readlink"
    [[ -n "$tmp" ]] && in_plugin_path="$tmp"

    if [[ "$in_plugin_path" != "$cpath" ]]; then
        # Get the user---plugin part of path -
        # it's right before completion file name
        in_plugin_path="${in_plugin_path:h}"
        in_plugin_path="${in_plugin_path:t}"
    else
        # readlink and :A have nothing
        in_plugin_path="[unknown]"
    fi

    REPLY="$in_plugin_path"
}

-zplg-check-comp-consistency() {
    local cfile="$1" bkpfile="$2"
    integer error="$3"

    # bkpfile must be a symlink
    if [[ -e "$bkpfile" && ! -L "$bkpfile" ]]; then
        print "${ZPLG_COL[error]}Warning: completion's backup file \`${bkpfile:t}' isn't a symlink${ZPLG_COL[rst]}"
        error=1
    fi

    # cfile must be a symlink
    if [[ -e "$cfile" && ! -L "$cfile" ]]; then
        print "${ZPLG_COL[error]}Warning: completion file \`${cfile:t}' isn't a symlink${ZPLG_COL[rst]}"
        error=1
    fi

    # Tell user that he can manually modify but should do it right
    (( error )) && print "${ZPLG_COL[error]}Manual edit of $ZPLG_COMPLETIONS_DIR occured?${ZPLG_COL[rst]}"
}

# Searches for completions owned by given plugin
# Returns them in reply array
-zplg-find-completions-of-plugin() {
    builtin setopt localoptions nullglob extendedglob
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" uspl="${1}---${2}"

    reply=( "$ZPLG_PLUGINS_DIR/$uspl"/_[^_]* )
}

# For each positional parameter that each should
# be path to completion within a plugin's dir, it
# checks whether that completion is installed -
# returns 0 or 1 on corresponding positions in reply
-zplg-check-which-completions-are-installed() {
    local i cfile bkpfile
    reply=( )
    for i in "$@"; do
        cfile="${i:t}"
        bkpfile="${cfile#_}"

        if [[ -e "$ZPLG_COMPLETIONS_DIR"/"$cfile" || -e "$ZPLG_COMPLETIONS_DIR"/"$bkpfile" ]]; then
            reply+=( "1" )
        else
            reply+=( "0" )
        fi
    done
}

# For each positional parameter that each should
# be path to completion within a plugin's dir, it
# checks whether that completion is disabled -
# returns 0 or 1 on corresponding positions in reply
#
# Uninstalled completions will be reported as "0"
# - i.e. disabled
-zplg-check-which-completions-are-enabled() {
    local i cfile
    reply=( )
    for i in "$@"; do
        cfile="${i:t}"

        if [[ -e "$ZPLG_COMPLETIONS_DIR"/"$cfile" ]]; then
            reply+=( "1" )
        else
            reply+=( "0" )
        fi
    done
}

# Clears all report data for given user/plugin
-zplg-clear-report-for() {
    -zplg-any-to-uspl2 "$1" "$2"

    # Shadowing
    ZPLG_REPORTS[$REPLY]=""
    ZPLG_BINDKEYS[$REPLY]=""
    ZPLG_ZSTYLES[$REPLY]=""
    ZPLG_ALIASES[$REPLY]=""
    ZPLG_WIDGETS_SAVED[$REPLY]=""
    ZPLG_WIDGETS_DELETE[$REPLY]=""

    # Function diffing
    ZPLG_FUNCTIONS[$REPLY]=""
    ZPLG_FUNCTIONS_BEFORE[$REPLY]=""
    ZPLG_FUNCTIONS_AFTER[$REPLY]=""
    ZPLG_FUNCTIONS_DIFF_RAN[$REPLY]=""

    # Option diffing
    ZPLG_OPTIONS[$REPLY]=""
    ZPLG_OPTIONS_BEFORE[$REPLY]=""
    ZPLG_OPTIONS_AFTER[$REPLY]=""
    ZPLG_OPTIONS_DIFF_RAN[$REPLY]="0"

    # Environment diffing
    ZPLG_PATH[$REPLY]=""
    ZPLG_PATH_BEFORE[$REPLY]=""
    ZPLG_PATH_AFTER[$REPLY]=""
    ZPLG_FPATH[$REPLY]=""
    ZPLG_FPATH_BEFORE[$REPLY]=""
    ZPLG_FPATH_AFTER[$REPLY]=""
    ZPLG_ENV_DIFF_RAN[$REPLY]="0"

    # Parameter diffing
    ZPLG_PARAMETERS_PRE[$REPLY]=""
    ZPLG_PARAMETERS_POST[$REPLY]=""
    ZPLG_PARAMETERS_BEFORE[$REPLY]=""
    ZPLG_PARAMETERS_AFTER[$REPLY]=""
    ZPLG_PARAMETERS_DIFF_RAN[$REPLY]="0"
}

# $1 - user---plugin, user/plugin, user (if $2 given), or plugin (if $2 empty)
# $2 - plugin (if $1 - user - given)
-zplg-uninstall-completions() {
    builtin setopt localoptions nullglob extendedglob unset

    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    typeset -a completions symlinked backup_comps
    local c cfile bkpfile
    integer action global_action=0

    completions=( "$ZPLG_PLUGINS_DIR/${user}---${plugin}"/_[^_]* )
    symlinked=( "$ZPLG_COMPLETIONS_DIR"/_[^_]* )
    backup_comps=( "$ZPLG_COMPLETIONS_DIR"/[^_]* )

    # Delete completions if they are really there, either
    # as completions (_fname) or backups (fname)
    for c in "${completions[@]}"; do
        action=0
        cfile="${c:t}"
        bkpfile="${cfile#_}"

        # Remove symlink to completion
        if [[ -n "${symlinked[(r)*/$cfile]}" ]]; then
            command rm -f "$ZPLG_COMPLETIONS_DIR/$cfile"
            action=1
        fi

        # Remove backup symlink (created by cdisable)
        if [[ -n "${backup_comps[(r)*/$bkpfile]}" ]]; then
            command rm -f "$ZPLG_COMPLETIONS_DIR/$bkpfile"
            action=1
        fi

        if (( action )); then
            print "${ZPLG_COL[info]}Uninstalling completion \`$cfile'${ZPLG_COL[rst]}"
            # Make compinit notice the change
            -zplg-forget-completion "$cfile"
            (( global_action ++ ))
        else
            print "${ZPLG_COL[info]}Completion \`$cfile' not installed${ZPLG_COL[rst]}"
        fi
    done

    if (( global_action > 0 )); then
        print "${ZPLG_COL[info]}Uninstalled $global_action completions${ZPLG_COL[rst]}"
    fi
}

-zplg-compinit() {
    builtin setopt localoptions nullglob extendedglob

    typeset -a symlinked backup_comps
    local c cfile bkpfile 

    symlinked=( "$ZPLG_COMPLETIONS_DIR"/_[^_]* )
    backup_comps=( "$ZPLG_COMPLETIONS_DIR"/[^_]* )

    # Delete completions if they are really there, either
    # as completions (_fname) or backups (fname)
    for c in "${symlinked[@]}" "${backup_comps[@]}"; do
        action=0
        cfile="${c:t}"
        cfile="_${cfile#_}"
        bkpfile="${cfile#_}"

        print "${ZPLG_COL[info]}Processing completion $cfile${ZPLG_COL[rst]}"
        -zplg-forget-completion "$cfile"
    done

    print "Initializing completion (compinit)..."
    command rm -f ~/.zcompdump

    # Workaround for a nasty trick in _vim
    (( ${+functions[_vim_files]} )) && unfunction _vim_files

    builtin autoload -Uz compinit
    compinit
}

-zplg-uncompile-plugin() {
    builtin setopt localoptions nullglob

    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" silent="$3"

    # There are plugins having ".plugin.zsh"
    # in ${plugin} directory name, also some
    # have ".zsh" there
    local dname="$ZPLG_PLUGINS_DIR/${user}---${plugin}"
    typeset -a matches m
    matches=( $dname/*.zwc )

    if [[ "${#matches[@]}" -eq "0" ]]; then
        if [[ "$silent" = "1" ]]; then
            print "not compiled"
        else
            -zplg-any-colorify-as-uspl2 "$user" "$plugin"
            print "$REPLY not compiled"
        fi
        return 1
    fi

    for m in "${matches[@]}"; do
        print "Removing ${ZPLG_COL[info]}${m:t}${ZPLG_COL[rst]}"
        command rm -f "$m"
    done
}

#
# User-exposed functions {{{
#
-zplg-show-completions() {
    builtin setopt localoptions nullglob extendedglob

    typeset -a completions
    completions=( "$ZPLG_COMPLETIONS_DIR"/_[^_]* "$ZPLG_COMPLETIONS_DIR"/[^_]* )

    # Find longest completion name
    local cpath c
    integer longest=0
    for cpath in "${completions[@]}"; do
        c="${cpath:t}"
        c="${c#_}"
        [[ "${#c}" -gt "$longest" ]] && longest="${#c}"
    done

    #
    # Display - resolves owner of each completion,
    # detects if completion is disabled 
    #

    integer disabled unknown stray
    for cpath in "${completions[@]}"; do
        c="${cpath:t}"
        [[ "${c#_}" = "${c}" ]] && disabled=1 || disabled=0
        c="${c#_}"

        # Prepare readlink command for establishing
        # completion's owner
        -zplg-prepare-readlink

        # This will resolve completion's symlink to obtain
        # information about the repository it comes from, i.e.
        # about user and plugin, taken from directory name
        -zplg-get-completion-owner "$cpath" "$REPLY"
        [[ "$REPLY" = "[unknown]" ]] && unknown=1 || unknown=0
        -zplg-any-colorify-as-uspl2 "$REPLY"

        # If we succesfully read a symlink (unknown == 0), test if it isn't broken
        stray=0
        if (( unknown == 0 )); then
            [[ ! -f "$cpath" ]] && stray=1
        fi

        # Output line of text
        print -n "${(r:longest+1:: :)c} $REPLY"
        (( disabled )) && print -n " ${ZPLG_COL[error]}[disabled]${ZPLG_COL[rst]}"
        (( unknown )) && print -n " ${ZPLG_COL[error]}[unknown file, clean with cclear]${ZPLG_COL[rst]}"
        (( stray )) && print -n " ${ZPLG_COL[error]}[stray, clean with cclear]${ZPLG_COL[rst]}"
        print
    done
}

-zplg-clear-completions() {
    builtin setopt localoptions nullglob extendedglob

    typeset -a completions
    completions=( "$ZPLG_COMPLETIONS_DIR"/_[^_]* "$ZPLG_COMPLETIONS_DIR"/[^_]* )

    # Find longest completion name
    local cpath c
    integer longest=0
    for cpath in "${completions[@]}"; do
        c="${cpath:t}"
        c="${c#_}"
        [[ "${#c}" -gt "$longest" ]] && longest="${#c}"
    done

    integer disabled unknown stray
    for cpath in "${completions[@]}"; do
        c="${cpath:t}"
        [[ "${c#_}" = "${c}" ]] && disabled=1 || disabled=0
        c="${c#_}"

        -zplg-prepare-readlink

        # This will resolve completion's symlink to obtain
        # information about the repository it comes from, i.e.
        # about user and plugin, taken from directory name
        -zplg-get-completion-owner "$cpath" "$REPLY"
        [[ "$REPLY" = "[unknown]" ]] && unknown=1 || unknown=0
        -zplg-any-colorify-as-uspl2 "$REPLY"

        # If we succesfully read a symlink (unknown == 0), test if it isn't broken
        stray=0
        if (( unknown == 0 )); then
            [[ ! -f "$cpath" ]] && stray=1
        fi

        if (( unknown == 1 || stray == 1 )); then
            print -n "Removing completion: ${(r:longest+1:: :)c} $REPLY"
            (( disabled )) && print -n " ${ZPLG_COL[error]}[disabled]${ZPLG_COL[rst]}"
            (( unknown )) && print -n " ${ZPLG_COL[error]}[unknown file]${ZPLG_COL[rst]}"
            (( stray )) && print -n " ${ZPLG_COL[error]}[stray]${ZPLG_COL[rst]}"
            print
            command rm -f "$cpath"
        fi
    done
}

# While -zplg-show-completions shows what completions are installed,
# this functions searches through all plugin directories showing what's available
-zplg-search-completions() {
    builtin setopt localoptions nullglob extendedglob

    typeset -a plugin_paths
    plugin_paths=( "$ZPLG_PLUGINS_DIR"/*---* )

    # Find longest plugin name. Things are ran twice here, first pass
    # is to get longest name of plugin which is having any completions
    integer longest=0
    typeset -a completions
    local pp
    for pp in "${plugin_paths[@]}"; do
        completions=( "$pp"/_[^_]* )
        if [[ "${#completions[@]}" -gt 0 ]]; then
            local pd="${pp:t}"
            [[ "${#pd}" -gt "$longest" ]] && longest="${#pd}"
        fi
    done

    print "${ZPLG_COL[info]}[+]${ZPLG_COL[rst]} is installed, ${ZPLG_COL[p]}[-]${ZPLG_COL[rst]} uninstalled, ${ZPLG_COL[error]}[+-]${ZPLG_COL[rst]} partially installed"

    local c
    for pp in "${plugin_paths[@]}"; do
        completions=( "$pp"/_[^_]* )

        if [[ "${#completions[@]}" -gt 0 ]]; then
            # Array of completions, e.g. ( _cp _xauth )
            completions=( "${completions[@]:t}" )

            # Detect if the completions are installed
            integer all_installed="${#completions[@]}"
            for c in "${completions[@]}"; do
                if [[ -e "$ZPLG_COMPLETIONS_DIR/$c" || -e "$ZPLG_COMPLETIONS_DIR/${c#_}" ]]; then
                    (( all_installed -- ))
                fi
            done

            if [[ "$all_installed" -eq "${#completions[@]}" ]]; then
                print -n "${ZPLG_COL[p]}[-]${ZPLG_COL[rst]} "
            elif [[ "$all_installed" -eq "0" ]]; then
                print -n "${ZPLG_COL[info]}[+]${ZPLG_COL[rst]} "
            else
                print -n "${ZPLG_COL[error]}[+-]${ZPLG_COL[rst]} "
            fi

            # Convert directory name to colorified $user/$plugin
            -zplg-any-colorify-as-uspl2 "${pp:t}"

            # Adjust for escape code (nasty, utilizes fact that
            # ${ZPLG_COL[rst]} is used twice, so as a $ZPLG_COL)
            integer adjust_ec=$(( ${#reset_color} * 2 + ${#ZPLG_COL[uname]} + ${#ZPLG_COL[pname]} ))

            print "${(r:longest+adjust_ec:: :)REPLY} ${(j:, :)completions}"
        fi
    done
}

-zplg-show-report() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"

    # Allow debug report
    if [[ "$user/$plugin" != "$ZPLG_DEBUG_USPL2" ]]; then
        -zplg-exists-message "$user" "$plugin" || return 1
    fi

    # Print title
    printf "${ZPLG_COL[title]}Plugin report for${ZPLG_COL[rst]} %s/%s\n"\
            "${ZPLG_COL[uname]}$user${ZPLG_COL[rst]}"\
            "${ZPLG_COL[pname]}$plugin${ZPLG_COL[rst]}"

    # Print "----------"
    local msg="Plugin report for $user/$plugin"
    print -- "${ZPLG_COL[bar]}${(r:${#msg}::-:)tmp__}${ZPLG_COL[rst]}"

    # Print report gathered via shadowing
    print "${ZPLG_REPORTS[${user}/${plugin}]}"

    # Print report gathered via $functions-diffing
    REPLY=""
    -zplg-diff-functions "$user/$plugin" diff
    -zplg-format-functions "$user/$plugin"
    [[ -n "$REPLY" ]] && print "${ZPLG_COL[p]}Functions created:${ZPLG_COL[rst]}"$'\n'"$REPLY"

    # Print report gathered via $options-diffing
    REPLY=""
    -zplg-diff-options "$user/$plugin" diff
    -zplg-format-options "$user/$plugin"
    [[ -n "$REPLY" ]] && print "${ZPLG_COL[p]}Options changed:${ZPLG_COL[rst]}"$'\n'"$REPLY"

    # Print report gathered via environment diffing
    REPLY=""
    -zplg-diff-env "$user/$plugin" diff
    -zplg-format-env "$user/$plugin" "1"
    [[ -n "$REPLY" ]] && print "${ZPLG_COL[p]}PATH elements added:${ZPLG_COL[rst]}"$'\n'"$REPLY"

    REPLY=""
    -zplg-format-env "$user/$plugin" "2"
    [[ -n "$REPLY" ]] && print "${ZPLG_COL[p]}FPATH elements added:${ZPLG_COL[rst]}"$'\n'"$REPLY"

    # Print report gathered via parameter diffing
    -zplg-diff-parameter "$user/$plugin" diff
    -zplg-format-parameter "$user/$plugin"
    [[ -n "$REPLY" ]] && print "${ZPLG_COL[p]}Variables added or redefined:${ZPLG_COL[rst]}"$'\n'"$REPLY"

    # Print what completions plugin has
    -zplg-find-completions-of-plugin "$user" "$plugin"
    typeset -a completions
    completions=( "${reply[@]}" )

    if [[ "${#completions[@]}" -ge "1" ]]; then
        print "${ZPLG_COL[p]}Completions:${ZPLG_COL[rst]}"
        -zplg-check-which-completions-are-installed "${completions[@]}"
        typeset -a installed
        installed=( "${reply[@]}" )

        -zplg-check-which-completions-are-enabled "${completions[@]}"
        typeset -a enabled
        enabled=( "${reply[@]}" )

        integer count="${#completions[@]}" idx
        for (( idx=1; idx <= count; idx ++ )); do
            print -n "${completions[idx]:t}"
            if [[ "${installed[idx]}" != "1" ]]; then
                print -n " ${ZPLG_COL[uninst]}[not installed]${ZPLG_COL[rst]}"
            else
                if [[ "${enabled[idx]}" = "1" ]]; then
                    print -n " ${ZPLG_COL[info]}[enabled]${ZPLG_COL[rst]}"
                else
                    print -n " ${ZPLG_COL[error]}[disabled]${ZPLG_COL[rst]}"
                fi
            fi
            print
        done
        print
    fi
}

-zplg-show-all-reports() {
    local i
    for i in "${ZPLG_REGISTERED_PLUGINS[@]}"; do
        [[ "$i" = "_local/$ZPLG_NAME" ]] && continue
        -zplg-show-report "$i"
    done
}

-zplg-show-registered-plugins() {
    typeset -a filtered
    local keyword="$1"

    -zplg-save-set-extendedglob
    keyword="${keyword## ##}"
    keyword="${keyword%% ##}"
    if [[ -n "$keyword" ]]; then
        print "Installed plugins matching ${ZPLG_COL[info]}$keyword${ZPLG_COL[rst]}:"
        filtered=( "${(M)ZPLG_REGISTERED_PLUGINS[@]:#*$keyword*}" )
    else
        filtered=( "${ZPLG_REGISTERED_PLUGINS[@]}" )
    fi
    -zplg-restore-extendedglob

    local i
    for i in "${filtered[@]}"; do
        # Skip _local/psprint
        [[ "$i" = "_local/zplugin" ]] && continue
        -zplg-any-colorify-as-uspl2 "$i"
        # Mark light loads
        [[ "${ZPLG_REGISTERED_STATES[$i]}" = "1" ]] && REPLY="$REPLY ${ZPLG_COL[info]}*${ZPLG_COL[rst]}"
        print "$REPLY"
    done
}

-zplg-cenable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZPLG_COMPLETIONS_DIR}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        print "${ZPLG_COL[error]}No such completion \`$c'${ZPLG_COL[rst]}"
        return 1
    fi

    # Check if there is no backup file
    # This is treated as if the completion is already enabled
    if [[ ! -e "$bkpfile" ]]; then
        print "Completion ${ZPLG_COL[info]}$c${ZPLG_COL[rst]} already enabled"

        -zplg-check-comp-consistency "$cfile" "$bkpfile" 0
        return 1
    fi

    # Disabled, but completion file already exists?
    if [[ -e "$cfile" ]]; then
        print "${ZPLG_COL[error]}Warning: completion's file \`${cfile:t}' exists, will overwrite${ZPLG_COL[rst]}"
        print "${ZPLG_COL[error]}Completion is actually enabled and will re-enable it again${ZPLG_COL[rst]}"
        -zplg-check-comp-consistency "$cfile" "$bkpfile" 1
        command rm -f "$cfile"
    else
        -zplg-check-comp-consistency "$cfile" "$bkpfile" 0
    fi

    # Enable
    command mv "$bkpfile" "$cfile" # move completion's backup file created when disabling

    # Prepare readlink command for establishing completion's owner
    -zplg-prepare-readlink
    # Get completion's owning plugin
    -zplg-get-completion-owner-uspl2col "$cfile" "$REPLY"

    print "Enabled ${ZPLG_COL[info]}$c${ZPLG_COL[rst]} completion belonging to $REPLY"

    return 0
}

-zplg-cdisable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZPLG_COMPLETIONS_DIR}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        print "${ZPLG_COL[error]}No such completion \`$c'${ZPLG_COL[rst]}"
        return 1
    fi

    # Check if it's already disabled
    # Not existing "$cfile" says that
    if [[ ! -e "$cfile" ]]; then
        print "Completion ${ZPLG_COL[info]}$c${ZPLG_COL[rst]} already disabled"

        -zplg-check-comp-consistency "$cfile" "$bkpfile" 0
        return 1
    fi

    # No disable, but bkpfile exists?
    if [[ -e "$bkpfile" ]]; then
        print "${ZPLG_COL[error]}Warning: completion's backup file \`${bkpfile:t}' already exists, will overwrite${ZPLG_COL[rst]}"
        -zplg-check-comp-consistency "$cfile" "$bkpfile" 1
        command rm -f "$bkpfile"
    else
        -zplg-check-comp-consistency "$cfile" "$bkpfile" 0
    fi

    # Disable
    command mv "$cfile" "$bkpfile"

    # Prepare readlink command for establishing completion's owner
    -zplg-prepare-readlink
    # Get completion's owning plugin
    -zplg-get-completion-owner-uspl2col "$bkpfile" "$REPLY"

    print "Disabled ${ZPLG_COL[info]}$c${ZPLG_COL[rst]} completion belonging to $REPLY"

    return 0
}

# $1 - user---plugin, user/plugin, user (if $2 given), or plugin (if $2 empty)
# $2 - plugin (if $1 - user - given)
#
# 1. Unfunction functions created by plugin
# 2. Delete bindkeys
# 3. Delete created Zstyles
# 4. Restore options
# 5. Restore (or just unalias?) aliases
# 6. Restore Zle state
# 7. Clean up FPATH and PATH
# 8. Delete created variables
# 9. Forget the plugin
-zplg-unload() {
    -zplg-any-to-user-plugin "$1" "$2"
    local uspl2="${reply[-2]}/${reply[-1]}" user="${reply[-2]}" plugin="${reply[-1]}"

    # KSH_ARRAYS immunity
    integer correct=0
    [[ -o "KSH_ARRAYS" ]] && correct=1

    # Allow unload for debug user
    if [[ "$uspl2" != "$ZPLG_DEBUG_USPL2" ]]; then
        -zplg-exists-message "$1" "$2" || return 1
    fi

    -zplg-any-colorify-as-uspl2 "$1" "$2"
    local uspl2col="$REPLY"

    # Store report of the plugin in variable LASTREPORT
    LASTREPORT=`-zplg-show-report "$1" "$2"`

    #
    # 1. Unfunction
    #

    -zplg-diff-functions "$uspl2" diff
    typeset -a func
    func=( "${(z)ZPLG_FUNCTIONS[$uspl2]}" )
    local f
    for f in "${(on)func[@]}"; do
        [[ -z "$f" ]] && continue
        f="${(Q)f}"
        print "Deleting function $f"
        unfunction -- "$f"
    done

    #
    # 2. Delete done bindkeys
    #

    typeset -a string_widget
    string_widget=( "${(z)ZPLG_BINDKEYS[$uspl2]}" )
    local sw
    for sw in "${(Oa)string_widget[@]}"; do
        [[ -z "$sw" ]] && continue
        # Remove one level of quoting to split using (z)
        sw="${(Q)sw}"
        typeset -a sw_arr
        sw_arr=( "${(z)sw}" )

        # Remove one level of quoting to pass to bindkey
        local sw_arr1="${(Q)sw_arr[1-correct]}" # Keys
        local sw_arr2="${(Q)sw_arr[2-correct]}" # Widget
        local sw_arr3="${(Q)sw_arr[3-correct]}" # Optional -M or -A or -N
        local sw_arr4="${(Q)sw_arr[4-correct]}" # Optional map name
        local sw_arr5="${(Q)sw_arr[5-correct]}" # Optional -R (not with -A, -N)

        if [[ "$sw_arr3" = "-M" && "$sw_arr5" != "-R" ]]; then
            print "Deleting bindkey $sw_arr1 $sw_arr2 ${ZPLG_COL[info]}mapped to $sw_arr4${ZPLG_COL[rst]}"
            bindkey -M "$sw_arr4" -r "$sw_arr1"
        elif [[ "$sw_arr3" = "-M" && "$sw_arr5" = "-R" ]]; then
            print "Deleting ${ZPLG_COL[info]}range${ZPLG_COL[rst]} bindkey $sw_arr1 $sw_arr2 ${ZPLG_COL[info]}mapped to $sw_arr4${ZPLG_COL[rst]}"
            bindkey -M "$sw_arr4" -Rr "$sw_arr1"
        elif [[ "$sw_arr3" != "-M" && "$sw_arr5" = "-R" ]]; then
            print "Deleting ${ZPLG_COL[info]}range${ZPLG_COL[rst]} bindkey $sw_arr1 $sw_arr2" 
            bindkey -Rr "$sw_arr1"
        elif [[ "$sw_arr3" = "-A" ]]; then
            print "Linking backup-\`main' keymap \`$sw_arr4' back to \`main'"
            bindkey -A "$sw_arr4" "main"
        elif [[ "$sw_arr3" = "-N" ]]; then
            print "Deleting keymap \`$sw_arr4'"
            bindkey -D "$sw_arr4"
        else
            print "Deleting bindkey $sw_arr1 $sw_arr2"
            bindkey -r "$sw_arr1"
        fi
    done

    #
    # 3. Delete created Zstyles
    #

    typeset -a pattern_style
    pattern_style=( "${(z)ZPLG_ZSTYLES[$uspl2]}" )
    local ps
    for ps in "${(Oa)pattern_style[@]}"; do
        [[ -z "$ps" ]] && continue
        # Remove one level of quoting to split using (z)
        ps="${(Q)ps}"
        typeset -a ps_arr
        ps_arr=( "${(z)ps}" )

        # Remove one level of quoting to pass to zstyle
        local ps_arr1="${(Q)ps_arr[1-correct]}"
        local ps_arr2="${(Q)ps_arr[2-correct]}"

        print "Deleting zstyle $ps_arr1 $ps_arr2"

        zstyle -d "$ps_arr1" "$ps_arr2"
    done

    #
    # 4. Restore changed options
    #

    # Paranoid, don't want bad key/value pair error
    -zplg-diff-options "$uspl2" diff
    integer empty=0
    -zplg-save-set-extendedglob
    [[ "${ZPLG_OPTIONS[$uspl2]}" != *[$'! \t']* ]] && empty=1
    -zplg-restore-extendedglob

    if (( empty != 1 )); then
        typeset -A opts
        opts=( "${(z)ZPLG_OPTIONS[$uspl2]}" )
        local k
        for k in "${(kon)opts[@]}"; do
            # Internal options
            [[ "$k" = "physical" ]] && continue

            if [[ "${opts[$k]}" = "on" ]]; then
                print "Setting option $k"
                builtin setopt "$k"
            else
                print "Unsetting option $k"
                builtin unsetopt "$k"
            fi
        done
    fi

    #
    # 5. Delete aliases
    #

    typeset -a aname_avalue
    aname_avalue=( "${(z)ZPLG_ALIASES[$uspl2]}" )
    local nv
    for nv in "${(Oa)aname_avalue[@]}"; do
        [[ -z "$nv" ]] && continue
        # Remove one level of quoting to split using (z)
        nv="${(Q)nv}"
        typeset -a nv_arr
        nv_arr=( "${(z)nv}" )

        # Remove one level of quoting to pass to unalias
        local nv_arr1="${(Q)nv_arr[1-correct]}"
        local nv_arr2="${(Q)nv_arr[2-correct]}"
        local nv_arr3="${(Q)nv_arr[3-correct]}"

        if [[ "$nv_arr3" = "-s" ]]; then
            print "Removing ${ZPLG_COL[info]}suffix${ZPLG_COL[rst]} alias ${nv_arr1}=${nv_arr2}"
            unalias -s -- "$nv_arr1"
        elif [[ "$nv_arr3" = "-g" ]]; then
            print "Removing ${ZPLG_COL[info]}global${ZPLG_COL[rst]} alias ${nv_arr1}=${nv_arr2}"
            unalias -- "${(q)nv_arr1}"
        else
            print "Removing alias ${nv_arr1}=${nv_arr2}"
            unalias -- "$nv_arr1"
        fi
    done

    #
    # 6. Restore Zle state
    #

    typeset -a delete_widgets
    delete_widgets=( "${(z)ZPLG_WIDGETS_DELETE[$uspl2]}" )
    local wid
    for wid in "${(Oa)delete_widgets[@]}"; do
        [[ -z "$wid" ]] && continue
        wid="${(Q)wid}"
        if [[ "${ZPLG_ZLE_HOOKS_LIST[$wid]}" = "1" ]]; then
            print "Removing Zle hook \`$wid'"
        else
            print "Removing Zle widget \`$wid'"
        fi
        zle -D "$wid"
    done

    typeset -a restore_widgets
    restore_widgets=( "${(z)ZPLG_WIDGETS_SAVED[$uspl2]}" )
    for wid in "${(Oa)restore_widgets[@]}"; do
        [[ -z "$wid" ]] && continue
        wid="${(Q)wid}"
        typeset -a orig_saved
        orig_saved=( "${(z)wid}" )

        local orig_saved1="${(Q)orig_saved[1-correct]}" # Original widget
        local orig_saved2="${(Q)orig_saved[2-correct]}" # Saved widget

        print "Restoring Zle widget $orig_saved1"
        zle -A "$orig_saved2" "$orig_saved1"
        zle -D "$orig_saved2"
    done

    #
    # 7. Clean up FPATH and PATH
    #

    -zplg-diff-env "$uspl2" diff

    # Have to iterate over $path elements and
    # skip those that were added by the plugin
    typeset -a new elem p
    elem=( "${(z)ZPLG_PATH[$uspl2]}" )
    for p in "${path[@]}"; do
        [[ -z "${elem[(r)$p]}" ]] && new+=( "$p" ) || {
            print "Removing PATH element ${ZPLG_COL[info]}$p${ZPLG_COL[rst]}"
            [[ -d "$p" ]] || print "${ZPLG_COL[error]}Warning:${ZPLG_COL[rst]} it didn't exist on disk"
        }
    done
    path=( "${new[@]}" )

    # The same for $fpath
    elem=( "${(z)ZPLG_FPATH[$uspl2]}" )
    new=( )
    for p in "${fpath[@]}"; do
        [[ -z "${elem[(r)$p]}" ]] && new+=( "$p" ) || {
            print "Removing FPATH element ${ZPLG_COL[info]}$p${ZPLG_COL[rst]}"
            [[ -d "$p" ]] || print "${ZPLG_COL[error]}Warning:${ZPLG_COL[rst]} it didn't exist on disk"
        }
    done
    fpath=( "${new[@]}" )

    #
    # 8. Delete created variables
    #

    # Paranoid for type of empty value,
    # i.e. include white spaces as empty
    -zplg-diff-parameter "$uspl2" diff
    empty=0
    -zplg-save-set-extendedglob
    [[ "${ZPLG_PARAMETERS_POST[$uspl2]}" != *[$'! \t']* ]] && empty=1
    -zplg-restore-extendedglob

    if (( empty != 1 )); then
        typeset -A elem_pre elem_post
        elem_pre=( "${(z)ZPLG_PARAMETERS_PRE[$uspl2]}" )
        elem_post=( "${(z)ZPLG_PARAMETERS_POST[$uspl2]}" )

        # Find variables created or modified
        for k in "${(k)elem_post[@]}"; do
            k="${(Q)k}"
            local v1="${(Q)elem_pre[$k]}" 
            local v2="${(Q)elem_post[$k]}"

            # "" means a variable was deleted, not created/changed
            if [[ "$v2" != "\"\"" ]]; then
                # Don't unset readonly variables
                [[ "${v1/-readonly/}" != "$v1" || "${v2/-readonly/}" != "$v2" ]] && continue

                # Don't unset arrays managed by add-zsh-hook,
                # also ignore a few special parameters
                # TODO: remember and remove hooks
                case "$k" in
                    (chpwd_functions|precmd_functions|preexec_functions|periodic_functions|zshaddhistory_functions|zshexit_functions|zsh_directory_name_functions)
                        continue
                    (path|PATH|fpath|FPATH)
                        continue;
                        ;;
                esac

                # Don't unset redefined variables, only newly defined
                # "" means variable didn't exist before plugin load
                # (didn't have a type)
                if [[ "$v1" = "\"\"" ]]; then
                    print "Unsetting variable $k"
                    # Checked that 4.3.17 does support "--"
                    # There cannot be parameter starting with
                    # "-" but let's defensively use "--" here
                    unset -- "$k"
                fi
            fi
        done
    fi

    #
    # 9. Forget the plugin
    #

    if [[ "$uspl2" = "$ZPLG_DEBUG_USPL2" ]]; then
        -zplg-clear-debug-report
        print "dtrace report saved to \$LASTREPORT"
    else
        print "Unregistering plugin $uspl2col"
        -zplg-unregister-plugin "$user" "$plugin"
        -zplg-clear-report-for "$user" "$plugin"
        print "Plugin's report saved to \$LASTREPORT"
    fi

}

# Updates given plugin
-zplg-update-or-status() {
    local st="$1"
    -zplg-any-to-user-plugin "$2" "$3"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    # Check if repository has a remote set, if it is _local
    if [[ "$user" = "_local" ]]; then
        local repo="$ZPLG_PLUGINS_DIR/${user}---${plugin}"
        if [[ -f "$repo/.git/config" ]]; then
            local -a config
            config=( "${(f)"$(<$repo/.git/config)"}" )
            if [[ -z "${(M)config:#\[remote[[:blank:]]*\]}" ]]; then
                -zplg-any-colorify-as-uspl2 "$user" "$plugin"
                print "$REPLY doesn't have a remote set, will not fetch"
                return
            fi
        fi
    fi

    if [[ "$st" = "status" ]]; then
        ( cd "$ZPLG_PLUGINS_DIR/${user}---${plugin}"; git status; )
    else
        ( cd "$ZPLG_PLUGINS_DIR/${user}---${plugin}"; git fetch --quiet && git log --color --date=short --pretty=format:'%Cgreen%cd %h %Creset%s %Cred%d%Creset' ..FETCH_HEAD | less -F && git pull --no-stat; )
    fi
}

-zplg-update-or-status-all() {
    builtin setopt localoptions nullglob

    local st="$1"
    local repo snip pd user plugin

    if [[ "$st" != "status" ]]; then
        for snip in "$ZPLG_SNIPPETS_DIR"/*; do
            [[ ! -f "$snip/.zplugin_url" ]] && continue
            local url=$(<$snip/.zplugin_url)
            -zplg-load-snippet "$url" "" "-f" "-u"
        done
        print
    fi

    if [[ "$st" = "status" ]]; then
        print "${ZPLG_COL[error]}Warning:${ZPLG_COL[rst]} status done also for unloaded plugins"
    else
        print "${ZPLG_COL[error]}Warning:${ZPLG_COL[rst]} updating also unloaded plugins"
    fi

    for repo in "$ZPLG_PLUGINS_DIR"/*; do
        pd="${repo:t}"

        # Two special cases
        [[ "$pd" = "_local---zplugin" ]] && continue
        [[ "$pd" = "custom" ]] && continue

        -zplg-any-colorify-as-uspl2 "$pd"

        # Check if repository has a remote set, if it is _local
        if [[ "$pd" = _local* ]]; then
            if [[ -f "$repo/.git/config" ]]; then
                local -a config
                config=( "${(f)"$(<$repo/.git/config)"}" )
                if [[ -z "${(M)config:#\[remote[[:blank:]]*\]}" ]]; then
                    print "\n$REPLY doesn't have a remote set, will not fetch"
                    continue
                fi
            fi
        fi

        # Must be a git repository
        if [[ ! -d "$repo/.git" ]]; then
            print "\n$REPLY not a git repository"
            continue
        fi

        if [[ "$st" = "status" ]]; then
            print "\nStatus for plugin $REPLY"
            ( cd "$repo"; git status )
        else
            print "\nUpdating plugin $REPLY"
            ( cd "$repo"; git fetch --quiet && git log --color --date=short --pretty=format:'%Cgreen%cd %h %Creset%s %Cred%d%Creset' ..FETCH_HEAD | less -F && git pull --no-stat; )
        fi
    done
}

# Updates Zplugin
-zplg-self-update() {
    ( cd "$ZPLG_DIR" ; git pull )
}

# Shows overall status
-zplg-show-zstatus() {
    builtin setopt localoptions nullglob extendedglob

    local infoc="${ZPLG_COL[info2]}"

    print "Zplugin's main directory: ${infoc}$ZPLG_HOME${reset_color}"
    print "Zplugin's binary directory: ${infoc}$ZPLG_DIR${reset_color}"
    print "Plugin directory: ${infoc}$ZPLG_PLUGINS_DIR${reset_color}"
    print "Completions directory: ${infoc}$ZPLG_COMPLETIONS_DIR${reset_color}"

    # Without _zlocal/zplugin
    print "Loaded plugins: ${infoc}$(( ${#ZPLG_REGISTERED_PLUGINS[@]} - 1 ))${reset_color}"

    # Count light-loaded plugins
    integer light=0
    local s
    for s in "${ZPLG_REGISTERED_STATES[@]}"; do
        [[ "$s" = 1 ]] && (( light ++ ))
    done
    # Without _zlocal/zplugin
    print "Light loaded: ${infoc}$(( light - 1 ))${reset_color}"

    # Downloaded plugins, without _zlocal/zplugin, custom
    typeset -a plugins
    plugins=( "$ZPLG_PLUGINS_DIR"/* )
    print "Downloaded plugins: ${infoc}$(( ${#plugins[@]} - 2 ))${reset_color}"

    # Number of enabled completions, with _zlocal/zplugin
    typeset -a completions
    completions=( "$ZPLG_COMPLETIONS_DIR"/_[^_]* )
    print "Enabled completions: ${infoc}${#completions[@]}${reset_color}"

    # Number of disabled completions, with _zlocal/zplugin
    completions=( "$ZPLG_COMPLETIONS_DIR"/[^_]* )
    print "Disabled completions: ${infoc}${#completions[@]}${reset_color}"

    # Number of completions existing in all plugins
    completions=( "$ZPLG_PLUGINS_DIR"/*/_[^_]* )
    print "Completions available overall: ${infoc}${#completions[@]}${reset_color}"

    # Enumerate snippets loaded
    print "Snippets loaded: ${infoc}${(j:, :onv)ZPLG_SNIPPETS[@]}${reset_color}"

    # Number of compiled plugins
    typeset -a matches m
    integer count=0
    matches=( $ZPLG_PLUGINS_DIR/*/*.zwc )

    local cur_plugin="" uspl1
    for m in "${matches[@]}"; do
        uspl1="${${m:h}:t}"

        if [[ "$cur_plugin" != "$uspl1" ]]; then
            (( count ++ ))
            cur_plugin="$uspl1"
        fi
    done

    print "Compiled plugins: ${infoc}$count${reset_color}"
}


# Gets list of compiled plugins
-zplg-compiled() {
    builtin setopt localoptions nullglob

    typeset -a matches m
    matches=( $ZPLG_PLUGINS_DIR/*/*.zwc )

    if [[ "${#matches[@]}" -eq "0" ]]; then
        print "No compiled plugins"
        return 0
    fi

    local cur_plugin="" uspl1
    for m in "${matches[@]}"; do
        file="${m:t}"
        uspl1="${${m:h}:t}"
        -zplg-any-to-user-plugin "$uspl1"
        user="${reply[-2]}" plugin="${reply[-1]}"

        if [[ "$cur_plugin" != "$uspl1" ]]; then
            [[ -n "$cur_plugin" ]] && print # newline
            -zplg-any-colorify-as-uspl2 "$user" "$plugin"
            print "$REPLY:"
            cur_plugin="$uspl1"
        fi

        print "$file"
    done
}

-zplg-compile-uncompile-all() {
    builtin setopt localoptions nullglob

    local compile="$1"

    typeset -a plugins
    plugins=( "$ZPLG_PLUGINS_DIR"/* )

    local p user plugin
    for p in "${plugins[@]}"; do
        [[ "${p:t}" = "custom" || "${p:t}" = "_local---zplugin" ]] && continue

        -zplg-any-to-user-plugin "${p:t}"
        user="${reply[-2]}" plugin="${reply[-1]}"

        -zplg-any-colorify-as-uspl2 "$user" "$plugin"
        print "$REPLY:"

        if [[ "$compile" = "1" ]]; then
            -zplg-compile-plugin "$user" "$plugin"
        else
            -zplg-uncompile-plugin "$user" "$plugin" "1"
        fi
    done
}

-zplg-list-compdef-replay() {
    print "Recorded compdefs:"
    local cdf
    for cdf in "${ZPLG_COMPDEF_REPLAY[@]}"; do
        print "compdef ${(Q)cdf}"
    done
}

-zplg-edit() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    # cd "$ZPLG_PLUGINS_DIR/${user}---${plugin}"
    -zplg-first "$1" "$2" || {
        print "${ZPLG_COL[error]}No source file found, cannot edit${ZPLG_COL[rst]}"
        return 1
    }

    local fname="${reply[-1]}"

    print "Editting ${ZPLG_COL[info]}$fname${ZPLG_COL[rst]} with ${ZPLG_COL[p]}${EDITOR:-vim}${ZPLG_COL[rst]}"
    "${EDITOR:-vim}" "$fname"
}

-zplg-glance() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    -zplg-first "$1" "$2" || {
        print "${ZPLG_COL[error]}No source file found, cannot glance${ZPLG_COL[rst]}"
        return 1
    }

    local fname="${reply[-1]}"

    integer has_256_colors=0
    [[ "$TERM" = xterm* || "$TERM" = "screen" ]] && has_256_colors=1

    {
        if (( ${+commands[pygmentize]} )); then
            print "Glancing with ${ZPLG_COL[info]}pygmentize${ZPLG_COL[rst]}"
            pygmentize -l bash -g "$fname"
        elif (( ${+commands[highlight]} )); then
            print "Glancing with ${ZPLG_COL[info]}highlight${ZPLG_COL[rst]}"
            if (( has_256_colors )); then
                highlight -q --force -S sh -O xterm256 "$fname"
            else
                highlight -q --force -S sh -O ansi "$fname"
            fi
        elif (( ${+commands[source-highlight]} )); then
            print "Glancing with ${ZPLG_COL[info]}source-highlight${ZPLG_COL[rst]}"
            source-highlight -fesc --failsafe -s zsh -o STDOUT -i "$fname"
        else
            cat "$fname"
        fi
    } | {
        if [[ -t 1 ]]; then
            less -iRFX
        else
            cat
        fi
    }
}

-zplg-changes() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    (
        cd "$ZPLG_PLUGINS_DIR/${user}---${plugin}"
        git log -p --graph --decorate --date=relative -C -M
    )
}

-zplg-recently() {
    builtin setopt localoptions nullglob extendedglob

    local IFS="."
    local gitout
    local timespec="${*// ##/.}"
    timespec="${timespec//.##/.}"
    [[ -z "$timespec" ]] && timespec="1.week"

    typeset -a plugins
    plugins=( "$ZPLG_PLUGINS_DIR"/* )

    local p uspl1
    for p in "${plugins[@]}"; do
        uspl1="${p:t}"
        [[ "$uspl1" = "custom" || "$uspl1" = "_local---zplugin" ]] && continue

        pushd "$p" >/dev/null
        if [[ -d ".git" ]]; then
            gitout=`git log --all --max-count=1 --since=$timespec`
            if [[ -n "$gitout" ]]; then
                -zplg-any-colorify-as-uspl2 "$uspl1"
                echo "$REPLY"
            fi
        fi
        popd >/dev/null
    done
}

-zplg-create() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    if (( ${+commands[curl]} == 0 || ${+commands[git]} == 0 )); then
        print "${ZPLG_COL[error]}curl and git needed${ZPLG_COL[rst]}"
        return 1
    fi

    # Read user
    local compcontext="user:User Name:(\"$USER\" \"$user\")"
    vared -cp "Github user name or just \"_local\": " user

    # Read plugin
    unset compcontext
    vared -cp 'Plugin name: ' plugin

    if [[ "$plugin" = "_unknown" ]]; then
        print "${ZPLG_COL[error]}No plugin name entered${ZPLG_COL[rst]}"
        return 1
    fi

    plugin="${plugin//[^a-zA-Z0-9_]##/-}"
    -zplg-any-colorify-as-uspl2 "$user" "$plugin"
    local uspl2col="$REPLY"
    print "Plugin is $uspl2col"

    if -zplg-exists-physically "$user" "$plugin"; then
        print "${ZPLG_COL[error]}Repository${ZPLG_COL[rst]} $uspl2col ${ZPLG_COL[error]}already exists locally${ZPLG_COL[rst]}"
        return 1
    fi

    cd "$ZPLG_PLUGINS_DIR"

    if [[ "$user" != "_local" ]]; then
        print "${ZPLG_COL[info]}Creating Github repository${ZPLG_COL[rst]}"
        curl --silent -u "$user" https://api.github.com/user/repos -d '{"name":"'"$plugin"'"}' >/dev/null
        git clone "https://github.com/${user}/${plugin}.git" "${user}---${plugin}" || {
            print "${ZPLG_COL[error]}Creation of remote repository $uspl2col ${ZPLG_COL[error]}failed${ZPLG_COL[rst]}"
            print "${ZPLG_COL[error]}Bad credentials?${ZPLG_COL[rst]}"
            return 1
        }
        cd "${user}---${plugin}"
    else
        print "${ZPLG_COL[info]}Creating local git repository${ZPLG_COL[rst]}"
        command mkdir "${user}---${plugin}"
        cd "${user}---${plugin}"
        git init || {
            print "Git repository initialization failed, aborting"
            return 1
        }
    fi

    echo >! "${plugin}.plugin.zsh"
    echo >! "README.md"
    echo >! "LICENSE"

    if [[ "$user" != "_local" ]]; then
        print "Remote repository $uspl2col set up as origin"
        print "You're in plugin's local folder"
        print "The files aren't added to git"
        print "Your next step after commiting will be:"
        print "git push -u origin master"
    else
        print "Created local $uspl2col plugin"
        print "You're in plugin's repository folder"
        print "The files aren't added to git"
    fi
}

# Compiles plugin with various options on and off
# to see how well the code is written
-zplg-stress() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    -zplg-first "$1" "$2" || {
        print "${ZPLG_COL[error]}No source file found, cannot stress${ZPLG_COL[rst]}"
        return 1
    }

    local dname="${reply[-2]}" fname="${reply[-1]}"

    integer compiled=1
    [[ -e "${fname}.zwc" ]] && command rm -f "${fname}.zwc" || compiled=0

    (
        emulate -LR ksh
        builtin unsetopt shglob kshglob
        for i in "${ZPLG_STRESS_TEST_OPTIONS[@]}"; do
            builtin setopt "$i"
            print -n "Stress-testing ${fname:t} for option $i "
            zcompile -R "$fname" 2>/dev/null && {
                print "[${ZPLG_COL[success]}Success${ZPLG_COL[rst]}]"
            } || {
                print "[${ZPLG_COL[failure]}Fail${ZPLG_COL[rst]}]"
            }
            builtin unsetopt "$i"
        done
    )

    command rm -f "${fname}.zwc"
    (( compiled )) && zcompile "$fname"
}
# }}}

-zplg-help() {
           print "${ZPLG_COL[p]}Usage${ZPLG_COL[rst]}:
-h|--help|help           - usage information
man                      - manual
zstatus                  - overall status of Zplugin
self-update              - updates Zplugin
load ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}       - load plugin
light ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}      - light plugin load, without reporting
unload ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}     - unload plugin
snippet [-f] [--command] ${ZPLG_COL[pname]}{url}${ZPLG_COL[rst]}       - source (or add to PATH with --command) local or remote file (-f: force - don't use cache)
update ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}     - Git update plugin (or all plugins and snippets if --all passed)
status ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}     - Git status for plugin (or all plugins if --all passed)
report ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}     - show plugin's report (or all plugins' if --all passed)
loaded|list [keyword]    - show what plugins are loaded (filter with \'keyword')
cd ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}         - cd into plugin's directory
create ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}     - create plugin (also together with Github repository)
edit ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}       - edit plugin's file with \$EDITOR
glance ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}     - look at plugin's source (pygmentize, {,source-}highlight)
stress ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}     - test plugin for compatibility with set of options
changes ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}    - view plugin's git log
recently ${ZPLG_COL[info]}[time-spec]${ZPLG_COL[rst]}     - show plugins that changed recently, argument is e.g. 1 month 2 days
clist|completions        - list completions in use
cdisable ${ZPLG_COL[info]}{cname}${ZPLG_COL[rst]}         - disable completion \`cname'
cenable  ${ZPLG_COL[info]}{cname}${ZPLG_COL[rst]}         - enable completion \`cname'
creinstall ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]} - install completions for plugin
cuninstall ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]} - uninstall completions for plugin
csearch                  - search for available completions from any plugin
compinit                 - refresh installed completions
dtrace|dstart            - start tracking what's going on in session
dstop                    - stop tracking what's going on in session
dunload                  - revert changes recorded between dstart and dstop
dreport                  - report what was going on in session
dclear                   - clear report of what was going on in session
compile  ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}   - compile plugin (or all plugins if --all passed)
uncompile ${ZPLG_COL[pname]}{plugin-name}${ZPLG_COL[rst]}  - remove compiled version of plugin (or of all plugins if --all passed)
compiled                 - list plugins that are compiled
cdlist                   - show compdef replay list
cdreplay                 - replay compdefs (to be done after compinit)
cdclear                  - clear compdef replay list"
}
