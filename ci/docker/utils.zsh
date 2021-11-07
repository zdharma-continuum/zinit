#!/usr/bin/env zsh

zinit::setup() {
  source /src/zinit.zsh
}

zinit::setup-annexes() {
  zinit light-mode for \
    zdharma-continuum/z-a-as-monitor \
    zdharma-continuum/z-a-bin-gem-node \
    zdharma-continuum/z-a-default-ice \
    zdharma-continuum/z-a-patch-dl \
    zdharma-continuum/z-a-rust
}

zinit::setup-minimal() {
  zinit wait lucid light-mode for \
    atinit"zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions
}
