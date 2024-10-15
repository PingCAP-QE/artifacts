# base image dockerfile: ci/jenkins/Dockerfile
ARG BASE_IMG
FROM $BASE_IMG

# create user jenkins and add it to sudoers.
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y sudo
RUN groupadd -g 1000 jenkins && \
    useradd -u 1000 -g 1000 -m -s /bin/bash jenkins && \
    echo "jenkins:password" | chpasswd && \
    echo "jenkins ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# install python2.7
RUN --mount=type=cache,target=/var/cache/dnf \
    dnf install -y python27
RUN ln -s /usr/bin/python2 /usr/bin/python && \
    ln -s /usr/bin/pip2 /usr/bin/pip


# Switch to the non-root user jenkins and set the working directory
USER jenkins
WORKDIR /home/jenkins

# install rustup and set stable toolchain as default
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain nightly-2023-12-28 && \
    source $HOME/.cargo/env && \
    rustup default nightly-2023-12-28

# install components
RUN rustup component add rustfmt clippy rust-src llvm-tools

# Install specific versions of cargo-nextest and cargo-sort
RUN cargo install cargo-nextest --version 0.9.72 && \
    cargo install cargo-sort --version 1.0.9

ENV CARGO_INCREMENTAL=0
