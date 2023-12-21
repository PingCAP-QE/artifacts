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
    local out_file="${9:-${RELEASE_SCRIPTS_DIR}/build-package-images.sh}"
    local target_info="component: $component, os: $os, arch: $arch, version: $version, profile: $profile"

    if [ "$os" != "linux" ]; then
        echo "Can not build container images for os: $os, only supports linux."
        exit 1
    fi

    # prepare template file's context.
    : >release-context.yaml
    yq -i ".Release.os = \"$os\"" release-context.yaml
    yq -i ".Release.arch = \"$arch\"" release-context.yaml
    yq -i ".Release.version = \"$version\"" release-context.yaml
    yq -i ".Release.profile = \"$profile\"" release-context.yaml
    yq -i ".Git.ref = \"$git_ref\"" release-context.yaml
    yq -i ".Git.sha = \"$git_sha\"" release-context.yaml

    gomplate --context .=release-context.yaml -f "$template_file" --out release-packages.yaml
    yq ".components[\"${component}\"]" release-packages.yaml >release-package.yaml

    # filter by os and arch and release version.
    yq -i ".routers |= map(select(
            (.if == null or .if)
            and ([\"$os\"] - .os | length == 0)
            and ([\"$arch\"] - .arch | length == 0)
            and ([\"$profile\"] - .profile | length == 0)
        ))" release-package.yaml
    yq -i '.routers[].artifactory = .artifactory' release-package.yaml

    # fail when array length greater than 1.
    if yq -e '.routers | length > 1' release-package.yaml >/dev/null 2>&1; then
        echo "Error: wrong package config that make me matched more than 1 routes!"
        exit 1
    fi

    if yq -e '.routers | length == 0' release-package.yaml >/dev/null 2>&1; then
        echo "No package routes matched for the target($target_info)."
        exit 1
    fi
    yq ".routers[0]" release-package.yaml >release-router.yaml

    # generate package build script
    yq -i ".os = \"$os\"" release-router.yaml
    yq -i ".arch = \"$arch\"" release-router.yaml
    yq -i ".profile = \"$profile\"" release-router.yaml
    yq -i ".steps = .steps[.profile]" release-router.yaml
    yq -i ".steps = (.steps | map(select(.os == null or .os == \"$os\")))" release-router.yaml
    yq -i ".steps = (.steps | map(select(.arch == null or .arch == \"$arch\")))" release-router.yaml
    yq -i '.artifacts = (.artifacts | map(select(.if == null or .if)))' release-router.yaml
    yq -i '.artifacts = (.artifacts | map(select(.type == "image")))' release-router.yaml
    yq -i ".artifacts[] |= (with(select((.context == null) and (.dockerfile | test(\"^http(s)?://\") | false)); .dockerfile = \"$PROJECT_ROOT_DIR/\" + .dockerfile))" release-router.yaml

    if yq -e '.artifacts | length == 0' release-router.yaml >/dev/null 2>&1; then
        echo "No images should be built for target($target_info)."
        exit 0
    fi

    gomplate --context .=release-router.yaml -f $RELEASE_SCRIPTS_DIR/build-package-images.sh.tmpl --chmod "755" --out $out_file
    echo "Generated shell script: $out_file"
}

main "$@"
