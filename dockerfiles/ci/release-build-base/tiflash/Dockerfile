FROM centos:7.9.2009

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"

ARG ARCH=amd64
ARG OS=linux
# renovate: datasource=github-tags depName=pingcap/tiflash
ARG TIFLASH_VER=v7.4.0

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

ENV PATH="/opt/cmake/bin:${PATH}:/usr/local/go/bin:/root/.cargo/bin"
ENV CC=clang
ENV CXX=clang++
ENV LD=ld.lld

# LIBRARY_PATH="/usr/local/lib/aarch64-unknown-linux-gnu/:${LIBRARY_PATH}" \
# LD_LIBRARY_PATH="/usr/local/lib/aarch64-unknown-linux-gnu/:${LD_LIBRARY_PATH}" \
# CPLUS_INCLUDE_PATH="/usr/local/include/aarch64-unknown-linux-gnu/c++/v1/:${CPLUS_INCLUDE_PATH}" \
# OPENSSL_ROOT_DIR="/usr/local/opt/openssl" \
