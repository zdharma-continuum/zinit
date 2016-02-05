#!/usr/bin/env zsh

echo "Test plugin loading"

bindkey -v
alias aa=bb

REPO_DIR="${0%/*}"
CONFIG_DIR="$HOME/.config/zew"

bindkey -N testmap main
bindkey -M testmap -s "^[t" "echo test1"
bindkey -s "^[y" "echo test2"

# 10. Break line
if [[ "$MC_SID" != "" || "$MC_CONTROL_PID" != "" ]]; then
    bindkey "^J" accept-line
else
    bindkey "^J" self-insert
fi

# 11. Undo
bindkey "^_" undo

alias aaa2=bbb
alias -s gif=iv
alias -g LLL="|less"

[[ -n ${-[(r)9]} ]] && echo "Initially it's -9 (auto_list) set" || echo "Initially it's -9 (auto_list) unset"
setopt +9
[[ -n ${-[(r)w]} ]] && echo "Initially it's -w (chase_links) set" || echo "Initially it's -w (chase_links) unset"
setopt -w
[[ -o "menucomplete" ]] && echo "Initially it's menucomplete set" || echo "Initially it's menucomplete unset"
setopt menucomplete
[[ -o "listtypes" ]] && echo "Initially it's listtypes set" || echo "Initially it's listtypes unset"
[[ -o "listpacked" ]] && echo "Initially it's listpacked set" || echo "Initially it's listpacked unset"
setopt -o nolist_types -o LIST_PACKED
#setopt -o automenu posix_cd -oautocd
#setopt \'pushd_minus
unsetopt +9
autoload -X test

fpath+=/usr/share/zsh

unset MY_VAR

bindkey -N testpluginmain main
bindkey -A testpluginmain main
