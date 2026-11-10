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
  example `v1.12.3`) to reproduce a historical finding.
- **Implementation:** `.github/scripts/scan-base-images.sh` (exit `2` means an
  image could not be scanned; vulnerability findings do not change its exit
  code).

### When the weekly scan fails

1. Open the linked issue; the per-image table shows which base image regressed.
2. Refresh the affected packages and release a new base image tag (the
   `fix(bases): refresh packages ...` PRs are the reference flow).
3. Re-run the weekly workflow with `image_tag` set to the new tag to confirm it
   is clean; the next clean scheduled run closes the issue automatically.
4. If the job failed in the scan step (not the gate step) and `failed_images` is
   non-empty, it was a registry or Trivy DB error: no issue is opened, just
   re-run the job.
