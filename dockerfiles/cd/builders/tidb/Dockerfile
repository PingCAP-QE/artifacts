# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone https://github.com/pingcap/tidb.git tidb
#   - rm tidb/.dockerignore # make step depended on git metadata.
#   - docker build -t tidb -f Dockerfile ./tidb

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528 as builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiDB"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf install -y make git gcc findutils

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.23.8
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

########### stage: non-root-builder, used for development with non-root user.
FROM builder as non-root-builder
RUN useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd
USER builder

########### stage: building
FROM builder as building
COPY . /ws
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make server -C /ws
RUN /ws/bin/tidb-server -V

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tidb-base:v1.9.2
COPY --from=building /ws/bin/tidb-server /tidb-server

WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]

# test it
RUN /tidb-server -V
