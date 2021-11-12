#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  ZSH_VERSION=5.4.2
  INIT_CONFIG=$(cat <<-'EOM'
    zinit light-mode for \
        zdharma-continuum/z-a-rust \
        zdharma-continuum/z-a-patch-dl \
        zdharma-continuum/z-a-as-monitor \
        zdharma-continuum/z-a-bin-gem-node

    zinit wait lucid from"gh-r" as"null" for \
        sbin"fzf" @junegunn/fzf \
        sbin"**/fd" @sharkdp/fd \
        sbin"**/bat" @sharkdp/bat \
        sbin"**/exa" @ogham/exa
EOM
)

  set -x
  ./issue-tester.sh --tag "zsh-$ZSH_VERSION" --config "$INIT_CONFIG"
fi
