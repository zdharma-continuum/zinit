#!/usr/bin/env bash

build() {
  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  local target="${1:-alpine}"
  local version="${2:-latest}"
  local tag

  case "$target" in
    alpine)
      dockerfile=Dockerfile.alpine
      tag="alpine-${version}"
      ;;
    ubuntu)
      dockerfile=Dockerfile.ubuntu
      tag="ubuntu-${version}"
      ;;
    *)
      echo "Unknown build target: $target" >&2
      return 2
      ;;
  esac

  docker build \
    --no-cache \
    --build-arg "VERSION=${version}" \
    --build-arg "ZINIT_ZSH_VERSION=5.4.2-tcsetpgrp" \
    --file "$dockerfile" \
    --tag "zinit/zinit:${tag}" "$(realpath ../../)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  build "$@"
fi
