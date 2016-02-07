#!/bin/zsh

setopt extendedglob

autoload colors
colors

local pre="==== "
local after=" ===="

# Normal tests
if [[ -z "$1" ]]; then
    echo -e ${fg_bold[magenta]}"${pre}normal tests${after}"$reset_color"\n"
    for i in test[0-9]##.zsh; do
        ./"$i"
        print
        print "${fg_bold[blue]}===================================================$reset_color"
        print
        print -n "Press any key for next test..."
        read -sk k
        echo -e "\n"
    done
fi

# KSH_ARRAYS
if [[ "$1" = "kshar" || -z "$1" ]]; then
    echo -e ${fg_bold[magenta]}"${pre}KSH_ARRAYS tests${after}"$reset_color"\n"
    for i in kshar_test[0-9]##.zsh; do
        ./"$i"
        print
        print "${fg_bold[blue]}===================================================$reset_color"
        print
        print -n "Press any key for next test..."
        read -sk k
        [ "$k" != $'\n' ] && print
        echo -e "\n"
    done
fi

# emulate sh
if [[ "$1" = "sh" || -z "$1" ]]; then
    echo -e ${fg_bold[magenta]}"${pre}emulate sh tests${after}"$reset_color"\n"
    for i in sh_test[0-9]##.zsh; do
        ./"$i"
        print
        print "${fg_bold[blue]}===================================================$reset_color"
        print
        print -n "Press any key for next test..."
        read -sk k
        [ "$k" != $'\n' ] && print
        echo -e "\n"
    done
fi
