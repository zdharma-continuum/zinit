# -*- mode: sh; sh-indentation: 4; sh-basic-offset: 4; -*-

# Copyright (c) 2020 Sebastian Gniazdowski
# License MIT

# Get $0 according to the Zsh Plugin Standard:
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html#zero-handling

0="${${ZERO:-${(%):-%x}}:P}"
local ZERO="$0"

# According to the Zsh Plugin Standard:
# https://zdharma-continuum.github.io/Zsh-100-Commits-Club/Zsh-Plugin-Standard.html#std-hash
() {
emulate -L zsh -o extendedglob -o warncreateglobal -o noshortloops \
                -o noautopushd -o typesetsilent

0=$ZERO
typeset -gA Plugins
Plugins[MG_0]=$0
Plugins[MG_DIR]=$0:h

# Verify $0
[[ -f $Plugins[MG_DIR]/mg.annex.zsh ]] || return 1

# Autoload all functions
autoload -Uz .nop-fn $Plugins[MG_DIR]/functions/mg::*~*~(N.,@:t)

# The mg-support hook.
@zinit-register-annex "zinit-annex-mg" \
    hook:before-load-3 \
    mg::before-load-handler \
    mg::help-null-handler \
    "keep|mg" # New ices

# The subcommand `xmg'.
@zinit-register-annex "zinit-annex-mg" \
    subcommand:xmg \
    mg::cmd \
    mg::help-handler
}

# vim:ft=zsh:tw=80:sw=4:sts=4:noet
