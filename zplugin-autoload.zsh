0="${(%):-%N}"
0="${${(M)0:#/*}:-$PWD/$0}"
source ${0:A:h}/zinit-autoload.zsh
