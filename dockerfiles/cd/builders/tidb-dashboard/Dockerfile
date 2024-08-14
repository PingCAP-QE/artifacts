# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone https://github.com/pingcap/tidb.git tidb 
#   - rm tidb/.dockerignore # make step depended on git metadata.
#   - docker build -t tidb -f Dockerfile ./tidb

########### stage: Builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528 as builder

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.21.13
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

# install packages.
RUN dnf install -y make git

# Install nodejs.
RUN curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
RUN yum -y install nodejs && yum clean all
RUN npm install -g pnpm@7.30.5

########### stage: Buiding
FROM builder as building
COPY . /ws
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make package -C /ws
RUN /ws/bin/tidb-dashboard --version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/pd-base:v1.9.1

COPY --from=building /ws/bin/tidb-dashboard /tidb-dashboard

EXPOSE 12333
ENTRYPOINT ["/tidb-dashboard"]

# test it
RUN /tidb-dashboard --version
