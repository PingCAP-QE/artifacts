# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - git clone https://github.com/pingcap/tidb-dashbord.git tidb-dashbord
#   - rm tidb-dashbord/.dockerignore # make step depended on git metadata.
#   - docker build -t tidb-dashbord -f Dockerfile ./tidb-dashbord

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528-ubi AS builder
LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description="binary builder for TiDB Dashboard"
LABEL org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf install -y make git gcc java-11-openjdk findutils

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.27.3
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH=/usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

# Install nodejs from a pinned upstream tarball. A NodeSource `setup_<major>.x`
# script is mutable and has to be piped into a shell; the dist tarball is
# version-addressed instead.
# renovate: datasource=docker depName=node
ARG NODE_VERSION=18.20.8
RUN OS_ARCH=$([ "$(arch)" = "x86_64" ] && echo x64 || echo arm64); \
    curl -fsSL -o /tmp/node.tar.gz "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${OS_ARCH}.tar.gz" && \
    tar -xzf /tmp/node.tar.gz -C /usr/local --strip-components=1 && \
    rm -f /tmp/node.tar.gz && \
    node --version && npm --version
RUN npm install -g pnpm@9.7.0

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
# The non-root stage exists to prove a build works without root, so it must
# not carry a passwordless sudo grant.
RUN useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group
USER builder

########### stage: building
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
