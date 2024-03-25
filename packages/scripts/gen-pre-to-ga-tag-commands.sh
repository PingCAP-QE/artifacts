#! /usr/bin/env bash

# Only just need to create a GA image/artifact tag.
function add_ga_tag_on_from_pre() {
    local rc_ver=$1
    local ga_ver=$2

    RELEASE_SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
    PROJECT_ROOT_DIR=$(realpath "${RELEASE_SCRIPTS_DIR}/../..")

    local outfile="${3:-${RELEASE_SCRIPTS_DIR}/pre-to-ga-tag.sh}"

    : >"$outfile"

    # image
    for repo in $(
        grep "^\s*repo:" "${PROJECT_ROOT_DIR}"/packages/packages.yaml.tmpl | awk '{print $2}' | sort -u |
            grep -v "advanced-statefulset" | grep -v tidb-operator | grep -v tidb-tools | grep -v tiflow-operator | grep -v tiproxy | grep -v tidb-ctl | grep -v tidb-tools
    ); do
        echo "oras oras discover --distribution-spec v1.1-referrers-tag $repo:$rc_ver && oras tag $repo:$rc_ver $ga_ver" | tee -a "$outfile"
    done

    # package
    for repo in $(
        grep "^\s*package_repo:" "${PROJECT_ROOT_DIR}"/packages/packages.yaml.tmpl | awk '{print $2}' | sort -u |
            grep -v "advanced-statefulset" | grep -v tidb-operator | grep -v tidb-tools | grep -v tiflow-operator | grep -v tiproxy | grep -v tidb-ctl | grep -v tidb-tools
    ); do

        for platform in linux_amd64 linux_arm64 darwin_amd64 darwin_arm64; do
            echo "oras oras discover --distribution-spec v1.1-referrers-tag $repo:${rc_ver}_${platform} && oras tag $repo:${rc_ver}_${platform} ${ga_ver}_${platform}" | tee -a "$outfile"
        done
    done
}

add_ga_tag_on_from_pre "$@"
