# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - git clone <tem-git-url> tem
#   - docker build -t tem -f Dockerfile ./tem

########### stage: builder
FROM quay.io/rockylinux/rockylinux:8.10.20240528 AS builder
LABEL org.opencontainers.image.authors "shenhaibo@pingcap.com"
LABEL org.opencontainers.image.description "builder with protobuf and Go toolchain for TEM cd"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf install -y epel-release && \
    dnf install -y make git gcc wget sshpass unzip findutils

# install protoc.
# renovate: datasource=github-release depName=protocolbuffers/protobuf
ARG PROTOBUF_VER=v3.15.8
RUN FILE=$([ "$(arch)" = "aarch64" ] && echo "protoc-${PROTOBUF_VER#?}-linux-aarch_64.zip" || echo "protoc-${PROTOBUF_VER#?}-linux-$(arch).zip"); \
    curl -LO "https://github.com/protocolbuffers/protobuf/releases/download/${PROTOBUF_VER}/${FILE}" && unzip "$FILE" -d /usr/local/ && rm -f "$FILE"

# Install buf
# Detect architecture and download the corresponding buf version
ARG BUF_VER=v1.47.2
RUN ARCH=$([ "$(arch)" = "x86_64" ] && echo "x86_64" || echo "aarch64"); \
    curl -LO "https://github.com/bufbuild/buf/releases/download/${BUF_VER}/buf-Linux-${ARCH}.tar.gz" && \
    tar -xzvf buf-Linux-${ARCH}.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/buf && \
    rm -f buf-Linux-${ARCH}.tar.gz
ENV PATH /usr/local/bin/buf/bin/:$PATH

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.21.13
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

# Install go tools
RUN go install github.com/googleapis/api-linter/cmd/api-linter@v1.67.4
RUN go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-grpc-gateway@v2.23.0
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0
RUN go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v2.23.0
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.35.1
ENV PATH /root/go/bin/:$PATH

# install tools: tiup
# renovate: datasource=github-release depName=pingcap/tiup
ARG TIUP_VER=1.16.1
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    wget -q -O - https://tiup-mirrors.pingcap.com/tiup-v${TIUP_VER}-${OS}-${ARCH}.tar.gz | tar -zxvf - -C /usr/local/bin && \
    chmod 755 /usr/local/bin/tiup && \
    mkdir -p "$HOME/.tiup/bin"

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y sudo && \
    useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
USER builder

########### stage: building
FROM builder AS building
COPY . /tem
RUN make build -C /tem
RUN /tem/bin/tem --version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/pingcap-base:v1.9.2
COPY --from=building /tem/bin/tem /tem

WORKDIR /
EXPOSE 8080
ENTRYPOINT ["/tem"]

# test it
RUN /tem --version
