Github Workflows
====

## Why we setup github workflows?

- Q: You may have questions, why not use our own system to handle the CI/CD work here (dog food principle).
  > A: We want to use github's build environment to solve the bandwidth problem.
  > Also we want to use the github build environment to publish open source artifacts to ghcr.io and establish an update monitoring mechanism, which is not possible using internal artifactories.

## Weekly base image vulnerability scan (`weekly-release.yaml`)

The `image-scan` job runs every Sunday and can be triggered manually with
`workflow_dispatch`.

- **Policy:** Trivy reports `HIGH` and `CRITICAL` findings, including those
  without an upstream fix; `MEDIUM` is out of scope. The publish gate in
  `release-prod-runtime-images.yaml` uses the same policy, so a green weekly run
  and a red publish run cannot contradict each other.
- **Signal:** when findings exist, the job opens (or updates) one issue labeled
  `security` + `weekly-scan`, titled
  `[weekly-scan] HIGH/CRITICAL vulnerabilities in base images (<tag>)`, and then
  fails. A clean run closes every open `weekly-scan` issue.
- **Reports:** `scan-report.md` and `scan-summary.json` are written to the job
  summary and uploaded as the `weekly-scan-<tag>` artifact (30 days).
- **Scan another tag:** dispatch the workflow with the `image_tag` input (for
  example `v1.12.6`) to reproduce a historical finding. Without the input the
  job scans the newest published base image tag.
- **Implementation:** `.github/scripts/scan-base-images.sh` (exit `2` means an
  image could not be scanned; vulnerability findings do not change its exit
  code) and `.github/scripts/resolve-published-base-tag.sh` (default tag
  resolution).

## Base image publishing (`release-prod-runtime-images.yaml`)

- The `default` module derives its tag from `git describe --tags --always`
  (`v2026.11.27-2-ge5c763a` → `v2026.11.27-2.ge5c763a`), so the tag identifies
  the commit and is never reused.
- Re-runs are deduplicated with skaffold's `--cache-artifacts` plus the
  `~/.skaffold/cache` actions cache: when the tag's remote digest still matches
  the cache entry, skaffold skips the build and push, so re-running the
  workflow normally does not overwrite an existing tag. This is best-effort - a
  cache miss (e.g. an expired actions cache) rebuilds and re-pushes the tag. To
  publish refreshed packages, change an input (e.g. bump `_date` in
  `bases/pingcap-base/Dockerfile`) so the commit, and therefore the tag,
  changes.
- The `release-6-5` module still uses the fixed `v1.0.2-old` tag and is
  rebuilt (overwritten) on every run.

### When the weekly scan fails

1. Open the linked issue; the per-image table shows which base image regressed.
2. Refresh the affected packages and let the publish workflow rebuild the base
   images (the `fix(bases): refresh packages ...` PRs are the reference flow).
   The default skaffold module converts `git describe --tags --always` into a
   semver-compatible tag (`v2026.11.27-2.ge5c763a`), so no version bump is
   needed.
3. Re-run the weekly workflow with `image_tag` set to the new tag to confirm it
   is clean; the next clean scheduled run closes the issue automatically.
4. If the job failed in the scan step (not the gate step) and `failed_images` is
   non-empty, it was a registry or Trivy DB error: no issue is opened, just
   re-run the job.
