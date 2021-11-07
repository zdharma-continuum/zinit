#!/usr/bin/env bash

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)" || exit 9

  docker run -it --rm -v "$(realpath ../..:)/src" zinit/zinit:alpine-latest
fi
