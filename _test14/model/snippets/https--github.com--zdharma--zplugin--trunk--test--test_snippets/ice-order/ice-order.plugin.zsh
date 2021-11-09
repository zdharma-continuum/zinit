0="${(%):-%N}"
fpath+=( $PWD )
local -a mkfiles
mkfiles=(
    answer/snippets/https--github.com--zdharma--zinit--trunk--test--test_snippets/ice-order/Makefile*(N:t)
)
print -rl -- "${mkfiles[@]:t}" >! answer/file.lst
