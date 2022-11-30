#!/usr/bin/env bash

echo "--- start scripts/rootfs/package.sh ---"

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

cd "${DEPLOY_DIR}" || exit 1

function rootfs_ext4() {
  dd if=/dev/zero of="${DEPLOY_DIR}/rootfs.raw" bs=512 count="${DATA_PARTITION_SIZE}" status=progress conv=fsync

  # losetup
  LOOP_DEVICE=$(losetup -f)
  sudo losetup "${LOOP_DEVICE}" "${DEPLOY_DIR}/rootfs.raw"

  # make the filesystem
  sudo mkfs.ext4 "${LOOP_DEVICE}"

  # mount rootfs
  sudo mount "${LOOP_DEVICE}" /mnt

  # tar in rootfs
  sudo tar xvf "${DEPLOY_DIR}/rootfs.tar" -C /mnt

  # tar in kernel modules
  echo "Copying in kernel modules from ${DEPLOY_DIR}/modules"
  sudo mkdir -p /mnt/lib/modules || true
  sudo tar xvf "${DEPLOY_DIR}/kmod.tar" -C /mnt

  # sync & unmount
  sudo umount /mnt
  sudo sync "${LOOP_DEVICE}"
  sudo losetup -d "${LOOP_DEVICE}"
}


# tar rootfs to tar.gz in deploy dir
sudo rm -f "${DEPLOY_DIR}/rootfs.tar"
sudo tar cvf "${DEPLOY_DIR}/rootfs.tar" "${ROOTFS_DIR}"

case "${TARGET_ROOT_FS}" in
  "ext4")
    rootfs_ext4
  ;;

  *)
    echo "Unknown TARGET_ROOT_FS"
    exit 1
esac


echo "--- end scripts/rootfs/package.sh ---"
