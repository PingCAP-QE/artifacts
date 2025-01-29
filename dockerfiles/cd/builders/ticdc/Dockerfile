# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/ticdc.git ticdc
#   - docker build -t ticdc -f Dockerfile ./ticdc

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528 as builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiFlow"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf install -y make git findutils gcc

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.23.5
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

########### stage: building-cdc
FROM builder as building
COPY . /ws
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make cdc -C /ws
RUN /ws/bin/cdc version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tools-base:v1.9.2
COPY --from=building /ws/bin/cdc /cdc

EXPOSE 8300
CMD ["/cdc"]

# test it
RUN /cdc version
