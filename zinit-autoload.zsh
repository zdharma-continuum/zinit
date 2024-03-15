#!/usr/bin/env zsh
#
# zdharma-continuum/zinit/zinit-autoload.zsh
# Copyright (c) 2016-2021 Sebastian Gniazdowski
# Copyright (c) 2021-2023 zdharma-continuum
# Homepage: https://github.com/zdharma-continuum/zinit
# License: MIT License
#

builtin source "${ZINIT[BIN_DIR]}/zinit-side.zsh" || { builtin print -P "${ZINIT[col-error]}ERROR:%f%b Couldn't find ${ZINIT[col-obj]}zinit-side.zsh%f%b."; return 1; }

ZINIT[EXTENDED_GLOB]=""

#
# Backend, low level functions
#

# FUNCTION: .zinit-unregister-plugin [[[
# Removes the plugin from ZINIT_REGISTERED_PLUGINS array and from the
# zsh_loaded_plugins array (managed according to the plugin standard)
.zinit-unregister-plugin() {
    .zinit-any-to-user-plugin "$1" "$2"
    local uspl2="${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]}" \
        teleid="$3"

    # If not found, the index will be length+1
    ZINIT_REGISTERED_PLUGINS[${ZINIT_REGISTERED_PLUGINS[(i)$uspl2]}]=()
    # Support Zsh plugin standard
    zsh_loaded_plugins[${zsh_loaded_plugins[(i)$teleid]}]=()
    ZINIT[STATES__$uspl2]="0"
} # ]]]
# FUNCTION: .zinit-diff-functions-compute [[[
# Computes FUNCTIONS that holds new functions added by plugin.
# Uses data gathered earlier by .zinit-diff-functions().
#
# $1 - user/plugin
.zinit-diff-functions-compute() {
    local uspl2="$1"

    # Cannot run diff if *_BEFORE or *_AFTER variable is not set
    # Following is paranoid for *_BEFORE and *_AFTER being only spaces

    builtin setopt localoptions extendedglob nokshglob noksharrays
    [[ "${ZINIT[FUNCTIONS_BEFORE__$uspl2]}" != *[$'! \t']* || "${ZINIT[FUNCTIONS_AFTER__$uspl2]}" != *[$'! \t']* ]] && return 1

    typeset -A func
    local i

    # This includes new functions. Quoting is kept (i.e. no i=${(Q)i})
    for i in "${(z)ZINIT[FUNCTIONS_AFTER__$uspl2]}"; do
        func[$i]=1
    done

    # Remove duplicated entries, i.e. existing before. Quoting is kept
    for i in "${(z)ZINIT[FUNCTIONS_BEFORE__$uspl2]}"; do
        # if would do unset, then: func[opp+a\[]: invalid parameter name
        func[$i]=0
    done

    # Store the functions, associating them with plugin ($uspl2)
    ZINIT[FUNCTIONS__$uspl2]=""
    for i in "${(onk)func[@]}"; do
        [[ "${func[$i]}" = "1" ]] && ZINIT[FUNCTIONS__$uspl2]+="$i "
    done

    return 0
} # ]]]
# FUNCTION: .zinit-diff-options-compute [[[
# Computes OPTIONS that holds options changed by plugin.
# Uses data gathered earlier by .zinit-diff-options().
#
# $1 - user/plugin
.zinit-diff-options-compute() {
    local uspl2="$1"

    # Cannot run diff if *_BEFORE or *_AFTER variable is not set
    # Following is paranoid for *_BEFORE and *_AFTER being only spaces
    builtin setopt localoptions extendedglob nokshglob noksharrays
    [[ "${ZINIT[OPTIONS_BEFORE__$uspl2]}" != *[$'! \t']* || "${ZINIT[OPTIONS_AFTER__$uspl2]}" != *[$'! \t']* ]] && return 1

    typeset -A opts_before opts_after opts
    opts_before=( "${(z)ZINIT[OPTIONS_BEFORE__$uspl2]}" )
    opts_after=( "${(z)ZINIT[OPTIONS_AFTER__$uspl2]}" )
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
    local IFS=" "
    ZINIT[OPTIONS__$uspl2]="${(kv)opts[@]}"
    return 0
} # ]]]
# FUNCTION: .zinit-diff-env-compute [[[
# Computes ZINIT_PATH, ZINIT_FPATH that hold (f)path components
# added by plugin. Uses data gathered earlier by .zinit-diff-env().
#
# $1 - user/plugin
.zinit-diff-env-compute() {
    local uspl2="$1"
    typeset -a tmp

    # Cannot run diff if *_BEFORE or *_AFTER variable is not set
    # Following is paranoid for *_BEFORE and *_AFTER being only spaces
    builtin setopt localoptions extendedglob nokshglob noksharrays
    [[ "${ZINIT[PATH_BEFORE__$uspl2]}" != *[$'! \t']* || "${ZINIT[PATH_AFTER__$uspl2]}" != *[$'! \t']* ]] && return 1
    [[ "${ZINIT[FPATH_BEFORE__$uspl2]}" != *[$'! \t']* || "${ZINIT[FPATH_AFTER__$uspl2]}" != *[$'! \t']* ]] && return 1

    typeset -A path_state fpath_state
    local i

    #
    # PATH processing
    #

    # This includes new path elements
    for i in "${(z)ZINIT[PATH_AFTER__$uspl2]}"; do
        path_state[${(Q)i}]=1
    done

    # Remove duplicated entries, i.e. existing before
    for i in "${(z)ZINIT[PATH_BEFORE__$uspl2]}"; do
        unset "path_state[${(Q)i}]"
    done

    # Store the path elements, associating them with plugin ($uspl2)
    ZINIT[PATH__$uspl2]=""
    for i in "${(onk)path_state[@]}"; do
        ZINIT[PATH__$uspl2]+="${(q)i} "
    done

    #
    # FPATH processing
    #

    # This includes new path elements
    for i in "${(z)ZINIT[FPATH_AFTER__$uspl2]}"; do
        fpath_state[${(Q)i}]=1
    done

    # Remove duplicated entries, i.e. existing before
    for i in "${(z)ZINIT[FPATH_BEFORE__$uspl2]}"; do
        unset "fpath_state[${(Q)i}]"
    done

    # Store the path elements, associating them with plugin ($uspl2)
    ZINIT[FPATH__$uspl2]=""
    for i in "${(onk)fpath_state[@]}"; do
        ZINIT[FPATH__$uspl2]+="${(q)i} "
    done

    return 0
} # ]]]
# FUNCTION: .zinit-diff-parameter-compute [[[
# Computes ZINIT_PARAMETERS_PRE, ZINIT_PARAMETERS_POST that hold
# parameters created or changed (their type) by plugin. Uses
# data gathered earlier by .zinit-diff-parameter().
#
# $1 - user/plugin
.zinit-diff-parameter-compute() {
    local uspl2="$1"
    typeset -a tmp

    # Cannot run diff if *_BEFORE or *_AFTER variable is not set
    # Following is paranoid for *_BEFORE and *_AFTER being only spaces
    builtin setopt localoptions extendedglob nokshglob noksharrays
    [[ "${ZINIT[PARAMETERS_BEFORE__$uspl2]}" != *[$'! \t']* || "${ZINIT[PARAMETERS_AFTER__$uspl2]}" != *[$'! \t']* ]] && return 1

    # Un-concatenated parameters from moment of diff start and of diff end
    typeset -A params_before params_after
    params_before=( "${(z)ZINIT[PARAMETERS_BEFORE__$uspl2]}" )
    params_after=( "${(z)ZINIT[PARAMETERS_AFTER__$uspl2]}" )

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
        [[ "${params_after[$key]}" = *local* ]] && continue
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
    ZINIT[PARAMETERS_PRE__$uspl2]="${(j: :)${(qkv)params_pre[@]}}"
    ZINIT[PARAMETERS_POST__$uspl2]="${(j: :)${(qkv)params_post[@]}}"

    return 0
} # ]]]
# FUNCTION: .zinit-any-to-uspl2 [[[
# Converts given plugin-spec to format that's used in keys for hash tables.
# So basically, creates string "user/plugin" (this format is called: uspl2).
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - (optional) plugin (only when $1 - i.e. user - given)
.zinit-any-to-uspl2() {
    .zinit-any-to-user-plugin "$1" "$2"
    [[ "${reply[-2]}" = "%" ]] && REPLY="${reply[-2]}${reply[-1]}" || REPLY="${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]//---//}"
} # ]]]
# FUNCTION: .zinit-save-set-extendedglob [[[
# Enables extendedglob-option first saving if it was already
# enabled, for restoration of this state later.
.zinit-save-set-extendedglob() {
    [[ -o "extendedglob" ]] && ZINIT[EXTENDED_GLOB]="1" || ZINIT[EXTENDED_GLOB]="0"
    builtin setopt extendedglob
} # ]]]
# FUNCTION: .zinit-restore-extendedglob [[[
# Restores extendedglob-option from state saved earlier.
.zinit-restore-extendedglob() {
    [[ "${ZINIT[EXTENDED_GLOB]}" = "0" ]] && builtin unsetopt extendedglob || builtin setopt extendedglob
} # ]]]
# FUNCTION: .zinit-prepare-readlink [[[
# Prepares readlink command, used for establishing completion's owner.
#
# $REPLY = ":" or "readlink"
.zinit-prepare-readlink() {
    REPLY=":"
    if type readlink 2>/dev/null 1>&2; then
        REPLY="readlink"
    fi
} # ]]]
# FUNCTION: .zinit-clear-report-for [[[
# Clears all report data for given user/plugin. This is
# done by resetting all related global ZINIT_* hashes.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - (optional) plugin (only when $1 - i.e. user - given)
.zinit-clear-report-for() {
    .zinit-any-to-uspl2 "$1" "$2"

    # Shadowing
    ZINIT_REPORTS[$REPLY]=""
    ZINIT[BINDKEYS__$REPLY]=""
    ZINIT[ZSTYLES__$REPLY]=""
    ZINIT[ALIASES__$REPLY]=""
    ZINIT[WIDGETS_SAVED__$REPLY]=""
    ZINIT[WIDGETS_DELETE__$REPLY]=""

    # Function diffing
    ZINIT[FUNCTIONS__$REPLY]=""
    ZINIT[FUNCTIONS_BEFORE__$REPLY]=""
    ZINIT[FUNCTIONS_AFTER__$REPLY]=""

    # Option diffing
    ZINIT[OPTIONS__$REPLY]=""
    ZINIT[OPTIONS_BEFORE__$REPLY]=""
    ZINIT[OPTIONS_AFTER__$REPLY]=""

    # Environment diffing
    ZINIT[PATH__$REPLY]=""
    ZINIT[PATH_BEFORE__$REPLY]=""
    ZINIT[PATH_AFTER__$REPLY]=""
    ZINIT[FPATH__$REPLY]=""
    ZINIT[FPATH_BEFORE__$REPLY]=""
    ZINIT[FPATH_AFTER__$REPLY]=""

    # Parameter diffing
    ZINIT[PARAMETERS_PRE__$REPLY]=""
    ZINIT[PARAMETERS_POST__$REPLY]=""
    ZINIT[PARAMETERS_BEFORE__$REPLY]=""
    ZINIT[PARAMETERS_AFTER__$REPLY]=""
} # ]]]
# FUNCTION: .zinit-exists-message [[[
# Checks if plugin is loaded. Testable. Also outputs error
# message if plugin is not loaded.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - (optional) plugin (only when $1 - i.e. user - given)
.zinit-exists-message() {
    .zinit-any-to-uspl2 "$1" "$2"
    if [[ -z "${ZINIT_REGISTERED_PLUGINS[(r)$REPLY]}" ]]; then
        .zinit-any-colorify-as-uspl2 "$1" "$2"
        builtin print "${ZINIT[col-error]}No such plugin${ZINIT[col-rst]} $REPLY"
        return 1
    fi
    return 0
} # ]]]
# FUNCTION: .zinit-at-eval [[[
.zinit-at-eval() {
    local atclone="$2" atpull="$1"
    integer retval
    @zinit-substitute atclone atpull
    [[ $atpull = "%atclone" ]] && { eval "$atclone"; retval=$?; } || { eval "$atpull"; retval=$?; }
    return $retval
} # ]]]

#
# Format functions
#

# FUNCTION: .zinit-format-functions [[[
# Creates a one or two columns text with functions created
# by given plugin.
#
# $1 - user/plugin (i.e. uspl2 format of plugin-spec)
.zinit-format-functions() {
    local uspl2="$1"

    typeset -a func
    func=( "${(z)ZINIT[FUNCTIONS__$uspl2]}" )

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
} # ]]]
# FUNCTION: .zinit-format-options [[[
# Creates one-column text about options that changed when
# plugin "$1" was loaded.
#
# $1 - user/plugin (i.e. uspl2 format of plugin-spec)
.zinit-format-options() {
    local uspl2="$1"

    REPLY=""

    # Paranoid, don't want bad key/value pair error
    integer empty=0
    .zinit-save-set-extendedglob
    [[ "${ZINIT[OPTIONS__$uspl2]}" != *[$'! \t']* ]] && empty=1
    .zinit-restore-extendedglob
    (( empty )) && return 0

    typeset -A opts
    opts=( "${(z)ZINIT[OPTIONS__$uspl2]}" )

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
} # ]]]
# FUNCTION: .zinit-format-env [[[
# Creates one-column text about FPATH or PATH elements
# added when given plugin was loaded.
#
# $1 - user/plugin (i.e. uspl2 format of plugin-spec)
# $2 - if 1, then examine PATH, if 2, then examine FPATH
.zinit-format-env() {
    local uspl2="$1" which="$2"

    # Format PATH?
    if [[ "$which" = "1" ]]; then
        typeset -a elem
        elem=( "${(z@)ZINIT[PATH__$uspl2]}" )
    elif [[ "$which" = "2" ]]; then
        typeset -a elem
        elem=( "${(z@)ZINIT[FPATH__$uspl2]}" )
    fi

    # Enumerate elements added
    local answer="" e
    for e in "${elem[@]}"; do
        [[ -z "$e" ]] && continue
        e="${(Q)e}"
        answer+="$e"$'\n'
    done

    [[ -n "$answer" ]] && REPLY="$answer"
} # ]]]
# FUNCTION: .zinit-format-parameter [[[
# Creates one column text that lists global parameters that
# changed when the given plugin was loaded.
#
# $1 - user/plugin (i.e. uspl2 format of plugin-spec)
.zinit-format-parameter() {
    local uspl2="$1" infoc="${ZINIT[col-info]}" k

    builtin setopt localoptions extendedglob nokshglob noksharrays
    REPLY=""
    [[ "${ZINIT[PARAMETERS_PRE__$uspl2]}" != *[$'! \t']* || "${ZINIT[PARAMETERS_POST__$uspl2]}" != *[$'! \t']* ]] && return 0

    typeset -A elem_pre elem_post
    elem_pre=( "${(z)ZINIT[PARAMETERS_PRE__$uspl2]}" )
    elem_post=( "${(z)ZINIT[PARAMETERS_POST__$uspl2]}" )

    # Find longest key and longest value
    integer longest=0 vlongest1=0 vlongest2=0
    local v1 v2
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
    local answer="" k
    for k in "${(k)elem_post[@]}"; do
        v1="${(Q)elem_pre[$k]}"
        v2="${(Q)elem_post[$k]}"
        k="${(Q)k}"

        k="${(r:longest+1:: :)k}"
        v1="${(l:vlongest1+1:: :)v1}"
        v2="${(r:vlongest2+1:: :)v2}"
        answer+="$k ${infoc}[$v1 -> $v2]${ZINIT[col-rst]}"$'\n'
    done

    [[ -n "$answer" ]] && REPLY="$answer"

    return 0
} # ]]]

#
# Completion functions
#

