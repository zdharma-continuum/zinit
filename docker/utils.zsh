#!/usr/bin/env zsh

zinit::setup() {
  source /src/zinit.zsh
}

zinit::reload() {
  local zf
  for zf in /src/*.zsh
  do
    source "$zf"
  done
}

zinit::setup-keys() {
  zinit snippet OMZL::key-bindings.zsh
}

zinit::setup-annexes() {
  zinit light-mode compile'*handler' for \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-default-ice \
    zdharma-continuum/zinit-annex-meta-plugins \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-readurl \
    zdharma-continuum/zinit-annex-rust \
    zdharma-continuum/zinit-annex-submods \
    zdharma-continuum/zinit-annex-unscope
}

zinit::setup-annexes-extra() {
  # Dependencies
  sudo apk add ruby-dev grep tree
  zinit::install-zshelldoc

  zinit light-mode compile'*handler' for \
    zdharma-continuum/zinit-annex-man \
    zdharma-continuum/zinit-annex-test
}

zinit::install-zshelldoc() {
  zinit light-mode \
    make"PREFIX=$ZPFX install" \
    for zdharma-continuum/zshelldoc
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

# Local Variables:
# mode: Shell-Script
# sh-indentation: 2
# indent-tabs-mode: nil
# sh-basic-offset: 2
# End:
# vim: ft=zsh sw=2 ts=2 et
