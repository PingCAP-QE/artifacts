# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone https://github.com/pingcap/tidb.git tidb 
#   - rm tidb/.dockerignore # make step depended on git metadata.
#   - docker build -t tidb -f Dockerfile ./tidb

########### stage: Builder
FROM centos:7.9.2009 as builder

# install packages.
RUN yum update --nogpgcheck -y && \
    yum install --nogpgcheck -y epel-release centos-release-scl deltarpm && \
    yum update --nogpgcheck -y && \
    yum groupinstall --nogpgcheck -y "Development Tools" && \
    yum clean all

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.21.10
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

########### stage: Buiding
FROM builder as building
COPY . /tidb
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make server -C /tidb
RUN /tidb/bin/tidb-server -V

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tidb-base:v1.8.0

COPY --from=building /tidb/bin/tidb-server /tidb-server

WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
