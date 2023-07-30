# -*- mode: sh; sh-indentation: 4; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors.

 ZINIT+=(
    col-annex   $'\e[38;5;57m'         col-faint   $'\e[38;5;238m'         col-msg2    $'\e[38;5;172m'      col-quo     $'\e[1;38;5;172m'
    col-apo     $'\e[1;38;5;178m'        col-file    $'\e[3;38;5;178m'       col-msg3    $'\e[38;5;238m'      col-quos    $'\e[1;38;5;160m'
    col-aps     $'\e[38;5;57m'         col-flag    $'\e[1;3;38;5;178m'      col-nb      $'\e[22m'            col-rst     $'\e[0m'
    col-b       $'\e[1m'                col-func    $'\e[38;5;178m'         col-nit     $'\e[23m'            col-slight  $'\e[38;5;230m'
    col-b-lhi   $'\e[1;38;5;178m'     col-glob    $'\e[38;5;137m'
     col-nl      $'\n'                col-st      $'\e[9m'
    col-b-warn  $'\e[1;38;5;105m'       col-happy   $'\e[1m\e[38;5;82m'     col-note    $'\e[38;5;172m'      col-tab     $' \t '
    col-bapo    $'\e[1;38;5;220m'       col-hi      $'\e[1m\e[38;5;183m'    col-nst     $'\e[29m'            col-term    $'\e[38;5;172m'
    col-baps    $'\e[1;38;5;178m'        col-ice     $'\e[38;5;172m'          col-nu      $'\e[24m'            col-th-bar  $'\e[38;5;82m'
    col-bar     $'\e[38;5;172m'          col-id-as   $'\e[4;38;5;172m'       col-num     $'\e[3;38;5;172m'    col-time    $'\e[38;5;178m'
    col-bcmd    $'\e[38;5;178m'         col-info    $'\e[38;5;82m'          col-obj     $'\e[38;5;178m'      col-txt     $'\e[38;5;254m'
    col-bspc    $'\b'                   col-info2   $'\e[38;5;172m'         col-obj2    $'\e[38;5;172m'      col-u       $'\e[4m'
    col-cmd     $'\e[38;5;172m'          col-info3   $'\e[1m\e[38;5;178m'    col-ok      $'\e[38;5;220m'      col-u-warn  $'\e[4;38;5;214m'
    col-data    $'\e[38;5;178m'          col-it      $'\e[3m'                col-opt     $'\e[38;5;219m'      col-uname   $'\e[1;4m\e[33m'
    col-data2   $'\e[38;5;137m'         col-keyword $'\e[1;38;5;172m'               col-p       $'\e[38;5;178m'       col-uninst  $'\e[38;5;137m'
    col-dir     $'\e[3;38;5;178m'       col-lhi     $'\e[1;38;5;220m'          col-pkg     $'\e[1;3;38;5;178m'   col-url     $'\e[38;5;178m'
    col-ehi     $'\e[1m\e[38;5;153m'    col-meta    $'\e[38;5;57m'          col-pname   $'\e[1;4;32m'     col-var     $'\e[38;5;57m'
    col-error   $'\e[1m\e[38;5;204m'    col-meta2   $'\e[38;5;57m'         col-pre     $'\e[38;5;178m'      col-version $'\e[3;38;5;57m'
    col-failure $'\e[38;5;204m'         col-msg     $'\e[0m'                col-profile $'\e[38;5;57m'      col-warn    $'\e[38;5;57m'

    col-i $'\e[1m\e[38;5;57m'"==>"$'\e[0m' col-e $'\e[1;38;5;204m'"Error: "$'\e[0m'
    col-m $'\e[1;38;5;172m'"==>"$'\e[0m' col-w $'\e[1;38;5;57m'"Warning: "$'\e[0m'

    col--…   "${${${(M)LANG:#*UTF-8*}:+⋯⋯}:-···}"    col-lr "${${${(M)LANG:#*UTF-8*}:+↔}:-"«-»"}"
    col-ndsh "${${${(M)LANG:#*UTF-8*}:+–}:-}"        col-…  "${${${(M)LANG:#*UTF-8*}:+…}:-...}"

    col-mdsh  $'\e[1;38;5;220m'"${${${(M)LANG:#*UTF-8*}:+–}:--}"$'\e[0m'
    col-mmdsh $'\e[1;38;5;220m'"${${${(M)LANG:#*UTF-8*}:+――}:--}"$'\e[0m'

    col-↔     ${${${(M)LANG:#*UTF-8*}:+$'\e[38;5;82m↔\e[0m'}:-$'\e[38;5;82m«-»\e[0m'}

    col-ext   $'\e[1;38;5;41m'
)
if [[ -z $SOURCED && ( $+terminfo -eq 1 && \
                        $terminfo[colors] -ge 256) || \
      ( $+termcap -eq 1 && $termcap[Co] -ge 256 ) ]]
then
    ZINIT+=( col-pname $'\e[1;4;38;5;178m' col-uname  $'\e[1;4;38;5;220m' )
fi

# vim: ft=zsh sw=4 ts=4 et foldmarker=[[[,]]] foldmethod=marker
