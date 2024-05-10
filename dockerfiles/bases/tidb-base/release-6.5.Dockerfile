# linux/amd64: https://github.com/PingCAP-QE/ci-dockerfile/blob/master/jenkins/amd64/alpine-3.14.6
# TODO: compose a multi-arch image.
FROM pingcap/alpine-glibc:alpine-3.14.6 AS amd64
RUN apk add --no-cache curl

# linux/arm64:
# base: https://github.com/PingCAP-QE/artifacts/blob/main/dockerfiles/old-bases/arm64/centos-stream.Dockerfile
FROM pingcap/centos-stream:8 AS arm64
RUN set -e && \
    dnf install bind-utils curl nmap-ncat -y && \
    dnf clean all
