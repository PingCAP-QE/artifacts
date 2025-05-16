# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/tiflow.git tiflow
#   - docker build -t dm -f Dockerfile ./tiflow

########### stage: Builder - cdc
FROM centos:7.9.2009 AS builder-cdc
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
ARG GOLANG_VERSION=1.21.13
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

########### stage: Builder - dm
FROM builder-cdc AS builder-dm

# install nodejs toolchain
# renovate: datasource=docker depName=node
ARG NODE_VERSION=16.20.2
# renovate: datasource=github-releases depName=nvm-sh/nvm
ARG NVM_VERSION=v0.40.3
ARG NVM_DIR=/usr/local/nvm
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install ${NODE_VERSION} && \
    nvm use v${NODE_VERSION} && \
    nvm alias default v${NODE_VERSION}
ENV PATH="${NVM_DIR}/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN node --version && npm --version && npm install -g yarn

########### stage: Builder - total
FROM builder-dm AS builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiFlow"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
RUN --mount=type=cache,target=/var/cache/yum \
    yum install --nogpgcheck -y sudo && \
    useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
USER builder

########### stage: Buiding cdc
FROM builder-cdc AS building-cdc

COPY . /tiflow
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make cdc -C /tiflow
RUN /tiflow/bin/cdc version

########### stage: Buiding dm
FROM builder-dm AS building-dm

COPY . /tiflow
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make dm-master-with-webui dm-worker dmctl dm-syncer -C /tiflow
RUN /tiflow/bin/dm-master -V
RUN /tiflow/bin/dm-worker -V
RUN /tiflow/bin/dm-syncer -V
RUN /tiflow/bin/dmctl -V

########### stage: Final image - cdc
FROM ghcr.io/pingcap-qe/bases/tools-base:v1.9.2 AS final-cdc

COPY --from=building-cdc /tiflow/bin/cdc /cdc
EXPOSE 8300
CMD ["/cdc"]

# test it
RUN /cdc version


########### stage: Final image - dm
FROM ghcr.io/pingcap-qe/bases/tools-base:v1.9.2 AS final-dm

COPY --from=building-dm /tiflow/bin/dm-master /dm-master
COPY --from=building-dm /tiflow/bin/dm-worker /dm-worker
COPY --from=building-dm /tiflow/bin/dm-syncer /dm-syncer
COPY --from=building-dm /tiflow/bin/dmctl     /dmctl

EXPOSE 8291 8261 8262

# test it
RUN /dm-master -V
RUN /dm-worker -V
RUN /dm-syncer -V
RUN /dmctl -V
