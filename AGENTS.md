# AGENTS.md

## Project overview
This repository hosts public templates and configuration used to publish PingCAP QE artifacts (container images, package manifests, and release routing). It includes Dockerfiles, package configuration templates, and scripts for generating release outputs.

## Key paths
- `dockerfiles/`: Dockerfiles and a `Justfile` for building CD/CI images; see `dockerfiles/cd/README.md`.
- `packages/`: Go-template YAML configs and scripts that generate release artifacts; see `packages/README.md`.
- `schemas/`: JSON schema(s) for delivery configs (e.g., `schemas/delivery-schema.json`).

## Conventions and expectations
- Preserve YAML ordering, comments, and quoting; avoid stylistic reformatting unless requested.
- `packages/*.tmpl` use Go template syntax (via gomplate). Prefer updating templates, then regenerating outputs.
- Bash scripts use `set -euo pipefail`; keep them shellcheck-clean.
- Avoid touching `release-*.yaml` directly; regenerate via the scripts under `packages/scripts/`.
- Commit messages follow Conventional Commits, e.g., `feat(scope): subject` or `fix: subject`.

## Common workflows
- Build images from source: `just` recipes in `dockerfiles/Justfile` (requires Docker and `just`).
- Validate package templates: `./.github/scripts/ci.sh` (long-running; requires `shellcheck` and `crane`, plus `gomplate`, `yq`, and `jq`).
- Pre-commit hooks: trailing whitespace, EOF fixer, and gitleaks (`.pre-commit-config.yaml`).
