Central declarative congfigurations for artifacts delivering. 
===

> We use go template format to control them.
> Ref for SemVer Constraint: https://github.com/Masterminds/semver#checking-version-constraints

## Prerequire tools

- [gomplate](https://github.com/hairyhenderson/gomplate) 
  > Please install the master version. 
- [yq](https://github.com/mikefarah/yq)
- [jq](https://jqlang.github.io/jq/download/)

## Profiles

- `release`: community release profile.
- `enterprise`: enterprise release profile, it will not publish any tiup pkgs.
- `failpoint`: enable failpoint switch on community profile.
- `fips`: fips feature release without enterprise plugins.

## For component binaries packages and container images

Configuration template: [packages.yaml.tmpl](./packages.yaml.tmpl)

### What's the golang version the builders are using

- `(~ 6.0]`: golang `v1.18.x`
- `[6.1 ~ 7.0)`: golang `v1.19`
- `[7.0 ~ 7.3]`: golang `v1.20.x`
- `[7.4 ~)`: golang `v1.21.x`

### Required context

You can get them by run:
```console
$ grep -oE "{{\s*\..*?}}" packages/packages.yaml.tmpl | grep -oE "\.\w+(\.\w+)*" | sort -u
.Git.ref
.Git.sha
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

Please run `./packages/scripts/ci.sh` locally before commit.
