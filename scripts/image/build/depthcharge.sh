#!/usr/bin/env bash

# called by build.sh in this dir

echo "--- start scripts/image/build/depthcharge.sh ---"

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
  bs=512 \
  if=/dev/zero \
  of="${IMAGES_DIR}/${TARGET_IMAGE_NAME}" \
  count="${TARGET_IMAGE_SIZE_SECTORS}" \
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

# first kernel partition
sudo cgpt \
  add -i 1 -S 1 -T 2 -P 10 \
  -t kernel \
  -b "${KERNEL_A_PARTITION_START}" \
  -s "${KERNEL_PARTITION_SIZE}" \
  -l KernelA \
  "${LOOP_DEVICE}" \
  || exit

sleep 5

# second kernel partition
sudo cgpt \
  add -i 2 -S 1 -T 2 -P 5 \
  -t kernel \
  -b "${KERNEL_B_PARTITION_START}" \
  -s "${KERNEL_PARTITION_SIZE}" \
  -l KernelB \
  "${LOOP_DEVICE}" \
  || exit

sleep 5

# data partition
sudo cgpt \
  add -i 3 \
  -t data \
  -b "${DATA_PARTITION_START}" \
  -s "${DATA_PARTITION_SIZE}" \
  -l Root \
  "${LOOP_DEVICE}" \
  || exit

sleep 5

# sync
sudo sync "${LOOP_DEVICE}"

# partprobe twice
sleep 5
sudo partprobe "${LOOP_DEVICE}"
sleep 5
sudo partprobe "${LOOP_DEVICE}"

ls -alh /dev/loop*

# dd in kernels
sudo dd \
  bs=512 \
  if="${DEPLOY_DIR}/vmlinux.kpart" \
  of="${LOOP_DEVICE}p1" \
  conv=fsync \
  status=progress \
  || exit

# partprobe again
sleep 5
sudo partprobe "${LOOP_DEVICE}"

sudo dd \
  bs=512 \
  if="${DEPLOY_DIR}/vmlinux.kpart" \
  of="${LOOP_DEVICE}p2" \
  conv=fsync \
  status=progress \
  || exit

# partprobe again
sleep 5
sudo partprobe "${LOOP_DEVICE}"

# and rootfs
sudo dd \
  bs=512 \
  if="${DEPLOY_DIR}/rootfs.${TARGET_ROOT_FS}" \
  of="${LOOP_DEVICE}p3" \
  conv=fsync \
  status=progress \
  || exit

# cleanup the loop device
sudo sync "${LOOP_DEVICE}"
sudo losetup -d "${LOOP_DEVICE}"

# and we're done

echo "--- end scripts/image/build/depthcharge.sh ---"
