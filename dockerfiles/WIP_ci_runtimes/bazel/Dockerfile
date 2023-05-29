# Base image
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.20.4
FROM golang:${GOLANG_VERSION}

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"

# renovate: datasource=github-tags depName=bazelbuild/bazelisk
ARG BAZELISK_VERSION=v1.16.0
ARG ARCH=amd64

# install build essential
RUN apt-get update && \
    apt-get install -y build-essential unzip psmisc && \
    apt-get clean

# install bazel tool
RUN curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-${ARCH}" \
    -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel
