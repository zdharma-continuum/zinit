#!/usr/bin/env zunit

setup() {
  export DATA_DIR="${TMPDIR:-/tmp}/zunit-zinit"
  export PLUGINS_DIR="${DATA_DIR}/plugins"
  export SNIPPETS_DIR="${DATA_DIR}/snippets"
  export ZPFX="${DATA_DIR}/polaris"

  {
    color magenta @setup started
    color magenta "DATA_DIR=${DATA_DIR}"
    color magenta "PLUGINS_DIR=${PLUGINS_DIR}"
    color magenta "SNIPPETS_DIR=${SNIPPETS_DIR}"
    color magenta "ZPFX=${ZPFX}"
  } >&2

  # Recreate DATA_DIR
  color red bold "Deleting $DATA_DIR" >&2
  sudo rm -rf "${DATA_DIR}"
  mkdir -p "${DATA_DIR}"
}

# vim: set ft=zsh et ts=2 sw=2 :
