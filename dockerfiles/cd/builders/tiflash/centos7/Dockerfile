# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/tiflash.git tiflash
#   - docker build -t tiflash -f Dockerfile ./tiflash

########### stage: builder
FROM centos:7.9.2009 AS builder
LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description="binary builder for TiFlash"
LABEL org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts"

# CentOS 7 has reached EOL
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo \
    && ([ "$(arch)" = "x86_64" ] || sed -i 's#vault.centos.org/centos/#vault.centos.org/altarch/#g' /etc/yum.repos.d/*.repo)

ARG TIFLASH_REPO=https://github.com/wuhuizuo/tiflash
ARG TIFLASH_VER=release-8.3
ARG TIFLASH_VER_TYPE=heads
RUN FILE=$([ "$(arch)" = "aarch64" ] && echo "bake_llvm_base_aarch64.sh" || echo "bake_llvm_base_amd64.sh"); \
    TAR_DIR="tiflash-$(echo $TIFLASH_VER | sed 's/v//')"; \
    curl -sSL ${TIFLASH_REPO}/archive/refs/${TIFLASH_VER_TYPE}/${TIFLASH_VER}.tar.gz -o tiflash.tar.gz && \
    tar -zxf tiflash.tar.gz "$TAR_DIR/release-centos7-llvm/dockerfiles/misc" && \
    pushd "$TAR_DIR/release-centos7-llvm/dockerfiles/misc" && \
    chmod +x * && ./${FILE} && \
    popd && \
    rm -rf tiflash.tar.gz "$TAR_DIR"

ENV PATH="/opt/cmake/bin:${PATH}:/usr/local/go/bin:/root/.cargo/bin"
ENV CC=clang
ENV CXX=clang++
ENV LD=ld.lld

# install protoc.
# renovate: datasource=github-release depName=protocolbuffers/protobuf
ARG PROTOBUF_VER=v3.15.8
RUN FILE=$([ "$(arch)" = "aarch64" ] && echo "protoc-${PROTOBUF_VER#?}-linux-aarch_64.zip" || echo "protoc-${PROTOBUF_VER#?}-linux-$(arch).zip"); \
    curl -LO "https://github.com/protocolbuffers/protobuf/releases/download/${PROTOBUF_VER}/${FILE}" && unzip "$FILE" -d /usr/local/ && rm -f "$FILE"

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
RUN --mount=type=cache,target=/var/cache/yum \
    yum install --nogpgcheck -y sudo && \
    useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
USER builder

########### stage: building
FROM builder AS building

ADD . /ws
RUN CARGO_NET_GIT_FETCH_WITH_CLI=true /ws/release-linux-llvm/scripts/build-release.sh
RUN mkdir /ws/output && mv /ws/release-linux-llvm/tiflash /ws/output/tiflash
RUN /ws/output/tiflash/tiflash version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tiflash-base:v1.10.1

ENV LD_LIBRARY_PATH /tiflash
COPY --from=building /ws/output/tiflash /tiflash

ENTRYPOINT ["/tiflash/tiflash", "server"]

# test it
RUN /tiflash/tiflash version
