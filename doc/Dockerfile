FROM ubuntu:latest

RUN apt-get update \
    && apt-get install -y ca-certificates curl git build-essential zsh tree

RUN git clone https://github.com/zdharma-continuum/zshelldoc.git /tmp/zsd.git \
    && cd /tmp/zsd.git \
    && make install \
    && zsd --help

RUN git clone https://github.com/rbenv/ruby-build.git /tmp/ruby-build \
    && cd /tmp/ruby-build \
    && PREFIX=/usr/local /tmp/ruby-build/install.sh \
    && apt-get install -y libssl-dev libreadline-dev zlib1g-dev \
    && ruby-build 2.6.0 /usr/local \
    && gem install asciidoctor-pdf

RUN apt-get install -y pandoc

RUN curl -fsSL https://deb.nodesource.com/setup_17.x | bash - \
    && apt-get install -y nodejs \
    && npm i -g doctoc

RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -yq asciidoc
