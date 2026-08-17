# syntax=docker/dockerfile:1.10
FROM quay.io/rockylinux/rockylinux:9.8.20260525.0
COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox

LABEL --remove=io.buildah.version \
      --remove=license \
      --remove=name \
      --remove=org.opencontainers.image.authors \
      --remove=org.opencontainers.image.licenses \
      --remove=org.opencontainers.image.source \
      --remove=org.opencontainers.image.title \
      --remove=org.opencontainers.image.vendor \
      --remove=org.opencontainers.image.version \
      --remove=summary \
      --remove=vendor \
      --remove=version

LABEL org.opencontainers.image.authors="Flare Zuo <wuhui.zuo@pingcap.com>" \
      org.opencontainers.image.title="pingcap-base" \
      org.opencontainers.image.vendor="PingCAP" \
      org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts" \
      org.opencontainers.image.licenses="Apache-2.0"

ARG _date=20260817
ARG PINGCAP_UID=1000
ARG PINGCAP_GID=2000
RUN dnf upgrade -y && dnf clean all && \
    groupadd -g ${PINGCAP_GID} pingcap && \
    useradd -u ${PINGCAP_UID} -g ${PINGCAP_GID} -m pingcap
