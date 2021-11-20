#!/usr/bin/env zunit

teardown() {
  color magenta @teardown called

  [[ -n "$DATA_DIR" ]] && {
    color red bold "Deleting $DATA_DIR" >&2
    sudo rm -rf "$DATA_DIR"
  }
}

# vim: set ft=zsh et ts=2 sw=2 : #
