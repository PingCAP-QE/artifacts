# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules --branch feature/release-6.5-fips https://github.com/tikv/tikv.git tikv
#   - docker build -t tikv -f Dockerfile ./tikv

########### stage: builder
FROM quay.io/rockylinux/rockylinux:9.5.20241118 AS builder
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "binary builder for TiKV with FIPS support"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# install packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf --enablerepo=crb install -y --allowerasing \
    git findutils gcc gcc-c++ make cmake dwz curl openssl-devel perl python3 \
    libstdc++-static

# install protoc.
# renovate: datasource=github-release depName=protocolbuffers/protobuf
ARG PROTOBUF_VER=v3.15.8
RUN FILE=$([ "$(arch)" = "aarch64" ] && echo "protoc-${PROTOBUF_VER#?}-linux-aarch_64.zip" || echo "protoc-${PROTOBUF_VER#?}-linux-$(arch).zip"); \
    curl -LO "https://github.com/protocolbuffers/protobuf/releases/download/${PROTOBUF_VER}/${FILE}" && unzip "$FILE" -d /usr/local/ && rm -f "$FILE"

# install rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain none
ENV PATH /root/.cargo/bin/:$PATH

########### stage: non-root-builder, used for development with non-root user.
FROM builder AS non-root-builder
RUN useradd builder --create-home --shell=/bin/bash --uid=1000 --user-group && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd
USER builder

########### stage: building
FROM builder AS building
COPY . /ws
RUN --mount=type=cache,target=/tikv/target \
    ENABLE_FIPS=1 ROCKSDB_SYS_STATIC=1 make dist_release -C /ws
RUN /ws/bin/tikv-server --version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tikv-base:v1.9.2-fips

ENV MALLOC_CONF="prof:true,prof_active:false"
COPY --from=building /ws/bin/tikv-server  /tikv-server
COPY --from=building /ws/bin/tikv-ctl     /tikv-ctl

EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
