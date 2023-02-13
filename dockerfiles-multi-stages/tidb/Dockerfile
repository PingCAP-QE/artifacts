# Ref: https://github.com/pingcap/tidb/raw/master/Dockerfile
#
# build requires:
#   - docker >= vX.Y.Z
#   - git >= vX.Y.Z

#build stage
FROM rockylinux:9 as builder

ENV GOLANG_VERSION 1.19.3
ENV ARCH amd64
ENV GOLANG_DOWNLOAD_URL https://dl.google.com/go/go$GOLANG_VERSION.linux-$ARCH.tar.gz
ENV GOPATH /go
ENV GOROOT /usr/local/go
ENV PATH $GOPATH/bin:$GOROOT/bin:$PATH
RUN yum update -y && yum groupinstall 'Development Tools' -y \
    && curl -fsSL "$GOLANG_DOWNLOAD_URL" -o golang.tar.gz \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz
COPY . .
ARG GOPROXY
RUN export GOPROXY=${GOPROXY} && make server

#final stage
FROM rockylinux:9

COPY --from=builder /tidb/bin/tidb-server /tidb-server

WORKDIR /
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]
