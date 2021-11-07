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
    --build-arg "VERSION=${version}" \
    --file "$dockerfile" \
    --tag "zinit/zinit:${tag}" .
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  build "$@"
fi
