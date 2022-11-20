ARG VERSION=latest
FROM alpine:${VERSION}

ARG PUSERNAME=user01
ARG PUID=1000
ARG PGID=1000
ARG TERM=xterm-256color
ARG ZINIT_ZSH_VERSION

ENV PUSERNAME=${PUSERNAME} PUID=${PUID} PGID=${PGID} \
    SHELL=/bin/zsh TERM=${TERM} ZINIT_ZSH_VERSION=${ZINIT_ZSH_VERSION}

RUN apk --no-cache --virtual base add \
  asciidoc \
  asciidoctor \
  autoconf \
  bash \
  build-base \
  coreutils \
  curl \
  git \
  go \
  jq \
  libuser \
  ncurses-dev \
  neovim \
  nodejs-dev \
  npm \
  rsync \
  ruby-dev \
  sudo \
  zsh \
 && gem install asciidoctor-pdf text-hyphen

RUN sed -ir 's#^(root:.+):/bin/ash#\1:/bin/zsh#' /etc/passwd && \
    adduser -D -s /bin/zsh -u "${PUID}" -h "/home/${PUSERNAME}" \
        "${PUSERNAME}" && \
    printf "${PUSERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user && \
    mkdir -p /src /data /data-static && \
    chown -R "${PUID}:${PGID}" /data /data-static && \
    ln -sfv /src/docker/zshenv /home/${PUSERNAME}/.zshenv && \
    ln -sfv /src/docker/zshrc /home/${PUSERNAME}/.zshrc

WORKDIR /home/${PUSERNAME}
VOLUME ["/src", "/data"]

COPY --chown=${PUSERNAME} . /src

USER ${PUSERNAME}

RUN ZINIT_HOME_DIR=/data-static zsh -ils -c -- '@zinit-scheduler burst'

CMD ["/bin/zsh"]
