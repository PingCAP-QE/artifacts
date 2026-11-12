#!/usr/bin/env bash
# Negative tests for the release-script input validation (packages/scripts/lib/validate.sh).
#
# Every "rejected" case below is a value that used to be interpolated straight
# into a yq expression or into the generated shell script. They must all be
# rejected with exit status 2, before anything is written to disk.
#
# Runs offline. The end-to-end cases need `yq` and `gomplate` and are skipped
# when either is missing.
set -euo pipefail

RELEASE_SCRIPTS_DIR=$(cd "$(dirname "$0")" && pwd -P)
PROJECT_ROOT_DIR=$(cd "${RELEASE_SCRIPTS_DIR}/../.." && pwd -P)

# shellcheck source=lib/validate.sh
source "${RELEASE_SCRIPTS_DIR}/lib/validate.sh"

failures=0
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

assert_rejected() {
    local label="$1"
    local fn="$2"
    local value="$3"
    local status=0
    ( "$fn" "$value" ) >/dev/null 2>&1 || status=$?
    if [ "$status" -ne 2 ]; then
        printf '❌ %-30s expected exit 2, got %s (%s=%q)\n' "$label" "$status" "$fn" "$value"
        failures=$((failures + 1))
    else
        printf '✅ %-30s rejected\n' "$label"
    fi
}

assert_accepted() {
    local label="$1"
    local fn="$2"
    local value="$3"
    if ( "$fn" "$value" ) >/dev/null 2>&1; then
        printf '✅ %-30s accepted\n' "$label"
    else
        printf '❌ %-30s expected success (%s=%q)\n' "$label" "$fn" "$value"
        failures=$((failures + 1))
    fi
}

echo ">>>>>>>> validate.sh: rejected values >>>>>>>>>>>>"
assert_rejected 'component: yq escape'      assert_component 'tidb" | .x = "pwned'
assert_rejected 'component: path traversal' assert_component '../../etc/passwd'
assert_rejected 'component: shell'          assert_component 'tidb;id'
assert_rejected 'os: shell'                 assert_os        'linux;id'
assert_rejected 'os: substitution'          assert_os        'linux$(id)'
assert_rejected 'arch: substitution'        assert_arch      'amd64`id`'
assert_rejected 'version: quote'            assert_version   'v8.5.0"; id; "'
assert_rejected 'version: pipe'             assert_version   'v8.5.0 | .x = "1"'
assert_rejected 'profile: space'            assert_profile   'rel ease'
assert_rejected 'ref: traversal'            assert_ref       'refs/heads/../../etc'
assert_rejected 'ref: option'               assert_ref       '-f'
assert_rejected 'sha: not hex'              assert_sha       'notahash'
assert_rejected 'registry: shell'           assert_registry  'hub;id'
assert_rejected 'url: plain http'           assert_url       'http://github.com/pingcap/tidb'
assert_rejected 'url: foreign host'         assert_url       'https://evil.example.com/x.git'
assert_rejected 'url: userinfo'             assert_url       'https://u:p@github.com/pingcap/tidb'
assert_rejected 'tiup mirror: shell'        assert_tiup_mirror '--reset; id'
assert_rejected 'output file: traversal'    assert_output_file '../../etc/passwd'
assert_rejected 'output file: not a script' assert_output_file '/etc/passwd'
assert_rejected 'output file: option'       assert_output_file '-o'
assert_rejected 'output file: no suffix'    assert_output_file 'out'
assert_rejected 'output file: empty'        assert_output_file ''
assert_rejected 'output file: missing dir'  assert_output_file '/nonexistent-dir-xyz/out.sh'
assert_rejected 'src url: plain http'        assert_src_url    'http://fileserver.pingcap.net/download/x.tar.gz'
assert_rejected 'src url: foreign host'     assert_src_url    'https://evil.example.com/x.tar.gz'
assert_rejected 'src url: userinfo'         assert_src_url    'https://u:p@github.com/a/b.tar.gz'
assert_rejected 'src url: file scheme'      assert_src_url    'file:///etc/passwd'

