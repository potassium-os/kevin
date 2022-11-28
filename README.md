# potassium
Embedded Linux image build tooling

At the moment it only supports the chromebook `kevin` and debian-like distros

## What do I need?
Any modern linux with docker installed \
A decent amount of (fast) storage

## How do I run a build?

```bash
./build-potassium.sh

alias potassium="./scripts/container-exec.sh"

# or run individual scripts
potassium scripts/kernel/download.sh
potassium scripts/rootfs/debootstrap.sh

# you can skip build steps if they've already run / are still clean
BUILD_SKIP_STEPS="kernel" potassium scripts/build.sh

# or skip sub-steps of a build step
KERNEL_BUILD_SKIP_STEPS="download patch" potassium scripts/build-steps/kernel.sh

# start over - must be set to "cleanall"
CLEAN_BUILD="cleanall" ./build-potassium.sh

# etc
```

## Envvars you need/want to set (with defaults):

```bash
# Your target
# Currently only kevin is supported,
# and it will remain the default
TARGET="kevin"
# Target config (ex targets/kevin/target.conf)
# is read fairly early in the build process.
# You can specify things there instead of at runtime

# Dangerous!
# When set to "cleanall" will rm -rf your entire tmpdir!
CLEAN_BUILD=false

# skip build steps
# scripts/build.sh
# BUILD_STEPS=("kernel" "rootfs" "bootloader" "image")
# ex: we want to skip rootfs step alltogether
BUILD_SKIP_STEPS="rootfs"

# scripts/build-steps/kernel.sh
# KERNEL_BUILD_STEPS=("download" "patch" "configure" "compile" "package")
# ex: we want to skip kernel download/config but still want to compile/package
KERNEL_BUILD_SKIP_STEPS="download patch configure"

# scripts/build-steps/rootfs.sh
# ROOTFS_BUILD_STEPS=("debootstrap")
ROOTFS_BUILD_SKIP_STEPS=""
```

## I want a shell in the build env container

```bash
./scripts/container-exec.sh bash
```
