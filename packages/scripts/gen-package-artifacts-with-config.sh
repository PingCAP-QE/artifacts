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

    # prepare template file's context.
    : >release-context.yaml
    yq -i ".Release.os=\"$os\"" release-context.yaml
    yq -i ".Release.arch=\"$arch\"" release-context.yaml
    yq -i ".Release.version=\"$version\"" release-context.yaml
    yq -i ".Git.ref=\"$git_ref\"" release-context.yaml
    yq -i ".Git.sha=\"$git_sha\"" release-context.yaml

    echo "$template_file"
    gomplate --context .=release-context.yaml -f "$template_file" --out release-packages.yaml

    # filter by os and arch and release version.
    yq ".components[\"${component}\"].routers | map(select(
            .semver.if
            and
            ([\"$os\"] - .os | length == 0)
            and ([\"$arch\"] - .arch | length == 0)
            and ([\"$profile\"] - .profile | length == 0)
        ))" release-packages.yaml >release-package-routes.yaml

    # fail when array length greater than 1.
    if yq -e 'length > 1' release-package-routes.yaml >/dev/null 2>&1; then
        echo "Error: wrong package config that make me matched more than 1 routes!"
        exit 1
    fi

    if yq -e 'length == 0' release-package-routes.yaml >/dev/null 2>&1; then
        echo "No package routes matched for arch: $arch, version: $version ."
        exit 0
    fi

    # generate package build script
    yq ".[0]" release-package-routes.yaml >release-package.yaml
    yq -i ".os=\"$os\"" release-package.yaml
    yq -i ".arch=\"$arch\"" release-package.yaml
    yq -i ".profile=\"$profile\"" release-package.yaml
    yq -i ".steps=.steps[.profile]" release-package.yaml
    yq -i '.artifacts = (.artifacts | map(select(.type == "file" or .type == null)))' release-package.yaml

    gomplate --context .=release-package.yaml -f $RELEASE_SCRIPTS_DIR/build-package-artifacts.sh.tmpl --chmod "755" --out $out_file

    echo "Generated shell script: $out_file"
}

main "$@"
