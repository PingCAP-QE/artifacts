Central declarative congfigurations for artifacts delivering. 
===

> We use go template format to control them.

## Prerequire tools

- [gomplate](https://github.com/hairyhenderson/gomplate) 
  > Please install the master version. 
- [yq]
- jq

## For component binaries packages and container images

Configuration template: [packages.yaml.tmpl](./packages.yaml.tmpl)

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

## For offline deploy pacakges

### Required context

You can get them by run:
```console
$ grep -oE "{{\s*\..*?}}" packages/offline-packages.yaml.tmpl | grep -oE "\.\w+(\.\w+)*" | sort -u
.Release.arch
.Release.version
```

## How to verify verifyl the template

Please run `./packages/scripts/ci.sh` locally before commit.
