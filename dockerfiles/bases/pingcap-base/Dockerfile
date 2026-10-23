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
# Rocky Linux 9 yet, and what it ships is exactly the removal of trusted roots,
# so that is done here too.
#
# Only the roots matter: the eight compromised intermediate CAs are not present
# in a trust store themselves, so the reachable attack path is a chain that ends
# in a trusted root. Every root that can anchor one of those intermediates is
# therefore dropped: the three removed by NSS 3.131.1 (emSign Root CA - C1,
# emSign ECC Root CA - C3, emSign ECC Root CA - G3) plus the direct issuers
# emSign Root TLS CA - G3, emSign Root CS CA - G3 and AAA Certificate Services,
# which are not installed today but are present in other root programs. The
# assertions below cover that whole set, not just the three labels removed.
# `emSign Root CA - G1` is kept, as upstream keeps it too.
#
# Remove this whole block once the `dnf upgrade -y` above starts installing
# ca-certificates >= 2026.2.92_v9.0.319: rebuilding this image is then enough.
#
# The patched copy must stay outside /usr/share/pki/ca-trust-source and
# /etc/pki/ca-trust/source, because every file below those trees is read as a
# trust source and a copy would add the removed roots back.
#
# `cat "$patched" > "$src"` is deliberate: it keeps the inode, mode and SELinux
# context of the package-owned file, which `mv` from /tmp would not.
RUN set -eux; \
    src=/usr/share/pki/ca-trust-source/ca-bundle.trust.p11-kit; \
    bundle=/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem; \
    orig=/tmp/ca-bundle.p11-kit.orig; \
    patched=/tmp/ca-bundle.p11-kit; \
    before=$(grep -c 'BEGIN CERTIFICATE' "$bundle"); \
    cp "$src" "$orig"; \
    roots='emSign Root CA - C1|emSign ECC Root CA - C3|emSign ECC Root CA - G3|emSign Root TLS CA - G3|emSign Root CS CA - G3|AAA Certificate Services'; \
    matched=$(grep -cE "^label: \"(${roots})\"$" "$orig" || true); \
    g1_present=0; \
    grep -qE '^label: "emSign Root CA - G1"$' "$orig" && g1_present=1 || true; \
    awk -v roots="$roots" 'BEGIN { RS = ""; ORS = "\n\n" } \
         { keep = 1; n = split($0, l, "\n"); \
           for (i = 1; i <= n; i++) \
               if (l[i] ~ ("^label: \"" roots "\"$")) keep = 0; \
           if (keep) print }' "$orig" > "$patched"; \
    cat "$patched" > "$src"; \
    rm -f "$patched"; \
    [ -s "$src" ]; \
    update-ca-trust extract; \
    after=$(grep -c 'BEGIN CERTIFICATE' "$bundle" || true); \
    echo "ca-certificates: $(rpm -q --qf '%{VERSION}-%{RELEASE}' ca-certificates)"; \
    echo "tls bundle certs: ${before} -> ${after}"; \
    echo "root label entries matched in the source: ${matched}"; \
    ! grep -qE "^# (${roots})$" "$bundle"; \
    if [ "$g1_present" = 1 ]; then grep -qE '^# emSign Root CA - G1$' "$bundle"; fi; \
    [ "$matched" -le 8 ]; \
    [ $((before - after)) -le 6 ]; \
    rm -f "$orig"
