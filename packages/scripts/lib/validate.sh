#!/usr/bin/env bash
# Shared input validation for the release-script generators.
#
# Every value that reaches `yq`, `gomplate` or a generated shell script through a
# positional argument must pass through one of the `assert_*` helpers below
# first. They exit with status 2 (not 1) so a caller can tell "the input is
# wrong" apart from "the command I ran failed".
#
# Sourced by gen-package-images-with-config.sh, gen-package-artifacts-with-config.sh
# and gen-package-offline-package-with-config.sh. Keep it bash-only and free of
# lint findings: it runs in the release utils image (alpine + bash).

# Hosts a git URL may point at. Override with ALLOWED_GIT_HOSTS
# (space-separated) when a build legitimately clones from somewhere else.
: "${ALLOWED_GIT_HOSTS:=github.com raw.githubusercontent.com gitlab.com}"

_validate_fail() {
    local kind="$1"
    local value="$2"
    local detail="${3:-}"
    if [ -n "$detail" ]; then
        printf 'invalid %s: %s (%s)\n' "$kind" "$value" "$detail" >&2
    else
        printf 'invalid %s: %s\n' "$kind" "$value" >&2
    fi
    exit 2
}

# component: lowercase identifier, no leading dash.
assert_component() {
    [[ "$1" =~ ^[a-z0-9][a-z0-9-]{0,62}$ ]] || _validate_fail component "$1"
}

assert_os() {
    case "$1" in
    linux | darwin) ;;
    *) _validate_fail os "$1" ;;
    esac
}

assert_arch() {
    case "$1" in
    amd64 | arm64) ;;
    *) _validate_fail arch "$1" ;;
    esac
}

# profile / edition: lowercase word, dashes allowed.
assert_profile() {
    [[ "$1" =~ ^[a-z][a-z-]{0,31}$ ]] || _validate_fail profile "$1"
}

assert_edition() {
    [[ "$1" =~ ^[a-z][a-z-]{0,31}$ ]] || _validate_fail edition "$1"
}

# version: no whitespace, quotes or shell metacharacters. Empty is allowed (a
# dev build may not resolve one), matching the previous behaviour.
assert_version() {
    local version="$1"
    [ -z "$version" ] && return 0
    [[ "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._+-]{0,63}$ ]] || _validate_fail version "$version"
}

# git ref: branch/tag/path. Rejects a leading dash (option injection), "..",
# "//" and a trailing "/". Empty is allowed for callers that build without a ref.
assert_ref() {
    local ref="$1"
    [ -z "$ref" ] && return 0
    [[ "$ref" =~ ^[0-9A-Za-z_][0-9A-Za-z._+/#-]{0,127}$ ]] || _validate_fail ref "$ref"
    case "$ref" in
    *..* | *//* | */) _validate_fail ref "$ref" ;;
    esac
}

# Optional short/full sha. Empty is allowed: the callers treat it as "unknown".
# 40 covers sha1, 64 covers sha256; the value is only ever used as a label and a
# short-tag suffix, so the length is not load-bearing.
assert_sha() {
    local sha="$1"
    [ -z "$sha" ] && return 0
    [[ "$sha" =~ ^[0-9a-f]{7,64}$ ]] || _validate_fail sha "$sha"
}

# registry/repository reference without tag or digest.
assert_registry() {
    [[ "$1" =~ ^[a-z0-9.-]+(:[0-9]+)?/[A-Za-z0-9._/-]+$ ]] ||
        _validate_fail registry "$1"
}

# Optional git URL: https only, no userinfo, no "..", host allowlisted.
assert_url() {
    local url="$1"
    local host allowed
    [ -z "$url" ] && return 0
    [[ "$url" =~ ^https://[A-Za-z0-9.-]+(:[0-9]+)?/[A-Za-z0-9._/~-]*$ ]] ||
        _validate_fail url "$url"
    case "$url" in
    *..*) _validate_fail url "$url" ;;
    esac
    host="${url#https://}"
    host="${host%%/*}"
    host="${host%%:*}"
    for allowed in $ALLOWED_GIT_HOSTS; do
        [ "$host" = "$allowed" ] && return 0
    done
    _validate_fail url "$url" "host not in ALLOWED_GIT_HOSTS ('$ALLOWED_GIT_HOSTS')"
}

# Remote sources for package artifacts (offline bundles and build inputs): https
# only, no userinfo, no "..", host allowlisted. The composer runs wget with the
# build credentials in scope and the result lands in a customer-facing bundle, so
# a plaintext or unlisted origin must fail before anything is downloaded.
: "${ALLOWED_SRC_HOSTS:=github.com objects.githubusercontent.com cdn.jsdelivr.net tiup-mirrors.pingcap.com}"
assert_src_url() {
    local url="$1"
    local host allowed
    # Kept in a variable: bash misparses a bare '&' inside an unquoted =~ pattern.
    local re='^https://[A-Za-z0-9.-]+(:[0-9]+)?/[A-Za-z0-9._~/?=&%+-]*$'
    [ -z "$url" ] && return 0
    [[ "$url" =~ $re ]] || _validate_fail src_url "$url"
    case "$url" in
    *..*) _validate_fail src_url "$url" ;;
    esac
    host="${url#https://}"
    host="${host%%/*}"
    host="${host%%:*}"
    for allowed in $ALLOWED_SRC_HOSTS; do
        [ "$host" = "$allowed" ] && return 0
    done
    _validate_fail src_url "$url" "host not in ALLOWED_SRC_HOSTS ('$ALLOWED_SRC_HOSTS')"
}

# tiup mirror argument: the literal --reset, an http(s) URL, or a mirror name.
assert_tiup_mirror() {
    local mirror="$1"
    [ "$mirror" = "--reset" ] && return 0
    [[ "$mirror" =~ ^https?://[A-Za-z0-9._:/-]+$ ]] && return 0
    [[ "$mirror" =~ ^[A-Za-z0-9._-]+$ ]] && return 0
    _validate_fail tiup_mirror "$mirror"
}

# Output file for a generated script. The generator truncates this path before
# writing, so a value that escapes through ".." or points at a non-script file
# lets the caller destroy something else. Accepted: a plain "*.sh" file name, or
# an absolute/relative path to one whose parent directory already exists.
# Refused: a leading "-" (option injection), "..", a missing parent, and
# anything that is already a symlink or not a regular file.
assert_output_file() {
    local path="$1"
    local dir=""

    [ -n "$path" ] || _validate_fail output_file "$path" "must not be empty"
    case "$path" in
    -*) _validate_fail output_file "$path" "must not start with '-'" ;;
    *..*) _validate_fail output_file "$path" "must not contain '..'" ;;
    esac
    [[ "${path##*/}" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*\.sh$ ]] ||
        _validate_fail output_file "$path" "must be a *.sh file name"

    case "$path" in
    */*)
        dir="${path%/*}"
        [ -d "$dir" ] || _validate_fail output_file "$path" "parent directory does not exist"
        if [ -e "$path" ]; then
            [ -L "$path" ] && _validate_fail output_file "$path" "must not be a symlink"
            [ -f "$path" ] || _validate_fail output_file "$path" "must be a regular file"
        fi
        ;;
    esac
}
