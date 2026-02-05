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
ARG GOLANG_VERSION=1.25.7
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

# Install nodejs.
RUN curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
RUN yum -y install nodejs && yum clean all
RUN npm install -g pnpm@9.7.0

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y sudo && \
    useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
USER builder

########### stage: building
FROM builder AS building
COPY . /ws
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make package -C /ws
RUN /ws/bin/tidb-dashboard --version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/pd-base:v1.11.1

COPY --from=building /ws/bin/tidb-dashboard /tidb-dashboard

EXPOSE 12333
ENTRYPOINT ["/tidb-dashboard"]

# test it
RUN /tidb-dashboard --version
