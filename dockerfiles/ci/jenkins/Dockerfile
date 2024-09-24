# base image dockerfile: ci/base/Dockerfile
ARG BASE_IMG
FROM $BASE_IMG

RUN which bash

RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y sudo

RUN groupadd -g 1000 jenkins && \
    useradd -u 1000 -g 1000 -m -s /bin/bash jenkins && \
    echo "jenkins:password" | chpasswd && \
    echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch to the non-root user jenkins and set the working directory
USER jenkins
WORKDIR /home/jenkins
