FROM ghcr.io/pingcap-qe/bases/tidb-base:v1.12.6@sha256:db0659ad73830ae04cef2aac7e08636d9ae28bf0cde54482de47558113c430f7
RUN dnf install -y epel-release \
    && dnf install -y dumb-init nmap-ncat \
    && ln -sfn /bin/bash /bin/sh \
    && dnf clean all
COPY tidb-server /tidb-server
WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/usr/bin/dumb-init", "/tidb-server"]
