# syntax=docker/dockerfile:1.7
#
# Alpine x glibc base image matrix.
#
# Two targets:
#   donor: glibc 2.30-2.35, copied from a pinned frolvlad donor image.
#          The donor images are amd64-only, so this target rejects other arches.
#   apk:   glibc 2.36-2.44, installed from dalet-oss signed APK releases
#          (amd64 + arm64). No glibc compilation or packaging on our side.
#
# Build through skaffold profiles (see skaffold.yaml / matrix.yaml), or:
#   docker buildx build --target donor --platform linux/amd64 \
#     --build-arg ALPINE_VERSION=3.22 \
#     --build-arg GLIBC_IMAGE=frolvlad/alpine-glibc:alpine-3.11_glibc-2.30@sha256:... .
#   docker buildx build --target apk --platform linux/amd64,linux/arm64 \
#     --build-arg ALPINE_VERSION=3.22 --build-arg GLIBC_VERSION=2.36 .

ARG GLIBC_IMAGE=frolvlad/alpine-glibc:alpine-3.11_glibc-2.30@sha256:b6165080982253b82ad8e0a782ba2b56309909de48f617fbff1aa2867408c787
ARG ALPINE_VERSION=3.22
# Optional mirror root, e.g. https://mirrors.aliyun.com/alpine
ARG ALPINE_REPO=""

FROM ${GLIBC_IMAGE} AS donor-src

# ---------- glibc 2.30 - 2.35 (linux/amd64) ----------

FROM alpine:${ALPINE_VERSION} AS donor

ARG ALPINE_REPO

COPY --from=donor-src /usr/glibc-compat /usr/glibc-compat
COPY --from=donor-src /etc/nsswitch.conf /etc/nsswitch.conf

RUN set -eux; \
    if [ -n "${ALPINE_REPO}" ]; then \
      sed -i "s|https://dl-cdn.alpinelinux.org/alpine|${ALPINE_REPO}|" /etc/apk/repositories; \
    fi; \
    case "$(apk --print-arch)" in \
      x86_64)  mkdir -p /lib64; \
               ln -sf /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /lib/ld-linux-x86-64.so.2; \
               ln -sf /usr/glibc-compat/lib/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2 ;; \
      *) echo "donor target only supports linux/amd64" >&2; exit 1 ;; \
    esac; \
    ln -sf /usr/glibc-compat/etc/ld.so.cache /etc/ld.so.cache; \
    echo 'export LANG=C.UTF-8' > /etc/profile.d/locale.sh; \
    /usr/glibc-compat/sbin/ldconfig; \
    apk add --no-cache tzdata

ENV LANG=C.UTF-8 \
    TZ=UTC

CMD ["/bin/sh"]

# ---------- glibc 2.36 - 2.44 (linux/amd64 + linux/arm64) ----------

FROM alpine:${ALPINE_VERSION} AS apk

ARG GLIBC_VERSION=2.36
ARG TARGETARCH
ARG ALPINE_REPO

RUN set -eux; \
    if [ -n "${ALPINE_REPO}" ]; then \
      sed -i "s|https://dl-cdn.alpinelinux.org/alpine|${ALPINE_REPO}|" /etc/apk/repositories; \
    fi; \
    apk add --no-cache --virtual .glibc-deps curl ca-certificates; \
    case "${GLIBC_VERSION}" in \
      2.3[0-5]) echo "use the donor target for glibc <= 2.35" >&2; exit 1 ;; \
      2.44) suffix="-r1" ;; \
      *) suffix="" ;; \
    esac; \
    tag="${GLIBC_VERSION}-${TARGETARCH}${suffix}"; \
    base="https://github.com/dalet-oss/alpine-glibc/releases/download/${tag}"; \
    curl -fsSL -o /etc/apk/keys/alpine-packaging-rsa.pub \
      https://raw.githubusercontent.com/dalet-oss/alpine-glibc/master/alpine-packaging-rsa.pub; \
    for p in glibc glibc-bin glibc-i18n; do \
      curl -fsSL -o "/tmp/${p}.apk" "${base}/${p}-${GLIBC_VERSION}.apk"; \
    done; \
    apk add --no-cache --force-overwrite /tmp/glibc.apk; \
    apk add --no-cache /tmp/glibc-bin.apk; \
    apk add --no-cache /tmp/glibc-i18n.apk; \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true; \
    echo 'export LANG=C.UTF-8' > /etc/profile.d/locale.sh; \
    apk del glibc-i18n; \
    rm -f /tmp/*.apk /etc/apk/keys/alpine-packaging-rsa.pub; \
    mkdir -p /lib64; \
    ln -sf /usr/glibc-compat/etc/ld.so.cache /etc/ld.so.cache; \
    /usr/glibc-compat/sbin/ldconfig; \
    apk del .glibc-deps; \
    apk add --no-cache tzdata

ENV LANG=C.UTF-8 \
    TZ=UTC

CMD ["/bin/sh"]
