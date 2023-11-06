FROM alpine:3.18.4

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"

# install tools: git, jq, yq, goemplate
RUN apk add --no-cache git jq yq gomplate

# install tools: oras
COPY --from=ghcr.io/oras-project/oras:v1.1.0 /bin/oras /usr/bin/oras
