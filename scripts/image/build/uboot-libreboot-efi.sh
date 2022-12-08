#!/usr/bin/env bash

# called by build.sh in this dir

echo "--- start scripts/image/build-depthcharge.sh ---"

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

# cd to deployment dir
cd "${IMAGES_DIR}" || exit 1

# create image
dd \
  bs=1M \
  if=/dev/zero \
  of="${IMAGES_DIR}/${TARGET_IMAGE_NAME}" \
  count="${TARGET_IMAGE_SIZE}" \
  status=progress \
  conv=fsync

# losetup
LOOP_DEVICE=$(sudo losetup -f)
sudo losetup "${LOOP_DEVICE}" "${IMAGES_DIR}/${TARGET_IMAGE_NAME}"

# stolen from cadmium
# make partition table
sudo parted --script "${LOOP_DEVICE}" mklabel gpt # cgpt dislikes if i don't do that, so do that
sleep 5
sudo partprobe "${LOOP_DEVICE}"

sudo cgpt create "${LOOP_DEVICE}"
sleep 5
sudo partprobe "${LOOP_DEVICE}"

# create partitions
sgdisk --zap-all "${LOOP_DEVICE}"

# ESP and /boot
sgdisk "-n1:${TARGET_PARTITION_OFFSET}:+${TARGET_ESP_SIZE}" "-t1:EF02" "${LOOP_DEVICE}"

# root filesystem
sgdisk "-n2:0:0" "-t1:8300" "${LOOP_DEVICE}"

# sync
sudo sync "${LOOP_DEVICE}"

# partprobe twice
sleep 5
sudo partprobe "${LOOP_DEVICE}"
sleep 5
sudo partprobe "${LOOP_DEVICE}"

ls -alh /dev/loop*

# create fat32 on esp
mkdosfs -F 32 -s 1 -n EFI "${LOOP_DEVICE}p1"

# mount esp
mkdir /mnt/boot
mount "${LOOP_DEVICE}p1" /mnt/boot

# copy in kernel efi stub
cp -pv "${DEPLOY_DIR}/linux.efi" /mnt/boot/

# done here, unmount
umount /mnt/boot

# dd in our rootfs
sudo dd \
  bs=512 \
  if="${DEPLOY_DIR}/rootfs.${TARGET_ROOT_FS}" \
  of="${LOOP_DEVICE}p2" \
  conv=fsync \
  status=progress \
  || exit

# cleanup the loop device
sudo sync "${LOOP_DEVICE}"
sudo losetup -d "${LOOP_DEVICE}"

# and we're done

echo "--- end scripts/image/build-depthcharge.sh ---"
