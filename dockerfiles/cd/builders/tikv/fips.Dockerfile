FROM rockylinux:9 as builder

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

# Install protoc
RUN case $(uname -m) in x86_64) url='https://github.com/protocolbuffers/protobuf/releases/download/v3.15.8/protoc-3.15.8-linux-x86_64.zip';; arm64|aarch64) url='https://github.com/protocolbuffers/protobuf/releases/download/v3.15.8/protoc-3.15.8-linux-aarch_64.zip';; *) exit 1;; esac; \
	curl -o protoc.zip -L $url && \
	unzip -d /usr/local protoc.zip && \
	rm protoc.zip;

# Install Rustup
RUN curl https://sh.rustup.rs -sSf | sh -s -- --no-modify-path --default-toolchain none -y
ENV PATH /root/.cargo/bin/:$PATH

