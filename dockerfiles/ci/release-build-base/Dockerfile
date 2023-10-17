# Base image
# renovate: datasource=docker depName=centos
FROM centos:7.9.2009

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"

ARG ARCH=amd64
ARG OS=linux

# install packages.
RUN yum update --nogpgcheck -y && \
    yum install --nogpgcheck -y epel-release centos-release-scl deltarpm && \
    yum update --nogpgcheck -y && \
    yum groupinstall --nogpgcheck -y "Development Tools" && \
    yum install --nogpgcheck -y \
    bind-license \
    bzip2 \
    chrpath \
    cmake \
    cyrus-sasl-lib \
    devtoolset-10 \
    fakeroot \
    gawk \
    glib2 \
    glibc-static \
    gzip \
    it \
    jq \
    krb5-libs \
    libstdc++-static \
    libtool libtool-ltdl-devel \
    lsof \
    ncurses-static \
    ninja-build \
    nss nss-sysinit nss-tools \
    openssl-libs \
    protobuf-compiler \
    psmisc \
    python3 python3-devel \
    systemd systemd-libs \
    unzip \
    wget \
    which \
    xpat \
    xz xz-libs \
    zlib zlib-devel \
    && \
    yum clean all

##### install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.21.3
RUN curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.${OS}-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

##### install rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain nightly
ENV PATH /root/.cargo/bin:$PATH

##### install nodejs toolchain
ARG NODE_VERSION=16
RUN curl -sL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    yum install -y nodejs && \
    yum clean all
RUN npm install -g yarn pnpm

##### install tools: bazelisk, yq, oras
# renovate: datasource=github-tags depName=bazelbuild/bazelisk
ARG BAZELISK_VERSION=v1.17.0
RUN curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-${OS}-${ARCH}" -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

# yq tool
# renovate: datasource=github-tags depName=mikefarah/yq
ARG YQ_VERSION=v4.34.1
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# oras tool
# renovate: datasource=github-tags depName=oras-project/oras
ARG ORAS_VERSION=v1.1.0
RUN curl -LO "https://github.com/oras-project/oras/releases/download/${ORAS_VERSION}/oras_${ORAS_VERSION#?}_${OS}_${ARCH}.tar.gz" && \
    mkdir -p oras-install/ && \
    tar -zxf oras_*_${OS}_${ARCH}.tar.gz -C oras-install/ && \
    install oras-install/oras /usr/local/bin/ && \
    rm -rf oras_*_${OS}_${ARCH}.tar.gz oras-install/

# go template tool
# renovate: datasource=docker depName=hairyhenderson/gomplate
COPY --from=hairyhenderson/gomplate:v3.11.5 /gomplate /usr/local/bin/gomplate

# Set cmake3 as default cmake
# renovate: datasource=github-tags depName=Kitware/CMake
ARG CMAKE_VERSION=3.22.1
RUN if [ "$ARCH" = "arm64" ]; then \
    filename="cmake-${CMAKE_VERSION}-${OS}-aarch64.sh"; \
    else \
    filename="cmake-${CMAKE_VERSION}-${OS}-x86_64.sh"; \
    fi; \
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${filename} && \
    sh ${filename} --prefix=/usr/local --skip-license --exclude-subdir && \
    rm -f ${filename}

# Link ninja for arm64 ARCH
RUN if [ "$ARCH" = "arm64" ]; then \
    ln -sf /usr/bin/ninja-build /usr/bin/ninja; \
    fi

ARG TIFLASH_TAG=v7.1.1
# LLVM
ARG LLVM_VERSION=13.0.0
ENV LIBRARY_PATH="/usr/local/lib/$(uname -m)-unknown-linux-gnu/:${LIBRARY_PATH:+LIBRARY_PATH:}"
ENV LD_LIBRARY_PATH="/usr/local/lib/$(uname -m)-unknown-linux-gnu/:${LD_LIBRARY_PATH:+LD_LIBRARY_PATH:}"
ENV CPLUS_INCLUDE_PATH="/usr/local/include/$(uname -m)-unknown-linux-gnu/c++/v1/:${CPLUS_INCLUDE_PATH:+CPLUS_INCLUDE_PATH:}"
RUN curl -sSL https://github.com/pingcap/tiflash/raw/${TIFLASH_TAG}/release-centos7-llvm/dockerfiles/misc/bootstrap_llvm.sh -o install_llvm.sh && \
    source ./install_llvm.sh && \
    bootstrap_llvm ${LLVM_VERSION}

# OpenSSL
ARG OPENSSL_TAG=1_1_1t
RUN curl -sSL https://github.com/pingcap/tiflash/raw/${TIFLASH_TAG}/release-centos7-llvm/dockerfiles/misc/install_openssl.sh -o install_openssl.sh && \
    source ./install_openssl.sh && install_openssl ${OPENSSL_TAG}
ENV OPENSSL_ROOT_DIR="/usr/local/opt/openssl"

ENV CC=clang
ENV CXX=clang++
ENV LD=ld.lld

# CCache
ARG CCACHE_VERSION=4.5.1
RUN curl -sSL https://github.com/pingcap/tiflash/raw/${TIFLASH_TAG}/release-centos7-llvm/dockerfiles/misc/install_ccache.sh -o install_ccache.sh && \
    source ./install_ccache.sh && \
    install_ccache ${CCACHE_VERSION}

