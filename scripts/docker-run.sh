#!/usr/bin/env bash
# -*- mode: sh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim:ft=sh:sw=2:sts=2:et:
#
# Copyright (c) 2021-2022 zdharma-continuum and contributors
#

parent_process() {
  local ppid pcmd
  ppid="$(ps -o ppid= -p "$$" | awk '{ print $1 }')"
  if [[ -z $ppid ]]; then
    echo "Failed to determine parent process" >&2
    return 1
  fi
  if pcmd="$(ps -o cmd= -p "$ppid")"; then
    echo "$pcmd"
    return
  fi
  return 1
}

running_interactively() {
  if [[ -n $CI ]]; then
    return 1
  fi
  if ! [[ -t 1 ]]; then
    parent_process | grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox} -q zunit
  fi
}

create_init_config_file() {
  local tempfile
  if [[ -z $* ]]; then
    return 1
  fi
  tempfile="$(mktemp)"
  echo "$*" > "$tempfile"
  chmod 666 "$tempfile"
  echo "$tempfile"
}

run() {
  local image="${CONTAINER_IMAGE:-ghcr.io/zdharma-continuum/zinit}"
  local tag="${CONTAINER_TAG:-latest}"
  local init_config="$1"
  shift
  local -a args=(--rm)
  local cruntime=docker
  local sudo_cmd
  if [[ -z $CI ]] && command -v podman > /dev/null 2>&1; then
    cruntime=podman
    sudo_cmd=sudo
  fi
  if running_interactively; then
    args+=(--tty=true --interactive=true)
  fi
  if [[ -n $init_config ]]; then
    if [[ -r $init_config ]]; then
      args+=(--volume "${init_config}:/init.zsh")
    else
      echo "❌ Init config file is not readable" >&2
      return 1
    fi
  fi
  if [[ -n $CONTAINER_WORKDIR ]]; then
    args+=(--workdir "$CONTAINER_WORKDIR")
  fi
  if [[ -n $TERM ]]; then
    args+=(--env "TERM=${TERM}")
  fi
  if [[ -n ${CONTAINER_ENV[*]} ]]; then
    local e
    for e in "${CONTAINER_ENV[@]}"; do
      args+=(--env "${e}")
    done
  fi
  if [[ -n ${CONTAINER_VOLUMES[*]} ]]; then
    local vol
    for vol in "${CONTAINER_VOLUMES[@]}"; do
      if [[ ! " ${args[*]} " =~ " --volume ${vol} " ]]; then
        args+=(--volume "${vol}")
      fi
    done
  fi
  local -a cmd=("$@")
  if [[ -n $WRAP_CMD ]]; then
    local zsh_opts="ilsc"
    [[ -n $ZSH_DEBUG ]] && zsh_opts="x${zsh_opts}"
    cmd=(zsh "-${zsh_opts}" "${cmd[*]}")
  fi
  if [[ -n $DEBUG ]]; then
    {
      echo -e "🚀 \e[35mRunning command"
      echo -e "\$ ${cruntime} run ${args[*]} ${image}:${tag} ${cmd[*]@Q}\e[0m"
    } >&2
  fi
  ${sudo_cmd} "${cruntime}" run "${args[@]}" "${image}:${tag}" "${cmd[@]}"
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
  CONTAINER_ENV=()
  CONTAINER_IMAGE="${CONTAINER_IMAGE:-ghcr.io/zdharma-continuum/zinit}"
  CONTAINER_TAG="${CONTAINER_TAG:-latest}"
  CONTAINER_VOLUMES=()
  CONTAINER_WORKDIR="${CONTAINER_WORKDIR:-}"
  DEBUG="${DEBUG:-}"
  INIT_CONFIG_VAL="${INIT_CONFIG_VAL:-}"
  PRESET="${PRESET:-}"
  WRAP_CMD="${WRAP_CMD:-}"
  ZSH_DEBUG="${ZSH_DEBUG:-}"
  while [[ -n $* ]]; do
    case "$1" in
      --xsel | -b)
        INIT_CONFIG_VAL="$(xsel -b)"
        shift
        ;;
      -c | --config | --init-config | --init)
        INIT_CONFIG_VAL="$2"
        shift 2
        ;;
      -f | --config-file | --init-config-file | --file)
        if ! [[ -r $2 ]]; then
          echo "Unable to read from file: $2" >&2
          exit 2
        fi
        INIT_CONFIG_VAL="$(cat "$2")"
        shift 2
        ;;
      -d | --debug)
        DEBUG=1
        shift
        ;;
      -D | --dev | --devel)
        DEVEL=1
        shift
        ;;
      --docs)
        PRESET=docs
        shift
        ;;
      -i | --image)
        CONTAINER_IMAGE="$2"
        shift 2
        ;;
      -t | --tag)
        CONTAINER_TAG="$2"
        shift 2
        ;;
      -e | --env | --environment)
        CONTAINER_ENV+=("$2")
        shift 2
        ;;
      -v | --volume)
        CONTAINER_VOLUMES+=("$2")
        shift 2
        ;;
      -w | --wrap)
        WRAP_CMD=1
        shift
        ;;
      --tests | --zunit | -z)
        PRESET=zunit
        shift
        ;;
      --zsh-debug | -x | -Z)
        ZSH_DEBUG=1
        shift
        ;;
      *) break ;;
    esac
  done
  GIT_ROOT_DIR="$(git rev-parse --show-toplevel)"
  CMD=("$@")
  case "$PRESET" in
    zunit)
      CONTAINER_VOLUMES+=("${GIT_ROOT_DIR}:/src" "${TMPDIR:-/tmp}/zunit-zinit:/data")
      CONTAINER_ENV+=("QUIET=1" "NOTHING_FANCY=1")
      ;;
    docs)
      CONTAINER_VOLUMES+=("${GIT_ROOT_DIR}:/src")
      CONTAINER_ENV+=("QUIET=1" "NOTHING_FANCY=1" "LC_ALL=en_US.UTF-8")
      CONTAINER_WORKDIR=/src
      INIT_CONFIG_VAL='zinit nocompile make'\''PREFIX=$ZPFX install'\'' for zdharma-continuum/zshelldoc'
      CMD=(zsh -ilsc 'sudo chown -R "$(id -u):$(id -g)" /src && @zinit-scheduler burst && sudo apk add tree && make -C /src doc')
      ;;
  esac
  if INIT_CONFIG="$(create_init_config_file "$INIT_CONFIG_VAL")"; then
    trap 'rm -vf $INIT_CONFIG' EXIT INT
  fi
  if [[ -n $DEVEL ]]; then
    CONTAINER_VOLUMES+=("${GIT_ROOT_DIR}:/src")
  fi
  run "$INIT_CONFIG" "${CMD[@]}"
fi
