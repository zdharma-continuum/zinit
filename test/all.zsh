#!/usr/bin/env zsh

setopt extendedglob

___TEST_DIR="`pwd`"

if [[ "${___TEST_DIR/\/zplugin/}" = "${___TEST_DIR}" && "${___TEST_DIR/\/.zplugin}" = "${___TEST_DIR}" ]]; then
    echo "all.zsh run not from zplugin's directory tree"
    return 1
fi

if [ "${___TEST_DIR:t}" != "test" ]; then
    () {
        setopt localoptions extendedglob
        local -a match mbegin mend
        local MATCH; integer MBEGIN MEND

        if [ "${___TEST_DIR/\/zplugin/}" != "${___TEST_DIR}" ]; then
            ___TEST_DIR="${___TEST_DIR/\/zplugin*//zplugin/test}"
        else
            # Get what's after /.zplugin/
            tmp="${___TEST_DIR##*\/.zplugin\/}"
            # Only first directory after /.zplugin/
            tmp="${tmp%%/*}"
            ___TEST_DIR="${___TEST_DIR/\/.zplugin*//.zplugin/${tmp}/test}"
        fi
    }
fi

if [ ! -d "$___TEST_DIR" ]; then
    echo "Could not resolve test directory (tried $___TEST_DIR)"
    return 1
fi

cd "$___TEST_DIR"

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

# emulate ksh
if [[ "$1" = "ksh" || -z "$1" ]]; then
    echo -e ${fg_bold[magenta]}"${pre}emulate ksh tests${after}"$reset_color"\n"
    for i in ksh_test[0-9]##.zsh; do
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

# csh setopts
if [[ "$1" = "csh" || -z "$1" ]]; then
    echo -e ${fg_bold[magenta]}"${pre}csh setopts tests${after}"$reset_color"\n"
    for i in csh_test[0-9]##.zsh; do
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