# FUNCTION: .zinit-get-completion-owner [[[
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
.zinit-get-completion-owner() {
    setopt localoptions extendedglob nokshglob noksharrays noshwordsplit
    local cpath="$1"
    local readlink_cmd="$2"
    local in_plugin_path tmp

    # Try to go not too deep into resolving the symlink,
    # to have the name as it is in .zinit/plugins
    # :A goes deep, descends fully to origin directory
    # Readlink just reads what symlink points to
    in_plugin_path="${cpath:A}"
    tmp=$( "$readlink_cmd" "$cpath" )
    # This in effect works as: "if different, then readlink"
    [[ -n "$tmp" ]] && in_plugin_path="$tmp"

    if [[ "$in_plugin_path" != "$cpath" && -r "$in_plugin_path" ]]; then
        # Get the user---plugin part of path
        while [[ "$in_plugin_path" != ${ZINIT[PLUGINS_DIR]}/[^/]## && "$in_plugin_path" != "/" && "$in_plugin_path" != "." ]]; do
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
} # ]]]
# FUNCTION: .zinit-get-completion-owner-uspl2col [[[
# For shortening of code - returns colorized plugin name
# that owns given completion.
#
# $1 - absolute path to completion file (in COMPLETIONS_DIR)
# $2 - readlink command (":" or "readlink")
.zinit-get-completion-owner-uspl2col() {
    # "cpath" "readline_cmd"
    .zinit-get-completion-owner "$1" "$2"
    .zinit-any-colorify-as-uspl2 "$REPLY"
} # ]]]
# FUNCTION: .zinit-find-completions-of-plugin [[[
# Searches for completions owned by given plugin.
# Returns them in `reply' array.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-find-completions-of-plugin() {
    builtin setopt localoptions nullglob extendedglob nokshglob noksharrays
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" uspl
    [[ "$user" = "%" ]] && uspl="${user}${plugin}" || uspl="${reply[-2]}${reply[-2]:+---}${reply[-1]//\//---}"

    reply=( "${ZINIT[PLUGINS_DIR]}/$uspl"/**/_[^_.]*~*(*.zwc|*.html|*.txt|*.png|*.jpg|*.jpeg|*.js|*.md|*.yml|*.ri|_zsh_highlight*|/zsdoc/*|*.ps1)(DN) )
} # ]]]
# FUNCTION: .zinit-check-comp-consistency [[[
# Zinit creates symlink for each installed completion.
# This function checks whether given completion (i.e.
# file like "_mkdir") is indeed a symlink. Backup file
# is a completion that is disabled - has the leading "_"
# removed.
#
# $1 - path to completion within plugin's directory
# $2 - path to backup file within plugin's directory
.zinit-check-comp-consistency() {
    local cfile="$1" bkpfile="$2"
    integer error="$3"

    # bkpfile must be a symlink
    if [[ -e "$bkpfile" && ! -L "$bkpfile" ]]; then
        builtin print "${ZINIT[col-error]}Warning: completion's backup file \`${bkpfile:t}' isn't a symlink${ZINIT[col-rst]}"
        error=1
    fi

    # cfile must be a symlink
    if [[ -e "$cfile" && ! -L "$cfile" ]]; then
        builtin print "${ZINIT[col-error]}Warning: completion file \`${cfile:t}' isn't a symlink${ZINIT[col-rst]}"
        error=1
    fi

    # Tell user that he can manually modify but should do it right
    (( error )) && builtin print "${ZINIT[col-error]}Manual edit of ${ZINIT[COMPLETIONS_DIR]} occured?${ZINIT[col-rst]}"
} # ]]]
# FUNCTION: .zinit-check-which-completions-are-installed [[[
# For each argument that each should be a path to completion
# within a plugin's dir, it checks whether that completion
# is installed - returns 0 or 1 on corresponding positions
# in reply.
#
# $1, ... - path to completion within plugin's directory
.zinit-check-which-completions-are-installed() {
    local i cfile bkpfile
    reply=( )
    for i in "$@"; do
        cfile="${i:t}"
        bkpfile="${cfile#_}"

        if [[ -e "${ZINIT[COMPLETIONS_DIR]}"/"$cfile" || -e "${ZINIT[COMPLETIONS_DIR]}"/"$bkpfile" ]]; then
            reply+=( "1" )
        else
            reply+=( "0" )
        fi
    done
} # ]]]
# FUNCTION: .zinit-check-which-completions-are-enabled [[[
# For each argument that each should be a path to completion
# within a plugin's dir, it checks whether that completion
# is disabled - returns 0 or 1 on corresponding positions
# in reply.
#
# Uninstalled completions will be reported as "0"
# - i.e. disabled
#
# $1, ... - path to completion within plugin's directory
.zinit-check-which-completions-are-enabled() {
    local i cfile
    reply=( )
    for i in "$@"; do
        cfile="${i:t}"

        if [[ -e "${ZINIT[COMPLETIONS_DIR]}"/"$cfile" ]]; then
            reply+=( "1" )
        else
            reply+=( "0" )
        fi
    done
} # ]]]
# FUNCTION: .zinit-uninstall-completions [[[
# Removes all completions of given plugin from Zshell (i.e. from FPATH).
# The FPATH is typically `~/.zinit/completions/'.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-uninstall-completions() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    builtin setopt nullglob extendedglob warncreateglobal typesetsilent noshortloops

    typeset -a completions symlinked backup_comps
    local c cfile bkpfile
    integer action global_action=0

    .zinit-get-path "$1" "$2"
    [[ -e $REPLY ]] && {
        completions=( $REPLY/**/_[^_.]*~*(*.zwc|*.html|*.txt|*.png|*.jpg|*.jpeg|*.js|*.md|*.yml|*.ri|_zsh_highlight*|/zsdoc/*|*.ps1)(DN) )
    } || {
        builtin print "No completions found for \`$1${${1:#(%|/)*}:+${2:+/}}$2'"
        return 1
    }

    symlinked=( ${ZINIT[COMPLETIONS_DIR]}/_[^_.]*~*.zwc )
    backup_comps=( ${ZINIT[COMPLETIONS_DIR]}/[^_.]*~*.zwc )

    (( ${+functions[.zinit-forget-completion]} )) || builtin source ${ZINIT[BIN_DIR]}"/zinit-install.zsh"

    # Delete completions if they are really there, either
    # as completions (_fname) or backups (fname)
    for c in ${completions[@]}; do
        action=0
        cfile=${c:t}
        bkpfile=${cfile#_}

        # Remove symlink to completion
        if [[ -n ${symlinked[(r)*/$cfile]} ]]; then
            command rm -f ${ZINIT[COMPLETIONS_DIR]}/$cfile
            action=1
        fi

        # Remove backup symlink (created by cdisable)
        if [[ -n ${backup_comps[(r)*/$bkpfile]} ]]; then
            command rm -f ${ZINIT[COMPLETIONS_DIR]}/$bkpfile
            action=1
        fi

        if (( action )); then
            +zi-log "{info}Uninstalling completion \`{file}$cfile{info}'{…}{rst}"
            # Make compinit notice the change
            .zinit-forget-completion "$cfile"
            (( global_action ++ ))
        else
            +zi-log "{info}Completion \`{file}$cfile{info}' not installed.{rst}"
        fi
    done

    if (( global_action > 0 )); then
        +zi-log "{info}Uninstalled {num}$global_action{info} completions.{rst}"
    fi

    .zinit-compinit >/dev/null
} # ]]]

#
# User-exposed functions
#

# FUNCTION: .zinit-pager [[[
# BusyBox less lacks the -X and -i options, so it can use more
.zinit-pager() {
    setopt LOCAL_OPTIONS EQUALS
    # Quiet mode ? → no pager.
    if (( OPTS[opt_-n,--no-pager] )) {
        cat
        return 0
    }
    if [[ ${${:-=less}:A:t} = busybox* ]] {
        more 2>/dev/null
        (( ${+commands[more]} ))
    } else {
        less -FRXi 2>/dev/null
        (( ${+commands[less]} ))
    }
    (( $? )) && cat
    return 0
} # ]]]

# FUNCTION: .zinit-build-module [[[
# Performs ./configure && make on the module and displays information
# how to load the module in .zshrc.
.zinit-build-module() {
    setopt localoptions localtraps
    trap 'return 1' INT TERM
    if command git -C "${ZINIT[MODULE_DIR]}" rev-parse 2>/dev/null; then
        command git -C "${ZINIT[MODULE_DIR]}" clean -d -f -f
        command git -C "${ZINIT[MODULE_DIR]}" reset --hard HEAD
        command git -C "${ZINIT[MODULE_DIR]}" pull
    else
        command git clone "https://github.com/zdharma-continuum/zinit-module.git" "${ZINIT[MODULE_DIR]}" || {
            builtin print "${ZINIT[col-error]}Failed to clone module repo${ZINIT[col-rst]}"
            return 1
        }
    fi
    ( builtin cd -q "${ZINIT[MODULE_DIR]}"
      +zi-log "{pname}== Building module zdharma-continuum/zinit-module, running: make clean, then ./configure and then make =={rst}"
      +zi-log "{pname}== The module sources are located at: "${ZINIT[MODULE_DIR]}" =={rst}"
      if [[ -f Makefile ]] {
          if [[ "$1" = "--clean" ]] {
              noglob +zi-log {p}-- make distclean --{rst}
              make distclean
              ((1))
          } else {
              noglob +zi-log {p}-- make clean --{rst}
              make clean
          }
      }
      noglob +zi-log  {p}-- ./configure --{rst}
      CPPFLAGS=-I/usr/local/include CFLAGS="-g -Wall -O3" LDFLAGS=-L/usr/local/lib ./configure --disable-gdbm --without-tcsetpgrp && {
          noglob +zi-log {p}-- make --{rst}
          if { make } {
            [[ -f Src/zdharma_continuum/zinit.so ]] && cp -vf Src/zdharma_continuum/zinit.{so,bundle}
            noglob +zi-log "{info}Module has been built correctly.{rst}"
            .zinit-module info
          } else {
              noglob +zi-log  "{error}Module didn't build.{rst} "
              .zinit-module info --link
          }
      }
      builtin print $EPOCHSECONDS >! "${ZINIT[MAN_DIR]}/COMPILED_AT"
    )
} # ]]]
# FUNCTION: .zinit-module [[[
# Function that has sub-commands passed as long-options (with two dashes, --).
# It's an attempt to plugin only this one function into `zinit' function
# defined in zinit.zsh, to not make this file longer than it's needed.
.zinit-module() {
    if [[ "$1" = "build" ]]; then
        .zinit-build-module "${@[2,-1]}"
    elif [[ "$1" = "info" ]]; then
        if [[ "$2" = "--link" ]]; then
              builtin print -r "You can copy the error messages and submit"
              builtin print -r "error-report at: https://github.com/zdharma-continuum/zinit-module/issues"
        else
            builtin print -r "To load the module, add following 2 lines to .zshrc, at top:"
            builtin print -r "    module_path+=( \"${ZINIT[MODULE_DIR]}/Src\" )"
            builtin print -r "    zmodload zdharma_continuum/zinit"
            builtin print -r ""
            builtin print -r "After loading, use command \`zpmod' to communicate with the module."
            builtin print -r "See \`zpmod -h' for more information."
        fi
    elif [[ "$1" = (help|usage) ]]; then
        builtin print -r "Usage: zinit module {build|info|help} [options]"
        builtin print -r "       zinit module build [--clean]"
        builtin print -r "       zinit module info [--link]"
        builtin print -r ""
        builtin print -r "To start using the zinit Zsh module run: \`zinit module build'"
        builtin print -r "and follow the instructions. Option --clean causes \`make distclean'"
        builtin print -r "to be run. To display the instructions on loading the module, run:"
        builtin print -r "\`zinit module info'."
    fi
} # ]]]

# FUNCTION: .zinit-cd [[[
# Jumps to plugin's directory (in Zinit's home directory).
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-cd() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    builtin setopt extendedglob warncreateglobal typesetsilent rcquotes

    .zinit-get-path "$1" "$2" && {
        if [[ -e $REPLY ]]; then
            builtin pushd $REPLY
        else
            +zi-log "No such plugin or snippet"
            return 1
        fi
        builtin print
    } || {
        +zi-log "No such plugin or snippet"
        return 1
    }
} # ]]]
# FUNCTION: .zinit-cdisable [[[
# Enables given installed completion.
#
# User-action entry point.
#
# $1 - e.g. "_mkdir" or "mkdir"
.zinit-cdisable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZINIT[COMPLETIONS_DIR]}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        builtin print "${ZINIT[col-error]}No such completion \`$c'${ZINIT[col-rst]}"
        return 1
    fi

    # Check if it's already disabled
    # Not existing "$cfile" says that
    if [[ ! -e "$cfile" ]]; then
        builtin print "Completion ${ZINIT[col-info]}$c${ZINIT[col-rst]} already disabled"

        .zinit-check-comp-consistency "$cfile" "$bkpfile" 0
        return 1
    fi

    # No disable, but bkpfile exists?
    if [[ -e "$bkpfile" ]]; then
        builtin print "${ZINIT[col-error]}Warning: completion's backup file \`${bkpfile:t}' already exists, will overwrite${ZINIT[col-rst]}"
        .zinit-check-comp-consistency "$cfile" "$bkpfile" 1
        command rm -f "$bkpfile"
    else
        .zinit-check-comp-consistency "$cfile" "$bkpfile" 0
    fi

    # Disable
    command mv "$cfile" "$bkpfile"

    # Prepare readlink command for establishing completion's owner
    .zinit-prepare-readlink
    # Get completion's owning plugin
    .zinit-get-completion-owner-uspl2col "$bkpfile" "$REPLY"

    builtin print "Disabled ${ZINIT[col-info]}$c${ZINIT[col-rst]} completion belonging to $REPLY"

    return 0
} # ]]]
# FUNCTION: .zinit-cenable [[[
# Disables given installed completion.
#
# User-action entry point.
#
# $1 - e.g. "_mkdir" or "mkdir"
.zinit-cenable() {
    local c="$1"
    c="${c#_}"

    local cfile="${ZINIT[COMPLETIONS_DIR]}/_${c}"
    local bkpfile="${cfile:h}/$c"

    if [[ ! -e "$cfile" && ! -e "$bkpfile" ]]; then
        builtin print "${ZINIT[col-error]}No such completion \`$c'${ZINIT[col-rst]}"
        return 1
    fi

    # Check if there is no backup file
    # This is treated as if the completion is already enabled
    if [[ ! -e "$bkpfile" ]]; then
        builtin print "Completion ${ZINIT[col-info]}$c${ZINIT[col-rst]} already enabled"

        .zinit-check-comp-consistency "$cfile" "$bkpfile" 0
        return 1
    fi

    # Disabled, but completion file already exists?
    if [[ -e "$cfile" ]]; then
        builtin print "${ZINIT[col-error]}Warning: completion's file \`${cfile:t}' exists, will overwrite${ZINIT[col-rst]}"
        builtin print "${ZINIT[col-error]}Completion is actually enabled and will re-enable it again${ZINIT[col-rst]}"
        .zinit-check-comp-consistency "$cfile" "$bkpfile" 1
        command rm -f "$cfile"
    else
        .zinit-check-comp-consistency "$cfile" "$bkpfile" 0
    fi

    # Enable
    command mv "$bkpfile" "$cfile" # move completion's backup file created when disabling

    # Prepare readlink command for establishing completion's owner
    .zinit-prepare-readlink
    # Get completion's owning plugin
    .zinit-get-completion-owner-uspl2col "$cfile" "$REPLY"

    builtin print "Enabled ${ZINIT[col-info]}$c${ZINIT[col-rst]} completion belonging to $REPLY"

    return 0
} # ]]]
# FUNCTION: .zinit-changes [[[
# Shows `git log` of given plugin.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-changes() {
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    .zinit-exists-physically-message "$user" "$plugin" || return 1

    (
        builtin cd -q "${ZINIT[PLUGINS_DIR]}/${user:+${user}---}${plugin//\//---}" && \
        command git log -p --graph --decorate --date=relative -C -M
    )
} # ]]]
# FUNCTION: .zinit-clear-completions [[[
# Delete stray and improper completions.
#
# Completions live even when plugin isn't loaded - if they are
# installed and enabled.
#
# User-action entry point.
.zinit-clear-completions() {
    builtin setopt localoptions nullglob extendedglob nokshglob noksharrays

    typeset -a completions
    completions=( "${ZINIT[COMPLETIONS_DIR]}"/_[^_.]*~*.zwc "${ZINIT[COMPLETIONS_DIR]}"/[^_.]*~*.zwc )

    # Find longest completion name
    local cpath c
    integer longest=0
    for cpath in "${completions[@]}"; do
        c="${cpath:t}"
        c="${c#_}"
        [[ "${#c}" -gt "$longest" ]] && longest="${#c}"
    done

    .zinit-prepare-readlink
    local rdlink="$REPLY"

    integer disabled unknown stray
    for cpath in "${completions[@]}"; do
        c="${cpath:t}"
        [[ "${c#_}" = "${c}" ]] && disabled=1 || disabled=0
        c="${c#_}"

        # This will resolve completion's symlink to obtain
        # information about the repository it comes from, i.e.
        # about user and plugin, taken from directory name
        .zinit-get-completion-owner "$cpath" "$rdlink"
        [[ "$REPLY" = "[unknown]" ]] && unknown=1 || unknown=0
        .zinit-any-colorify-as-uspl2 "$REPLY"

        # If we successfully read a symlink (unknown == 0), test if it isn't broken
        stray=0
        if (( unknown == 0 )); then
            [[ ! -f "$cpath" ]] && stray=1
        fi

        if (( unknown == 1 || stray == 1 )); then
            builtin print -n "Removing completion: ${(r:longest+1:: :)c} $REPLY"
            (( disabled )) && builtin print -n " ${ZINIT[col-error]}[disabled]${ZINIT[col-rst]}"
            (( unknown )) && builtin print -n " ${ZINIT[col-error]}[unknown file]${ZINIT[col-rst]}"
            (( stray )) && builtin print -n " ${ZINIT[col-error]}[stray]${ZINIT[col-rst]}"
            builtin print
            command rm -f "$cpath"
        fi
    done
} # ]]]

