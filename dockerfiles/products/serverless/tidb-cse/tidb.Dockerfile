FROM ghcr.io/pingcap-qe/bases/tidb-base:v1.12.6@sha256:1fca90e621de74c295fbd53f7cec0c652a019bd275fc0799aa786dc09e0a31e1
RUN dnf install -y epel-release \
    && dnf install -y dumb-init nmap-ncat \
    && ln -sfn /bin/bash /bin/sh \
    && dnf clean all
COPY tidb-server /tidb-server
WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/usr/bin/dumb-init", "/tidb-server"]
