# Deprecated: please use the builder images in dockerfiles/cd/builders folder.

# Base image
FROM centos:7.9.2009
# CentOS 7 has reached EOL
RUN sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo \
    && sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo \
    && sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "CD Base image for building"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN yum update --nogpgcheck -y && \
    yum install --nogpgcheck -y epel-release centos-release-scl deltarpm && \
    sed -i s/mirror.centos.org/vault.centos.org/g /etc/yum.repos.d/*.repo && \
    sed -i s/^#.*baseurl=http/baseurl=http/g /etc/yum.repos.d/*.repo && \
    sed -i s/^mirrorlist=http/#mirrorlist=http/g /etc/yum.repos.d/*.repo && \
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
ARG GOLANG_VERSION=1.23.11
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
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
ARG BAZELISK_VERSION=v1.26.0
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-${OS}-${ARCH}" -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

# yq tool
# renovate: datasource=github-tags depName=mikefarah/yq
ARG YQ_VERSION=v4.45.4
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# oras tool
# renovate: datasource=github-tags depName=oras-project/oras
ARG ORAS_VERSION=v1.2.3
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -LO "https://github.com/oras-project/oras/releases/download/${ORAS_VERSION}/oras_${ORAS_VERSION#?}_${OS}_${ARCH}.tar.gz" && \
    mkdir -p oras-install/ && \
    tar -zxf oras_*_${OS}_${ARCH}.tar.gz -C oras-install/ && \
    install oras-install/oras /usr/local/bin/ && \
    rm -rf oras_*_${OS}_${ARCH}.tar.gz oras-install/

# go template tool
# renovate: datasource=docker depName=hairyhenderson/gomplate
COPY --from=hairyhenderson/gomplate:v4.3.2 /gomplate /usr/local/bin/gomplate

# Set cmake3 as default cmake
# renovate: datasource=github-tags depName=Kitware/CMake
ARG CMAKE_VERSION=3.23.5
RUN filename="cmake-${CMAKE_VERSION}-linux-$(arch).sh"; \
    wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${filename} && \
    sh ${filename} --prefix=/usr/local --skip-license --exclude-subdir && \
    rm -f ${filename}

# Link ninja for arm64 arch
RUN if [ "$(arch)" = "aarch64" ]; then \
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

# renovate: datasource=github-tags depName=git/git
ARG GIT_VERSION=2.50.1
RUN wget https://github.com/git/git/archive/refs/tags/v$GIT_VERSION.zip -O git.zip && \
    unzip git.zip && \
    cd git-$GIT_VERSION && \
    make configure && \
    ./configure --with-openssl /usr/local/opt/openssl --prefix /usr/local && \
    make all && \
    make install && \
    cd .. && \
    rm -rf git-$GIT_VERSION git.zip
