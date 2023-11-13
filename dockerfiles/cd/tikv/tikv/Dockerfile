# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/tikv/tikv.git tikv
#   - docker build -t tikv -f Dockerfile ./tikv

########### stage: Builder
FROM centos:7.9.2009 as builder
# install packages.
RUN yum update --nogpgcheck -y && \
    yum install --nogpgcheck -y epel-release centos-release-scl deltarpm && \
    yum update --nogpgcheck -y && \
    yum groupinstall --nogpgcheck -y "Development Tools" && \
    yum install -y git make cmake gawk llvm protobuf-compiler libstdc++-static python3 && \
    yum clean all && \
    ln -fs /usr/bin/python3 /usr/bin/python

# Set cmake3 as default cmake
# renovate: datasource=github-tags depName=Kitware/CMake
ARG CMAKE_VERSION=3.22.1
RUN filename="cmake-${CMAKE_VERSION}-linux-$(arch).sh"; \
    curl --proto '=https' --tlsv1.2 -sSf https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/${filename} | \
    sh -s - --prefix=/usr/local --skip-license --exclude-subdir

# install rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain none
ENV PATH /root/.cargo/bin/:$PATH

########### stage: Buiding
FROM builder as building
COPY . /tikv
RUN --mount=type=cache,target=/tikv/target \
    ROCKSDB_SYS_STATIC=1 \
    make dist_release -C /tikv
RUN /tikv/bin/tikv-server --version

########### stage: Final image
FROM ghcr.io/pingcap-qe/bases/tikv-base:v1.7.1

ENV MALLOC_CONF="prof:true,prof_active:false"
COPY --from=building /tikv/bin/tikv-server  /tikv-server
COPY --from=building /tikv/bin/tikv-ctl     /tikv-ctl

EXPOSE 20160
ENTRYPOINT ["/tikv-server"]
