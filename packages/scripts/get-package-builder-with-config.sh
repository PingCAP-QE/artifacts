#!/usr/bin/env bash
set -euo pipefail

RELEASE_SCRIPTS_DIR=$(cd "$(dirname "$0")" && pwd -P)
PROJECT_ROOT_DIR=$(cd "${RELEASE_SCRIPTS_DIR}/../.." && pwd -P)

# shellcheck source=lib/validate.sh
source "${RELEASE_SCRIPTS_DIR}/lib/validate.sh"

function normalize_profile_for_match() {
    local profile="${1:-}"
    case "$profile" in
        nextgen|next-gen)
            echo "nextgen"
            ;;
        *)
            echo "$profile"
            ;;
    esac
}

function main() {
    local component=$1
    local os=$2
    local arch=$3
    local version=$4
    local profile=$5
    local profile_match
    local template_file="${6:-${PROJECT_ROOT_DIR}/packages/packages.yaml.tmpl}"
    local out_file="${7:-build-package-builder.txt}"
    local git_url="${8:-}"
    local target_info="component: $component, os: $os, arch: $arch, version: $version, profile: $profile"

    assert_component "$component"
    assert_os "$os"
    assert_arch "$arch"
    assert_version "$version"
    assert_profile "$profile"
    assert_url "$git_url"

    profile_match="$(normalize_profile_for_match "$profile")"

    # prepare template file's context.
    : >release-context.yaml
    OS="$os" yq -i '.Release.os = strenv(OS)' release-context.yaml
    ARCH="$arch" yq -i '.Release.arch = strenv(ARCH)' release-context.yaml
    VERSION="$version" yq -i '.Release.version = strenv(VERSION)' release-context.yaml
    PROFILE="$profile_match" yq -i '.Release.profile = strenv(PROFILE)' release-context.yaml
    yq -i '.Release.registry = "localhost"' release-context.yaml
    yq -i '.Git.ref = ""' release-context.yaml
    yq -i '.Git.sha = ""' release-context.yaml
    GIT_URL_VALUE="$git_url" yq -i '.Git.url = strenv(GIT_URL_VALUE)' release-context.yaml

    gomplate --context .=release-context.yaml -f "$template_file" --out release-packages.yaml
    COMPONENT="$component" yq '.components[strenv(COMPONENT)]' release-packages.yaml >release-package.yaml

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
    yq -e '.builders[0].image' release-package.yaml | tee "$out_file"
}

main "$@"
