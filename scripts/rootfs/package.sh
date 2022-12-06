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

cd "${ROOTFS_DIR}" || exit 1

# tar rootfs to tar.gz in deploy dir
sudo rm -vf "${DEPLOY_DIR}/rootfs.tar"

cd "${ROOTFS_DIR}" || exit 1
sudo bsdtar \
  --create \
  --preserve-permissions \
  --numeric-owner \
  --directory="${ROOTFS_DIR}" \
  --exclude "./dev" \
  --exclude "./proc" \
  --exclude "./sys" \
  --exclude "./run" \
  --exclude "./opt/workdir/potassium" \
  --verbose \
  --file="${DEPLOY_DIR}/rootfs.tar" .

# create the root filesystem image
rm -vf "${DEPLOY_DIR}/rootfs.${TARGET_ROOT_FS}"
dd \
  bs=512 \
  if=/dev/zero \
  of="${DEPLOY_DIR}/rootfs.${TARGET_ROOT_FS}" \
  count="$(( DATA_PARTITION_SIZE - 512 ))" \
  status=progress \
  conv=fsync

# setup the rootfs
case "${TARGET_ROOT_FS}" in
  "ext4")
    # losetup the image
    LOOP_DEVICE=$(sudo losetup -f)
    sudo losetup "${LOOP_DEVICE}" "${DEPLOY_DIR}/rootfs.${TARGET_ROOT_FS}"
    sudo mkfs.ext4 "${LOOP_DEVICE}"

    # mount the image to /mnt
    sudo mount "${LOOP_DEVICE}" /mnt || exit
    cd /mnt || exit

    # untar in rootfs
    sudo bsdtar \
      --extract \
      --verbose \
      --preserve-permissions \
      --same-owner \
      --numeric-owner \
      --directory="/mnt" \
      --file="${DEPLOY_DIR}/rootfs.tar" \
    || exit

    # ensure our modules dir is created
    sudo mkdir -p /mnt/usr/lib/modules
    # untar in kernel modules
    sudo bsdtar \
      --extract \
      --verbose \
      --preserve-permissions \
      --same-owner \
      --numeric-owner \
      --directory="/mnt/usr/lib" \
      --file="${DEPLOY_DIR}/kmod.tar" \
    || exit

    # get out of /mnt and umount it
    cd "${DEPLOY_DIR}" || exit
    sudo umount /mnt
  ;;

  # TODO: squashfs
  *)
    echo "Unknown TARGET_ROOT_FS"
    exit 1
esac


echo "--- end scripts/rootfs/package.sh ---"
