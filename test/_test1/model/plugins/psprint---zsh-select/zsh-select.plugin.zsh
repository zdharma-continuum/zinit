# Copy the file "zsh-select" to e.g. /usr/local/bin
# The package is also available as plugin. `zsh-select` will be
# available in interactive `Zsh` sessions only when using this
# method.

0="${(%):-%N}" # this gives immunity to functionargzero being unset
REPO_DIR="${0%/*}"
path+=( "$REPO_DIR" )
