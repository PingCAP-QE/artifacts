FROM docker.io/library/alpine:3.24@sha256:3f4d6b32e26703c6082839234f43769d5046b3ac7c910033911d1e71d8cd630a
RUN apk add tzdata bind-tools --no-cache
ARG TARGETARCH
COPY bin/${TARGETARCH}/tidb-scheduler /usr/local/bin/tidb-scheduler
COPY bin/${TARGETARCH}/tidb-discovery /usr/local/bin/tidb-discovery
COPY bin/${TARGETARCH}/tidb-controller-manager /usr/local/bin/tidb-controller-manager
COPY bin/${TARGETARCH}/tidb-admission-webhook /usr/local/bin/tidb-admission-webhook
