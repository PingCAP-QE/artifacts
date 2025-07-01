ARG BASE_IMG=ghcr.io/pingcap-qe/cd/builders/tiflash:v2024.10.8-135-g43bfc3c-centos7
FROM $BASE_IMG

RUN yum install -y wget lsof openssh-server openssh-clients sudo mysql protobuf-compiler perl-core openssl-devel

# MinIO
RUN wget -q -O minio https://dl.min.io/server/minio/release/linux-amd64/archive/minio.RELEASE.2025-02-07T23-21-09Z && \
    chmod +x minio && \
    wget -q -O mc https://dl.min.io/client/mc/release/linux-amd64/archive/mc.RELEASE.2025-02-08T19-14-21Z && \
    chmod +x mc && \
    mv minio /usr/local/bin/minio && \
    mv mc /usr/local/bin/mc

# TiUP
RUN curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
ENV PATH=/root/.tiup/bin:$PATH

# To run python test scripts
RUN yum install -y python3 python3-devel mysql-devel
RUN pip3 install protobuf==3.6.1 mysql mysql-connector-python==8.0.23

# For rustup toolchain
ENV RUSTUP_DIST_SERVER="https://mirrors.ustc.edu.cn/rust-static" RUSTUP_UPDATE_ROOT="https://mirrors.ustc.edu.cn/rust-static/rustup"
RUN rustup install nightly-2025-02-28

# Install Go and build ticdc
RUN wget -q https://go.dev/dl/go1.23.10.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && tar -C /usr/local -xzf go1.23.10.linux-amd64.tar.gz && \
    go version && \
    rm go1.23.10.linux-amd64.tar.gz

RUN git clone https://github.com/pingcap/ticdc.git && \
    cd ticdc && \
    git fetch origin pull/1403/head:pr-1403 && git checkout pr-1403 && \
    make cdc && \
    mv bin/cdc /usr/local/bin/cdc && \
    cd .. && \
    rm -rf ticdc

# Dataset (put it at last because it takes a long time to download)
# It could be cached elsewhere to reduce size of the image
RUN wget -q https://quickwit-datasets-public.s3.amazonaws.com/hdfs-logs-multitenants.json.gz && gzip -d hdfs-logs-multitenants.json.gz
