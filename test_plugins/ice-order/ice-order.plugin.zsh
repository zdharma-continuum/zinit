0="${(%):-%N}"
fpath+=( $PWD )
local -a mkfiles
mkfiles=( answer/plugins/zdharma---ice-order/Makefile*(N:t) )
print -rl -- "${mkfiles[@]:t}" >! answer/file.lst
