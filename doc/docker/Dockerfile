FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y \
    git \
    locales \
    make \
    tree \
    zsh \
    && rm -rf /var/lib/apt/lists/*

RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && \
    locale-gen

RUN git clone https://github.com/zdharma-continuum/zshelldoc.git /tmp/zsd.git && \
        cd /tmp/zsd.git && make install

VOLUME /zinit.git
WORKDIR /zinit.git
ENTRYPOINT ["/bin/bash"]
CMD [ "-c", "make doc"]
