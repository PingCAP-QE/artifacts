# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/tikv/pd.git pd
#   - docker build -t pd -f Dockerfile ./pd

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528 AS builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for PD"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf install -y make git gcc which unzip findutils

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.23.2
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
RUN GOPROXY=${GOPROXY} make build tools -C /ws
RUN /ws/bin/pd-server -V
RUN /ws/bin/pd-ctl -V
RUN /ws/bin/pd-recover -V

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/pd-base:v1.9.2
COPY --from=building /ws/bin/pd-server  /pd-server
COPY --from=building /ws/bin/pd-ctl     /pd-ctl
COPY --from=building /ws/bin/pd-recover /pd-recover

EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]

# test it
RUN /pd-server -V
