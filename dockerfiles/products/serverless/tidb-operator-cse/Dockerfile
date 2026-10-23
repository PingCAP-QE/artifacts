FROM ghcr.io/pingcap-qe/bases/pingcap-base:v1.12.4@sha256:fc77996d3438ce6040a48a5caa73fa7a207d120114e37d20b90f86f5db22d70a
RUN dnf install -y tzdata bind-utils && dnf clean all
ARG TARGETARCH
COPY bin/${TARGETARCH}/tidb-scheduler /usr/local/bin/tidb-scheduler
COPY bin/${TARGETARCH}/tidb-discovery /usr/local/bin/tidb-discovery
COPY bin/${TARGETARCH}/tidb-controller-manager /usr/local/bin/tidb-controller-manager
COPY bin/${TARGETARCH}/tidb-admission-webhook /usr/local/bin/tidb-admission-webhook
