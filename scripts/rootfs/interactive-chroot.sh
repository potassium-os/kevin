#!/usr/bin/env bash

# this file isn't a build step
# it's meant to be used interactivly

echo "--- start scripts/rootfs/interactive-chroot.sh ---"

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

# setup chroot

# setup chroot
echo "Setting up chroot for ${ROOTFS_DIR}"
sudo mkdir -p "${ROOTFS_DIR}/opt/workdir/scripts"
sudo mkdir -p "${ROOTFS_DIR}/opt/workdir/targets"

# sudo mount --bind /dev         "${ROOTFS_DIR}/dev"
# sudo mount --bind /proc        "${ROOTFS_DIR}/proc"
# sudo mount --bind /sys         "${ROOTFS_DIR}/sys"
# sudo mount --bind /run         "${ROOTFS_DIR}/run"
sudo mount --bind -o ro "${TOP_DIR}/scripts" "${ROOTFS_DIR}/opt/workdir/scripts"
sudo mount --bind -o ro "${TOP_DIR}/targets" "${ROOTFS_DIR}/opt/workdir/targets"

# enter chroot
sudo chroot "${ROOTFS_DIR}" /bin/bash --login

# when that exits, cleanup
# sudo umount -f "${ROOTFS_DIR}/dev"  || lsof "${ROOTFS_DIR}/dev"
# sudo umount -f "${ROOTFS_DIR}/proc" || lsof "${ROOTFS_DIR}/proc"
# sudo umount -f "${ROOTFS_DIR}/sys"  || lsof "${ROOTFS_DIR}/sys"
# sudo umount -f "${ROOTFS_DIR}/run"  || lsof "${ROOTFS_DIR}/run"
sudo umount -f "${ROOTFS_DIR}/opt/workdir/scripts" || lsof "${ROOTFS_DIR}/opt/workdir/scripts"
sudo umount -f "${ROOTFS_DIR}/opt/workdir/targets" || lsof "${ROOTFS_DIR}/opt/workdir/targets"

echo "--- end scripts/rootfs/interactive-chroot.sh ---"
