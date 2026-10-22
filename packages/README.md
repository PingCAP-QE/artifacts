Central declarative congfigurations for artifacts delivering.
===

> We use go template format to control them.
> Ref for SemVer Constraint: https://github.com/Masterminds/semver#checking-version-constraints

## Prerequire tools

- [gomplate](https://github.com/hairyhenderson/gomplate)
- [yq](https://github.com/mikefarah/yq)
- [jq](https://jqlang.github.io/jq/download/)

## Profiles

- `release`: community release profile.
- `enterprise`: enterprise release profile, it will not publish any tiup pkgs.
- `failpoint`: enable failpoint switch on community profile.
- `fips`: fips feature release without enterprise plugins.
- `rust`: builds only the standalone Rust SQL node (`tidb-server`) for
  `pingcap/tidb@hparser-integration` on `linux/amd64` and `linux/arm64`, and publishes the
  `tidb` tiup package to the **staging** mirror only. Uses the official Rust image
  (`docker.io/rustlang/rust:nightly-2026-08-22`, glibc) and builds no container images.

## For component binaries packages and container images

Configuration template: [packages.yaml.tmpl](./packages.yaml.tmpl)

### What's the golang version the builders are using

- `(~ 6.0]`: golang `v1.18.x`
- `[6.1 ~ 7.0)`: golang `v1.19`
- `[7.0 ~ 7.3]`: golang `v1.20.x`
- `[7.4 ~ 8.3]`: golang `v1.21.x`
- `[8.4 ~ 8.5.4]`: golang `v1.23.x`
- `[8.5.5 ~ )`: golang `v1.25.x`

### macOS native build toolchains (`macos.tools`)

For macOS (`darwin`) **native** builds, a builder entry may carry a `macos.tools` mapping. It is read **only**
by the mac agent (`mac-builder-operator`); Linux builds ignore it (they run the builder image, which already
pins the toolchain). Its content is a [mise](https://mise.jdx.dev) `[tools]` table — no new format.

**One `macos.tools` per `builders[].image` entry**, covering that image's `if:` range — a single config governs
multiple versions, the same granularity as "one Linux builder image governs multiple versions". Only
`darwin`-capable ranges on maintained lines (TiDB `>= v7.1`, plus trunk/dev branches treated as `>= v9.0.0`)
are declared. **Profile-keyed builders** (`experiment`, `rust`, `nextgen`, …) must hang `macos.tools` on the
**same `if:`**.

Sources of truth per tool (do **not** guess; leave unverified tools to the ambient fallback):

- `go` — the builder **image tag** (mirrors Linux).
- `node`/`pnpm`/`yarn` ("node series") — the **component branch** (e.g. `ui/package.json` `engines.node` /
  `packageManager`, `.nvmrc`), **not** the image's fixed value.
- `rust` — the branch `rust-toolchain` / `rust-toolchain.toml`.
- C++ build tools (`tikv`, `tiflash`) — `cmake` (pinned `3`, to avoid CMake 4 breakage); `tikv` also needs
  `ccache` (rocksdb's CMake auto-enables it as the compiler launcher via `find_program(ccache)` when present).
  Declare a tool only on the components that actually use it.

**Only per-component build tools belong here.** Generic CLI tools shared by every component/version
(`gomplate`, `yq`, `jq`, `deno`, `oras`) are **worker-global** — declared once in
[`macos/bootstrap/mise.toml`](./macos/bootstrap/mise.toml).

```yaml
    builders:
      - if: {{ semver.CheckConstraint ">= 8.5.5-0, < 8.5.6-0" .Release.version }}
        image: ghcr.io/pingcap-qe/cd/builders/pd:v2025.12.7-3-g1c0b8cf-centos7-go1.25
        macos:
          tools:
            go: "1.25"
      - if: {{ semver.CheckConstraint ">= 6.1.0-0" .Release.version }}
        image: ghcr.io/pingcap-qe/cd/builders/tikv:v2025.4.24-10-g9c32f77-centos7-devtoolset10
        macos:
          tools:
            rust: "nightly-2026-01-30"
            cmake: "3"
            ccache: "4"
```

The mac agent resolves the single matching builder for a build (component + semver range + profile) and
provisions these tool versions **per build** (isolated), instead of relying on them being installed globally
on the worker OS. If a component/builder has no `macos.tools`, the agent falls back to the builder image's
labels (e.g. `go-version`), then to the worker's global tools. The `[tools]` versions should mirror the
builder image's toolchain (the table above) so native output matches Linux.

**Clone parity with Tekton (`pingcap-git-clone`):** alongside the toolchain, the mac agent injects git
credentials from a Secret (`spec.source.gitSecretRef`) so it can clone **private** repos, and initializes
**submodules** (`git submodule update --init --recursive`; `spec.source.submodules`, default on) — several
components (e.g. `tiflash`) vendor their C/C++ deps (`contrib/` Boost/Poco/re2/gRPC) as submodules.

### What's the minimum OS of the packages

The OS floor of a package is **not** declared per component — it is inherited from the builder image that
produced it and, for darwin, from the SDK of the macOS build machine. Use this table to answer
"can my machine run this package".

| Platform | Minimum OS requirement | Determined by |
|---|---|---|
| `linux/amd64`, `linux/arm64` | depends on the builder image: **glibc 2.28** for the Rocky Linux 8.10 builders (most components), **glibc 2.17** for the `centos7` builders; components built on other base images (e.g. `tidb-operator` uses the official `golang` image) can be higher | `dockerfiles/cd/builders/<component>/Dockerfile` vs `.../centos7/Dockerfile`; routing in [packages.yaml.tmpl](./packages.yaml.tmpl) |
| `darwin/amd64`, `darwin/arm64` | **macOS 13.0** | SDK of the macOS build machine (Command Line Tools 14.3 / SDK 13.3) |

Checking a package:

```console
# darwin: minimum macOS version recorded in the Mach-O load commands
$ otool -l <binary> | grep -A3 LC_BUILD_VERSION      # minos 13.0 => needs macOS 13+

# linux: highest glibc symbol version required by the binary
$ objdump -T <binary> | grep -o 'GLIBC_[0-9.]*' | sort -uV | tail -1
```

Change history:

| Date | Change |
|---|---|
| 2026-10-22 | `darwin/amd64` and `darwin/arm64` packages moved from **macOS 12.0** to **macOS 13.0**. The macOS build machines were upgraded from macOS 12.7.6 to 13.7.8 (Command Line Tools 14.3 / SDK 13.3) in preparation for the Go 1.27 toolchain, which requires macOS 13+. Because `LC_BUILD_VERSION.minos` follows the SDK of the build machine, the new floor took effect immediately, before any Go version bump. `linux` packages are unaffected. |

> The floor is a property of the produced binaries, not of this repository, so it can change without any
> change to `go.mod` or `packages.yaml.tmpl`.

### Required context

You can get them by run:
```console
$ grep -oE "{{\s*\..*?}}" packages/packages.yaml.tmpl | grep -oE "\.\w+(\.\w+)*" | sort -u
.Git.ref
.Git.sha
.Git.url
.Release.arch
.Release.os
.Release.version
```

## For offline deploy packages

### Required context

You can get them by run:
```console
$ grep -oE "{{\s*\..*?}}" packages/offline-packages.yaml.tmpl | grep -oE "\.\w+(\.\w+)*" | sort -u
.Release.arch
.Release.version
```

## How to verify the template

Please run `./.github/scripts/ci.sh` locally before commit.
