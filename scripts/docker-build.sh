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

  echo -e "\e[34mBuilding image: ${image_name}\e[0m" >&2

  if docker build \
    --build-arg "PUSERNAME=$(id -u -n)" \
    --build-arg "PUID=$(id -u)" \
    --build-arg "PGID=$(id -g)" \
    --build-arg "TERM=${TERM:-xterm-256color}" \
    --build-arg "ZINIT_ZSH_VERSION=${zsh_version}" \
    --file "$dockerfile" \
    --tag "${image_name}:${tag}" \
    "$(realpath ..)" \
    "$@"
  then
    {
      echo -e "\e[34mTo use this image for zunit tests run: \e[0m"
      echo -e "\e[34mexport CONTAINER_IMAGE=\"${image_name}\" CONTAINER_TAG=\"${tag}\"\e[0m"
      echo -e "\e[34mzunit run --verbose\e[0m"
    } >&2
  else
    echo -e "\e[31m❌ Container failed to build.\e[0m" >&2
    return 1
  fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  build "$@"
fi
