# syntax=docker/dockerfile-upstream:master

FROM asciidoctor/docker-asciidoctor:latest

ENV ZINIT_SRC ${HOME}/zinit.git

RUN apk add \
  asciidoc-doc \
  less \
  tree \
  zsh

COPY ./docker/zshrc ${HOME}/.zshrc
COPY . ${ZINIT_SRC}

WORKDIR ${ZINIT_SRC}

ENTRYPOINT ["zsh"]
CMD ["-i", "-l"]
