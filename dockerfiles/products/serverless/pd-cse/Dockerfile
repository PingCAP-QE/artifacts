FROM ghcr.io/pingcap-qe/bases/pd-base:v1.12.5
RUN dnf install --allowerasing -y curl \
    && ln -sfn /bin/bash /bin/sh \
    && dnf clean all
COPY pd-server pd-ctl pd-recover /
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
