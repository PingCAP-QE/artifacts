FROM rockylinux:8 as builder
RUN yum groupinstall -y "Development Tools"
RUN yum install -y git make cmake gawk llvm protobuf-compiler
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s - -y --default-toolchain none
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

FROM rockylinux:9.1
COPY --from=busybox:1.36.0 /bin/busybox /bin/busybox

RUN dnf install -y tzdata
ENV TZ=/etc/localtime
ENV TZDIR=/usr/share/zoneinfo

COPY --from=builder /tikv/bin/tikv-server /tikv-server
COPY --from=builder /tikv/bin/tikv-ctl /tikv-ctl
ENV MALLOC_CONF="prof:true,prof_active:false"
EXPOSE 20160
ENTRYPOINT ["/tikv-server"]