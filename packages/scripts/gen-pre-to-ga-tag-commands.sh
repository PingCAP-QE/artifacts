#! /usr/bin/env bash
set -euo pipefail

RELEASE_SCRIPTS_DIR=$(cd "$(dirname "$0")" && pwd -P)
PROJECT_ROOT_DIR=$(cd "${RELEASE_SCRIPTS_DIR}/../.." && pwd -P)

# shellcheck source=lib/validate.sh
source "${RELEASE_SCRIPTS_DIR}/lib/validate.sh"

# Only just need to create a GA image/artifact tag.
#
# The versions are interpolated into a shell script that the promotion job runs
# with registry push credentials, so both must pass the shared validator before
# anything is written. The output file is truncated, so it is validated too.
function add_ga_tag_on_from_pre() {
    local rc_ver="${1:-}"
    local ga_ver="${2:-}"

    if [ -z "$rc_ver" ] || [ -z "$ga_ver" ]; then
        echo "usage: $0 <rc-version> <ga-version> [output-file]" >&2
        exit 2
    fi

    assert_version "$rc_ver"
    assert_version "$ga_ver"

    local outfile="${3:-${RELEASE_SCRIPTS_DIR}/pre-to-ga-tag.sh}"
    if [ -n "${3:-}" ]; then
        assert_output_file "$outfile"
    fi

    : >"$outfile"

    # image
    local repo
    for repo in $(
        grep "^\s*repo:" "${PROJECT_ROOT_DIR}"/packages/packages.yaml.tmpl | awk '{print $2}' | sort -u |
            grep -v "advanced-statefulset" | grep -v tidb-operator | grep -v tidb-tools | grep -v tiflow-operator | grep -v tiproxy | grep -v tidb-ctl | grep -v tidb-tools
    ); do
        echo "oras discover --distribution-spec v1.1-referrers-tag \"${repo}:${rc_ver}\" && oras tag \"${repo}:${rc_ver}\" \"${ga_ver}\"" | tee -a "$outfile"
    done

    # package
    local platform
    for repo in $(
        grep "^\s*package_repo:" "${PROJECT_ROOT_DIR}"/packages/packages.yaml.tmpl | awk '{print $2}' | sort -u |
            grep -v "advanced-statefulset" | grep -v tidb-operator | grep -v tidb-tools | grep -v tiflow-operator | grep -v tiproxy | grep -v tidb-ctl | grep -v tidb-tools
    ); do

        for platform in linux_amd64 linux_arm64 darwin_amd64 darwin_arm64; do
            echo "oras discover --distribution-spec v1.1-referrers-tag \"${repo}:${rc_ver}_${platform}\" && oras tag \"${repo}:${rc_ver}_${platform}\" \"${ga_ver}_${platform}\"" | tee -a "$outfile"
        done
    done
}

add_ga_tag_on_from_pre "$@"
