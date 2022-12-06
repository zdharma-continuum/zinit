# syntax=docker/dockerfile-upstream:master

FROM asciidoctor/docker-asciidoctor:latest

ENV USER root
ENV ZINIT_SRC /${USER}/zinit.git

RUN apk add \
  asciidoc-doc \
  less \
  tree \
  zsh

USER ${USER}
WORKDIR /${USER}

COPY ./docker/zshrc .zshrc
COPY . zinit.git

RUN zsh --interactive --login -c -- '@zinit-scheduler burst'

ENTRYPOINT ["zsh"]
CMD ["-i", "-l"]
