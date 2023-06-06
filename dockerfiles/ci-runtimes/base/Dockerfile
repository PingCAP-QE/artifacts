# Base image
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.20.5
FROM golang:${GOLANG_VERSION}

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"

ARG ARCH=amd64
ARG OS=linux

# install build essential
RUN apt-get update && \
    apt-get install -y build-essential unzip psmisc jq && \
    apt-get clean

##### install tools: bazelisk, yq, oras, codecov
# renovate: datasource=github-tags depName=bazelbuild/bazelisk
ARG BAZELISK_VERSION=v1.17.0
RUN curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-${OS}-${ARCH}" -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel
# renovate: datasource=github-tags depName=mikefarah/yq
ARG YQ_VERSION=v4.34.1
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq
# renovate: datasource=github-tags depName=oras-project/oras
ARG ORAS_VERSION=1.0.0
RUN curl -LO "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_${OS}_${ARCH}.tar.gz" && \
    mkdir -p oras-install/ && \
    tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/ && \
    mv oras-install/oras /usr/local/bin/ && \
    rm -rf oras_${ORAS_VERSION}_*.tar.gz oras-install/
# renovate: datasource=github-tags depName=codecov/uploader
ARG CODECOV_VERSION=v0.5.0
# only has x86-64 edition.
RUN curl -fsSL https://uploader.codecov.io/${CODECOV_VERSION}/linux/codecov -o /usr/local/bin/codecov && chmod +x /usr/local/bin/codecov
