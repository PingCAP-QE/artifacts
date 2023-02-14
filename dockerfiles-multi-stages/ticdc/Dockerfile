# build requires:
#   - docker >= v20.10
#
# build steps:
#   - git clone https://github.com/pingcap/tiflow.git tiflow
#   - docker build -t ticdc -f Dockerfile ./tiflow

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
COPY . /tiflow
ARG GOPROXY
RUN cd /tiflow && GOPROXY=${GOPROXY} make cdc
RUN /tiflow/bin/cdc version

#final stage
FROM rockylinux:9
# pingcap-base
COPY --from=busybox:1.34.1 /bin/busybox /bin/busybox
# tools-base
RUN dnf install -y bind-utils wget nc && dnf clean all

COPY --from=builder /tiflow/bin/cdc /cdc
EXPOSE 8300

CMD ["/cdc"]
