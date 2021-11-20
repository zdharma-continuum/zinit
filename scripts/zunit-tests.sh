#!/usr/bin/env bash

run_tests() {
  cd "$(cd "$(dirname "$0")" >/dev/null 2>&1; pwd -P)/.." || exit 9

  zunit run --verbose "$@"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]
then
  run_tests "$@"
fi
