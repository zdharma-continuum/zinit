ARG VERSION=latest
FROM alpine:${VERSION}

ARG PUSERNAME=user01
ARG PUID=1000
ARG PGID=1000
ARG ZINIT_ZSH_VERSION
ENV PUSERNAME=${PUSERNAME} PUID=${PUID} PGID=${PGID} \
    ZINIT_ZSH_VERSION=${ZINIT_ZSH_VERSION}

RUN apk --no-cache --virtual base add \
        zsh curl git libuser sudo && \
    apk --no-cache --virtual build-tools add \
        build-base autoconf ncurses-dev bash go

RUN sed -ir 's#^(root:.+):/bin/ash#\1:/bin/zsh#' /etc/passwd && \
    adduser -D -s /bin/zsh -u "${PUID}" -h "/home/${PUSERNAME}" \
        "${PUSERNAME}" && \
    printf "${PUSERNAME} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user && \
    mkdir -p /src /data && \
    chown -R "${PUID}:${PGID}" /data && \
    ln -sfv /src/docker/zshenv /home/${PUSERNAME}/.zshenv && \
    ln -sfv /src/docker/zshrc /home/${PUSERNAME}/.zshrc

WORKDIR /home/${PUSERNAME}
VOLUME ["/src", "/data"]

COPY --chown=${PUSERNAME} . /src

USER ${PUSERNAME}

# Fetch keys config and store it outside of ZINIT[HOME_DIR] since it might get
# overridden at runtime (the /data volume)
RUN zsh -ils -c -- '@zinit-scheduler burst' && \
    cp -vf /data/snippets/OMZL::key-bindings.zsh/OMZL::key-bindings.zsh \
        /home/${PUSERNAME}/OMZL::key-bindings.zsh

CMD ["/bin/zsh"]