echo
echo ">>>>>>>> validate.sh: accepted values >>>>>>>>>>>>"
assert_accepted 'component' assert_component 'tidb'
assert_accepted 'component: dash' assert_component 'tidb-operator'
assert_accepted 'os' assert_os 'darwin'
assert_accepted 'arch' assert_arch 'arm64'
assert_accepted 'version' assert_version 'v8.5.4-20260331-bfa749d'
assert_accepted 'profile' assert_profile 'next-gen'
assert_accepted 'edition' assert_edition 'community'
assert_accepted 'ref' assert_ref 'release-nextgen-202611'
assert_accepted 'ref: empty' assert_ref ''
assert_accepted 'version: empty' assert_version ''
assert_accepted 'sha' assert_sha 'bfa749d'
assert_accepted 'sha: sha1' assert_sha 'aabbccddeeff1234567890abcdef1234567890ab'
assert_accepted 'sha: sha256' assert_sha '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef'
assert_accepted 'sha: empty' assert_sha ''
assert_accepted 'registry' assert_registry 'us-docker.pkg.dev/pingcap-testing-account/hub'
assert_accepted 'url: empty' assert_url ''
assert_accepted 'url: github' assert_url 'https://github.com/pingcap/tidb.git'
assert_accepted 'tiup mirror: reset' assert_tiup_mirror '--reset'
assert_accepted 'tiup mirror: url' assert_tiup_mirror 'https://tiup-mirrors.pingcap.com'
assert_accepted 'output file' assert_output_file 'pre-to-ga-tag.sh'
assert_accepted 'output file: absolute' assert_output_file "${tmpdir}/pre-to-ga-tag.sh"
assert_accepted 'src url: github release' assert_src_url 'https://github.com/pingcap/mydumper/releases/download/build-0042e179/mydumper-linux-amd64.tar.gz'
assert_accepted 'src url: empty' assert_src_url ''

echo
echo ">>>>>>>> gen-pre-to-ga-tag-commands.sh: hostile input must not produce a script >>>>>>>>>>>>"
promo_out="${tmpdir}/pre-to-ga-tag.sh"

# The promotion generator is the one script under packages/scripts/ that used to
# take its version strings straight into the emitted `oras` commands. A value
# carrying shell metacharacters would become code in the promotion container.
status=0
"${RELEASE_SCRIPTS_DIR}/gen-pre-to-ga-tag-commands.sh" 'v9.0.0" ; id ; "' 'v9.0.0' "$promo_out" >/dev/null 2>&1 || status=$?
if [ "$status" -ne 2 ]; then
    printf '❌ %-30s expected exit 2 for a hostile rc version, got %s\n' 'promotion generator' "$status"
    failures=$((failures + 1))
elif [ -e "$promo_out" ]; then
    printf '❌ %-30s rejected the input but still wrote %s\n' 'promotion generator' "$promo_out"
    failures=$((failures + 1))
else
    printf '✅ %-30s rejected hostile rc version, no script written\n' 'promotion generator'
fi

status=0
"${RELEASE_SCRIPTS_DIR}/gen-pre-to-ga-tag-commands.sh" 'v9.0.0-rc.1' 'v9.0.0$(id)' "$promo_out" >/dev/null 2>&1 || status=$?
if [ "$status" -ne 2 ] || [ -e "$promo_out" ]; then
    printf '❌ %-30s expected exit 2 for a hostile ga version, got %s\n' 'promotion generator' "$status"
    failures=$((failures + 1))
else
    printf '✅ %-30s rejected hostile ga version\n' 'promotion generator'
fi

