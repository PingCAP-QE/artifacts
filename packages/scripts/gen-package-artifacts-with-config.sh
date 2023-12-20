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
    local git_ref=$6
    local git_sha=$7
    local template_file="${8:-${PROJECT_ROOT_DIR}/packages/packages.yaml.tmpl}"
    local out_file="${9:-${RELEASE_SCRIPTS_DIR}/build-package-artifacts.sh}"
    local target_info="component: $component, os: $os, arch: $arch, version: $version, profile: $profile"

    # prepare template file's context.
    : >release-context.yaml
    yq -i ".Release.os = \"$os\"" release-context.yaml
    yq -i ".Release.arch = \"$arch\"" release-context.yaml
    yq -i ".Release.version = \"$version\"" release-context.yaml
    yq -i ".Release.profile = \"$profile\"" release-context.yaml
    yq -i ".Git.ref = \"$git_ref\"" release-context.yaml
    yq -i ".Git.sha = \"$git_sha\"" release-context.yaml

    gomplate --context .=release-context.yaml -f "$template_file" --out release-packages.yaml
    yq ".components[\"${component}\"]" release-packages.yaml >release-package-config.yaml

    # filter by os and arch and release version.
    yq -i ".routers |= map(select(
            .if
            and ([\"$os\"] - .os | length == 0)
            and ([\"$arch\"] - .arch | length == 0)
            and ([\"$profile\"] - .profile | length == 0)
        ))" release-package-config.yaml
    yq -i '.routers[].artifactory = .artifactory' release-package-config.yaml

    # fail when array length greater than 1.
    if yq -e '.routers | length > 1' release-package-config.yaml >/dev/null 2>&1; then
        echo "Error: wrong package config that make me matched more than 1 routes!"
        exit 1
    fi

    if yq -e '.routers | length == 0' release-package-config.yaml >/dev/null 2>&1; then
        echo "No package routes matched for the target($target_info)."
        exit 0
    fi

    # generate package build script
    yq ".routers[0]" release-package-config.yaml >release-package.yaml
    yq -i ".os = \"$os\"" release-package.yaml
    yq -i ".arch = \"$arch\"" release-package.yaml
    yq -i ".profile = \"$profile\"" release-package.yaml
    yq -i ".steps = .steps[.profile]" release-package.yaml
    yq -i ".steps = (.steps | map(select(.os == null or .os == \"$os\")))" release-package.yaml
    yq -i ".steps = (.steps | map(select(.arch == null or .arch == \"$arch\")))" release-package.yaml
    yq -i '.artifacts = (.artifacts | map(select(.if == null or .if)))' release-package.yaml
    yq -i '.artifacts = (.artifacts | map(select(.type == "file" or .type == null)))' release-package.yaml

    if yq -e '.artifacts | length == 0' release-package.yaml >/dev/null 2>&1; then
        echo "No artifacts should be built for target($target_info)."
        exit 0
    fi

    gomplate --context .=release-package.yaml -f $RELEASE_SCRIPTS_DIR/build-package-artifacts.sh.tmpl --chmod "755" --out $out_file
    echo "Generated shell script: $out_file"
}

main "$@"
