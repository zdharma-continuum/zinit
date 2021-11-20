#!/usr/bin/env bash

build() {
  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  local image_name="${1:-zinit}"
  local zsh_version="${2}"
  local dockerfile="../docker/Dockerfile"
  local tag="latest"

  if [[ -n "$zsh_version" ]]
  then
    tag="zsh${zsh_version}-${tag}"
  fi
  local image_name="zinit:${tag}"

  echo -e "\e[34mBuilding image: ${image_name}\e[0m" >&2

  docker build \
    --no-cache \
    --build-arg "PUSERNAME=$(id -u -n)" \
    --build-arg "PUID=$(id -u)" \
    --build-arg "PGID=$(id -g)" \
    --build-arg "ZINIT_ZSH_VERSION=${zsh_version}" \
    --file "$dockerfile" \
    --tag "$image_name" "$(realpath ..)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  build "$@"
fi
