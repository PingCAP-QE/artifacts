FROM rockylinux:9 as builder-base

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

# Install Rustup
RUN curl https://sh.rustup.rs -sSf | sh -s -- --no-modify-path --default-toolchain none -y
ENV PATH /root/.cargo/bin/:$PATH
