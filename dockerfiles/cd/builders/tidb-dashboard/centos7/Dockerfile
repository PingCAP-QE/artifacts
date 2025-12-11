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
    yum -y update && \
    yum -y groupinstall "Development Tools" && \
    yum -y install java-11-openjdk

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.23.12
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

# Install nodejs.
RUN curl -fsSL https://rpm.nodesource.com/setup_16.x | bash -
RUN yum -y install nodejs && yum clean all
RUN npm install -g pnpm@7.30.5

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
RUN GOPROXY=${GOPROXY} make package -C /ws
RUN /ws/bin/tidb-dashboard --version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/pd-base:v1.11.0

COPY --from=building /ws/bin/tidb-dashboard /tidb-dashboard

EXPOSE 12333
ENTRYPOINT ["/tidb-dashboard"]

# test it
RUN /tidb-dashboard --version
