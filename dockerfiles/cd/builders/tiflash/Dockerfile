# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/tiflash.git tiflash
#   - docker build -t tiflash -f Dockerfile ./tiflash

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528-ubi as builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiFlash"
LABEL org.opencontainers.image.source = "https://github.com/PingCAP-QE/artifacts"

# install packages.
# openssl is not updated to 1.1.1w, just 1.1.1o
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf --enablerepo=powertools install -y git llvm-toolset cmake ninja-build openssl python3.12 libcurl-devel

ENV CC clang
ENV CXX clang++
ENV LD ld.lld

# building and install libc++
RUN --mount=type=cache,target=/tmp/llvm \
    git clone https://github.com/llvm/llvm-project.git  --branch llvmorg-17.0.6 --depth 1 /tmp/llvm/llvm-project && \
    cd /tmp/llvm/llvm-project && rm -rf build && mkdir build && \
    cmake -G Ninja -S runtimes -B build -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -DCMAKE_INSTALL_PREFIX=/usr -DLLVM_LIBDIR_SUFFIX=64 && \
    ninja -C build cxx cxxabi unwind && \
    ninja -C build install-cxx install-cxxabi install-unwind

# install rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain none
ENV PATH /root/.cargo/bin/:$PATH

########### stage: building
FROM builder as building

ADD . /ws
RUN CARGO_NET_GIT_FETCH_WITH_CLI=true /ws/release-centos7-llvm/scripts/build-release.sh
RUN mkdir output && mv /ws/release-centos7-llvm/tiflash output/tiflash
RUN output/tiflash/tiflash version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tiflash-base:v1.9.1

ENV LD_LIBRARY_PATH /tiflash
COPY --from=building /ws/output/tiflash /tiflash

ENTRYPOINT ["/tiflash/tiflash", "server"]

# test it
RUN /tiflash/tiflash version
