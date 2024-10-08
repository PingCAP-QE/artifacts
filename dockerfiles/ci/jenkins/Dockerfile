# base image dockerfile: ci/base/Dockerfile
ARG BASE_IMG
FROM $BASE_IMG

# create user jenkins and add it to sudoers.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y sudo
RUN groupadd -g 1000 jenkins && \
    useradd -u 1000 -g 1000 -m -s /bin/bash jenkins && \
    echo "jenkins:password" | chpasswd && \
    echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Switch to the non-root user jenkins and set the working directory
USER jenkins
WORKDIR /home/jenkins

# TODO: we should set it in CI script or pipeline to avoid frequently update the image.
ENV USE_BAZEL_VERSION=6.5.0

# Other environment variables:
# - `BAZELISK_BASE_URL` should be set in CI script or pipeline for different regions.