# The output path is caller-chosen and was truncated before any validation, so it
# could destroy any file the invoking user can write.
status=0
"${RELEASE_SCRIPTS_DIR}/gen-pre-to-ga-tag-commands.sh" 'v9.0.0-rc.1' 'v9.0.0' '../../tmp/evil.sh' >/dev/null 2>&1 || status=$?
if [ "$status" -ne 2 ]; then
    printf '❌ %-30s expected exit 2 for a path-traversal output file, got %s\n' 'promotion generator' "$status"
    failures=$((failures + 1))
else
    printf '✅ %-30s rejected path-traversal output file\n' 'promotion generator'
fi

echo
echo ">>>>>>>> gen-pre-to-ga-tag-commands.sh: valid input still works >>>>>>>>>>>>"
status=0
"${RELEASE_SCRIPTS_DIR}/gen-pre-to-ga-tag-commands.sh" 'v9.0.0-rc.1' 'v9.0.0' "$promo_out" >/dev/null 2>&1 || status=$?
if [ "$status" -ne 0 ] || [ ! -s "$promo_out" ]; then
    printf '❌ %-30s generation failed (exit %s)\n' 'promotion generator' "$status"
    failures=$((failures + 1))
elif ! sh -n "$promo_out" >/dev/null 2>&1; then
    printf '❌ %-30s generated script is not valid POSIX sh\n' 'promotion generator'
    failures=$((failures + 1))
elif ! grep -qE '"v9\.0\.0"$' "$promo_out"; then
    printf '❌ %-30s generated GA tag is not quoted\n' 'promotion generator'
    failures=$((failures + 1))
elif grep -qE '&& oras tag [^"]*[;$(]' "$promo_out"; then
    printf '❌ %-30s generated oras commands contain unquoted shell metacharacters\n' 'promotion generator'
    failures=$((failures + 1))
else
    printf '✅ %-30s generated, POSIX-clean and quoted\n' 'promotion generator'
fi

echo
if ! command -v yq >/dev/null 2>&1 || ! command -v gomplate >/dev/null 2>&1; then
    echo "🤷 yq or gomplate not found; skipping the end-to-end cases."
