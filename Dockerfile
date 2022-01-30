#
#
#

FROM debian:buster

LABEL maintainer="Nick Gregory <docker@openenterprise.co.uk>"

ARG GOLANG_VERSION="1.17.6"
ARG GOLANG_SHA256="82c1a033cce9bc1b47073fd6285233133040f0378439f3c4659fe77cc534622a"

ARG CADDY_VERSION="2.4.6"
ARG CORAZA_VERSION="1.0.0"

# basic build infra
RUN apt-get -y update \
    && apt-get -y dist-upgrade \
    && apt-get -y install curl build-essential cmake sudo wget git-core autoconf automake pkg-config quilt \
    && apt-get -y install ruby ruby-dev rubygems \
    && gem install --no-document fpm

RUN cd /tmp \
    && echo "==> Downloading Golang..." \
    && curl -fSL  https://go.dev/dl/go${GOLANG_VERSION}.linux-arm64.tar.gz -o go${GOLANG_VERSION}.linux-arm64.tar.gz \
    && sha256sum go${GOLANG_VERSION}.linux-arm64.tar.gz \
    && echo "${GOLANG_SHA256}  go${GOLANG_VERSION}.linux-arm64.tar.gz" | sha256sum -c - \
    && tar -C /usr/local -xzf /tmp/go${GOLANG_VERSION}.linux-arm64.tar.gz

# package build
RUN go install -v github.com/caddyserver/xcaddy/cmd/xcaddy@latest \
    && /root/go/bin/xcaddy build v${CADDY_VERSION} \
    --output /tmp/caddy \
    --with github.com/jptosso/coraza-caddy@v${CORAZA_VERSION}

# package install
RUN cd /tmp \
    && install -D -m 0755 ./caddy /install/usr/bin/caddy \
    && fpm -s dir -t deb -C /install --name coraza-caddy --version 1 --iteration ${CORAZA_VERSION} \
       --description "Caddy HTTP server with the coraza plugin built in"

STOPSIGNAL SIGTERM
