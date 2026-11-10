FROM ghcr.io/pingcap-qe/bases/tidb-base:v1.12.5
RUN dnf install -y epel-release \
    && dnf install -y dumb-init nmap-ncat \
    && ln -sfn /bin/bash /bin/sh \
    && dnf clean all
COPY tidb-server /tidb-server
WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/usr/bin/dumb-init", "/tidb-server"]
