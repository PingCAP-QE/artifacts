# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/tikv/tikv.git tikv
#   - docker build -t tikv -f Dockerfile ./tikv

########### stage: Builder
FROM centos:7.9.2009 as builder

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for tiflash"
LABEL org.opencontainers.image.source = "https://github.com/PingCAP-QE/artifacts"

# renovate: datasource=github-tags depName=pingcap/tiflash
ARG TIFLASH_VER=v7.6.0
RUN FILE=$([ "$(arch)" = "aarch64" ] && echo "bake_llvm_base_aarch64.sh" || echo "bake_llvm_base_amd64.sh"); \
    TAR_DIR="tiflash-$(echo $TIFLASH_VER | sed 's/v//')"; \
    curl -sSL https://github.com/pingcap/tiflash/archive/refs/tags/${TIFLASH_VER}.tar.gz -o tiflash.tar.gz && \
    tar -zxf tiflash.tar.gz "$TAR_DIR/release-centos7-llvm/dockerfiles/misc" && \
    pushd "$TAR_DIR/release-centos7-llvm/dockerfiles/misc" && \
    chmod +x * && ./${FILE} && \
    popd && \
    rm -rf tiflash.tar.gz "$TAR_DIR"

ENV PATH="/opt/cmake/bin:${PATH}:/usr/local/go/bin:/root/.cargo/bin"
ENV CC=clang
ENV CXX=clang++
ENV LD=ld.lld

########### stage: Buiding
FROM builder as building

ADD . /tiflash
RUN /tiflash/release-centos7-llvm/scripts/build-release.sh
RUN mkdir output && mv release-centos7-llvm/tiflash output/tiflash
RUN output/tiflash/tiflash version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tiflash-base:v1.8.0

ENV LD_LIBRARY_PATH /tiflash
COPY --from=building /tiflash/output/tiflash /tiflash

ENTRYPOINT ["/tiflash/tiflash", "server"]
