FROM docker.io/library/alpine:3.24@sha256:be2656061b536c1883c4034790e21d0a09c5aaaf51968b89368a3c0371ea2c9a
RUN apk add tzdata bind-tools --no-cache
ARG TARGETARCH
COPY bin/${TARGETARCH}/tidb-scheduler /usr/local/bin/tidb-scheduler
COPY bin/${TARGETARCH}/tidb-discovery /usr/local/bin/tidb-discovery
COPY bin/${TARGETARCH}/tidb-controller-manager /usr/local/bin/tidb-controller-manager
COPY bin/${TARGETARCH}/tidb-admission-webhook /usr/local/bin/tidb-admission-webhook
