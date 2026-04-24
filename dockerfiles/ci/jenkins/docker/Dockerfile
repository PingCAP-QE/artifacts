# Base image dockerfile: ci/base/Dockerfile
ARG BASE_IMG=ghcr.io/pingcap-qe/ci/base:v2026.3.29-14-g90ae7ef-go1.25

# renovate: datasource=docker depName=docker
ARG DOCKER_CLI_IMG=docker:28.4.0-cli

FROM ${DOCKER_CLI_IMG} AS dockercli
FROM ${BASE_IMG}

COPY --from=dockercli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=dockercli /usr/local/libexec/docker/cli-plugins /usr/local/libexec/docker/cli-plugins

RUN ln -sf /usr/local/libexec/docker/cli-plugins/docker-compose /usr/local/bin/docker-compose && \
    ln -sf /usr/local/libexec/docker/cli-plugins/docker-buildx /usr/local/bin/docker-buildx
