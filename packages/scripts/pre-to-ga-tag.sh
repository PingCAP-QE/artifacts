#! /usr/bin/env bash

# Only just need to create a GA image/artifact tag.
function add_ga_tag_on_from_pre() {
    local rc_ver=$1
    local ga_ver=$2

    RELEASE_SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
    PROJECT_ROOT_DIR=$(realpath "${RELEASE_SCRIPTS_DIR}/../..")

    # image
    for repo in $(grep "^\s*repo:" ${PROJECT_ROOT_DIR}/packages/packages.yaml.tmpl | awk '{print $2}' | sort -u); do
        oras repo tags $repo:$rc_ver && oras tag $repo:$rc_ver $repo:$ga_ver
    done

    # package
    for repo in $(grep "^\s*package_repo:" ${PROJECT_ROOT_DIR}/packages/packages.yaml.tmpl | awk '{print $2}' | sort -u); do
        for platform in linux_amd64 linux_arm64 darwin_amd64 darwin_arm64; do
            oras repo tags $repo:${rc_ver}_${platform} && {
                oras tag $repo:${rc_ver}_${platform} $repo:${ga_ver}_${platform}
            }
        done
    done
}
