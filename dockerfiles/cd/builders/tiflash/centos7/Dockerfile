# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/tiflash.git tiflash
#   - docker build -t tiflash -f Dockerfile ./tiflash

########### stage: builder
FROM centos:7.9.2009 as builder
# CentOS 7 has reached EOL
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiFlash"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# renovate: datasource=github-tags depName=pingcap/tiflash
ARG TIFLASH_VER=v8.3.0
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

########### stage: building
FROM builder as building

ADD . /ws
RUN CARGO_NET_GIT_FETCH_WITH_CLI=true /ws/release-centos7-llvm/scripts/build-release.sh
RUN mkdir /ws/output && mv /ws/release-centos7-llvm/tiflash /ws/output/tiflash
RUN /ws/output/tiflash/tiflash version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tiflash-base:v1.9.2

ENV LD_LIBRARY_PATH /tiflash
COPY --from=building /ws/output/tiflash /tiflash

ENTRYPOINT ["/tiflash/tiflash", "server"]

# test it
RUN /tiflash/tiflash version
