# Ref: https://github.com/pingcap/tidb/raw/master/Dockerfile
#
# build requires:
#   - docker >= vX.Y.Z
#   - git >= vX.Y.Z

#build stage
FROM golang:alpine AS builder
RUN apk add --no-cache git
WORKDIR /go/src/app
COPY . .
RUN go get -d -v ./...
RUN go build -o /go/bin/app -v ./...

#final stage
FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /go/bin/app /app
ENTRYPOINT /app
LABEL Name=artifacts Version=0.0.1
EXPOSE 3000
