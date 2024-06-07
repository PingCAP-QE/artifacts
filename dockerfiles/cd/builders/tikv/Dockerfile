# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/tikv/tikv.git tikv
#   - docker build -t tikv -f Dockerfile ./tikv

########### stage: Builder
FROM centos:7.9.2009 as builder
# install packages.
ARG DEVTOOLSET_VER=8
RUN yum update --nogpgcheck -y && \
    yum install --nogpgcheck -y epel-release centos-release-scl deltarpm && \
    yum update --nogpgcheck -y && \
    yum install -y git devtoolset-${DEVTOOLSET_VER} perl cmake3 && \
    yum clean all && \
    ln -s /usr/bin/cmake3 /usr/bin/cmake
ENV DEVTOOLSET_VER ${DEVTOOLSET_VER}

# install protoc.
# renovate: datasource=github-release depName=protocolbuffers/protobuf
ARG PROTOBUF_VER=v3.15.8
RUN FILE=$([ "$(arch)" = "aarch64" ] && echo "protoc-${PROTOBUF_VER#?}-linux-aarch_64.zip" || echo "protoc-${PROTOBUF_VER#?}-linux-$(arch).zip"); \
    curl -LO "https://github.com/protocolbuffers/protobuf/releases/download/${PROTOBUF_VER}/${FILE}" && unzip "$FILE" -d /usr/local/ && rm -f "$FILE"

# install rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain none
ENV PATH /root/.cargo/bin/:$PATH
LABEL devtoolset-ver="${DEVTOOLSET_VER}"

########### stage: Buiding
FROM builder as building
COPY . /tikv
RUN --mount=type=cache,target=/tikv/target \
    source /opt/rh/devtoolset-${DEVTOOLSET_VER}/enable && \
    ROCKSDB_SYS_STATIC=1 \
    make dist_release -C /tikv
RUN /tikv/bin/tikv-server --version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tikv-base:v1.8.0

ENV MALLOC_CONF="prof:true,prof_active:false"
COPY --from=building /tikv/bin/tikv-server  /tikv-server
COPY --from=building /tikv/bin/tikv-ctl     /tikv-ctl

EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
