# Base image
FROM quay.io/rockylinux/rockylinux:8.10.20240528

LABEL org.opencontainers.image.authors "wuhui.zuo@pingcap.com"
LABEL org.opencontainers.image.description "CI Base image for building/testing"
LABEL org.opencontainers.image.source "https://github.com/PingCAP-QE/artifacts"

# setup mariadb repo
#   ref: https://mariadb.com/docs/server/connect/clients/mariadb-client/#Linux_(Repository)
RUN curl -LsSO https://r.mariadb.com/downloads/mariadb_repo_setup \
    && echo "6083ef1974d11f49d42ae668fb9d513f7dc2c6276ffa47caed488c4b47268593  mariadb_repo_setup" | sha256sum -c - \
    && chmod +x mariadb_repo_setup \
    && ./mariadb_repo_setup \
    && rm mariadb_repo_setup

# install OS packages.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf upgrade-minimal -y && \
    dnf install -y make git gcc wget unzip psmisc lsof jq MariaDB-client

# install golang toolchain
# renovate: datasource=docker depName=golang
ARG GOLANG_VERSION=1.23.2
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL https://dl.google.com/go/go${GOLANG_VERSION}.linux-${ARCH}.tar.gz | tar -C /usr/local -xz
ENV PATH /usr/local/go/bin/:$PATH
LABEL go-version="${GOLANG_VERSION}"

# install rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain nightly
ENV PATH /root/.cargo/bin:$PATH

# install nodejs toolchain
ARG NODE_VERSION=18
RUN curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && dnf install -y nsolid \
    && npm install -g yarn@1.22.22 pnpm@8.15.9

#### install java tool chains: open-jdk, gradle, apache-maven
#   -> open-jdk
ARG JAVA_VER=17
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y java-${JAVA_VER}-openjdk-devel
ENV JAVA_HOME=/usr/lib/jvm/jre-openjdk

#   -> gradle
ARG GRADLE_VER=7.4.2
RUN wget https://services.gradle.org/distributions/gradle-${GRADLE_VER}-bin.zip && \
    unzip gradle-${GRADLE_VER}-bin.zip -d /opt && \
    rm gradle-${GRADLE_VER}-bin.zip
ENV PATH=$PATH:/opt/gradle-${GRADLE_VER}/bin

#   -> apache-maven
ARG MAVEN_VER=3.8.8
RUN wget https://downloads.apache.org/maven/maven-3/${MAVEN_VER}/binaries/apache-maven-${MAVEN_VER}-bin.tar.gz && \
    tar -xf apache-maven-${MAVEN_VER}-bin.tar.gz -C /opt && \
    rm apache-maven-${MAVEN_VER}-bin.tar.gz
ENV PATH=$PATH:/opt/apache-maven-${MAVEN_VER}/bin

#### install tools: bazelisk, codecov, oras
# renovate: datasource=github-tags depName=bazelbuild/bazelisk
ARG BAZELISK_VERSION=v1.22.0
RUN OS=linux; ARCH=$([ "$(arch)" = "x86_64" ] && echo amd64 || echo arm64); \
    curl -fsSL "https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-${OS}-${ARCH}" -o /usr/local/bin/bazel && chmod +x /usr/local/bin/bazel

# codecov tool
# renovate: datasource=github-tags depName=codecov/uploader
ARG CODECOV_VERSION=v0.8.0
RUN folder=$([ "$(arch)" = "x86_64" ] && echo linux || echo aarch64); \
    curl -fsSL https://uploader.codecov.io/${CODECOV_VERSION}/${folder}/codecov -o /usr/local/bin/codecov && \
    chmod +x /usr/local/bin/codecov

# oras tool
# renovate: datasource=github-tags depName=oras-project/oras
COPY --from=bitnami/oras:1.2.0 /oras /usr/local/bin/oras
