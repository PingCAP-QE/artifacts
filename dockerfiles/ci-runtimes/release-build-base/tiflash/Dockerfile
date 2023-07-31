FROM centos:7.9.2009

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"

ARG ARCH=amd64
ARG OS=linux
# renovate: datasource=github-tags depName=pingcap/tiflash
ARG TIFLASH_VER=7.1.1

RUN curl -sSL https://github.com/pingcap/tiflash/archive/refs/tags/v${TIFLASH_VER}.tar.gz -o tiflash.tar.gz && \
    tar -zxf tiflash.tar.gz tiflash-${TIFLASH_VER}/release-centos7-llvm/dockerfiles/misc && \
    pushd tiflash-${TIFLASH_VER}/release-centos7-llvm/dockerfiles/misc && \
    chmod +x * && \
    if [ "$ARCH" = "arm64" ]; then \
    ./bake_llvm_base_aarch64.sh; \
    else \
    ./bake_llvm_base_amd64.sh; \
    fi && \
    popd && \
    rm -rf tiflash.tar.gz tiflash-${TIFLASH_VER}
