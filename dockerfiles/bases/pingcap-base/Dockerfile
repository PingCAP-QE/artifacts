FROM quay.io/rockylinux/rockylinux:9.8.20260525.0
COPY --from=busybox:1.38.0-musl /bin/busybox /bin/busybox

LABEL org.opencontainers.image.authors="wuhuizuo <wuhuizuo@gmail.com>" \
      org.opencontainers.image.title="pingcap-base" \
      org.opencontainers.image.vendor="PingCAP" \
      org.opencontainers.image.source="https://github.com/PingCAP-QE/artifacts" \
      org.opencontainers.image.licenses="Apache-2.0 AND BSD-3-Clause AND GPL-2.0-only" \
      license="Apache-2.0 AND BSD-3-Clause AND GPL-2.0-only" \
      name="pingcap-base" \
      summary="PingCAP QE base image built on Rocky Linux 9" \
      vendor="PingCAP"

ARG _date=20261104
ARG PINGCAP_UID=1000
ARG PINGCAP_GID=2000
RUN echo "package refresh ${_date}" && \
    dnf upgrade -y && dnf clean all && \
    groupadd -g ${PINGCAP_GID} pingcap && \
    useradd -u ${PINGCAP_UID} -g ${PINGCAP_GID} -m pingcap

# ca-certificates-2026.2.92_v9.0.319 is the first Rocky Linux 9 build whose trust
# store no longer anchors the intermediate CAs compromised on 2026-10-20
# (RHSB-2026-012 / CVE-2026-114406). The Rocky mirrors serve it since 2026-10-23,
# so the `dnf upgrade` above installs it on a refreshed (cache-busted) layer and
# the build-time origin override that #1138 added is no longer needed.
# The check is not a version pin: any newer package passes, it only fails the
# build when a stale source would silently ship the vulnerable trust store.
RUN set -eux; \
    ver=$(rpm -q --qf '%{VERSION}' ca-certificates); \
    echo "ca-certificates: ${ver}"; \
    test "${ver%%.*}" -ge 2026
