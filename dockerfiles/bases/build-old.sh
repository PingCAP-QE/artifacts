#!/usr/bin/env bash

set -euo pipefail

build() {
    dockerfile="${1:-Dockerfile}"

    case "${PLATFORMS}" in
    linux/amd64)
        echo "building for linux/amd64 platform..."
        docker build --tag="$IMAGE" --platform="$PLATFORMS" --target amd64 . -f "$dockerfile"
        if $PUSH_IMAGE; then
            docker push "$IMAGE"
        fi
        ;;
    linux/arm64)
        echo "building for linux/arm64 platform..."
        docker build --tag="$IMAGE" --platform="$PLATFORMS" --target arm64 . -f "$dockerfile"
        if $PUSH_IMAGE; then
            docker push "$IMAGE"
        fi
        ;;
    linux/arm64,linux/amd64 | linux/amd64,linux/arm64)
        echo "building for linux/arm64 and linux/amd64 platforms..."
        docker build --tag="${IMAGE}_linux_amd64" --platform=linux/amd64 --target amd64 . -f "$dockerfile"
        docker build --tag="${IMAGE}_linux_arm64" --platform=linux/arm64 --target arm64 . -f "$dockerfile"
        if $PUSH_IMAGE; then
            docker push "${IMAGE}_linux_amd64"
            docker push "${IMAGE}_linux_arm64"

            # compose manifest for multi-arch image.
            pushed_repo="${IMAGE%:*}"
            tag="${IMAGE#*:}"
            yq -n ".image = \"$pushed_repo\"" >manifest.yaml
            yq -i ".tags = [\"$tag\"]" manifest.yaml

            # linux/amd64
            manifest-tool inspect --raw "${IMAGE}_linux_amd64" >manifest_linux_amd64.json
            yq -i '.manifests += [{}]' manifest.yaml
            digest=$(jq -r '.digest' manifest_linux_amd64.json)
            yq -i ".manifests[-1].image = \"${pushed_repo}@${digest}\"" manifest.yaml
            yq -i '.manifests[-1].platform.os = "linux"' manifest.yaml
            yq -i '.manifests[-1].platform.architecture = "amd64"' manifest.yaml
            # linux/arm64
            manifest-tool inspect --raw "${IMAGE}_linux_arm64" >manifest_linux_arm64.json
            yq -i '.manifests += [{}]' manifest.yaml
            digest=$(jq -r '.digest' manifest_linux_arm64.json)
            yq -i ".manifests[-1].image = \"${pushed_repo}@${digest}\"" manifest.yaml
            yq -i '.manifests[-1].platform.os = "linux"' manifest.yaml
            yq -i '.manifests[-1].platform.architecture = "arm64"' manifest.yaml

            # push multi-arch image
            manifest-tool push from-spec manifest.yaml
        fi
        ;;
    *)
        echo "default (none of above)"
        ;;
    esac
}

echo "image: $IMAGE"
echo "platforms: $PLATFORMS"
context_dir="${1:-.}"
dockerfile="${2:-Dockerfile}"
cd "$context_dir"
build "$dockerfile"
