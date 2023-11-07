# Base image
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.21.4
FROM golang:${GOLANG_VERSION}

LABEL go-version "${GOLANG_VERSION}"
LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "CI Base image for building/testing"

# install packages.
RUN apt-get update && \
    apt-get install -y build-essential wget unzip psmisc lsof jq mariadb-client && \
    apt-get clean

# rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain nightly
ENV PATH /root/.cargo/bin:$PATH

##### install tools: bazelisk, yq, oras, codecov, gradle, apache-maven
# renovate: datasource=github-tags depName=bazelbuild/bazelisk
ARG BAZELISK_VERSION=v1.18.0
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-${OS}-${ARCH}" -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

# yq tool
# renovate: datasource=github-tags depName=mikefarah/yq
ARG YQ_VERSION=v4.35.2
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_${OS}_${ARCH}" -o /usr/local/bin/yq && chmod +x /usr/local/bin/yq

# oras tool
# renovate: datasource=github-tags depName=oras-project/oras
ARG ORAS_VERSION=v1.1.0
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -LO "https://github.com/oras-project/oras/releases/download/${ORAS_VERSION}/oras_${ORAS_VERSION#?}_${OS}_${ARCH}.tar.gz" && \
    mkdir -p oras-install/ && \
    tar -zxf oras_*_${OS}_${ARCH}.tar.gz -C oras-install/ && \
    install oras-install/oras /usr/local/bin/ && \
    rm -rf oras_*_${OS}_${ARCH}.tar.gz oras-install/

# codecov tool
# renovate: datasource=github-tags depName=codecov/uploader
ARG CODECOV_VERSION=v0.7.1
RUN folder=$([ "$(arch)" = "x86_64" ] && echo linux || echo aarch64); \
    curl -fsSL https://uploader.codecov.io/${CODECOV_VERSION}/${folder}/codecov -o /usr/local/bin/codecov && \
    chmod +x /usr/local/bin/codecov

# java tool chains -> open-jdk
ARG OPENJDK_VER=17
RUN apt-get update && apt-get install -y openjdk-${OPENJDK_VER}-jdk && apt-get clean
RUN ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); cd /usr/lib/jvm/ && ln -s java-${OPENJDK_VER}-openjdk-${ARCH} java-17-openjdk
ENV JAVA_HOME=/usr/lib/jvm/java-${OPENJDK_VER}-openjdk

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

# install nodejs toolchain
ARG NODE_VERSION=16
RUN curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs npm && \
    apt-get clean && \
    npm install -g yarn pnpm
