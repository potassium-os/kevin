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

# identify our built kernel id (differs slightly from git tag)
BUILT_KERNEL_ID=$(ls "${KERNEL_OUTPUT_DIR}/lib/modules/")

# create image
dd if=/dev/zero of="${TARGET_IMAGE_NAME}" bs=1M count="$((${TARGET_IMAGE_SIZE} + 10))" status=progress conv=fsync

# losetup
LOOP_DEVICE=$(losetup -f)
sudo losetup "${LOOP_DEVICE}" "${IMAGES_DIR}/${TARGET_IMAGE_NAME}"

echo "TARGET_IMAGE_SIZE_KBYTES=${TARGET_IMAGE_SIZE_KBYTES}"
echo "DATA_PARTITION_START=${DATA_PARTITION_START}"
echo "DATA_PARTITION_SIZE=${DATA_PARTITION_SIZE}"

# stolen from cadmium
# make partition table
sudo parted --script "${LOOP_DEVICE}" mklabel gpt # cgpt dislikes if i don't do that, so do that
sudo partprobe "${LOOP_DEVICE}"

sudo cgpt create "${LOOP_DEVICE}"
sudo partprobe "${LOOP_DEVICE}"

# first kernel partition
sudo cgpt add -i 1 -t kernel -b "${KERNEL_A_PARTITION_START}" -s "${KERNEL_PARTITION_SIZE}" -l KernelA "${LOOP_DEVICE}" -S 1 -T 2 -P 10

# second kernel partition
sudo cgpt add -i 2 -t kernel -b "${KERNEL_B_PARTITION_START}" -s "${KERNEL_PARTITION_SIZE}" -l KernelB "${LOOP_DEVICE}" -S 0 -T 2 -P  5

# data partition
sudo cgpt add -i 3 -t rootfs   -b "${DATA_PARTITION_START}"     -s "${DATA_PARTITION_SIZE}"   -l Root    "${LOOP_DEVICE}"

# sync
sudo sync "${LOOP_DEVICE}"

# wait a few for the kernel partition table to settle
sleep 5

# drop the loop device
sudo losetup -d "${LOOP_DEVICE}"

# wait a few for the kernel partition table to settle
sleep 5

# and pick it back up
LOOP_DEVICE=$(losetup -f)
sudo losetup "${LOOP_DEVICE}" "${IMAGES_DIR}/${TARGET_IMAGE_NAME}"

sudo partprobe "${LOOP_DEVICE}"

# wait a few for the kernel partition table to settle
sleep 5

# dd in kernels
sudo dd if="${DEPLOY_DIR}/vmlinux.kpart" of="${LOOP_DEVICE}p1" bs=32M conv=fsync,notrunc status=progress
sudo dd if="${DEPLOY_DIR}/vmlinux.kpart" of="${LOOP_DEVICE}p2" bs=32M conv=fsync,notrunc status=progress

# and the rootfs
sudo dd if="${DEPLOY_DIR}/rootfs.raw" of="${LOOP_DEVICE}p3" bs=512 conv=fsync,notrunc

# cleanup the loop device
sudo sync "${LOOP_DEVICE}"
sudo losetup -d "${LOOP_DEVICE}"

# and we're done

echo "--- end scripts/image/build-depthcharge.sh ---"
