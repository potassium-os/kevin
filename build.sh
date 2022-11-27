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
SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
cd "$SCRIPT_DIR" || exit 1

DEFAULT_TOP_DIR="${SCRIPT_DIR}"
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/defaults.sh"

# draw box around string for pretty output
. "${TOP_DIR}/scripts/common/drawbox.sh"

LOGO=$(cat <<END

  ╔════════════════════════════╗  
  ║                            ║  
  ║                            ║  
  ║                            ║  
  ║          ██╗  ██╗          ║
  ║          ██║ ██╔╝          ║
  ║          █████╔╝           ║
  ║          ██╔═██╗           ║
  ║          ██║  ██╗          ║
  ║          ╚═╝  ╚═╝          ║  
  ║                            ║  
  ║                            ║  
  ║                            ║  
  ╚════════════════════════════╝  
  Potassium ${VERSION}
  
END
)

echo "${LOGO}"

# tell the user what we're about to do
box_out "
Target Name:            ${TARGET_FRIENDLY_NAME}
Target ID:              ${TARGET_ID}

Kernel Repo:            ${TARGET_KERNEL_REPO}
Kernel Tag:             ${TARGET_KERNEL_TAG}
Clean Kernel Download:  ${CLEAN_KERNEL_DOWNLOAD}

U-Boot Repo:            ${TARGET_UBOOT_REPO}
U-Boot Tag:             ${TARGET_UBOOT_TAG}
Clean U-Boot Download:  ${CLEAN_UBOOT_DOWNLOAD}

Target Distro:          ${TARGET_DISTRO}
Target Distro Codename: ${TARGET_DISTRO_CODENAME}
"

# build steps to run (in order)
BUILD_STEPS=("kernel" "rootfs" "bootloader" "image")

# are we skipping any build steps?
# ex BUILD_SKIP_STEPS="uboot rootfs" ./build.sh
BUILD_SKIP_STEPS="${BUILD_SKIP_STEPS:-""}"
SKIP_STEPS=()
IFS=' ' read -r -a SKIP_STEPS <<< "${BUILD_SKIP_STEPS}"

# run each build step
for STEP in "${BUILD_STEPS[@]}"; do
  # if current step is NOT in KERNEL_BUILD_SKIP_STEPS
  if ! [[ " ${SKIP_STEPS[*]} " =~ " ${STEP} " ]]; then
    # run the step
    echo "About to run ${TOP_DIR}/scripts/build-steps/${STEP}.sh"
    . "${TOP_DIR}/scripts/build-steps/${STEP}.sh"
  else
    echo "Skipping build step: ${STEP}"
  fi
done

echo "--- end build.sh ---"
