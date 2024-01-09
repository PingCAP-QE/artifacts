# linux/amd64: https://github.com/PingCAP-QE/ci-dockerfile/blob/master/jenkins/amd64/alpine-3.14.6
# TODO: compose a multi-arch image.

# linux/arm64:
# base: https://github.com/PingCAP-QE/artifacts/blob/main/dockerfiles/old-bases/arm64/centos-stream.Dockerfile
FROM pingcap/centos-stream:8
RUN set -e && \
    dnf install bind-utils curl nmap-ncat -y && \
    dnf clean all
