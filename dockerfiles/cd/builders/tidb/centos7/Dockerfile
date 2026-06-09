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
# This prevents package cache from being stored in image layers.
# CentOS7 repo only ships git 1.8.x, so build a newer git from source.
ARG GIT_VERSION=2.45.2
ARG GIT_TAR_XZ_SHA256=51bfe87eb1c02fed1484051875365eeab229831d30d0cec5d89a14f9e40e9adb
RUN --mount=type=cache,target=/var/cache/yum \
    yum install --nogpgcheck -y \
      ca-certificates \
      curl \
      expat-devel \
      gcc \
      gcc-c++ \
      libcurl-devel \
      make \
      openssl-devel \
      tar \
      xz \
      zlib-devel && \
    curl -fsSL "https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.xz" -o /tmp/git.tar.xz && \
    echo "${GIT_TAR_XZ_SHA256}  /tmp/git.tar.xz" | sha256sum -c - && \
    tar -xf /tmp/git.tar.xz -C /tmp && \
    make -j"$(nproc)" -C /tmp/git-${GIT_VERSION} prefix=/usr/local NO_TCLTK=YesPlease NO_GETTEXT=YesPlease NO_PERL=YesPlease CFLAGS="-std=gnu99" all && \
    make -C /tmp/git-${GIT_VERSION} prefix=/usr/local NO_TCLTK=YesPlease NO_GETTEXT=YesPlease NO_PERL=YesPlease CFLAGS="-std=gnu99" install && \
    yum clean all && \
    rm -rf /tmp/git-${GIT_VERSION} /tmp/git.tar.xz && \
    git --version

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.26.1
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH=/usr/local/go/bin/:$PATH
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
FROM ghcr.io/pingcap-qe/bases/tidb-base:v1.11.2

COPY --from=building /tidb/bin/tidb-server /tidb-server

WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]

# test it
RUN /tidb-server -V
