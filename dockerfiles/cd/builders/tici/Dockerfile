# syntax=docker/dockerfile:1
# build requires:
#   - docker >= v23.0
#
# build steps:
#   - git clone --recurse-submodules <tici-repo-url> tici
#   - docker build -t tiflash -f Dockerfile ./tici

########### stage: builder
FROM ghcr.io/pingcap-qe/cd/builders/tiflash:v2025.4.15-rocky8-llvm-17.0.6-v2 AS builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiCI"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y perl-core openssl-devel

ENV CXXFLAGS="-stdlib=libc++" \
    LDFLAGS="-stdlib=libc++"

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y sudo && \
    useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/builder
USER builder

########### stage: building
FROM builder AS building

ADD . /ws
RUN CARGO_NET_GIT_FETCH_WITH_CLI=true make release -c /ws
RUN mkdir /ws/output && mv /ws/target/release/tici /ws/output/tici
RUN /ws/output/tici version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tiflash-base:v1.9.2
COPY --from=building /ws/output/tici /app/tici

ENTRYPOINT ["/app/tici"]

# test it
RUN /app/tici version
