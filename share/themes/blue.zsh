
# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors.

ZINIT+=(
    col-pname   $'\e[1;38;5;27m' col-uname   $'\e[1;38;5;39m'     col-keyword $'\e[27m'
    col-note    $'\e[38;5;69m'   col-error   $'\e[1;38;5;9m'       col-p       $'\e[38;5;81m'
    col-info    $'\e[38;5;39m'   col-info2   $'\e[38;5;227m'       col-profile $'\e[38;5;69m'
    col-uninst  $'\e[38;5;118m'  col-info3   $'\e[1m\e[38;5;227m'  col-slight  $'\e[38;5;230m'
    col-failure $'\e[38;5;75m'   col-happy   $'\e[1m\e[38;5;39m'   col-annex   $'\e[38;5;33m'
    col-id-as   $'\e[1;4;38;5;75m'    col-version $'\e[3;38;5;69m'
    # The more recent, fresh ones:
    col-pre  $'\e[38;5;27m'   col-msg   $'\e[0m'       col-msg2  $'\e[38;5;174m'
    col-obj  $'\e[38;5;208m'  col-obj2  $'\e[38;5;69m' col-file  $'\e[3;38;5;41m'
    col-dir  $'\e[3;38;5;75m' col-func $'\e[38;5;208m'
    col-url  $'\e[38;5;75m'   col-meta  $'\e[38;5;69m' col-meta2 $'\e[38;5;39m'
    col-data $'\e[38;5;33m'   col-data2 $'\e[38;5;117m'   col-hi    $'\e[1m\e[38;5;208m'
    col-var  $'\e[38;5;81m'   col-glob  $'\e[1;38;5;118m' col-ehi   $'\e[1m\e[38;5;208m'
    col-cmd  $'\e[38;5;39m'   col-ice   $'\e[38;5;39m'    col-nl    $'\n'
    col-txt  $'\e[38;5;254m'  col-num  $'\e[3;38;5;155m'  col-term  $'\e[38;5;185m'
    col-warn $'\e[38;5;208m'  col-ok    $'\e[38;5;220m'   col-time  $'\e[38;5;220m'
    col-apo $'\e[1;38;5;45m'   col-aps $'\e[38;5;117m'
    col-quo $'\e[1;38;5;33m'   col-quos    $'\e[1;38;5;204m'
    col-bapo $'\e[1;38;5;208m' col-baps $'\e[1;38;5;39m'
    col-faint $'\e[38;5;238m'  col-opt   $'\e[1;38;5;75m'   col-lhi   $'\e[38;5;117m'
    col-flag  $'\e[1;3;38;5;69m' col-pkg $'\e[1;3;38;5;27m'
    col-tab  $' \t ' col-msg3  $'\e[38;5;238m'  col-b-lhi $'\e[1m\e[38;5;75m'
    col-bar  $'\e[38;5;39m'  col-th-bar $'\e[38;5;39m'
    col-…    "${${${(M)LANG:#*UTF-8*}:+…}:-...}"  col-ndsh  "${${${(M)LANG:#*UTF-8*}:+–}:-}"
    col-mdsh $'\e[1;38;5;220m'"${${${(M)LANG:#*UTF-8*}:+–}:--}"$'\e[0m'
    col-mmdsh $'\e[1;38;5;220m'"${${${(M)LANG:#*UTF-8*}:+――}:--}"$'\e[0m'
    col--…   "${${${(M)LANG:#*UTF-8*}:+⋯⋯}:-···}" col-lr    "${${${(M)LANG:#*UTF-8*}:+↔}:-"«-»"}"
    col-↔    ${${${(M)LANG:#*UTF-8*}:+$'\e[38;5;39m↔\e[0m'}:-$'\e[38;5;39m«-»\e[0m'}
    col-rst  $'\e[0m'  col-b      $'\e[1m'          col-nb     $'\e[22m'
    col-u    $'\e[4m'  col-it     $'\e[3m'          col-st     $'\e[9m'
    col-nu   $'\e[24m' col-nit    $'\e[23m'         col-nst    $'\e[29m'
    col-bspc $'\b'     col-b-warn $'\e[1;38;5;214m' col-u-warn $'\e[4;38;5;214m'
    col-bcmd $'\e[38;5;220m'
 )

# vim: ft=zsh sw=4 ts=4 et foldmarker=[[[,]]] foldmethod=marker
