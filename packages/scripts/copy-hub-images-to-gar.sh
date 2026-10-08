#!/usr/bin/env bash
set -euo pipefail

readonly DELIVERY_YAML="${DELIVERY_YAML:-packages/delivery.yaml}"

readonly SRC_REGISTRY="hub.pingcap.net"
readonly DST_REGISTRY="us-docker.pkg.dev/pingcap-testing-account/hub"

readonly SEMVER_PATTERN='^v[0-9]+\.[0-9]+\.[0-9]+$'
readonly ENTERPRISE_PATTERN='^v[0-9]+\.[0-9]+\.[0-9]+-enterprise$'
readonly BETA_PATTERN='^v[0-9]+\.[0-9]+\.[0-9]+-beta\.[0-9]+$'
readonly BETA_ENTERPRISE_PATTERN='^v[0-9]+\.[0-9]+\.[0-9]+-beta\.[0-9]+-enterprise$'

DRY_RUN="${DRY_RUN:-false}"

function extract_hub_image_paths() {
    yq '.image_copy_rules | keys | .[]' "$DELIVERY_YAML" |
        grep "^${DST_REGISTRY}/" || true
}

function get_remote_tags() {
    local repo="$1"
    crane ls "$repo" 2>/dev/null || true
}

function main() {
    local image_paths
    image_paths=$(extract_hub_image_paths)

    if [ -z "$image_paths" ]; then
        echo "No hub image paths found in delivery.yaml matching '${DST_REGISTRY}/'"
        exit 0
    fi

    local total=0
    local copied=0
    local skipped=0
    local failed=0

    for dst_image in $image_paths; do
        local src_image="${dst_image/#${DST_REGISTRY}/${SRC_REGISTRY}}"

        echo "=== ${src_image} -> ${dst_image} ==="

        local src_tags
        src_tags=$(get_remote_tags "$src_image")
        if [ -z "$src_tags" ]; then
            echo "  [WARN] no tags found at ${src_image}, skipping"
            continue
        fi

        for tag in $src_tags; do
            if [[ "$tag" =~ $SEMVER_PATTERN ]] || [[ "$tag" =~ $ENTERPRISE_PATTERN ]] || [[ "$tag" =~ $BETA_PATTERN ]] || [[ "$tag" =~ $BETA_ENTERPRISE_PATTERN ]]; then
                total=$((total + 1))

                if [ "$DRY_RUN" = "true" ]; then
                    echo "  [COPY] ${tag} (dry-run)"
                    copied=$((copied + 1))
                else
                    echo "  [COPY] ${tag}"
                    if crane copy --no-clobber "${src_image}:${tag}" "${dst_image}:${tag}"; then
                        echo "  [OK  ] ${tag}"
                        copied=$((copied + 1))
                    else
                        echo "  [FAIL] ${tag}"
                        failed=$((failed + 1))
                    fi
                fi
            fi
        done
    done

    echo ""
    echo "=== Summary ==="
    echo "  Total candidates: ${total}"
    echo "  Copied: ${copied}"
    echo "  Failed: ${failed}"
}

main "$@"
