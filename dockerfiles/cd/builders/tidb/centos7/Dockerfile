# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - git clone https://github.com/pingcap/tidb.git tidb
#   - rm tidb/.dockerignore # make step depended on git metadata.
#   - docker build -t tidb -f Dockerfile ./tidb

########### stage: Builder
FROM centos:7.9.2009 AS builder
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

########### stage: Buiding
FROM builder AS building
COPY . /tidb
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make server -C /tidb
RUN /tidb/bin/tidb-server -V

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tidb-base:v1.10.0

COPY --from=building /tidb/bin/tidb-server /tidb-server

WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]

# test it
RUN /tidb-server -V
