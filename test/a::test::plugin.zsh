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

setopt +9
setopt -w
setopt menucomplete
setopt -o nolist_types -o LIST_PACKED
#setopt -o automenu posix_cd -oautocd
#setopt \'pushd_minus
unsetopt +9
autoload -X test

fpath+=/usr/share/zsh

unset MY_VAR

bindkey -N testpluginmain main
bindkey -A testpluginmain main
