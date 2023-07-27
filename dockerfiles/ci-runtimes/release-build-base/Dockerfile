# Base image
# renovate: datasource=docker depName=centos
FROM centos:7.9.2009

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"

ARG ARCH=amd64
ARG OS=linux

# install packages.
RUN yum update --nogpgcheck -y && \
    yum install --nogpgcheck -y epel-release deltarpm && \
    yum update --nogpgcheck -y && \
    yum groupinstall --nogpgcheck -y "Development Tools" && \
    yum install --nogpgcheck -y \
    # libraries.
    bind-license cyrus-sasl-lib glib2 krb5-libs nss nss-sysinit nss-tools openssl-libs systemd systemd-libs xpat xz xz-libs zlib \
    # insall tools.
    jq lsof gzip psmisc unzip wget which \
    # Development tools.
    cmake gawk git libstdc++-static llvm protobuf-compiler python3 \
    && \
    yum clean all
# should run after yum.
RUN ln -sf /usr/bin/python3 /usr/bin/python

##### install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.20.6
RUN curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.${OS}-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH

##### install rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain nightly
ENV PATH /root/.cargo/bin:$PATH

##### install tools: bazelisk, yq, oras
# renovate: datasource=github-tags depName=bazelbuild/bazelisk
ARG BAZELISK_VERSION=v1.17.0
RUN curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-${OS}-${ARCH}" -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

# yq tool
# renovate: datasource=github-tags depName=mikefarah/yq
ARG YQ_VERSION=v4.34.1
RUN curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# oras tool
# renovate: datasource=github-tags depName=oras-project/oras
ARG ORAS_VERSION=1.0.0
RUN curl -LO "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_${OS}_${ARCH}.tar.gz" && \
    mkdir -p oras-install/ && \
    tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/ && \
    mv oras-install/oras /usr/local/bin/ && \
    rm -rf oras_${ORAS_VERSION}_*.tar.gz oras-install/

# go template tool
# renovate: datasource=docker depName=hairyhenderson/gomplate
COPY --from=hairyhenderson/gomplate:v3.11.5 /gomplate /usr/local/bin/gomplate
