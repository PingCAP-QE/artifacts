IMG ?= none
VERSION ?= $(shell ls $(IMG) |sed 's/\.Dockerfile//1' | sort -rV|head -n 1)
MINOR_VERSION ?= $(shell echo $(VERSION) |sed -E 's/([[:digit:]]+)\.([[:digit:]]+).([[:digit:]]+)/\1.\2/1' )
MAJOR_VERSION ?= $(shell echo $(VERSION) |sed -E 's/([[:digit:]]+)\.([[:digit:]]+).([[:digit:]]+)/\1/1' )
DOCKERFILE ?= $(VERSION).Dockerfile

default:
	docker buildx build $(IMG) -f $(IMG)/$(DOCKERFILE) -t hub.pingcap.net/bases/$(IMG):$(VERSION) -t hub.pingcap.net/bases/$(IMG):$(MINOR_VERSION) -t hub.pingcap.net/bases/$(IMG):$(MAJOR_VERSION)  --push --platform=linux/amd64,linux/arm64
	

