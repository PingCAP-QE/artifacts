# Ref: https://github.com/pingcap/tidb/raw/master/Dockerfile
#
# build requires:
#   - docker >= vX.Y.Z
#   - git >= vX.Y.Z
#
# build steps:
#   - git clone https://github.com/tikv/pd.git pd
#   - docker build -t tidb -f Dockerfile ./pd

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
COPY . /pd
ARG GOPROXY
RUN cd /pd && GOPROXY=${GOPROXY} make build tools
RUN /pd/bin/pd-server -V
RUN /pd/bin/pd-ctl -V

#final stage
FROM rockylinux:9
# pingcap-base
COPY --from=busybox:1.34.1 /bin/busybox /bin/busybox
# pd-base
RUN dnf install bind-utils wget -y && dnf clean all

COPY --from=builder /pd/bin/pd-server /pd-server
COPY --from=builder /pd/bin/pd-ctl /pd-ctl

EXPOSE 2379 2380
ENTRYPOINT ["/pd-server"]
