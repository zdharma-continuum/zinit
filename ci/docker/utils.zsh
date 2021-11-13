#!/usr/bin/env zsh

zinit::setup() {
  source /src/zinit.zsh
}

zinit::setup-keys() {
  zinit light-mode snippet for OMZL::key-bindings.zsh
}

zinit::setup-annexes() {
  zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-default-ice \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust
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

zinit::pack-zsh() {
  local version="$1"

  zinit pack"$version" for zsh
}
