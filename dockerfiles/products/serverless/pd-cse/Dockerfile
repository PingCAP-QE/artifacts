FROM ghcr.io/pingcap-qe/bases/pd-base:v1.12.6@sha256:9c8abf01cf172078d258be9c8238a65f041fea0b52edcdbf7a5855809d231179
RUN dnf install --allowerasing -y curl \
    && ln -sfn /bin/bash /bin/sh \
    && dnf clean all
COPY pd-server pd-ctl pd-recover /
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
