# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone --recurse-submodules https://github.com/pingcap/tiflow.git tiflow
#   - docker build -t dm -f Dockerfile ./tiflow

#build stage
FROM rockylinux:9 as builder

ENV GOLANG_VERSION 1.19.5
ENV ARCH amd64
ENV GOLANG_DOWNLOAD_URL https://dl.google.com/go/go$GOLANG_VERSION.linux-$ARCH.tar.gz
ENV GOPATH /go
ENV GOROOT /usr/local/go
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH
RUN yum update -y && yum groupinstall 'Development Tools' -y \
    && curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash && \
    source ~/.bashrc && \
    nvm install 16 && \
    npm install -g yarn
COPY . /tiflow
ARG GOPROXY
RUN cd /tiflow && source ~/.bashrc && GOPROXY=${GOPROXY} make dm-master-with-webui dm-worker dmctl dm-syncer

RUN /tiflow/bin/dm-master -V
RUN /tiflow/bin/dm-worker -V
RUN /tiflow/bin/dm-syncer -V
RUN /tiflow/bin/dmctl -V

#final stage
FROM rockylinux:9
# pingcap-base
COPY --from=busybox:1.36.1 /bin/busybox /bin/busybox
# tools-base
RUN dnf install -y bind-utils wget nc && dnf clean all

COPY --from=builder /tiflow/bin/dm-master /dm-master
COPY --from=builder /tiflow/bin/dm-worker /dm-worker
COPY --from=builder /tiflow/bin/dm-syncer /dm-syncer
COPY --from=builder /tiflow/bin/dmctl     /dmctl

EXPOSE 8291 8261 8262