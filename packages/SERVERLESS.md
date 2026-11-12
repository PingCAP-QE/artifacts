# Serverless artifacts

Five independent components use the `release` profile: `tidb-cse`, `pd-cse`,
`tidb-operator-cse`, `cassandra-on-mysql`, and `qdrant-on-tidb`. Each produces Linux
amd64 and arm64 binaries, tarball checksums and container images. Operator
keeps its four executables and explicitly passes `TARGETARCH` into its Dockerfile.
Runtime Dockerfiles live in `dockerfiles/products/serverless/`; use the same
artifacts revision for builder selection, binaries and images.

| Component | Image suffix under `tidbcloud/<component>/` | Initial Git baseline |
| --- | --- | --- |
| tidb-cse | images/tidb-server, images/br, images/dumpling, images/tidb-lightning | v8.5.3-alpha.0 |
| pd-cse | image | v8.5.0-alpha.0 |
| tidb-operator-cse | images/tidb-operator | v1.4.0-alpha.0 |
| cassandra-on-mysql | image | v0.1.0-alpha.0 |
| qdrant-on-tidb | image | v1.3.4-alpha.0 |

Registry is an execution parameter: formal builds use
`us-docker.pkg.dev/pingcap-testing-account/serverless`; devbuild uses
`us-docker.pkg.dev/pingcap-testing-account/dev`. Both place binary artifacts at
`tidbcloud/<component>/package`. A fork URL changes source checkout/OCI provenance,
but component identity continues to determine artifact paths.

The `tidb-cse` release builds TiDB server, BR, Dumpling, Lightning and
Lightning control together using `make server build_tools build_dumpling`.
Each binary has its own tarball and SHA-256 checksum in the existing package
repository; the TiDB server tarball keeps its `tidb-cse-<version>-<os>-<arch>`
name. The Lightning image includes both `tidb-lightning` and
`tidb-lightning-ctl`. Tool images preserve the source Dockerfiles' executable
paths, `dumb-init` entrypoints, runtime utilities and BR logging environment.

Merge and validate these tool outputs for both architectures and all six
maintained TiDB branches before merging the source PRs that remove
`cd-br.yaml`, `cd-dumpling.yaml` and `cd-lightning.yaml`. The historical native
validation record below predates the tool outputs and covers TiDB server only.

The version passed to the generator must come from Git, never the devbuild
request's compatibility `version` field. Tags retain the shared conventions:
normalized ref, ref plus seven-character SHA and inferred version; platform tags
end in `_linux_amd64` or `_linux_arm64`. Both platform images must exist before a
manifest without a platform suffix is published. A single-platform build can
succeed with its platform image only. No Serverless package is delivered to TiUP.

Checkout and dependency downloads require a GitHub token authorized for the
private source/modules. Tekton mounts the existing basic-auth secret at runtime;
do not put tokens into build args, image layers or repository config. Go builders
and runtime bases are pinned by version and multi-platform digest. Qdrant uses
Rust `nightly-2024-12-28` on the pinned Amazon Linux base.

Serverless Go components build with pinned images from
`ghcr.io/pingcap-qe/cd/builders`. There is no automatic builder upgrade: when a
source repository raises its `go` directive, update the builder here in a pull
request. `pd-cse` uses the `centos7` Go 1.27.3 builder to match
`tidbcloud/pd-cse@release-8.5-keyspace` and does not override
`GOTOOLCHAIN`, so Go's default (`auto`) downloads the needed toolchain when a
builder lags instead of failing the build. `tidb-cse` (Go 1.24) and
`tidb-operator-cse` (Go 1.21) stay on their current builders until their source
`go.mod` moves.

Run `.github/scripts/test-serverless.sh` for both architectures and both registries,
and `.github/scripts/ci.sh` for the existing package matrix regression. These test
generated scripts and routes; successful native builds, registry pushes and
manifest inspection must also be recorded before cutover. Formal registry
provisioning is managed by `PingCAP-QE/ee-infra`, execution by `PingCAP-QE/ci`,
product mappings by `PingCAP-QE/ee-ops`, and formal distribution by
`tidbcloud/docker-image-controller`. Native regional Qdrant, TiKV and TiFlash are
outside this change.

Serverless runtime bases are pinned by digest from `ghcr.io/pingcap-qe/bases`:
`tidb-cse` server uses `tidb-base:v1.12.6`, `pd-cse` uses `pd-base:v1.12.6`, and
`tidb-operator-cse` uses `pingcap-base:v1.12.6`. The `tidb-cse` BR, Dumpling and
Lightning images still use `debian:bullseye-slim` by digest to preserve the
upstream tool images' utilities and init process.

## Native validation evidence

See [the 2026-10-20 validation record](validation/serverless-20261020.json) for
all five Linux amd64/arm64 PipelineRuns, pinned source/config revisions, image
and complete manifest digests, downloaded package SHA-256 values and ELF machine
checks. The same record includes isolated HTTP API → CloudEvents → Tekton →
Dashboard reconciliation devbuild checks for branch, PR and commit inputs.

These runs used local checkout-only baseline tags and the existing dev GAR.
They do not create remote baselines, provision the formal GAR, deploy service
images, send Lark messages or validate distribution into ECR/AliCloud. Those
checks remain explicit rollout gates. TiDB's divergent maintenance branches have
separate cutover PRs and reserved reachable prerelease baselines in the CI guide.
