FROM rockylinux:9.3.20231119 as builder

RUN dnf install -y openssl-devel

RUN dnf install -y \
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
RUN curl https://sh.rustup.rs -sSf | sh -s -- --no-modify-path --default-toolchain none -y
ENV PATH /root/.cargo/bin/:$PATH

