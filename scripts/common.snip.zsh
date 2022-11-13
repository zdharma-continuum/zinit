#!/usr/bin/env zsh
# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-

# Copyright (c) 2022 Sebastian Gniazdowski

# Set the base and typically useful options
builtin emulate -L zsh
builtin setopt extendedglob warncreateglobal typesetsilent noshortloops \
        noautopushd multios

# Set $0 given.
local -A ZINIT=( BIN_DIR $2 )
0=$ZINIT[BIN_DIR]/lib/common.snip.zsh

# Such global variable is expected to be typeset'd -g in the plugin.zsh
# file. Here it's restored in case of the function being run as a script.
typeset -gA Plugins
typeset -g ZICMD_NULL
Plugins[ZICMD_DIR]=$ZINIT[BIN_DIR]
Plugins[ZICMD_CUR_SUB_CMD]=$1
# Export crucial paths.
Plugins[ZICMD_FILE_CHARS]='[[:alnum:]+_%@…\[\]\{\}\(\):.,\?\~\!\/–—-]'

# Export.
typeset -gx ZICMD_NULL
: ${CMD_NULL:=/dev/null}

{ zmodload zsh/system && zsystem supports flock
  Plugins+=( CMD_FLOCK_AVAIL $((!$?)) ); 
  zmodload zsh/datetime
  Plugins+=( CMD_DATETIME_AVAIL $((!$?)) ); 
  zmodload zsh/stat
  Plugins+=( CMD_ZSTAT_AVAIL $((!$?)) ); 
} \
    &>/dev/null

# Cleanup on exit.
trap 'fpath=( ${fpath[@]:#$Plugins[ZICMD_DIR]/functions} )' EXIT
trap 'fpath=( ${fpath[@]:#$Plugins[ZICMD_DIR]/functions} ); return 0' INT
local -a mbegin mend match reply
integer MBEGIN MEND
local MATCH REPLY

fpath+=( $ZINIT[BIN_DIR]/functions )
local -a func=( $ZINIT[BIN_DIR]/functions/*~*~(N:t) )
builtin autoload -U $func

zi-non-empty() {
    builtin emulate -L zsh -o extendedglob

    # Not space and slash only string?
    [[ $1 != ([[:space:]]#|/#) ]]
}

# vim:ft=zsh:tw=80:sw=4:sts=4:et:foldmarker=[[[,]]]
