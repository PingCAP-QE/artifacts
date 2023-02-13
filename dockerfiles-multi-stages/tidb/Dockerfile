# Ref: https://github.com/pingcap/tidb/raw/master/Dockerfile
#
# build requires:
#   - docker >= vX.Y.Z
#   - git >= vX.Y.Z
#
# build steps:
#   - git clone https://github.com/pingcap/tidb.git tidb 
#   - rm tidb/.dockerignore # make step depended on git metadata.
#   - docker build -t tidb -f Dockerfile ./tidb

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
COPY . /tidb
ARG GOPROXY
RUN cd /tidb && GOPROXY=${GOPROXY} make server
RUN /tidb/bin/tidb-server -V

#final stage
FROM rockylinux:9
# pingcap-base
COPY --from=busybox:1.34.1 /bin/busybox /bin/busybox
# tidb-base
RUN dnf install -y curl && dnf clean all

COPY --from=builder /tidb/bin/tidb-server /tidb-server

WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
