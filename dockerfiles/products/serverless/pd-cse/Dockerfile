FROM ghcr.io/pingcap-qe/bases/pd-base:v1.12.6@sha256:aeff60b852ff121ed05e02fed026a1bf5755050d54581d037f6376416ccda2b4
RUN dnf install --allowerasing -y curl \
    && ln -sfn /bin/bash /bin/sh \
    && dnf clean all
COPY pd-server pd-ctl pd-recover /
EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
