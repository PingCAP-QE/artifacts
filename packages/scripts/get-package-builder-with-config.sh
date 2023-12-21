#!/usr/bin/env bash
set -euo pipefail

RELEASE_SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
PROJECT_ROOT_DIR=$(realpath "${RELEASE_SCRIPTS_DIR}/../..")

function main() {
    local component=$1
    local os=$2
    local arch=$3
    local version=$4
    local profile=$5
    local template_file="${6:-${PROJECT_ROOT_DIR}/packages/packages.yaml.tmpl}"
    local out_file="${7:-build-package-builder.txt}"
    local target_info="component: $component, os: $os, arch: $arch, version: $version, profile: $profile"

    # prepare template file's context.
    : >release-context.yaml
    yq -i ".Release.os = \"$os\"" release-context.yaml
    yq -i ".Release.arch = \"$arch\"" release-context.yaml
    yq -i ".Release.version = \"$version\"" release-context.yaml
    yq -i ".Release.profile = \"$profile\"" release-context.yaml
    yq -i '.Git.ref = ""' release-context.yaml
    yq -i '.Git.sha = ""' release-context.yaml

    gomplate --context .=release-context.yaml -f "$template_file" --out release-packages.yaml
    yq ".components[\"${component}\"]" release-packages.yaml >release-package.yaml

    ###### filter builders #######
    yq -i ".builders |= map(select( .if == null or .if ))" release-package.yaml
    # fail when array length greater than 1.
    if yq -e '.builders | length > 1' release-package.yaml >/dev/null 2>&1; then
        echo "Error: wrong package config that make me matched more than 1 builders!"
        exit 1
    fi
    if yq -e '.builders | length == 0' release-package.yaml >/dev/null 2>&1; then
        echo "No package builder matched for the target($target_info)." >&2
        exit 1
    fi

    # get the builder image.
    yq -e '.builders[0].image' release-package.yaml | tee $out_file
}

main "$@"
