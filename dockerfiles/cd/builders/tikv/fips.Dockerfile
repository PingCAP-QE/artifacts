# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules --branch feature/release-6.5-fips https://github.com/tikv/tikv.git tikv
#   - docker build -t tikv -f Dockerfile ./tikv

########### stage: Builder
FROM rockylinux:9.3.20231119 as builder

# install packages.
RUN dnf install -y \
  openssl-devel \
  gcc \
  gcc-c++ \
  make \
  cmake \
  perl \
  git \
  findutils \
  curl \
  python3 --allowerasing && \
  dnf --enablerepo=crb install -y \
  libstdc++-static && \
  dnf clean all

# install protoc.
# renovate: datasource=github-release depName=protocolbuffers/protobuf
ARG PROTOBUF_VER=v3.15.8
RUN FILE=$([ "$(arch)" = "aarch64" ] && echo "protoc-${PROTOBUF_VER#?}-linux-aarch_64.zip" || echo "protoc-${PROTOBUF_VER#?}-linux-$(arch).zip"); \
  curl -LO "https://github.com/protocolbuffers/protobuf/releases/download/${PROTOBUF_VER}/${FILE}" && unzip "$FILE" -d /usr/local/ && rm -f "$FILE"

# Install Rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain none
ENV PATH /root/.cargo/bin/:$PATH

########### stage: Buiding
FROM builder as building
COPY . /tikv
RUN --mount=type=cache,target=/tikv/target \
  source /opt/rh/devtoolset-8/enable && \
  ENABLE_FIPS=1 \
  ROCKSDB_SYS_STATIC=1 \
  make dist_release -C /tikv
RUN /tikv/bin/tikv-server --version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tikv-base:v1.9.1-fips

ENV MALLOC_CONF="prof:true,prof_active:false"
COPY --from=building /tikv/bin/tikv-server  /tikv-server
COPY --from=building /tikv/bin/tikv-ctl     /tikv-ctl

EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
