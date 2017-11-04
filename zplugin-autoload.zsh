# -*- mode: shell-script -*-
# vim:ft=zsh

builtin source ${ZPLGM[BIN_DIR]}"/zplugin-side.zsh"

ZPLGM[EXTENDED_GLOB]=""

#
# Backend, low level functions
#

# FUNCTION: -zplg-diff-functions-compute {{{
# Computes ZPLG_FUNCTIONS that holds new functions added by plugin.
# Uses data gathered earlier by -zplg-diff-functions().
#
# $1 - user/plugin
-zplg-diff-functions-compute() {
    local uspl2="$1"

    # Cannot run diff if *_BEFORE or *_AFTER variable is not set
    # Following is paranoid for *_BEFORE and *_AFTER being only spaces

    builtin setopt localoptions extendedglob
    [[ "${ZPLG_FUNCTIONS_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_FUNCTIONS_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1

    typeset -A func
    local i

    # This includes new functions. Quoting is kept (i.e. no i=${(Q)i})
    for i in "${(z)ZPLG_FUNCTIONS_AFTER[$uspl2]}"; do
        func[$i]=1
    done

    # Remove duplicated entries, i.e. existing before. Quoting is kept
    for i in "${(z)ZPLG_FUNCTIONS_BEFORE[$uspl2]}"; do
        # if would do unset, then: func[opp+a\[]: invalid parameter name
        func[$i]=0
    done

    # Store the functions, associating them with plugin ($uspl2)
    for i in "${(onk)func[@]}"; do
        [[ "${func[$i]}" = "1" ]] && ZPLG_FUNCTIONS[$uspl2]+="$i "
    done

    return 0
} # }}}
# FUNCTION: -zplg-diff-options-compute {{{
# Computes ZPLG_OPTIONS that holds options changed by plugin.
# Uses data gathered earlier by -zplg-diff-options().
#
# $1 - user/plugin
-zplg-diff-options-compute() {
    local uspl2="$1"

    # Cannot run diff if *_BEFORE or *_AFTER variable is not set
    # Following is paranoid for *_BEFORE and *_AFTER being only spaces
    builtin setopt localoptions extendedglob
    [[ "${ZPLG_OPTIONS_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_OPTIONS_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1

    typeset -A opts_before opts_after opts
    opts_before=( "${(z)ZPLG_OPTIONS_BEFORE[$uspl2]}" )
    opts_after=( "${(z)ZPLG_OPTIONS_AFTER[$uspl2]}" )
    opts=( )

    # Iterate through first array (keys the same
    # on both of them though) and test for a change
    local key
    for key in "${(k)opts_before[@]}"; do
        if [[ "${opts_before[$key]}" != "${opts_after[$key]}" ]]; then
            opts[$key]="${opts_before[$key]}"
        fi
    done

    # Serialize for reporting
    local bIFS="$IFS"; IFS=" "
    ZPLG_OPTIONS[$uspl2]="${(kv)opts[@]}"
    IFS="$bIFS"
    return 0
} # }}}
# FUNCTION: -zplg-diff-env-compute {{{
# Computes ZPLG_PATH, ZPLG_FPATH that hold (f)path components
# added by plugin. Uses data gathered earlier by -zplg-diff-env().
#
# $1 - user/plugin
-zplg-diff-env-compute() {
    local uspl2="$1"
    typeset -a tmp

    # Cannot run diff if *_BEFORE or *_AFTER variable is not set
    # Following is paranoid for *_BEFORE and *_AFTER being only spaces
    builtin setopt localoptions extendedglob
    [[ "${ZPLG_PATH_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_PATH_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1
    [[ "${ZPLG_FPATH_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_FPATH_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1

    typeset -A path_state fpath_state
    local i

    #
    # PATH processing
    #

    # This includes new path elements
    for i in "${(z)ZPLG_PATH_AFTER[$uspl2]}"; do
        path_state[$i]=1
    done

    # Remove duplicated entries, i.e. existing before
    for i in "${(z)ZPLG_PATH_BEFORE[$uspl2]}"; do
        unset "path_state[$i]"
    done

    # Store the path elements, associating them with plugin ($uspl2)
    for i in "${(onk)path_state[@]}"; do
        ZPLG_PATH[$uspl2]+="$i "
    done

    #
    # FPATH processing
    #

    # This includes new path elements
    for i in "${(z)ZPLG_FPATH_AFTER[$uspl2]}"; do
        fpath_state[$i]=1
    done

    # Remove duplicated entries, i.e. existing before
    for i in "${(z)ZPLG_FPATH_BEFORE[$uspl2]}"; do
        unset "fpath_state[$i]"
    done

    # Store the path elements, associating them with plugin ($uspl2)
    for i in "${(onk)fpath_state[@]}"; do
        ZPLG_FPATH[$uspl2]+="$i "
    done

    return 0
} # }}}
# FUNCTION: -zplg-diff-parameter-compute {{{
# Computes ZPLG_PARAMETERS_PRE, ZPLG_PARAMETERS_POST that hold
# parameters created or changed (their type) by plugin. Uses
# data gathered earlier by -zplg-diff-parameter().
#
# $1 - user/plugin
-zplg-diff-parameter-compute() {
    local uspl2="$1"
    typeset -a tmp

    # Cannot run diff if *_BEFORE or *_AFTER variable is not set
    # Following is paranoid for *_BEFORE and *_AFTER being only spaces
    builtin setopt localoptions extendedglob
    [[ "${ZPLG_PARAMETERS_BEFORE[$uspl2]}" != *[$'! \t']* || "${ZPLG_PARAMETERS_AFTER[$uspl2]}" != *[$'! \t']* ]] && return 1

    # Un-concatenated parameters from moment of diff start and of diff end
    typeset -A params_before params_after
    params_before=( "${(z)ZPLG_PARAMETERS_BEFORE[$uspl2]}" )
    params_after=( "${(z)ZPLG_PARAMETERS_AFTER[$uspl2]}" )

    # The parameters that changed, with save of what
    # parameter was when diff started or when diff ended
    typeset -A params_pre params_post
    params_pre=( )
    params_post=( )

    # Iterate through all existing keys, before or after diff,
    # i.e. after all variables that were somehow live across
    # the diffing process
    local key
    typeset -aU keys
    keys=( "${(k)params_after[@]}" );
    keys=( "${keys[@]}" "${(k)params_before[@]}" );
    for key in "${keys[@]}"; do
        key="${(Q)key}"
        if [[ "${params_after[$key]}" != "${params_before[$key]}" ]]; then
            # Empty for a new param, a type otherwise
            [[ -z "${params_before[$key]}" ]] && params_before[$key]="\"\""
            params_pre[$key]="${params_before[$key]}"

            # Current type, can also be empty, when plugin
            # unsets a parameter
            [[ -z "${params_after[$key]}" ]] && params_after[$key]="\"\""
            params_post[$key]="${params_after[$key]}"
        fi
    done

    # Serialize for reporting
    ZPLG_PARAMETERS_PRE[$uspl2]="${(j: :)${(qkv)params_pre[@]}}"
    ZPLG_PARAMETERS_POST[$uspl2]="${(j: :)${(qkv)params_post[@]}}"

    return 0
} # }}}
# FUNCTION: -zplg-any-to-uspl2 {{{
# Converts given plugin-spec to format that's used in keys for hash tables.
# So basically, creates string "user/plugin" (this format is called: uspl2).
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - (optional) plugin (only when $1 - i.e. user - given)
-zplg-any-to-uspl2() {
    -zplg-any-to-user-plugin "$1" "$2"
    REPLY="${reply[-2]}/${reply[-1]}"
} # }}}
# FUNCTION: -zplg-save-set-extendedglob {{{
# Enables extendedglob-option first saving if it was already
# enabled, for restoration of this state later.
-zplg-save-set-extendedglob() {
    [[ -o "extendedglob" ]] && ZPLGM[EXTENDED_GLOB]="1" || ZPLGM[EXTENDED_GLOB]="0"
    builtin setopt extendedglob
} # }}}
# FUNCTION: -zplg-restore-extendedglob {{{
# Restores extendedglob-option from state saved earlier.
-zplg-restore-extendedglob() {
    [[ "${ZPLGM[EXTENDED_GLOB]}" = "0" ]] && builtin unsetopt extendedglob || builtin setopt extendedglob
} # }}}
# FUNCTION: -zplg-prepare-readlink {{{
# Prepares readlink command, used for establishing completion's owner.
#
# $REPLY = ":" or "readlink"
-zplg-prepare-readlink() {
    REPLY=":"
    if type readlink 2>/dev/null 1>&2; then
        REPLY="readlink"
    fi
} # }}}
# FUNCTION: -zplg-clear-report-for {{{
# Clears all report data for given user/plugin. This is
# done by resetting all related global ZPLG_* hashes.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - (optional) plugin (only when $1 - i.e. user - given)
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

    # Option diffing
    ZPLG_OPTIONS[$REPLY]=""
    ZPLG_OPTIONS_BEFORE[$REPLY]=""
    ZPLG_OPTIONS_AFTER[$REPLY]=""

    # Environment diffing
    ZPLG_PATH[$REPLY]=""
    ZPLG_PATH_BEFORE[$REPLY]=""
    ZPLG_PATH_AFTER[$REPLY]=""
    ZPLG_FPATH[$REPLY]=""
    ZPLG_FPATH_BEFORE[$REPLY]=""
    ZPLG_FPATH_AFTER[$REPLY]=""

    # Parameter diffing
    ZPLG_PARAMETERS_PRE[$REPLY]=""
    ZPLG_PARAMETERS_POST[$REPLY]=""
    ZPLG_PARAMETERS_BEFORE[$REPLY]=""
    ZPLG_PARAMETERS_AFTER[$REPLY]=""
} # }}}
# FUNCTION: -zplg-exists-message {{{
# Checks if plugin is loaded. Testable. Also outputs error
# message if plugin is not loaded.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - (optional) plugin (only when $1 - i.e. user - given)
-zplg-exists-message() {
    -zplg-any-to-uspl2 "$1" "$2"
    if [[ -z "${ZPLG_REGISTERED_PLUGINS[(r)$REPLY]}" ]]; then
        -zplg-any-colorify-as-uspl2 "$1" "$2"
        print "${ZPLGM[col-error]}No such plugin${ZPLGM[col-rst]} $REPLY"
        return 1
    fi
    return 0
} # }}}

#
# Format functions
#

# FUNCTION: -zplg-format-functions {{{
# Creates a one or two columns text with functions created
# by given plugin.
#
# $1 - user/plugin (i.e. uspl2 format of plugin-spec)
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
} # }}}
# FUNCTION: -zplg-format-options {{{
# Creates one-column text about options that changed when
# plugin "$1" was loaded.
#
# $1 - user/plugin (i.e. uspl2 format of plugin-spec)
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
} # }}}
# FUNCTION: -zplg-format-env {{{
# Creates one-column text about FPATH or PATH elements
# added when given plugin was loaded.
#
# $1 - user/plugin (i.e. uspl2 format of plugin-spec)
# $2 - if 1, then examine PATH, if 2, then examine FPATH
-zplg-format-env() {
    local uspl2="$1" which="$2"

    # Format PATH?
    if [[ "$which" = "1" ]]; then
        typeset -a elem
        elem=( "${(z@)ZPLG_PATH[$uspl2]}" )
    elif [[ "$which" = "2" ]]; then
        typeset -a elem
        elem=( "${(z@)ZPLG_FPATH[$uspl2]}" )
    fi

    # Enumerate elements added
    local answer="" e
    for e in "${elem[@]}"; do
        [[ -z "$e" ]] && continue
        e="${(Q)e}"
        answer+="$e"$'\n'
    done

    [[ -n "$answer" ]] && REPLY="$answer"
} # }}}
# FUNCTION: -zplg-format-parameter {{{
# Creates one column text that lists global parameters that
# changed when the given plugin was loaded.
#
# $1 - user/plugin (i.e. uspl2 format of plugin-spec)
-zplg-format-parameter() {
    local uspl2="$1" infoc="${ZPLGM[col-info]}"

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
        answer+="$k ${infoc}[$v1 -> $v2]${ZPLGM[col-rst]}"$'\n'
    done

    [[ -n "$answer" ]] && REPLY="$answer"

    return 0
} # }}}

#
# Completion functions
#

# FUNCTION: -zplg-get-completion-owner {{{
# Returns "user---plugin" string (uspl1 format) of plugin that
# owns given completion.
#
# Both :A and readlink will be used, then readlink's output if
# results differ. Readlink might not be available.
#
# :A will read the link "twice" and give the final repository
# directory, possibly without username in the uspl format;
# readlink will read the link "once"
#
# $1 - absolute path to completion file (in COMPLETIONS_DIR)
# $2 - readlink command (":" or "readlink")
-zplg-get-completion-owner() {
    setopt localoptions extendedglob
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
        # Get the user---plugin part of path
        while [[ "$in_plugin_path" != */[^/]##---[^/]## && "$in_plugin_path" != "/" ]]; do
            in_plugin_path="${in_plugin_path:h}"
        done
        in_plugin_path="${in_plugin_path:t}"

        if [[ -z "$in_plugin_path" ]]; then
            in_plugin_path="${tmp:h}"
        fi
    else
        # readlink and :A have nothing
        in_plugin_path="[unknown]"
    fi

    REPLY="$in_plugin_path"
} # }}}
# FUNCTION: -zplg-get-completion-owner-uspl2col {{{
# For shortening of code - returns colorized plugin name
# that owns given completion.
#
# $1 - absolute path to completion file (in COMPLETIONS_DIR)
# $2 - readlink command (":" or "readlink")
-zplg-get-completion-owner-uspl2col() {
    # "cpath" "readline_cmd"
    -zplg-get-completion-owner "$1" "$2"
    -zplg-any-colorify-as-uspl2 "$REPLY"
} # }}}
# FUNCTION: -zplg-find-completions-of-plugin {{{
# Searches for completions owned by given plugin.
# Returns them in `reply' array.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-find-completions-of-plugin() {
    builtin setopt localoptions nullglob extendedglob
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" uspl="${1}---${2}"

    reply=( "${ZPLGM[PLUGINS_DIR]}/$uspl"/**/_[^_.][^.]#~*(zplg_functions|/zsdoc/)* )
} # }}}
# FUNCTION: -zplg-check-comp-consistency {{{
# Zplugin creates symlink for each installed completion.
# This function checks whether given completion (i.e.
# file like "_mkdir") is indeed a symlink. Backup file
# is a completion that is disabled - has the leading "_"
# removed.
#
# $1 - path to completion within plugin's directory
# $2 - path to backup file within plugin's directory
-zplg-check-comp-consistency() {
    local cfile="$1" bkpfile="$2"
    integer error="$3"

    # bkpfile must be a symlink
    if [[ -e "$bkpfile" && ! -L "$bkpfile" ]]; then
        print "${ZPLGM[col-error]}Warning: completion's backup file \`${bkpfile:t}' isn't a symlink${ZPLGM[col-rst]}"
        error=1
    fi

    # cfile must be a symlink
    if [[ -e "$cfile" && ! -L "$cfile" ]]; then
        print "${ZPLGM[col-error]}Warning: completion file \`${cfile:t}' isn't a symlink${ZPLGM[col-rst]}"
        error=1
    fi

    # Tell user that he can manually modify but should do it right
    (( error )) && print "${ZPLGM[col-error]}Manual edit of ${ZPLGM[COMPLETIONS_DIR]} occured?${ZPLGM[col-rst]}"
} # }}}
# FUNCTION: -zplg-check-which-completions-are-installed {{{
# For each argument that each should be a path to completion
# within a plugin's dir, it checks whether that completion
# is installed - returns 0 or 1 on corresponding positions
# in reply.
#
# $1, ... - path to completion within plugin's directory
-zplg-check-which-completions-are-installed() {
    local i cfile bkpfile
    reply=( )
    for i in "$@"; do
        cfile="${i:t}"
        bkpfile="${cfile#_}"

        if [[ -e "${ZPLGM[COMPLETIONS_DIR]}"/"$cfile" || -e "${ZPLGM[COMPLETIONS_DIR]}"/"$bkpfile" ]]; then
            reply+=( "1" )
        else
            reply+=( "0" )
        fi
    done
} # }}}
# FUNCTION: -zplg-check-which-completions-are-enabled {{{
# For each argument that each should be a path to completion
# within a plugin's dir, it checks whether that completion
# is disabled - returns 0 or 1 on corresponding positions
# in reply.
#
# Uninstalled completions will be reported as "0"
# - i.e. disabled
#
# $1, ... - path to completion within plugin's directory
-zplg-check-which-completions-are-enabled() {
    local i cfile
    reply=( )
    for i in "$@"; do
        cfile="${i:t}"

        if [[ -e "${ZPLGM[COMPLETIONS_DIR]}"/"$cfile" ]]; then
            reply+=( "1" )
        else
            reply+=( "0" )
        fi
    done
} # }}}
# FUNCTION: -zplg-uninstall-completions {{{
# Removes all completions of given plugin from Zshell (i.e. from FPATH).
# The FPATH is typically `~/.zplugin/completions/'.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-uninstall-completions() {
    builtin setopt localoptions nullglob extendedglob unset

    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    typeset -a completions symlinked backup_comps
    local c cfile bkpfile
    integer action global_action=0

    [[ "$user" = "%" ]] && completions=( "${plugin}"/**/_[^_.][^.]#~*(zplg_functions|/zsdoc/)* ) || completions=( "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"/**/_[^_.][^.]#~*(zplg_functions|/zsdoc/)* )
    symlinked=( "${ZPLGM[COMPLETIONS_DIR]}"/_[^_.][^.]# )
    backup_comps=( "${ZPLGM[COMPLETIONS_DIR]}"/[^_.][^.]# )

    # Delete completions if they are really there, either
    # as completions (_fname) or backups (fname)
    for c in "${completions[@]}"; do
        action=0
        cfile="${c:t}"
        bkpfile="${cfile#_}"

        # Remove symlink to completion
        if [[ -n "${symlinked[(r)*/$cfile]}" ]]; then
            command rm -f "${ZPLGM[COMPLETIONS_DIR]}/$cfile"
            action=1
        fi

        # Remove backup symlink (created by cdisable)
        if [[ -n "${backup_comps[(r)*/$bkpfile]}" ]]; then
            command rm -f "${ZPLGM[COMPLETIONS_DIR]}/$bkpfile"
            action=1
        fi

        if (( action )); then
            print "${ZPLGM[col-info]}Uninstalling completion \`$cfile'${ZPLGM[col-rst]}"
            # Make compinit notice the change
            -zplg-forget-completion "$cfile"
            (( global_action ++ ))
        else
            print "${ZPLGM[col-info]}Completion \`$cfile' not installed${ZPLGM[col-rst]}"
        fi
    done

    if (( global_action > 0 )); then
        print "${ZPLGM[col-info]}Uninstalled $global_action completions${ZPLGM[col-rst]}"
    fi
} # }}}
# FUNCTION: -zplg-compinit {{{
# User-exposed `compinit' frontend which first ensures that all
# completions managed by Zplugin are forgotten by Zshell. After
# that it runs normal `compinit', which should more easily detect
# Zplugin's completions.
#
# No arguments.
-zplg-compinit() {
    builtin setopt localoptions nullglob extendedglob

    typeset -a symlinked backup_comps
    local c cfile bkpfile

    symlinked=( "${ZPLGM[COMPLETIONS_DIR]}"/_[^_.][^.]# )
    backup_comps=( "${ZPLGM[COMPLETIONS_DIR]}"/[^_.][^.]# )

    # Delete completions if they are really there, either
    # as completions (_fname) or backups (fname)
    for c in "${symlinked[@]}" "${backup_comps[@]}"; do
        action=0
        cfile="${c:t}"
        cfile="_${cfile#_}"
        bkpfile="${cfile#_}"

        print "${ZPLGM[col-info]}Processing completion $cfile${ZPLGM[col-rst]}"
        -zplg-forget-completion "$cfile"
    done

    print "Initializing completion (compinit)..."
    command rm -f ~/.zcompdump

    # Workaround for a nasty trick in _vim
    (( ${+functions[_vim_files]} )) && unfunction _vim_files

    builtin autoload -Uz compinit
    compinit
} # }}}

#
# User-exposed functions
#

# FUNCTION: -zplg-self-update {{{
# Updates Zplugin code (does a git pull).
#
# User-action entry point.
-zplg-self-update() {
    ( builtin cd "${ZPLGM[BIN_DIR]}" ; command git pull )
} # }}}
# FUNCTION: -zplg-show-registered-plugins {{{
# Lists loaded plugins (subcommands list, lodaded).
#
# User-action entry point.
-zplg-show-registered-plugins() {
    typeset -a filtered
    local keyword="$1"

    -zplg-save-set-extendedglob
    keyword="${keyword## ##}"
    keyword="${keyword%% ##}"
    if [[ -n "$keyword" ]]; then
        print "Installed plugins matching ${ZPLGM[col-info]}$keyword${ZPLGM[col-rst]}:"
        filtered=( "${(M)ZPLG_REGISTERED_PLUGINS[@]:#*$keyword*}" )
    else
        filtered=( "${ZPLG_REGISTERED_PLUGINS[@]}" )
    fi
    -zplg-restore-extendedglob

    local i
    for i in "${filtered[@]}"; do
        [[ "$i" = "_local/zplugin" ]] && continue
        -zplg-any-colorify-as-uspl2 "$i"
        # Mark light loads
        [[ "${ZPLG_REGISTERED_STATES[$i]}" = "1" ]] && REPLY="$REPLY ${ZPLGM[col-info]}*${ZPLGM[col-rst]}"
        print "$REPLY"
    done
} # }}}
# FUNCTION: -zplg-unload {{{
# 1. Unfunction functions (created by plugin)
# 2. Delete bindkeys (...)
# 3. Delete Zstyles
# 4. Restore options
# 5. Remove aliases
# 6. Restore Zle state
# 7. Clean-up FPATH and PATH
# 8. Delete created variables
# 9. Forget the plugin
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-unload() {
    -zplg-any-to-user-plugin "$1" "$2"
    local uspl2="${reply[-2]}/${reply[-1]}" user="${reply[-2]}" plugin="${reply[-1]}"

    # KSH_ARRAYS immunity
    integer correct=0
    [[ -o "KSH_ARRAYS" ]] && correct=1

    # Allow unload for debug user
    if [[ "$uspl2" != "_dtrace/_dtrace" ]]; then
        -zplg-exists-message "$1" "$2" || return 1
    fi

    -zplg-any-colorify-as-uspl2 "$1" "$2"
    local uspl2col="$REPLY"

    # Store report of the plugin in variable LASTREPORT
    LASTREPORT=`-zplg-show-report "$1" "$2"`

    #
    # 1. Unfunction
    #

    -zplg-diff-functions-compute "$uspl2"
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
            print "Deleting bindkey $sw_arr1 $sw_arr2 ${ZPLGM[col-info]}mapped to $sw_arr4${ZPLGM[col-rst]}"
            bindkey -M "$sw_arr4" -r "$sw_arr1"
        elif [[ "$sw_arr3" = "-M" && "$sw_arr5" = "-R" ]]; then
            print "Deleting ${ZPLGM[col-info]}range${ZPLGM[col-rst]} bindkey $sw_arr1 $sw_arr2 ${ZPLGM[col-info]}mapped to $sw_arr4${ZPLGM[col-rst]}"
            bindkey -M "$sw_arr4" -Rr "$sw_arr1"
        elif [[ "$sw_arr3" != "-M" && "$sw_arr5" = "-R" ]]; then
            print "Deleting ${ZPLGM[col-info]}range${ZPLGM[col-rst]} bindkey $sw_arr1 $sw_arr2"
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
    -zplg-diff-options-compute "$uspl2"
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
            print "Removing ${ZPLGM[col-info]}suffix${ZPLGM[col-rst]} alias ${nv_arr1}=${nv_arr2}"
            unalias -s -- "$nv_arr1"
        elif [[ "$nv_arr3" = "-g" ]]; then
            print "Removing ${ZPLGM[col-info]}global${ZPLGM[col-rst]} alias ${nv_arr1}=${nv_arr2}"
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

    -zplg-diff-env-compute "$uspl2"

    # Have to iterate over $path elements and
    # skip those that were added by the plugin
    typeset -a new elem p
    elem=( "${(z)ZPLG_PATH[$uspl2]}" )
    for p in "${path[@]}"; do
        [[ -z "${elem[(r)$p]}" ]] && new+=( "$p" ) || {
            print "Removing PATH element ${ZPLGM[col-info]}$p${ZPLGM[col-rst]}"
            [[ -d "$p" ]] || print "${ZPLGM[col-error]}Warning:${ZPLGM[col-rst]} it didn't exist on disk"
        }
    done
    path=( "${new[@]}" )

    # The same for $fpath
    elem=( "${(z)ZPLG_FPATH[$uspl2]}" )
    new=( )
    for p in "${fpath[@]}"; do
        [[ -z "${elem[(r)$p]}" ]] && new+=( "$p" ) || {
            print "Removing FPATH element ${ZPLGM[col-info]}$p${ZPLGM[col-rst]}"
            [[ -d "$p" ]] || print "${ZPLGM[col-error]}Warning:${ZPLGM[col-rst]} it didn't exist on disk"
        }
    done
    fpath=( "${new[@]}" )

    #
    # 8. Delete created variables
    #

    # Paranoid for type of empty value,
    # i.e. include white spaces as empty
    -zplg-diff-parameter-compute "$uspl2"
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

    if [[ "$uspl2" = "_dtrace/_dtrace" ]]; then
        -zplg-clear-debug-report
        print "dtrace report saved to \$LASTREPORT"
    else
        print "Unregistering plugin $uspl2col"
        -zplg-unregister-plugin "$user" "$plugin"
        -zplg-clear-report-for "$user" "$plugin"
        print "Plugin's report saved to \$LASTREPORT"
    fi

} # }}}
# FUNCTION: -zplg-show-report {{{
# Displays report of the plugin given.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user (+ plugin in $2), plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-show-report() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}"
    local plugin="${reply[-1]}"

    # Allow debug report
    if [[ "$user/$plugin" != "_dtrace/_dtrace" ]]; then
        -zplg-exists-message "$user" "$plugin" || return 1
    fi

    # Print title
    printf "${ZPLGM[col-title]}Plugin report for${ZPLGM[col-rst]} %s/%s\n"\
            "${ZPLGM[col-uname]}$user${ZPLGM[col-rst]}"\
            "${ZPLGM[col-pname]}$plugin${ZPLGM[col-rst]}"

    # Print "----------"
    local msg="Plugin report for $user/$plugin"
    print -- "${ZPLGM[col-bar]}${(r:${#msg}::-:)tmp__}${ZPLGM[col-rst]}"

    # Print report gathered via shadowing
    print "${ZPLG_REPORTS[${user}/${plugin}]}"

    # Print report gathered via $functions-diffing
    REPLY=""
    -zplg-diff-functions-compute "$user/$plugin"
    -zplg-format-functions "$user/$plugin"
    [[ -n "$REPLY" ]] && print "${ZPLGM[col-p]}Functions created:${ZPLGM[col-rst]}"$'\n'"$REPLY"

    # Print report gathered via $options-diffing
    REPLY=""
    -zplg-diff-options-compute "$user/$plugin"
    -zplg-format-options "$user/$plugin"
    [[ -n "$REPLY" ]] && print "${ZPLGM[col-p]}Options changed:${ZPLGM[col-rst]}"$'\n'"$REPLY"

    # Print report gathered via environment diffing
    REPLY=""
    -zplg-diff-env-compute "$user/$plugin"
    -zplg-format-env "$user/$plugin" "1"
    [[ -n "$REPLY" ]] && print "${ZPLGM[col-p]}PATH elements added:${ZPLGM[col-rst]}"$'\n'"$REPLY"

    REPLY=""
    -zplg-format-env "$user/$plugin" "2"
    [[ -n "$REPLY" ]] && print "${ZPLGM[col-p]}FPATH elements added:${ZPLGM[col-rst]}"$'\n'"$REPLY"

    # Print report gathered via parameter diffing
    -zplg-diff-parameter-compute "$user/$plugin"
    -zplg-format-parameter "$user/$plugin"
    [[ -n "$REPLY" ]] && print "${ZPLGM[col-p]}Variables added or redefined:${ZPLGM[col-rst]}"$'\n'"$REPLY"

    # Print what completions plugin has
    -zplg-find-completions-of-plugin "$user" "$plugin"
    typeset -a completions
    completions=( "${reply[@]}" )

    if [[ "${#completions[@]}" -ge "1" ]]; then
        print "${ZPLGM[col-p]}Completions:${ZPLGM[col-rst]}"
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
                print -n " ${ZPLGM[col-uninst]}[not installed]${ZPLGM[col-rst]}"
            else
                if [[ "${enabled[idx]}" = "1" ]]; then
                    print -n " ${ZPLGM[col-info]}[enabled]${ZPLGM[col-rst]}"
                else
                    print -n " ${ZPLGM[col-error]}[disabled]${ZPLGM[col-rst]}"
                fi
            fi
            print
        done
        print
    fi
} # }}}
# FUNCTION: -zplg-show-all-reports {{{
# Displays reports of all loaded plugins.
#
# User-action entry point.
-zplg-show-all-reports() {
    local i
    for i in "${ZPLG_REGISTERED_PLUGINS[@]}"; do
        [[ "$i" = "_local/zplugin" ]] && continue
        -zplg-show-report "$i"
    done
} # }}}
# FUNCTION: -zplg-show-debug-report {{{
# Displays dtrace report (data recorded in interactive session).
#
# User-action entry point.
-zplg-show-debug-report() {
    -zplg-show-report "_dtrace/_dtrace"
} # }}}
# FUNCTION: -zplg-update-or-status {{{
# Updates (git pull) or does `git status' for given plugin.
#
# User-action entry point.
#
# $1 - "status" for status, other for update
# $2 - plugin spec (4 formats: user---plugin, user/plugin, user (+ plugin in $2), plugin)
# $3 - plugin (only when $1 - i.e. user - given)
-zplg-update-or-status() {
    setopt localoptions extendedglob

    local st="$1"
    -zplg-any-to-user-plugin "$2" "$3"
    local user="${reply[-2]}" plugin="${reply[-1]}"
    local local_dir="${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}" key
    local -A mdata sice

    -zplg-pack-ice "$user" "$plugin"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    # Check if repository has a remote set, if it is _local
    if [[ "$user" = "_local" ]]; then
        local repo="${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"
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
        ( builtin cd "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"; command git status; return 0; )
    else
        sice=( "${(z@)ZPLG_SICE[$user/$plugin]:-no op}" )

        { for key in from as pick mv cp atpull ver is_release; do
            mdata[$key]=$(<${local_dir}/._zplugin/$key)
          done
        } 2>/dev/null
        for key in from as pick mv cp atpull ver; do
            [[ -n "${sice[$key]}" || -n "${mdata[$key]}" ]] && sice[$key]=${sice[$key]:-${(q)mdata[$key]}}
        done

        if [[ -n "${mdata[is_release]}" ]]; then
            (( ${+functions[-zplg-setup-plugin-dir]} )) || builtin source ${ZPLGM[BIN_DIR]}"/zplugin-install.zsh"
            -zplg-get-latest-gh-r-version "$user" "$plugin"
            if [[ "${mdata[is_release]/\/$REPLY\//}" != "${mdata[is_release]}" ]]; then
                echo "Binary release already up to date (version: $REPLY)"
            else
                [[ ${${sice[atpull]}[1,2]} = *"!"* ]] && ( (( ${+sice[atpull]} )) && { builtin cd "$local_dir"; eval "${(Q)sice[atpull]#\\!}"; } )
                print -r -- "<mark>" >! "$local_dir/.zplugin_lstupd"
                for key in from as pick mv cp atpull ver; do ZPLG_ICE[$key]="${ZPLG_ICE[$key]:-${(Q)sice[$key]}}" done
                -zplg-setup-plugin-dir "$user" "$plugin"
            fi
        else
            ( builtin cd "$local_dir"
              command rm -f .zplugin_lstupd
              command git fetch --quiet && \
                command git log --color --date=short --pretty=format:'%Cgreen%cd %h %Creset%s %Cred%d%Creset' ..FETCH_HEAD | \
                command tee .zplugin_lstupd | \
                command less -F

              local -a log
              { log=( ${(@f)"$(<$local_dir/.zplugin_lstupd)"} ); } 2>/dev/null
              [[ ${#log} -gt 0 ]] && {
                [[ ${${sice[atpull]}[1,2]} = *"!"* ]] && ( (( ${+sice[atpull]} )) && { builtin cd "$local_dir"; eval "${(Q)sice[atpull]#\\!}"; } )
              }

              command git pull --no-stat; )
        fi

        # Any new commits?
        local -a log
        { log=( ${(@f)"$(<$local_dir/.zplugin_lstupd)"} ); } 2>/dev/null
        [[ ${#log} -gt 0 ]] && {
            if [[ -z "${mdata[is_release]}" && -n "${sice[mv]}" ]]; then
                local from="${${(Q)sice[mv]}%%[[:space:]]#->*}" to="${${(Q)sice[mv]}##*->[[:space:]]#}"
                local -a afr
                ( builtin cd "$local_dir"
                  afr=( ${~from}(N) )
                  [[ ${#afr} -gt 0 ]] && { command mv -vf "${afr[1]}" "$to"; command mv -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
                )
            fi

            if [[ -z "${mdata[is_release]}" && -n "${sice[cp]}" ]]; then
                local from="${${(Q)sice[cp]}%%[[:space:]]#->*}" to="${${(Q)sice[cp]}##*->[[:space:]]#}"
                local -a afr
                ( builtin cd "$local_dir"
                  afr=( ${~from}(N) )
                  [[ ${#afr} -gt 0 ]] && { command cp -vf "${afr[1]}" "$to"; command cp -vf "${afr[1]}".zwc "$to".zwc 2>/dev/null; }
                )
            fi

            [[ ${${sice[atpull]}[1,2]} != *"!"* ]] && ( (( ${+sice[atpull]} )) && { builtin cd "$local_dir"; eval "${(Q)sice[atpull]}"; } )
        }

        # Record new ICE modifiers used
        ( builtin cd "$local_dir"
          command mkdir -p ._zplugin
          for key in proto from as pick mv cp atpull ver; do
              print -r -- "${(Q)sice[$key]}" >! "._zplugin/$key"
          done
        )
    fi

    return 0
} # }}}
# FUNCTION: -zplg-update-or-status-all {{{
# Updates (git pull) or does `git status` for all existing plugins.
# This includes also plugins that are not loaded into Zsh (but exist
# on disk). Also updates (i.e. redownloads) snippets.
#
# User-action entry point.
-zplg-update-or-status-all() {
    builtin setopt localoptions nullglob

    local st="$1"
    local repo snip pd user plugin

    if [[ "$st" != "status" ]]; then
        for snip in "${ZPLGM[SNIPPETS_DIR]}"/**/._zplugin/mode; do
            [[ ! -f "${snip:h}/url" ]] && continue
            {
                local mode=$(<${snip})
                local url=$(<${snip:h}/url)
                local as=$(<${snip:h}/as)
                local pick=$(<${snip:h}/pick)
                local mv=$(<${snip:h}/mv)
                local cp=$(<${snip:h}/cp)
                local atpull=$(<${snip:h}/atpull)
            } 2>/dev/null
            [[ "$mode" = "1" ]] && zplugin ice svn
            [[ "$as" = "command" ]] && zplugin ice as"command"
            [[ -n "$pick" ]] && zplugin ice pick"$pick"
            [[ -n "$mv" ]] && zplugin ice mv"$mv"
            [[ -n "$cp" ]] && zplugin ice cp"$cp"
            [[ -n "$atpull" ]] && zplugin ice atpull"$atpull"
            -zplg-load-snippet "$url" "" "-f" "-u"
            ZPLG_ICE=()
        done
        print
    fi

    if [[ "$st" = "status" ]]; then
        print "${ZPLGM[col-error]}Warning:${ZPLGM[col-rst]} status done also for unloaded plugins"
    else
        print "${ZPLGM[col-error]}Warning:${ZPLGM[col-rst]} updating also unloaded plugins"
    fi

    for repo in "${ZPLGM[PLUGINS_DIR]}"/*; do
        pd="${repo:t}"

        # Two special cases
        [[ "$pd" = "custom" || "$pd" = "_local---zplugin" ]] && continue

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

        -zplg-any-to-user-plugin "$pd"
        local user="${reply[-2]}" plugin="${reply[-1]}"

        # Must be a git repository or a binary release
        if [[ ! -d "$repo/.git" && ! -f "$repo/._zplugin/is_release" ]]; then
            print "\n$REPLY not a git repository"
            continue
        fi

        if [[ "$st" = "status" ]]; then
            print "\nStatus for plugin $REPLY"
            ( builtin cd "$repo"; command git status )
        else
            print "\nUpdating plugin $REPLY"
            -zplg-update-or-status "update" "$user" "$plugin"
        fi
    done
} # }}}
# FUNCTION: -zplg-show-zstatus {{{
# Shows Zplugin status, i.e. number of loaded plugins,
# of available completions, etc.
#
# User-action entry point.
-zplg-show-zstatus() {
    builtin setopt localoptions nullglob extendedglob

    local infoc="${ZPLGM[col-info2]}"

    print "Zplugin's main directory: ${infoc}${ZPLGM[HOME_DIR]}${reset_color}"
    print "Zplugin's binary directory: ${infoc}${ZPLGM[BIN_DIR]}${reset_color}"
    print "Plugin directory: ${infoc}${ZPLGM[PLUGINS_DIR]}${reset_color}"
    print "Completions directory: ${infoc}${ZPLGM[COMPLETIONS_DIR]}${reset_color}"

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
    plugins=( "${ZPLGM[PLUGINS_DIR]}"/* )
    print "Downloaded plugins: ${infoc}$(( ${#plugins[@]} - 1 ))${reset_color}"

    # Number of enabled completions, with _zlocal/zplugin
    typeset -a completions
    completions=( "${ZPLGM[COMPLETIONS_DIR]}"/_[^_.][^.]# )
    print "Enabled completions: ${infoc}${#completions[@]}${reset_color}"

    # Number of disabled completions, with _zlocal/zplugin
    completions=( "${ZPLGM[COMPLETIONS_DIR]}"/[^_.][^.]# )
    print "Disabled completions: ${infoc}${#completions[@]}${reset_color}"

    # Number of completions existing in all plugins
    completions=( "${ZPLGM[PLUGINS_DIR]}"/*/**/_[^_.][^.]#~*(zplg_functions|/zsdoc/)* )
    print "Completions available overall: ${infoc}${#completions[@]}${reset_color}"

    # Enumerate snippets loaded
    print "Snippets loaded: ${infoc}${(j:, :onv)ZPLG_SNIPPETS[@]}${reset_color}"

    # Number of compiled plugins
    typeset -a matches m
    integer count=0
    matches=( ${ZPLGM[PLUGINS_DIR]}/*/*.zwc )

    local cur_plugin="" uspl1
    for m in "${matches[@]}"; do
        uspl1="${${m:h}:t}"

        if [[ "$cur_plugin" != "$uspl1" ]]; then
            (( count ++ ))
            cur_plugin="$uspl1"
        fi
    done

    print "Compiled plugins: ${infoc}$count${reset_color}"
} # }}}
# FUNCTION: -zplg-show-times {{{
# Shows loading times of all loaded plugins.
#
# User-action entry point.
-zplg-show-times() {
    setopt localoptions extendedglob
    local entry entry2 user plugin
    float -F 3 sum=0.0

    print "Plugin loading times:"
    for entry in "${(@on)ZPLGM[(I)TIME_[0-9]##_*]}"; do
        entry2="${entry#TIME_[0-9]##_}"
        if [[ "$entry2" = (http|https|ftp|ftps|scp|OMZ|PZT):* ]]; then
            REPLY="${ZPLGM[col-pname]}$entry2${ZPLGM[col-rst]}"
        else
            user="${entry2%---*}"
            plugin="${entry2#*---}"
            -zplg-any-colorify-as-uspl2 "$user" "$plugin"
        fi

        print "${ZPLGM[$entry]} sec" - "$REPLY"
        (( sum += ZPLGM[$entry] ))
    done
    print "Total: $sum sec"
}
# }}}

# FUNCTION: -zplg-compiled {{{
# Displays list of plugins that are compiled.
#
# User-action entry point.
-zplg-compiled() {
    builtin setopt localoptions nullglob

    typeset -a matches m
    matches=( ${ZPLGM[PLUGINS_DIR]}/*/*.zwc )

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
} # }}}
# FUNCTION: -zplg-compile-uncompile-all {{{
# Compiles or uncompiles all existing (on disk) plugins.
#
# User-action entry point.
-zplg-compile-uncompile-all() {
    builtin setopt localoptions nullglob

    local compile="$1"

    typeset -a plugins
    plugins=( "${ZPLGM[PLUGINS_DIR]}"/* )

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
} # }}}
# FUNCTION: -zplg-uncompile-plugin {{{
# Uncompiles given plugin.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user (+ plugin in $2), plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-uncompile-plugin() {
    builtin setopt localoptions nullglob

    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" silent="$3"

    # There are plugins having ".plugin.zsh"
    # in ${plugin} directory name, also some
    # have ".zsh" there
    local pdir_path="${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"
    typeset -a matches m
    matches=( $pdir_path/*.zwc )

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
        print "Removing ${ZPLGM[col-info]}${m:t}${ZPLGM[col-rst]}"
        command rm -f "$m"
    done
} # }}}

# FUNCTION: -zplg-show-completions {{{
# Display installed (enabled and disabled), completions. Detect
# stray and improper ones.
#
# Completions live even when plugin isn't loaded - if they are
# installed and enabled.
#
# User-action entry point.
-zplg-show-completions() {
    builtin setopt localoptions nullglob extendedglob

    typeset -a completions
    completions=( "${ZPLGM[COMPLETIONS_DIR]}"/_[^_.][^.]# "${ZPLGM[COMPLETIONS_DIR]}"/[^_.][^.]# )

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
        (( disabled )) && print -n " ${ZPLGM[col-error]}[disabled]${ZPLGM[col-rst]}"
        (( unknown )) && print -n " ${ZPLGM[col-error]}[unknown file, clean with cclear]${ZPLGM[col-rst]}"
        (( stray )) && print -n " ${ZPLGM[col-error]}[stray, clean with cclear]${ZPLGM[col-rst]}"
        print
    done
} # }}}
# FUNCTION: -zplg-clear-completions {{{
# Delete stray and improper completions.
#
# Completions live even when plugin isn't loaded - if they are
# installed and enabled.
#
# User-action entry point.
-zplg-clear-completions() {
    builtin setopt localoptions nullglob extendedglob

    typeset -a completions
    completions=( "${ZPLGM[COMPLETIONS_DIR]}"/_[^_.][^.]# "${ZPLGM[COMPLETIONS_DIR]}"/[^_.][^.]# )

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
            (( disabled )) && print -n " ${ZPLGM[col-error]}[disabled]${ZPLGM[col-rst]}"
            (( unknown )) && print -n " ${ZPLGM[col-error]}[unknown file]${ZPLGM[col-rst]}"
            (( stray )) && print -n " ${ZPLGM[col-error]}[stray]${ZPLGM[col-rst]}"
            print
            command rm -f "$cpath"
        fi
    done
} # }}}
# FUNCTION: -zplg-search-completions {{{
# While -zplg-show-completions() shows what completions are
# installed, this functions searches through all plugin dirs
# showing what's available in general (for installation).
#
# User-action entry point.
-zplg-search-completions() {
    builtin setopt localoptions nullglob extendedglob

    typeset -a plugin_paths
    plugin_paths=( "${ZPLGM[PLUGINS_DIR]}"/*---* )

    # Find longest plugin name. Things are ran twice here, first pass
    # is to get longest name of plugin which is having any completions
    integer longest=0
    typeset -a completions
    local pp
    for pp in "${plugin_paths[@]}"; do
        completions=( "$pp"/**/_[^_.][^.]#~*(zplg_functions|/zsdoc/)* )
        if [[ "${#completions[@]}" -gt 0 ]]; then
            local pd="${pp:t}"
            [[ "${#pd}" -gt "$longest" ]] && longest="${#pd}"
        fi
    done

    print "${ZPLGM[col-info]}[+]${ZPLGM[col-rst]} is installed, ${ZPLGM[col-p]}[-]${ZPLGM[col-rst]} uninstalled, ${ZPLGM[col-error]}[+-]${ZPLGM[col-rst]} partially installed"

    local c
    for pp in "${plugin_paths[@]}"; do
        completions=( "$pp"/**/_[^_.][^.]#~*(zplg_functions|/zsdoc/)* )

        if [[ "${#completions[@]}" -gt 0 ]]; then
            # Array of completions, e.g. ( _cp _xauth )
            completions=( "${completions[@]:t}" )

            # Detect if the completions are installed
            integer all_installed="${#completions[@]}"
            for c in "${completions[@]}"; do
                if [[ -e "${ZPLGM[COMPLETIONS_DIR]}/$c" || -e "${ZPLGM[COMPLETIONS_DIR]}/${c#_}" ]]; then
                    (( all_installed -- ))
                fi
            done

            if [[ "$all_installed" -eq "${#completions[@]}" ]]; then
                print -n "${ZPLGM[col-p]}[-]${ZPLGM[col-rst]} "
            elif [[ "$all_installed" -eq "0" ]]; then
                print -n "${ZPLGM[col-info]}[+]${ZPLGM[col-rst]} "
            else
                print -n "${ZPLGM[col-error]}[+-]${ZPLGM[col-rst]} "
            fi

            # Convert directory name to colorified $user/$plugin
            -zplg-any-colorify-as-uspl2 "${pp:t}"

            # Adjust for escape code (nasty, utilizes fact that
            # ${ZPLGM[col-rst]} is used twice, so as a $ZPLG_COL)
            integer adjust_ec=$(( ${#reset_color} * 2 + ${#ZPLGM[col-uname]} + ${#ZPLGM[col-pname]} ))

            print "${(r:longest+adjust_ec:: :)REPLY} ${(j:, :)completions}"
        fi
    done
} # }}}
# FUNCTION: -zplg-cenable {{{
# Disables given installed completion.
#
# User-action entry point.
#
# $1 - e.g. "_mkdir" or "mkdir"
-zplg-cenable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZPLGM[COMPLETIONS_DIR]}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        print "${ZPLGM[col-error]}No such completion \`$c'${ZPLGM[col-rst]}"
        return 1
    fi

    # Check if there is no backup file
    # This is treated as if the completion is already enabled
    if [[ ! -e "$bkpfile" ]]; then
        print "Completion ${ZPLGM[col-info]}$c${ZPLGM[col-rst]} already enabled"

        -zplg-check-comp-consistency "$cfile" "$bkpfile" 0
        return 1
    fi

    # Disabled, but completion file already exists?
    if [[ -e "$cfile" ]]; then
        print "${ZPLGM[col-error]}Warning: completion's file \`${cfile:t}' exists, will overwrite${ZPLGM[col-rst]}"
        print "${ZPLGM[col-error]}Completion is actually enabled and will re-enable it again${ZPLGM[col-rst]}"
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

    print "Enabled ${ZPLGM[col-info]}$c${ZPLGM[col-rst]} completion belonging to $REPLY"

    return 0
} # }}}
# FUNCTION: -zplg-cdisable {{{
# Enables given installed completion.
#
# User-action entry point.
#
# $1 - e.g. "_mkdir" or "mkdir"
-zplg-cdisable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZPLGM[COMPLETIONS_DIR]}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        print "${ZPLGM[col-error]}No such completion \`$c'${ZPLGM[col-rst]}"
        return 1
    fi

    # Check if it's already disabled
    # Not existing "$cfile" says that
    if [[ ! -e "$cfile" ]]; then
        print "Completion ${ZPLGM[col-info]}$c${ZPLGM[col-rst]} already disabled"

        -zplg-check-comp-consistency "$cfile" "$bkpfile" 0
        return 1
    fi

    # No disable, but bkpfile exists?
    if [[ -e "$bkpfile" ]]; then
        print "${ZPLGM[col-error]}Warning: completion's backup file \`${bkpfile:t}' already exists, will overwrite${ZPLGM[col-rst]}"
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

    print "Disabled ${ZPLGM[col-info]}$c${ZPLGM[col-rst]} completion belonging to $REPLY"

    return 0
} # }}}

# FUNCTION: -zplg-cd {{{
# Jumps to plugin's directory (in Zplugin's home directory).
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-cd() {
    setopt localoptions extendedglob

    if [[ "$1" = (http|https|ftp|ftps|scp)://* || "$1" = OMZ::* || "$1" = PZT::* ]]; then
        integer MBEGIN MEND
        local url="$1" url1 url2 filenameA filenameB filename0A filename0B local_dirA local_dirB MATCH

        # Remove leading whitespace and trailing /
        url="${${url#"${url%%[! $'\t']*}"}%/}"
        url1="$url" url2="$url"

        local -A sice
        local -a tmp
        tmp=( "${(z@)ZPLG_SICE[$url/]}" )
        (( ${#tmp} > 1 && ${#tmp} % 2 == 0 )) && sice=( "${tmp[@]}" )

        url1[1,5]="${ZPLG_1MAP[${url[1,5]}]:-$url[1,5]}" # svn
        url2[1,5]="${ZPLG_2MAP[${url[1,5]}]:-$url[1,5]}" # normal

        filenameA="${${url1%%\?*}:t}"
        filename0A="${${${url1%%\?*}:h}:t}"
        filenameB="${${url2%%\?*}:t}"
        filename0B="${${${url2%%\?*}:h}:t}"

        # Construct a local directory name from what's in url
        local_dirA="${${url1%/*}//(#m)(http|https|ftp|ftps|scp):\/\//${MATCH%???}--}"
        local_dirA="${${${${local_dirA//\//--}//=/--EQ--}//\?/--QM--}//\&/--AMP--}"
        local_dirA="${ZPLGM[SNIPPETS_DIR]}/$local_dirA"

        local_dirB="${${url2%/*}//(#m)(http|https|ftp|ftps|scp):\/\//${MATCH%???}--}"
        local_dirB="${${${${local_dirB//\//--}//=/--EQ--}//\?/--QM--}//\&/--AMP--}"
        local_dirB="${ZPLGM[SNIPPETS_DIR]}/${local_dirB%--$filename0B}/$filename0B"

        [[ "${+sice[svn]}" = "1" || -e "$local_dirA/$filenameA" ]] && {
            [[ -e "$local_dirA/$filenameA" ]] && builtin cd "$local_dirA/$filenameA" || echo "No such snippet"
        } || {
            [[ -e "$local_dirB" ]] && builtin cd "$local_dirB" || echo "No such snippet"
        }
    else
        -zplg-any-to-user-plugin "$1" "$2"
        local user="${reply[-2]}" plugin="${reply[-1]}"

        -zplg-exists-physically-message "$user" "$plugin" || return 1

        builtin cd "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"
    fi
} # }}}
# FUNCTION: -zplg-changes {{{
# Shows `git log` of given plugin.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-changes() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    (
        builtin cd "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"
        command git log -p --graph --decorate --date=relative -C -M
    )
} # }}}
# FUNCTION: -zplg-recently {{{
# Shows plugins that obtained commits in specified past time.
#
# User-action entry point.
#
# $1 - time spec, e.g. "1 week"
-zplg-recently() {
    builtin setopt localoptions nullglob extendedglob

    local IFS="."
    local gitout
    local timespec="${*// ##/.}"
    timespec="${timespec//.##/.}"
    [[ -z "$timespec" ]] && timespec="1.week"

    typeset -a plugins
    plugins=( "${ZPLGM[PLUGINS_DIR]}"/* )

    local p uspl1
    for p in "${plugins[@]}"; do
        uspl1="${p:t}"
        [[ "$uspl1" = "custom" || "$uspl1" = "_local---zplugin" ]] && continue

        pushd "$p" >/dev/null
        if [[ -d ".git" ]]; then
            gitout=`command git log --all --max-count=1 --since=$timespec`
            if [[ -n "$gitout" ]]; then
                -zplg-any-colorify-as-uspl2 "$uspl1"
                echo "$REPLY"
            fi
        fi
        popd >/dev/null
    done
} # }}}
# FUNCTION: -zplg-create {{{
# Creates a plugin, also on Github (if not "_local/name" plugin).
#
# User-action entry point.
#
# $1 - (optional) plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - (optional) plugin (only when $1 - i.e. user - given)
-zplg-create() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    if (( ${+commands[curl]} == 0 || ${+commands[git]} == 0 )); then
        print "${ZPLGM[col-error]}curl and git needed${ZPLGM[col-rst]}"
        return 1
    fi

    # Read user
    local compcontext="user:User Name:(\"$USER\" \"$user\")"
    vared -cp "Github user name or just \"_local\": " user

    # Read plugin
    unset compcontext
    vared -cp 'Plugin name: ' plugin

    if [[ "$plugin" = "_unknown" ]]; then
        print "${ZPLGM[col-error]}No plugin name entered${ZPLGM[col-rst]}"
        return 1
    fi

    plugin="${plugin//[^a-zA-Z0-9_]##/-}"
    -zplg-any-colorify-as-uspl2 "$user" "$plugin"
    local uspl2col="$REPLY"
    print "Plugin is $uspl2col"

    if -zplg-exists-physically "$user" "$plugin"; then
        print "${ZPLGM[col-error]}Repository${ZPLGM[col-rst]} $uspl2col ${ZPLGM[col-error]}already exists locally${ZPLGM[col-rst]}"
        return 1
    fi

    builtin cd "${ZPLGM[PLUGINS_DIR]}"

    if [[ "$user" != "_local" ]]; then
        print "${ZPLGM[col-info]}Creating Github repository${ZPLGM[col-rst]}"
        curl --silent -u "$user" https://api.github.com/user/repos -d '{"name":"'"$plugin"'"}' >/dev/null
        command git clone "https://github.com/${user}/${plugin}.git" "${user}---${plugin}" || {
            print "${ZPLGM[col-error]}Creation of remote repository $uspl2col ${ZPLGM[col-error]}failed${ZPLGM[col-rst]}"
            print "${ZPLGM[col-error]}Bad credentials?${ZPLGM[col-rst]}"
            return 1
        }
        builtin cd "${user}---${plugin}"
    else
        print "${ZPLGM[col-info]}Creating local git repository${ZPLGM[col-rst]}"
        command mkdir "${user}---${plugin}"
        builtin cd "${user}---${plugin}"
        command git init || {
            print "Git repository initialization failed, aborting"
            return 1
        }
    fi

    echo >! "${plugin}.plugin.zsh"
    echo >! "README.md"
    echo >! "LICENSE"

    if [[ "$user" != "_local" ]]; then
        print "Remote repository $uspl2col set up as origin."
        print "You're in plugin's local folder, the files aren't added to git."
        print "Your next step after commiting will be:"
        print "git push -u origin master"
    else
        print "Created local $uspl2col plugin."
        print "You're in plugin's repository folder, the files aren't added to git."
    fi
} # }}}
# FUNCTION: -zplg-glance {{{
# Shows colorized source code of plugin. Is able to use pygmentize,
# highlight, GNU source-highlight.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-glance() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    -zplg-first "$1" "$2" || {
        print "${ZPLGM[col-error]}No source file found, cannot glance${ZPLGM[col-rst]}"
        return 1
    }

    local fname="${reply[-1]}"

    integer has_256_colors=0
    [[ "$TERM" = xterm* || "$TERM" = "screen" ]] && has_256_colors=1

    {
        if (( ${+commands[pygmentize]} )); then
            print "Glancing with ${ZPLGM[col-info]}pygmentize${ZPLGM[col-rst]}"
            pygmentize -l bash -g "$fname"
        elif (( ${+commands[highlight]} )); then
            print "Glancing with ${ZPLGM[col-info]}highlight${ZPLGM[col-rst]}"
            if (( has_256_colors )); then
                highlight -q --force -S sh -O xterm256 "$fname"
            else
                highlight -q --force -S sh -O ansi "$fname"
            fi
        elif (( ${+commands[source-highlight]} )); then
            print "Glancing with ${ZPLGM[col-info]}source-highlight${ZPLGM[col-rst]}"
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
} # }}}
# FUNCTION: -zplg-edit {{{
# Runs $EDITOR on source of given plugin. If the variable is not
# set then defaults to `vim'.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-edit() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    # builtin cd "${ZPLGM[PLUGINS_DIR]}/${user}---${plugin}"
    -zplg-first "$1" "$2" || {
        print "${ZPLGM[col-error]}No source file found, cannot edit${ZPLGM[col-rst]}"
        return 1
    }

    local fname="${reply[-1]}"

    print "Editting ${ZPLGM[col-info]}$fname${ZPLGM[col-rst]} with ${ZPLGM[col-p]}${EDITOR:-vim}${ZPLGM[col-rst]}"
    "${EDITOR:-vim}" "$fname"
} # }}}
# FUNCTION: -zplg-stress {{{
# Compiles plugin with various options on and off to see
# how well the code is written. The options are:
#
# NO_SHORT_LOOPS, IGNORE_BRACES, IGNORE_CLOSE_BRACES, SH_GLOB,
# CSH_JUNKIE_QUOTES, NO_MULTI_FUNC_DEF.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
-zplg-stress() {
    -zplg-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    -zplg-exists-physically-message "$user" "$plugin" || return 1

    -zplg-first "$1" "$2" || {
        print "${ZPLGM[col-error]}No source file found, cannot stress${ZPLGM[col-rst]}"
        return 1
    }

    local pdir_path="${reply[-2]}" fname="${reply[-1]}"

    integer compiled=1
    [[ -e "${fname}.zwc" ]] && command rm -f "${fname}.zwc" || compiled=0

    local -a ZPLG_STRESS_TEST_OPTIONS
    ZPLG_STRESS_TEST_OPTIONS=( "NO_SHORT_LOOPS" "IGNORE_BRACES" "IGNORE_CLOSE_BRACES" "SH_GLOB" "CSH_JUNKIE_QUOTES" "NO_MULTI_FUNC_DEF" )

    (
        emulate -LR ksh
        builtin unsetopt shglob kshglob
        for i in "${ZPLG_STRESS_TEST_OPTIONS[@]}"; do
            builtin setopt "$i"
            print -n "Stress-testing ${fname:t} for option $i "
            zcompile -R "$fname" 2>/dev/null && {
                print "[${ZPLGM[col-success]}Success${ZPLGM[col-rst]}]"
            } || {
                print "[${ZPLGM[col-failure]}Fail${ZPLGM[col-rst]}]"
            }
            builtin unsetopt "$i"
        done
    )

    command rm -f "${fname}.zwc"
    (( compiled )) && zcompile "$fname"
} # }}}
# FUNCTION: -zplg-list-compdef-replay {{{
# Shows recorded compdefs (called by plugins loaded earlier).
# Plugins often call `compdef' hoping for `compinit' being
# already ran. Zplugin solves this by recording compdefs.
#
# User-action entry point.
-zplg-list-compdef-replay() {
    print "Recorded compdefs:"
    local cdf
    for cdf in "${ZPLG_COMPDEF_REPLAY[@]}"; do
        print "compdef ${(Q)cdf}"
    done
} # }}}

#
# Help function
#

# FUNCTION: -zplg-help {{{
# Shows usage information.
#
# User-action entry point.
-zplg-help() {
           print "${ZPLGM[col-p]}Usage${ZPLGM[col-rst]}:
-h|--help|help           - usage information
man                      - manual
zstatus                  - overall status of Zplugin
times                    - statistics on plugin load times, sorted in order of loading
self-update              - updates Zplugin
load ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}       - load plugin, can also receive absolute local path
light ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}      - light plugin load, without reporting
unload ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}     - unload plugin
snippet [-f] [--command] ${ZPLGM[col-pname]}{url}${ZPLGM[col-rst]} - source (or add to PATH with --command) local or remote file (-f: force - don't use cache)
ice <ice specification>  - add ICE to next command, argument is e.g. from\"gitlab\"
update ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}     - Git update plugin (or all plugins and snippets if --all passed)
status ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}     - Git status for plugin (or all plugins if --all passed)
report ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}     - show plugin's report (or all plugins' if --all passed)
loaded|list [keyword]    - show what plugins are loaded (filter with \'keyword')
cd ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}         - cd into plugin's directory; also support snippets, if feed with URL
create ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}     - create plugin (also together with Github repository)
edit ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}       - edit plugin's file with \$EDITOR
glance ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}     - look at plugin's source (pygmentize, {,source-}highlight)
stress ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}     - test plugin for compatibility with set of options
changes ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}    - view plugin's git log
recently ${ZPLGM[col-info]}[time-spec]${ZPLGM[col-rst]}     - show plugins that changed recently, argument is e.g. 1 month 2 days
clist|completions        - list completions in use
cdisable ${ZPLGM[col-info]}{cname}${ZPLGM[col-rst]}         - disable completion \`cname'
cenable  ${ZPLGM[col-info]}{cname}${ZPLGM[col-rst]}         - enable completion \`cname'
creinstall ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]} - install completions for plugin, can also receive absolute local path
cuninstall ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]} - uninstall completions for plugin
csearch                  - search for available completions from any plugin
compinit                 - refresh installed completions
dtrace|dstart            - start tracking what's going on in session
dstop                    - stop tracking what's going on in session
dunload                  - revert changes recorded between dstart and dstop
dreport                  - report what was going on in session
dclear                   - clear report of what was going on in session
compile  ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}   - compile plugin (or all plugins if --all passed)
uncompile ${ZPLGM[col-pname]}{plugin-name}${ZPLGM[col-rst]}  - remove compiled version of plugin (or of all plugins if --all passed)
compiled                 - list plugins that are compiled
cdlist                   - show compdef replay list
cdreplay [-q]            - replay compdefs (to be done after compinit), -q - quiet
cdclear [-q]             - clear compdef replay list, -q - quiet"
} # }}}
