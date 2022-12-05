# syntax=docker/dockerfile-upstream:master

FROM ubuntu:latest

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name="zdharm-continuum/zinit"
LABEL org.label-schema.description="Containerized dotfiles environment"
LABEL org.label-schema.vcs-url="https://github.com/zdharm-continuum/zinit"
LABEL org.label-schema.docker.cmd="docker run --interactive --mount source=dotfiles-volume,destination=/home/ --tty vladdoster/dotfiles"

ARG USER

ENV USER ${USER:-zinit}
ENV HOME /home/${USER}
ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm-256color

RUN apt-get update \
 && apt-get --yes install --no-install-recommends \
   apt-utils autoconf automake \
   ca-certificates cmake curl \
   debianutils \
   file \
   g++ gcc git \
   less \
   make man-db \
   ncurses-base ncurses-bin ncurses-dev ncurses-term \
   pkg-config \
   subversion sudo \
   tar tree \
   unzip \
   xz-utils \
   zsh

RUN useradd \
  --create-home \
  --gid root --groups sudo \
  --home-dir ${HOME} \
  --shell "$(which zsh)" \
  --uid 1001 \
  ${USER} \
 && passwd --delete ${USER}

USER ${USER}
WORKDIR ${HOME}

COPY --chown=${USER} ./docker/zshrc ${HOME}/.zshrc
COPY --chown=${USER} . ${HOME}/zinit.git

ENTRYPOINT ["zsh"]
CMD ["-l"]
