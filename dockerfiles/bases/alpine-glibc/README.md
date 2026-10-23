# alpine-glibc

Alpine base images with glibc, published as a matrix of
Alpine version x glibc version.

Phase 1 covers **Alpine 3.22**; 3.23 and 3.24 are added later by
appending one line to `matrix.yaml`.

## Sources

| glibc | source | architectures |
| --- | --- | --- |
| 2.30 - 2.35 | `frolvlad/alpine-glibc` donor image (sgerrand recipe) | amd64 |
| 2.36 - 2.44 | [`dalet-oss/alpine-glibc`](https://github.com/dalet-oss/alpine-glibc) signed APK releases | amd64 + arm64 |

We do not compile or package glibc:

- For 2.30-2.35 the runtime tree (`/usr/glibc-compat`, locale archive,
  `ldconfig`) is copied from a digest-pinned donor image.
- For 2.36-2.44 the signed APKs are downloaded from GitHub Releases and
  installed with `apk`; the dalet-oss project continues the sgerrand
  packaging work and publishes both amd64 and arm64.

`2.44` release tags use a `-r1` suffix (`2.44-<arch>-r1`); the Dockerfile
derives it from the version, asset names stay `glibc-2.44.apk`.

## Images and tags

Registry: `ghcr.io/pingcap-qe/bases/alpine-glibc`

Tag: `<alpine-minor>_glibc-<version>`, e.g. `3.22_glibc-2.44` (the image name already contains `alpine`).
Production consumers should pin by digest.

## Build

The matrix is driven by `matrix.yaml`; `skaffold.yaml` is generated from it.

```bash
make generate                 # regenerate skaffold.yaml
make check                    # fail if skaffold.yaml is out of date
make build PROFILE=3.22_glibc-2.30
```

Profiles follow `<alpine-minor>_glibc-<version>`; one `skaffold build`
produces exactly one tag. The release workflow runs one job per profile
with `--default-repo=ghcr.io/pingcap-qe/bases`.

For local builds behind a restricted network, point apk at a mirror:

```bash
docker buildx build --target donor --platform linux/amd64 \
  --build-arg ALPINE_VERSION=3.22 \
  --build-arg ALPINE_REPO=https://mirrors.aliyun.com/alpine \
  --build-arg GLIBC_IMAGE=<donor> --load -t local/alpine-glibc:test .
```

### Adding a version

1. Append the glibc entry (or the Alpine version) to `matrix.yaml`.
2. `make generate` and commit both files.
3. CI publishes the new profiles.

## Validation

```bash
/usr/glibc-compat/lib/libc.so.6 | head -1        # must match the profile version
readlink -f /lib/ld-linux-x86-64.so.2 | grep -q /usr/glibc-compat/
/usr/glibc-compat/bin/locale charmap | grep -qi utf-8
/usr/glibc-compat/bin/getent hosts localhost
test -e /usr/share/zoneinfo/UTC
apk info -e tzdata
```

`ldd` is a bash script in glibc; the `donor` target does not install bash,
so do not use `ldd` as a gate.

## Known limits

- glibc CVE coverage is a blind spot: these packages are not in the Alpine
  secdb, so Trivy reports zero even for old glibc versions. Treat the old
  versions as compatibility fixtures and record explicit risk acceptance
  before using them in production.
- dalet-oss packaging drops `lib/gconv`; non-UTF-8 `iconv` conversions may
  not work.
- Only `tzdata` is installed. `bind-tools`/`curl` are not part of the base;
  add them in derived images if needed.
- 2.30-2.35 have no arm64 upstream artifacts; they are amd64-only.
