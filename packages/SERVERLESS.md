# Serverless artifacts

Five independent components use the `release` profile: `tidb-cse`, `pd-cse`,
`tidb-operator-cse`, `cassandra-on-mysql`, and `qdrant-on-tidb`. Each produces Linux
amd64 and arm64 binaries, a tarball checksum and one container image. Operator
keeps its four executables and explicitly passes `TARGETARCH` into its Dockerfile.
Runtime Dockerfiles live in `dockerfiles/products/serverless/`; use the same
artifacts revision for builder selection, binaries and images.

| Component | Image suffix under `tidbcloud/<component>/` | Initial Git baseline |
| --- | --- | --- |
| tidb-cse | images/tidb-server | v8.5.3-alpha.0 |
| pd-cse | image | v8.5.0-alpha.0 |
| tidb-operator-cse | images/tidb-operator | v1.4.0-alpha.0 |
| cassandra-on-mysql | image | v0.1.0-alpha.0 |
| qdrant-on-tidb | image | v1.3.4-alpha.0 |

Registry is an execution parameter: formal builds use
`us-docker.pkg.dev/pingcap-testing-account/serverless`; devbuild uses
`us-docker.pkg.dev/pingcap-testing-account/dev`. Both place binary artifacts at
`tidbcloud/<component>/package`. A fork URL changes source checkout/OCI provenance,
but component identity continues to determine artifact paths.

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

Run `.github/scripts/test-serverless.sh` for both architectures and both registries,
and `.github/scripts/ci.sh` for the existing package matrix regression. These test
generated scripts and routes; successful native builds, registry pushes and
manifest inspection must also be recorded before cutover. Formal registry
provisioning is managed by `PingCAP-QE/ee-infra`, execution by `PingCAP-QE/ci`,
product mappings by `PingCAP-QE/ee-ops`, and formal distribution by
`tidbcloud/docker-image-controller`. Native regional Qdrant, TiKV and TiFlash are
outside this change.

TiDB/PD use the official Debian Bullseye runtime by digest directly. The former
keyspace Harbor alias and Docker Hub contain the identical multi-architecture
manifest `sha256:acc5810124f0929ab44fc7913c0ad936b074cbd3eadf094ac120190862ba36c4`;
using Docker Hub preserves every base layer and avoids private Harbor routing
from GCP build workers.

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
