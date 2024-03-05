# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/tiflow.git tiflow
#   - docker build -t dm -f Dockerfile ./tiflow

########### stage: Builder - cdc
FROM centos:7.9.2009 as builder-cdc

# install packages.
RUN yum update --nogpgcheck -y && \
    yum install --nogpgcheck -y epel-release centos-release-scl deltarpm && \
    yum update --nogpgcheck -y && \
    yum groupinstall --nogpgcheck -y "Development Tools" && \
    yum clean all

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.21.8
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

########### stage: Builder - dm
FROM builder-cdc as builder-dm

# install nodejs toolchain
# renovate: datasource=docker depName=node
ARG NODE_VERSION=16.20.2
# renovate: datasource=github-releases depName=nvm-sh/nvm
ARG NVM_VERSION=v0.39.7
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
FROM builder-dm as builder

########### stage: Buiding cdc
FROM builder-cdc as building-cdc

COPY . /tiflow
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make cdc -C /tiflow
RUN /tiflow/bin/cdc version

########### stage: Buiding dm
FROM builder-dm as building-dm

COPY . /tiflow
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make dm-master-with-webui dm-worker dmctl dm-syncer -C /tiflow
RUN /tiflow/bin/dm-master -V
RUN /tiflow/bin/dm-worker -V
RUN /tiflow/bin/dm-syncer -V
RUN /tiflow/bin/dmctl -V

########### stage: Final image - cdc
FROM ghcr.io/pingcap-qe/bases/tools-base:v1.8.0 as final-cdc

COPY --from=building-cdc /tiflow/bin/cdc /cdc
EXPOSE 8300
CMD ["/cdc"]

########### stage: Final image - dm
FROM ghcr.io/pingcap-qe/bases/tools-base:v1.8.0 as final-dm

COPY --from=building-dm /tiflow/bin/dm-master /dm-master
COPY --from=building-dm /tiflow/bin/dm-worker /dm-worker
COPY --from=building-dm /tiflow/bin/dm-syncer /dm-syncer
COPY --from=building-dm /tiflow/bin/dmctl     /dmctl

EXPOSE 8291 8261 8262
