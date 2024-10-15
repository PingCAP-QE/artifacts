# base image dockerfile: cd/builders/tiflash/Dockerfile
ARG BASE_IMG
FROM $BASE_IMG

# create user jenkins and add it to sudoers.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y sudo
RUN groupadd -g 1000 jenkins && \
    useradd -u 1000 -g 1000 -m -s /bin/bash jenkins && \
    echo "jenkins:password" | chpasswd && \
    echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

    