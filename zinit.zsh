# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors.

#
# Main state variables.
#

typeset -gaH ZINIT_REGISTERED_PLUGINS ZINIT_TASKS ZINIT_RUN
typeset -ga zsh_loaded_plugins
if (( !${#ZINIT_TASKS} )) { ZINIT_TASKS=( "<no-data>" ); }
# Snippets loaded, url -> file name.
typeset -gAH ZINIT ZINIT_SNIPPETS ZINIT_REPORTS ZINIT_ICES ZINIT_SICE ZINIT_CUR_BIND_MAP ZINIT_EXTS ZINIT_EXTS2
typeset -gaH ZINIT_COMPDEF_REPLAY

# Compatibility with pre-rename project (Zplugin).
typeset -gAH ZPLGM
ZINIT=( "${(kv)ZPLGM[@]}" "${(kv)ZINIT[@]}" )
unset ZPLGM

#
# Common needed values.
#

[[ ! -e ${ZINIT[BIN_DIR]}/zinit.zsh ]] && ZINIT[BIN_DIR]=

# Respect the plugin standard too.
ZINIT[ZERO]="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
[[ ! -o functionargzero || ${options[posixargzero]} = on || ${ZINIT[ZERO]} != */* ]] && ZINIT[ZERO]="${(%):-%N}"

: ${ZINIT[BIN_DIR]:="${ZINIT[ZERO]:h}"}
[[ ${ZINIT[BIN_DIR]} = \~* ]] && ZINIT[BIN_DIR]=${~ZINIT[BIN_DIR]}

# Make ZINIT[BIN_DIR] path absolute.
ZINIT[BIN_DIR]="${${(M)ZINIT[BIN_DIR]:#/*}:-$PWD/${ZINIT[BIN_DIR]}}"

# Final test of ZINIT[BIN_DIR].
if [[ ! -e ${ZINIT[BIN_DIR]}/zinit.zsh ]]; then
    builtin print -P "%F{196}Could not establish ZINIT[BIN_DIR] hash field. It should point where Zinit's Git repository is.%f"
    return 1
fi

# User can override ZINIT[HOME_DIR].
if [[ -z ${ZINIT[HOME_DIR]} ]]; then
    # Search for zinit home in the usual locations
    if [[ -d ${XDG_DATA_HOME:-${HOME}/.local/share}/zinit ]]; then
        ZINIT[HOME_DIR]="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"
    elif [[ -d $HOME/.zinit ]]; then
        ZINIT[HOME_DIR]="$HOME/.zinit"
    elif [[ -d ${ZDOTDIR:-$HOME}/.zinit ]]; then
        ZINIT[HOME_DIR]="${ZDOTDIR:-$HOME}/.zinit"
    elif [[ -d $HOME/.zplugin ]]; then
        ZINIT[HOME_DIR]="$HOME/.zplugin"
    elif [[ -d ${ZDOTDIR:-$HOME}/.zplugin ]]; then
        ZINIT[HOME_DIR]="${ZDOTDIR:-$HOME}/.zplugin"
    else
        ZINIT[HOME_DIR]="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit"
    fi
fi

ZINIT[ice-list]="svn|proto|from|teleid|bindmap|cloneopts|id-as|depth|if|wait|load|\
unload|blockf|pick|bpick|src|as|ver|silent|lucid|notify|mv|cp|\
atinit|atclone|atload|atpull|nocd|run-atpull|has|cloneonly|make|\
service|trackbinds|multisrc|compile|nocompile|nocompletions|\
reset-prompt|wrap|reset|sh|\!sh|bash|\!bash|ksh|\!ksh|csh|\
\!csh|aliases|countdown|ps-on-unload|ps-on-update|trigger-load|\
light-mode|is-snippet|atdelete|pack|git|verbose|on-update-of|\
subscribe|extract|param|opts|autoload|subst|install|pullopts|\
debug|null|binary"
ZINIT[nval-ice-list]="blockf|silent|lucid|trackbinds|cloneonly|nocd|run-atpull|\
nocompletions|sh|\!sh|bash|\!bash|ksh|\!ksh|csh|\!csh|\
aliases|countdown|light-mode|is-snippet|git|verbose|cloneopts|\
pullopts|debug|null|binary|make|nocompile|notify|reset"

# Can be customized.
: ${ZINIT[COMPLETIONS_DIR]:=${ZINIT[HOME_DIR]}/completions}
: ${ZINIT[MODULE_DIR]:=${ZINIT[HOME_DIR]}/module}
: ${ZINIT[PACKAGES_REPO]:=zdharma-continuum/zinit-packages}
: ${ZINIT[PACKAGES_BRANCH]:=HEAD}
: ${ZINIT[PLUGINS_DIR]:=${ZINIT[HOME_DIR]}/plugins}
: ${ZINIT[SERVICES_DIR]:=${ZINIT[HOME_DIR]}/services}
: ${ZINIT[SNIPPETS_DIR]:=${ZINIT[HOME_DIR]}/snippets}
typeset -g ZPFX
: ${ZPFX:=${ZINIT[HOME_DIR]}/polaris}
: ${ZINIT[ALIASES_OPT]::=${${options[aliases]:#off}:+1}}
: ${ZINIT[MAN_DIR]:=${ZPFX}/man}

ZINIT[PLUGINS_DIR]=${~ZINIT[PLUGINS_DIR]}   ZINIT[COMPLETIONS_DIR]=${~ZINIT[COMPLETIONS_DIR]}
ZINIT[SNIPPETS_DIR]=${~ZINIT[SNIPPETS_DIR]} ZINIT[SERVICES_DIR]=${~ZINIT[SERVICES_DIR]}
export ZPFX=${~ZPFX} ZSH_CACHE_DIR="${ZSH_CACHE_DIR:-${XDG_CACHE_HOME:-$HOME/.cache}/zinit}" \
    PMSPEC=0uUpiPsf
[[ -z ${path[(re)$ZPFX/bin]} ]] && [[ -d "$ZPFX/bin" ]] && path=( "$ZPFX/bin" "${path[@]}" )
[[ -z ${path[(re)$ZPFX/sbin]} ]] && [[ -d "$ZPFX/sbin" ]] && path=( "$ZPFX/sbin" "${path[@]}" )

# Add completions directory to fpath.
[[ -z ${fpath[(re)${ZINIT[COMPLETIONS_DIR]}]} ]] && fpath=( "${ZINIT[COMPLETIONS_DIR]}" "${fpath[@]}" )

[[ ! -d $ZSH_CACHE_DIR ]] && command mkdir -p "$ZSH_CACHE_DIR"
[[ -n ${ZINIT[ZCOMPDUMP_PATH]} ]] && ZINIT[ZCOMPDUMP_PATH]=${~ZINIT[ZCOMPDUMP_PATH]}

ZINIT[UPAR]=";:^[[A;:^[OA;:\\e[A;:\\eOA;:${termcap[ku]/$'\e'/^\[};:${terminfo[kcuu1]/$'\e'/^\[};:"
ZINIT[DOWNAR]=";:^[[B;:^[OB;:\\e[B;:\\eOB;:${termcap[kd]/$'\e'/^\[};:${terminfo[kcud1]/$'\e'/^\[};:"
ZINIT[RIGHTAR]=";:^[[C;:^[OC;:\\e[C;:\\eOC;:${termcap[kr]/$'\e'/^\[};:${terminfo[kcuf1]/$'\e'/^\[};:"
ZINIT[LEFTAR]=";:^[[D;:^[OD;:\\e[D;:\\eOD;:${termcap[kl]/$'\e'/^\[};:${terminfo[kcub1]/$'\e'/^\[};:"

builtin autoload -Uz is-at-least
is-at-least 5.1 && ZINIT[NEW_AUTOLOAD]=1 || ZINIT[NEW_AUTOLOAD]=0
#is-at-least 5.4 && ZINIT[NEW_AUTOLOAD]=2

# Parameters - temporary substituting of functions. [[[
ZINIT[TMP_SUBST]=inactive   ZINIT[DTRACE]=0    ZINIT[CUR_PLUGIN]=
# ]]]
# Parameters - ICE. [[[
declare -gA ZINIT_1MAP ZINIT_2MAP
ZINIT_1MAP=(
    OMZ:: https://github.com/ohmyzsh/ohmyzsh/trunk/
    OMZP:: https://github.com/ohmyzsh/ohmyzsh/trunk/plugins/
    OMZT:: https://github.com/ohmyzsh/ohmyzsh/trunk/themes/
    OMZL:: https://github.com/ohmyzsh/ohmyzsh/trunk/lib/
    PZT:: https://github.com/sorin-ionescu/prezto/trunk/
    PZTM:: https://github.com/sorin-ionescu/prezto/trunk/modules/
)
ZINIT_2MAP=(
    OMZ:: https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/
    OMZP:: https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/
    OMZT:: https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/themes/
    OMZL:: https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/lib/
    PZT:: https://raw.githubusercontent.com/sorin-ionescu/prezto/master/
    PZTM:: https://raw.githubusercontent.com/sorin-ionescu/prezto/master/modules/
)
# ]]]

# Init. [[[
zmodload zsh/zutil || { builtin print -P "%F{196}zsh/zutil module is required, aborting Zinit set up.%f"; return 1; }
zmodload zsh/parameter || { builtin print -P "%F{196}zsh/parameter module is required, aborting Zinit set up.%f"; return 1; }
zmodload zsh/terminfo 2>/dev/null
zmodload zsh/termcap 2>/dev/null

if [[ -z $SOURCED && ( ${+terminfo} -eq 1 && -n ${terminfo[colors]} ) || \
      ( ${+termcap} -eq 1 && -n ${termcap[Co]} )
]] {
    ZINIT+=(
        # Old colors: 31m
        col-pname   $'\e[1;4m\e[32m'     col-uname   $'\e[1;4m\e[35m'     col-keyword $'\e[32m'
        col-note    $'\e[38;5;148m'       col-error   $'\e[1m\e[38;5;204m' col-p       $'\e[38;5;81m'
        col-info    $'\e[38;5;82m'       col-info2   $'\e[38;5;227m'      col-profile $'\e[38;5;148m'
        col-uninst  $'\e[38;5;118m'      col-info3   $'\e[1m\e[38;5;227m' col-slight  $'\e[38;5;230m'
        col-failure $'\e[38;5;204m'      col-happy   $'\e[1m\e[38;5;82m'  col-annex   $'\e[38;5;153m'
        col-id-as   $'\e[4;38;5;220m'    col-version $'\e[3;38;5;87m'
        # The more recent, fresh ones:
        col-pre  $'\e[38;5;135m'  col-msg   $'\e[0m'        col-msg2  $'\e[38;5;172m'
        col-obj  $'\e[38;5;218m'  col-obj2  $'\e[38;5;118m' col-file  $'\e[3;38;5;117m'
        col-dir  $'\e[3;38;5;153m' col-func $'\e[38;5;219m'
        col-url  $'\e[38;5;75m'   col-meta  $'\e[38;5;57m'  col-meta2 $'\e[38;5;147m'
        col-data $'\e[38;5;82m'   col-data2 $'\e[38;5;117m' col-hi    $'\e[1m\e[38;5;183m'
        col-var  $'\e[38;5;81m'   col-glob  $'\e[38;5;227m' col-ehi   $'\e[1m\e[38;5;210m'
        col-cmd  $'\e[38;5;82m'   col-ice   $'\e[38;5;39m'  col-nl    $'\n'
        col-txt  $'\e[38;5;254m' col-num  $'\e[3;38;5;155m' col-term  $'\e[38;5;185m'
        col-warn $'\e[38;5;214m'  col-apo $'\e[1;38;5;220m' col-ok    $'\e[38;5;220m'
        col-faint $'\e[38;5;238m' col-opt   $'\e[38;5;219m' col-lhi   $'\e[38;5;81m'
        col-tab  $' \t '            col-msg3  $'\e[38;5;238m' col-b-lhi $'\e[1m\e[38;5;75m'
        col-bar  $'\e[38;5;82m'  col-th-bar $'\e[38;5;82m'
        col-…    "${${${(M)LANG:#*UTF-8*}:+…}:-...}"  col-ndsh  "${${${(M)LANG:#*UTF-8*}:+–}:-}"
        col-mdsh $'\e[1;38;5;220m'"${${${(M)LANG:#*UTF-8*}:+–}:--}"$'\e[0m'
        col-mmdsh $'\e[1;38;5;220m'"${${${(M)LANG:#*UTF-8*}:+――}:--}"$'\e[0m'
        col--…   "${${${(M)LANG:#*UTF-8*}:+⋯⋯}:-···}" col-lr    "${${${(M)LANG:#*UTF-8*}:+↔}:-"«-»"}"
        col-↔    ${${${(M)LANG:#*UTF-8*}:+$'\e[38;5;82m↔\e[0m'}:-$'\e[38;5;82m«-»\e[0m'}
        col-rst  $'\e[0m'        col-b     $'\e[1m'        col-nb     $'\e[22m'
        col-u    $'\e[4m'        col-it    $'\e[3m'        col-st     $'\e[9m'
        col-nu   $'\e[24m'       col-nit   $'\e[23m'       col-nst    $'\e[29m'
        col-bspc $'\b'        col-b-warn $'\e[1;38;5;214m' col-u-warn $'\e[4;38;5;214m'
    )
    if [[ ( ${+terminfo} -eq 1 && ${terminfo[colors]} -ge 256 ) || \
          ( ${+termcap} -eq 1 && ${termcap[Co]} -ge 256 )
    ]] {
        ZINIT+=( col-pname $'\e[1;4m\e[38;5;39m' col-uname  $'\e[1;4m\e[38;5;207m' )
    }
}

# List of hooks.
typeset -gAH ZINIT_ZLE_HOOKS_LIST
ZINIT_ZLE_HOOKS_LIST=(
    zle-isearch-exit 1
    zle-isearch-update 1
    zle-line-pre-redraw 1
    zle-line-init 1
    zle-line-finish 1
    zle-history-line-set 1
    zle-keymap-select 1
    paste-insert 1
)

builtin setopt noaliases

# ]]]

#
# Temporary substituting of functions-related functions.
#

# FUNCTION: :zinit-reload-and-run. [[[
# Marks given function ($3) for autoloading, and executes it triggering the
# load. $1 is the fpath dedicated to the function, $2 are autoload options.
# This function replaces "autoload -X", because using that on older Zsh
# versions causes problems with traps.
#
# So basically one creates function stub that calls :zinit-reload-and-run()
# instead of "autoload -X".
#
# $1 - FPATH dedicated to function
# $2 - autoload options
# $3 - function name (one that needs autoloading)
#
# Author: Bart Schaefer
:zinit-reload-and-run () {
    local fpath_prefix="$1" autoload_opts="$2" func="$3"
    shift 3

    # Unfunction caller function (its name is given).
    unfunction -- "$func"

    local -a ___fpath
    ___fpath=( ${fpath[@]} )
    local -a +h fpath
    # See #127.
    [[ $FPATH != *${${(@0)fpath_prefix}[1]}* ]] && \
        fpath=( ${(@0)fpath_prefix} ${___fpath[@]} )

    # After this the function exists again.
    builtin autoload ${(s: :)autoload_opts} -- "$func"

    # User wanted to call the function, not only load it.
    "$func" "$@"
} # ]]]
# FUNCTION: :zinit-tmp-subst-autoload. [[[
# Function defined to hijack plugin's calls to the `autoload' builtin.
#
# The hijacking is not only to gather report data, but also to.
# run custom `autoload' function, that doesn't need FPATH.
:zinit-tmp-subst-autoload () {
    emulate -LR zsh
    builtin setopt extendedglob warncreateglobal typesetsilent rcquotes
    local -a opts opts2 custom reply
    local func

    zparseopts -D -E -M -a opts ${(s::):-RTUXdkmrtWzwC} I+=opts2 S+:=custom

    builtin set -- ${@:#--}

    # Process the id-as''/teleid'' to get the plugin dir.
    .zinit-any-to-user-plugin $ZINIT[CUR_USPL2]
    [[ $reply[1] = % ]] && \
        local PLUGIN_DIR="$reply[2]" || \
        local PLUGIN_DIR="$ZINIT[PLUGINS_DIR]/${reply[1]:+$reply[1]---}${reply[2]//\//---}"


    # "fpath elements" ----  those elements that lie inside the plug directory.
    local -a fpath_elements
    fpath_elements=( ${fpath[(r)$PLUGIN_DIR/*]} )

    # Add a function subdirectory to items, if any (this action is
    # according to the Plug Standard version 1.07 and later).
    [[ -d $PLUGIN_DIR/functions ]] && fpath_elements+=( "$PLUGIN_DIR"/functions )

    if (( ${+opts[(r)-X]} )); then
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: Failed autoload ${(j: :)opts[@]} $*"
        +zinit-message -u2 "{error}builtin autoload required for {obj}${(j: :)opts[@]}{error} option(s)"
        return 1
    fi
    if (( ${+opts[(r)-w]} )); then
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "-w-Autoload ${(j: :)opts[@]} ${(j: :)@}"
        fpath+=( $PLUGIN_DIR )
        builtin autoload ${opts[@]} "$@"
        return $?
    fi
    if [[ -n ${(M)@:#+X} ]]; then
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Autoload +X ${opts:+${(j: :)opts[@]} }${(j: :)${@:#+X}}"
        local +h FPATH=$PLUGINS_DIR${fpath_elements:+:${(j.:.)fpath_elements[@]}}:$FPATH
        local +h -a fpath
        fpath=( $PLUGIN_DIR $fpath_elements $fpath )
        builtin autoload +X ${opts[@]} "${@:#+X}"
        return $?
    fi

    for func; do
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Autoload $func${opts:+ with options ${(j: :)opts[@]}}"
    done

    integer count retval
    for func; do
        # Real autoload doesn't touch function if it already exists.
        # Author of the idea of FPATH-clean autoloading: Bart Schaefer.
        if (( ${+functions[$func]} != 1 )) {
            builtin setopt noaliases
            if [[ $func == /* ]] && is-at-least 5.4; then
                builtin autoload ${opts[@]} $func
                return $?
            elif [[ $func == /* ]]; then
                if [[ $ZINIT[MUTE_WARNINGS] != (1|true|on|yes) && \
                        -z $ZINIT[WARN_SHOWN_FOR_$ZINIT[CUR_USPL2]] ]]; then
                    +zinit-message "{u-warn}Warning{b-warn}: {rst}the plugin {pid}$ZINIT[CUR_USPL2]" \
                        "{rst}is using autoload functions specified by their absolute path," \
                        "which is not supported by this Zsh version ({↔} {version}$ZSH_VERSION{rst}," \
                        "required is Zsh >= {version}5.4{rst})." \
                        "{nl}A fallback mechanism has been applied, which works well only" \
                        "for functions in the plugin {u}{slight}main{rst} directory." \
                        "{nl}(To mute this message, set" \
                        "{var}\$ZINIT[MUTE_WARNINGS]{rst} to a truth value.)"
                    ZINIT[WARN_SHOWN_FOR_$ZINIT[CUR_USPL2]]=1
                fi

                # Workaround
                func=$func:t
            fi
            if [[ ${ZINIT[NEW_AUTOLOAD]} = 2 ]]; then
                builtin autoload ${opts[@]} "$PLUGIN_DIR/$func"
                retval=$?
            elif [[ ${ZINIT[NEW_AUTOLOAD]} = 1 ]]; then
                if (( ${+opts[(r)-C]} )) {
                    local pth nl=$'\n' sel=""
                    for pth ( $PLUGIN_DIR $fpath_elements $fpath ) {
                        [[ -f $pth/$func ]] && { sel=$pth; break; }
                    }
                    if [[ -z $sel ]] {
                        +zinit-message '{u-warn}zinit{b-warn}:{error} Couldn''t find autoload function{ehi}:' \
                            "{apo}\`{file}${func}{apo}\`{error} anywhere in {var}\$fpath{error}."
                            retval=1
                    } else {
                        eval "function ${(q)${custom[++count*2]}:-$func} {
                            local body=\"\$(<${(qqq)sel}/${(qqq)func})\" body2
                            () { setopt localoptions extendedglob
                                 body2=\"\${body##[[:space:]]#${func}[[:blank:]]#\(\)[[:space:]]#\{}\"
                                 [[ \$body2 != \$body ]] && \
                                    body2=\"\${body2%\}[[:space:]]#([$nl]#([[:blank:]]#\#[^$nl]#((#e)|[$nl]))#)#}\"
                            }

                            functions[${${(q)custom[count*2]}:-$func}]=\"\$body2\"
                            ${(q)${custom[count*2]}:-$func} \"\$@\"
                        }"
                        retval=$?
                    }
                } else {
                    eval "function ${(q)func} {
                        local -a fpath
                        fpath=( ${(qqq)PLUGIN_DIR} ${(qqq@)fpath_elements} ${(qqq@)fpath} )
                        builtin autoload -X ${(j: :)${(q-)opts[@]}}
                    }"
                    retval=$?
                }
            else
                eval "function ${(q)func} {
                    :zinit-reload-and-run ${(qqq)PLUGIN_DIR}"$'\0'"${(pj,\0,)${(qqq)fpath_elements[@]}} ${(qq)opts[*]} ${(q)func} "'"$@"
                }'
                retval=$?
            fi
            (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases
        }
        if (( ${+opts2[(r)-I]} )) {
            ${custom[count*2]:-$func}
            retval=$?
        }
    done

    return $retval
} # ]]]
# FUNCTION: :zinit-tmp-subst-bindkey. [[[
# Function defined to hijack plugin's calls to the `bindkey' builtin.
#
# The hijacking is to gather report data (which is used in unload).
:zinit-tmp-subst-bindkey() {
    emulate -LR zsh
    builtin setopt extendedglob warncreateglobal typesetsilent noshortloops

    is-at-least 5.3 && \
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Bindkey ${(j: :)${(q+)@}}" || \
        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Bindkey ${(j: :)${(q)@}}"

    # Remember to perform the actual bindkey call.
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular bindkey call, i.e.
    # with no options or with -s, plus possible -M
    # option.
    local -A opts
    zparseopts -A opts -D ${(s::):-lLdDAmrsevaR} M: N:

    if (( ${#opts} == 0 ||
        ( ${#opts} == 1 && ${+opts[-M]} ) ||
        ( ${#opts} == 1 && ${+opts[-R]} ) ||
        ( ${#opts} == 1 && ${+opts[-s]} ) ||
        ( ${#opts} <= 2 && ${+opts[-M]} && ${+opts[-s]} ) ||
        ( ${#opts} <= 2 && ${+opts[-M]} && ${+opts[-R]} )
    )); then
        local string="${(q)1}" widget="${(q)2}"
        local quoted

        if [[ -n ${ICE[bindmap]} && ${ZINIT_CUR_BIND_MAP[empty]} -eq 1 ]]; then
            local -a pairs
            pairs=( "${(@s,;,)ICE[bindmap]}" )
            if [[ -n ${(M)pairs:#*\\(#e)} ]] {
                local prev
                pairs=( ${pairs[@]//(#b)((*)\\(#e)|(*))/${match[3]:+${prev:+$prev\;}}${match[3]}${${prev::=${match[2]:+${prev:+$prev\;}}${match[2]}}:+}} )
            }
            pairs=( "${(@)${(@)${(@s:->:)pairs}##[[:space:]]##}%%[[:space:]]##}" )
            ZINIT_CUR_BIND_MAP=( empty 0 )
            (( ${#pairs} > 1 && ${#pairs[@]} % 2 == 0 )) && ZINIT_CUR_BIND_MAP+=( "${pairs[@]}" )
        fi

        local bmap_val="${ZINIT_CUR_BIND_MAP[${1}]}"
        if (( !ZINIT_CUR_BIND_MAP[empty] )) {
            [[ -z $bmap_val ]] && bmap_val="${ZINIT_CUR_BIND_MAP[${(qqq)1}]}"
            [[ -z $bmap_val ]] && bmap_val="${ZINIT_CUR_BIND_MAP[${(qqq)${(Q)1}}]}"
            [[ -z $bmap_val ]] && { bmap_val="${ZINIT_CUR_BIND_MAP[!${(qqq)1}]}"; integer val=1; }
            [[ -z $bmap_val ]] && bmap_val="${ZINIT_CUR_BIND_MAP[!${(qqq)${(Q)1}}]}"
        }
        if [[ -n $bmap_val ]]; then
            string="${(q)bmap_val}"
            if (( val )) {
                [[ ${pos[1]} = "-M" ]] && pos[4]="$bmap_val" || pos[2]="$bmap_val"
            } else {
                [[ ${pos[1]} = "-M" ]] && pos[3]="${(Q)bmap_val}" || pos[1]="${(Q)bmap_val}"
            }
            .zinit-add-report "${ZINIT[CUR_USPL2]}" ":::Bindkey: combination <$1> changed to <$bmap_val>${${(M)bmap_val:#hold}:+, i.e. ${ZINIT[col-error]}unmapped${ZINIT[col-rst]}}"
            ((1))
        elif [[ ( -n ${bmap_val::=${ZINIT_CUR_BIND_MAP[UPAR]}} && -n ${${ZINIT[UPAR]}[(r);:${(q)1};:]} ) || \
                ( -n ${bmap_val::=${ZINIT_CUR_BIND_MAP[DOWNAR]}} && -n ${${ZINIT[DOWNAR]}[(r);:${(q)1};:]} ) || \
                ( -n ${bmap_val::=${ZINIT_CUR_BIND_MAP[RIGHTAR]}} && -n ${${ZINIT[RIGHTAR]}[(r);:${(q)1};:]} ) || \
                ( -n ${bmap_val::=${ZINIT_CUR_BIND_MAP[LEFTAR]}} && -n ${${ZINIT[LEFTAR]}[(r);:${(q)1};:]} )
        ]]; then
            string="${(q)bmap_val}"
            if (( val )) {
                [[ ${pos[1]} = "-M" ]] && pos[4]="$bmap_val" || pos[2]="$bmap_val"
            } else {
                [[ ${pos[1]} = "-M" ]] && pos[3]="${(Q)bmap_val}" || pos[1]="${(Q)bmap_val}"
            }
            .zinit-add-report "${ZINIT[CUR_USPL2]}" ":::Bindkey: combination <$1> recognized as cursor-key and changed to <${bmap_val}>${${(M)bmap_val:#hold}:+, i.e. ${ZINIT[col-error]}unmapped${ZINIT[col-rst]}}"
        fi
        [[ $bmap_val = hold ]] && return 0

        local prev="${(q)${(s: :)$(builtin bindkey ${(Q)string})}[-1]#undefined-key}"

        # "-M map" given?
        if (( ${+opts[-M]} )); then
            local Mopt=-M
            local Marg="${opts[-M]}"

            Mopt="${(q)Mopt}"
            Marg="${(q)Marg}"

            quoted="$string $widget $prev $Mopt $Marg"
        else
            quoted="$string $widget $prev"
        fi

        # -R given?
        if (( ${+opts[-R]} )); then
            local Ropt=-R
            Ropt="${(q)Ropt}"

            if (( ${+opts[-M]} )); then
                quoted="$quoted $Ropt"
            else
                # Two empty fields for non-existent -M arg.
                local space=_
                space="${(q)space}"
                quoted="$quoted $space $space $Ropt"
            fi
        fi

        quoted="${(q)quoted}"

        # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here).
        [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[BINDKEYS__${ZINIT[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace.
        [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[BINDKEYS___dtrace/_dtrace]+="$quoted "
    else
        # bindkey -A newkeymap main?
        # Negative indices for KSH_ARRAYS immunity.
        if [[ ${#opts} -eq 1 && ${+opts[-A]} = 1 && ${#pos} = 3 && ${pos[-1]} = main && ${pos[-2]} != -A ]]; then
            # Save a copy of main keymap.
            (( ZINIT[BINDKEY_MAIN_IDX] = ${ZINIT[BINDKEY_MAIN_IDX]:-0} + 1 ))
            local pname="${ZINIT[CUR_PLUGIN]:-_dtrace}"
            local name="${(q)pname}-main-${ZINIT[BINDKEY_MAIN_IDX]}"
            builtin bindkey -N "$name" main

            # Remember occurence of main keymap substitution, to revert on unload.
            local keys=_ widget=_ prev= optA=-A mapname="${name}" optR=_
            local quoted="${(q)keys} ${(q)widget} ${(q)prev} ${(q)optA} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here).
            [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[BINDKEYS__${ZINIT[CUR_USPL2]}]+="$quoted "
            [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[BINDKEYS___dtrace/_dtrace]+="$quoted "

            .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: keymap \`main' copied to \`${name}' because of \`${pos[-2]}' substitution"
        # bindkey -N newkeymap [other].
        elif [[ ${#opts} -eq 1 && ${+opts[-N]} = 1 ]]; then
            local Nopt=-N
            local Narg="${opts[-N]}"

            local keys=_ widget=_ prev= optN=-N mapname="${Narg}" optR=_
            local quoted="${(q)keys} ${(q)widget} ${(q)prev} ${(q)optN} ${(q)mapname} ${(q)optR}"
            quoted="${(q)quoted}"

            # Remember the bindkey, only when load is in progress (it can be dstart that leads execution here).
            [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[BINDKEYS__${ZINIT[CUR_USPL2]}]+="$quoted "
            [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[BINDKEYS___dtrace/_dtrace]+="$quoted "
        else
            .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: last bindkey used non-typical options: ${(kv)opts[*]}"
        fi
    fi

    # Actual bindkey.
    builtin bindkey "${pos[@]}"
    return $? # testable
} # ]]]
# FUNCTION: :zinit-tmp-subst-zstyle. [[[
# Function defined to hijack plugin's calls to the `zstyle' builtin.
#
# The hijacking is to gather report data (which is used in unload).
:zinit-tmp-subst-zstyle() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob nowarncreateglobal \
        typesetsilent noshortloops unset
    .zinit-add-report "${ZINIT[CUR_USPL2]}" "Zstyle $*"

    # Remember in order to perform the actual zstyle call.
    typeset -a pos
    pos=( "$@" )

    # Check if we have regular zstyle call, i.e.
    # with no options or with -e.
    local -a opts
    zparseopts -a opts -D ${(s::):-eLdgabsTtm}

    if [[ ${#opts} -eq 0 || ( ${#opts} -eq 1 && ${+opts[(r)-e]} = 1 ) ]]; then
        # Have to quote $1, then $2, then concatenate them, then quote them again.
        local pattern="${(q)1}" style="${(q)2}"
        local ps="$pattern $style"
        ps="${(q)ps}"

        # Remember the zstyle, only when load is in progress (it can be dstart that leads execution here).
        [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[ZSTYLES__${ZINIT[CUR_USPL2]}]+="$ps "
        # Remember for dtrace.
        [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[ZSTYLES___dtrace/_dtrace]+=$ps
    else
        if [[ ! ${#opts[@]} = 1 && ( ${+opts[(r)-s]} = 1 || ${+opts[(r)-b]} = 1 || ${+opts[(r)-a]} = 1 ||
              ${+opts[(r)-t]} = 1 || ${+opts[(r)-T]} = 1 || ${+opts[(r)-m]} = 1 )
        ]]; then
            .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: last zstyle used non-typical options: ${opts[*]}"
        fi
    fi

    # Actual zstyle.
    builtin zstyle "${pos[@]}"
    return $? # testable
} # ]]]
# FUNCTION: :zinit-tmp-subst-alias. [[[
# Function defined to hijack plugin's calls to the `alias' builtin.
#
# The hijacking is to gather report data (which is used in unload).
:zinit-tmp-subst-alias() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    .zinit-add-report "${ZINIT[CUR_USPL2]}" "Alias $*"

    # Remember to perform the actual alias call.
    typeset -a pos
    pos=( "$@" )

    local -a opts
    zparseopts -a opts -D ${(s::):-gs}

    local a quoted tmp
    for a in "$@"; do
        local aname="${a%%[=]*}"
        local avalue="${a#*=}"

        # Check if alias is to be redefined.
        (( ${+aliases[$aname]} )) && .zinit-add-report "${ZINIT[CUR_USPL2]}" "Warning: redefining alias \`${aname}', previous value: ${aliases[$aname]}"

        local bname=${(q)aliases[$aname]}
        aname="${(q)aname}"

        if (( ${+opts[(r)-s]} )); then
            tmp=-s
            tmp="${(q)tmp}"
            quoted="$aname $bname $tmp"
        elif (( ${+opts[(r)-g]} )); then
            tmp=-g
            tmp="${(q)tmp}"
            quoted="$aname $bname $tmp"
        else
            quoted="$aname $bname"
        fi

        quoted="${(q)quoted}"

        # Remember the alias, only when load is in progress (it can be dstart that leads execution here).
        [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[ALIASES__${ZINIT[CUR_USPL2]}]+="$quoted "
        # Remember for dtrace.
        [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[ALIASES___dtrace/_dtrace]+="$quoted "
    done

    # Actual alias.
    builtin alias "${pos[@]}"
    return $? # testable
} # ]]]
# FUNCTION: :zinit-tmp-subst-zle. [[[.
# Function defined to hijack plugin's calls to the `zle' builtin.
#
# The hijacking is to gather report data (which is used in unload).
:zinit-tmp-subst-zle() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    .zinit-add-report "${ZINIT[CUR_USPL2]}" "Zle $*"

    # Remember to perform the actual zle call.
    typeset -a pos
    pos=( "$@" )

    builtin set -- "${@:#--}"

    # Try to catch game-changing "-N".
    if [[ ( $1 = -N && ( $# = 2 || $# = 3 ) ) || ( $1 = -C && $# = 4 ) ]]; then
            # Hooks.
            if [[ ${ZINIT_ZLE_HOOKS_LIST[$2]} = 1 ]]; then
                local quoted="$2"
                quoted="${(q)quoted}"
                # Remember only when load is in progress (it can be dstart that leads execution here).
                [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[WIDGETS_DELETE__${ZINIT[CUR_USPL2]}]+="$quoted "
                # Remember for dtrace.
                [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[WIDGETS_DELETE___dtrace/_dtrace]+="$quoted "
            # These will be saved and restored.
            elif (( ${+widgets[$2]} )); then
                # Have to remember original widget "$2" and
                # the copy that it's going to be done.
                local widname="$2" targetfun="${${${(M)1:#-C}:+$4}:-$3}"
                local completion_widget="${${(M)1:#-C}:+$3}"
                local saved_widcontents="${widgets[$widname]}"

                widname="${(q)widname}"
                completion_widget="${(q)completion_widget}"
                targetfun="${(q)targetfun}"
                saved_widcontents="${(q)saved_widcontents}"
                local quoted="$1 $widname $completion_widget $targetfun $saved_widcontents"
                quoted="${(q)quoted}"
                # Remember only when load is in progress (it can be dstart that leads execution here).
                [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[WIDGETS_SAVED__${ZINIT[CUR_USPL2]}]+="$quoted "
                # Remember for dtrace.
                [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[WIDGETS_SAVED___dtrace/_dtrace]+="$quoted "
             # These will be deleted.
             else
                 .zinit-add-report "${ZINIT[CUR_USPL2]}" "Note: a new widget created via zle -N: \`$2'"
                 local quoted="$2"
                 quoted="${(q)quoted}"
                 # Remember only when load is in progress (it can be dstart that leads execution here).
                 [[ -n ${ZINIT[CUR_USPL2]} ]] && ZINIT[WIDGETS_DELETE__${ZINIT[CUR_USPL2]}]+="$quoted "
                 # Remember for dtrace.
                 [[ ${ZINIT[DTRACE]} = 1 ]] && ZINIT[WIDGETS_DELETE___dtrace/_dtrace]+="$quoted "
             fi
    fi

    # Actual zle.
    builtin zle "${pos[@]}"
    return $? # testable
} # ]]]
# FUNCTION: :zinit-tmp-subst-compdef. [[[
# Function defined to hijack plugin's calls to the `compdef' function.
# The hijacking is not only for reporting, but also to save compdef
# calls so that `compinit' can be called after loading plugins.
:zinit-tmp-subst-compdef() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset
    .zinit-add-report "${ZINIT[CUR_USPL2]}" "Saving \`compdef $*' for replay"
    ZINIT_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" )

    return 0 # testable
} # ]]]
# FUNCTION: .zinit-tmp-subst-on. [[[
# Turn on temporary substituting of functions of builtins and functions according to passed
# mode ("load", "light", "light-b" or "compdef"). The temporary substituting of functions is
# to gather report data, and to hijack `autoload', `bindkey' and
# `compdef' calls.
.zinit-tmp-subst-on() {
    local mode="$1"

    # Enable temporary substituting of functions only once.
    #
    # One could expect possibility of widening of temporary substituting of functions, however
    # such sequence doesn't exist, e.g. "light" then "load"/"dtrace", "compdef" then "load"/
    # "dtrace", "light" then "compdef", "compdef" then "light".
    #
    # It is always "dtrace" then "load" (i.e. dtrace then load) "dtrace" then "light" (i.e.:
    # dtrace then light load) "dtrace" then "compdef" (i.e.: dtrace then snippet).
    [[ ${ZINIT[TMP_SUBST]} != inactive ]] && builtin return 0

    ZINIT[TMP_SUBST]="$mode"

    # The point about backuping is: does the key exist in functions array.
    # If it does exist, then it will also exist as ZINIT[bkp-*].

    # Defensive code, shouldn't be needed.
    builtin unset "ZINIT[bkp-autoload]" "ZINIT[bkp-compdef]"  # 0, E.

    if [[ $mode != compdef ]]; then
        # 0. Used, but not in temporary restoration, which doesn't happen for autoload.
        (( ${+functions[autoload]} )) && ZINIT[bkp-autoload]="${functions[autoload]}"
        functions[autoload]=':zinit-tmp-subst-autoload "$@";'
    fi

    # E. Always shade compdef.
    (( ${+functions[compdef]} )) && ZINIT[bkp-compdef]="${functions[compdef]}"
    functions[compdef]=':zinit-tmp-subst-compdef "$@";'

    # Temporarily replace `source' if subst'' given.
    if [[ -n ${ICE[subst]} ]] {
        (( ${+functions[source]} )) && ZINIT[bkp-source]="${functions[source]}"
        (( ${+functions[.]} )) && ZINIT[bkp-.]="${functions[.]}"
        (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
        functions[source]=':zinit-tmp-subst-source "$@";'
        functions[.]=':zinit-tmp-subst-source "$@";'
    }

    # Light and compdef temporary substituting of functions stops here. Dtrace and load go on.
    [[ ( $mode = light && ${+ICE[trackbinds]} -eq 0 ) || $mode = compdef ]] && return 0

    # Defensive code, shouldn't be needed. A, B, C, D.
    builtin unset "ZINIT[bkp-bindkey]" "ZINIT[bkp-zstyle]" "ZINIT[bkp-alias]" "ZINIT[bkp-zle]"

    # A.
    (( ${+functions[bindkey]} )) && ZINIT[bkp-bindkey]="${functions[bindkey]}"
    functions[bindkey]=':zinit-tmp-subst-bindkey "$@";'

    # B, when `zinit light -b ...' or when `zinit ice trackbinds ...; zinit light ...'.
    [[ $mode = light-b || ( $mode = light && ${+ICE[trackbinds]} -eq 1 ) ]] && return 0

    # B.
    (( ${+functions[zstyle]} )) && ZINIT[bkp-zstyle]="${functions[zstyle]}"
    functions[zstyle]=':zinit-tmp-subst-zstyle "$@";'

    # C.
    (( ${+functions[alias]} )) && ZINIT[bkp-alias]="${functions[alias]}"
    functions[alias]=':zinit-tmp-subst-alias "$@";'

    # D.
    (( ${+functions[zle]} )) && ZINIT[bkp-zle]="${functions[zle]}"
    functions[zle]=':zinit-tmp-subst-zle "$@";'

    builtin return 0
} # ]]]
# FUNCTION: .zinit-tmp-subst-off. [[[
# Turn off temporary substituting of functions completely for a given mode ("load", "light",
# "light-b" (i.e. the `trackbinds' mode) or "compdef").
.zinit-tmp-subst-off() {
    builtin setopt localoptions noerrreturn noerrexit extendedglob warncreateglobal \
        typesetsilent noshortloops unset noaliases
    local mode="$1"

    # Disable temporary substituting of functions only once.
    # Disable temporary substituting of functions only the way it was enabled first.
    [[ ${ZINIT[TMP_SUBST]} = inactive || ${ZINIT[TMP_SUBST]} != $mode ]] && return 0

    ZINIT[TMP_SUBST]=inactive

    if [[ $mode != compdef ]]; then
        # 0. Unfunction autoload.
        (( ${+ZINIT[bkp-autoload]} )) && functions[autoload]="${ZINIT[bkp-autoload]}" || unfunction autoload
    fi

    # E. Restore original compdef if it existed.
    (( ${+ZINIT[bkp-compdef]} )) && functions[compdef]="${ZINIT[bkp-compdef]}" || unfunction compdef

    # Restore the possible source function.
    (( ${+ZINIT[bkp-source]} )) && functions[source]="${ZINIT[bkp-source]}" || unfunction source 2>/dev/null
    (( ${+ZINIT[bkp-.]} )) && functions[.]="${ZINIT[bkp-.]}" || unfunction . 2> /dev/null

    # Light and compdef temporary substituting of functions stops here.
    [[ ( $mode = light && ${+ICE[trackbinds]} -eq 0 ) || $mode = compdef ]] && return 0

    # Unfunction temporary substituting of functions functions.

    # A.
    (( ${+ZINIT[bkp-bindkey]} )) && functions[bindkey]="${ZINIT[bkp-bindkey]}" || unfunction bindkey

    # When `zinit light -b ...' or when `zinit ice trackbinds ...; zinit light ...'.
    [[ $mode = light-b || ( $mode = light && ${+ICE[trackbinds]} -eq 1 ) ]] && return 0

    # B.
    (( ${+ZINIT[bkp-zstyle]} )) && functions[zstyle]="${ZINIT[bkp-zstyle]}" || unfunction zstyle
    # C.
    (( ${+ZINIT[bkp-alias]} )) && functions[alias]="${ZINIT[bkp-alias]}" || unfunction alias
    # D.
    (( ${+ZINIT[bkp-zle]} )) && functions[zle]="${ZINIT[bkp-zle]}" || unfunction zle

    return 0
} # ]]]
# FUNCTION: pmodload. [[[
# {function:pmodload} Compatibility with Prezto. Calls can be recursive.
(( ${+functions[pmodload]} )) || pmodload() {
    local -A ices
    (( ${+ICE} )) && ices=( "${(kv)ICE[@]}" teleid '' )
    local -A ICE ZINIT_ICE
    ICE=( "${(kv)ices[@]}" ) ZINIT_ICE=( "${(kv)ices[@]}" )
    while (( $# )); do
        ICE[teleid]="PZT::modules/$1${ICE[svn]-/init.zsh}"
        ZINIT_ICE[teleid]="PZT::modules/$1${ICE[svn]-/init.zsh}"
        if zstyle -t ":prezto:module:$1" loaded 'yes' 'no'; then
            shift
            continue
        else
            [[ -z ${ZINIT_SNIPPETS[PZT::modules/$1${ICE[svn]-/init.zsh}]} && -z ${ZINIT_SNIPPETS[https://github.com/sorin-ionescu/prezto/trunk/modules/$1${ICE[svn]-/init.zsh}]} ]] && .zinit-load-snippet PZT::modules/"$1${ICE[svn]-/init.zsh}"
            shift
        fi
    done
}
# ]]]

#
# Diff functions.
#

# FUNCTION: .zinit-diff-functions. [[[
# Implements detection of newly created functions. Performs
# data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
.zinit-diff-functions() {
    local uspl2="$1"
    local cmd="$2"

    [[ $cmd = begin ]] && \
        { [[ -z ${ZINIT[FUNCTIONS_BEFORE__$uspl2]} ]] && \
                ZINIT[FUNCTIONS_BEFORE__$uspl2]="${(j: :)${(qk)functions[@]}}"
        } || \
            ZINIT[FUNCTIONS_AFTER__$uspl2]+=" ${(j: :)${(qk)functions[@]}}"
} # ]]]
# FUNCTION: .zinit-diff-options. [[[
# Implements detection of change in option state. Performs
# data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
.zinit-diff-options() {
    local IFS=" "

    [[ $2 = begin ]] && \
        { [[ -z ${ZINIT[OPTIONS_BEFORE__$uspl2]} ]] && \
            ZINIT[OPTIONS_BEFORE__$1]="${(kv)options[@]}"
        } || \
        ZINIT[OPTIONS_AFTER__$1]+=" ${(kv)options[@]}"
} # ]]]
# FUNCTION: .zinit-diff-env. [[[
# Implements detection of change in PATH and FPATH.
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
.zinit-diff-env() {
    typeset -a tmp
    local IFS=" "

    [[ $2 = begin ]] && {
            { [[ -z ${ZINIT[PATH_BEFORE__$uspl2]} ]] && \
                tmp=( "${(q)path[@]}" )
                ZINIT[PATH_BEFORE__$1]="${tmp[*]}"
            }
            { [[ -z ${ZINIT[FPATH_BEFORE__$uspl2]} ]] && \
                tmp=( "${(q)fpath[@]}" )
                ZINIT[FPATH_BEFORE__$1]="${tmp[*]}"
            }
    } || {
            tmp=( "${(q)path[@]}" )
            ZINIT[PATH_AFTER__$1]+=" ${tmp[*]}"
            tmp=( "${(q)fpath[@]}" )
            ZINIT[FPATH_AFTER__$1]+=" ${tmp[*]}"
    }
} # ]]]
# FUNCTION: .zinit-diff-parameter. [[[
# Implements detection of change in any parameter's existence and type.
# Performs data gathering, computation is done in *-compute().
#
# $1 - user/plugin (i.e. uspl2 format)
# $2 - command, can be "begin" or "end"
.zinit-diff-parameter() {
    typeset -a tmp

    [[ $2 = begin ]] && {
        { [[ -z ${ZINIT[PARAMETERS_BEFORE__$uspl2]} ]] && \
            ZINIT[PARAMETERS_BEFORE__$1]="${(j: :)${(qkv)parameters[@]}}"
        }
    } || {
        ZINIT[PARAMETERS_AFTER__$1]+=" ${(j: :)${(qkv)parameters[@]}}"
    }
} # ]]]
# FUNCTION: .zinit-diff. [[[
# Performs diff actions of all types
.zinit-diff() {
    .zinit-diff-functions "$1" "$2"
    .zinit-diff-options "$1" "$2"
    .zinit-diff-env "$1" "$2"
    .zinit-diff-parameter "$1" "$2"
}
# ]]]

#
# Utility functions.
#

# FUNCTION: .zinit-get-mtime-into. [[[
.zinit-get-mtime-into() {
    if (( ZINIT[HAVE_ZSTAT] )) {
        local -a arr
        { zstat +mtime -A arr "$1"; } 2>/dev/null
        : ${(P)2::="${arr[1]}"}
    } else {
        { : ${(P)2::="$(stat -c %Y "$1")"}; } 2>/dev/null
    }
} # ]]]
# FUNCTION: .zinit-any-to-user-plugin. [[[
# Allows elastic plugin-spec across the code.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin (only when $1 - i.e. user - given)
#
# Returns user and plugin in $reply.
#
.zinit-any-to-user-plugin() {
    emulate -LR zsh
    builtin setopt extendedglob typesetsilent noshortloops rcquotes \
         ${${${+reply}:#0}:+warncreateglobal}

    # Two components given?
    # That's a pretty fast track to call this function this way.
    if [[ -n $2 ]]; then
        2=${~2}
        reply=( ${1:-${${(M)2#/}:+%}} ${${${(M)1#%}:+$2}:-${2//---//}} )
        return 0
    fi

    # Is it absolute path?
    if [[ $1 = /* ]]; then
        reply=( % $1 )
        return 0
    fi

    # Is it absolute path in zinit format?
    if [[ $1 = %* ]]; then
        local -A map
        map=( ZPFX "$ZPFX" HOME $HOME SNIPPETS $ZINIT[SNIPPETS_DIR] PLUGINS $ZINIT[PLUGINS_DIR] )
        reply=( % ${${1/(#b)(#s)%(${(~j:|:)${(@k)map}}|)/$map[$match[1]]}} )
        reply[2]=${~reply[2]}
        return 0
    fi

    # Rest is for single component given.
    # It doesn't touch $2

    1=${1//---//}
    if [[ $1 = */* ]]; then
        reply=( ${1%%/*} ${1#*/} )
        return 0
    fi

    reply=( "" "${1:-_unknown}" )

    return 0
} # ]]]
# FUNCTION: .zinit-any-to-pid. [[[
.zinit-any-to-pid() {
    emulate -LR zsh
    builtin setopt extendedglob typesetsilent noshortloops rcquotes \
         ${${${+REPLY}:#0}:+warncreateglobal}

    1=${~1} 2=${~2}

    # Two components given?
    if [[ -n $2 ]] {
        if [[ $1 == (%|/)* || ( -z $1 && $2 == /* ) ]] {
            .zinit-util-shands-path $1${${(M)1#(%/?|%[^/]|/?)}:+/}$2
            REPLY=${${REPLY:#%*}:+%}$REPLY
        } else {
            REPLY=$1${1:+/}$2
        }
        return 0
    }

    # Is it absolute path?
    if [[ $1 = (%|/|\~)* ]] {
        .zinit-util-shands-path $1
        REPLY=${${REPLY:#%*}:+%}$REPLY
        return 0
    }

    # Single component given.
    REPLY=${1//---//}

    return 0
} # ]]]
# FUNCTION: .zinit-util-shands-path. [[[
# Replaces parts of path with %HOME, etc.
.zinit-util-shands-path() {
    emulate -LR zsh
    builtin setopt extendedglob typesetsilent noshortloops rcquotes \
         ${${${+REPLY}:#0}:+warncreateglobal}

    local -A map
    map=( \~ %HOME $HOME %HOME $ZINIT[SNIPPETS_DIR] %SNIPPETS $ZINIT[PLUGINS_DIR] %PLUGINS
        "$ZPFX" %ZPFX HOME %HOME SNIPPETS %SNIPPETS PLUGINS %PLUGINS "" "" )
    REPLY=${${1/(#b)(#s)(%|)(${(~j:|:)${(@k)map:#$HOME}}|$HOME|)/$map[$match[2]]}}
    return 0
} # ]]]
# FUNCTION: .zinit-find-other-matches. [[[
# Plugin's main source file is in general `name.plugin.zsh'. However,
# there can be different conventions, if that file is not found, then
# this functions examines other conventions in the most sane order.
.zinit-find-other-matches() {
    local pdir_path="$1" pbase="$2"

    if [[ -e $pdir_path/init.zsh ]] {
        reply=( "$pdir_path"/init.zsh )
    } elif [[ -e $pdir_path/$pbase.zsh-theme ]] {
        reply=( "$pdir_path/$pbase".zsh-theme )
    } elif [[ -e $pdir_path/$pbase.theme.zsh ]] {
        reply=( "$pdir_path/$pbase".theme.zsh )
    } else {
        reply=(
            "$pdir_path"/*.plugin.zsh(DN) "$pdir_path"/*.zsh-theme(DN) "$pdir_path"/*.lib.zsh(DN)
            "$pdir_path"/*.zsh(DN) "$pdir_path"/*.sh(DN) "$pdir_path"/.zshrc(DN)
        )
    }
    reply=( "${(u)reply[@]}" )

    return $(( ${#reply} > 0 ? 0 : 1 ))
} # ]]]
# FUNCTION: .zinit-register-plugin. [[[
# Adds the plugin to ZINIT_REGISTERED_PLUGINS array and to the
# zsh_loaded_plugins array (managed according to the plugin standard:
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html).
.zinit-register-plugin() {
    local uspl2="$1" mode="$2" teleid="$3"
    integer ret=0

    if [[ -z ${ZINIT_REGISTERED_PLUGINS[(r)$uspl2]} ]]; then
        ZINIT_REGISTERED_PLUGINS+=( "$uspl2" )
    else
        # Allow overwrite-load, however warn about it.
        [[ -z ${ZINIT[TEST]}${${+ICE[wait]}:#0}${ICE[load]}${ICE[subscribe]} && ${ZINIT[MUTE_WARNINGS]} != (1|true|on|yes) ]] && +zinit-message "{u-warn}Warning{b-warn}:{rst} plugin {apo}\`{pid}${uspl2}{apo}\`{rst} already registered, will overwrite-load."
        ret=1
    fi

    # Support Zsh plugin standard.
    zsh_loaded_plugins+=( "$teleid" )

    # Full or light load?
    [[ $mode == light ]] && ZINIT[STATES__$uspl2]=1 || ZINIT[STATES__$uspl2]=2

    ZINIT_REPORTS[$uspl2]=             ZINIT_CUR_BIND_MAP=( empty 1 )
    # Functions.
    ZINIT[FUNCTIONS_BEFORE__$uspl2]=  ZINIT[FUNCTIONS_AFTER__$uspl2]=
    ZINIT[FUNCTIONS__$uspl2]=
    # Objects.
    ZINIT[ZSTYLES__$uspl2]=           ZINIT[BINDKEYS__$uspl2]=
    ZINIT[ALIASES__$uspl2]=
    # Widgets.
    ZINIT[WIDGETS_SAVED__$uspl2]=     ZINIT[WIDGETS_DELETE__$uspl2]=
    # Rest (options and (f)path).
    ZINIT[OPTIONS__$uspl2]=           ZINIT[PATH__$uspl2]=
    ZINIT[OPTIONS_BEFORE__$uspl2]=    ZINIT[OPTIONS_AFTER__$uspl2]=
    ZINIT[FPATH__$uspl2]=

    return ret
} # ]]]
# FUNCTION: .zinit-get-object-path. [[[
.zinit-get-object-path() {
    local type="$1" id_as="$2" local_dir dirname
    integer exists

    id_as="${ICE[id-as]:-$id_as}"

    # Remove leading whitespace and trailing /.
    id_as="${${id_as#"${id_as%%[! $'\t']*}"}%/}"

    for type ( ${=${${(M)type:#AUTO}:+snippet plugin}:-$type} ) {
        if [[ $type == snippet ]] {
            dirname="${${id_as%%\?*}:t}"
            local_dir="${${${id_as%%\?*}/:\/\//--}:h}"
            [[ $local_dir = . ]] && local_dir= || local_dir="${${${${${local_dir#/}//\//--}//=/-EQ-}//\?/-QM-}//\&/-AMP-}"
            local_dir="${ZINIT[SNIPPETS_DIR]}${local_dir:+/$local_dir}"
        } else {
            .zinit-any-to-user-plugin "$id_as"
            local_dir=${${${(M)reply[-2]:#%}:+${reply[2]}}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}
            [[ $id_as == _local/* && -d $local_dir && ! -d $local_dir/._zinit ]] && command mkdir -p "$local_dir"/._zinit
            dirname=""
        }
        [[ -e $local_dir/${dirname:+$dirname/}._zinit || \
            -e $local_dir/${dirname:+$dirname/}._zplugin ]] && exists=1

        (( exists )) && break
    }

    reply=( "$local_dir" "$dirname" "$exists" )
    REPLY="$local_dir${dirname:+/$dirname}"

    return $(( 1 - exists ))
}
# ]]]
# FUNCTION: @zinit-substitute. [[[
@zinit-substitute() {
    emulate -LR zsh
    builtin setopt extendedglob warncreateglobal typesetsilent noshortloops

    local -A ___subst_map
    ___subst_map=(
        "%ID%"   "${id_as_clean:-$id_as}"
        "%USER%" "$user"
        "%PLUGIN%" "${plugin:-$save_url}"
        "%URL%" "${save_url:-${user:+$user/}$plugin}"
        "%DIR%" "${local_path:-$local_dir${dirname:+/$dirname}}"
        '$ZPFX' "$ZPFX"
        '${ZPFX}' "$ZPFX"
        '%OS%' "${OSTYPE%(-gnu|[0-9]##)}" '%MACH%' "$MACHTYPE" '%CPU%' "$CPUTYPE"
        '%VENDOR%' "$VENDOR" '%HOST%' "$HOST" '%UID%' "$UID" '%GID%' "$GID"
    )
    if [[ -n ${ICE[param]} && ${ZINIT[SUBST_DONE_FOR]} != ${ICE[param]} ]] {
        ZINIT[SUBST_DONE_FOR]=${ICE[param]}
        ZINIT[PARAM_SUBST]=
        local -a ___params
        ___params=( ${(s.;.)ICE[param]} )
        local ___param ___from ___to
        for ___param ( ${___params[@]} ) {
            local ___from=${${___param%%([[:space:]]|)(->|→)*}##[[:space:]]##} \
                ___to=${${___param#*(->|→)([[:space:]]|)}%[[:space:]]}
            ___from=${___from//((#s)[[:space:]]##|[[:space:]]##(#e))/}
            ___to=${___to//((#s)[[:space:]]##|[[:space:]]##(#e))/}
            ZINIT[PARAM_SUBST]+="%${(q)___from}% ${(q)___to} "
        }
    }

    local -a ___add
    ___add=( "${ICE[param]:+${(@Q)${(@z)ZINIT[PARAM_SUBST]}}}" )
    (( ${#___add} % 2 == 0 )) && ___subst_map+=( "${___add[@]}" )

    local ___var_name
    for ___var_name; do
        local ___value=${(P)___var_name}
        ___value=${___value//(#m)(%[a-zA-Z0-9]##%|\$ZPFX|\$\{ZPFX\})/${___subst_map[$MATCH]}}
        : ${(P)___var_name::=$___value}
    done
}
# ]]]
# FUNCTION: @zinit-register-annex. [[[
# Registers the z-annex inside Zinit – i.e. an Zinit extension
@zinit-register-annex() {
    local name="$1" type="$2" handler="$3" helphandler="$4" icemods="$5" key="z-annex ${(q)2}"
    ZINIT_EXTS[seqno]=$(( ${ZINIT_EXTS[seqno]:-0} + 1 ))
    ZINIT_EXTS[$key${${(M)type#hook:}:+ ${ZINIT_EXTS[seqno]}}]="${ZINIT_EXTS[seqno]} z-annex-data: ${(q)name} ${(q)type} ${(q)handler} ${(q)helphandler} ${(q)icemods}"
    () {
        emulate -LR zsh -o extendedglob
        integer index="${type##[%a-zA-Z:_!-]##}"
        ZINIT_EXTS[ice-mods]="${ZINIT_EXTS[ice-mods]}${icemods:+|}${(j:|:)${(@)${(@s:|:)icemods}/(#b)(#s)(?)/$index-$match[1]}}"
    }
}
# ]]]
# FUNCTION: @zinit-register-hook. [[[
# Registers the z-annex inside Zinit – i.e. an Zinit extension
@zinit-register-hook() {
    local name="$1" type="$2" handler="$3" icemods="$4" key="zinit ${(q)2}"
    ZINIT_EXTS2[seqno]=$(( ${ZINIT_EXTS2[seqno]:-0} + 1 ))
    ZINIT_EXTS2[$key${${(M)type#hook:}:+ ${ZINIT_EXTS2[seqno]}}]="${ZINIT_EXTS2[seqno]} z-annex-data: ${(q)name} ${(q)type} ${(q)handler} '' ${(q)icemods}"
    ZINIT_EXTS2[ice-mods]="${ZINIT_EXTS2[ice-mods]}${icemods:+|}$icemods"
}
# ]]]
# FUNCTION: @zsh-plugin-run-on-update. [[[
# The Plugin Standard required mechanism, see:
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html
@zsh-plugin-run-on-unload() {
    ICE[ps-on-unload]="${(j.; .)@}"
    .zinit-pack-ice "$id_as" ""
}
# ]]]
# FUNCTION: @zsh-plugin-run-on-update. [[[
# The Plugin Standard required mechanism
@zsh-plugin-run-on-update() {
    ICE[ps-on-update]="${(j.; .)@}"
    .zinit-pack-ice "$id_as" ""
}
# ]]]

#
# Remaining functions.
#

# FUNCTION: .zinit-prepare-home. [[[
# Creates all directories needed by Zinit, first checks if they
# already exist.
.zinit-prepare-home() {
    [[ -n ${ZINIT[HOME_READY]} ]] && return
    ZINIT[HOME_READY]=1

    [[ ! -d ${ZINIT[HOME_DIR]} ]] && {
        command mkdir  -p "${ZINIT[HOME_DIR]}"
        # For compaudit.
        command chmod go-w "${ZINIT[HOME_DIR]}"
        # Also set up */bin and ZPFX in general.
        command mkdir 2>/dev/null -p $ZPFX/bin
    }
    [[ ! -d ${ZINIT[PLUGINS_DIR]}/_local---zinit ]] && {
        command rm -rf "${ZINIT[PLUGINS_DIR]:-${TMPDIR:-/tmp}/132bcaCAB}/_local---zplugin"
        command mkdir -p "${ZINIT[PLUGINS_DIR]}/_local---zinit"
        command chmod go-w "${ZINIT[PLUGINS_DIR]}"
        command ln -s "${ZINIT[BIN_DIR]}/_zinit" "${ZINIT[PLUGINS_DIR]}/_local---zinit"

        # Also set up */bin and ZPFX in general.
        command mkdir 2>/dev/null -p $ZPFX/bin

        (( ${+functions[.zinit-setup-plugin-dir]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
        (( ${+functions[.zinit-confirm]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh" || return 1
        .zinit-clear-completions &>/dev/null
        .zinit-compinit &>/dev/null
    }
    [[ ! -d ${ZINIT[COMPLETIONS_DIR]} ]] && {
        command mkdir "${ZINIT[COMPLETIONS_DIR]}"
        # For compaudit.
        command chmod go-w "${ZINIT[COMPLETIONS_DIR]}"

        # Symlink _zinit completion into _local---zinit directory.
        command ln -s "${ZINIT[PLUGINS_DIR]}/_local---zinit/_zinit" "${ZINIT[COMPLETIONS_DIR]}"

        # Also set up */bin and ZPFX in general.
        command mkdir 2>/dev/null -p $ZPFX/bin

        (( ${+functions[.zinit-setup-plugin-dir]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
        .zinit-compinit &>/dev/null
    }
    [[ ! -d ${ZINIT[SNIPPETS_DIR]} ]] && {
        command mkdir -p "${ZINIT[SNIPPETS_DIR]}/OMZ::plugins"
        command chmod go-w "${ZINIT[SNIPPETS_DIR]}"
        ( builtin cd ${ZINIT[SNIPPETS_DIR]}; command ln -s OMZ::plugins plugins; )

        # Also create the SERVICES_DIR.
        command mkdir -p "${ZINIT[SERVICES_DIR]}"
        command chmod go-w "${ZINIT[SERVICES_DIR]}"

        # Also set up */bin and ZPFX in general.
        command mkdir 2>/dev/null -p $ZPFX/bin
    }
    [[ ! -d ${~ZINIT[MAN_DIR]}/man9 ]] && {
        # Create ZINIT[MAN_DIR]/man{1..9}
        command mkdir 2>/dev/null -p ${~ZINIT[MAN_DIR]}/man{1..9}
    }
} # ]]]
# FUNCTION: .zinit-load-object. [[[
.zinit-load-object() {
    local ___type="$1" ___id=$2
    local -a ___opt
    ___opt=( ${@[3,-1]} )

    if [[ $___type == snippet ]] {
        .zinit-load-snippet $___opt "$___id"
    } elif [[ $___type == plugin ]] {
        .zinit-load "$___id" "" $___opt
    }
    ___retval+=$?

    return __retval
}
# ]]]
# FUNCTION:.zinit-set-m-func() [[[
# Sets and withdraws the temporary, atclone/atpull time function `m`.
.zinit-set-m-func() {
    if [[ $1 == set ]]; then
        ZINIT[___m_bkp]="${functions[m]}"
        setopt noaliases
        functions[m]="${functions[+zinit-message]}"
        setopt aliases
    elif [[ $1 == unset ]]; then
        if [[ -n ${ZINIT[___m_bkp]} ]]; then
            setopt noaliases
            functions[m]="${ZINIT[___m_bkp]}"
            setopt aliases
        else
            noglob unset functions[m]
        fi
    else
        +zinit-message "{error}ERROR #1"
        return 1
    fi
}
# ]]]
# FUNCTION: .zinit-load-snippet. [[[
# Implements the exposed-to-user action of loading a snippet.
#
# $1 - url (can be local, absolute path).
.zinit-load-snippet() {
    typeset -F 3 SECONDS=0
    local -a opts
    zparseopts -E -D -a opts f -command || { +zinit-message "{u-warn}Error{b-warn}:{rst} Incorrect options (accepted ones: {opt}-f{rst}, {opt}--command{rst})."; return 1; }
    local url="$1"
    [[ -n ${ICE[teleid]} ]] && url="${ICE[teleid]}"
    # Hide arguments from sourced scripts. Without this calls our "$@" are visible as "$@"
    # within scripts that we `source`.
    builtin set --
    integer correct retval exists
    [[ -o ksharrays ]] && correct=1

    [[ -n ${ICE[(i)(\!|)(sh|bash|ksh|csh)]}${ICE[opts]} ]] && {
        local -a precm
        precm=(
            emulate
            ${${(M)${ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}:+-R}
            ${${${ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}:-zsh}
            ${${ICE[(i)(\!|)bash]}:+-${(s: :):-o noshglob -o braceexpand -o kshglob}}
            ${(s: :):-${${:-${(@s: :):--o}" "${(s: :)^ICE[opts]}}:#-o }}
            -c
        )
    }
    # Remove leading whitespace and trailing /.
    url="${${url#"${url%%[! $'\t']*}"}%/}"
    ICE[teleid]="${ICE[teleid]:-$url}"
    [[ ${ICE[as]} = null || ${+ICE[null]} -eq 1 || ${+ICE[binary]} -eq 1 ]] && \
        ICE[pick]="${ICE[pick]:-/dev/null}"

    local local_dir dirname filename save_url="$url"

    # Allow things like $OSTYPE in the URL.
    eval "url=\"$url\""

    local id_as="${ICE[id-as]:-$url}"

    .zinit-set-m-func set

    # Set up param'' objects (parameters).
    if [[ -n ${ICE[param]} ]] {
        .zinit-setup-params && local ${(Q)reply[@]}
    }

    .zinit-pack-ice "$id_as" ""

    # Oh-My-Zsh, Prezto and manual shorthands.
    [[ $url = *(${(~kj.|.)${(Mk)ZINIT_1MAP:#OMZ*}}|robbyrussell*oh-my-zsh|ohmyzsh/ohmyzsh)* ]] && local ZSH="${ZINIT[SNIPPETS_DIR]}"

    # Construct containing directory, extract final directory
    # into handy-variable $dirname.
    .zinit-get-object-path snippet "$id_as"
    filename="${reply[-2]}" dirname="${reply[-2]}"
    local_dir="${reply[-3]}" exists=${reply[-1]}

    local -a arr
    local key
    reply=(
        ${(on)ZINIT_EXTS2[(I)zinit hook:preinit-pre <->]}
        ${(on)ZINIT_EXTS[(I)z-annex hook:preinit-<-> <->]}
        ${(on)ZINIT_EXTS2[(I)zinit hook:preinit-post <->]}
    )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]:-$ZINIT_EXTS2[$key]}[@]}" )
        "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" "${${key##(zinit|z-annex) hook:}%% <->}" load || \
            return $(( 10 - $? ))
    done

    # Download or copy the file.
    if [[ -n ${opts[(r)-f]} || $exists -eq 0 ]] {
        (( ${+functions[.zinit-download-snippet]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
        .zinit-download-snippet "$save_url" "$url" "$id_as" "$local_dir" "$dirname" "$filename"
        retval=$?
    }

    (( ${+ICE[cloneonly]} || retval )) && return 0

    ZINIT_SNIPPETS[$id_as]="$id_as <${${ICE[svn]+svn}:-single file}>"

    ZINIT[CUR_USPL2]="$id_as" ZINIT_REPORTS[$id_as]=

    reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:\\\!atinit-<-> <->]} )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" \!atinit || \
            return $(( 10 - $? ))
    done

    (( ${+ICE[atinit]} )) && { local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && eval "${ICE[atinit]}"; ((1)); } || eval "${ICE[atinit]}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }

    reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:atinit-<-> <->]} )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" atinit || \
            return $(( 10 - $? ))
    done

    local -a list
    local ZERO

    if [[ -z ${opts[(r)--command]} && ( -z ${ICE[as]} || ${ICE[as]} = null || ${+ICE[null]} -eq 1 || ${+ICE[binary]} -eq 1 ) ]]; then
        # Source the file with compdef temporary substituting of functions.
        if [[ ${ZINIT[TMP_SUBST]} = inactive ]]; then
            # Temporary substituting of functions code is inlined from .zinit-tmp-subst-on.
            (( ${+functions[compdef]} )) && ZINIT[bkp-compdef]="${functions[compdef]}" || builtin unset "ZINIT[bkp-compdef]"
            functions[compdef]=':zinit-tmp-subst-compdef "$@";'
            ZINIT[TMP_SUBST]=1
        else
            (( ++ ZINIT[TMP_SUBST] ))
        fi

        # Add to fpath.
        if [[ -d $local_dir/$dirname/functions ]] {
            [[ -z ${fpath[(r)$local_dir/$dirname/functions]} ]] && fpath+=( "$local_dir/$dirname/functions" )
            () {
                builtin setopt localoptions extendedglob
                autoload $local_dir/$dirname/functions/^([_.]*|prompt_*_setup|README*)(D-.N:t)
            }
        }

        # Source.
        if (( ${+ICE[svn]} == 0 )) {
            [[ ${+ICE[pick]} = 0 ]] && list=( "$local_dir/$dirname/$filename" )
            [[ -n ${ICE[pick]} ]] && list=( ${(M)~ICE[pick]##/*}(DN) $local_dir/$dirname/${~ICE[pick]}(DN) )
        } else {
            if [[ -n ${ICE[pick]} ]]; then
                list=( ${(M)~ICE[pick]##/*}(DN) $local_dir/$dirname/${~ICE[pick]}(DN) )
            elif (( ${+ICE[pick]} == 0 )); then
                .zinit-find-other-matches "$local_dir/$dirname" "$filename"
                list=( ${reply[@]} )
            fi
        }

        if [[ -f ${list[1-correct]} ]] {
            ZERO="${list[1-correct]}"
            (( ${+ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }
            (( 0 == retval )) && [[ $url = PZT::* || $url = https://github.com/sorin-ionescu/prezto/* ]] && zstyle ":prezto:module:${${id_as%/init.zsh}:t}" loaded 'yes'
        } else { [[ ${+ICE[silent]} -eq 1 || ${+ICE[pick]} -eq 1 && -z ${ICE[pick]} || ${ICE[pick]} = /dev/null ]] || { +zinit-message "Snippet not loaded ({url}${id_as}{rst})"; retval=1; } }

        [[ -n ${ICE[src]} ]] && { ZERO="${${(M)ICE[src]##/*}:-$local_dir/$dirname/${ICE[src]}}"; (( ${+ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }; }
        [[ -n ${ICE[multisrc]} ]] && { local ___oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; }; eval "reply=(${ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$local_dir/$dirname/$fname}"; (( ${+ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }; done; }

        # Run the atload hooks right before atload ice.
        reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:\\\!atload-<-> <->]} )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
            "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" \!atload
        done

        # Run the functions' wrapping & tracking requests.
        if [[ -n ${ICE[wrap]} ]] {
            (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
            .zinit-wrap-functions "$save_url" "" "$id_as"
        }

        [[ ${ICE[atload][1]} = "!" ]] && { .zinit-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$local_dir/$dirname/-atload-"; local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ICE[atload]#\!}"; ((1)); } || eval "${ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }

        (( -- ZINIT[TMP_SUBST] == 0 )) && { ZINIT[TMP_SUBST]=inactive; builtin setopt noaliases; (( ${+ZINIT[bkp-compdef]} )) && functions[compdef]="${ZINIT[bkp-compdef]}" || unfunction compdef; (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases; }
    elif [[ -n ${opts[(r)--command]} || ${ICE[as]} = command ]]; then
        [[ ${+ICE[pick]} = 1 && -z ${ICE[pick]} ]] && \
            ICE[pick]="${id_as:t}"
        # Subversion - directory and multiple files possible.
        if (( ${+ICE[svn]} )); then
            if [[ -n ${ICE[pick]} ]]; then
                list=( ${(M)~ICE[pick]##/*}(DN) $local_dir/$dirname/${~ICE[pick]}(DN) )
                [[ -n ${list[1-correct]} ]] && local xpath="${list[1-correct]:h}" xfilepath="${list[1-correct]}"
            else
                local xpath="$local_dir/$dirname"
            fi
        else
            local xpath="$local_dir/$dirname" xfilepath="$local_dir/$dirname/$filename"
            # This doesn't make sense, but users may come up with something.
            [[ -n ${ICE[pick]} ]] && {
                list=( ${(M)~ICE[pick]##/*}(DN) $local_dir/$dirname/${~ICE[pick]}(DN) )
                [[ -n ${list[1-correct]} ]] && xpath="${list[1-correct]:h}" xfilepath="${list[1-correct]}"
            }
        fi
        [[ -n $xpath && -z ${path[(er)$xpath]} ]] && path=( "${xpath%/}" ${path[@]} )
        [[ -n $xfilepath && -f $xfilepath && ! -x "$xfilepath" ]] && command chmod a+x "$xfilepath" ${list[@]:#$xfilepath}
        [[ -n ${ICE[src]} || -n ${ICE[multisrc]} || ${ICE[atload][1]} = "!" ]] && {
            if [[ ${ZINIT[TMP_SUBST]} = inactive ]]; then
                # Temporary substituting of functions code is inlined from .zinit-tmp-subst-on.
                (( ${+functions[compdef]} )) && ZINIT[bkp-compdef]="${functions[compdef]}" || builtin unset "ZINIT[bkp-compdef]"
                functions[compdef]=':zinit-tmp-subst-compdef "$@";'
                ZINIT[TMP_SUBST]=1
            else
                (( ++ ZINIT[TMP_SUBST] ))
            fi
        }

        if [[ -n ${ICE[src]} ]]; then
            ZERO="${${(M)ICE[src]##/*}:-$local_dir/$dirname/${ICE[src]}}"
            (( ${+ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }
        fi
        [[ -n ${ICE[multisrc]} ]] && { local ___oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; }; eval "reply=(${ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; local fname; for fname in "${reply[@]}"; do ZERO="${${(M)fname:#/*}:-$local_dir/$dirname/$fname}"; (( ${+ICE[silent]} )) && { { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( retval += $? )); ((1)); } || { ((1)); { [[ -n $precm ]] && { builtin ${precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); builtin source "$ZERO"; }; }; (( retval += $? )); }; done; }

        # Run the atload hooks right before atload ice.
        reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:\\\!atload-<-> <->]} )
        for key in "${reply[@]}"; do
            arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
            "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" \!atload
        done

        # Run the functions' wrapping & tracking requests.
        if [[ -n ${ICE[wrap]} ]] {
            (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
            .zinit-wrap-functions "$save_url" "" "$id_as"
        }

        [[ ${ICE[atload][1]} = "!" ]] && { .zinit-add-report "$id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$local_dir/$dirname/-atload-"; local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ICE[atload]#\!}"; ((1)); } || eval "${ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }

        [[ -n ${ICE[src]} || -n ${ICE[multisrc]} || ${ICE[atload][1]} = "!" ]] && {
            (( -- ZINIT[TMP_SUBST] == 0 )) && { ZINIT[TMP_SUBST]=inactive; builtin setopt noaliases; (( ${+ZINIT[bkp-compdef]} )) && functions[compdef]="${ZINIT[bkp-compdef]}" || unfunction compdef; (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases; }
        }
    elif [[ ${ICE[as]} = completion ]]; then
        ((1))
    fi

    (( ${+ICE[atload]} )) && [[ ${ICE[atload][1]} != "!" ]] && { ZERO="$local_dir/$dirname/-atload-"; local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$local_dir/$dirname"; } && builtin eval "${ICE[atload]}"; ((1)); } || eval "${ICE[atload]}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }

    reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:atload-<-> <->]} )
    for key in "${reply[@]}"; do
        arr=( "${(Q)${(z@)ZINIT_EXTS[$key]}[@]}" )
        "${arr[5]}" snippet "$save_url" "$id_as" "$local_dir/$dirname" atload
    done

    (( ${+ICE[notify]} == 1 )) && { [[ $retval -eq 0 || -n ${(M)ICE[notify]#\!} ]] && { local msg; eval "msg=\"${ICE[notify]#\!}\""; +zinit-deploy-message @msg "$msg" } || +zinit-deploy-message @msg "notify: Plugin not loaded / loaded with problem, the return code: $retval"; }
    (( ${+ICE[reset-prompt]} == 1 )) && +zinit-deploy-message @rst

    ZINIT[CUR_USPL2]=
    ZINIT[TIME_INDEX]=$(( ${ZINIT[TIME_INDEX]:-0} + 1 ))
    ZINIT[TIME_${ZINIT[TIME_INDEX]}_${id_as}]=$SECONDS
    ZINIT[AT_TIME_${ZINIT[TIME_INDEX]}_${id_as}]=$EPOCHREALTIME

    .zinit-set-m-func unset
    return retval
} # ]]]
# FUNCTION: .zinit-load. [[[
# Implements the exposed-to-user action of loading a plugin.
#
# $1 - plugin spec (4 formats: user---plugin, user/plugin, user, plugin)
# $2 - plugin name, if the third format is used
.zinit-load () {
    typeset -F 3 SECONDS=0
    local ___mode="$3" ___rst=0 ___retval=0 ___key
    .zinit-any-to-user-plugin "$1" "$2"
    local ___user="${reply[-2]}" ___plugin="${reply[-1]}" ___id_as="${ICE[id-as]:-${reply[-2]}${${reply[-2]:#(%|/)*}:+/}${reply[-1]}}"
    local ___pdir_path="${${${(M)___user:#%}:+$___plugin}:-${ZINIT[PLUGINS_DIR]}/${___id_as//\//---}}"
    local ___pdir_orig="$___pdir_path"
    ZINIT[CUR_USR]="$___user" ZINIT[CUR_PLUGIN]="$___plugin" ZINIT[CUR_USPL2]="$___id_as"
    if [[ -n ${ICE[teleid]} ]] {
        .zinit-any-to-user-plugin "${ICE[teleid]}"
        ___user="${reply[-2]}" ___plugin="${reply[-1]}"
    } else {
        ICE[teleid]="$___user${${___user:#%}:+/}$___plugin"
    }

    .zinit-set-m-func set

    local -a ___arr
    reply=(
        ${(on)ZINIT_EXTS2[(I)zinit hook:preinit-pre <->]}
        ${(on)ZINIT_EXTS[(I)z-annex hook:preinit-<-> <->]}
        ${(on)ZINIT_EXTS2[(I)zinit hook:preinit-post <->]}
    )
    for ___key in "${reply[@]}"; do
        ___arr=( "${(Q)${(z@)ZINIT_EXTS[$___key]:-$ZINIT_EXTS2[$___key]}[@]}" )
        "${___arr[5]}" plugin "$___user" "$___plugin" "$___id_as" "$___pdir_orig" "${${___key##(zinit|z-annex) hook:}%% <->}" load || \
            return $(( 10 - $? ))
    done

    if [[ $___user != % && ! -d ${ZINIT[PLUGINS_DIR]}/${___id_as//\//---} ]] {
        (( ${+functions[.zinit-setup-plugin-dir]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
        reply=( "$___user" "$___plugin" ) REPLY=github
        if (( ${+ICE[pack]} )) {
            if ! .zinit-get-package "$___user" "$___plugin" "$___id_as" \
                "${ZINIT[PLUGINS_DIR]}/${___id_as//\//---}" \
                "${ICE[pack]:-default}"
            then
                zle && { builtin print; zle .reset-prompt; }
                return 1
            fi
            ___id_as="${ICE[id-as]:-${___user}${${___user:#(%|/)*}:+/}$___plugin}"
        }
        ___user="${reply[-2]}" ___plugin="${reply[-1]}"
        ICE[teleid]="$___user${${___user:#(%|/)*}:+/}$___plugin"
        [[ $REPLY = snippet ]] && {
            ICE[id-as]="${ICE[id-as]:-$___id_as}"
            .zinit-load-snippet $___plugin && return
            zle && { builtin print; zle .reset-prompt; }
            return 1
        }
        .zinit-setup-plugin-dir "$___user" "$___plugin" "$___id_as" "$REPLY"
        local rc="$?"
        if [[ "$rc" -ne 0 ]]; then
            zle && { builtin print; zle .reset-prompt; }
            return "$rc"
        fi
        zle && ___rst=1
    }

    ZINIT_SICE[$___id_as]=
    .zinit-pack-ice "$___id_as"

    (( ${+ICE[cloneonly]} )) && return 0

    .zinit-register-plugin "$___id_as" "$___mode" "${ICE[teleid]}"

    # Set up param'' objects (parameters).
    if [[ -n ${ICE[param]} ]] {
        .zinit-setup-params && local ${(Q)reply[@]}
    }

    reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:\\\!atinit-<-> <->]} )
    for ___key in "${reply[@]}"; do
        ___arr=( "${(Q)${(z@)ZINIT_EXTS[$___key]}[@]}" )
        "${___arr[5]}" plugin "$___user" "$___plugin" "$___id_as" "${${${(M)___user:#%}:+$___plugin}:-${ZINIT[PLUGINS_DIR]}/${___id_as//\//---}}" \!atinit || \
            return $(( 10 - $? ))
    done

    [[ ${+ICE[atinit]} = 1 && $ICE[atinit] != '!'*   ]] && { local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "${${${(M)___user:#%}:+$___plugin}:-${ZINIT[PLUGINS_DIR]}/${___id_as//\//---}}"; } && eval "${ICE[atinit]}"; ((1)); } || eval "${ICE[atinit]}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }

    reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:atinit-<-> <->]} )
    for ___key in "${reply[@]}"; do
        ___arr=( "${(Q)${(z@)ZINIT_EXTS[$___key]}[@]}" )
        "${___arr[5]}" plugin "$___user" "$___plugin" "$___id_as" "${${${(M)___user:#%}:+$___plugin}:-${ZINIT[PLUGINS_DIR]}/${___id_as//\//---}}" atinit || \
            return $(( 10 - $? ))
    done

    .zinit-load-plugin "$___user" "$___plugin" "$___id_as" "$___mode" "$___rst"; ___retval=$?
    (( ${+ICE[notify]} == 1 )) && { [[ $___retval -eq 0 || -n ${(M)ICE[notify]#\!} ]] && { local msg; eval "msg=\"${ICE[notify]#\!}\""; +zinit-deploy-message @msg "$msg" } || +zinit-deploy-message @msg "notify: Plugin not loaded / loaded with problem, the return code: $___retval"; }
    (( ${+ICE[reset-prompt]} == 1 )) && +zinit-deploy-message @___rst

    # Unset the `m` function.
    .zinit-set-m-func unset

    # Mark no load is in progress.
    ZINIT[CUR_USR]= ZINIT[CUR_PLUGIN]= ZINIT[CUR_USPL2]=

    ZINIT[TIME_INDEX]=$(( ${ZINIT[TIME_INDEX]:-0} + 1 ))
    ZINIT[TIME_${ZINIT[TIME_INDEX]}_${___id_as//\//---}]=$SECONDS
    ZINIT[AT_TIME_${ZINIT[TIME_INDEX]}_${___id_as//\//---}]=$EPOCHREALTIME
    return ___retval
} # ]]]
# FUNCTION: .zinit-load-plugin. [[[
# Lower-level function for loading a plugin.
#
# $1 - user
# $2 - plugin
# $3 - mode (light or load)
.zinit-load-plugin() {
    local ___user="$1" ___plugin="$2" ___id_as="$3" ___mode="$4" ___rst="$5" ___correct=0 ___retval=0
    local ___pbase="${${___plugin:t}%(.plugin.zsh|.zsh|.git)}" ___key
    # Hide arguments from sourced scripts. Without this calls our "$@" are visible as "$@"
    # within scripts that we `source`.
    builtin set --
    [[ -o ksharrays ]] && ___correct=1

    [[ -n ${ICE[(i)(\!|)(sh|bash|ksh|csh)]}${ICE[opts]} ]] && {
        local -a ___precm
        ___precm=(
            emulate
            ${${(M)${ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}:+-R}
            ${${${ICE[(i)(\!|)(sh|bash|ksh|csh)]}#\!}:-zsh}
            ${${ICE[(i)(\!|)bash]}:+-${(s: :):-o noshglob -o braceexpand -o kshglob}}
            ${(s: :):-${${:-${(@s: :):--o}" "${(s: :)^ICE[opts]}}:#-o }}
            -c
        )
    }

    [[ -z ${ICE[subst]} ]] && local ___builtin=builtin

    [[ ${ICE[as]} = null || ${+ICE[null]} -eq 1 || ${+ICE[binary]} -eq 1 ]] && \
        ICE[pick]="${ICE[pick]:-/dev/null}"

    if [[ -n ${ICE[autoload]} ]] {
        :zinit-tmp-subst-autoload -Uz \
            ${(s: :)${${${(s.;.)ICE[autoload]#[\!\#]}#[\!\#]}//(#b)((*)(->|=>|→)(*)|(*))/${match[2]:+$match[2] -S $match[4]}${match[5]:+${match[5]} -S ${match[5]}}}} \
            ${${(M)ICE[autoload]:#*(->|=>|→)*}:+-C} ${${(M)ICE[autoload]#(?\!|\!)}:+-C} ${${(M)ICE[autoload]#(?\#|\#)}:+-I}
    }

    if [[ ${ICE[as]} = command ]]; then
        [[ ${+ICE[pick]} = 1 && -z ${ICE[pick]} ]] && \
            ICE[pick]="${___id_as:t}"
        reply=()
        if [[ -n ${ICE[pick]} && ${ICE[pick]} != /dev/null ]]; then
            reply=( ${(M)~ICE[pick]##/*}(DN) $___pdir_path/${~ICE[pick]}(DN) )
            [[ -n ${reply[1-correct]} ]] && ___pdir_path="${reply[1-correct]:h}"
        fi
        [[ -z ${path[(er)$___pdir_path]} ]] && {
            [[ $___mode != light ]] && .zinit-diff-env "${ZINIT[CUR_USPL2]}" begin
            path=( "${___pdir_path%/}" ${path[@]} )
            [[ $___mode != light ]] && .zinit-diff-env "${ZINIT[CUR_USPL2]}" end
            .zinit-add-report "${ZINIT[CUR_USPL2]}" "$ZINIT[col-info2]$___pdir_path$ZINIT[col-rst] added to \$PATH"
        }
        [[ -n ${reply[1-correct]} && ! -x ${reply[1-correct]} ]] && command chmod a+x ${reply[@]}

        [[ ${ICE[atinit]} = '!'* || -n ${ICE[src]} || -n ${ICE[multisrc]} || ${ICE[atload][1]} = "!" ]] && {
            if [[ ${ZINIT[TMP_SUBST]} = inactive ]]; then
                (( ${+functions[compdef]} )) && ZINIT[bkp-compdef]="${functions[compdef]}" || builtin unset "ZINIT[bkp-compdef]"
                functions[compdef]=':zinit-tmp-subst-compdef "$@";'
                ZINIT[TMP_SUBST]=1
            else
                (( ++ ZINIT[TMP_SUBST] ))
            fi
        }

        local ZERO
        [[ $ICE[atinit] = '!'* ]] && { local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "${${${(M)___user:#%}:+$___plugin}:-${ZINIT[PLUGINS_DIR]}/${___id_as//\//---}}"; } && eval "${ICE[atinit#!]}"; ((1)); } || eval "${ICE[atinit]#!}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }
        [[ -n ${ICE[src]} ]] && { ZERO="${${(M)ICE[src]##/*}:-$___pdir_orig/${ICE[src]}}"; (( ${+ICE[silent]} )) && { { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( ___retval += $? )); ((1)); } || { ((1)); { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; }; (( ___retval += $? )); }; }
        [[ -n ${ICE[multisrc]} ]] && { local ___oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$___pdir_orig"; }; eval "reply=(${ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; local ___fname; for ___fname in "${reply[@]}"; do ZERO="${${(M)___fname:#/*}:-$___pdir_orig/$___fname}"; (( ${+ICE[silent]} )) && { { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( ___retval += $? )); ((1)); } || { ((1)); { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; }; (( ___retval += $? )); }; done; }

        # Run the atload hooks right before atload ice.
        reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:\\\!atload-<-> <->]} )
        for ___key in "${reply[@]}"; do
            ___arr=( "${(Q)${(z@)ZINIT_EXTS[$___key]}[@]}" )
            "${___arr[5]}" plugin "$___user" "$___plugin" "$___id_as" "$___pdir_orig" \!atload
        done

        # Run the functions' wrapping & tracking requests.
        if [[ -n ${ICE[wrap]} ]] {
            (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
            .zinit-wrap-functions "$___user" "$___plugin" "$___id_as"
        }

        [[ ${ICE[atload][1]} = "!" ]] && { .zinit-add-report "$___id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$___pdir_orig/-atload-"; local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$___pdir_orig"; } && builtin eval "${ICE[atload]#\!}"; } || eval "${ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }

        [[ -n ${ICE[src]} || -n ${ICE[multisrc]} || ${ICE[atload][1]} = "!" ]] && {
            (( -- ZINIT[TMP_SUBST] == 0 )) && { ZINIT[TMP_SUBST]=inactive; builtin setopt noaliases; (( ${+ZINIT[bkp-compdef]} )) && functions[compdef]="${ZINIT[bkp-compdef]}" || unfunction compdef; (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases; }
        }
    elif [[ ${ICE[as]} = completion ]]; then
        ((1))
    else
        if [[ -n ${ICE[pick]} ]]; then
            [[ ${ICE[pick]} = /dev/null ]] && reply=( /dev/null ) || reply=( ${(M)~ICE[pick]##/*}(DN) $___pdir_path/${~ICE[pick]}(DN) )
        elif [[ -e $___pdir_path/$___pbase.plugin.zsh ]]; then
            reply=( "$___pdir_path/$___pbase".plugin.zsh )
        else
            .zinit-find-other-matches "$___pdir_path" "$___pbase"
        fi

        #[[ ${#reply} -eq 0 ]] && return 1

        # Get first one.
        local ___fname="${reply[1-correct]:t}"
        ___pdir_path="${reply[1-correct]:h}"

        .zinit-add-report "${ZINIT[CUR_USPL2]}" "Source $___fname ${${${(M)___mode:#light}:+(no reporting)}:-$ZINIT[col-info2](reporting enabled)$ZINIT[col-rst]}"

        # Light and compdef ___mode doesn't do diffs and temporary substituting of functions.
        [[ $___mode != light(|-b) ]] && .zinit-diff "${ZINIT[CUR_USPL2]}" begin

        .zinit-tmp-subst-on "${___mode:-load}"

        # We need some state, but ___user wants his for his plugins.
        (( ${+ICE[blockf]} )) && { local -a fpath_bkp; fpath_bkp=( "${fpath[@]}" ); }
        local ZERO="$___pdir_path/$___fname"
        (( ${+ICE[aliases]} )) || builtin setopt noaliases
        [[ $ICE[atinit] = '!'* ]] && { local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "${${${(M)___user:#%}:+$___plugin}:-${ZINIT[PLUGINS_DIR]}/${___id_as//\//---}}"; } && eval "${ICE[atinit]#!}"; ((1)); } || eval "${ICE[atinit]#1}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }
        (( ${+ICE[silent]} )) && { { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( ___retval += $? )); ((1)); } || { ((1)); { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; }; (( ___retval += $? )); }
        [[ -n ${ICE[src]} ]] && { ZERO="${${(M)ICE[src]##/*}:-$___pdir_orig/${ICE[src]}}"; (( ${+ICE[silent]} )) && { { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( ___retval += $? )); ((1)); } || { ((1)); { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; }; (( ___retval += $? )); }; }
        [[ -n ${ICE[multisrc]} ]] && { local ___oldcd="$PWD"; () { setopt localoptions noautopushd; builtin cd -q "$___pdir_orig"; }; eval "reply=(${ICE[multisrc]})"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; for ___fname in "${reply[@]}"; do ZERO="${${(M)___fname:#/*}:-$___pdir_orig/$___fname}"; (( ${+ICE[silent]} )) && { { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; } 2>/dev/null 1>&2; (( ___retval += $? )); ((1)); } || { { [[ -n $___precm ]] && { builtin ${___precm[@]} 'source "$ZERO"'; ((1)); } || { ((1)); $___builtin source "$ZERO"; }; }; (( ___retval += $? )); } done; }

        # Run the atload hooks right before atload ice.
        reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:\\\!atload-<-> <->]} )
        for ___key in "${reply[@]}"; do
            ___arr=( "${(Q)${(z@)ZINIT_EXTS[$___key]}[@]}" )
            "${___arr[5]}" plugin "$___user" "$___plugin" "$___id_as" "$___pdir_orig" \!atload
        done

        # Run the functions' wrapping & tracking requests.
        if [[ -n ${ICE[wrap]} ]] {
            (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
            .zinit-wrap-functions "$___user" "$___plugin" "$___id_as"
        }

        [[ ${ICE[atload][1]} = "!" ]] && { .zinit-add-report "$___id_as" "Note: Starting to track the atload'!…' ice…"; ZERO="$___pdir_orig/-atload-"; local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$___pdir_orig"; } && builtin eval "${ICE[atload]#\!}"; ((1)); } || eval "${ICE[atload]#\!}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }
        (( ZINIT[ALIASES_OPT] )) && builtin setopt aliases
        (( ${+ICE[blockf]} )) && { fpath=( "${fpath_bkp[@]}" ); }

        .zinit-tmp-subst-off "${___mode:-load}"

        [[ $___mode != light(|-b) ]] && .zinit-diff "${ZINIT[CUR_USPL2]}" end
    fi

    [[ ${+ICE[atload]} = 1 && ${ICE[atload][1]} != "!" ]] && { ZERO="$___pdir_orig/-atload-"; local ___oldcd="$PWD"; (( ${+ICE[nocd]} == 0 )) && { () { setopt localoptions noautopushd; builtin cd -q "$___pdir_orig"; } && builtin eval "${ICE[atload]}"; ((1)); } || eval "${ICE[atload]}"; () { setopt localoptions noautopushd; builtin cd -q "$___oldcd"; }; }

    reply=( ${(on)ZINIT_EXTS[(I)z-annex hook:atload-<-> <->]} )
    for ___key in "${reply[@]}"; do
        ___arr=( "${(Q)${(z@)ZINIT_EXTS[$___key]}[@]}" )
        "${___arr[5]}" plugin "$___user" "$___plugin" "$___id_as" "$___pdir_orig" atload
    done

    (( ___rst )) && { builtin print; zle .reset-prompt; }

    return ___retval
} # ]]]
# FUNCTION: .zinit-compdef-replay. [[[
# Runs gathered compdef calls. This allows to run `compinit'
# after loading plugins.
.zinit-compdef-replay() {
    local quiet="$1"
    typeset -a pos

    # Check if compinit was loaded.
    if [[ ${+functions[compdef]} = 0 ]]; then
        +zinit-message "{u-warn}Error{b-warn}:{rst} The {func}compinit{rst}" \
            "function hasn't been loaded, cannot do {it}{cmd}compdef replay{rst}."
        return 1
    fi

    # In the same order.
    local cdf
    for cdf in "${ZINIT_COMPDEF_REPLAY[@]}"; do
        pos=( "${(z)cdf}" )
        # When ZINIT_COMPDEF_REPLAY empty (also when only white spaces).
        [[ ${#pos[@]} = 1 && -z ${pos[-1]} ]] && continue
        pos=( "${(Q)pos[@]}" )
        [[ $quiet = -q ]] || +zinit-message "Running compdef: {cmd}${pos[*]}{rst}"
        compdef "${pos[@]}"
    done

    return 0
} # ]]]
# FUNCTION: .zinit-compdef-clear. [[[
# Implements user-exposed functionality to clear gathered compdefs.
.zinit-compdef-clear() {
    local quiet="$1" count="${#ZINIT_COMPDEF_REPLAY}"
    ZINIT_COMPDEF_REPLAY=( )
    [[ $quiet = -q ]] || +zinit-message "Compdef-replay cleared (it had {num}${count}{rst} entries)."
} # ]]]
# FUNCTION: .zinit-add-report. [[[
# Adds a report line for given plugin.
#
# $1 - uspl2, i.e. user/plugin
# $2, ... - the text
.zinit-add-report() {
    # Use zinit binary module if available.
    [[ -n $1 ]] && { (( ${+builtins[zpmod]} && 0 )) && zpmod report-append "$1" "$2"$'\n' || ZINIT_REPORTS[$1]+="$2"$'\n'; }
    [[ ${ZINIT[DTRACE]} = 1 ]] && { (( ${+builtins[zpmod]} )) && zpmod report-append _dtrace/_dtrace "$2"$'\n' || ZINIT_REPORTS[_dtrace/_dtrace]+="$2"$'\n'; }
    return 0
} # ]]]
# FUNCTION: .zinit-add-fpath. [[[
.zinit-add-fpath() {
    [[ $1 = (-f|--front) ]] && { shift; integer front=1; }
    .zinit-any-to-user-plugin "$1" ""
    local id_as="$1" add_dir="$2" user="${reply[-2]}" plugin="${reply[-1]}"
    if (( front )) {
        fpath[1,0]=${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}${add_dir:+/$add_dir}
    } else {
        fpath+=(
            ${${${(M)user:#%}:+$plugin}:-${ZINIT[PLUGINS_DIR]}/${id_as//\//---}}${add_dir:+/$add_dir}
        )
    }
}
# ]]]
# FUNCTION: .zinit-run. [[[
# Run code inside plugin's folder
# It uses the `correct' parameter from upper's scope zinit().
.zinit-run() {
    if [[ $1 = (-l|--last) ]]; then
        { set -- "${ZINIT[last-run-plugin]:-$(<${ZINIT[BIN_DIR]}/last-run-object.txt)}" "${@[2-correct,-1]}"; } &>/dev/null
        [[ -z $1 ]] && { +zinit-message "{u-warn}Error{b-warn}:{rst} No recent plugin-ID saved on the disk yet, please specify" \
                            "it as the first argument, i.e.{ehi}: {cmd}zi run {pid}usr/plg{slight} {…}the code to run{…} "; return 1; }
    else
        integer ___nolast=1
    fi
    .zinit-any-to-user-plugin "$1" ""
    local ___id_as="$1" ___user="${reply[-2]}" ___plugin="${reply[-1]}" ___oldpwd="$PWD"
    () {
        emulate -LR zsh
        builtin cd &>/dev/null -q ${${${(M)___user:#%}:+$___plugin}:-${ZINIT[PLUGINS_DIR]}/${___id_as//\//---}} || {
            .zinit-get-object-path snippet "$___id_as"
            builtin cd &>/dev/null -q $REPLY
        }
    }
    if (( $? == 0 )); then
        (( ___nolast )) && { builtin print -r "$1" >! ${ZINIT[BIN_DIR]}/last-run-object.txt; }
        ZINIT[last-run-plugin]="$1"
        eval "${@[2-correct,-1]}"
        () { setopt localoptions noautopushd; builtin cd -q "$___oldpwd"; }
    else
        +zinit-message "{u-warn}Error{b-warn}:{rst} no such plugin or snippet."
    fi
}
# ]]]
# FUNCTION: +zinit-deploy-message. [[[
# Deploys a sub-prompt message to be displayed OR a `zle
# .reset-prompt' call to be invoked
+zinit-deploy-message() {
    [[ $1 = <-> && ( ${#} = 1 || ( $2 = (hup|nval|err) && ${#} = 2 ) ) ]] && { zle && {
            local alltext text IFS=$'\n' nl=$'\n'
            repeat 25; do read -r -u"$1" text; alltext+="${text:+$text$nl}"; done
            [[ $alltext = @rst$nl ]] && { builtin zle reset-prompt; ((1)); } || \
                { [[ -n $alltext ]] && builtin zle -M "$alltext"; }
        }
        builtin zle -F "$1"; exec {1}<&-
        return 0
    }
    local THEFD=13371337 hasw
    # The expansion is: if there is @sleep: pfx, then use what's after.
    # it, otherwise substitute 0
    exec {THEFD} < <(LANG=C sleep $(( 0.01 + ${${${(M)1#@sleep:}:+${1#@sleep:}}:-0} )); builtin print -r -- ${1:#(@msg|@sleep:*)} "${@[2,-1]}"; )
    command true # workaround a Zsh bug, see: https://www.zsh.org/mla/workers/2018/msg00966.html
    builtin zle -F "$THEFD" +zinit-deploy-message
}
# ]]]
# FUNCTION: .zinit-formatter-pid. [[[
.zinit-formatter-pid() {
    builtin emulate -L zsh -o extendedglob

    # Save whitespace location
    local pbz=${(M)1##(#s)[[:space:]]##}
    local kbz=${(M)1%%[[:space:]]##(#e)}
    # trim whitespace
    1=${1//((#s)[[:space:]]##|[[:space:]]##(#e))/}

    ((${+functions[.zinit-first]})) || source ${ZINIT[BIN_DIR]}/zinit-side.zsh
    .zinit-any-colorify-as-uspl2 "$1";

    # Replace at least one character with an unbreakable space, because
    # due to implementation problems, marginal whitespace is lost ...
    pbz=${pbz/[[:blank:]]/ }
    local kbz_rev="${(j::)${(@Oas::)kbz}}"
    kbz="${(j::)${(@Oas::)${kbz_rev/[[:blank:]]/ }}}"

    # Re-add whitespace
    REPLY=$pbz$REPLY$kbz
}
# ]]]
# FUNCTION: .zinit-formatter-bar. [[[
.zinit-formatter-bar() {
    .zinit-formatter-bar-util ─ bar
}
# ]]]
# FUNCTION: .zinit-formatter-th-bar. [[[
.zinit-formatter-th-bar() {
    .zinit-formatter-bar-util ━ th-bar
}
# FUNCTION: .zinit-formatter-bar-util. [[[
.zinit-formatter-bar-util() {
    if [[ $LANG == (#i)*utf-8* ]]; then
        ch=$1
    else
        ch=-
    fi

    REPLY=$ZINIT[col-$2]${(pl:COLUMNS-1::$ch:):-}$ZINIT[col-rst]
}
# ]]]
# FUNCTION: .zinit-formatter-url. [[[
.zinit-formatter-url() {
    builtin emulate -LR zsh -o extendedglob
    #              1:proto        3:domain/5:start      6:end-of-it         7:no-dot-domain        9:file-path
    if [[ $1 = (#b)([^:]#)(://|::)((([[:alnum:]._+-]##).([[:alnum:]_+-]##))|([[:alnum:].+_-]##))(|/(*)) ]] {
        # The advanced coloring if recognized the format…
        match[9]=${match[9]//\//"%F{227}%B"/"%F{81}%b"}
        if [[ -n $match[4] ]]; then
            REPLY="$(builtin print -Pr -- %F{220}$match[1]%F{227}$match[2]\
%B%F{82}$match[5]\
%B%F{227}.\
%B%F{183}$match[6]%f%b)" # … this ·case· ends at: trailing component of the with-dot domain …
        else
            REPLY="$(builtin print -Pr -- %F{220}$match[1]%F{227}$match[2]\
%B%F{82}$match[7]%f%b)" # … this ·case· ends at: no-dot domain …
        fi
        # Is there any file-path part in the URL?
        if [[ -n $match[9] ]]; then
            REPLY+="$(print -Pr -- \
%F{227}%B/%F{81}%b$match[9]%f%b)" # … append it. This ends the URL.
        fi
#endif
    } else {
        # …revert to the basic if not…
        REPLY=$ZINIT[col-url]$1$ZINIT[col-rst]
    }
}
# ]]]
# FUNCTION: +zinit-message-formatter [[[
.zinit-main-message-formatter() {
    if [[ -z $1 && -z $2 && -z $3 ]]; then
        REPLY=""
        return
    fi
    local append influx in_prepend
    if [[ $2 == (b|u|it|st|nb|nu|nit|nst) ]]; then
        # Code repetition to preserve any leading/trailing whitespace
        # and to allow accumulation of this code with others.
        append=$ZINIT[col-$2]
    elif [[ $2 == (…|ndsh|mdsh|mmdsh|-…|lr|) || -z $2 || -z $ZINIT[col-$2] ]]; then
        # Resume previous escape code, if one is present.
        if [[ $ZINIT[__last-formatter-code] != (…|ndsh|mdsh|mmdsh|-…|lr|rst|nl|) ]]; then
            in_prepend=$ZINIT[col-$ZINIT[__last-formatter-code]]
            influx=$ZINIT[col-$ZINIT[__last-formatter-code]]
        fi
        # Otherwise no action - only copy of this code without color.
    else
        # End of escaping logic
        append=$ZINIT[col-rst]
    fi

    # Construct the text.
    REPLY=$in_prepend${ZINIT[col-$2]:-$1}$influx$3$append

    # Replace new lines with characters that work the same but are not
    # deleted in the substitution $ (...) - vertical tab 0xB ↔ 13 in the system
    # octagonal connected back carriage (015).
    local nl=$'\n' vertical=$'\013' carriager=$'\015'
    REPLY=${REPLY//$nl/$vertical$carriager}

#    REPLY+="x(${3}…)"
}
# ]]]
# FUNCTION: +zinit-message. [[[
+zinit-message() {
    builtin emulate -LR zsh -o extendedglob
    local opt msg
    [[ $1 = -* ]] && { local opt=$1; shift; }

    ZINIT[__last-formatter-code]=
    msg=${${(j: :)${@:#--}}//\%/%%}

    # First try a dedicated formatter, marking its empty output with ←→, then
    # the general formatter and in the end filter-out the ←→ from the message.
    msg=${${msg//(#b)(([\\]|(%F))([\{]([^\}]##)[\}])|([\{]([^\}]##)[\}])([^\%\{\\]#))/\
${match[4]:+${${match[3]:-$ZINIT[col-${ZINIT[__last-formatter-code]}]}:#%F}}$match[3]$match[4]\
${${functions[.zinit-formatter-$match[7]]:+\
${$(.zinit-formatter-$match[7] "$match[8]"; builtin print -rn -- $REPLY):-←→}}:-\
$(.zinit-main-message-formatter "$match[6]" "$match[7]" "$match[8]"; \
  builtin print -rn -- "$REPLY"
 )${${ZINIT[__last-formatter-code]::=${${${match[7]:#(…|ndsh|mdsh|mmdsh|-…|lr)}:+\
$match[7]}:-${ZINIT[__last-formatter-code]}}}:+}}}//←→}


    # Reset color attributes at the end of the message
    msg=$msg$ZINIT[col-rst]
    # Output the processed message:
    builtin print -Pr ${opt:#--} -- $msg

    # Needed to correctly end a message with {nl}.
    if [[ -n ${opt:#*n*} || -z $opt ]]; then
        print -n $'\015'
    fi
}
# ]]]
# FUNCTION: +zinit-prehelp-usage-message. [[[
+zinit-prehelp-usage-message() {
    builtin emulate -LR zsh -o extendedglob
    local cmd=$1 allowed=$2 sep="$ZINIT[col-msg2], $ZINIT[col-ehi]" \
        sep2="$ZINIT[col-msg2], $ZINIT[col-opt]" bcol

    # -h/--help given?
    if (( OPTS[opt_-h,--help] )) {
        # Yes – a help message:
        +zinit-message "{lhi}HELP FOR {apo}\`{cmd}$cmd{apo}\`{lhi} subcommand {mdsh}" \
                "the available {b-lhi}options{ehi}:{rst}"
        local opt
        for opt ( ${(kos:|:)allowed} ) {
            [[ $opt == --* ]] && continue
            local msg=${___opt_map[$opt]#*:} txt=${___opt_map[(r)opt_$opt,--[^:]##]}
            if [[ $msg == *":["* ]] {
                msg=${${(MS)msg##$cmd:\[[^]]##}:-${(MS)msg##\*:\[[^]]##}}
                msg=${msg#($cmd|\*):\[}
            }
            local pre_msg=`+zinit-message -n {opt}${(r:14:)${txt#opt_}}`
            +zinit-message ${(r:35:: :)pre_msg}{rst}{ehi}→{rst}"  $msg"
        }
    } elif [[ -n $allowed ]] {
        shift 2
        # No – an error message:
        +zinit-message "{b}{u-warn}ERROR{b-warn}:{rst}{msg2} Incorrect options given{ehi}:" \
                "${(Mpj:$sep:)@:#-*}{rst}{msg2}. Allowed for the subcommand{ehi}:{rst}" \
                "{apo}\`{cmd}$cmd{apo}\`{msg2} are{ehi}:{rst}" \
                "{nl}{mmdsh} {opt}${allowed//\|/$sep2}{msg2}." \
                "{nl}{…} Aborting.{rst}"
    } else {
        local -a cmds
        cmds=( load snippet update delete )
        local bcol="{$cmd}" sep="${ZINIT[col-rst]}${ZINIT[col-$cmd]}\`, \`${ZINIT[col-cmd]}"
        +zinit-message "$bcol(it should be one of, e.g.{ehi}:" \
                "{nb}$bcol\`{cmd}${(pj:$sep:)cmds}$bcol\`," \
                "{cmd}{…}$bcol, e.g.{ehi}: {nb}$bcol\`{lhi}zinit {b}{cmd}load" \
                "{pid}username/reponame$bcol\`) or a {b}{hi}for{nb}$bcol-based" \
                "command body (i.e.{ehi}:{rst}$bcol e.g.{ehi}: {rst}$bcol\`{lhi}zinit" \
                    "{…}{b}ice-spec{nb}{…} {hi}for{nb}{lhi} {…}({b}plugin" \
                    "{nb}or{b} snippet) {pname}ID-1 ID-2 {-…} {lhi}{…}$bcol\`)." \
                "See \`{cmd}help$bcol\` for a more detailed usage information and" \
                "the list of the {cmd}subcommands$bcol.{rst}"
    }
}
# ]]]
# FUNCTION: +zinit-parse-opts. [[[
.zinit-parse-opts() {
    builtin emulate -LR zsh -o extendedglob
    reply=( "${(@)${@[2,-1]//([  $'\t']##|(#s))(#b)(${(~j.|.)${(@s.|.)___opt_map[$1]}})(#B)([  $'\t']##|(#e))/${OPTS[${___opt_map[${match[1]}]%%:*}]::=1}ß←↓→}:#1ß←↓→}" )
}
# ]]]

#
# Ice support.
#

# FUNCTION: .zinit-ice. [[[
# Parses ICE specification, puts the result into ICE global hash.
# The ice-spec is valid for next command only (i.e. it "melts"), but
# it can then stick to plugin and activate e.g. at update.
.zinit-ice() {
    builtin setopt localoptions noksharrays extendedglob warncreateglobal typesetsilent noshortloops
    integer retval
    local bit exts="${(j:|:)${(@)${(@Akons:|:)${ZINIT_EXTS[ice-mods]//\'\'/}}/(#s)<->-/}}"
    for bit; do
        [[ $bit = (#b)(--|)(${~ZINIT[ice-list]}${~exts})(*) ]] && \
            ZINIT_ICES[${match[2]}]+="${ZINIT_ICES[${match[2]}]:+;}${match[3]#(:|=)}" || \
            break
        retval+=1
    done
    [[ ${ZINIT_ICES[as]} = program ]] && ZINIT_ICES[as]=command
    [[ -n ${ZINIT_ICES[on-update-of]} ]] && ZINIT_ICES[subscribe]="${ZINIT_ICES[subscribe]:-${ZINIT_ICES[on-update-of]}}"
    [[ -n ${ZINIT_ICES[pick]} ]] && ZINIT_ICES[pick]="${ZINIT_ICES[pick]//\$ZPFX/${ZPFX%/}}"
    return retval
} # ]]]
# FUNCTION: .zinit-pack-ice. [[[
# Remembers all ice-mods, assigns them to concrete plugin. Ice spec
# is in general forgotten for second-next command (that's why it's
# called "ice" - it melts), however they glue to the object (plugin
# or snippet) mentioned in the next command – for later use with e.g.
# `zinit update ...'.
.zinit-pack-ice() {
    ZINIT_SICE[$1${1:+${2:+/}}$2]+="${(j: :)${(qkv)ICE[@]}} "
    ZINIT_SICE[$1${1:+${2:+/}}$2]="${ZINIT_SICE[$1${1:+${2:+/}}$2]# }"
    return 0
} # ]]]
# FUNCTION: .zinit-load-ices. [[[
.zinit-load-ices() {
    local id_as="$1" ___key ___path
    local -a ice_order
    ice_order=(
        ${(As:|:)ZINIT[ice-list]}
        ${(@)${(A@kons:|:)${ZINIT_EXTS[ice-mods]//\'\'/}}/(#s)<->-/}
    )
    ___path="${ZINIT[PLUGINS_DIR]}/${id_as//\//---}"/._zinit
    # TODO snippet's dir computation…
    if [[ ! -d $___path ]] {
        if ! .zinit-get-object-path snippet "${id_as//\//---}"; then
            return 1
        fi
        ___path="$REPLY"/._zinit
    }
    for ___key ( "${ice_order[@]}" ) {
        (( ${+ICE[$___key]} )) && [[ ${ICE[$___key]} != +* ]] && continue
        [[ -e $___path/$___key ]] && ICE[$___key]="$(<$___path/$___key)"
    }
    [[ -n ${ICE[on-update-of]} ]] && ICE[subscribe]="${ICE[subscribe]:-${ICE[on-update-of]}}"
    [[ ${ICE[as]} = program ]] && ICE[as]=command
    [[ -n ${ICE[pick]} ]] && ICE[pick]="${ICE[pick]//\$ZPFX/${ZPFX%/}}"

    return 0
}
# ]]]
# FUNCTION: .zinit-setup-params. [[[
.zinit-setup-params() {
    emulate -LR zsh -o extendedglob
    reply=( ${(@)${(@s.;.)ICE[param]}/(#m)*/${${MATCH%%(-\>|→|=\>)*}//((#s)[[:space:]]##|[[:space:]]##(#e))}${${(M)MATCH#*(-\>|→|=\>)}:+\=${${MATCH#*(-\>|→|=\>)}//((#s)[[:space:]]##|[[:space:]]##(#e))}}} )
    (( ${#reply} )) && return 0 || return 1
}
# ]]]

#
# Turbo.
#

# FUNCTION: .zinit-run-task. [[[
# A backend, worker function of .zinit-scheduler. It obtains the tasks
# index and a few of its properties (like the type: plugin, snippet,
# service plugin, service snippet) and executes it first checking for
# additional conditions (like non-numeric wait'' ice).
#
# $1 - the pass number, either 1st or 2nd pass
# $2 - the time assigned to the task
# $3 - type: plugin, snippet, service plugin, service snippet
# $4 - task's index in the ZINIT[WAIT_ICE_...] fields
# $5 - mode: load or light
# $6 - the plugin-spec or snippet URL or alias name (from id-as'')
.zinit-run-task() {
    local ___pass="$1" ___t="$2" ___tpe="$3" ___idx="$4" ___mode="$5" ___id="${(Q)6}" ___opt="${(Q)7}" ___action ___s=1 ___retval=0

    local -A ICE ZINIT_ICE
    ICE=( "${(@Q)${(z@)ZINIT[WAIT_ICE_${___idx}]}}" )
    ZINIT_ICE=( "${(kv)ICE[@]}" )

    local ___id_as=${ICE[id-as]:-$___id}

    if [[ $___pass = 1 && ${${ICE[wait]#\!}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)} = <-> ]]; then
        ___action="${(M)ICE[wait]#\!}load"
    elif [[ $___pass = 1 && -n ${ICE[wait]#\!} ]] && { eval "${ICE[wait]#\!}" || [[ $(( ___s=0 )) = 1 ]]; }; then
        ___action="${(M)ICE[wait]#\!}load"
    elif [[ -n ${ICE[load]#\!} && -n $(( ___s=0 )) && $___pass = 3 && -z ${ZINIT_REGISTERED_PLUGINS[(r)$___id_as]} ]] && eval "${ICE[load]#\!}"; then
        ___action="${(M)ICE[load]#\!}load"
    elif [[ -n ${ICE[unload]#\!} && -n $(( ___s=0 )) && $___pass = 2 && -n ${ZINIT_REGISTERED_PLUGINS[(r)$___id_as]} ]] && eval "${ICE[unload]#\!}"; then
        ___action="${(M)ICE[unload]#\!}remove"
    elif [[ -n ${ICE[subscribe]#\!} && -n $(( ___s=0 )) && $___pass = 3 ]] && \
        { local -a fts_arr
          eval "fts_arr=( ${ICE[subscribe]}(DNms-$(( EPOCHSECONDS -
                 ZINIT[fts-${ICE[subscribe]}] ))) ); (( \${#fts_arr} ))" && \
             { ZINIT[fts-${ICE[subscribe]}]="$EPOCHSECONDS"; ___s=${+ICE[once]}; } || \
             (( 0 ))
        }
    then
        ___action="${(M)ICE[subscribe]#\!}load"
    fi

    if [[ $___action = *load ]]; then
        if [[ $___tpe = p ]]; then
            .zinit-load "${(@)=___id}" "" "$___mode"; (( ___retval += $? ))
        elif [[ $___tpe = s ]]; then
            .zinit-load-snippet $___opt "$___id"; (( ___retval += $? ))
        elif [[ $___tpe = p1 || $___tpe = s1 ]]; then
            (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
            zpty -b "${___id//\//:} / ${ICE[service]}" '.zinit-service '"${(M)___tpe#?}"' "$___mode" "$___id"'
        fi
        (( ${+ICE[silent]} == 0 && ${+ICE[lucid]} == 0 && ___retval == 0 )) && zle && zle -M "Loaded $___id"
    elif [[ $___action = *remove ]]; then
        (( ${+functions[.zinit-confirm]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh" || return 1
        [[ $___tpe = p ]] && .zinit-unload "$___id_as" "" -q
        (( ${+ICE[silent]} == 0 && ${+ICE[lucid]} == 0 && ___retval == 0 )) && zle && zle -M "Unloaded $___id_as"
    fi

    [[ ${REPLY::=$___action} = \!* ]] && zle && zle .reset-prompt

    return ___s
}
# ]]]

# FUNCTION: .zinit-submit-turbo. [[[
# If `zinit load`, `zinit light` or `zinit snippet`  will be
# preceded with `wait', `load', `unload' or `on-update-of`/`subscribe'
# ice-mods then the plugin or snipped is to be loaded in turbo-mode,
# and this function adds it to internal data structures, so that
# @zinit-scheduler can run (load, unload) this as a task.
.zinit-submit-turbo() {
    local tpe="$1" mode="$2" opt_uspl2="$3" opt_plugin="$4"

    ICE[wait]="${ICE[wait]%%.[0-9]##}"
    ZINIT[WAIT_IDX]=$(( ${ZINIT[WAIT_IDX]:-0} + 1 ))
    ZINIT[WAIT_ICE_${ZINIT[WAIT_IDX]}]="${(j: :)${(qkv)ICE[@]}}"
    ZINIT[fts-${ICE[subscribe]}]="${ICE[subscribe]:+$EPOCHSECONDS}"

    [[ $tpe = s* ]] && \
        local id="${${opt_plugin:+$opt_plugin}:-$opt_uspl2}" || \
        local id="${${opt_plugin:+$opt_uspl2${${opt_uspl2:#%*}:+/}$opt_plugin}:-$opt_uspl2}"

    if [[ ${${ICE[wait]}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)} = (\!|.|)<-> ]]; then
        ZINIT_TASKS+=( "$EPOCHSECONDS+${${ICE[wait]#(\!|.)}%%[^0-9]([^0-9]|)([^0-9]|)([^0-9]|)}+${${${(M)ICE[wait]%a}:+1}:-${${${(M)ICE[wait]%b}:+2}:-${${${(M)ICE[wait]%c}:+3}:-1}}} $tpe ${ZINIT[WAIT_IDX]} ${mode:-_} ${(q)id} ${opt_plugin:+${(q)opt_uspl2}}" )
    elif [[ -n ${ICE[wait]}${ICE[load]}${ICE[unload]}${ICE[subscribe]} ]]; then
        ZINIT_TASKS+=( "${${ICE[wait]:+0}:-1}+0+1 $tpe ${ZINIT[WAIT_IDX]} ${mode:-_} ${(q)id} ${opt_plugin:+${(q)opt_uspl2}}" )
    fi
}
# ]]]
# FUNCTION: -zinit_scheduler_add_sh. [[[
# Copies task into ZINIT_RUN array, called when a task timeouts.
# A small function ran from pattern in /-substitution as a math
# function.
-zinit_scheduler_add_sh() {
    local idx="$1" in_wait="$___ar2" in_abc="$___ar3" ver_wait="$___ar4" ver_abc="$___ar5"
    if [[ ( $in_wait = $ver_wait || $in_wait -ge 4 ) && $in_abc = $ver_abc ]]; then
        ZINIT_RUN+=( "${ZINIT_TASKS[$idx]}" )
        return 1
    else
        return idx
    fi
}
# ]]]
# FUNCTION: @zinit-scheduler. [[[
# Searches for timeout tasks, executes them. There's an array of tasks
# waiting for execution, this scheduler manages them, detects which ones
# should be run at current moment, decides to remove (or not) them from
# the array after execution.
#
# $1 - if "following", then it is non-first (second and more)
#      invocation of the scheduler; this results in chain of `sched'
#      invocations that results in repetitive @zinit-scheduler activity.
#
#      if "burst", then all tasks are marked timeout and executed one
#      by one; this is handy if e.g. a docker image starts up and
#      needs to install all turbo-mode plugins without any hesitation
#      (delay), i.e. "burst" allows to run package installations from
#      script, not from prompt.
#
@zinit-scheduler() {
    integer ___ret="${${ZINIT[lro-data]%:*}##*:}"
    # lro stands for lastarg-retval-option.
    [[ $1 = following ]] && sched +1 'ZINIT[lro-data]="$_:$?:${options[printexitvalue]}"; @zinit-scheduler following "${ZINIT[lro-data]%:*:*}"'
    [[ -n $1 && $1 != (following*|burst) ]] && { local THEFD="$1"; zle -F "$THEFD"; exec {THEFD}<&-; }
    [[ $1 = burst ]] && local -h EPOCHSECONDS=$(( EPOCHSECONDS+10000 ))
    ZINIT[START_TIME]="${ZINIT[START_TIME]:-$EPOCHREALTIME}"

    integer ___t=EPOCHSECONDS ___i correct
    local -a match mbegin mend reply
    local MATCH REPLY AFD; integer MBEGIN MEND

    [[ -o ksharrays ]] && correct=1

    if [[ -n $1 ]] {
        if [[ ${#ZINIT_RUN} -le 1 || $1 = following ]]  {
            () {
                builtin emulate -L zsh
                builtin setopt extendedglob
                # Example entry:
                # 1531252764+2+1 p 18 light zdharma/zsh-diff-so-fancy
                #
                # This either doesn't change ZINIT_TASKS entry - when
                # ___i is used in the ternary expression, or replaces
                # an entry with "<no-data>", i.e. ZINIT_TASKS[1] entry.
                integer ___idx1 ___idx2
                local ___ar2 ___ar3 ___ar4 ___ar5
                for (( ___idx1 = 0; ___idx1 <= 4; ___idx1 ++ )) {
                    for (( ___idx2 = 1; ___idx2 <= (___idx >= 4 ? 1 : 3); ___idx2 ++ )) {
                        # The following substitution could be just (well, 'just'..) this:
                        #
                        # ZINIT_TASKS=( ${ZINIT_TASKS[@]/(#b)([0-9]##)+([0-9]##)+([1-3])(*)/
                        # ${ZINIT_TASKS[$(( (${match[1]}+${match[2]}) <= $___t ?
                        # zinit_scheduler_add(___i++, ${match[2]},
                        # ${(M)match[3]%[1-3]}, ___idx1, ___idx2) : ___i++ ))]}} )
                        #
                        # However, there's a severe bug in Zsh <= 5.3.1 - use of the period
                        # (,) is impossible inside ${..//$arr[$(( ... ))]}.
                        ___i=2

                        ZINIT_TASKS=( ${ZINIT_TASKS[@]/(#b)([0-9]##)+([0-9]##)+([1-3])(*)/${ZINIT_TASKS[
                        $(( (___ar2=${match[2]}+1) ? (
                            (___ar3=${(M)match[3]%[1-3]}) ? (
                            (___ar4=___idx1+1) ? (
                            (___ar5=___idx2) ? (
                (${match[1]}+${match[2]}) <= $___t ?
                zinit_scheduler_add(___i++) : ___i++ )
                            : 1 )
                            : 1 )
                            : 1 )
                            : 1  ))]}} )
                        ZINIT_TASKS=( "<no-data>" ${ZINIT_TASKS[@]:#<no-data>} )
                    }
                }
            }
        }
    } else {
        add-zsh-hook -d -- precmd @zinit-scheduler
        add-zsh-hook -- chpwd @zinit-scheduler
        () {
            builtin emulate -L zsh
            builtin setopt extendedglob
            # No "+" in this pattern, it will match only "1531252764"
            # in "1531252764+2" and replace it with current time.
            ZINIT_TASKS=( ${ZINIT_TASKS[@]/(#b)([0-9]##)(*)/$(( ${match[1]} <= 1 ? ${match[1]} : ___t ))${match[2]}} )
        }
        # There's a bug in Zsh: first sched call would not be issued
        # until a key-press, if "sched +1 ..." would be called inside
        # zle -F handler. So it's done here, in precmd-handle code.
        sched +1 'ZINIT[lro-data]="$_:$?:${options[printexitvalue]}"; @zinit-scheduler following ${ZINIT[lro-data]%:*:*}'

        AFD=13371337 # for older Zsh + noclobber option
        exec {AFD}< <(LANG=C command sleep 0.002; builtin print run;)
	command true # workaround a Zsh bug, see: https://www.zsh.org/mla/workers/2018/msg00966.html
        zle -F "$AFD" @zinit-scheduler
    }

    local ___task ___idx=0 ___count=0 ___idx2
    # All wait'' objects.
    for ___task ( "${ZINIT_RUN[@]}" ) {
        .zinit-run-task 1 "${(@z)___task}" && ZINIT_TASKS+=( "$___task" )
        if [[ $(( ++___idx, ___count += ${${REPLY:+1}:-0} )) -gt 0 && $1 != burst ]] {
            AFD=13371337 # for older Zsh + noclobber option
            exec {AFD}< <(LANG=C command sleep 0.0002; builtin print run;)
            command true
            # The $? and $_ will be left unchanged automatically by Zsh.
            zle -F "$AFD" @zinit-scheduler
            break
        }
    }
    # All unload'' objects.
    for (( ___idx2=1; ___idx2 <= ___idx; ++ ___idx2 )) {
        .zinit-run-task 2 "${(@z)ZINIT_RUN[___idx2-correct]}"
    }
    # All load'' & subscribe'' objects.
    for (( ___idx2=1; ___idx2 <= ___idx; ++ ___idx2 )) {
        .zinit-run-task 3 "${(@z)ZINIT_RUN[___idx2-correct]}"
    }
    ZINIT_RUN[1-correct,___idx-correct]=()

    [[ ${ZINIT[lro-data]##*:} = on ]] && return 0 || return ___ret
}
# ]]]

#
# Exposed functions.
#

# FUNCTION: zinit. [[[
# Main function directly exposed to user, obtains subcommand and its
# arguments, has completion.
zinit() {
    local -A ICE ZINIT_ICE
    ICE=( "${(kv)ZINIT_ICES[@]}" )
    ZINIT_ICE=( "${(kv)ICE[@]}" )
    ZINIT_ICES=()

    integer ___retval ___retval2 ___correct
    local -a match mbegin mend
    local MATCH cmd ___q="\`" ___q2="'" IFS=$' \t\n\0'; integer MBEGIN MEND

    # An annex's subcommand might use the reply vars.
    match=( ${ZINIT_EXTS[(I)z-annex subcommand:$1]} )
    if (( !${#match} )) {
        local -a reply; local REPLY
    }

    [[ -o ksharrays ]] && ___correct=1

    local -A ___opt_map OPTS
    ___opt_map=(
        -q         opt_-q,--quiet:"update:[Turn off almost-all messages from the {cmd}update{rst} operation {b-lhi}FOR the objects{rst} which don't have any {b-lhi}new version{rst} available.] *:[Turn off any (or: almost-any) messages from the operation.]"
        --quiet    opt_-q,--quiet
        -v         opt_-v,--verbose:"Turn on more messages from the operation."
        --verbose  opt_-v,--verbose
        -r         opt_-r,--reset:"Reset the repository before updating (or remove the files for single-file snippets and gh-r plugins)."
        --reset    opt_-r,--reset
        -a         opt_-a,--all:"delete:[Delete {hi}all{rst} plugins and snippets.] update:[Update {b-lhi}all{rst} plugins and snippets.]"
        --all      opt_-a,--all
        -c         opt_-c,--clean:"Delete {b-lhi}only{rst} the {b-lhi}currently-not loaded{rst} plugins and snippets."
        --clean    opt_-c,--clean
        -y         opt_-y,--yes:"Automatically confirm any yes/no prompts."
        --yes      opt_-y,--yes
        -f         opt_-f,--force:"Force new download of the snippet file."
        --force    opt_-f,--force
        -p         opt_-p,--parallel:"Turn on concurrent, multi-thread update (of all objects)."
        --parallel opt_-p,--parallel
        -s         opt_-s,--snippets:"snippets:[Update only snippets (i.e.: skip updating plugins).] times:[Show times in seconds instead of milliseconds.]"
        --snippets opt_-s,--snippets
        -L         opt_-l,--plugins:"Update only plugins (i.e.: skip updating snippets)."
        --plugins  opt_-l,--plugins
        -h         opt_-h,--help:"Show this help message."
        --help     opt_-h,--help
        -u         opt_-u,--urge:"Cause all the hooks like{ehi}:{rst} {ice}atpull{apo}''{rst}, {ice}cp{apo}''{rst}, etc. to execute even when there aren't any new commits {b}/{rst} any new version of the {b}{meta}gh-r{rst} file {b}/{rst} etc.{…} available for download {ehi}{lr}{rst} simulate a non-empty update."
        --urge     opt_-u,--urge
        -n         opt_-n,--no-pager:"Disable the use of the pager."
        --no-pager opt_-n,--no-pager
        -m         opt_-m,--moments:"Show the {apo}*{b-lhi}moments{apo}*{rst} of object (i.e.: a plugin or snippet) loading time."
        --moments  opt_-m,--moments
        -b         opt_-b,--bindkeys:"Load in light mode, however do still track {cmd}bindkey{rst} calls (to allow remapping the keys bound)."
        --bindkeys opt_-b,--bindkeys
        -x         opt_-x,--command:"Load the snippet as a {cmd}command{rst}, i.e.: add it to {var}\$PATH{rst} and set {b-lhi}+x{rst} on it."
        --command  opt_-x,--command
        env-whitelist "-h|--help|-v|--verbose"
        update        "-L|--plugins|-s|--snippets|-p|--parallel|-a|--all|\
-q|--quiet|-r|--reset|-u|--urge|-n|--no-pager|-v|--verbose|-h|--help"
        delete        "-a|--all|-c|--clean|-y|--yes|-q|--quiet|-h|--help"
        unload        "-h|--help|-q|--quiet"
        cdclear       "-h|--help|-q|--quiet"
        cdreplay      "-h|--help|-q|--quiet"
        times         "-h|--help|-m|-s"
        light         "-h|--help|-b"
        snippet       "-h|--help|-f|--force|--command|-x"
    )

    cmd="$1"
    if [[ $cmd == (times|unload|env-whitelist|update|snippet|load|light|cdreplay|\
cdclear|delete) ]]; then
        if (( $@[(I)-*] || OPTS[opt_-h,--help] )); then
            .zinit-parse-opts "$cmd" "$@"
            if (( OPTS[opt_-h,--help] )); then
                +zinit-prehelp-usage-message $cmd $___opt_map[$cmd] $@
                return 1;
            fi
        fi
    fi

    reply=( ${ZINIT_EXTS[(I)z-annex subcommand:*]} )

    [[ -n $1 && $1 != (-h|--help|help|man|self-update|times|zstatus|load|light|unload|snippet|ls|ice|\
update|status|report|delete|loaded|list|cd|create|edit|glance|stress|changes|recently|clist|\
completions|cclear|cdisable|cenable|creinstall|cuninstall|csearch|compinit|dtrace|dstart|dstop|\
dunload|dreport|dclear|compile|uncompile|compiled|cdlist|cdreplay|cdclear|srv|recall|\
env-whitelist|bindkeys|module|add-fpath|fpath|run${reply:+|${(~j:|:)"${reply[@]#z-annex subcommand:}"}}) || $1 = (load|light|snippet) ]] && \
    {
        integer ___error
        if [[ $1 = (load|light|snippet) ]] {
            integer  ___is_snippet
            # Classic syntax -> simulate a call through the for-syntax.
            () {
                builtin setopt localoptions extendedglob
                : ${@[@]//(#b)([ $'\t']##|(#s))(-b|--command|-f|--force)([ $'\t']##|(#e))/${OPTS[${match[2]}]::=1}}
            } "$@"
            builtin set -- "${@[@]:#(-b|--command|-f|--force)}"
            [[ $1 = light && -z ${OPTS[(I)-b]} ]] && ICE[light-mode]=
            [[ $1 = snippet ]] && ICE[is-snippet]= || ___is_snippet=-1
            shift

            ZINIT_ICES=( "${(kv)ICE[@]}" )
            ICE=() ZINIT_ICE=()
            1="${1:+@}${1#@}${2:+/$2}"
            (( $# > 1 )) && { shift -p $(( $# - 1 )); }
            [[ -z $1 ]] && {
               +zinit-message "Argument needed, try: {cmd}help."
               return 1
            }
        } else {
            .zinit-ice "$@"
            ___retval2=$?
            local ___last_ice=${@[___retval2]}
            shift ___retval2
            if [[ $# -gt 0 && $1 != for ]] {
                +zinit-message -n "{b}{u-warn}ERROR{b-warn}:{rst} Unknown subcommand{ehi}:" \
                        "{apo}\`{cmd}$1{apo}\`{rst} "
                +zinit-prehelp-usage-message rst
                return 1
            } elif (( $# == 0 )) {
                ___error=1
            } else {
                shift
            }
        }
        integer ___had_wait
        local ___id ___ehid ___etid ___key
        local -a ___arr
        ZINIT[annex-exposed-processed-IDs]=
        if (( $# )) {
            local -a ___ices
            ___ices=( "${(kv)ZINIT_ICES[@]}" )
            ZINIT_ICES=()
            while (( $# )) {
                .zinit-ice "$@"
                ___retval2=$?
                local ___last_ice=${@[___retval2]}
                shift ___retval2
                if [[ -n $1 ]] {
                    ICE=( "${___ices[@]}" "${(kv)ZINIT_ICES[@]}" )
                    ZINIT_ICE=( "${(kv)ICE[@]}" ) ZINIT_ICES=()
                    integer ___msgs=${+ICE[debug]}
                    (( ___msgs )) && +zinit-message "{pre}zinit-main:{faint} Processing {pname}$1{faint}{…}{rst}"

                    # Delete up to the final space to get the previously-processed ID.
                    ZINIT[annex-exposed-processed-IDs]+="${___id:+ $___id}"

                    # Strip the ID-qualifier (`@') and GitHub domain from the ID.
                    ___id="${${1#@}%%(///|//|/)}"
                    (( ___is_snippet == -1 )) && ___id="${___id#https://github.com/}"

                    # Effective handle-ID – the label under which the object
                    # will be identified / referred-to by Zinit.
                    ___ehid="${ICE[id-as]:-$___id}"

                    # Effective remote-ID (i.e.: URL, GitHub username/repo,
                    # package name, etc.). teleid'' allows "overriding" of $1.
                    # In case of a package using teleid'', the value here
                    # is being took from the given ices, before disk-ices.
                    ___etid="${ICE[teleid]:-$___id}"

                    if (( ${+ICE[pack]} )); then
                        ___had_wait=${+ICE[wait]}
                        .zinit-load-ices "$___ehid"
                        # wait'' isn't possible via the disk-ices (for
                        # packages), only via the command's ice-spec.
                        [[ $___had_wait -eq 0 ]] && unset 'ICE[wait]'
                    fi

                    [[ ${ICE[id-as]} = (auto|) && ${+ICE[id-as]} == 1 ]] && ICE[id-as]="${___etid:t}"

                    integer  ___is_snippet=${${(M)___is_snippet:#-1}:-0}
                    () {
                        builtin setopt localoptions extendedglob
                        if [[ $___is_snippet -ge 0 && ( -n ${ICE[is-snippet]+1} || $___etid = ((#i)(http(s|)|ftp(s|)):/|(${(~kj.|.)ZINIT_1MAP}))* ) ]] {
                            ___is_snippet=1
                        }
                    } "$@"

                    local ___type=${${${(M)___is_snippet:#1}:+snippet}:-plugin}
                    reply=(
                        ${(on)ZINIT_EXTS2[(I)zinit hook:before-load-pre <->]}
                        ${(on)ZINIT_EXTS[(I)z-annex hook:before-load-<-> <->]}
                        ${(on)ZINIT_EXTS2[(I)zinit hook:before-load-post <->]}
                    )
                    for ___key in "${reply[@]}"; do
                        ___arr=( "${(Q)${(z@)ZINIT_EXTS[$___key]:-$ZINIT_EXTS2[$___key]}[@]}" )
                        "${___arr[5]}" "$___type" "$___id" "${ICE[id_as]}" \
                            "${(j: :)${(q)@[2,-1]}}" "${(j: :)${(qkv)___ices[@]}}" \
                            "${${___key##(zinit|z-annex) hook:}%% <->}" load
                        ___retval2=$?
                        if (( ___retval2 )) {
                            # An error is actually only an odd return code.
                            ___retval+=$(( ___retval2 & 1 ? ___retval2 : 0 ))
                            (( ___retval2 & 1 && $# )) && shift

                            # Override $@?
                            if (( ___retval2 & 2 )) {
                                local -a ___args
                                ___args=( "${(@Q)${(@z)ZINIT[annex-before-load:new-@]}}" )
                                builtin set -- "${___args[@]}"
                            }

                            # Override $___ices?
                            if (( ___retval2 & 4 )) {
                                local -a ___new_ices
                                ___new_ices=( "${(Q@)${(@z)ZINIT[annex-before-load:new-global-ices]}}" )
                                (( 0 == ${#___new_ices} % 2 )) && \
                                    ___ices=( "${___new_ices[@]}" ) || \
                                        { [[ ${ZINIT[MUTE_WARNINGS]} != (1|true|on|yes) ]] && \
                                            +zinit-message "{u-warn}Warning{b-warn}:{msg} Bad new-ices returned" \
                                                "from the annex{ehi}:{rst} {annex}${___arr[3]}{msg}," \
                                                "please file an issue report at:{url}" \
                                    "https://github.com/zdharma-continuum/${___arr[3]}/issues/new{msg}.{rst}"
                                            ___ices=(  ) ___retval+=7
                                        }
                            }
                            continue 2
                        }
                    done
                    integer ___action_load=0 ___turbo=0
                    if [[ -n ${(M)${+ICE[wait]}:#1}${ICE[load]}${ICE[unload]}${ICE[service]}${ICE[subscribe]} ]] {
                        ___turbo=1
                    }

                    if [[ -n ${ICE[trigger-load]} || \
                          ( ${+ICE[wait]} == 1 &&
                              ${ICE[wait]} = (\!|)(<->(a|b|c|)|) )
                       ]] && (( !ZINIT[OPTIMIZE_OUT_DISK_ACCESSES]
                    )) {
                        if (( ___is_snippet > 0 )) {
                            .zinit-get-object-path snippet $___ehid
                        } else {
                            .zinit-get-object-path plugin $___ehid
                        }
                        (( $? )) && [[ ${zsh_eval_context[1]} = file ]] && { ___action_load=1; }
                        local ___object_path="$REPLY"
                    } elif (( ! ___turbo )) {
                        ___action_load=1
                        reply=( 1 )
                    } else {
                        reply=( 1 )
                    }

                    if [[ ${reply[-1]} -eq 1 && -n ${ICE[trigger-load]} ]] {
                        () {
                            builtin setopt localoptions extendedglob
                            local ___mode
                            (( ___is_snippet > 0 )) && ___mode=snippet || ___mode="${${${ICE[light-mode]+light}}:-load}"
                            for MATCH ( ${(s.;.)ICE[trigger-load]} ) {
                                eval "${MATCH#!}() {
                                    ${${(M)MATCH#!}:+unset -f ${MATCH#!}}
                                    local a b; local -a ices
                                    # The wait'' ice is filtered-out.
                                    for a b ( ${(qqkv@)${(kv@)ICE[(I)^(trigger-load|wait|light-mode)]}} ) {
                                        ices+=( \"\$a\$b\" )
                                    }
                                    zinit ice \${ices[@]}; zinit $___mode ${(qqq)___id}
                                    ${${(M)MATCH#!}:+# Forward the call
                                    eval ${MATCH#!} \$@}
                                }"
                            }
                        } "$@"
                        ___retval+=$?
                        (( $# )) && shift
                        continue
                    }

                    if (( ${+ICE[if]} )) {
                        eval "${ICE[if]}" || { (( $# )) && shift; continue; };
                    }
                    for REPLY ( ${(s.;.)ICE[has]} ) {
                        (( ${+commands[$REPLY]} )) || \
                            { (( $# )) && shift; continue 2; }
                    }

                    integer ___had_cloneonly=0
                    ICE[wait]="${${(M)${+ICE[wait]}:#1}:+${(M)ICE[wait]#!}${${ICE[wait]#!}:-0}}"
                    if (( ___action_load || !ZINIT[HAVE_SCHEDULER] )) {
                        if (( ___turbo && ZINIT[HAVE_SCHEDULER] )) {
                            ___had_cloneonly=${+ICE[cloneonly]}
                            ICE[cloneonly]=""
                        }

                        (( ___is_snippet )) && \
                            local ___opt="${(k)OPTS[*]}" || \
                            local ___opt="${${ICE[light-mode]+light}:-${OPTS[(I)-b]:+light-b}}"

                        .zinit-load-object ${${${(M)___is_snippet:#1}:+snippet}:-plugin} $___id $___opt
                        integer ___last_retval=$?
                        ___retval+=___last_retval

                        if (( ___turbo && !___had_cloneonly && ZINIT[HAVE_SCHEDULER] )) {
                            command rm -f $___object_path/._zinit/cloneonly
                            unset 'ICE[cloneonly]'
                        }
                    }
                    if (( ___turbo && ZINIT[HAVE_SCHEDULER] && 0 == ___last_retval )) {
                        ICE[wait]="${ICE[wait]:-${ICE[service]:+0}}"
                        if (( ___is_snippet > 0 )); then
                            ZINIT_SICE[$___ehid]=
                            .zinit-submit-turbo s${ICE[service]:+1} "" \
                                "$___id" "${(k)OPTS[*]}"
                        else
                            ZINIT_SICE[$___ehid]=
                            .zinit-submit-turbo p${ICE[service]:+1} \
                                "${${${ICE[light-mode]+light}}:-load}" \
                                "$___id" ""
                        fi
                        ___retval+=$?
                    }
                } else {
                    ___error=1
                }
                (( $# )) && shift
                ___is_snippet=0
            }
        } else {
            ___error=1
        }

        if (( ___error )) {
            () {
                emulate -LR zsh -o extendedglob
                +zinit-message -n "{u-warn}Error{b-warn}:{rst} No plugin or snippet ID given"
                if [[ -n $___last_ice ]] {
                    +zinit-message -n " (the last recognized ice was: {ice}"\
"${___last_ice/(#m)(${~ZINIT[ice-list]})/"{data}$MATCH"}{apo}''{rst}).{error}
You can try to prepend {apo}${___q}{lhi}@{apo}'{error} to the ID if the last ice is in fact a plugin.{rst}
{note}Note:{rst} The {apo}\`{ice}ice{apo}\`{rst} subcommand is now again required if not using the for-syntax"
                }
                +zinit-message "."
            }
            return 2
       } elif (( ! $# )) {
           return ___retval
       }
    }

    case "$1" in
       (ice)
           shift
           .zinit-ice "$@"
           ;;
       (cdreplay)
           .zinit-compdef-replay "$2"; ___retval=$?
           ;;
       (cdclear)
           .zinit-compdef-clear "$2"
           ;;
       (add-fpath|fpath)
           .zinit-add-fpath "${@[2-correct,-1]}"
           ;;
       (run)
           .zinit-run "${@[2-correct,-1]}"
           ;;
       (dstart|dtrace)
            (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
           .zinit-debug-start
           ;;
       (dstop)
            (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
           .zinit-debug-stop
           ;;
       (man)
           man "${ZINIT[BIN_DIR]}/doc/zinit.1"
           ;;
       (env-whitelist)
            shift
            .zinit-parse-opts env-whitelist "$@"
            builtin set -- "${reply[@]}"

            if (( $# == 0 )) {
                ZINIT[ENV-WHITELIST]=
                (( OPTS[opt_-v,--verbose] )) && +zinit-message "{msg2}Cleared the parameter whitelist.{rst}"
            } else {
                ZINIT[ENV-WHITELIST]+="${(j: :)${(q-kv)@}} "
                local ___sep="$ZINIT[col-msg2], $ZINIT[col-data2]"
                (( OPTS[opt_-v,--verbose] )) && +zinit-message "{msg2}Extended the parameter whitelist with: {data2}${(pj:$___sep:)@}{msg2}.{rst}"
            }
            ;;
       (*)
           # Check if there is a z-annex registered for the subcommand.
           reply=( ${ZINIT_EXTS[z-annex subcommand:${(q)1}]} )
           (( ${#reply} )) && {
               reply=( "${(Q)${(z@)reply[1]}[@]}" )
               (( ${+functions[${reply[5]}]} )) && \
                   { "${reply[5]}" "$@"; return $?; } || \
                   { +zinit-message "({error}Couldn't find the subcommand-handler \`{obj}${reply[5]}{error}' of the z-annex \`{file}${reply[3]}{error}')"; return 1; }
           }
           (( ${+functions[.zinit-confirm]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh" || return 1
           case "$1" in
                (zstatus)
                    .zinit-show-zstatus
                    ;;
                (times)
                    .zinit-show-times "${@[2-correct,-1]}"
                    ;;
                (self-update)
                    .zinit-self-update
                    ;;
                (unload)
                    (( ${+functions[.zinit-unload]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh" || return 1
                    if [[ -z $2 && -z $3 ]]; then
                        builtin print "Argument needed, try: help"; ___retval=1
                    else
                        [[ $2 = -q ]] && { 5=-q; shift; }
                        # Unload given plugin. Cloned directory remains intact
                        # so as are completions.
                        .zinit-unload "${2%%(///|//|/)}" "${${3:#-q}%%(///|//|/)}" "${${(M)4:#-q}:-${(M)3:#-q}}"; ___retval=$?
                    fi
                    ;;
                 (bindkeys)
                    .zinit-list-bindkeys
                    ;;
                 (update)
                    if (( ${+ICE[if]} )) {
                        eval "${ICE[if]}" || return 1;
                    }
                    for REPLY ( ${(s.;.)ICE[has]} ) {
                        (( ${+commands[$REPLY]} )) || return 1
                    }

                    shift
                    .zinit-parse-opts update "$@"
                    builtin set -- "${reply[@]}"
                    if [[ ${OPTS[opt_-a,--all]} -eq 1 || ${OPTS[opt_-p,--parallel]} -eq 1 || ${OPTS[opt_-s,--snippets]} -eq 1 || ${OPTS[opt_-l,--plugins]} -eq 1 || -z $1$2${ICE[teleid]}${ICE[id-as]} ]]; then
                        [[ -z $1$2 && $(( OPTS[opt_-a,--all] + OPTS[opt_-p,--parallel] + OPTS[opt_-s,--snippets] + OPTS[opt_-l,--plugins] )) -eq 0 ]] && { builtin print -r -- "Assuming --all is passed"; sleep 3; }
                        (( OPTS[opt_-p,--parallel] )) && OPTS[value]=${1:-15}
                        .zinit-update-or-status-all update; ___retval=$?
                    else
                        local ___key ___id="${1%%(///|//|/)}${2:+/}${2%%(///|//|/)}"
                        [[ -z ${___id//[[:space:]]/} ]] && ___id="${ICE[id-as]:-$ICE[teleid]}"
                        .zinit-update-or-status update "$___id" ""; ___retval=$?
                    fi
                    ;;
                (status)
                    if [[ $2 = --all || ( -z $2 && -z $3 ) ]]; then
                        [[ -z $2 ]] && { builtin print -r -- "Assuming --all is passed"; sleep 3; }
                        .zinit-update-or-status-all status; ___retval=$?
                    else
                        .zinit-update-or-status status "${2%%(///|//|/)}" "${3%%(///|//|/)}"; ___retval=$?
                    fi
                    ;;
                (report)
                    if [[ $2 = --all || ( -z $2 && -z $3 ) ]]; then
                        [[ -z $2 ]] && { builtin print -r -- "Assuming --all is passed"; sleep 4; }
                     .zinit-show-all-reports
                    else
                        .zinit-show-report "${2%%(///|//|/)}" "${3%%(///|//|/)}"; ___retval=$?
                    fi
                    ;;
                (loaded|list)
                    # Show list of loaded plugins.
                    .zinit-show-registered-plugins "$2"
                    ;;
                (clist|completions)
                    # Show installed, enabled or disabled, completions.
                    # Detect stray and improper ones.
                    .zinit-show-completions "$2"
                    ;;
                (cclear)
                    # Delete stray and improper completions.
                    .zinit-clear-completions
                    ;;
                (cdisable)
                    if [[ -z $2 ]]; then
                        builtin print "Argument needed, try: help"; ___retval=1
                    else
                        local ___f="_${2#_}"
                        # Disable completion given by completion function name
                        # with or without leading _, e.g. cp, _cp.
                        if .zinit-cdisable "$___f"; then
                            (( ${+functions[.zinit-forget-completion]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
                            .zinit-forget-completion "$___f"
                            +zinit-message "Initializing completion system ({func}compinit{rst}){…}"
                            builtin autoload -Uz compinit
                            compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
                        else
                            ___retval=1
                        fi
                    fi
                    ;;
                (cenable)
                    if [[ -z $2 ]]; then
                        builtin print "Argument needed, try: help"; ___retval=1
                    else
                         local ___f="_${2#_}"
                        # Enable completion given by completion function name
                        # with or without leading _, e.g. cp, _cp.
                        if .zinit-cenable "$___f"; then
                            (( ${+functions[.zinit-forget-completion]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
                            .zinit-forget-completion "$___f"
                            +zinit-message "Initializing completion system ({func}compinit{rst}){…}"
                            builtin autoload -Uz compinit
                            compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
                        else
                            ___retval=1
                        fi
                    fi
                    ;;
                (creinstall)
                    (( ${+functions[.zinit-install-completions]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
                    # Installs completions for plugin. Enables them all. It's a
                    # reinstallation, thus every obstacle gets overwritten or removed.
                    [[ $2 = -[qQ] ]] && { 5=$2; shift; }
                    .zinit-install-completions "${2%%(///|//|/)}" "${3%%(///|//|/)}" 1 "${(M)4:#-[qQ]}"; ___retval=$?
                    [[ -z ${(M)4:#-[qQ]} ]] && +zinit-message "Initializing completion ({func}compinit{rst}){…}"
                    builtin autoload -Uz compinit
                    compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
                    ;;
                (cuninstall)
                    if [[ -z $2 && -z $3 ]]; then
                        builtin print "Argument needed, try: help"; ___retval=1
                    else
                        (( ${+functions[.zinit-forget-completion]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
                        # Uninstalls completions for plugin.
                        .zinit-uninstall-completions "${2%%(///|//|/)}" "${3%%(///|//|/)}"; ___retval=$?
                        +zinit-message "Initializing completion ({func}compinit{rst}){…}"
                        builtin autoload -Uz compinit
                        compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"
                    fi
                    ;;
                (csearch)
                    .zinit-search-completions
                    ;;
                (compinit)
                    (( ${+functions[.zinit-forget-completion]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
                    .zinit-compinit; ___retval=$?
                    ;;
                (dreport)
                    .zinit-show-debug-report
                    ;;
                (dclear)
                    (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
                    .zinit-clear-debug-report
                    ;;
                (dunload)
                    (( ${+functions[.zinit-service]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-additional.zsh"
                    .zinit-debug-unload
                    ;;
                (compile)
                    (( ${+functions[.zinit-compile-plugin]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-install.zsh" || return 1
                    if [[ $2 = --all || ( -z $2 && -z $3 ) ]]; then
                        [[ -z $2 ]] && { builtin print -r -- "Assuming --all is passed"; sleep 3; }
                        .zinit-compile-uncompile-all 1; ___retval=$?
                    else
                        .zinit-compile-plugin "${2%%(///|//|/)}" "${3%%(///|//|/)}"; ___retval=$?
                    fi
                    ;;
                (uncompile)
                    if [[ $2 = --all || ( -z $2 && -z $3 ) ]]; then
                        [[ -z $2 ]] && { builtin print -r -- "Assuming --all is passed"; sleep 3; }
                        .zinit-compile-uncompile-all 0; ___retval=$?
                    else
                        .zinit-uncompile-plugin "${2%%(///|//|/)}" "${3%%(///|//|/)}"; ___retval=$?
                    fi
                    ;;
                (compiled)
                    .zinit-compiled
                    ;;
                (cdlist)
                    .zinit-list-compdef-replay
                    ;;
                (cd|delete|recall|edit|glance|changes|create|stress)
                    .zinit-"$1" "${@[2-correct,-1]%%(///|//|/)}"; ___retval=$?
                    ;;
                (recently)
                    shift
                    .zinit-recently "$@"; ___retval=$?
                    ;;
                (-h|--help|help)
                    .zinit-help
                    ;;
                (ls)
                    shift
                    .zinit-ls "$@"
                    ;;
                (srv)
                    () { setopt localoptions extendedglob warncreateglobal
                    [[ ! -e ${ZINIT[SERVICES_DIR]}/"$2".fifo ]] && { builtin print "No such service: $2"; } ||
                        { [[ $3 = (#i)(next|stop|quit|restart) ]] &&
                            { builtin print "${(U)3}" >>! ${ZINIT[SERVICES_DIR]}/"$2".fifo || builtin print "Service $2 inactive"; ___retval=1; } ||
                                { [[ $3 = (#i)start ]] && rm -f ${ZINIT[SERVICES_DIR]}/"$2".stop ||
                                    { builtin print "Unknown service-command: $3"; ___retval=1; }
                                }
                        }
                    } "$@"
                    ;;
                (module)
                    .zinit-module "${@[2-correct,-1]}"; ___retval=$?
                    ;;
                 (*)
                     if [[ -z $1 ]] {
                         +zinit-message -n "{b}{u-warn}ERROR{b-warn}:{rst} Missing a {cmd}subcommand "
                         +zinit-prehelp-usage-message rst
                     } else {
                         +zinit-message -n "{b}{u-warn}ERROR{b-warn}:{rst} Unknown subcommand{ehi}:{rst}" \
                                 "{apo}\`{error}$1{apo}\`{rst} "
                         +zinit-prehelp-usage-message rst
                     }
                     ___retval=1
                     ;;
             esac
             ;;
    esac

    return ___retval
} # ]]]
# FUNCTION: zicdreplay. [[[
# A function that can be invoked from within `atinit', `atload', etc.
# ice-mod.  It works like `zinit cdreplay', which cannot be invoked
# from such hook ices.
zicdreplay() { .zinit-compdef-replay -q; }
# ]]]
# FUNCTION: zicdclear. [[[
# A wrapper for `zinit cdclear -q' which can be called from hook
# ices like the atinit'', atload'', etc. ices.
zicdclear() { .zinit-compdef-clear -q; }
# ]]]
# FUNCTION: zicompinit. [[[
# A function that can be invoked from within `atinit', `atload', etc.
# ice-mod.  It runs `autoload compinit; compinit' and respects
# ZINIT[ZCOMPDUMP_PATH] and ZINIT[COMPINIT_OPTS].
zicompinit() { autoload -Uz compinit; compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"; }
# ]]]
# FUNCTION: zicompdef. [[[
# Stores compdef for a replay with `zicdreplay' (turbo mode) or
# with `zinit cdreplay' (normal mode). An utility functton of
# an undefined use case.
zicompdef() { ZINIT_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" ); }
# ]]]
# FUNCTION: @autoload. [[[
@autoload() {
    :zinit-tmp-subst-autoload -Uz \
        ${(s: :)${${(j: :)${@#\!}}//(#b)((*)(->|=>|→)(*)|(*))/${match[2]:+$match[2] -S $match[4]}${match[5]:+${match[5]} -S ${match[5]}}}} \
        ${${${(@M)${@#\!}:#*(->|=>|→)*}}:+-C} ${${@#\!}:+-C}
}
# ]]]

# Compatibility functions. [[[
zplugin() { zinit "$@"; }
zpcdreplay() { .zinit-compdef-replay -q; }
zpcdclear() { .zinit-compdef-clear -q; }
zpcompinit() { autoload -Uz compinit; compinit -d ${ZINIT[ZCOMPDUMP_PATH]:-${ZDOTDIR:-$HOME}/.zcompdump} "${(Q@)${(z@)ZINIT[COMPINIT_OPTS]}}"; }
zpcompdef() { ZINIT_COMPDEF_REPLAY+=( "${(j: :)${(q)@}}" ); }
# ]]]

#
# Source-executed code.
#

(( ZINIT[ALIASES_OPT] )) && builtin setopt aliases
(( ZINIT[SOURCED] ++ )) && return

autoload add-zsh-hook
if { zmodload zsh/datetime } {
    add-zsh-hook -- precmd @zinit-scheduler  # zsh/datetime required for wait/load/unload ice-mods
    ZINIT[HAVE_SCHEDULER]=1
}
functions -M -- zinit_scheduler_add 1 1 -zinit_scheduler_add_sh 2>/dev/null
zmodload zsh/zpty zsh/system 2>/dev/null
zmodload -F zsh/stat b:zstat 2>/dev/null && ZINIT[HAVE_ZSTAT]=1

# code. [[[
builtin alias zpl=zinit zplg=zinit zi=zinit zini=zinit

.zinit-prepare-home

# Remember source's timestamps for the automatic-reload feature.
typeset -g ZINIT_TMP
for ZINIT_TMP ( "" -side -install -autoload ) {
    .zinit-get-mtime-into "${ZINIT[BIN_DIR]}/zinit$ZINIT_TMP.zsh" "ZINIT[mtime$ZINIT_TMP]"
}

# Simulate existence of _local/zinit plugin.
# This will allow to cuninstall of its completion
ZINIT_REGISTERED_PLUGINS=( _local/zinit "${(u)ZINIT_REGISTERED_PLUGINS[@]:#_local/zinit}" )
ZINIT[STATES___local/zinit]=1

# Inform Prezto that the compdef function is available.
zstyle ':prezto:module:completion' loaded 1

# Colorize completions for commands unload, report, creinstall, cuninstall.
zstyle ':completion:*:zinit:argument-rest:plugins' list-colors '=(#b)(*)/(*)==1;35=1;33'
zstyle ':completion:*:zinit:argument-rest:plugins' matcher 'r:|=** l:|=*'
zstyle ':completion:*:*:zinit:*' group-name ""
# ]]]

# module recompilation for the project rename. [[[
if [[ -e ${${ZINIT[BIN_DIR]}}/zmodules/Src/zdharma/zplugin.so ]] {
    if [[ ! -f ${${ZINIT[BIN_DIR]}}/zmodules/COMPILED_AT || ( ${${ZINIT[BIN_DIR]}}/zmodules/COMPILED_AT -ot ${${ZINIT[BIN_DIR]}}/zmodules/RECOMPILE_REQUEST ) ]] {
        # Don't trust access times and verify hard stored values.
        [[ -e ${${ZINIT[BIN_DIR]}}/module/COMPILED_AT ]] && local compiled_at_ts="$(<${${ZINIT[BIN_DIR]}}/module/COMPILED_AT)"
        [[ -e ${${ZINIT[BIN_DIR]}}/module/RECOMPILE_REQUEST ]] && local recompile_request_ts="$(<${${ZINIT[BIN_DIR]}}/module/RECOMPILE_REQUEST)"

        if [[ ${recompile_request_ts:-1} -gt ${compiled_at_ts:-0} ]] {
            +zinit-message "{u-warn}WARNING{b-warn}:{rst}{msg} A {lhi}recompilation{rst}" \
                "of the Zinit module has been requested… {hi}Building{rst}…"
            (( ${+functions[.zinit-confirm]} )) || builtin source "${ZINIT[BIN_DIR]}/zinit-autoload.zsh" || return 1
            command make -C "${ZINIT[BIN_DIR]}/zmodules" distclean &>/dev/null
            .zinit-module build &>/dev/null
            if command make -C "${ZINIT[BIN_DIR]}/zmodules" &>/dev/null; then
                +zinit-message "{ok}Build successful!{rst}"
            else
                builtin print -r -- "${ZINIT[col-error]}Compilation failed.${ZINIT[col-rst]}" \
                     "${ZINIT[col-pre]}You can enter the following command:${ZINIT[col-rst]}" \
                     'make -C "${ZINIT[BIN_DIR]}/zmodules' \
                     "${ZINIT[col-pre]}to see the error messages and e.g.: report an issue" \
                     "at GitHub${ZINIT[col-rst]}"
            fi

            command date '+%s' >! "${ZINIT[BIN_DIR]}/zmodules/COMPILED_AT"
        }
    }
}
# ]]]

# !atpull-pre.
@zinit-register-hook "-r/--reset" hook:e-\!atpull-pre ∞zinit-reset-hook
# !atpull-post.
@zinit-register-hook "ICE[reset]" hook:e-\!atpull-post ∞zinit-reset-hook
@zinit-register-hook "atpull'!'" hook:e-\!atpull-post ∞zinit-atpull-e-hook

# e-!atpull-pre.
@zinit-register-hook "make'!!'" hook:no-e-\!atpull-pre ∞zinit-make-ee-hook
@zinit-register-hook "mv''" hook:no-e-\!atpull-pre ∞zinit-mv-hook
@zinit-register-hook "cp''" hook:no-e-\!atpull-pre ∞zinit-cp-hook
@zinit-register-hook "compile-plugin" hook:no-e-\!atpull-pre ∞zinit-compile-plugin-hook
# no-e-!atpull-post.
@zinit-register-hook "make'!'" hook:no-e-\!atpull-post ∞zinit-make-e-hook
@zinit-register-hook "atpull" hook:no-e-\!atpull-post ∞zinit-atpull-hook
@zinit-register-hook "make''" hook:no-e-\!atpull-post ∞zinit-make-hook
@zinit-register-hook "extract" hook:atpull-post ∞zinit-extract-hook
# atpull-post.
@zinit-register-hook "compile-plugin" hook:atpull-post ∞zinit-compile-plugin-hook
@zinit-register-hook "ps-on-update" hook:%atpull-post ∞zinit-ps-on-update-hook

# !atclone-pre.
@zinit-register-hook "make'!!'" hook:\!atclone-pre ∞zinit-make-ee-hook
@zinit-register-hook "mv''" hook:\!atclone-pre ∞zinit-mv-hook
@zinit-register-hook "cp''" hook:\!atclone-pre ∞zinit-cp-hook
@zinit-register-hook "compile-plugin" hook:\!atclone-pre ∞zinit-compile-plugin-hook
# !atclone-post.
@zinit-register-hook "make'!'" hook:\!atclone-post ∞zinit-make-e-hook
@zinit-register-hook "atclone" hook:\!atclone-post ∞zinit-atclone-hook
@zinit-register-hook "make''" hook:\!atclone-post ∞zinit-make-hook
@zinit-register-hook "extract" hook:\!atclone-post ∞zinit-extract-hook
# atclone-post.
@zinit-register-hook "compile-plugin" hook:atclone-post ∞zinit-compile-plugin-hook

# vim:ft=zsh:sw=4:sts=4:et:foldmarker=[[[,]]]:foldmethod=marker
