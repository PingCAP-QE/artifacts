# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/tiflash.git tiflash
#   - docker build -t tiflash -f Dockerfile ./tiflash

########### stage: extract-conda-openssl
FROM quay.io/rockylinux/rockylinux:8.10.20240528-ubi as extract-conda-openssl
RUN dnf install -y unzip wget zstd
# install openssl with conda pre-build package.
# index: in https://prefix.dev/channels/conda-forge/packages/openssl
RUN zip_url=$([ "$(arch)" = "x86_64" ] && \
        echo "https://conda.anaconda.org/conda-forge/linux-64/openssl-1.1.1w-hd590300_0.conda" || \
        echo "https://conda.anaconda.org/conda-forge/linux-aarch64/openssl-1.1.1w-h31becfc_0.conda"\
    ); \
    pkg_file=$(basename "$zip_url" .conda); \
    mkdir /output; \
    wget ${zip_url} -O /output/openssl.conda && unzip -d /output /output/openssl.conda && \
    mkdir -p /usr/local/opt/openssl && \
    tar -C /usr/local/opt/openssl -I zstd -xvf /output/pkg-${pkg_file}.tar.zst

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528-ubi as builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiFlash"
LABEL org.opencontainers.image.source = "https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf --enablerepo=powertools install -y git llvm-toolset cmake ninja-build python3.12 libcurl-devel
ENV CC clang
ENV CXX clang++
ENV LD ld.lld

# install openssl
COPY --from=extract-conda-openssl /usr/local/opt/openssl /usr/local/opt/openssl

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
