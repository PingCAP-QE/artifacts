# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/tiflash.git tiflash
#   - docker build -t tiflash -f Dockerfile ./tiflash

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528 as builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiFlash"
LABEL org.opencontainers.image.source = "https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf --enablerepo=powertools install -y git llvm-toolset cmake ninja-build openssl

# install rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain none
ENV PATH /root/.cargo/bin/:$PATH

ENV CC clang
ENV CXX clang++
ENV LD ld.lld
# ENV LIBRARY_PATH="/usr/local/lib/$(uname -m)-unknown-linux-gnu/:${LIBRARY_PATH:+LIBRARY_PATH:}"
# ENV LD_LIBRARY_PATH="/usr/local/lib/$(uname -m)-unknown-linux-gnu/:${LD_LIBRARY_PATH:+LD_LIBRARY_PATH:}"
# ENV CPLUS_INCLUDE_PATH="/usr/local/include/$(uname -m)-unknown-linux-gnu/c++/v1/:${CPLUS_INCLUDE_PATH:+CPLUS_INCLUDE_PATH:}"

########### stage: building
FROM builder as building

ADD . /ws
RUN /ws/release-centos7-llvm/scripts/build-release.sh
RUN mkdir output && mv /ws/release-centos7-llvm/tiflash output/tiflash
RUN output/tiflash/tiflash version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tiflash-base:v1.9.1

ENV LD_LIBRARY_PATH /tiflash
COPY --from=building /ws/output/tiflash /tiflash

ENTRYPOINT ["/tiflash/tiflash", "server"]

# test it
RUN /tiflash/tiflash version
