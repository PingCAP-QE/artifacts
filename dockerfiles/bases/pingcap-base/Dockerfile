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

ARG _date=20261022
ARG PINGCAP_UID=1000
ARG PINGCAP_GID=2000
RUN echo "package refresh ${_date}" && \
    dnf upgrade -y && dnf clean all && \
    groupadd -g ${PINGCAP_GID} pingcap && \
    useradd -u ${PINGCAP_UID} -g ${PINGCAP_GID} -m pingcap

# Temporary mitigation for the eMudhra intermediate CA compromise disclosed on
# 2026-10-20 (RHSB-2026-012, CVE-2026-114406; upstream fix is NSS 3.131.1).
# The fixed ca-certificates package (>= 2026.2.92_v9.0.319) is not published for
# Rocky Linux 9 yet, and what it ships is exactly the removal of the three roots
# below, so perform the same removal here. `emSign Root CA - G1` is kept, as
# upstream keeps it too.
#
# Remove this whole block once the `dnf upgrade -y` above starts installing
# ca-certificates >= 2026.2.92_v9.0.319: rebuilding this image is then enough.
#
# The patched copy must stay outside /usr/share/pki/ca-trust-source and
# /etc/pki/ca-trust/source, because every file below those trees is read as a
# trust source and a copy would add the removed roots back.
RUN set -eux; \
    src=/usr/share/pki/ca-trust-source/ca-bundle.trust.p11-kit; \
    awk 'BEGIN { RS = ""; ORS = "\n\n" } \
         !/label: "emSign Root CA - C1"/ && \
         !/label: "emSign ECC Root CA - C3"/ && \
         !/label: "emSign ECC Root CA - G3"/' "$src" > /tmp/ca-bundle.p11-kit; \
    cat /tmp/ca-bundle.p11-kit > "$src"; \
    rm -f /tmp/ca-bundle.p11-kit; \
    update-ca-trust extract; \
    bundle=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem; \
    echo "ca-certificates: $(rpm -q --qf '%{VERSION}-%{RELEASE}' ca-certificates)"; \
    echo "tls bundle certs: $(grep -c 'BEGIN CERTIFICATE' "$bundle")"; \
    ! grep -qE '^# (emSign Root CA - C1|emSign ECC Root CA - C3|emSign ECC Root CA - G3)$' "$bundle"; \
    grep -q '^# emSign Root CA - G1$' "$bundle"