# FUNCTION: .zinit-compile-plugin [[[
# Compiles given plugin (its main source file, and also an
# additional "....zsh" file if it exists).
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-compile-plugin () {
    emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent noshortloops rcquotes
    local id_as=$1${2:+${${${(M)1:#%}:+$2}:-/$2}} first plugin_dir filename is_snippet
    local -a list
    local -A ICE
    .zinit-compute-ice "$id_as" "pack" ICE plugin_dir filename is_snippet || return 1
    if [[ ${ICE[from]} = gh-r ]] && (( ${+ICE[compile]} == 0 )); then
        +zi-log "{dbg} $0: ${id_as} has from'gh-r', skip compile"
        return 0
    fi
    __compile_header () {
        (( $#quiet )) || +zi-log "{i} {b}${1}{rst}"
    }
    if [[ -n "${ICE[compile]}" ]]; then
        local -aU pats list=()
        pats=(${(s.;.)ICE[compile]})
        local pat
        __compile_header "${id_as}"
        for pat in $pats; do
            list+=("${plugin_dir:A}/"${~pat}(.N))
        done
        +zi-log "{dbg} $0: pattern {glob}${pats}{rst} found ${(pj;, ;)list[@]:t}"
        if [[ ${#list} -eq 0 ]]; then
            +zi-log "{w} {ice}compile{apo}''{rst} didn't match any files"
        else
            +zi-log -n "{m} Compiling {num}${#list}{rst} file${=${list:#1}:+s} ${(pj;, ;)list[@]:t}"
            integer retval
            for first in $list; do
                () {
                    builtin zcompile -Uz -- "${first}"
                    retval+=$?
                }
            done
            builtin print -rl -- ${list[@]#$plugin_dir/} >| ${TMPDIR:-/tmp}/zinit.compiled.$$.lst
            if (( !retval )); then
                +zi-log " [{happy}OK{rst}]"
            else
                +zi-log " (exit code: {ehi}$retval{rst})"
            fi
        fi
        return
    fi
    if [[ ${ICE[pick]} != /dev/null && ${ICE[as]} != null && ${+ICE[null]} -eq 0 && ${ICE[as]} != command && ${+ICE[binary]} -eq 0 && ( ${+ICE[nocompile]} = 0 || ${ICE[nocompile]} = \! ) ]]; then
        __compile_header "${id_as}"
        reply=()
        if [[ -n ${ICE[pick]} ]]; then
            list=(${~${(M)ICE[pick]:#/*}:-$plugin_dir/$ICE[pick]}(DN))
            if [[ ${#list} -eq 0 ]]; then
                +zi-log "{w} No files for compilation found (pick-ice didn't match)"
                return 1
            fi
            reply=("${list[1]:h}" "${list[1]}")
        else
            if (( is_snippet )); then
                if [[ -f $plugin_dir/$filename ]]; then
                    reply=("$plugin_dir" $plugin_dir/$filename)
                elif { ! .zinit-first % "$plugin_dir" }; then
                    +zi-log "{m} No files for compilation found"
                    return 1
                fi
            else
                .zinit-first "$1" "$2" || {
                    +zi-log "{m} No files for compilation found"
                    return 1
                }
            fi
        fi
        local pdir_path=${reply[-2]}
        first=${reply[-1]}
        local fname=${first#$pdir_path/}
        +zi-log -n "{m} Compiling {file}${fname}{rst}"
        if [[ -z ${ICE[(i)(\!|)(sh|bash|ksh|csh)]} ]]; then
            () {
                builtin emulate -LR zsh -o extendedglob ${=${options[xtrace]:#off}:+-o xtrace}
                if { ! zcompile -Uz "$first" }; then
                    +zi-log "{msg2}Warning:{rst} Compilation failed. Don't worry, the plugin will work also without compilation."
                    +zi-log "{msg2}Warning:{rst} Consider submitting an error report to Zinit or to the plugin's author."
                else
                    +zi-log " [{happy}OK{rst}]"
                fi
                zcompile -U "${${first%.plugin.zsh}%.zsh-theme}.zsh" 2> /dev/null
            }
        fi
    fi
    return 0
} # ]]]
# FUNCTION: .zinit-compile-uncompile-all [[[
# Compiles or uncompiles all existing (on disk) plugins.
#
# User-action entry point.
.zinit-compile-uncompile-all () {
    emulate -L zsh
    setopt extendedglob null_glob typeset_silent
    local compile="$1"
    +zi-log "{dbg} ${compile} all"
    condition () {
        if [[ -e "${REPLY:h}"/id-as ]]; then
            reply+=("$(cat "${REPLY:h}/id-as")")
        else
            reply+=("$(cat "${REPLY:A}")")
        fi
    }
    local -aU plugins=("$ZINIT_REGISTERED_PLUGINS[@]")
    plugins+=(${ZINIT[PLUGINS_DIR]}/*/\._zinit/teleid(on+condition))
    local p user plugin
    for p in "${plugins[@]}"; do
        [[ "${p:t}" = "custom" || "${p}" = "_local/zinit" ]] && continue
        .zinit-any-to-user-plugin "${p}"
        user="${reply[-2]}" plugin="${reply[-1]}"
        if [[ -n ${user} ]]; then
            .zinit-${compile}-plugin "$user" "$plugin"
        else
            .zinit-${compile}-plugin "$plugin"
        fi
    done
} # ]]]
# FUNCTION: .zinit-compiled [[[
# Displays list of plugins that are compiled.
#
# User-action entry point.
.zinit-compiled () {
    builtin setopt localoptions nullglob
    typeset -a matches m
    matches=(${ZINIT[PLUGINS_DIR]}/*/*.zwc(DN))
    if [[ "${#matches[@]}" -eq "0" ]]; then
        builtin print "No compiled plugins"
        return 0
    fi
    local cur_plugin="" uspl1 file user plugin
    for m in "${matches[@]}"; do
        file="${m:t}"
        uspl1="${${m:h}:t}"
        .zinit-any-to-user-plugin "$uspl1"
        user="${reply[-2]}" plugin="${reply[-1]}"
        if [[ "$cur_plugin" != "$uspl1" ]]; then
            [[ -n "$cur_plugin" ]] && builtin print
            .zinit-any-colorify-as-uspl2 "$user" "$plugin"
            builtin print -r -- "$REPLY:"
            cur_plugin="$uspl1"
        fi
        builtin print "$file"
    done
} # ]]]
# FUNCTION: .zinit-uncompile-plugin [[[
# Uncompiles given plugin.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user (+ plugin in $2), plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-uncompile-plugin () {
    emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extended_glob no_short_loops rc_quotes warn_create_global
    local id_as=$1${2:+${${${(M)1:#%}:+$2}:-/$2}} filename first is_snippet m plugin_dir
    local -a list
    local -A ICE
    .zinit-compute-ice "$id_as" "pack" ICE plugin_dir filename is_snippet || return 1
    if [[ ${ICE[from]} = gh-r ]] && (( ${+ICE[compile]} == 0 )); then
        +zi-log "{dbg} $0: ${id_as} has from'gh-r', skip compile"
        return 0
    fi
    if [[ -n ${plugin_dir}/*.zwc(#qN) ]]; then
        if (( $#quiet )); then
            +zi-log -n "{m} Uncompiling {b}${id_as}{rst}"
        else
            +zi-log "{i} {file}${id_as}{rst}"
        fi
        integer retval
        (( !$#quiet )) && +zi-log -n "{m} Removing: "
        for m in ${plugin_dir}/*.zwc(.N); do
            command rm -f "${m:A}"
            retval+=$?
            (( !$#quiet )) && +zi-log -n "{file}${m:t}{rst} "
        done
        if (( retval )); then
            +zi-log " [exit code: {ehi}$retval{rst}]"
        else
            +zi-log " [{happy}OK{rst}]"
        fi
    fi
} # ]]]

# FUNCTION: .zinit-confirm [[[
# Prints given question, waits for "y" key, evals
# given expression if "y" obtained
#
# $1 - question
# $2 - expression
.zinit-confirm() {
    integer retval
    if (( OPTS[opt_-y,--yes] )); then
        builtin eval "${2}"; retval=$?
        (( OPTS[opt_-q,--quiet] )) || +zi-log -lrP "{m} Action executed (exit code: {num}${retval}{rst})"
    else
      local choice prompt
      builtin print -D -v prompt "$(+zi-log '{i} Press [{opt}Y{rst}/{opt}y{rst}] to continue: {nl}')"
      +zi-log "${1}"
      if builtin read -qs "choice?${prompt}"; then
        builtin eval "${2}"; retval=$?
        +zi-log "{m} Action executed (exit code: {num}${retval}{rst})"
        return 0
      else
        +zi-log "{m} No action executed ('{opt}${choice}{rst}' not 'Y' or 'y')"
        return 1
      fi
    fi
} # ]]]
# FUNCTION: .zinit-create [[[
# Creates a plugin, also on Github (if not "_local/name" plugin).
#
# User-action entry point.
#
# $1 - (optional) plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - (optional) plugin (only when $1 - i.e. user - given)
.zinit-create() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt localoptions extendedglob noshortloops rcquotes typesetsilent warncreateglobal

    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    if (( ${+commands[curl]} == 0 || ${+commands[git]} == 0 )); then
        builtin print "${ZINIT[col-error]}curl and git are needed${ZINIT[col-rst]}"
        return 1
    fi

    # Read whether to create under organization
    local isorg
    vared -cp 'Create under an organization? (y/n): ' isorg

    if [[ $isorg = (y|yes) ]]; then
        local org="$user"
        vared -cp "Github organization name: " org
    fi

    # Read user
    local compcontext="user:User Name:(\"$USER\" \"$user\")"
    vared -cp "Github user name or just \"_local\" (or leave blank, for an userless plugin): " user

    # Read plugin
    unset compcontext
    vared -cp 'Plugin name: ' plugin

    if [[ "$plugin" = "_unknown" ]]; then
        builtin print "${ZINIT[col-error]}No plugin name entered${ZINIT[col-rst]}"
        return 1
    fi

    plugin="${plugin//[^a-zA-Z0-9_]##/-}"
    .zinit-any-colorify-as-uspl2 "${${${(M)isorg:#(y|yes)}:+$org}:-$user}" "$plugin"
    local uspl2col="$REPLY"
    builtin print "Plugin is $uspl2col"

    if .zinit-exists-physically "${${${(M)isorg:#(y|yes)}:+$org}:-$user}" "$plugin"; then
        builtin print "${ZINIT[col-error]}Repository${ZINIT[col-rst]} $uspl2col ${ZINIT[col-error]}already exists locally${ZINIT[col-rst]}"
        return 1
    fi

    builtin cd -q "${ZINIT[PLUGINS_DIR]}"

    if [[ "$user" != "_local" && -n "$user" ]]; then
        builtin print "${ZINIT[col-info]}Creating Github repository${ZINIT[col-rst]}"
        if [[ $isorg = (y|yes) ]]; then
            curl --silent -u "$user" https://api.github.com/orgs/$org/repos -d '{"name":"'"$plugin"'"}' >/dev/null
        else
            curl --silent -u "$user" https://api.github.com/user/repos -d '{"name":"'"$plugin"'"}' >/dev/null
        fi
        command git clone "https://github.com/${${${(M)isorg:#(y|yes)}:+$org}:-$user}/${plugin}.git" "${${${(M)isorg:#(y|yes)}:+$org}:-$user}---${plugin//\//---}" || {
            builtin print "${ZINIT[col-error]}Creation of remote repository $uspl2col ${ZINIT[col-error]}failed${ZINIT[col-rst]}"
            builtin print "${ZINIT[col-error]}Bad credentials?${ZINIT[col-rst]}"
            return 1
        }
        builtin cd -q "${${${(M)isorg:#(y|yes)}:+$org}:-$user}---${plugin//\//---}"
        command git config credential.https://github.com.username "${user}"
    else
        builtin print "${ZINIT[col-info]}Creating local git repository${${user:+.}:-, ${ZINIT[col-pname]}free-style, without the \"_local/\" part${ZINIT[col-info]}.}${ZINIT[col-rst]}"
        command mkdir "${user:+${user}---}${plugin//\//---}"
        builtin cd -q "${user:+${user}---}${plugin//\//---}"
        command git init || {
            builtin print "Git repository initialization failed, aborting"
            return 1
        }
    fi

    local user_name="$(command git config user.name 2>/dev/null)"
    local year="${$(command date "+%Y"):-2020}"

    command cat >! "${plugin:t}.plugin.zsh" <<EOF
# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-

# Copyright (c) $year $user_name

# According to the Zsh Plugin Standard:
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html

0=\${\${ZERO:-\${0:#\$ZSH_ARGZERO}}:-\${(%):-%N}}
0=\${\${(M)0:#/*}:-\$PWD/\$0}

# Then \${0:h} to get plugin's directory

if [[ \${zsh_loaded_plugins[-1]} != */${plugin:t} && -z \${fpath[(r)\${0:h}]} ]] {
    fpath+=( "\${0:h}" )
}

# Standard hash for plugins, to not pollute the namespace
typeset -gA Plugins
Plugins[${${(U)plugin:t}//-/_}_DIR]="\${0:h}"

autoload -Uz template-script

# Use alternate vim marks [[[ and ]]] as the original ones can
# confuse nested substitutions, e.g.: \${\${\${VAR}}}

# vim:ft=zsh:tw=80:sw=4:sts=4:et:foldmarker=[[[,]]]
EOF

    builtin print -r -- "# $plugin" >! "README.md"
    command cp -vf "${ZINIT[BIN_DIR]}/LICENSE" LICENSE
    command cp -vf "${ZINIT[BIN_DIR]}/share/template-plugin/zsh.gitignore" .gitignore
    command cp -vf "${ZINIT[BIN_DIR]}/share/template-plugin/template-script" .

    command sed -i -e "s/MY_PLUGIN_DIR/${${(U)plugin:t}//-/_}_DIR/g" template-script
    command sed -i -e "s/USER_NAME/$user_name/g" template-script
    command sed -i -e "s/YEAR/$year/g" template-script

    if [[ "$user" != "_local" && -n "$user" ]]; then
        builtin print "Your repository is ready\!"
        builtin print "An MIT LICENSE file has been placed - please review the " \
                      "license terms to see if they fit your new project:"
        builtin print "- https://choosealicense.com/"
        builtin print "Remote repository $uspl2col set up as origin."
        builtin print "You're in plugin's local folder, the files aren't added to git."
        builtin print "Your next step after commiting will be:"
        builtin print "git push -u origin master (or \`… -u origin main')"
    else
        builtin print "Created local $uspl2col plugin."
        builtin print "You're in plugin's repository folder, the files aren't added to git."
    fi
} # ]]]

# FUNCTION: .zinit-delete [[[
# Deletes a plugin or snippet and related files and hooks
#
# $1 - snippet url or plugin
.zinit-delete () {
    emulate -LR zsh
    setopt extended_glob no_ksh_arrays no_ksh_glob typeset_silent warn_create_global
    +zi-log "{dbg} $0: ${(qqS)@}"
    local o_all o_clean o_debug o_help o_quiet o_yes rc
    local -a usage=(
        'Usage:'
        '  zinit delete [options] [plugins...]'
        ' '
        'Options:'
        '  -a, --all      Delete all installed plugins, snippets, and completions'
        '  -c, --clean    Delete unloaded plugins and snippets'
        '  -d, --debug    Enable debug mode'
        '  -h, --help     Show list of command-line options'
        '  -q, --quiet    Make some output more quiet'
        '  -y, --yes      Don´t prompt for user confirmation'
    )
    zmodload zsh/zutil
    zparseopts -D -E -F -K -- \
        {a,-all}=o_all \
        {c,-clean}=o_clean \
        {d,-debug}=o_debug \
        {h,-help}=o_help \
        {q,-quiet}=o_quiet \
        {y,-yes}=o_yes \
    || return 1
    (( $#o_help )) && {
        print -l -- ${usage}
        return 0
    }
    (( $#o_debug )) && {
        setopt xtrace
    }
    (( $#o_clean && $#o_all )) && {
        +zi-log "{e} Invalid usage: Options --all and --clean are mutually exclusive"
        return 1
    }
    (( $#o_clean )) && {
        local -a unld_plgns
        local -aU ld_snips unld_snips del_list
        local snip plugin _retval dir=${${ZINIT[SNIPPETS_DIR]%%[/[:space:]]##}:-${TMPDIR:-${TMPDIR:-/tmp}}/xyzcba231}
        unld_snips=($dir/*/*/*(ND/) $dir/*/*(ND/) $dir/*(ND/))
        ld_snips=(${${ZINIT_SNIPPETS[@]% <*>}/(#m)*/$(.zinit-get-object-path snippet "$MATCH" && builtin print -rn -- $REPLY; )})
        del_list=(${unld_snips[@]:#*/(${(~j:|:)ld_snips}|*/plugins|._backup|._zinit|.svn|.git)(|/*)})
        del_list=(${del_list[@]//(#m)*/$( .zinit-get-object-path snippet "${${${MATCH##${dir}[/[:space:]]#}/(#i)(#b)(http(s|)|ftp(s|)|ssh|rsync)--/${match[1]##--}://}//--//}" && builtin print -r -- $REPLY)})
        del_list=(${del_list[@]:#(${(~j:|:)ld_snips}|*/plugins|*/._backup|*/._zinit|*/.svn|*/.git)(|/*)})
        unld_snips=(${${${(@)${(@)del_list##$dir/#}//(#i)(#m)(http(s|)|ftp(s|)|ssh|rsync)--/${MATCH%--}://}//--//}//(#b)(*)\/([^\/]##)(#e)/$match[1]/$ZINIT[col-file]$match[2]$ZINIT[col-rst]})
        unld_snips=(${unld_snips[@]//(#m)(#s)[^\/]##(#e)/$ZINIT[col-file]$MATCH$ZINIT[col-rst]})
        unld_snips+=($(builtin print -- "${ZINIT[HOME_DIR]}"/snippets/*(/N^F:t)))
        del_list=(${${${(@)${(@)del_list##$dir/#}//(#i)(#m)(http(s|)|ftp(s|)|ssh|rsync)--/${MATCH%--}://}//--//}//(#b)(*)\/([^\/]##)(#e)/$match[1]/$match[2]})
        unld_plgns=(${${ZINIT[PLUGINS_DIR]%%[/[:space:]]##}:-${TMPDIR:-${TMPDIR:-/tmp}}/abcEFG312}/*~*/(${(~j:|:)${ZINIT_REGISTERED_PLUGINS[@]//\//---}})(ND/))
        unld_plgns=(${(@)${unld_plgns[@]##$ZINIT[PLUGINS_DIR]/#}//---//})
        (( $#del_list || $#unld_plgns || $#unld_snips )) && {
            (( $#unld_snips )) && +zi-log "{m} Deleting {num}${#unld_snips}{rst} unloaded snippets:" $unld_snips
            (( $#unld_plgns )) && +zi-log "{m} Deleting {num}${#unld_plgns}{rst} unloaded plugins:" $unld_plgns
            if (( $#o_yes )) || ( .zinit-prompt "Delete ${#unld_snips} snippets and ${#unld_plgns} plugins?" ); then
                for snip in $del_list $unld_plgns $unld_snips; do
                    zinit delete --yes "$snip"
                    _retval+=$?
                done
                return _retval
            else
                return 0
            fi
        } || {
            +zi-log "{m} No unloaded plugins or snippets to delete"
            return 0
        }
    }
    local i
    if (( $#o_all && !$#o_clean )); then
        condition () {
            if [[ -e "${REPLY:h}"/id-as ]]; then
                reply+=("$(cat "${REPLY:h}/id-as")")
            else
                reply+=("$(cat "${REPLY:A}")")
            fi
        }
        local -a all_installed=("${ZINIT[HOME_DIR]}"/{'plugins','snippets'}/**/\._zinit/teleid(N+condition))
        if (( $#o_yes )) || ( .zinit-prompt "Delete all plugins and snippets ($#all_installed total)" ); then
            for i in ${all_installed[@]}; do
                zinit delete --yes "${i}"
            done
            rc=$?
            command rm -d -f -v "${ZINIT[HOME_DIR]}"/**/*(-@N) "${ZINIT[HOME_DIR]}"/{'plugins','snippets'}/*(N/^F)
            local f
            for f in ${(k)ZINIT[(I)STATES__*~*local/zinit]}; do
                builtin unset "ZINIT[${f}]"
            done
            +zi-log "{m} Delete completed with return code {num}${rc}{rst}"
            return $rc
        fi
        return 1
    fi
    (( !$# )) && {
        +zi-log "{e} Invalid usage: This command requires at least 1 plugin or snippet argument."
        return 0
    }
    if (( $#o_yes )) || ( .zinit-prompt "Delete ${(j:, :)@}" ); then
        for i in "${@}"; do
            local -A ICE=() ICE2=()
            local the_id="${${i:#(%|/)*}}" filename is_snippet local_dir
            .zinit-compute-ice "$the_id" "pack" ICE2 local_dir filename is_snippet || return 1
            if [[ "$local_dir" != /* ]]; then
                +zi-log "{w} No available plugin or snippet with the name '{b}$i{rst}'"
                return 1
            fi
            ICE2[teleid]="${ICE2[teleid]:-${ICE2[id-as]}}"
            local -a files
            files=("$local_dir"/*(%DN:t) "$local_dir"/*(*DN:t) "$local_dir"/*(.DN:t) "$local_dir"/*(=DN:t) "$local_dir"/*(@DN:t) "$local_dir"/*(pDN:t) "$local_dir"/*.(zsh|sh|bash|ksh)(DN:t) "$local_dir"/*~*/.(_zinit|svn|git)(/DN:t))
            (( !${#files} )) && files=("no files?")
            files=(${(@)files[1,4]} ${files[4]+more…})
            ICE=("${(kv)ICE2[@]}")
            if [[ -e $local_dir ]]; then
                (( is_snippet )) && {
                    .zinit-run-delete-hooks snippet "${ICE2[teleid]}" "" "$the_id" "$local_dir"
                } || {
                    .zinit-any-to-user-plugin "${ICE2[teleid]}"
                    .zinit-run-delete-hooks plugin "${reply[-2]}" "${reply[-1]}" "$the_id" "$local_dir"
                }
                command rm -d -f -r "${ZINIT[HOME_DIR]}"/**/*(-@N) "${ZINIT[HOME_DIR]}"/{'plugins','snippets'}/*(N/^F) ${(q)${${local_dir:#[/[:space:]]##}:-${TMPDIR:-${TMPDIR:-/tmp}}/abcYZX321}}(N)
                builtin unset "ZINIT[STATES__${i}]" || builtin unset "ZINIT[STATES__${ICE2[teleid]}]"
                (( $#o_quiet )) || +zi-log "{m} Uninstalled {b}$i{rst}"
            else
                +zi-log "{w} No available plugin or snippet with the name '{b}$i{rst}'"
                return 1
            fi
        done
    fi
    return 0
} # ]]]
# FUNCTION: .zinit-edit [[[
# Runs $EDITOR on source of given plugin. If the variable is not
# set then defaults to `vim'.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-edit() {
    local -A ICE2
    local local_dir filename is_snippet the_id="$1${${1:#(%|/)*}:+${2:+/}}$2"

    .zinit-compute-ice "$the_id" "pack" \
        ICE2 local_dir filename is_snippet || return 1

    ICE2[teleid]="${ICE2[teleid]:-${ICE2[id-as]}}"

    if (( is_snippet )); then
        if [[ ! -e "$local_dir" ]]; then
            builtin print "No such snippet"
            return 1
        fi
    else
        if [[ ! -e "$local_dir" ]]; then
            builtin print -r -- "No such plugin or snippet"
            return 1
        fi
    fi

    "${EDITOR:-vim}" "$local_dir"
    return 0
} # ]]]
# FUNCTION: .zinit-get-path [[[
# Returns path of given ID-string, which may be a plugin-spec
# (like "user/plugin" or "user" "plugin"), an absolute path
# ("%" "/home/..." and also "%SNIPPETS/..." etc.), or a plugin
# nickname (i.e. id-as'' ice-mod), or a snippet nickname.
.zinit-get-path() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent noshortloops

    [[ $1 == % ]] && local id_as=%$2 || local id_as=$1${1:+/}$2
    .zinit-get-object-path snippet "$id_as" || \
        .zinit-get-object-path plugin "$id_as"

    return $(( 1 - reply[3] ))
} # ]]]
# FUNCTION: .zinit-glance [[[
# Shows colorized source code of plugin. Is able to use pygmentize,
# highlight, GNU source-highlight.
#
# User-action entry point.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-glance() {
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    .zinit-exists-physically-message "$user" "$plugin" || return 1

    .zinit-first "$1" "$2" || {
       +zi-log '{log-err} No source file found, cannot glance'
        return 1
    }

    local fname="${reply[-1]}"

    integer has_256_colors=0
    [[ "$TERM" = xterm* || "$TERM" = "screen" ]] && has_256_colors=1

    {
        if (( ${+commands[pygmentize]} )); then
            +zi-log "{log-info} Inspecting via {cmd}pygmentize{rst}"
            pygmentize -l 'bash' "$fname"
        elif (( ${+commands[highlight]} )); then
            +zi-log "{log-info} Inspecting via {cmd}highlight{rst}"
            if (( has_256_colors )); then
                highlight --force --output-format xterm256 --quiet --syntax sh "$fname"
            else
                highlight --force --output-format ansi --quiet --syntax sh "$fname"
            fi
        elif (( ${+commands[source-highlight]} )); then
            +zi-log "{log-info} Inspecting via {cmd}source-highlight{rst}"
            source-highlight -fesc --failsafe -s zsh -o STDOUT -i "$fname"
        else
            cat "$fname"
        fi
    } | {
        if [[ -t 1 ]]; then
            .zinit-pager
        else
            cat
        fi
    }
} # ]]]
# FUNCTION: .zinit-help [[[
# Shows usage information.
#
# User-action entry point.
.zinit-help() {
           builtin print -r -- "${ZINIT[col-p]}Usage${ZINIT[col-rst]}:
—— help                          – usage information
—— bindkeys                      – lists bindkeys set up by each plugin
—— cd ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}                   – cd into plugin's directory; also support snippets, if feed with URL
—— cdclear [-q]                  – clear compdef replay list, -q – quiet
—— cdisable ${ZINIT[col-info]}cname${ZINIT[col-rst]}                – disable completion \`cname'
—— cdlist                        – show compdef replay list
—— cdreplay [-q]                 – replay compdefs (to be done after compinit), -q – quiet
—— cenable ${ZINIT[col-info]}cname${ZINIT[col-rst]}                 – enable completion \`cname'
—— changes ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}              – view plugin's git log
—— completions                   – list installed completions
—— compile ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}              – compile plugin (or all plugins if ——all passed)
—— compiled                      – list plugins that are compiled
—— compinit                      – refresh installed completions
—— create ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}               – create plugin (also together with Github repository)
—— creinstall ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}           – install completions for plugin, can also receive absolute local path; -q – quiet
—— csearch                       – search for available completions from any plugin
—— cuninstall ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}           – uninstall completions for plugin
—— debug                         – manage debug mode
—— delete                        – delete a plugin or snippet
—— edit ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}                 – edit plugin's file with \$EDITOR
—— env-whitelist [-v|-h] {env..} – allows to specify names (also patterns) of variables left unchanged during an unload. -v – verbose
—— glance ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}               – look at plugin's source (pygmentize, {,source-}highlight)
—— ice <ice specification>       – add ICE to next command, argument is e.g. from\"gitlab\"
—— light [-b] ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}           – light plugin load, without reporting/tracking (-b – do track but bindkey-calls only)
—— load ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}                 – load plugin, can also receive absolute local path
—— loaded|list {keyword}         – show what plugins are loaded (filter with \'keyword')
—— ls                            – list snippets in formatted and colorized manner
—— man                           – manual
—— module                        – manage binary Zsh module shipped with Zinit, see \`zinit module help'
—— recall ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}|URL           – fetch saved ice modifiers and construct \`zinit ice ...' command
—— recently ${ZINIT[col-info]}[time-spec]${ZINIT[col-rst]}          – show plugins that changed recently, argument is e.g. 1 month 2 days
—— report ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}               – show plugin's report (or all plugins' if ——all passed)
—— self-update                   – updates and compiles Zinit
—— snippet [-f] ${ZINIT[col-pname]}{url}${ZINIT[col-rst]}            – source local or remote file (by direct URL), -f: force – don't use cache
—— srv {service-id} [cmd]        – control a service, command can be: stop,start,restart,next,quit; \`next' moves the service to another Zshell
—— status ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}|URL           – Git status for plugin or svn status for snippet (or for all those if ——all passed)
—— stress ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}               – test plugin for compatibility with set of options
—— times [-s] [-m] [-a] – statistics on plugin load times, sorted in order of loading; -s – use seconds instead of milliseconds, -m – show plugin loading moments, -a – show both load times and loading moments
—— uncompile ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}            – remove compiled version of plugin (or of all plugins if ——all passed)
—— unload ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}               – unload plugin loaded with \`zinit load ...', -q – quiet
—— update [-q] ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]}|URL      – Git update plugin or snippet (or all plugins and snippets if ——all passed); besides -q accepts also ——quiet, and also -r/--reset – this option causes to run git reset --hard / svn revert before pulling changes
—— version                       – display zinit version
—— zstatus                       – overall Zinit statu
—— add-fpath|fpath ${ZINIT[col-info]}[-f|--front]${ZINIT[col-rst]} \\
    ${ZINIT[col-pname]}plg-spec ${ZINIT[col-info]}[subdirectory]${ZINIT[col-rst]}      – adds given plugin directory to \$fpath; if the second argument is given, it is appended to the directory path; if the option -f/--front is given, the directory path is prepended instead of appended to \$fpath. The ${ZINIT[col-pname]}plg-spec${ZINIT[col-rst]} can be absolute path
—— run [-l] [plugin] {command}   – runs the given command in the given plugin's directory; if the option -l will be given then the plugin should be skipped – the option will cause the previous plugin to be reused"

    integer idx
    local type key
    local -a arr
    for type in subcommand hook; do
        for (( idx=1; idx <= ZINIT_EXTS[seqno]; ++ idx )); do
            key="${(k)ZINIT_EXTS[(r)$idx *]}"
            [[ -z "$key" || "$key" != "z-annex $type:"* ]] && continue
            arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
            (( ${+functions[${arr[6]}]} )) && { "${arr[6]}"; ((1)); } || \
                { builtin print -rl -- "(Couldn't find the help-handler \`${arr[6]}' of the z-annex \`${arr[3]}')"; }
        done
    done

local -a ice_order
ice_order=( ${${(s.|.)ZINIT[ice-list]}:#teleid} ${(@)${(@)${(@Akons:|:u)${ZINIT_EXTS[ice-mods]//\'\'/}}/(#s)<->-/}:#(.*|dynamic-unscope)} )
print -- "\nAvailable ice-modifiers:\n\n${ice_order[*]}"
} # ]]]

# FUNCTION: .zinit-list-bindkeys [[[
.zinit-list-bindkeys() {
    local uspl2 uspl2col sw first=1
    local -a string_widget

    # KSH_ARRAYS immunity
    integer correct=0
    [[ -o "KSH_ARRAYS" ]] && correct=1

    for uspl2 in "${(@ko)ZINIT[(I)BINDKEYS__*]}"; do
        [[ -z "${ZINIT[$uspl2]}" ]] && continue

        (( !first )) && builtin print
        first=0

        uspl2="${uspl2#BINDKEYS__}"

        .zinit-any-colorify-as-uspl2 "$uspl2"
        uspl2col="$REPLY"
        builtin print "$uspl2col"

        string_widget=( "${(z@)ZINIT[BINDKEYS__$uspl2]}" )
        for sw in "${(Oa)string_widget[@]}"; do
            [[ -z "$sw" ]] && continue
            # Remove one level of quoting to split using (z)
            sw="${(Q)sw}"
            typeset -a sw_arr
            sw_arr=( "${(z@)sw}" )

            # Remove one level of quoting to pass to bindkey
            local sw_arr1="${(Q)sw_arr[1-correct]}" # Keys
            local sw_arr2="${(Q)sw_arr[2-correct]}" # Widget
            local sw_arr3="${(Q)sw_arr[3-correct]}" # Optional -M or -A or -N
            local sw_arr4="${(Q)sw_arr[4-correct]}" # Optional map name
            local sw_arr5="${(Q)sw_arr[5-correct]}" # Optional -R (not with -A, -N)

            if [[ "$sw_arr3" = "-M" && "$sw_arr5" != "-R" ]]; then
                builtin print "bindkey $sw_arr1 $sw_arr2 ${ZINIT[col-info]}for keymap $sw_arr4${ZINIT[col-rst]}"
            elif [[ "$sw_arr3" = "-M" && "$sw_arr5" = "-R" ]]; then
                builtin print "${ZINIT[col-info]}range${ZINIT[col-rst]} bindkey $sw_arr1 $sw_arr2 ${ZINIT[col-info]}mapped to $sw_arr4${ZINIT[col-rst]}"
            elif [[ "$sw_arr3" != "-M" && "$sw_arr5" = "-R" ]]; then
                builtin print "${ZINIT[col-info]}range${ZINIT[col-rst]} bindkey $sw_arr1 $sw_arr2"
            elif [[ "$sw_arr3" = "-A" ]]; then
                builtin print "Override of keymap \`main'"
            elif [[ "$sw_arr3" = "-N" ]]; then
                builtin print "New keymap \`$sw_arr4'"
            else
                builtin print "bindkey $sw_arr1 $sw_arr2"
            fi
        done
    done
} # ]]]
# FUNCTION: .zinit-list-compdef-replay [[[
# Shows recorded compdefs (called by plugins loaded earlier).
# Plugins often call `compdef' hoping for `compinit' being
# already ran. Zinit solves this by recording compdefs.
#
# User-action entry point.
.zinit-list-compdef-replay() {
    builtin print "Recorded compdefs:"
    local cdf
    for cdf in "${ZINIT_COMPDEF_REPLAY[@]}"; do
        builtin print "compdef ${(Q)cdf}"
    done
} # ]]]
# FUNCTION: .zinit-list-plugins [[[
# Lists loaded plugins
.zinit-list-plugins () {
    builtin emulate -LR zsh
    setopt extended_glob warn_create_global typeset_silent no_short_loops
    typeset -a filtered
    local keyword="${${${1}## ##}%% ##}"
    if [[ -n "$keyword" ]]; then
        +zi-log "{dbg} ${(qqq)1} -> ${(qqq)keyword}{rst}"
        filtered=(${${(k)ZINIT[(I)STATES__*${keyword}*~*(local/zinit)*]}//[A-Z]*__/})
        +zi-log "{m} ${#filtered} {b}Plugins{rst} matching '{glob}${keyword}{rst}'"
    else
        filtered=(${${(M)${(k)ZINIT[@]}:##STATES__*~*local/zinit*}//[A-Z]*__/})
        +zi-log "{m} ${#filtered} {b}Plugins{rst}"
    fi
    local i
    local -i idx=1
    for i in "${(o)filtered[@]}"; do
        local is_loaded='{error}U'
        (( ZINIT[STATES__${i}] )) && is_loaded="{happy}L"
        +zi-log "$(print -f "%2d %s %s\n" ${idx} ${is_loaded} {b}${(D)i//[%]/}{rst})"
        (( idx+=1 ))
    done
    +zi-log -- '{nl}Loaded: {happy}L{rst} | Unloaded: {error}U{rst}'
} # ]]]
# FUNCTION: .zinit-list-snippets [[[
.zinit-list-snippets() {
    (( ${+commands[tree]} )) || {
        builtin print "${ZINIT[col-error]}No \`tree' program, it is required by the subcommand \`ls\'${ZINIT[col-rst]}"
        builtin print "Download from: http://mama.indstate.edu/users/ice/tree/"
        builtin print "It is also available probably in all distributions and Homebrew, as package \`tree'"
    }
    (
        setopt localoptions extendedglob nokshglob noksharrays
        builtin cd -q "${ZINIT[SNIPPETS_DIR]}"
        local -a list
        local -x LANG=en_US.utf-8
        list=( "${(f@)"$(${=ZINIT[LIST_COMMAND]})"}" )
        # Oh-My-Zsh single file
        list=( "${list[@]//(#b)(https--github.com--(ohmyzsh|robbyrussel)l--oh-my-zsh--raw--master(--)(#c0,1)(*))/$ZINIT[col-info]Oh-My-Zsh$ZINIT[col-error]${match[2]/--//}$ZINIT[col-pname]${match[3]//--/$ZINIT[col-error]/$ZINIT[col-pname]} $ZINIT[col-info](single-file)$ZINIT[col-rst] ${match[1]}}" )
        # Oh-My-Zsh SVN
        list=( "${list[@]//(#b)(https--github.com--(ohmyzsh|robbyrussel)l--oh-my-zsh--trunk(--)(#c0,1)(*))/$ZINIT[col-info]Oh-My-Zsh$ZINIT[col-error]${match[2]/--//}$ZINIT[col-pname]${match[3]//--/$ZINIT[col-error]/$ZINIT[col-pname]} $ZINIT[col-info](SVN)$ZINIT[col-rst] ${match[1]}}" )
        # Prezto single file
        list=( "${list[@]//(#b)(https--github.com--sorin-ionescu--prezto--raw--master(--)(#c0,1)(*))/$ZINIT[col-info]Prezto$ZINIT[col-error]${match[2]/--//}$ZINIT[col-pname]${match[3]//--/$ZINIT[col-error]/$ZINIT[col-pname]} $ZINIT[col-info](single-file)$ZINIT[col-rst] ${match[1]}}" )
        # Prezto SVN
        list=( "${list[@]//(#b)(https--github.com--sorin-ionescu--prezto--trunk(--)(#c0,1)(*))/$ZINIT[col-info]Prezto$ZINIT[col-error]${match[2]/--//}$ZINIT[col-pname]${match[3]//--/$ZINIT[col-error]/$ZINIT[col-pname]} $ZINIT[col-info](SVN)$ZINIT[col-rst] ${match[1]}}" )

        # First-level names
        list=( "${list[@]//(#b)(#s)(│   └──|    └──|    ├──|│   ├──) (*)/${match[1]} $ZINIT[col-p]${match[2]}$ZINIT[col-rst]}" )

        list[-1]+=", located at ZINIT[SNIPPETS_DIR], i.e. ${ZINIT[SNIPPETS_DIR]}"
        builtin print -rl -- "${list[@]}"
    )
} # ]]]

# FUNCTION: .zinit-prompt [[[
# Prompt user to confirm
#
# $1 - prompt
#
# $REPLY - 0 or 1
.zinit-prompt () {
    local REPLY
    read -q ${(%):-"?%s%F{cyan}==>%f%s ${1}? [y/N]: "} && REPLY=y
    print ''
    [[ $REPLY == y ]] && return 0 || return 1
} # ]]]
# FUNCTION: .zinit-recall [[[
.zinit-recall() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent noshortloops

    local -A ice
    local el val cand1 cand2 local_dir filename is_snippet

    local -a ice_order nval_ices output
    ice_order=(
        ${(s.|.)ZINIT[ice-list]}

        # Include all additional ices – after
        # stripping them from the possible: ''
        ${(@)${(@Akons:|:u)${ZINIT_EXTS[ice-mods]//\'\'/}}/(#s)<->-/}
    )
    nval_ices=(
            ${(s.|.)ZINIT[nval-ice-list]}
            # Include only those additional ices,
            # don't have the '' in their name, i.e.
            # aren't designed to hold value
            ${(@)${(@)${(@Akons:|:u)ZINIT_EXTS[ice-mods]}:#*\'\'*}/(#s)<->-/}

            # Must be last
            svn
    )
    .zinit-compute-ice "$1${${1:#(%|/)*}:+${2:+/}}$2" "pack" \
        ice local_dir filename is_snippet || return 1

    [[ -e $local_dir ]] && {
        for el ( ${ice_order[@]} ) {
            val="${ice[$el]}"
            cand1="${(qqq)val}"
            cand2="${(qq)val}"
            if [[ -n "$val" ]] {
                [[ "${cand1/\\\$/}" != "$cand1" || "${cand1/\\\!/}" != "$cand1" ]] && output+=( "$el$cand2" ) || output+=( "$el$cand1" )
            } elif [[ ${+ice[$el]} = 1 && -n "${nval_ices[(r)$el]}" ]] {
                output+=( "$el" )
            }
        }

        if [[ ${#output} = 0 ]]; then
            builtin print -zr "# No Ice modifiers"
        else
            builtin print -zr "zinit ice ${output[*]}; zinit "
        fi
        +zinit-deploy-message @rst
    } || builtin print -r -- "No such plugin or snippet"
} # ]]]
# FUNCTION: .zinit-recently [[[
# Shows plugins that obtained commits in specified past time.
#
# User-action entry point.
#
# $1 - time spec, e.g. "1 week"
.zinit-recently() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    builtin setopt nullglob extendedglob warncreateglobal \
                typesetsilent noshortloops

    local IFS=.
    local gitout
    local timespec=${*// ##/.}
    timespec=${timespec//.##/.}
    [[ -z $timespec ]] && timespec=1.week

    typeset -a plugins
    plugins=( ${ZINIT[PLUGINS_DIR]}/*(DN-/) )

    local p uspl1
    for p in ${plugins[@]}; do
        uspl1=${p:t}
        [[ $uspl1 = custom || $uspl1 = _local---zinit ]] && continue

        pushd "$p" >/dev/null || continue
        if [[ -d .git ]]; then
            gitout=`command git log --all --max-count=1 --since=$timespec 2>/dev/null`
            if [[ -n $gitout ]]; then
                .zinit-any-colorify-as-uspl2 "$uspl1"
                builtin print -r -- "$REPLY"
            fi
        fi
        popd >/dev/null
    done
} # ]]]
# FUNCTION: .zinit-run-delete-hooks [[[
.zinit-run-delete-hooks () {
    local make_path=$5/Makefile mfest_path=$5/build/install_manifest.txt quiet='2>/dev/null 1>&2'
    if [[ -f $make_path ]] && grep '^uninstall' $make_path &> /dev/null; then
        +zi-log -n "{m} Make uninstall... "
        eval 'command make -C ${make_path:h} {prefix,{,CMAKE_INSTALL_}PREFIX}=$ZINIT[ZPFX] --ignore-errors uninstall' 2>/dev/null 1>&2
        if (( $? == 0 )); then
            +zi-log " [{happy}OK{rst}]"
        else
            +zi-log " [{error}Failed{rst}]"
        fi
    elif [[ -f $mfest_path ]]; then
        +zi-log -n "{m} Cmake uninstall... "
        if { command cmake --build ${mfest_path:h} --target uninstall || xargs rm -rf < "$mfest_path" } &>/dev/null ; then
            +zi-log " [{happy}OK{rst}]"
        else
            +zi-log " [{error}Failed{rst}]"
        fi
    fi
    eval 'find $ZINIT[ZPFX] -depth -type d -empty -delete' &> /dev/null
    if [[ -n ${ICE[atdelete]} ]]; then
        (
            (( ${+ICE[nocd]} == 0 )) && {
                builtin cd -q "$5" && eval "${ICE[atdelete]}"
                ((1))
            } || eval "${ICE[atdelete]}"
        )
    fi
    local -a arr
    local key
    reply=(${(on)ZINIT_EXTS2[(I)zinit hook:atdelete-pre <->]} ${(on)ZINIT_EXTS[(I)z-annex hook:atdelete-<-> <->]} ${(on)ZINIT_EXTS2[(I)zinit hook:atdelete-post <->]})
    for key in "${reply[@]}"; do
        arr=("${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}")
        "${arr[5]}" "$1" "$2" $3 "$4" "$5" "${${key##(zinit|z-annex) hook:}%% <->}" delete:TODO
    done
} # ]]]
# FUNCTION: .zinit-search-completions [[[
# While .zinit-show-completions() shows what completions are
# installed, this functions searches through all plugin dirs
# showing what's available in general (for installation).
#
# User-action entry point.
.zinit-search-completions() {
    builtin setopt localoptions nullglob extendedglob nokshglob noksharrays

    typeset -a plugin_paths
    plugin_paths=( "${ZINIT[PLUGINS_DIR]}"/*(DN) )

    # Find longest plugin name. Things are ran twice here, first pass
    # is to get longest name of plugin which is having any completions
    integer longest=0
    typeset -a completions
    local pp
    for pp in "${plugin_paths[@]}"; do
        completions=( "$pp"/**/_[^_.]*~*(*.zwc|*.html|*.txt|*.png|*.jpg|*.jpeg|*.js|*.md|*.yml|*.ri|_zsh_highlight*|/zsdoc/*|*.ps1|*.lua)(DN^/) )
        if [[ "${#completions[@]}" -gt 0 ]]; then
            local pd="${pp:t}"
            [[ "${#pd}" -gt "$longest" ]] && longest="${#pd}"
        fi
    done

    builtin print "${ZINIT[col-info]}[+]${ZINIT[col-rst]} is installed, ${ZINIT[col-p]}[-]${ZINIT[col-rst]} uninstalled, ${ZINIT[col-error]}[+-]${ZINIT[col-rst]} partially installed"

    local c
    for pp in "${plugin_paths[@]}"; do
        completions=( "$pp"/**/_[^_.]*~*(*.zwc|*.html|*.txt|*.png|*.jpg|*.jpeg|*.js|*.md|*.yml|*.ri|_zsh_highlight*|/zsdoc/*|*.ps1|*.lua)(DN^/) )

        if [[ "${#completions[@]}" -gt 0 ]]; then
            # Array of completions, e.g. ( _cp _xauth )
            completions=( "${completions[@]:t}" )

            # Detect if the completions are installed
            integer all_installed="${#completions[@]}"
            for c in "${completions[@]}"; do
                if [[ -e "${ZINIT[COMPLETIONS_DIR]}/$c" || -e "${ZINIT[COMPLETIONS_DIR]}/${c#_}" ]]; then
                    (( all_installed -- ))
                fi
            done

            if [[ "$all_installed" -eq "${#completions[@]}" ]]; then
                builtin print -n "${ZINIT[col-p]}[-]${ZINIT[col-rst]} "
            elif [[ "$all_installed" -eq "0" ]]; then
                builtin print -n "${ZINIT[col-info]}[+]${ZINIT[col-rst]} "
            else
                builtin print -n "${ZINIT[col-error]}[+-]${ZINIT[col-rst]} "
            fi

            # Convert directory name to colorified $user/$plugin
            .zinit-any-colorify-as-uspl2 "${pp:t}"

            # Adjust for escape code (nasty, utilizes fact that
            # ${ZINIT[col-rst]} is used twice, so as a $ZINIT_COL)
            integer adjust_ec=$(( ${#ZINIT[col-rst]} * 2 + ${#ZINIT[col-uname]} + ${#ZINIT[col-pname]} ))

            builtin print "${(r:longest+adjust_ec:: :)REPLY} ${(j:, :)completions}"
        fi
    done
} # ]]]

# FUNCTION: .zi-check-for-git-changes [[[
# Check for Git updates
#
# $1 - Absolute path to Git repository"
.zi-check-for-git-changes() {
    +zi-log "{dbg} checking $1"
    if command git --work-tree "$1" rev-parse --is-inside-work-tree &> /dev/null; then
        if command git --work-tree "$1" rev-parse --abbrev-ref @'{u}' &> /dev/null; then
            local count="$(command git --work-tree "$1" rev-list --left-right --count HEAD...@'{u}' 2> /dev/null)"
            local down="$count[(w)2]"
            if [[ $down -gt 0 ]]; then
                return 0
            fi
        fi
        builtin print -P -- "Already up-to-date."
        return 1
    fi
} # ]]]
# FUNCTION: .zinit-self-update [[[
# Updates Zinit code (does a git pull)
.zinit-self-update() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob typesetsilent warncreateglobal

    if .zi-check-for-git-changes "$ZINIT[BIN_DIR]"; then
        [[ $1 = -q ]] && +zi-log "{pre}[self-update]{info} updating zinit repository{msg2}" \

        local nl=$'\n' escape=$'\x1b['
        local current_branch=$(command git -C $ZINIT[BIN_DIR] rev-parse --abbrev-ref HEAD)
        # local current_branch='main'
        local -a lines
        (
            builtin cd -q "$ZINIT[BIN_DIR]" \
            && +zi-log -n "{pre}[self-update]{info} fetching latest changes from {obj}$current_branch{info} branch$nl{rst}" \
            && command git fetch --quiet \
            && lines=( ${(f)"$(command git log --color --date=short --pretty=format:'%Cgreen%cd %h %Creset%s %Cred%d%Creset || %b' ..origin/HEAD)"} )
            if (( ${#lines} > 0 )); then
                # Remove the (origin/main ...) segments, to expect only tags to appear
                lines=( "${(S)lines[@]//\(([,[:blank:]]#(origin|HEAD|master|main)[^a-zA-Z]##(HEAD|origin|master|main)[,[:blank:]]#)#\)/}" )
                # Remove " ||" if it ends the line (i.e. no additional text from the body)
                lines=( "${lines[@]/ \|\|[[:blank:]]#(#e)/}" )
                # If there's no ref-name, 2 consecutive spaces occur - fix this
                lines=( "${lines[@]/(#b)[[:space:]]#\|\|[[:space:]]#(*)(#e)/|| ${match[1]}}" )
                lines=( "${lines[@]/(#b)$escape([0-9]##)m[[:space:]]##${escape}m/$escape${match[1]}m${escape}m}" )
                # Replace what follows "|| ..." with the same thing but with no
                # newlines, and also only first 10 words (the (w)-flag enables
                # word-indexing)
                lines=( "${lines[@]/(#b)[[:blank:]]#\|\|(*)(#e)/| ${${match[1]//$nl/ }[(w)1,(w)10]}}" )
                builtin print -rl -- "${lines[@]}" | .zinit-pager
                builtin print
            fi
            if [[ $1 != -q ]] {
                command git pull --no-stat --ff-only origin main
            } else {
                command git pull --no-stat --quiet --ff-only origin main
            }
        )
        if [[ $1 != -q ]] {
            +zi-log "{pre}[self-update]{info} compiling zinit via {obj}zcompile{rst}"
        }
        command rm -f $ZINIT[BIN_DIR]/*.zwc(DN)
        zcompile -U $ZINIT[BIN_DIR]/zinit.zsh
        zcompile -U $ZINIT[BIN_DIR]/zinit-{'side','install','autoload','additional'}.zsh
        zcompile -U $ZINIT[BIN_DIR]/share/git-process-output.zsh
        # Load for the current session
        [[ $1 != -q ]] && +zi-log "{pre}[self-update]{info} reloading zinit for the current session{rst}"

        # +zi-log "{pre}[self-update]{info} resetting zinit repository via{rst}: {cmd}${ICE[reset]:-git reset --hard HEAD}{rst}"
        source $ZINIT[BIN_DIR]/zinit.zsh
        zcompile -U $ZINIT[BIN_DIR]/zinit-{'side','install','autoload'}.zsh
        # Read and remember the new modification timestamps
        local file
        for file ( "" -side -install -autoload ) {
            .zinit-get-mtime-into "${ZINIT[BIN_DIR]}/zinit$file.zsh" "ZINIT[mtime$file]"
        }
    fi
} # ]]]

# FUNCTION: .zinit-show-all-reports [[[
# Displays reports of all loaded plugins.
#
# User-action entry point.
.zinit-show-all-reports() {
    local i
    for i in "${ZINIT_REGISTERED_PLUGINS[@]}"; do
        [[ "$i" = "_local/zinit" ]] && continue
        .zinit-show-report "$i"
    done
} # ]]]
# FUNCTION: .zinit-show-completions [[[
# Display installed (enabled and disabled), completions. Detect
# stray and improper ones.
#
# Completions live even when plugin isn't loaded - if they are
# installed and enabled.
#
# User-action entry point.
.zinit-show-completions() {
    builtin setopt localoptions nullglob extendedglob nokshglob noksharrays
    local count="${1:-3}"

    typeset -a completions
    completions=( "${ZINIT[COMPLETIONS_DIR]}"/_[^_.]*~*.zwc "${ZINIT[COMPLETIONS_DIR]}"/[^_.]*~*.zwc )

    local cpath c o s group

    # Prepare readlink command for establishing
    # completion's owner
    .zinit-prepare-readlink
    local rdlink="$REPLY"

    float flmax=${#completions} flcur=0
    typeset -F1 flper

    local -A owner_to_group
    local -a packs splitted

    integer disabled unknown stray
    for cpath in "${completions[@]}"; do
        c="${cpath:t}"
        [[ "${c#_}" = "${c}" ]] && disabled=1 || disabled=0
        c="${c#_}"

        # This will resolve completion's symlink to obtain
        # information about the repository it comes from, i.e.
        # about user and plugin, taken from directory name
        .zinit-get-completion-owner "$cpath" "$rdlink"
        [[ "$REPLY" = "[unknown]" ]] && unknown=1 || unknown=0
        o="$REPLY"

        # If we successfully read a symlink (unknown == 0), test if it isn't broken
        stray=0
        if (( unknown == 0 )); then
            [[ ! -f "$cpath" ]] && stray=1
        fi

        s=$(( 1*disabled + 2*unknown + 4*stray ))

        owner_to_group[${o}--$s]+="$c;"
        group="${owner_to_group[${o}--$s]%;}"
        splitted=( "${(s:;:)group}" )

        if [[ "${#splitted}" -ge "$count" ]]; then
            packs+=( "${(q)group//;/, } ${(q)o} ${(q)s}" )
            unset "owner_to_group[${o}--$s]"
        fi

        (( ++ flcur ))
        flper=$(( flcur / flmax * 100 ))
        builtin print -u 2 -n -- "\r${flper}% "
    done

    for o in "${(k)owner_to_group[@]}"; do
        group="${owner_to_group[$o]%;}"
        s="${o##*--}"
        o="${o%--*}"
        packs+=( "${(q)group//;/, } ${(q)o} ${(q)s}" )
    done
    packs=( "${(on)packs[@]}" )

    builtin print -u 2 # newline after percent

    # Find longest completion name
    integer longest=0
    local -a unpacked
    for c in "${packs[@]}"; do
        unpacked=( "${(Q@)${(z@)c}}" )
        [[ "${#unpacked[1]}" -gt "$longest" ]] && longest="${#unpacked[1]}"
    done

    for c in "${packs[@]}"; do
        unpacked=( "${(Q@)${(z@)c}}" ) # TODO: ${(Q)${(z@)c}[@]} ?

        .zinit-any-colorify-as-uspl2 "$unpacked[2]"
        builtin print -n "${(r:longest+1:: :)unpacked[1]} $REPLY"

        (( unpacked[3] & 0x1 )) && builtin print -n " ${ZINIT[col-error]}[disabled]${ZINIT[col-rst]}"
        (( unpacked[3] & 0x2 )) && builtin print -n " ${ZINIT[col-error]}[unknown file, clean with cclear]${ZINIT[col-rst]}"
        (( unpacked[3] & 0x4 )) && builtin print -n " ${ZINIT[col-error]}[stray, clean with cclear]${ZINIT[col-rst]}"
        builtin print
    done
} # ]]]
# FUNCTION: .zinit-show-debug-report [[[
# Displays dtrace report (data recorded in interactive session).
#
# User-action entry point.
.zinit-show-debug-report() {
    .zinit-show-report "_dtrace/_dtrace"
} # ]]]
# FUNCTION: .zinit-show-report [[[
# Displays report of the plugin given.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user (+ plugin in $2), plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-show-report() {
    setopt localoptions extendedglob warncreateglobal typesetsilent noksharrays
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}" uspl2="${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]}"

    # Allow debug report
    if [[ "$user/$plugin" != "_dtrace/_dtrace" ]]; then
        .zinit-exists-message "$user" "$plugin" || return 1
    fi

    # Print title
    builtin printf "${ZINIT[col-title]}Report for${ZINIT[col-rst]} %s%s plugin\n"\
            "${user:+${ZINIT[col-uname]}$user${ZINIT[col-rst]}}${${user:#(%|/)*}:+/}"\
            "${ZINIT[col-pname]}$plugin${ZINIT[col-rst]}"

    # Print "----------"
    local msg="Report for $user${${user:#(%|/)*}:+/}$plugin plugin"
    builtin print -- "${ZINIT[col-bar]}${(r:${#msg}::-:)tmp__}${ZINIT[col-rst]}"

    local -A map
    map=(
        Error:  "${ZINIT[col-error]}"
        Warning:  "${ZINIT[col-error]}"
        Note:  "${ZINIT[col-note]}"
    )
    # Print report gathered via shadowing
    () {
        setopt localoptions extendedglob
        builtin print -rl -- "${(@)${(f@)ZINIT_REPORTS[$uspl2]}/(#b)(#s)([^[:space:]]##)([[:space:]]##)/${map[${match[1]}]:-${ZINIT[col-keyword]}}${match[1]}${ZINIT[col-rst]}${match[2]}}"
    }

    # Print report gathered via $functions-diffing
    REPLY=""
    .zinit-diff-functions-compute "$uspl2"
    .zinit-format-functions "$uspl2"
    [[ -n "$REPLY" ]] && builtin print "${ZINIT[col-p]}Functions created:${ZINIT[col-rst]}"$'\n'"$REPLY"

    # Print report gathered via $options-diffing
    REPLY=""
    .zinit-diff-options-compute "$uspl2"
    .zinit-format-options "$uspl2"
    [[ -n "$REPLY" ]] && builtin print "${ZINIT[col-p]}Options changed:${ZINIT[col-rst]}"$'\n'"$REPLY"

    # Print report gathered via environment diffing
    REPLY=""
    .zinit-diff-env-compute "$uspl2"
    .zinit-format-env "$uspl2" "1"
    [[ -n "$REPLY" ]] && builtin print "${ZINIT[col-p]}PATH elements added:${ZINIT[col-rst]}"$'\n'"$REPLY"

    REPLY=""
    .zinit-format-env "$uspl2" "2"
    [[ -n "$REPLY" ]] && builtin print "${ZINIT[col-p]}FPATH elements added:${ZINIT[col-rst]}"$'\n'"$REPLY"

    # Print report gathered via parameter diffing
    .zinit-diff-parameter-compute "$uspl2"
    .zinit-format-parameter "$uspl2"
    [[ -n "$REPLY" ]] && builtin print "${ZINIT[col-p]}Variables added or redefined:${ZINIT[col-rst]}"$'\n'"$REPLY"

    # Print what completions plugin has
    .zinit-find-completions-of-plugin "$user" "$plugin"
    typeset -a completions
    completions=( "${reply[@]}" )

    if [[ "${#completions[@]}" -ge "1" ]]; then
        builtin print "${ZINIT[col-p]}Completions:${ZINIT[col-rst]}"
        .zinit-check-which-completions-are-installed "${completions[@]}"
        typeset -a installed
        installed=( "${reply[@]}" )

        .zinit-check-which-completions-are-enabled "${completions[@]}"
        typeset -a enabled
        enabled=( "${reply[@]}" )

        integer count="${#completions[@]}" idx
        for (( idx=1; idx <= count; idx ++ )); do
            builtin print -n "${completions[idx]:t}"
            if [[ "${installed[idx]}" != "1" ]]; then
                builtin print -n " ${ZINIT[col-uninst]}[not installed]${ZINIT[col-rst]}"
            else
                if [[ "${enabled[idx]}" = "1" ]]; then
                    builtin print -n " ${ZINIT[col-info]}[enabled]${ZINIT[col-rst]}"
                else
                    builtin print -n " ${ZINIT[col-error]}[disabled]${ZINIT[col-rst]}"
                fi
            fi
            builtin print
        done
        builtin print
    fi
} # ]]]
# FUNCTION: .zinit-show-times [[[
# Shows loading times of all loaded plugins.
#
# User-action entry point.
.zinit-show-times() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt  extendedglob warncreateglobal noshortloops

    local opt="$1 $2 $3" entry entry2 entry3 user plugin
    float -F 3 sum=0.0
    local -A sice
    local -a tmp

    [[ "$opt" = *-[a-z]#m[a-z]#* ]] && \
        { builtin print "Plugin loading moments (relative to the first prompt):"; ((1)); } || \
        builtin print "Plugin loading times:"

    for entry in "${(@on)ZINIT[(I)TIME_[0-9]##_*]}"; do
        entry2="${entry#TIME_[0-9]##_}"
        entry3="AT_$entry"
        if [[ "$entry2" = (http|https|ftp|ftps|scp|${(~j.|.)${${(k)ZINIT_1MAP}%::}}):* ]]; then
            REPLY="${ZINIT[col-pname]}$entry2${ZINIT[col-rst]}"

            tmp=( "${(z@)ZINIT_SICE[${entry2%/}]}" )
            (( ${#tmp} > 1 && ${#tmp} % 2 == 0 )) && sice=( "${(Q)tmp[@]}" ) || sice=()
        else
            user="${entry2%%---*}"
            plugin="${entry2#*---}"
            [[ "$user" = \% ]] && plugin="/${plugin//---/\/}"
            [[ "$user" = "$plugin" && "$user/$plugin" != "$entry2" ]] && user=""
            .zinit-any-colorify-as-uspl2 "$user" "$plugin"

            tmp=( "${(z@)ZINIT_SICE[$user/$plugin]}" )
            (( ${#tmp} > 1 && ${#tmp} % 2 == 0 )) && sice=( "${(Q)tmp[@]}" ) || sice=()
        fi

        local attime=$(( ZINIT[$entry3] - ZINIT[START_TIME] ))
        if [[ "$opt" = *-[a-z]#s[a-z]#* ]]; then
            local time="$ZINIT[$entry] sec"
            attime="${(M)attime#*.???} sec"
        else
            local time="${(l:5:: :)$(( ZINIT[$entry] * 1000 ))%%[,.]*} ms"
            attime="${(l:5:: :)$(( attime * 1000 ))%%[,.]*} ms"
        fi
        [[ -z $EPOCHREALTIME ]] && attime="<no zsh/datetime module → no time data>"

        local line="$time"
        if [[ "$opt" = *-[a-z]#m[a-z]#* ]]; then
            line="$attime"
        elif [[ "$opt" = *-[a-z]#a[a-z]#* ]]; then
            line="$attime $line"
        fi

        line="$line - $REPLY"

        if [[ ${sice[as]} == "command" ]]; then
            line="$line (command)"
        elif [[ -n ${sice[sbin]+abc} ]]; then
            line="$line (sbin command)"
        elif [[ -n ${sice[fbin]+abc} ]]; then
            line="$line (fbin command)"
        elif [[ ( ${sice[pick]} = /dev/null || ${sice[as]} = null ) && ${+sice[make]} = 1 ]]; then
            line="$line (/dev/null make plugin)"
        fi

        builtin print "$line"

        (( sum += ZINIT[$entry] ))
    done
    builtin print "Total: $sum sec"
} # ]]]
# FUNCTION: .zinit-show-zstatus [[[
# Shows Zinit status, i.e. number of loaded plugins,
# of available completions, etc.
#
# User-action entry point.
.zinit-show-zstatus() {
    builtin setopt localoptions nullglob extendedglob nokshglob noksharrays

    local infoc="${ZINIT[col-info2]}"

    +zi-log "Zinit's main directory: {file}${ZINIT[HOME_DIR]}{rst}"
    +zi-log "Zinit's binary directory: {file}${ZINIT[BIN_DIR]}{rst}"
    +zi-log "Plugin directory: {file}${ZINIT[PLUGINS_DIR]}{rst}"
    +zi-log "Completions directory: {file}${ZINIT[COMPLETIONS_DIR]}{rst}"

    # Without _zlocal/zinit
    +zi-log "Loaded plugins: {num}$(( ${#ZINIT_REGISTERED_PLUGINS[@]} - 1 )){rst}"

    # Count light-loaded plugins
    integer light=0
    local s
    for s in "${(@v)ZINIT[(I)STATES__*]}"; do
        [[ "$s" = 1 ]] && (( light ++ ))
    done
    # Without _zlocal/zinit
    +zi-log "Light loaded: {num}$(( light - 1 )){rst}"

    # Downloaded plugins, without _zlocal/zinit, custom
    typeset -a plugins
    plugins=( "${ZINIT[PLUGINS_DIR]}"/*(DN) )
    +zi-log "Downloaded plugins: {num}$(( ${#plugins} - 1 )){rst}"

    # Number of enabled completions, with _zlocal/zinit
    typeset -a completions
    completions=( "${ZINIT[COMPLETIONS_DIR]}"/_[^_.]*~*.zwc(DN) )
    +zi-log "Enabled completions: {num}${#completions[@]}{rst}"

    # Number of disabled completions, with _zlocal/zinit
    completions=( "${ZINIT[COMPLETIONS_DIR]}"/[^_.]*~*.zwc(DN) )
    +zi-log "Disabled completions: {num}${#completions[@]}{rst}"

    # Number of completions existing in all plugins
    completions=( "${ZINIT[PLUGINS_DIR]}"/*/**/_[^_.]*~*(*.zwc|*.html|*.txt|*.png|*.jpg|*.jpeg|*.js|*.md|*.yml|*.ri|_zsh_highlight*|/zsdoc/*|*.ps1)(DN) )
    +zi-log "Completions available overall: {num}${#completions[@]}{rst}"

    # Enumerate snippets loaded
    # }, ${infoc}{rst}", j:, :, {msg}"$'\e[0m, +zi-log h
    +zi-log -n "Snippets loaded: "
    local sni
    for sni in ${(onv)ZINIT_SNIPPETS[@]}; do
        +zi-log -n "{url}${sni% <[^>]#>}{rst} ${(M)sni%<[^>]##>}, "
    done
    [[ -z $sni ]] && builtin print -n " "
    builtin print '\b\b  '

    # Number of compiled plugins
    typeset -a matches m
    integer count=0
    matches=( ${ZINIT[PLUGINS_DIR]}/*/*.zwc(DN) )

    local cur_plugin="" uspl1
    for m in "${matches[@]}"; do
        uspl1="${${m:h}:t}"

        if [[ "$cur_plugin" != "$uspl1" ]]; then
            (( count ++ ))
            cur_plugin="$uspl1"
        fi
    done

    +zi-log "Compiled plugins: {num}$count{rst}"
} # ]]]

# FUNCTION: .zinit-stress [[[
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
.zinit-stress() {
    .zinit-any-to-user-plugin "$1" "$2"
    local user="${reply[-2]}" plugin="${reply[-1]}"

    .zinit-exists-physically-message "$user" "$plugin" || return 1

    .zinit-first "$1" "$2" || {
        builtin print "${ZINIT[col-error]}No source file found, cannot stress${ZINIT[col-rst]}"
        return 1
    }

    local pdir_path="${reply[-2]}" fname="${reply[-1]}"

    integer compiled=1
    [[ -e "${fname}.zwc" ]] && command rm -f "${fname}.zwc" || compiled=0

    local -a ZINIT_STRESS_TEST_OPTIONS
    ZINIT_STRESS_TEST_OPTIONS=(
        "NO_SHORT_LOOPS" "IGNORE_BRACES" "IGNORE_CLOSE_BRACES"
        "SH_GLOB" "CSH_JUNKIE_QUOTES" "NO_MULTI_FUNC_DEF"
    )

    (
        builtin emulate -LR ksh ${=${options[xtrace]:#off}:+-o xtrace}
        builtin unsetopt shglob kshglob
        for i in "${ZINIT_STRESS_TEST_OPTIONS[@]}"; do
            builtin setopt "$i"
            builtin print -n "Stress-testing ${fname:t} for option $i "
            zcompile -UR "$fname" 2>/dev/null && {
                builtin print "[${ZINIT[col-success]}Success${ZINIT[col-rst]}]"
            } || {
                builtin print "[${ZINIT[col-failure]}Fail${ZINIT[col-rst]}]"
            }
            builtin unsetopt "$i"
        done
    )

    command rm -f "${fname}.zwc"
    (( compiled )) && zcompile -U "$fname"
} # ]]]

# FUNCTION: .zinit-unload [[[
# 1. call the zsh plugin's standard *_plugin_unload function
# 2. call the code provided by the zsh plugin's standard @zsh-plugin-run-at-update
# 3. delete bindkeys (...)
# 4. delete zstyles
# 5. restore options
# 6. remove aliases
# 7. restore zle state
# 8. unfunction functions (created by plugin)
# 9. clean-up fpath and path
# 10. delete created variables
# 11. forget the plugin
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
.zinit-unload() {
    .zinit-any-to-user-plugin "$1" "$2"
    local uspl2="${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]}" user="${reply[-2]}" plugin="${reply[-1]}" quiet="${${3:+1}:-0}"
    local k

    .zinit-any-colorify-as-uspl2 "$uspl2"
    (( quiet )) || +zi-log "{i} Unloading $REPLY"

    local ___dir
    [[ "$user" = "%" ]] && ___dir="$plugin" || ___dir="${ZINIT[PLUGINS_DIR]}/${user:+${user}---}${plugin//\//---}"

    # KSH_ARRAYS immunity
    integer correct=0
    [[ -o "KSH_ARRAYS" ]] && correct=1

    # Allow unload for debug user
    if [[ "$uspl2" != "_dtrace/_dtrace" ]]; then
        .zinit-exists-message "$1" "$2" || return 1
    fi

    .zinit-any-colorify-as-uspl2 "$1" "$2"
    local uspl2col="$REPLY"

    # Store report of the plugin in variable LASTREPORT
    typeset -g LASTREPORT
    LASTREPORT=`.zinit-show-report "$1" "$2"`

    # Call the Zsh Plugin's Standard *_plugin_unload function
    (( ${+functions[${plugin}_plugin_unload]} )) && ${plugin}_plugin_unload

    # Call the code provided by the Zsh Plugin's Standard @zsh-plugin-run-at-update
    local -a tmp
    local -A sice
    tmp=( "${(z@)ZINIT_SICE[$uspl2]}" )
    (( ${#tmp} > 1 && ${#tmp} % 2 == 0 )) && sice=( "${(Q)tmp[@]}" ) || sice=()

    if [[ -n ${sice[ps-on-unload]} ]]; then
        (( quiet )) || builtin print -r "Running plugin's provided unload code: ${ZINIT[col-info]}${sice[ps-on-unload][1,50]}${sice[ps-on-unload][51]:+…}${ZINIT[col-rst]}"
        local ___oldcd="$PWD"
        () { setopt localoptions noautopushd; builtin cd -q "$___dir"; }
        eval "${sice[ps-on-unload]}"
        () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }
    fi

    # 1. Delete done bindkeys
    typeset -a string_widget
    string_widget=( "${(z)ZINIT[BINDKEYS__$uspl2]}" )
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
        local sw_arr3="${(Q)sw_arr[3-correct]}" # Optional previous-bound widget
        local sw_arr4="${(Q)sw_arr[4-correct]}" # Optional -M or -A or -N
        local sw_arr5="${(Q)sw_arr[5-correct]}" # Optional map name
        local sw_arr6="${(Q)sw_arr[6-correct]}" # Optional -R (not with -A, -N)

        if [[ "$sw_arr4" = "-M" && "$sw_arr6" != "-R" ]]; then
            if [[ -n "$sw_arr3" ]]; then
                () {
                    builtin emulate -LR zsh -o extendedglob ${=${options[xtrace]:#off}:+-o xtrace}
                    (( quiet )) || builtin print -r "Restoring bindkey ${${(q)sw_arr1}//(#m)\\[\^\?\]\[\)\(\'\"\}\{\`]/${MATCH#\\}} $sw_arr3 ${ZINIT[col-info]}in map ${ZINIT[col-rst]}$sw_arr5"
                }
                bindkey -M "$sw_arr5" "$sw_arr1" "$sw_arr3"
            else
                (( quiet )) || builtin print -r "Deleting bindkey ${(q)sw_arr1} $sw_arr2 ${ZINIT[col-info]}in map ${ZINIT[col-rst]}$sw_arr5"
                bindkey -M "$sw_arr5" -r "$sw_arr1"
            fi
        elif [[ "$sw_arr4" = "-M" && "$sw_arr6" = "-R" ]]; then
            if [[ -n "$sw_arr3" ]]; then
                (( quiet )) || builtin print -r "Restoring ${ZINIT[col-info]}range${ZINIT[col-rst]} bindkey ${(q)sw_arr1} $sw_arr3 ${ZINIT[col-info]}in map ${ZINIT[col-rst]}$sw_arr5"
                bindkey -RM "$sw_arr5" "$sw_arr1" "$sw_arr3"
            else
                (( quiet )) || builtin print -r "Deleting ${ZINIT[col-info]}range${ZINIT[col-rst]} bindkey ${(q)sw_arr1} $sw_arr2 ${ZINIT[col-info]}in map ${ZINIT[col-rst]}$sw_arr5"
                bindkey -M "$sw_arr5" -Rr "$sw_arr1"
            fi
        elif [[ "$sw_arr4" != "-M" && "$sw_arr6" = "-R" ]]; then
            if [[ -n "$sw_arr3" ]]; then
                (( quiet )) || builtin print -r "Restoring ${ZINIT[col-info]}range${ZINIT[col-rst]} bindkey ${(q)sw_arr1} $sw_arr3"
                bindkey -R "$sw_arr1" "$sw_arr3"
            else
                (( quiet )) || builtin print -r "Deleting ${ZINIT[col-info]}range${ZINIT[col-rst]} bindkey ${(q)sw_arr1} $sw_arr2"
                bindkey -Rr "$sw_arr1"
            fi
        elif [[ "$sw_arr4" = "-A" ]]; then
            (( quiet )) || builtin print -r "Linking backup-\`main' keymap \`$sw_arr5' back to \`main'"
            bindkey -A "$sw_arr5" "main"
        elif [[ "$sw_arr4" = "-N" ]]; then
            (( quiet )) || builtin print -r "Deleting keymap \`$sw_arr5'"
            bindkey -D "$sw_arr5"
        else
            if [[ -n "$sw_arr3" ]]; then
                () {
                    builtin emulate -LR zsh -o extendedglob ${=${options[xtrace]:#off}:+-o xtrace}
                    (( quiet )) || builtin print -r "Restoring bindkey ${${(q)sw_arr1}//(#m)\\[\^\?\]\[\)\(\'\"\}\{\`]/${MATCH#\\}} $sw_arr3"
                }
                bindkey "$sw_arr1" "$sw_arr3"
            else
                (( quiet )) || builtin print -r "Deleting bindkey ${(q)sw_arr1} $sw_arr2"
                bindkey -r "$sw_arr1"
            fi
        fi
    done

    # 2. Delete created Zstyles

    typeset -a pattern_style
    pattern_style=( "${(z)ZINIT[ZSTYLES__$uspl2]}" )
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

        (( quiet )) || builtin print "Deleting zstyle $ps_arr1 $ps_arr2"

        zstyle -d "$ps_arr1" "$ps_arr2"
    done

    # 3. Restore changed options
    # paranoid, don't want bad key/value pair error
    .zinit-diff-options-compute "$uspl2"
    integer empty=0
    .zinit-save-set-extendedglob
    [[ "${ZINIT[OPTIONS__$uspl2]}" != *[$'! \t']* ]] && empty=1
    .zinit-restore-extendedglob

    if (( empty != 1 )); then
        typeset -A opts
        opts=( "${(z)ZINIT[OPTIONS__$uspl2]}" )
        for k in "${(kon)opts[@]}"; do
            # Internal options
            [[ "$k" = "physical" ]] && continue

            if [[ "${opts[$k]}" = "on" ]]; then
                (( quiet )) || builtin print "Setting option $k"
                builtin setopt "$k"
            else
                (( quiet )) || builtin print "Unsetting option $k"
                builtin unsetopt "$k"
            fi
        done
    fi

    # 4. Delete aliases
    typeset -a aname_avalue
    aname_avalue=( "${(z)ZINIT[ALIASES__$uspl2]}" )
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
            if [[ -n "$nv_arr2" ]]; then
                (( quiet )) || builtin print "Restoring ${ZINIT[col-info]}suffix${ZINIT[col-rst]} alias ${nv_arr1}=${nv_arr2}"
                alias "$nv_arr1" &> /dev/null && unalias -s -- "$nv_arr1"
                alias -s -- "${nv_arr1}=${nv_arr2}"
            else
                (( quiet )) || alias "$nv_arr1" &> /dev/null && {
                    builtin print "Removing ${ZINIT[col-info]}suffix${ZINIT[col-rst]} alias ${nv_arr1}"
                    unalias -s -- "$nv_arr1"
                }
            fi
        elif [[ "$nv_arr3" = "-g" ]]; then
            if [[ -n "$nv_arr2" ]]; then
                (( quiet )) || builtin print "Restoring ${ZINIT[col-info]}global${ZINIT[col-rst]} alias ${nv_arr1}=${nv_arr2}"
                alias "$nv_arr1" &> /dev/null && unalias -g -- "$nv_arr1"
                alias -g -- "${nv_arr1}=${nv_arr2}"
            else
                (( quiet )) || alias "$nv_arr1" &> /dev/null && {
                    builtin print "Removing ${ZINIT[col-info]}global${ZINIT[col-rst]} alias ${nv_arr1}"
                    unalias -- "${(q)nv_arr1}"
                }
            fi
        else
            if [[ -n "$nv_arr2" ]]; then
                (( quiet )) || builtin print "Restoring alias ${nv_arr1}=${nv_arr2}"
                alias "$nv_arr1" &> /dev/null && unalias -- "$nv_arr1"
                alias -- "${nv_arr1}=${nv_arr2}"
            else
                (( quiet )) || alias "$nv_arr1" &> /dev/null && {
                    builtin print "Removing alias ${nv_arr1}"
                    unalias -- "$nv_arr1"
                }
            fi
        fi
    done

    #
    # 5. Restore Zle state
    #

    local -a keys
    keys=( "${(@on)ZINIT[(I)TIME_<->_*]}" )
    integer keys_size=${#keys}
    () {
        setopt localoptions extendedglob noksharrays typesetsilent
        typeset -a restore_widgets skip_delete
        local wid
        restore_widgets=( "${(z)ZINIT[WIDGETS_SAVED__$uspl2]}" )
        for wid in "${(Oa)restore_widgets[@]}"; do
            [[ -z "$wid" ]] && continue
            wid="${(Q)wid}"
            typeset -a orig_saved
            orig_saved=( "${(z)wid}" )

            local tpe="${orig_saved[1]}"
            local orig_saved1="${(Q)orig_saved[2]}" # Original widget
            local comp_wid="${(Q)orig_saved[3]}"
            local orig_saved2="${(Q)orig_saved[4]}" # Saved target function
            local orig_saved3="${(Q)orig_saved[5]}" # Saved previous $widget's contents

            local found_time_key="${keys[(r)TIME_<->_${uspl2//\//---}]}" to_process_plugin
            integer found_time_idx=0 idx=0
            to_process_plugin=""
            [[ "$found_time_key" = (#b)TIME_(<->)_* ]] && found_time_idx="${match[1]}"
            if (( found_time_idx )); then # Must be true
                for (( idx = found_time_idx + 1; idx <= keys_size; ++ idx )); do
                    found_time_key="${keys[(r)TIME_${idx}_*]}"
                    local oth_uspl2=""
                    [[ "$found_time_key" = (#b)TIME_${idx}_(*) ]] && oth_uspl2="${match[1]//---//}"
                    local -a entry_splitted
                    entry_splitted=( "${(z@)ZINIT[WIDGETS_SAVED__$oth_uspl2]}" )
                    integer found_idx="${entry_splitted[(I)(-N|-C)\ $orig_saved1\\\ *]}"
                    local -a entry_splitted2
                    entry_splitted2=( "${(z@)ZINIT[BINDKEYS__$oth_uspl2]}" )
                    integer found_idx2="${entry_splitted2[(I)*\ $orig_saved1\ *]}"
                    if (( found_idx || found_idx2 ))
                    then
                        # Skip multiple loads of the same plugin
                        # TODO: fully handle multiple plugin loads
                        if [[ "$oth_uspl2" != "$uspl2" ]]; then
                            to_process_plugin="$oth_uspl2"
                            # only the first one is needed
                            break
                        fi
                    fi
                done
                if [[ -n "$to_process_plugin" ]]; then
                    if (( !found_idx && !found_idx2 )); then
                        (( quiet )) || builtin print "Problem (1) during handling of widget \`$orig_saved1' (contents: $orig_saved2)"
                        continue
                    fi
                    (( quiet )) || builtin print "Chaining widget \`$orig_saved1' to plugin $oth_uspl2"
                    local -a oth_orig_saved
                    if (( found_idx )) {
                        oth_orig_saved=( "${(z)${(Q)entry_splitted[found_idx]}}" )
                        local oth_fun="${oth_orig_saved[4]}"
                        # below is wrong because we don't want to call other plugins function at any moment
                        # oth_orig_saved[2]="${(q)orig_saved2}"
                        oth_orig_saved[5]="${(q)orig_saved3}" # chain up the widget
                        entry_splitted[found_idx]="${(q)${(j: :)oth_orig_saved}}"
                        ZINIT[WIDGETS_SAVED__$oth_uspl2]="${(j: :)entry_splitted}"
                    } else {
                        oth_orig_saved=( "${(z)${(Q)entry_splitted2[found_idx2]}}" )
                        local oth_fun="${widgets[${oth_orig_saved[3]}]#*:}"
                    }
                    integer idx="${functions[$orig_saved2][(i)(#b)([^[:space:]]#${orig_saved1}[^[:space:]]#)]}"
                    if (( idx <= ${#functions[$orig_saved2]} ))
                    then
                        local prefix_X="${match[1]#\{}"
                        [[ $prefix_X != \$* ]] && prefix_X="${prefix_X%\}}"
                        idx="${functions[$oth_fun][(i)(#b)([^[:space:]]#${orig_saved1}[^[:space:]]#)]}"
                        if (( idx <= ${#functions[$oth_fun]} )); then
                            match[1]="${match[1]#\{}"
                            [[ ${match[1]} != \$* ]] && match[1]="${match[1]%\}}"
                            eval "local oth_prefix_uspl2_X=\"${match[1]}\""
                            if [[ "${widgets[$prefix_X]}" = builtin ]]; then
                                (( quiet )) || builtin print "Builtin-restoring widget \`$oth_prefix_uspl2_X' ($oth_uspl2)"
                                zle -A ".${prefix_X#.}" "$oth_prefix_uspl2_X"
                            elif [[ "${widgets[$prefix_X]}" = completion:* ]]; then
                                (( quiet )) || builtin print "Chain*-restoring widget \`$oth_prefix_uspl2_X' ($oth_uspl2)"
                                zle -C "$oth_prefix_uspl2_X" "${(@)${(@s.:.)${orig_saved3#user:}}[2,3]}"
                            else
                                (( quiet )) || builtin print "Chain-restoring widget \`$oth_prefix_uspl2_X' ($oth_uspl2)"
                                zle -N "$oth_prefix_uspl2_X" "${widgets[$prefix_X]#user:}"
                            fi
                        fi
                        # The alternate method
                        # skip_delete+=( "${match[1]}" )
                        # functions[$oth_fun]="${functions[$oth_fun]//[^\{[:space:]]#$orig_saved1/${match[1]}}"
                    fi
                else
                    (( quiet )) || builtin print "Restoring Zle widget $orig_saved1"
                    if [[ "$orig_saved3" = builtin ]]; then
                        zle -A ".$orig_saved1" "$orig_saved1"
                    elif [[ "$orig_saved3" = completion:* ]]; then
                        zle -C "$orig_saved1" "${(@)${(@s.:.)${orig_saved3#user:}}[2,3]}"
                    else
                        zle -N "$orig_saved1" "${orig_saved3#user:}"
                    fi
                fi
            else
                (( quiet )) || builtin print "Problem (2) during handling of widget \`$orig_saved1' (contents: $orig_saved2)"
            fi
        done
    }

    typeset -a delete_widgets
    delete_widgets=( "${(z)ZINIT[WIDGETS_DELETE__$uspl2]}" )
    local wid
    for wid in "${(Oa)delete_widgets[@]}"; do
        [[ -z "$wid" ]] && continue
        wid="${(Q)wid}"
        if [[ -n "${skip_delete[(r)$wid]}" ]]; then
            builtin print "Would delete $wid"
            continue
        fi
        if [[ "${ZINIT_ZLE_HOOKS_LIST[$wid]}" = "1" ]]; then
            (( quiet )) || builtin print "Removing Zle hook \`$wid'"
        else
            (( quiet )) || builtin print "Removing Zle widget \`$wid'"
        fi
        zle -D "$wid"
    done

    # 6. Unfunction
    .zinit-diff-functions-compute "$uspl2"
    typeset -a func
    func=( "${(z)ZINIT[FUNCTIONS__$uspl2]}" )
    local f
    for f in "${(on)func[@]}"; do
        [[ -z "$f" ]] && continue
        f="${(Q)f}"
        (( quiet )) || builtin print "Deleting function $f"
        (( ${+functions[$f]} )) && unfunction -- "$f"
        (( ${+precmd_functions} )) && precmd_functions=( ${precmd_functions[@]:#$f} )
        (( ${+preexec_functions} )) && preexec_functions=( ${preexec_functions[@]:#$f} )
        (( ${+chpwd_functions} )) && chpwd_functions=( ${chpwd_functions[@]:#$f} )
        (( ${+periodic_functions} )) && periodic_functions=( ${periodic_functions[@]:#$f} )
        (( ${+zshaddhistory_functions} )) && zshaddhistory_functions=( ${zshaddhistory_functions[@]:#$f} )
        (( ${+zshexit_functions} )) && zshexit_functions=( ${zshexit_functions[@]:#$f} )
    done

    # 7. Clean up FPATH and PATH
    .zinit-diff-env-compute "$uspl2"
    # iterate over $path elements and skip those that were added by the plugin
    typeset -a new elem p
    elem=( "${(z)ZINIT[PATH__$uspl2]}" )
    for p in "${path[@]}"; do
        if [[ -z "${elem[(r)${(q)p}]}" ]] {
            new+=( "$p" )
        } else {
            (( quiet )) || builtin print "Removing PATH element ${ZINIT[col-info]}$p${ZINIT[col-rst]}"
            [[ -d "$p" ]] || (( quiet )) || builtin print "${ZINIT[col-error]}Warning:${ZINIT[col-rst]} it didn't exist on disk"
        }
    done
    path=( "${new[@]}" )

    # The same for $fpath
    elem=( "${(z)ZINIT[FPATH__$uspl2]}" )
    new=( )
    for p ( "${fpath[@]}" ) {
        if [[ -z "${elem[(r)${(q)p}]}" ]] {
            new+=( "$p" )
        } else {
            (( quiet )) || builtin print "Removing FPATH element ${ZINIT[col-info]}$p${ZINIT[col-rst]}"
            [[ -d "$p" ]] || (( quiet )) || builtin print "${ZINIT[col-error]}Warning:${ZINIT[col-rst]} it didn't exist on disk"
        }
    }
    fpath=( "${new[@]}" )

    # 8. Delete created variables
    .zinit-diff-parameter-compute "$uspl2"
    empty=0
    .zinit-save-set-extendedglob
    [[ "${ZINIT[PARAMETERS_POST__$uspl2]}" != *[$'! \t']* ]] && empty=1
    .zinit-restore-extendedglob

    if (( empty != 1 )); then
        typeset -A elem_pre elem_post
        elem_pre=( "${(z)ZINIT[PARAMETERS_PRE__$uspl2]}" )
        elem_post=( "${(z)ZINIT[PARAMETERS_POST__$uspl2]}" )

        # Find variables created or modified
        local wl found
        local -a whitelist
        whitelist=( "${(@Q)${(z@)ZINIT[ENV-WHITELIST]}}" )
        for k in "${(k)elem_post[@]}"; do
            k="${(Q)k}"
            local v1="${(Q)elem_pre[$k]}"
            local v2="${(Q)elem_post[$k]}"

            # "" means a variable was deleted, not created/changed
            if [[ $v2 != '""' ]]; then
                # Don't unset readonly variables
                [[ ${(tP)k} == *-readonly(|-*) ]] && continue

                # Don't unset arrays managed by add-zsh-hook, also ignore a few special parameters
                # TODO: remember and remove hooks
                case "$k" in
                    (chpwd_functions|precmd_functions|preexec_functions|periodic_functions|zshaddhistory_functions|zshexit_functions|zsh_directory_name_functions)
                        continue
                    (path|PATH|fpath|FPATH)
                        continue;
                        ;;
                esac

                # Don't unset redefined variables, only newly defined "" means variable didn't exist before plugin load (didn't have a type).
                # Do an exception for the prompt variables
                if [[ $v1 = '""' || ( $k = (RPROMPT|RPS1|RPS2|PROMPT|PS1|PS2|PS3|PS4) && $v1 != $v2 ) ]]; then
                    found=0
                    for wl in "${whitelist[@]}"; do
                        if [[ "$k" = ${~wl} ]]; then
                            found=1
                            break
                        fi
                    done
                    if (( !found )); then
                        (( quiet )) || builtin print "Unsetting variable $k"
                        # checked that 4.3.17 does support "--"; cannot be parameter starting with "-" but let's defensively use "--" here
                        unset -- "$k"
                    else
                        builtin print "Skipping unset of variable $k (whitelist)"
                    fi
                fi
            fi
        done
    fi

    # 9. Forget the plugin
    if [[ "$uspl2" = "_dtrace/_dtrace" ]]; then
        .zinit-debug-clear
    else
        (( quiet )) || builtin print "Unregistering plugin $uspl2col"
        .zinit-unregister-plugin "$user" "$plugin" "${sice[teleid]}"
        zsh_loaded_plugins[${zsh_loaded_plugins[(i)$user${${user:#(%|/)*}:+/}$plugin]}]=()  # Support Zsh plugin standard
        .zinit-clear-report-for "$user" "$plugin"
        (( quiet )) || builtin print "Plugin's report saved to \$LASTREPORT"
    fi
} # ]]]

# FUNCTION: .zinit-update-all-parallel [[[
.zinit-update-all-parallel() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob warncreateglobal typesetsilent \
        noshortloops nomonitor nonotify

    local id_as repo snip uspl user plugin PUDIR="$(mktemp -d)"

    local -A PUAssocArray map
    map=( / --  "=" -EQ-  "?" -QM-  "&" -AMP-  : - )
    local -a files
    integer main_counter counter PUPDATE=1

    files=( ${ZINIT[SNIPPETS_DIR]}/**/(._zinit|._zplugin)/mode(ND) )
    main_counter=${#files}
    if (( OPTS[opt_-s,--snippets] || !OPTS[opt_-l,--plugins] )) {
        for snip ( "${files[@]}" ) {
            main_counter=main_counter-1
            # The continue may cause the tail of processes to fall-through to the following plugins-specific `wait'
            # Should happen only in a very special conditions
            # TODO handle this
            [[ ! -f ${snip:h}/url ]] && continue
            [[ -f ${snip:h}/id-as ]] && \
                id_as="$(<${snip:h}/id-as)" || \
                id_as=

            counter+=1
            local ef_id="${id_as:-$(<${snip:h}/url)}"
            local PUFILEMAIN=${${ef_id#/}//(#m)[\/=\?\&:]/${map[$MATCH]}}
            local PUFILE=$PUDIR/${counter}_$PUFILEMAIN.out

            .zinit-update-or-status-snippet "$st" "$ef_id" &>! $PUFILE &

            PUAssocArray[$!]=$PUFILE

            .zinit-wait-for-update-jobs snippets
        }
    }

    counter=0
    PUAssocArray=()

    if (( OPTS[opt_-l,--plugins] || !OPTS[opt_-s,--snippets] )) {
        local -a files2
        files=( ${ZINIT[PLUGINS_DIR]}/*(ND/) )

        # Pre-process plugins
        for repo ( $files ) {
            uspl=${repo:t}
            # Two special cases
            [[ $uspl = custom || $uspl = _local---zinit ]] && continue

            # Check if repository has a remote set
            if [[ -f $repo/.git/config ]] {
                local -a config
                config=( ${(f)"$(<$repo/.git/config)"} )
                if [[ ${#${(M)config[@]:#\[remote[[:blank:]]*\]}} -eq 0 ]] {
                    continue
                }
            }

            .zinit-any-to-user-plugin "$uspl"
            local user=${reply[-2]} plugin=${reply[-1]}

            # Must be a git repository or a binary release
            if [[ ! -d $repo/.git && ! -f $repo/._zinit/is_release ]] {
                continue
            }
            files2+=( $repo )
        }

        main_counter=${#files2}
        for repo ( "${files2[@]}" ) {
            main_counter=main_counter-1

            uspl=${repo:t}
            id_as=${uspl//---//}

            counter+=1
            local PUFILEMAIN=${${id_as#/}//(#m)[\/=\?\&:]/${map[$MATCH]}}
            local PUFILE=$PUDIR/${counter}_$PUFILEMAIN.out

            .zinit-any-colorify-as-uspl2 "$uspl"
            +zi-log "Updating $REPLY{…}" >! $PUFILE

            .zinit-any-to-user-plugin "$uspl"
            local user=${reply[-2]} plugin=${reply[-1]}

            .zinit-update-or-status update "$user" "$plugin" &>>! $PUFILE &

            PUAssocArray[$!]=$PUFILE

            .zinit-wait-for-update-jobs plugins

        }
    }
    # Shouldn't happen
    # (( ${#PUAssocArray} > 0 )) && wait ${(k)PUAssocArray}
} # ]]]
# FUNCTION: .zinit-update-or-status [[[
# Updates (git pull) or does `git status' for given plugin.
#
# User-action entry point.
#
# $1 - "status" for status, other for update
# $2 - plugin spec (4 formats: user---plugin, user/plugin, user (+ plugin in $2), plugin)
# $3 - plugin (only when $1 - i.e. user - given)
.zinit-update-or-status() {
    # Set the localtraps option.
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob nullglob warncreateglobal typesetsilent noshortloops

    local -a arr
    ZINIT[first-plugin-mark]=${${ZINIT[first-plugin-mark]:#init}:-1}
    ZINIT[-r/--reset-opt-hook-has-been-run]=0

    # Deliver and withdraw the `m` function when finished.
    .zinit-set-m-func set
    trap ".zinit-set-m-func unset" EXIT

    integer retval hook_rc was_snippet
    .zinit-two-paths "$2${${2:#(%|/)*}:+${3:+/}}$3"
    if [[ -d ${reply[-4]} || -d ${reply[-2]} ]]; then
        .zinit-update-or-status-snippet "$1" "$2${${2:#(%|/)*}:+${3:+/}}$3"
        retval=$?
        was_snippet=1
    fi

    .zinit-any-to-user-plugin "$2" "$3"
    local user=${reply[-2]} plugin=${reply[-1]} st=$1 \
        local_dir filename is_snippet key \
        id_as="${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]}"
    local -A ice

    if (( was_snippet )) {
        .zinit-exists-physically "$user" "$plugin" || return $retval
        .zinit-any-colorify-as-uspl2 "$2" "$3"
        (( !OPTS[opt_-q,--quiet] )) && \
            +zi-log "{msg2}Updating also \`$REPLY{rst}{msg2}'" \
                "plugin (already updated a snippet of the same name){…}{rst}"
    } else {
        .zinit-exists-physically-message "$user" "$plugin" || return 1
    }

    if [[ $st = status ]]; then
        ( builtin cd -q ${ZINIT[PLUGINS_DIR]}/${user:+${user}---}${plugin//\//---}; command git status; )
        return $retval
    fi

    command rm -f ${TMPDIR:-${TMPDIR:-/tmp}}/zinit-execs.$$.lst ${TMPDIR:-${TMPDIR:-/tmp}}/zinit.installed_comps.$$.lst \
                    ${TMPDIR:-${TMPDIR:-/tmp}}/zinit.skipped_comps.$$.lst ${TMPDIR:-${TMPDIR:-/tmp}}/zinit.compiled.$$.lst

    # A flag for the annexes. 0 – no new commits, 1 - run-atpull mode,
    # 2 – full update/there are new commits to download, 3 - full but
    # a forced download (i.e.: the medium doesn't allow to peek update)
    ZINIT[annex-multi-flag:pull-active]=0

    (( ${#ICE[@]} > 0 )) && { ZINIT_SICE[$user${${user:#(%|/)*}:+/}$plugin]=""; local nf="-nftid"; }

    .zinit-compute-ice "$user${${user:#(%|/)*}:+/}$plugin" "pack$nf" \
        ice local_dir filename is_snippet || return 1

    .zinit-any-to-user-plugin ${ice[teleid]:-$id_as}
    user=${reply[1]} plugin=${reply[2]}

    local repo="${${${(M)id_as#%}:+${id_as#%}}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}"

    # Run annexes' preinit hooks
    local -a arr
    reply=(
        ${(on)ZINIT_EXTS2[(I)zinit hook:preinit-pre <->]}
        ${(on)ZINIT_EXTS[(I)z-annex hook:preinit-<-> <->]}
        ${(on)ZINIT_EXTS2[(I)zinit hook:preinit-post <->]}
    )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
        "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$local_dir" ${${key##(zinit|z-annex) hook:}%% <->} update || \
            return $(( 10 - $? ))
    done

    # Check if repository has a remote set, if it is _local
    if [[ -f $local_dir/.git/config ]]; then
        local -a config
        config=( ${(f)"$(<$local_dir/.git/config)"} )
        if [[ ${#${(M)config[@]:#\[remote[[:blank:]]*\]}} -eq 0 ]]; then
            (( !OPTS[opt_-q,--quiet] )) && {
                .zinit-any-colorify-as-uspl2 "$id_as"
                [[ $id_as = _local/* ]] && builtin print -r -- "Skipping local plugin $REPLY" || \
                    builtin print -r -- "$REPLY doesn't have a remote set, will not fetch"
            }
            return 1
        fi
    fi

    command rm -f $local_dir/.zinit_lastupd

    if (( 1 )); then
        if [[ -z ${ice[is_release]} && ${ice[from]} = (gh-r|github-rel|cygwin) ]] {
            ice[is_release]=true
        }

        integer count is_release=0
        for (( count = 1; count <= 5; ++ count )) {
            if (( ${+ice[is_release${count:#1}]} )) {
                is_release=1
            }
        }

        (( ${+functions[.zinit-setup-plugin-dir]} )) || builtin source ${ZINIT[BIN_DIR]}"/zinit-install.zsh"
        if [[ $ice[from] == (gh-r|github-rel) ]] {
            {
                ICE=( "${(kv)ice[@]}" )
                .zinit-get-latest-gh-r-url-part "$user" "$plugin" || return $?
            } always {
                ICE=()
            }
        } else {
            REPLY=""
        }

        if (( is_release )) {
            count=0
            for REPLY ( $reply ) {
                count+=1
                local version=${REPLY/(#b)(\/[^\/]##)(#c4,4)\/([^\/]##)*/${match[2]}}
                if [[ ${ice[is_release${count:#1}]} = $REPLY ]] {
                    (( ${+ice[run-atpull]} || OPTS[opt_-u,--urge] )) && \
                        ZINIT[annex-multi-flag:pull-active]=1 || \
                        ZINIT[annex-multi-flag:pull-active]=0
                } else {
                    ZINIT[annex-multi-flag:pull-active]=2
                    break
                }
            }
            if (( ZINIT[annex-multi-flag:pull-active] <= 1 && !OPTS[opt_-q,--quiet] )) {
                +zi-log "{info}[{pre}${ice[from]}{info}]{rst} latest version ({version}${version}{rst}) already installed"
            }
        }

        if (( 1 )) {
            if (( ZINIT[annex-multi-flag:pull-active] >= 1 )) {
                if (( OPTS[opt_-q,--quiet] && !PUPDATE )) {
                    .zinit-any-colorify-as-uspl2 "$id_as"
                    (( ZINIT[first-plugin-mark] )) && {
                        ZINIT[first-plugin-mark]=0
                    } || builtin print
                    builtin print "\rUpdating $REPLY"
                }

                ICE=( "${(kv)ice[@]}" )
                # Run annexes' atpull hooks (the before atpull-ice ones).
                # The gh-r / GitHub releases block.
                reply=(
                    ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-pre <->]}
                    ${${(M)ICE[atpull]#\!}:+${(on)ZINIT_EXTS[(I)z-annex hook:\!atpull-<-> <->]}}
                    ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-post <->]}
                )
                for key in "${reply[@]}"; do
                    arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                    "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$local_dir" "${${key##(zinit|z-annex) hook:}%% <->}" update:bin
                    hook_rc=$?
                    [[ "$hook_rc" -ne 0 ]] && {
                        # note: this will effectively return the last != 0 rc
                        retval="$hook_rc"
                        builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                    }
                done

                if (( ZINIT[annex-multi-flag:pull-active] >= 2 )) {
                    if ! .zinit-setup-plugin-dir "$user" "$plugin" "$id_as" release -u $version; then
                        ZINIT[annex-multi-flag:pull-active]=0
                    fi
                    if (( OPTS[opt_-q,--quiet] != 1 )) {
                        builtin print
                    }
                }
                ICE=()
            }
        }

        if [[ -d $local_dir/.git ]] && ( builtin cd -q $local_dir ; command git show-ref --verify --quiet refs/heads/main ); then
            local main_branch=main
        else
            local main_branch=master
        fi

        if (( ! is_release )) {
            ( builtin cd -q "$local_dir" || return 1
              integer had_output=0
              local IFS=$'\n'
              command git fetch --quiet && \
                command git --no-pager log --color --date=short --pretty=format:'%Cgreen%cd %h %Creset%s%n' ..FETCH_HEAD | \
                while read line; do
                  [[ -n ${line%%[[:space:]]##} ]] && {
                      [[ $had_output -eq 0 ]] && {
                          had_output=1
                          if (( OPTS[opt_-q,--quiet] && !PUPDATE )) {
                              .zinit-any-colorify-as-uspl2 "$id_as"
                              (( ZINIT[first-plugin-mark] )) && {
                                  ZINIT[first-plugin-mark]=0
                              } || builtin print
                              builtin print "Updating $REPLY"
                          }
                      }
                      builtin print $line
                  }
                done | \
                command tee .zinit_lastupd | \
                .zinit-pager &

              integer pager_pid=$!
              { sleep 20 && kill -9 $pager_pid 2>/dev/null 1>&2; } &!
              { wait $pager_pid; } > /dev/null 2>&1

              local -a log
              { log=( ${(@f)"$(<$local_dir/.zinit_lastupd)"} ); } 2>/dev/null
              command rm -f $local_dir/.zinit_lastupd

              if [[ ${#log} -gt 0 ]] {
                  ZINIT[annex-multi-flag:pull-active]=2
              } else {
                  if (( ${+ice[run-atpull]} || OPTS[opt_-u,--urge] )) {
                      ZINIT[annex-multi-flag:pull-active]=1

                      # Handle the snippet/plugin boundary in the messages
                      if (( OPTS[opt_-q,--quiet] && !PUPDATE )) {
                          .zinit-any-colorify-as-uspl2 "$id_as"
                          (( ZINIT[first-plugin-mark] )) && {
                              ZINIT[first-plugin-mark]=0
                          } || builtin print
                          builtin print "\rUpdating $REPLY"
                      }
                  } else {
                      ZINIT[annex-multi-flag:pull-active]=0
                  }
              }

              if (( ZINIT[annex-multi-flag:pull-active] >= 1 )) {
                  ICE=( "${(kv)ice[@]}" )
                  # Run annexes' atpull hooks (the before atpull-ice ones).
                  # The regular Git-plugins block.
                  reply=(
                      ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-pre <->]}
                      ${${(M)ICE[atpull]#\!}:+${(on)ZINIT_EXTS[(I)z-annex hook:\!atpull-<-> <->]}}
                      ${(on)ZINIT_EXTS2[(I)zinit hook:e-\!atpull-post <->]}
                  )
                  for key in "${reply[@]}"; do
                      arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                      "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$local_dir" "${${key##(zinit|z-annex) hook:}%% <->}" update:git
                      hook_rc=$?
                      [[ "$hook_rc" -ne 0 ]] && {
                          # note: this will effectively return the last != 0 rc
                          retval="$hook_rc"
                          builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                      }
                  done
                  ICE=()
                  (( ZINIT[annex-multi-flag:pull-active] >= 2 )) && command git pull --no-stat ${=ice[pullopts]:---ff-only} origin ${ice[ver]:-$main_branch} |& command grep -E -v '(FETCH_HEAD|up.to.date\.|From.*://)'
              }
              return ${ZINIT[annex-multi-flag:pull-active]}
            )
            ZINIT[annex-multi-flag:pull-active]=$?
        }

        if [[ -d $local_dir/.git ]]; then
            (
                builtin cd -q "$local_dir" # || return 1 - don't return, maybe it's some hook's logic
                if (( OPTS[opt_-q,--quiet] )) {
                    command git pull --recurse-submodules ${=ice[pullopts]:---ff-only} origin ${ice[ver]:-$main_branch} &> /dev/null
                } else {
                    command git pull --recurse-submodules ${=ice[pullopts]:---ff-only} origin ${ice[ver]:-$main_branch} |& command grep -E -v '(FETCH_HEAD|up.to.date\.|From.*://)'
                }
            )
        fi
        if [[ -n ${(v)ice[(I)(mv|cp|atpull|ps-on-update|cargo)]} || $+ice[sbin]$+ice[make]$+ice[extract]$+ice[configure] -ne 0 ]] {
            if (( !OPTS[opt_-q,--quiet] && ZINIT[annex-multi-flag:pull-active] == 1 )) {
                +zi-log -n "{pre}[update]{msg3} Continuing with the update because "
                (( ${+ice[run-atpull]} )) && \
                    +zi-log "{ice}run-atpull{apo}''{msg3} ice given.{rst}" || \
                    +zi-log "{opt}-u{msg3}/{opt}--urge{msg3} given.{rst}"
            }
        }

        # Any new commits?
        if (( ZINIT[annex-multi-flag:pull-active] >= 1  )) {
            ICE=( "${(kv)ice[@]}" )
            # Run annexes' atpull hooks (the before atpull[^!]…-ice ones).
            # Block common for Git and gh-r plugins.
            reply=(
                ${(on)ZINIT_EXTS2[(I)zinit hook:no-e-\!atpull-pre <->]}
                ${${ICE[atpull]:#\!*}:+${(on)ZINIT_EXTS[(I)z-annex hook:\!atpull-<-> <->]}}
                ${(on)ZINIT_EXTS2[(I)zinit hook:no-e-\!atpull-post <->]}
            )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$local_dir" "${${key##(zinit|z-annex) hook:}%% <->}" update
                hook_rc="$?"
                [[ "$hook_rc" -ne 0 ]] && {
                    # note: this will effectively return the last != 0 rc
                    retval="$hook_rc"
                    builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                }
            done

            # Run annexes' atpull hooks (the after atpull-ice ones).
            # Block common for Git and gh-r plugins.
            reply=(
                ${(on)ZINIT_EXTS2[(I)zinit hook:atpull-pre <->]}
                ${(on)ZINIT_EXTS[(I)z-annex hook:atpull-<-> <->]}
                ${(on)ZINIT_EXTS2[(I)zinit hook:atpull-post <->]}
            )
            for key in "${reply[@]}"; do
                arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
                "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$local_dir" "${${key##(zinit|z-annex) hook:}%% <->}" update
                hook_rc="$?"
                [[ "$hook_rc" -ne 0 ]] && {
                    # note: this will effectively return the last != 0 rc
                    retval="$hook_rc"
                    builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
                }
            done
            ICE=()
        }

        # Store ices to disk at update of plugin
        .zinit-store-ices "$local_dir/._zinit" ice "" "" "" ""
    fi

    # Run annexes' atpull hooks (the `always' after atpull-ice ones)
    # Block common for Git and gh-r plugins.
    ICE=( "${(kv)ice[@]}" )
    reply=(
        ${(on)ZINIT_EXTS2[(I)zinit hook:%atpull-pre <->]}
        ${(on)ZINIT_EXTS[(I)z-annex hook:%atpull-<-> <->]}
        ${(on)ZINIT_EXTS2[(I)zinit hook:%atpull-post <->]}
    )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
        "${arr[5]}" plugin "$user" "$plugin" "$id_as" "$local_dir" "${${key##(zinit|z-annex) hook:}%% <->}" update:$ZINIT[annex-multi-flag:pull-active]
        hook_rc=$?
        [[ "$hook_rc" -ne 0 ]] && {
            # note: this will effectively return the last != 0 rc
            retval="$hook_rc"
            builtin print -Pr -- "${ZINIT[col-warn]}Warning:%f%b ${ZINIT[col-obj]}${arr[5]}${ZINIT[col-warn]} hook returned with ${ZINIT[col-obj]}${hook_rc}${ZINIT[col-rst]}"
        }
    done
    ICE=()

    typeset -ga INSTALLED_EXECS
    { INSTALLED_EXECS=( "${(@f)$(<${TMPDIR:-${TMPDIR:-/tmp}}/zinit-execs.$$.lst)}" ) } 2>/dev/null

    if [[ -e ${TMPDIR:-${TMPDIR:-/tmp}}/zinit.skipped_comps.$$.lst || -e ${TMPDIR:-${TMPDIR:-/tmp}}/zinit.installed_comps.$$.lst ]] {
        typeset -ga INSTALLED_COMPS SKIPPED_COMPS
        { INSTALLED_COMPS=( "${(@f)$(<${TMPDIR:-${TMPDIR:-/tmp}}/zinit.installed_comps.$$.lst)}" ) } 2>/dev/null
        { SKIPPED_COMPS=( "${(@f)$(<${TMPDIR:-${TMPDIR:-/tmp}}/zinit.skipped_comps.$$.lst)}" ) } 2>/dev/null
    }

    if [[ -e ${TMPDIR:-${TMPDIR:-/tmp}}/zinit.compiled.$$.lst ]] {
        typeset -ga ADD_COMPILED
        { ADD_COMPILED=( "${(@f)$(<${TMPDIR:-${TMPDIR:-/tmp}}/zinit.compiled.$$.lst)}" ) } 2>/dev/null
    }

    if (( PUPDATE && ZINIT[annex-multi-flag:pull-active] > 0 )) {
        builtin print ${ZINIT[annex-multi-flag:pull-active]} >! $PUFILE.ind
    }

    return $retval
} # ]]]
# FUNCTION: .zinit-update-or-status-all [[[
# Updates (git pull) or does `git status` for all existing plugins.
# This includes also plugins that are not loaded into Zsh (but exist
# on disk). Also updates (i.e. redownloads) snippets.
#
# User-action entry point.
.zinit-update-or-status-all() {
    builtin emulate -LR zsh ${=${options[xtrace]:#off}:+-o xtrace}
    setopt extendedglob nullglob warncreateglobal typesetsilent noshortloops

    local -F2 SECONDS=0

    .zinit-self-update -q

    [[ $2 = restart ]] && \
        +zi-log "{msg2}Restarting the update with the new codebase loaded.{rst}"$'\n'

    local file
    integer sum el update_rc
    for file ( "" -side -install -autoload ) {
        .zinit-get-mtime-into "${ZINIT[BIN_DIR]}/zinit$file.zsh" el; sum+=el
    }

    # Reload Zinit?
    if [[ $2 != restart ]] && (( ZINIT[mtime] + ZINIT[mtime-side] +
        ZINIT[mtime-install] + ZINIT[mtime-autoload] != sum
    )) {
        +zi-log "{msg2}Detected Zinit update in another session -" \
            "{pre}reloading Zinit{msg2}{…}{rst}"
        source $ZINIT[BIN_DIR]/zinit.zsh
        source $ZINIT[BIN_DIR]/zinit-side.zsh
        source $ZINIT[BIN_DIR]/zinit-install.zsh
        source $ZINIT[BIN_DIR]/zinit-autoload.zsh
        for file ( "" -side -install -autoload ) {
            .zinit-get-mtime-into "${ZINIT[BIN_DIR]}/zinit$file.zsh" "ZINIT[mtime$file]"
        }
        +zi-log "%B{pname}Done.{rst}"$'\n'
        .zinit-update-or-status-all "$1" restart
        return $?
    }

    integer retval

    if (( OPTS[opt_-p,--parallel] )) && [[ $1 = update ]] {
        (( !OPTS[opt_-q,--quiet] )) && \
            +zi-log '{info2}Parallel Update Starts Now{…}{rst}'
        .zinit-update-all-parallel
        retval=$?
        .zinit-compinit 1 1 &>/dev/null
        rehash
        if (( !OPTS[opt_-q,--quiet] )) {
            +zi-log "{msg2}The update took {obj}${SECONDS}{msg2} seconds{rst}"
        }
        return $retval
    }

    local st=$1 id_as repo snip pd user plugin
    integer PUPDATE=0

    local -A ICE


    if (( OPTS[opt_-s,--snippets] || !OPTS[opt_-l,--plugins] )) {
        local -a snipps
        snipps=( ${ZINIT[SNIPPETS_DIR]}/**/(._zinit|._zplugin)(ND) )

        [[ $st != status && ${OPTS[opt_-q,--quiet]} != 1 && -n $snipps ]] && \
            +zi-log "{info}Note:{rst} updating also unloaded snippets"

        for snip ( ${ZINIT[SNIPPETS_DIR]}/**/(._zinit|._zplugin)/mode(D) ) {
            [[ ! -f ${snip:h}/url ]] && continue
            [[ -f ${snip:h}/id-as ]] && \
                id_as="$(<${snip:h}/id-as)" || \
                id_as=
            .zinit-update-or-status-snippet "$st" "${id_as:-$(<${snip:h}/url)}"
            ICE=()
        }
        [[ -n $snipps ]] && builtin print
    }

    ICE=()

    if (( OPTS[opt_-s,--snippets] && !OPTS[opt_-l,--plugins] )) {
        return
    }

    if [[ $st = status ]]; then
        (( !OPTS[opt_-q,--quiet] )) && \
            +zi-log "{info}Note:{rst} status done also for unloaded plugins"
    else
        (( !OPTS[opt_-q,--quiet] )) && \
            +zi-log "{info}Note:{rst} updating also unloaded plugins"
    fi

    ZINIT[first-plugin-mark]=init

    for repo in ${ZINIT[PLUGINS_DIR]}/*; do
        pd=${repo:t}

        # Two special cases
        [[ $pd = custom || $pd = _local---zinit ]] && continue

        .zinit-any-colorify-as-uspl2 "$pd"

        # Check if repository has a remote set
        if [[ -f $repo/.git/config ]]; then
            local -a config
            config=( ${(f)"$(<$repo/.git/config)"} )
            if [[ ${#${(M)config[@]:#\[remote[[:blank:]]*\]}} -eq 0 ]]; then
                if (( !OPTS[opt_-q,--quiet] )) {
                    [[ $pd = _local---* ]] && \
                        builtin print -- "\nSkipping local plugin $REPLY" || \
                        builtin print "\n$REPLY doesn't have a remote set, will not fetch"
                }
                continue
            fi
        fi

        .zinit-any-to-user-plugin "$pd"
        local user=${reply[-2]} plugin=${reply[-1]}

        # Must be a git repository or a binary release
        if [[ ! -d $repo/.git && ! -f $repo/._zinit/is_release ]]; then
            (( !OPTS[opt_-q,--quiet] )) && \
                builtin print "$REPLY: not a git repository"
            continue
        fi

        if [[ $st = status ]]; then
            builtin print "\nStatus for plugin $REPLY"
            ( builtin cd -q "$repo"; command git status )
        else
            (( !OPTS[opt_-q,--quiet] )) && builtin print "Updating $REPLY" || builtin print -n .
            .zinit-update-or-status update "$user" "$plugin"
            update_rc=$?
            [[ $update_rc -ne 0 ]] && {
                +zi-log "🚧{warn}Warning: {pid}${user}/${plugin} {warn}update returned {obj}$update_rc"
                retval=$?
            }
        fi
    done

    .zinit-compinit 1 1 &>/dev/null
    if (( !OPTS[opt_-q,--quiet] )) {
        +zi-log "{msg2}The update took {obj}${SECONDS}{msg2} seconds{rst}"
    }

    return "$retval"
} # ]]]
# FUNCTION: .zinit-update-or-status-snippet [[[
#
# Implements update or status operation for snippet given by URL.
#
# $1 - "status" or "update"
# $2 - snippet URL
.zinit-update-or-status-snippet() {
    local st="$1" URL="${2%/}" local_dir filename is_snippet
    (( ${#ICE[@]} > 0 )) && { ZINIT_SICE[$URL]=""; local nf="-nftid"; }
    local -A ICE2
    .zinit-compute-ice "$URL" "pack$nf" \
        ICE2 local_dir filename is_snippet || return 1

    integer retval

    if [[ "$st" = "status" ]]; then
        if (( ${+ICE2[svn]} )); then
            builtin print -r -- "${ZINIT[col-info]}Status for ${${${local_dir:h}:t}##*--}/${local_dir:t}${ZINIT[col-rst]}"
            ( builtin cd -q "$local_dir"; command svn status -vu )
            retval=$?
            builtin print
        else
            builtin print -r -- "${ZINIT[col-info]}Status for ${${local_dir:h}##*--}/$filename${ZINIT[col-rst]}"
            ( builtin cd -q "$local_dir"; command ls -lth $filename )
            retval=$?
            builtin print
        fi
    else
        (( ${+functions[.zinit-setup-plugin-dir]} )) || builtin source ${ZINIT[BIN_DIR]}"/zinit-install.zsh"
        ICE=( "${(kv)ICE2[@]}" )
        .zinit-update-snippet "${ICE2[teleid]:-$URL}"
        retval=$?
    fi

    ICE=()

    if (( PUPDATE && ZINIT[annex-multi-flag:pull-active] > 0 )) {
        builtin print ${ZINIT[annex-multi-flag:pull-active]} >! $PUFILE.ind
    }

    return $retval
} # ]]]
# FUNCTION: .zinit-wait-for-update-jobs [[[
.zinit-wait-for-update-jobs() {
    local tpe=$1
    if (( counter > OPTS[value] || main_counter == 0 )) {
        wait ${(k)PUAssocArray}
        local ind_file
        for ind_file ( ${^${(von)PUAssocArray}}.ind(DN.) ) {
            command cat ${ind_file:r}
            (( !OPTS[opt_-d,--debug] && !ZINIT[DEBUG_MODE] )) && \
                command rm -f $ind_file
        }
        (( !OPTS[opt_-d,--debug] && !ZINIT[DEBUG_MODE] )) && \
            command rm -f ${(v)PUAssocArray}
        counter=0
        PUAssocArray=()
    } elif (( counter == 1 && !OPTS[opt_-q,--quiet] )) {
        +zi-log "{obj}Spawning the next{num}" \
            "${OPTS[value]}{obj} concurrent update jobs" \
            "({msg2}${tpe}{obj}){…}{rst}"
    }
} # ]]]

# FUNCTION: zi::version [[[
# Shows usage information.
#
# User-action entry point.
zi::version() {
	+zi-log "zinit{cmd} $(command git --git-dir=$(realpath ${ZINIT[BIN_DIR]}/.git) describe --tags) {rst}(${OSTYPE}_${CPUTYPE})"
	return $?
} # ]]]

# vim: set fenc=utf8 ffs=unix foldmarker=[[[,]]] foldmethod=marker ft=zsh list et sts=4 sw=4 ts=4 tw=100:
