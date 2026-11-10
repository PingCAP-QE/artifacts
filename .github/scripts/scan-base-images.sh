#!/usr/bin/env bash
#
# Scan the PingCAP-QE base images published to ghcr.io and build a structured
# vulnerability report for the weekly scan workflow.
#
# Policy (owner decision, 2026-10-26):
#   - severity: HIGH + CRITICAL only (MEDIUM is out of scope)
#   - unfixed vulnerabilities are INCLUDED; "fixable" is reported as a column
#     but does not gate
#
# Exit codes:
#   0  every image scanned successfully (findings may still exist; the caller
#      decides whether to fail the job)
#   1  invalid usage or missing dependency (trivy / jq)
#   2  at least one image could not be scanned (registry pull, Trivy DB, ...)
#      The report is still written with the images that succeeded, and
#      `failed_images` in scan-summary.json lists the rest.
#
# Usage:
#   scan-base-images.sh --tag <image-tag> [--output-dir <dir>]
#                       [--severity <list>] [--images <comma-separated>]
#
# Environment:
#   RUN_URL       optional workflow run URL recorded in the report
#   GITHUB_OUTPUT optional; when set, totals are appended for later steps
#
# Outputs (under --output-dir):
#   scan-summary.json  machine-readable report (per-image counts + findings)
#   scan-report.md     Markdown report used for the issue body / step summary
#   raw/<image>.json   raw Trivy JSON per image

set -euo pipefail

DEFAULT_IMAGES=(pingcap-base pd-base tikv-base tidb-base ng-monitoring-base tiflash-base tools-base)

IMAGE_TAG=""
OUTPUT_DIR="${RUNNER_TEMP:-/tmp}/weekly-scan"
SEVERITIES="HIGH,CRITICAL"
IMAGES=("${DEFAULT_IMAGES[@]}")

usage() {
  awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print; next } NR > 1 { exit }' "$0"
}

while [ $# -gt 0 ]; do
  case "$1" in
    --tag)
      IMAGE_TAG="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    --severity)
      SEVERITIES="${2:-}"
      shift 2
      ;;
    --images)
      IFS=',' read -r -a IMAGES <<<"${2:-}"
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

if [ -z "$IMAGE_TAG" ]; then
  echo "error: --tag is required" >&2
  usage >&2
  exit 1
fi

if ! command -v trivy >/dev/null 2>&1; then
  echo "error: trivy is not installed" >&2
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is not installed" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR/raw" "$OUTPUT_DIR/summaries"

SCANNED_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
FAILED_JSON='[]'

