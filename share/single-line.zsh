#!/usr/bin/env zsh
#
# Copyright (c) 2016-2020 Sebastian Gniazdowski and contributors
# Copyright (c) 2021-2022 zdharma-continuum and contributors

emulate -R zsh
setopt extendedglob noshortloops rcquotes typesetsilent warncreateglobal

local IFS= n=$'\n' r=$'\r' zero=$'\0'

{
  command perl -pe 'BEGIN { $|++; $/ = \1 }; tr/\r\n/\n\0/' \
    || gstdbuf -o0 gtr '\r\n' '\n\0' \
    || stdbuf -o0 tr '\r\n' '\n\0';
  print
} 2>/dev/null | while read -r line;
do
  if [[ $line == *$zero* ]]; then
    # cURL doesn't add a newline to progress bars
    # print -nr -- "${r}${(l:COLUMNS:: :):-}${r}${line##*${zero}}"
    print -nr -- "${r}${(l:COLUMNS:: :):-}${r}${line%${zero}}"
  else
    print -nr -- "${r}${(l:COLUMNS:: :):-}${r}${${line//[${r}${n}]/}%\%*}${${(M)line%\%}:+%}"
  fi
done

print