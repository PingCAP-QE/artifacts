FROM golang:1.21.4-alpine3.18 as gomplate_builder

RUN wget https://github.com/wuhuizuo/gomplate/archive/refs/heads/feature/semver-functions.zip -O - | unzip - && cd gomplate-feature-semver-functions && go build -o /usr/bin/gomplate ./cmd/gomplate

FROM alpine:3.18.4

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "utils image for CD release"

# install tools: bash, git, jq, yq, goemplate
# RUN apk add --no-cache bash git jq yq gomplate
RUN apk add --no-cache bash git jq yq
COPY --from=gomplate_builder /usr/bin/gomplate /usr/bin/gomplate

# install tools: oras
COPY --from=ghcr.io/oras-project/oras:v1.1.0 /bin/oras /usr/bin/oras
