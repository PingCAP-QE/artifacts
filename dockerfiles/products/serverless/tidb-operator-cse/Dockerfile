FROM ghcr.io/pingcap-qe/bases/pingcap-base:v1.12.6@sha256:78abe406f6fccdaa962de58c074e1b5b25cf710ebb1bfcba2f01206f75b0b04b
RUN dnf install -y tzdata bind-utils && dnf clean all
ARG TARGETARCH
COPY bin/${TARGETARCH}/tidb-scheduler /usr/local/bin/tidb-scheduler
COPY bin/${TARGETARCH}/tidb-discovery /usr/local/bin/tidb-discovery
COPY bin/${TARGETARCH}/tidb-controller-manager /usr/local/bin/tidb-controller-manager
COPY bin/${TARGETARCH}/tidb-admission-webhook /usr/local/bin/tidb-admission-webhook
