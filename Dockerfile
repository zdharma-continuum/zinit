# syntax=docker/dockerfile-upstream:master

ARG TARGETPLATFORM=linux/amd64
FROM --platform=$TARGETPLATFORM asciidoctor/docker-asciidoctor:latest

ENV USER root
ENV ZINIT_HOME /${USER}/zinit.git

RUN apk add \
  asciidoc-doc \
  make \
  less \
  tree \
  zsh

WORKDIR /${USER}

COPY . ./zinit.git
COPY ./docker/zshrc .zshrc

RUN zsh --interactive --login -c -- '@zi::scheduler burst'

CMD ["zsh","--interactive","--login"]

# vim: set fenc=utf8 ffs=unix ft=dockerfile list noet sw=4 ts=4 tw=72:
