#!/usr/bin/env zsh

emulate -R zsh
setopt extendedglob warncreateglobal typesetsilent rcquotes noshortloops

local zero=$'\0' r=$'\r' n=$'\n' IFS=
{ command perl -pe 'BEGIN { $|++; $/ = \1 }; tr/\r\n/\n\0/' || \
gstdbuf -o0 gtr '\r\n' '\n\0' || \
stdbuf -o0 tr '\r\n' '\n\0'; print } 2>/dev/null | \
	while read -r line; do
		if [[ $line == *$zero* ]]; then
			# Unused by cURL (there's no newline after the previous progress bar)
			#print -nr -- $r${(l:COLUMNS:: :):-}$r${line##*$zero}
			print -nr -- $r${(l:COLUMNS:: :):-}$r${line%$zero}
		else
			print -nr -- $r${(l:COLUMNS:: :):-}$r${${line//[$r$n]/}%\%*}${${(M)line%\%}:+%}
		fi
	done
print
