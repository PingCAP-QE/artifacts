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

    # filter by os and arch and release version.
    yq ".components[\"${component}\"].routers | map(select(
            .if
            and ([\"$os\"] - .os | length == 0)
            and ([\"$arch\"] - .arch | length == 0)
            and ([\"$profile\"] - .profile | length == 0)
        ))" release-packages.yaml >release-package-routes.yaml

    # fail when array length greater than 1.
    if yq -e 'length > 1' release-package-routes.yaml >/dev/null 2>&1; then
        echo "Error: wrong package config that make me matched more than 1 routes!"
        exit 1
    fi

    if yq -e 'length == 0' release-package-routes.yaml >/dev/null 2>&1; then
        echo "No package routes matched for the target($target_info)."
        exit 0
    fi

    # get the builder image.
    yq -e '.[0].builder' release-package-routes.yaml | tee $out_file
}

main "$@"
