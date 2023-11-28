FROM golang:1.21.4-alpine3.18 as gomplate_builder

RUN wget https://github.com/hairyhenderson/gomplate/archive/refs/heads/main.zip -O - | unzip - && cd gomplate-main && go build -o /usr/local/bin/gomplate ./cmd/gomplate

FROM alpine:3.18.4

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "utils image for CD release"

# install tools: bash, git, jq, yq, goemplate
# RUN apk add --no-cache bash git jq yq gomplate
RUN apk add --no-cache bash git jq yq
COPY --from=gomplate_builder /usr/local/bin/gomplate /usr/local/bin/gomplate

# install tools: oras
COPY --from=ghcr.io/oras-project/oras:v1.1.0 /bin/oras /usr/local/bin/oras

# install tools: manifest-tool
COPY --from=mplatform/manifest-tool:alpine-v2.1.3 /manifest-tool /usr/local/bin/manifest-tool
