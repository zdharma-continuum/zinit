#!/usr/bin/env bash

create_config() {
  local tempfile

  if [[ -z "$*" ]]
  then
    return
  fi

  tempfile=$(mktemp)
  echo "$*" > "$tempfile"
  echo "$tempfile"
}

run() {
  local image="${1:-ghcr.io/zdharma-continuum/zinit}"
  local tag="${2:-latest}"
  local init_config="${3}"

  local -a args=()

  if [[ -n "$init_config" ]] && [[ -r "$init_config" ]]
  then
    args+=(-v "${init_config}:/init.zsh")
  fi

  docker run -it --rm "${args[@]}" "$image:$tag"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  CONTAINER_IMAGE=ghcr.io/zdharma-continuum/zinit
  CONTAINER_TAG=latest
  INIT_CONFIG_VAL=""

  while [[ -n "$*" ]]
  do
    case "$1" in
      xsel|--xsel|-b)
        INIT_CONFIG_VAL="$(xsel -b)"
        shift
        ;;
      -c|--config|--init-config|--init)
        INIT_CONFIG_VAL="$2"
        shift 2
        ;;
      -i|--image)
        CONTAINER_IMAGE="$2"
        shift 2
        ;;
      -t|--tag)
        CONTAINER_TAG="$2"
        shift 2
        ;;
      *)
        break
        ;;
    esac
  done

  INIT_CONFIG="$(create_config "$INIT_CONFIG_VAL")"
  trap 'rm -vf $INIT_CONFIG' EXIT INT
  run "$CONTAINER_IMAGE" "$CONTAINER_TAG" "$INIT_CONFIG"
fi
