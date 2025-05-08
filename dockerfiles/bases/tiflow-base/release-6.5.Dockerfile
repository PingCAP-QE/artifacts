############## linux/amd64 ##################
FROM pingcap/alpine-glibc:alpine-3.14.6 AS amd64
RUN apk add --no-cache tzdata bash curl socat

############## linux/arm64 ##################
FROM alpine:3.12 AS arm64
RUN apk add --no-cache tzdata bash curl socat