for img in "${IMAGES[@]}"; do
  ref="ghcr.io/pingcap-qe/bases/${img}:${IMAGE_TAG}"
  raw="$OUTPUT_DIR/raw/${img}.json"

  echo "=== Scanning ${ref} ==="
  if ! trivy image \
    --image-src remote \
    --quiet \
    --format json \
    --output "$raw" \
    --severity "$SEVERITIES" \
    --exit-code 0 \
    "$ref"; then
    echo "::error::Trivy could not scan ${ref}; see the log above"
    FAILED_JSON="$(jq -c --arg img "$img" '. + [$img]' <<<"$FAILED_JSON")"
    rm -f "$raw"
    continue
  fi

  jq --arg image "$img" --arg ref "$ref" '
    ([.Results[]?.Vulnerabilities[]?
      | select(.Severity == "CRITICAL" or .Severity == "HIGH")]) as $vulns
    | {
        image: $image,
        ref: $ref,
        critical: ([$vulns[] | select(.Severity == "CRITICAL")] | length),
        high: ([$vulns[] | select(.Severity == "HIGH")] | length),
        fixable: ([$vulns[] | select((.FixedVersion // "") != "")] | length),
        vulnerabilities: ($vulns
          | map({
              cve: .VulnerabilityID,
              severity: .Severity,
              package: .PkgName,
              installed: .InstalledVersion,
              fixed: (.FixedVersion // ""),
              title: (.Title // "")
            })
          | unique_by(.cve, .package, .installed))
      }
  ' "$raw" >"$OUTPUT_DIR/summaries/${img}.json"

  jq -r '"\(.image): CRITICAL=\(.critical) HIGH=\(.high) fixable=\(.fixable)"' \
    "$OUTPUT_DIR/summaries/${img}.json"
done

shopt -s nullglob
summary_files=("$OUTPUT_DIR"/summaries/*.json)
if [ "${#summary_files[@]}" -gt 0 ]; then
  jq -s '.' "${summary_files[@]}" >"$OUTPUT_DIR/images.json"
else
  echo '[]' >"$OUTPUT_DIR/images.json"
fi

jq -n \
  --arg tag "$IMAGE_TAG" \
  --arg scanned_at "$SCANNED_AT" \
  --arg run_url "${RUN_URL:-}" \
  --arg severity "$SEVERITIES" \
  --argjson failed "$FAILED_JSON" \
  --slurpfile images "$OUTPUT_DIR/images.json" \
  '{
    tag: $tag,
    scanned_at: $scanned_at,
    run_url: $run_url,
    severity: ($severity | split(",")),
    images: $images[0],
    failed_images: $failed,
    totals: {
      critical: ([$images[0][].critical] | add // 0),
      high: ([$images[0][].high] | add // 0),
      fixable: ([$images[0][].fixable] | add // 0)
    }
  }' >"$OUTPUT_DIR/scan-summary.json"

jq -r '
  def row:
    "| `\(.cve)` | \(.severity) | `\(.package)` | `\(.installed)` | "
    + (if .fixed == "" then "_unfixed_" else "`\(.fixed)`" end)
    + " | " + ([.images[] | "`\(.)`"] | join(", ")) + " |";

  ([.images[]
    as $img
    | $img.vulnerabilities[]
    | . + {image: $img.image}]
    | group_by([.cve, .package, .installed])
    | map({
        cve: .[0].cve,
        severity: (map(.severity) | unique | join("/")),
        package: .[0].package,
        installed: .[0].installed,
        fixed: (map(.fixed) | unique | map(select(. != "")) | join(", ")),
        images: (map(.image) | unique)
      })
    | sort_by(.severity, .cve)) as $vulns
  | (.images | length) as $scanned
  | (.failed_images | length) as $failed
  |
  (
    "# Base image Trivy scan — bases:\(.tag)",
    "",
    "- Tag: `\(.tag)`",
    "- Scanned at: \(.scanned_at)",
    "- Policy: \(.severity | join(" + ")) (unfixed included; fixable is informational)",
    "- Run: \(if .run_url == "" then "n/a" else .run_url end)",
    "- Images scanned: \($scanned) / \($scanned + $failed)",
    "",
    "## Per-image summary",
    "",
    "| Image | CRITICAL | HIGH | Fixable |",
    "| --- | ---: | ---: | ---: |",
    (.images[] | "| `\(.image)` | \(.critical) | \(.high) | \(.fixable) |"),
    "| **Total** | **\(.totals.critical)** | **\(.totals.high)** | **\(.totals.fixable)** |",
    "",
    (if (.totals.critical + .totals.high) == 0 then
       "No HIGH/CRITICAL vulnerabilities found.",
       ""
     else
       "## HIGH / CRITICAL vulnerabilities",
       "",
       "| CVE | Severity | Package | Installed | Fixed | Images |",
       "| --- | --- | --- | --- | --- | --- |",
       ($vulns[0:300][] | row),
       (if ($vulns | length) > 300 then
          "",
          "_Only the first 300 distinct findings are listed; see `scan-summary.json` for the complete set._"
        else empty end),
       ""
     end),
    (if (.failed_images | length) > 0 then
       "",
       "## Scan errors",
       "",
       (.failed_images[] | "- `\(.)` could not be scanned (registry or Trivy DB error)"),
       ""
     else empty end)
  )
' "$OUTPUT_DIR/scan-summary.json" >"$OUTPUT_DIR/scan-report.md"

cat "$OUTPUT_DIR/scan-report.md"

if [ -n "${GITHUB_OUTPUT:-}" ]; then
  {
    echo "critical=$(jq -r '.totals.critical' "$OUTPUT_DIR/scan-summary.json")"
    echo "high=$(jq -r '.totals.high' "$OUTPUT_DIR/scan-summary.json")"
    echo "total=$(jq -r '.totals.critical + .totals.high' "$OUTPUT_DIR/scan-summary.json")"
    echo "failed=$(jq -r '.failed_images | length' "$OUTPUT_DIR/scan-summary.json")"
    echo "report_file=$OUTPUT_DIR/scan-report.md"
    echo "summary_file=$OUTPUT_DIR/scan-summary.json"
  } >>"$GITHUB_OUTPUT"
fi

if [ "$FAILED_JSON" != '[]' ]; then
  echo "::error::Some base images could not be scanned; treating this run as an infrastructure failure"
  exit 2
fi
