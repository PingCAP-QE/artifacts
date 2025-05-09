# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/tiflash.git tiflash
#   - docker build -t tiflash -f Dockerfile ./tiflash

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528-ubi AS builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiFlash"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# FIXME: replace with official repo and tag.
# renovate: datasource=github-tags depName=pingcap/tiflash
ARG TIFLASH_REPO=pingcap/tiflash
ARG TIFLASH_REF=master
RUN TAR_DIR="tiflash-${TIFLASH_REF}"; \
    curl -sSL https://github.com/${TIFLASH_REPO}/archive/refs/heads/${TIFLASH_REF}.tar.gz -o tiflash.tar.gz && \
    tar -zxf tiflash.tar.gz "$TAR_DIR/release-linux-llvm/dockerfiles/misc" && \
    pushd "$TAR_DIR/release-linux-llvm/dockerfiles/misc" && \
    chmod +x * && \
    ./bake_base.sh && ./bake_llvm.sh && ./bake_rest.sh && \
    popd && \
    rm -rf tiflash.tar.gz "$TAR_DIR"

ENV TZ Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

ENV PATH="/opt/cmake/bin:/usr/local/bin/:${PATH}:/usr/local/go/bin:/root/.cargo/bin" \
    LIBRARY_PATH="/usr/local/lib/$(uname -m)-unknown-linux-gnu/:${LIBRARY_PATH}" \
    LD_LIBRARY_PATH="/usr/local/lib/$(uname -m)-unknown-linux-gnu/:${LD_LIBRARY_PATH}" \
    CPLUS_INCLUDE_PATH="/usr/local/include/$(uname -m)-unknown-linux-gnu/c++/v1/:${CPLUS_INCLUDE_PATH}" \
    OPENSSL_ROOT_DIR="/usr/local/opt/openssl" \
    CC=clang \
    CXX=clang++ \
    LD=ld.lld

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
RUN sudo ls && useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
USER builder

########### stage: building
FROM builder AS building

ADD . /ws
RUN CARGO_NET_GIT_FETCH_WITH_CLI=true /ws/release-linux-llvm/scripts/build-release.sh
RUN mkdir /ws/output && mv /ws/release-linux-llvm/tiflash /ws/output/tiflash
RUN /ws/output/tiflash/tiflash version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tiflash-base:v1.9.2

ENV LD_LIBRARY_PATH /tiflash
COPY --from=building /ws/output/tiflash /tiflash

ENTRYPOINT ["/tiflash/tiflash", "server"]

# test it
RUN /tiflash/tiflash version
