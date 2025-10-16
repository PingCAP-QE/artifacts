# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# compose from tikv, tidb, pd, and other components.

########### stage: builder
FROM ghcr.io/pingcap-qe/cd/builders/tikv:v2024.10.8-63-gb22476a-centos7 AS builder
LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description="binary builder for TiDBx (experimental)"
LABEL org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts"

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.25.3
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
RUN --mount=type=cache,target=/var/cache/yum \
    yum install --nogpgcheck -y sudo && \
    useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
USER builder
