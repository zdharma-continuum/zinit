#!/bin/zsh

setopt extendedglob

# NO_KSH_ARRAYS
if [[ "$1" = "sh" || -z "$1" ]]; then
    for i in test[0-9]##.zsh; do
        ./"$i"
        echo
        echo "==================================================="
        echo
    done
fi

# KSH_ARRAYS
if [[ "$1" = "ksh" || -z "$1" ]]; then
    for i in test[0-9]##_ksh.zsh; do
        ./"$i"
        echo
        echo "==================================================="
        echo
    done
fi
