#!/usr/bin/env bash

echo "--- start scripts/rootfs/base-setup.sh ---"

# debug mode = set -x = loud
DEBUG="${DEBUG:-false}"
if $DEBUG; then
  set -exu
else
  set -eu
fi

# If the script wasn't sourced we need to set DIRNAME and SCRIPT_DIR
if ! (return 0 2>/dev/null)
then
  # where this .sh file lives
  DIRNAME=$(dirname "$0")
  SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
fi

DEFAULT_TOP_DIR=$(dirname "${SCRIPT_DIR}/../../.")
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/config.sh"

# end boilerplate

# cd to rootfs dir
cd "${ROOTFS_DIR}" || exit 1

sudo mkdir -p "${ROOTFS_DIR}/opt/workdir"

# setup chroot
echo "Setting up chroot for ${ROOTFS_DIR}"
sudo mount --bind /dev         "${ROOTFS_DIR}/dev"
sudo mount --bind /proc        "${ROOTFS_DIR}/proc"
sudo mount --bind /sys         "${ROOTFS_DIR}/sys"
sudo mount --bind /run         "${ROOTFS_DIR}/run"
sudo mount --bind "${TOP_DIR}" "${ROOTFS_DIR}/opt/workdir"

ROOTFS_CHROOT_BUILD_STEPS=("base-setup")

SKIP_STEPS=()
# specify as "base-setup foo bar"
IFS=' ' read -r -a SKIP_STEPS <<< "${ROOTFS_CHROOT_BUILD_SKIP_STEPS}"

# run each build step
# enter chroot
for STEP in "${ROOTFS_CHROOT_BUILD_STEPS[@]}"; do
  # if current step is in ROOTFS_CHROOT_BUILD_SKIP_STEPS
  if ! [[ " ${SKIP_STEPS[*]} " =~ " ${STEP} " ]]; then
    # run the step
    echo "About to run ${TOP_DIR}/scripts/rootfs/chroot/${STEP}.sh inside the chroot at ${ROOTFS_DIR}"
    # we want ${TOP_DIR} to be literal, but ${STEP} to be replaced
    sudo chroot "${ROOTFS_DIR}" "/opt/workdir/scripts/rootfs/chroot/${STEP}.sh" || exit
  else
    echo "Skipping rootfs chroot build step: ${STEP}"
  fi
done

sudo umount -f "${ROOTFS_DIR}/dev"  || lsof "${ROOTFS_DIR}/dev"
sudo umount -f "${ROOTFS_DIR}/proc" || lsof "${ROOTFS_DIR}/proc"
sudo umount -f "${ROOTFS_DIR}/sys"  || lsof "${ROOTFS_DIR}/sys"
sudo umount -f "${ROOTFS_DIR}/run"  || lsof "${ROOTFS_DIR}/run"
sudo umount -f "${ROOTFS_DIR}/opt/workdir" || lsof "${ROOTFS_DIR}/opt/workdir"

echo "--- end scripts/rootfs/base-setup.sh ---"
