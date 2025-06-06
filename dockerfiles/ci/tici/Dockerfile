# base image dockerfile: ci/base/Dockerfile
ARG BASE_IMG
FROM $BASE_IMG

RUN yum install -y wget lsof openssh-server openssh-clients sudo mysql protobuf-compiler perl-core

# MinIO
RUN wget -O minio https://dl.min.io/server/minio/release/linux-amd64/archive/minio.RELEASE.2025-02-07T23-21-09Z && \
    chmod +x minio && \
    wget -O mc https://dl.min.io/client/mc/release/linux-amd64/archive/mc.RELEASE.2025-02-08T19-14-21Z && \
    chmod +x mc && \
    mv minio /usr/local/bin/minio && \
    mv mc /usr/local/bin/mc

# TiUP
RUN curl --proto '=https' --tlsv1.2 -sSf https://tiup-mirrors.pingcap.com/install.sh | sh
ENV PATH=/root/.tiup/bin:$PATH

# To run python test scripts
RUN yum install -y python3 python3-devel mysql-devel
RUN pip3 install protobuf==3.6.1 mysql mysql-connector-python==8.0.23

RUN wget http://fileserver.pingcap.net/download/builds/devbuild/7930/ticdc-newarch-linux-amd64.tar.gz && \
    tar -zxvf ticdc-newarch-linux-amd64.tar.gz -C /usr/local/