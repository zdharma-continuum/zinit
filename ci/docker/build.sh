#!/usr/bin/env bash

build() {
  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  local target="${1:-alpine}"
  local version="${2:-latest}"
  local zsh_version="${3}"
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

  local image_name="zinit:${tag}"

  if [[ -n "$CI" ]]
  then
    image_name="ghcr.io/${GITHUB_REPOSITORY}:${tag}"
  fi

  docker build \
    --no-cache \
    --build-arg "VERSION=${version}" \
    --build-arg "ZINIT_ZSH_VERSION=${zsh_version}" \
    --file "$dockerfile" \
    --tag "$image_name" "$(realpath ../../)"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  build "$@"
fi
