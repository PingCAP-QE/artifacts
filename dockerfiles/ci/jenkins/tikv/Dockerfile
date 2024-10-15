# base image dockerfile: ci/jenkins/Dockerfile
ARG BASE_IMG
FROM $BASE_IMG

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
 