# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone https://github.com/pingcap/tidb-operator.git tidb
#   - rm tidb-operator/.dockerignore # make step depended on git metadata.
#   - docker build -t tidb-operator -f Dockerfile ./tidb-operator

########### stage: builder
ARG GOLANG_VERSION=1.23.6
FROM golang:${GOLANG_VERSION} as builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiDB Operator"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"
LABEL go-version="${GOLANG_VERSION}"

# install packages.
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y uuid-runtime


########### stage: building
FROM builder as building
COPY . /ws
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make build -C /ws && mv /ws/images/tidb-operator/bin/$(arch) /ws/bin

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/pingcap-base:v1.9.2

COPY --from=building /ws/bin/tidb-scheduler /usr/local/bin/tidb-scheduler
COPY --from=building /ws/bin/tidb-discovery /usr/local/bin/tidb-discovery
COPY --from=building /ws/bin/tidb-controller-manager  /usr/local/bin/tidb-controller-manager
COPY --from=building /ws/bin/tidb-admission-webhook /usr/local/bin/tidb-admission-webhook

# test it
RUN /usr/local/bin/tidb-scheduler -V
RUN /usr/local/bin/tidb-discovery -V
RUN /usr/local/bin/tidb-controller-manager -V
RUN /usr/local/bin/tidb-admission-webhook -V
