FROM alpine:3.20.2

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "utils image for CD release"
LABEL org.opencontainers.image.source = "https://github.com/PingCAP-QE/artifacts"

# install tools: k3sutil
ARG KS3UTIL_VER=2.4.2
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    wget https://ks3util-version-update.ks3-cn-beijing.ksyuncs.com/${KS3UTIL_VER}/ks3util-${OS}-${ARCH} -O /usr/local/bin/ks3util && \
    chmod a+x /usr/local/bin/ks3util
