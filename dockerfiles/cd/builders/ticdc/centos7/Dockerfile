# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/ticdc.git ticdc
#   - docker build -t ticdc -f Dockerfile ./ticdc

########### stage: Builder
FROM centos:7.9.2009 AS builder
LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description="binary builder for TiFlow"
LABEL org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts"

# CentOS 7 has reached EOL
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo

# install packages with BuildKit cache mount
# This prevents package cache from being stored in image layers
RUN --mount=type=cache,target=/var/cache/yum \
    yum update --nogpgcheck -y && \
    yum install --nogpgcheck -y epel-release deltarpm && \
    yum update --nogpgcheck -y && \
    yum groupinstall --nogpgcheck -y "Development Tools"

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.26.0
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

########### stage: Buiding
FROM builder AS building

COPY . /ws
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make cdc -C /ws
RUN /ws/bin/cdc version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tools-base:v1.11.1

COPY --from=building /ws/bin/cdc /cdc
EXPOSE 8300
CMD ["/cdc"]

# test it
RUN /cdc version
