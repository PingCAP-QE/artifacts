FROM golang:1.22.3-alpine3.19 as gomplate_builder

RUN wget https://github.com/hairyhenderson/gomplate/archive/refs/heads/main.zip -O - | unzip - && cd gomplate-main && go build -o /usr/local/bin/gomplate ./cmd/gomplate

FROM alpine:3.19.1

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "utils image for CD release"
LABEL org.opencontainers.image.source = "https://github.com/PingCAP-QE/artifacts"

# install tools: bash, git, jq, yq, goemplate
# RUN apk add --no-cache bash git jq yq uuidgen gomplate
RUN apk add --no-cache bash git jq yq uuidgen

# install gomplate
COPY --from=gomplate_builder --chown=0:0 /usr/local/bin/gomplate /usr/local/bin/gomplate

# install tools: oras
COPY --from=ghcr.io/oras-project/oras:v1.1.0 --chown=0:0 /bin/oras /usr/local/bin/oras

# install tools: manifest-tool
COPY --from=mplatform/manifest-tool:alpine-v2.1.3 --chown=0:0 /manifest-tool /usr/local/bin/manifest-tool
COPY --from=mplatform/manifest-tool:alpine-v2.1.3 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=mplatform/manifest-tool:alpine-v2.1.3 --chown=0:0 /usr/bin/docker-credential-gcloud     /usr/local/bin/docker-credential-gcloud
COPY --from=mplatform/manifest-tool:alpine-v2.1.3 --chown=0:0 /usr/bin/docker-credential-ecr-login  /usr/local/bin/docker-credential-ecr-login
COPY --from=mplatform/manifest-tool:alpine-v2.1.3 --chown=0:0 /usr/bin/docker-credential-acr-env    /usr/local/bin/docker-credential-acr-env

# install tools: k3sutil
ARG KS3UTIL_VER=2.4.2
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    wget https://ks3util-version-update.ks3-cn-beijing.ksyuncs.com/${KS3UTIL_VER}/ks3util-${OS}-${ARCH} -O /usr/local/bin/ks3util && \
    chmod a+x /usr/local/bin/ks3util

# install tools: tiup
# renovate: datasource=github-release depName=pingcap/tiup
ARG TIUP_VER=v1.14.1
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    wget -q -O - https://tiup-mirrors.pingcap.com/tiup-${TIUP_VER}-${OS}-${ARCH}.tar.gz | tar -zxvf - -C /usr/local/bin && \
    chmod 755 /usr/local/bin/tiup
