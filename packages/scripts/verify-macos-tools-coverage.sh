#!/usr/bin/env bash
# Verify the macOS native-build toolchain declarations (`macos.tools`).
#
# `macos.tools` is declared on `builders[].macos.tools` (per builder image entry)
# and read only by the macOS agent (`mac-builder-operator`). Which build targets
# are eligible for macOS is decided by the `routers` (`os` list). Because the
# router -> builder mapping is a *projection over the `os` dimension* (builders
# have no `os`), this is a sampled matrix regression rather than a 1:1 scan:
#
#   for each sampled darwin target (component, version, profile):
#     1. resolve the matching builder with the same resolver used by CI/agent;
#     2. if a `darwin` router matches the target, assert the resolved builder
#        declares a non-empty `macos.tools`;
#     3. when the builder declares `go` and the image tag carries `go1.x`, assert
#        they agree (major.minor) — `go` mirrors the builder image tag.
#
# Only maintained lines are sampled (TiDB >= v7.1, plus trunk/dev lines).
set -euo pipefail

readonly RESOLVER="./packages/scripts/get-package-builder-with-config.sh"
readonly RENDERED_ALL="release-packages.yaml"
readonly RENDERED_COMPONENT="release-package.yaml"

# component, version, profile
read -r -d '' SAMPLES <<'EOF' || true
monitoring v9.0.0 release
monitoring v7.5.0 release
ng-monitoring v9.0.0 release
ng-monitoring v7.5.0 release
pd v9.0.0 release
pd v7.5.0 release
tidb v9.0.0 release
tidb v7.5.0 release
tidb-binlog v7.5.0 release
tidb-ctl v9.0.0 release
tidb-tools v8.5.5 release
tidb-dashboard v9.0.0 release
tidb-dashboard v7.5.0 release
ticdc v9.0.0 release
ticdc v8.5.4 release
tiproxy v1.4.0 release
tiproxy v0.1.3 release
tiflow v9.0.0 release
tiflow v7.5.0 release
tici v0.2.0 release
tikv v8.5.5 release
tikv v7.5.0 release
tiflash v8.5.5 release
tiflash v7.5.0 release
tidb v8.5.5 enterprise
pd v8.5.5 enterprise
tikv v8.5.5 enterprise
tiflash v8.5.5 enterprise
tidb v9.0.0 nextgen
pd v9.0.0 nextgen
tikv v9.0.0 nextgen
tiflash v9.0.0 nextgen
ticdc v9.0.0 nextgen
EOF

function die() {
    echo "❌ $*" >&2
    exit 1
}

# has_darwin_router <component> <profile>: true when some router matches this
# target on darwin (rendered `if` true or absent, `os` contains darwin, and the
# router's `profile` list — if present — contains the target profile).
function has_darwin_router() {
    local component=$1 profile=$2
    yq -o=json ".components[\"${component}\"].routers // []" "${RENDERED_ALL}" |
        jq -e --arg profile "${profile}" '
            [ .[]
              | select( ((.["if"] == true) or (.["if"] == null))
                        and ((.os // []) | index("darwin"))
                        and ((.profile // [$profile]) | index($profile)) )
            ] | length > 0
        ' >/dev/null
}

# assert_go_matches_image <declared go> <image>
function assert_go_matches_image() {
    local declared_go=$1 image=$2
    local image_go
    image_go=$(sed -nE 's/.*(^|[^0-9.])go([0-9]+\.[0-9]+)([^0-9.].*)?$/\2/p' <<<"${image}")
    if [[ -z ${image_go} ]]; then
        return 0 # image tag carries no go version; nothing to cross-check.
    fi
    if [[ ${declared_go} != "${image_go}"* ]]; then
        die "declared go '${declared_go}' does not match image tag go '${image_go}' (${image})"
    fi
}

function verify_sample() {
    local component=$1 version=$2 profile=$3
    local label="${component} darwin/amd64 ${version} ${profile}"

    if ! "${RESOLVER}" "${component}" darwin amd64 "${version}" "${profile}" >/dev/null 2>&1; then
        die "resolver failed for ${label}"
    fi

    if ! has_darwin_router "${component}" "${profile}"; then
        echo "  - skip (no darwin router): ${label}"
        return 0
    fi

    local tools image declared_go tool_count
    tools=$(yq -o=json '.builders[0].macos.tools // {}' "${RENDERED_COMPONENT}")
    image=$(yq -r '.builders[0].image' "${RENDERED_COMPONENT}")
    tool_count=$(jq 'length' <<<"${tools}")
    if [[ ${tool_count} -eq 0 ]]; then
        die "missing macos.tools for ${label} (image: ${image})"
    fi

    declared_go=$(jq -r '.["go"] // empty' <<<"${tools}")
    if [[ -n ${declared_go} ]]; then
        assert_go_matches_image "${declared_go}" "${image}"
    fi

    echo "  - ok: ${label} -> $(jq -c . <<<"${tools}")"
}

function main() {
    echo ">>>>>>>> verify macos.tools coverage (sampled darwin matrix) >>>>>>>>"
    local component version profile
    while read -r component version profile; do
        [[ -z ${component} ]] && continue
        verify_sample "${component}" "${version}" "${profile}"
    done <<<"${SAMPLES}"
    echo "<<<<<<<< verify macos.tools coverage <<<<<<<<"
}

main "$@"
