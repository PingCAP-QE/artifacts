# base image dockerfile: cd/builders/tiflash/Dockerfile
ARG BASE_IMG=ghcr.io/pingcap-qe/cd/builders/tiflash:v2024.10.8-14-g52a7228
FROM $BASE_IMG

# create user jenkins and add it to sudoers.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y sudo
RUN groupadd -g 1000 jenkins && \
    useradd -u 1000 -g 1000 -m -s /bin/bash jenkins && \
    echo "jenkins:password" | chpasswd && \
    echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y hostname wget procps-ng python27
RUN ln -s /usr/bin/python2 /usr/bin/python && \
    ln -s /usr/bin/pip2 /usr/bin/pip

# install ccache
ARG CCACHE_VERSION=4.10.2
RUN curl -LO  https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}.tar.gz && \
    tar -xvf ccache-${CCACHE_VERSION}.tar.gz && \
    mkdir -p ccache-${CCACHE_VERSION}/build && \
    cd ccache-${CCACHE_VERSION}/build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release \
    -DZSTD_FROM_INTERNET=ON \
    -DHIREDIS_FROM_INTERNET=ON \
    -DENABLE_TESTING=OFF \
    -DCMAKE_INSTALL_PREFIX="/usr/local" \
    -GNinja && \
    ninja && \
    ninja install && \
    cd ../.. && \
    rm -rf ccache-${CCACHE_VERSION} ccache-${CCACHE_VERSION}.tar.gz && \
    mkdir -p /usr/lib64/ccache && \
    ln -s $(which ccache) /usr/lib64/ccache/clang && \
    ln -s $(which ccache) /usr/lib64/ccache/clang++

# Switch to the non-root user jenkins and set the working directory
USER jenkins
WORKDIR /home/jenkins

ENV CARGO_HOME="/home/jenkins/.cargo"
# install rustup and set stable toolchain as default
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly-2023-12-28 && \
    source $HOME/.cargo/env && \
    rustup default nightly-2023-12-28

ENV PATH="${CARGO_HOME}/bin:${PATH}"
