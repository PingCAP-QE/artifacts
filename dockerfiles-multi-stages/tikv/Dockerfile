FROM rockylinux:8 as builder
RUN yum groupinstall -y "Development Tools"
RUN yum install -y git make cmake gawk llvm unzip
RUN curl -OL https://github.com/google/protobuf/releases/download/v3.3.0/protoc-3.3.0-linux-x86_64.zip \
	&& unzip -o protoc-3.3.0-linux-x86_64.zip -d /usr/local bin/protoc \
	&& rm -f protoc-3.3.0-linux-x86_64.zip
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y
ENV PATH /root/.cargo/bin/:$PATH
WORKDIR /tikv
ARG GIT_FALLBACK="v6.7.0-alpha"
ARG GIT_HASH=${GIT_FALLBACK}
ARG GIT_TAG=${GIT_FALLBACK}
ARG GIT_BRANCH=${GIT_FALLBACK}
ENV TIKV_BUILD_GIT_HASH=${GIT_HASH}
ENV TIKV_BUILD_GIT_TAG=${GIT_TAG}
ENV TIKV_BUILD_GIT_BRANCH=${GIT_BRANCH}
ADD . .
RUN ROCKSDB_SYS_STATIC=1 make build_dist_release
WORKDIR /tikv/bin



FROM hub.pingcap.net/bases/tikv-base:v1
COPY --from=builder tikv-server /tikv-server
COPY --from=builder tikv-ctl /tikv-ctl
ENV MALLOC_CONF="prof:true,prof_active:false"
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]