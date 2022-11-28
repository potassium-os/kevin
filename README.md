# potassium
Full Linux on Kevin

This repo defines targets and is a metarepo for other required things.

At the moment it only supports the chromebook `kevin` and debian-like distros

## Envvars you need/want to set (with defaults):

```bash
# Your target
# Currently only kevin is supported,
# and it will remain the default
TARGET="kevin"
# Target config (ex targets/kevin/target.conf)
# is read fairly early in the build process.
# You can specify things there instead of at runtime

# do we rm -rf tmp/kernel/$TARGET before downloading?
CLEAN_KERNEL_DOWNLOAD="${CLEAN_KERNEL_DOWNLOAD:-false}"

# do we rm -rf tmp/uboot/$TARGET before downloading?
CLEAN_UBOOT_DOWNLOAD="${CLEAN_UBOOT_DOWNLOAD:-false}"

# skip build steps
# scripts/build.sh
BUILD_SKIP_STEPS=""

# scripts/build-steps/kernel.sh
KERNEL_BUILD_SKIP_STEPS=""

# scripts/build-steps/rootfs.sh
ROOTFS_BUILD_SKIP_STEPS=""
```

## How do I run a build?

```bash
./build-potassium.sh

# or run individual scripts
./scripts/container-exec.sh scripts/kernel/download.sh
./scripts/container-exec.sh scripts/rootfs/debootstrap.sh
# etc
```

## I want a shell in the build env container

```bash
./scripts/container-exec.sh bash
```
