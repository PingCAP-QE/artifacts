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
    yum groupinstall --nogpgcheck -y "Development Tools" && \
    yum install --nogpgcheck -y wget

# install golang toolchain
ARG GOLANG_VERSION=1.23.12
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
RUN GOPROXY=${GOPROXY} make default -C /ws
RUN /ws/bin/ng-monitoring-server -V

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/ng-monitoring-base:v1.10.0

COPY --from=building /ws/bin/ng-monitoring-server /ng-monitoring-server

WORKDIR /
EXPOSE 12020
ENTRYPOINT ["/ng-monitoring-server"]

# test it
RUN /ng-monitoring-server -V
