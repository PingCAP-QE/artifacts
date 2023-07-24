# Base image
# renovate: datasource=docker depName=centos
FROM centos:7.9.2009

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"

ARG ARCH=amd64
ARG OS=linux

# install packages.
RUN yum makecache -y && \
    yum install -y epel-release centos-release-scl && \
    yum install -y deltarpm && \
    # Import the missing public key
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7 && \
    yum makecache -y && \
    yum install -y wget unzip psmisc lsof jq && \
    yum clean all

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
