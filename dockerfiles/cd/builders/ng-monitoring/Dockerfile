# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone https://github.com/pingcap/ng-monitoring.git ng-monitoring
#   - rm ng-monitoring/.dockerignore # make step depended on git metadata.
#   - docker build -t ng-monitoring -f Dockerfile ./ng-monitoring

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528 AS builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for NG-Monitoring"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf install -y make git gcc wget

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.23.8
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
RUN sudo ls && useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
USER builder

########### stage: building
FROM builder AS building
COPY . /ws
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make default -C /ws
RUN /ws/bin/ng-monitoring-server -V

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/ng-monitoring-base:v1.9.2
COPY --from=building /ws/bin/ng-monitoring-server /ng-monitoring-server

WORKDIR /
EXPOSE 12020
ENTRYPOINT ["/ng-monitoring-server"]

# test it
RUN /ng-monitoring-server -V
