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

# ca-certificates-2026.2.92_v9.0.319 is the first Rocky Linux 9 build whose trust
# store no longer anchors the intermediate CAs compromised on 2026-10-20
# (RHSB-2026-012 / CVE-2026-114406). It is already published on the origin while
# the mirrorlist-selected mirrors still lag, so the `dnf upgrade` above keeps
# installing 2025.2.80. Pull that single package from the origin and drop the
# temporary repo again, so the image keeps the stock mirror configuration.
# The trailing check is not a version pin: any newer package passes, it only
# fails the build when a stale source would silently ship the vulnerable trust
# store. Remove this block once the mirrors serve the fixed package.
RUN set -eux; \
    printf '%s\n' \
      '[origin-baseos]' \
      'name=Rocky Linux BaseOS (build-time origin only)' \
      'baseurl=https://dl.rockylinux.org/pub/rocky/$releasever/BaseOS/$basearch/os/' \
      'gpgcheck=1' \
      'gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-rockyofficial' \
      'enabled=1' \
      'metadata_expire=0' \
      > /etc/yum.repos.d/zz-origin.repo; \
    dnf -y --refresh upgrade ca-certificates --repo=origin-baseos; \
    rm -f /etc/yum.repos.d/zz-origin.repo; \
    ver=$(rpm -q --qf '%{VERSION}' ca-certificates); \
    echo "ca-certificates: ${ver}"; \
    test "${ver%%.*}" -ge 2026