else
    echo ">>>>>>>> generators: hostile input must not produce a script >>>>>>>>>>>>"
    hostile_out="$tmpdir/hostile.sh"
    status=0
    (
        cd "$tmpdir"
        "$RELEASE_SCRIPTS_DIR/gen-package-images-with-config.sh" \
            'tidb" | .x = "pwned' linux amd64 v8.5.4 release release-8.5 bfa749d \
            "" "$hostile_out" us-docker.pkg.dev/pingcap-testing-account/hub ""
    ) >/dev/null 2>&1 || status=$?
    if [ "$status" -ne 2 ]; then
        printf '❌ %-30s expected exit 2, got %s\n' 'images generator' "$status"
        failures=$((failures + 1))
    elif [ -e "$hostile_out" ]; then
        printf '❌ %-30s rejected the input but still wrote %s\n' 'images generator' "$hostile_out"
        failures=$((failures + 1))
    else
        printf '✅ %-30s rejected, no script written\n' 'images generator'
    fi

    status=0
    (
        cd "$tmpdir"
        "$RELEASE_SCRIPTS_DIR/gen-package-offline-package-with-config.sh" \
            linux amd64 v8.5.4 community "" "$tmpdir/hostile-offline.sh" '--reset; id'
    ) >/dev/null 2>&1 || status=$?
    if [ "$status" -ne 2 ]; then
        printf '❌ %-30s expected exit 2, got %s\n' 'offline generator' "$status"
        failures=$((failures + 1))
    else
        printf '✅ %-30s rejected\n' 'offline generator'
    fi

    echo
    echo ">>>>>>>> offline generator: a plaintext source must be refused >>>>>>>>>>>>"
    # The offline bundle is shipped to customers, so a "src.url" outside the
    # accepted hosts must stop the generator before the composer downloads it.
    hostile_tmpl="$tmpdir/offline-hostile.tmpl"
    sed 's|https://github.com/pingcap/mydumper/releases/download/build-0042e179/mydumper-linux-amd64.tar.gz|http://fileserver.pingcap.net/download/mydumper-linux-amd64.tar.gz|' \
        "${PROJECT_ROOT_DIR}/packages/offline-packages.yaml.tmpl" > "$hostile_tmpl"
    status=0
    (
        cd "$tmpdir"
        "$RELEASE_SCRIPTS_DIR/gen-package-offline-package-with-config.sh" \
            linux amd64 v6.5.0 community "$hostile_tmpl" \
            "$tmpdir/hostile-offline-src.sh" http://tiup.pingcap.net:8987 \
            us-docker.pkg.dev/pingcap-testing-account/hub
    ) >/dev/null 2>&1 || status=$?
    if [ "$status" -ne 2 ]; then
        printf '❌ %-30s expected exit 2 for a plaintext src.url, got %s\n' 'offline generator' "$status"
        failures=$((failures + 1))
    elif [ -e "$tmpdir/hostile-offline-src.sh" ]; then
        printf '❌ %-30s rejected the source but still wrote a script\n' 'offline generator'
        failures=$((failures + 1))
    else
        printf '✅ %-30s rejected plaintext src.url, no script written\n' 'offline generator'
    fi

    echo
    echo ">>>>>>>> offline generator: the bundle verifies a published digest >>>>>>>>>>>>"
    offline_good="$tmpdir/offline-good.sh"
    status=0
    (
        cd "$tmpdir"
        "$RELEASE_SCRIPTS_DIR/gen-package-offline-package-with-config.sh" \
            linux amd64 v6.5.0 community \
            "${PROJECT_ROOT_DIR}/packages/offline-packages.yaml.tmpl" "$offline_good" \
            http://tiup.pingcap.net:8987 us-docker.pkg.dev/pingcap-testing-account/hub
    ) >/dev/null 2>&1 || status=$?
    if [ "$status" -ne 0 ] || [ ! -s "$offline_good" ]; then
        printf '❌ %-30s generation failed (exit %s)\n' 'offline generator' "$status"
        failures=$((failures + 1))
    elif ! grep -q 'sha256sum -c -' "$offline_good"; then
        printf '❌ %-30s generated script has no expected-digest check\n' 'offline generator'
        failures=$((failures + 1))
    elif ! grep -q 'refusing to fetch' "$offline_good"; then
        printf '❌ %-30s generated script has no plaintext-source guard\n' 'offline generator'
        failures=$((failures + 1))
    else
        printf '✅ %-30s generated with the https guard and the digest check\n' 'offline generator'
    fi

    echo
    echo ">>>>>>>> generators: valid input still works >>>>>>>>>>>>"
    good_out="$tmpdir/good.sh"
    status=0
    (
        cd "$tmpdir"
        "$RELEASE_SCRIPTS_DIR/gen-package-images-with-config.sh" \
            tidb linux amd64 v8.5.4 release release-8.5 bfa749d \
            "" "$good_out" us-docker.pkg.dev/pingcap-testing-account/hub ""
    ) >/dev/null 2>&1 || status=$?
    if [ "$status" -ne 0 ] || [ ! -s "$good_out" ]; then
        printf '❌ %-30s generation failed (exit %s)\n' 'images generator' "$status"
        failures=$((failures + 1))
    elif command -v shellcheck >/dev/null 2>&1 && ! shellcheck -S error "$good_out" >/dev/null 2>&1; then
        printf '❌ %-30s generated script fails shellcheck\n' 'images generator'
        failures=$((failures + 1))
    else
        printf '✅ %-30s generated and shellcheck-clean\n' 'images generator'
    fi
fi

echo
if [ "$failures" -ne 0 ]; then
    echo "❌ ${failures} validation case(s) failed"
    exit 1
fi
echo "✅ all validation cases passed"
