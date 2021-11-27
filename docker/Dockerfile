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
        coreutils curl git libuser rsync sudo zsh && \
    apk --no-cache --virtual zsh-build-tools add \
        autoconf bash build-base ncurses-dev && \
    apk --no-cache --virtual dev-tools add \
        go jq nodejs-dev npm ruby-dev neovim

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

# Fetch keys config and store it outside of ZINIT[HOME_DIR] since it might get
# overridden at runtime (the /data volume)
RUN ZINIT_HOME_DIR=/data-static ZSH_NO_INIT=1 \
    zsh -ils -c -- '@zinit-scheduler burst'

CMD ["/bin/zsh"]
