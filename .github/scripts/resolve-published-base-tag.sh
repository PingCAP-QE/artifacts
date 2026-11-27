#!/usr/bin/env bash
#
# Resolve the tag of the most recently published base images.
#
# The `default` module in dockerfiles/bases/skaffold.yaml turns
# `git describe --tags --always` into a semver-compatible tag
# (`v2026.11.27-2-ge5c763a` -> `v2026.11.27-2.ge5c763a`), so the tag embeds the
# commit that produced the image. Find that tag in the registry instead of
# re-deriving it here, which also keeps the result stable when tags change
# after the image was pushed (e.g. the weekly release tag lands on that very
# commit).
#
# Usage:
#   resolve-published-base-tag.sh [--workdir <dir>]
#                                 [--repository <owner/registry-path>]
#                                 [--image <name>]
#
# Prints the resolved tag on stdout and progress/errors on stderr.

set -euo pipefail

WORKDIR="dockerfiles/bases"
REPOSITORY="pingcap-qe/bases"
# Every artifact in the module shares the same tag, so any image works as the
# registry probe.
IMAGE="pingcap-base"

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --workdir)
      WORKDIR="${2:-}"
      shift 2
      ;;
    --repository)
      REPOSITORY="${2:-}"
      shift 2
      ;;
    --image)
      IMAGE="${2:-}"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

for cmd in git jq curl; do
  if ! command -v "$cmd" > /dev/null 2>&1; then
    echo "error: ${cmd} is required" >&2
    exit 1
  fi
done

if ! git -C "$WORKDIR" rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  echo "error: ${WORKDIR} is not inside a git work tree" >&2
  exit 1
fi

commit=$(git -C "$WORKDIR" log -1 --format=%H -- .)
if [ -z "$commit" ]; then
  echo "error: no commit touches ${WORKDIR}" >&2
  exit 1
fi
echo "last commit touching ${WORKDIR}: ${commit}" >&2

token=$(curl -fsS "https://ghcr.io/token?scope=repository:${REPOSITORY}/${IMAGE}:pull" | jq -r '.token // empty')
if [ -z "$token" ]; then
  echo "error: could not get an anonymous pull token for ${REPOSITORY}/${IMAGE}" >&2
  exit 1
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "${tmp_dir}"' EXIT

# The registry returns at most 1000 tags per page, so follow the `Link` header
# until there is no next page.
list_tags() {
  local url="https://ghcr.io/v2/${REPOSITORY}/${IMAGE}/tags/list?n=1000"
  local link
  while [ -n "$url" ]; do
    curl -fsS -D "${tmp_dir}/headers" -o "${tmp_dir}/body" \
      -H "Authorization: Bearer ${token}" "$url"
    jq -r '.tags[]?' "${tmp_dir}/body"
    link=$(tr -d '\r' < "${tmp_dir}/headers" |
      sed -n 's/^[Ll]ink: <\([^>]*\)>; rel="next"$/\1/p' | tail -n 1)
    url=""
    if [ -n "$link" ]; then
      url="https://ghcr.io${link}"
    fi
  done
}

tags=$(list_tags)

# `git describe --tags --always` output converted the same way as in
# dockerfiles/bases/skaffold.yaml: `v2026.11.27-2-ge5c763a` -> `v2026.11.27-2.ge5c763a`.
# An exact tag has no `-g<sha>` suffix, so it stays as-is.
describe=$(git -C "$WORKDIR" describe --tags --always "$commit")
echo "git describe: ${describe}" >&2
current_tag=$(printf '%s' "$describe" | sed -E 's/-g([0-9a-f]+)$/.g\1/')
echo "current tag: ${current_tag}" >&2

# A commit that was already tagged when it was built keeps the bare tag.
if printf '%s\n' "$tags" | grep -Fxq "$current_tag"; then
  echo "$current_tag"
  exit 0
fi

# Otherwise the published tag embeds the abbreviated build commit, e.g.
# `v2026.11.27-2.ge5c763a`.
matches=""
while IFS= read -r candidate; do
  [ -n "$candidate" ] || continue
  embedded="${candidate##*g}"
  case "$commit" in
    "$embedded"*) matches="${matches}${candidate}"$'\n' ;;
  esac
done <<< "$(printf '%s\n' "$tags" | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+-[0-9]+\.g[0-9a-f]{7,}$' || true)"

tag=$(printf '%s' "$matches" | sort -V | tail -n 1)
if [ -n "$tag" ]; then
  echo "$tag"
  exit 0
fi

echo "error: no published tag for ${REPOSITORY}/${IMAGE} embeds commit ${commit}" >&2
exit 1
