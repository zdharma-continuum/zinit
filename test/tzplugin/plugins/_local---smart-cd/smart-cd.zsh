#!/usr/bin/env zsh

[ ! -n "${SMART_CD_LS+1}" ] && SMART_CD_LS=true
[ ! -n "${SMART_CD_GIT_STATUS+1}" ] && SMART_CD_GIT_STATUS=true

_smart_cd_lastgitdir=''
_smart_cd_chpwd_handler () {
  emulate -L zsh

  [[ $SMART_CD_LS == true ]] && ls -A

  if [[ $SMART_CD_GIT_STATUS == true ]]; then
    local gitdir="$(git rev-parse --git-dir 2>/dev/null)"
    if [[ -n "$gitdir" ]]; then
      gitdir="$gitdir:A" # absolute path of $gitdir
      [[ "$gitdir" != "$_smart_cd_lastgitdir" ]] && (echo; git status)
      _smart_cd_lastgitdir="$gitdir"
    fi
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd _smart_cd_chpwd_handler
_smart_cd_chpwd_handler
