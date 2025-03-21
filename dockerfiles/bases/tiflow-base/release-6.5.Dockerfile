############## linux/amd64 ##################
FROM pingcap/alpine-glibc:alpine-3.14.6 as amd64
RUN apk add --no-cache tzdata bash curl socat

############## linux/arm64 ##################
FROM alpine:3.21 as arm64
RUN apk add --no-cache tzdata bash curl socat
