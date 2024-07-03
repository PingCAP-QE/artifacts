FROM pingcap/alpine-glibc:alpine-3.14.6
RUN apk add --no-cache curl

COPY tidb-server /tidb-server
EXPOSE 4000
ENTRYPOINT ["/tidb-server"]