Public template files for publish artifacts
===

> We using [just](https://github.com/casey/just) tool to group the shell steps to debug the image building.

**Attention**: currently they are only tested on linux/x86_64 platform.

## TiDB

### How to build the image from source

You can simplely build it by run `just msb-tidb`, or run the same steps in bash:

```bash
#!/usr/bin/env bash

component=tidb
git_url=https://github.com/pingcap/tidb.git

[ -e ../${component} ] || git clone --recurse-submodules ${git_url} ../${component}
([ -e ../${component}/.dockerignore ] && rm ../${component}/.dockerignore) || true # make step depended on git metadata.
docker build -t ${component} -f dockerfiles-multi-stages/${component}/Dockerfile ../${component}
```

### System Requirement
- Docker version: 20.10
- CPU: 8 core or higher
- RAM: 16 GiB or higher

Estimated Time: 0.5 hour

### How to check the server version

You can get the information by the command:

```bash
docker run --rm tidb:latest -V
```

Example of output:

```yaml
Release Version: v6.7.0-alpha-6-g55c83585d-dirty
Edition: Community
Git Commit Hash: 55c83585d2b58e88ba8eaf58c47448f624022d1d
Git Branch: master
UTC Build Time: 2023-02-14 03:10:00
GoVersion: go1.19.5
Race Enabled: false
TiKV Min Version: 6.2.0-alpha
Check Table Before Drop: false
Store: unistore
```

## TiKV

### How to build the image from source

You can simplely build it by run `just msb-tikv`, or run the same steps in bash:

```bash
#!/usr/bin/env bash

component=tikv
git_url=https://github.com/tikv/tikv.git

[ -e ../${component} ] || git clone --recurse-submodules ${git_url} ../${component}
([ -e ../${component}/.dockerignore ] && rm ../${component}/.dockerignore) || true # make step depended on git metadata.
docker build -t ${component} -f dockerfiles-multi-stages/${component}/Dockerfile ../${component}
```

### System Requirement
- Docker version: 20.10
- CPU: 8 core or higher
- RAM: 32 GiB or higher

Estimated Time: 1.5 hour

### How to check the server version

```bash
docker run --rm tikv:latest --version
```

## PD

### How to build the image from source

You can simplely build it by run `just msb-pd`, or run the same steps in bash:

```bash
#!/usr/bin/env bash

component=pd
git_url=https://github.com/tikv/pd.git

[ -e ../${component} ] || git clone --recurse-submodules ${git_url} ../${component}
([ -e ../${component}/.dockerignore ] && rm ../${component}/.dockerignore) || true # make step depended on git metadata.
docker build -t ${component} -f dockerfiles-multi-stages/${component}/Dockerfile ../${component}
```

### System Requirement
- Docker version: 20.10
- CPU: 8 core or higher
- RAM: 16 GiB or higher

Estimated Time: 0.5 hour

### How to check the server version

You can get the information by the command:

```bash
docker run --rm pd:latest -V
```

## TiFlash

### How to build the image from source

You can simplely build it by run `just msb-tiflash`, or run the same steps in bash:

```bash
#!/usr/bin/env bash

component=tiflash
git_url=https://github.com/pingcap/tiflash.git

[ -e ../${component} ] || git clone --recurse-submodules ${git_url} ../${component}
([ -e ../${component}/.dockerignore ] && rm ../${component}/.dockerignore) || true # make step depended on git metadata.
docker build -t ${component} -f dockerfiles-multi-stages/${component}/Dockerfile ../${component}
```

### System Requirement
- Docker version: 20.10
- CPU: 8 core or higher
- RAM: 32 GiB or higher

Estimated Time: 6 hour

### How to check the server version

You can get the information by the command:
```bash
docker run --rm --entrypoint=/tiflash/tiflash tiflash:latest version
```
