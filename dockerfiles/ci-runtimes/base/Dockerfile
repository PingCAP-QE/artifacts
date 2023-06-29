# Base image
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.20.5
FROM golang:${GOLANG_VERSION}

LABEL org.opencontainers.image.authors="wuhui.zuo@pingcap.com"

ARG ARCH=amd64
ARG OS=linux
ARG OPENJDK_VER=17

# install packages.
RUN apt-get update && \
    apt-get install -y build-essential wget unzip psmisc lsof jq mariadb-client openjdk-${OPENJDK_VER}-jdk && \
    apt-get clean

# java tool chains -> open-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-${OPENJDK_VER}-openjdk-${ARCH}
ENV PATH=$PATH:$JAVA_HOME/bin

##### install tools: bazelisk, yq, oras, codecov, gradle, apache-maven
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

# codecov tool
# renovate: datasource=github-tags depName=codecov/uploader
ARG CODECOV_VERSION=v0.5.0
# only has x86-64 edition.
RUN curl -fsSL https://uploader.codecov.io/${CODECOV_VERSION}/linux/codecov -o /usr/local/bin/codecov && chmod +x /usr/local/bin/codecov

# java tool chains -> gradle
ARG GRADLE_VER=7.4.2
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VER}-bin.zip && \
    unzip gradle-${GRADLE_VER}-bin.zip -d /opt && \
    rm gradle-${GRADLE_VER}-bin.zip
ENV PATH=$PATH:/opt/gradle-${GRADLE_VER}/bin

# java tool chains -> apache-maven
ARG MAVEN_VER=3.8.8
RUN wget https://downloads.apache.org/maven/maven-3/${MAVEN_VER}/binaries/apache-maven-${MAVEN_VER}-bin.tar.gz && \
    tar -xf apache-maven-${MAVEN_VER}-bin.tar.gz -C /opt && \
    rm apache-maven-${MAVEN_VER}-bin.tar.gz
ENV PATH=$PATH:/opt/apache-maven-${MAVEN_VER}/bin
