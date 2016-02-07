#!/bin/zsh

setopt extendedglob

autoload colors
colors

# NO_KSH_ARRAYS
if [[ "$1" = "sh" || -z "$1" ]]; then
    for i in test[0-9]##.zsh; do
        ./"$i"
        print
        print "${fg_bold[blue]}===================================================$reset_color"
        print
        print -n "Press any key for next test..."
        read -sk k
        print -e "\n"
    done
fi

# KSH_ARRAYS
if [[ "$1" = "ksh" || -z "$1" ]]; then
    for i in test[0-9]##_ksh.zsh; do
        ./"$i"
        print
        print "${fg_bold[blue]}===================================================$reset_color"
        print
        print -n "Press any key for next test..."
        read -sk k
        [ "$k" != $'\n' ] && print
        print -e "\n"
    done
fi
