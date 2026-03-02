ARG BASE_IMG=ghcr.io/pingcap-qe/cd/builders/tiflash:v2024.10.8-135-g43bfc3c-centos7
FROM $BASE_IMG

RUN yum install -y wget lsof openssh-server openssh-clients sudo mysql protobuf-compiler perl-core openssl-devel

ARG OS=linux

# MinIO
RUN ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    wget -q -O minio https://dl.min.io/server/minio/release/${OS}-${ARCH}/archive/minio.RELEASE.2025-02-07T23-21-09Z && \
    chmod +x minio && \
    wget -q -O mc https://dl.min.io/client/mc/release/${OS}-${ARCH}/archive/mc.RELEASE.2025-02-08T19-14-21Z && \
    chmod +x mc && \
    mv minio /usr/local/bin/minio && \
    mv mc /usr/local/bin/mc

# yq、oras tool
ARG YQ_VERSION=v4.52.2
ARG ORAS_VERSION=v1.3.0
RUN ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}" -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq && \
    curl -LO "https://github.com/oras-project/oras/releases/download/${ORAS_VERSION}/oras_${ORAS_VERSION#?}_${OS}_${ARCH}.tar.gz" && \
    mkdir -p oras-install/ && \
    tar -zxf oras_*_${OS}_${ARCH}.tar.gz -C oras-install/ && \
    install oras-install/oras /usr/local/bin/ && \
    rm -rf oras_*_${OS}_${ARCH}.tar.gz oras-install/

# TiUP
RUN curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
ENV PATH=/root/.tiup/bin:$PATH

# To run python test scripts
RUN yum install -y python3 python3-devel mysql-devel
RUN pip3 install protobuf==3.6.1 mysql mysql-connector-python==8.0.23

# For rustup toolchain
RUN rustup install nightly-2025-02-28

ENV CXXFLAGS="-stdlib=libc++"
ENV LDFLAGS="-stdlib=libc++"
ENV CC="clang"
ENV CXX="clang++"

# Set up Rust linker and flags
ENV RUSTFLAGS="-C rpath -C linker=/usr/local/bin/clang -C link-arg=-fuse-ld=lld -C link-arg=-Wl,-Bsymbolic -C link-arg=-lc++ -C link-arg=-lc++abi"
