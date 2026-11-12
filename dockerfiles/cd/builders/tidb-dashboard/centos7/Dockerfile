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
# CentOS 7 has reached EOL. The official vault still serves x86_64, but its
# aarch64 (altarch) tree is incomplete: yum gets 403 for
# altarch/7/os/aarch64/repodata/*-filelists.sqlite.bz2, so pin aarch64 to the
# archived 7.9.2009 tree on a public mirror.
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo \
    && ([ "$(arch)" = "x86_64" ] \
        || sed -i 's#baseurl=http://vault\.centos\.org/altarch/\$releasever/#baseurl=https://archive.kernel.org/centos-vault/altarch/7.9.2009/#' /etc/yum.repos.d/*.repo)

# install packages with BuildKit cache mount
# This prevents package cache from being stored in image layers
RUN --mount=type=cache,target=/var/cache/yum \
    yum -y update && \
    yum -y groupinstall "Development Tools" && \
    yum -y install java-11-openjdk

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.27.4
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH=/usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"



# Install nodejs from a pinned upstream tarball. A NodeSource `setup_<major>.x`
# script is mutable and has to be piped into a shell; the dist tarball is
# version-addressed instead.
# renovate: datasource=docker depName=node
ARG NODE_VERSION=16.20.2
RUN OS_ARCH=$([ "$(arch)" = "x86_64" ] && echo x64 || echo arm64); \
    curl -fsSL -o /tmp/node.tar.gz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${OS_ARCH}.tar.gz" && \
    tar -xzf /tmp/node.tar.gz -C /usr/local --strip-components=1 && \
    rm -f /tmp/node.tar.gz && \
    node --version && npm --version
RUN npm install -g pnpm@7.30.5

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
# The non-root stage exists to prove a build works without root, so it must
# not carry a passwordless sudo grant.
RUN useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group
USER builder

########### stage: Buiding
FROM builder AS building
COPY . /ws
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make package -C /ws
RUN /ws/bin/tidb-dashboard --version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/pd-base:v1.12.6

COPY --from=building /ws/bin/tidb-dashboard /tidb-dashboard

EXPOSE 12333
ENTRYPOINT ["/tidb-dashboard"]

# test it
RUN /tidb-dashboard --version
