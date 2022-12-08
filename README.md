# Why is this archived?
I libreboot'ed my `kevin` and no longer need chromeos style images

# What is this?
Embedded Linux image build tooling for the chromebook `kevin` and ubuntu LUNAR LOBSTER

## What do I need?
Any modern linux with docker installed \
A decent amount of (fast) storage

## How do I run a build?

```bash
./build-potassium.sh

# or run individual scripts
alias potassium="./scripts/container-exec.sh"
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
# Currently only kevin and ubuntu lunar are supported,
#   and it will remain the default
TARGET="kevin-lunar"
# Target config (ex targets/kevin-lunar/target.conf)
#   is (re)read early in the execution of each build step
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

## How to I menuconfig the kernel?

```bash
./scripts/container-exec.sh scripts/kernel/nconfig.sh
# do your thing with nconfig
# save it to "newconfig"

# then diffconfig it like such
./scripts/container-exec.sh bash

# inside container
cd tmp/kevin-lunar-cmdline/dst/kernel
make defconfig
source/scripts/diffconfig -m .config newconfig | tee targets/kevin-lunar-cmdline/kernel/diffconfig
```

## It booted (yay!), but how do I login?

```bash 
# users root, ubuntu
# password potassium
# change it in scripts/roots/base-setup.sh
```

## I want a DE

```bash
# wayland recommended
apt install ubuntu-desktop
```


## Why "Potassium" ?

kevin = K = potassium
