#!/usr/bin/env bash

echo "--- start build.sh ---"

# debug mode = set -x = loud
DEBUG="${DEBUG:-false}"
if $DEBUG; then
  set -exu
else
  set -eu
fi

# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "$DIRNAME" || exit; pwd)
cd "$SCRIPT_DIR" || exit

DEFAULT_TOP_DIR="${SCRIPT_DIR}"
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/defaults.sh"

# draw box around string for pretty output
. "${TOP_DIR}/scripts/common/drawbox.sh"

# tell the user what we're about to do
box_out "
About to build Potassium:

Target:                 ${TARGET_FRIENDLY_NAME}

Kernel Repo:            ${TARGET_KERNEL_REPO}
Kernel Tag:             ${TARGET_KERNEL_TAG}
Clean Kernel Download:  ${CLEAN_KERNEL_DOWNLOAD}

U-Boot Repo:            ${TARGET_UBOOT_REPO}
U-Boot Tag:             ${TARGET_UBOOT_TAG}
Clean U-Boot Download:  ${CLEAN_UBOOT_DOWNLOAD}

Target Distro:          ${TARGET_DISTRO}
Target Distro Codename: ${TARGET_DISTRO_CODENAME}
"

# build the kernel
. "${TOP_DIR}/scripts/kernel/build.sh"

# build u-boot
# scripts/uboot/build.sh

# build the rootfs
# scripts/rootfs/build.sh


echo "--- end build.sh ---"
