# syntax=docker/dockerfile-upstream:master

ARG TARGETPLATFORM=linux/amd64
FROM --platform=$TARGETPLATFORM asciidoctor/docker-asciidoctor:latest

ENV USER root
ENV ZINIT_HOME /${USER}/zinit.git

RUN apk add \
  asciidoc-doc \
  less \
  tree \
  zsh

WORKDIR /${USER}

COPY ./docker/zshrc .zshrc
COPY . ./zinit.git

RUN zsh --interactive --login -c -- '@zinit-scheduler burst'

ENTRYPOINT ["zsh"]
CMD ["-i", "-l"]
