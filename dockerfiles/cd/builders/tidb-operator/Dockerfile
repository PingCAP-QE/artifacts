# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone https://github.com/pingcap/tidb.git tidb 
#   - rm tidb/.dockerignore # make step depended on git metadata.
#   - docker build -t tidb -f Dockerfile ./tidb

########### stage: Builder
ARG GOLANG_VERSION=1.21.12
FROM golang:${GOLANG_VERSION} as builder

# install packages.
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && apt-get install -y uuid-runtime

LABEL go-version="${GOLANG_VERSION}"

########### stage: Buiding
FROM builder as building
COPY . /ws
ARG GOPROXY
RUN GOPROXY=${GOPROXY} make build -C /ws && mv /ws/images/tidb-operator/bin/$(arch) /ws/bin

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tidb-base:v1.9.0

COPY --from=building /ws/bin/tidb-scheduler /usr/local/bin/tidb-scheduler
COPY --from=building /ws/bin/tidb-discovery /usr/local/bin/tidb-discovery
COPY --from=building /ws/bin/tidb-controller-manager  /usr/local/bin/tidb-controller-manager
COPY --from=building /ws/bin/tidb-admission-webhook /usr/local/bin/tidb-admission-webhook
