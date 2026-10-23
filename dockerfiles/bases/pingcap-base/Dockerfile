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

ARG _date=20261023
ARG PINGCAP_UID=1000
ARG PINGCAP_GID=2000
RUN echo "package refresh ${_date}" && \
    dnf upgrade -y && dnf clean all && \
    groupadd -g ${PINGCAP_GID} pingcap && \
    useradd -u ${PINGCAP_UID} -g ${PINGCAP_GID} -m pingcap

# Release guard for the eMudhra intermediate CA compromise (RHSB-2026-012 /
# CVE-2026-114406). This refresh exists to pick up the ca-certificates build
# whose trust store no longer anchors the compromised intermediates, which Rocky
# Linux 9 first published as 2026.2.92_v9.0.319. Any newer version passes, so
# nothing is pinned here; the check only stops the build when a stale mirror
# would silently keep the vulnerable package. Drop it with a future `_date`
# bump once this generation is long gone.
RUN set -eux; \
    ver=$(rpm -q --qf '%{VERSION}' ca-certificates); \
    echo "ca-certificates: ${ver}"; \
    test "${ver%%.*}" -ge 2026
