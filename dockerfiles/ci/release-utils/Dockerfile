FROM alpine:3.18.4

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "utils image for CD release"

# install tools: bash, git, jq, yq, goemplate
RUN apk add --no-cache bash git jq yq gomplate

# install tools: oras
COPY --from=ghcr.io/oras-project/oras:v1.1.0 /bin/oras /usr/bin/oras
