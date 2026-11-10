FROM ghcr.io/pingcap-qe/bases/pingcap-base:v1.12.6@sha256:047091400d8a700fd3c51bd441cb5cc4436493e1d2e4a9335e7becb51665d51f
RUN dnf install -y tzdata bind-utils && dnf clean all
ARG TARGETARCH
COPY bin/${TARGETARCH}/tidb-scheduler /usr/local/bin/tidb-scheduler
COPY bin/${TARGETARCH}/tidb-discovery /usr/local/bin/tidb-discovery
COPY bin/${TARGETARCH}/tidb-controller-manager /usr/local/bin/tidb-controller-manager
COPY bin/${TARGETARCH}/tidb-admission-webhook /usr/local/bin/tidb-admission-webhook
