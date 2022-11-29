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
. "${TOP_DIR}/scripts/common/defaults.sh"

# end boilerplate

# cd to deployment dir
cd "${IMAGES_DIR}" || exit 1

# identify our built kernel id (differs slightly from git tag)
BUILT_KERNEL_ID=$(ls "${KERNEL_OUTPUT_DIR}/lib/modules/")

# create image
BUILD_TIME=$(date '+%F-%H%M')
IMAGE_NAME="${TARGET_ID}-${BUILD_TIME}.img"
dd if=/dev/zero of="${IMAGE_NAME}" bs=1M count="$((${TARGET_IMAGE_SIZE} + 10))" status=progress conv=fsync

# losetup
LOOP_DEVICE=$(losetup -f)
sudo losetup "${LOOP_DEVICE}" "${IMAGES_DIR}/${IMAGE_NAME}"



# now this is _real_ partition table
# 73728 comes from: size of kernel partition(65536) + beginning of kernel partition(8192)
# 139264 comes from: size of B kernel partition(65536) + beginning of B kernel partition(73728)

# convert MB to B
TARGET_IMAGE_SIZE_KBYTES=$(( TARGET_IMAGE_SIZE * 1024 ))

TARGET_IMAGE_SIZE_SECTORS=$(( TARGET_IMAGE_SIZE_KBYTES * 2 ))

# kevin: 65536 = 32MiB @ 512KiB sectors
KERNEL_PARTITION_SIZE=$(( 65536 ))

# kevin: 4MiB offset
KERNEL_A_PARTITION_START=$(( 8192 ))

# kevin: 73728 sector offset
KERNEL_B_PARTITION_START=$(( KERNEL_A_PARTITION_START + KERNEL_PARTITION_SIZE ))

# kevin: 139264 sector offset
DATA_PARTITION_START=$(( KERNEL_B_PARTITION_START + KERNEL_PARTITION_SIZE ))

# 2GiB: 1957888 sectors remaining space in image
DATA_PARTITION_SIZE=$(( TARGET_IMAGE_SIZE_SECTORS - DATA_PARTITION_START ))

# 4075487

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
sudo losetup "${LOOP_DEVICE}" "${IMAGES_DIR}/${IMAGE_NAME}"

sudo partprobe "${LOOP_DEVICE}"

# wait a few for the kernel partition table to settle
sleep 5

# dd in kernels
sudo dd if="${DEPLOY_DIR}/vmlinux-${BUILT_KERNEL_ID}.kpart" of="${LOOP_DEVICE}p1" bs=32M conv=notrunc
sudo dd if="${DEPLOY_DIR}/vmlinux-${BUILT_KERNEL_ID}.kpart" of="${LOOP_DEVICE}p2" bs=32M conv=notrunc

# mkfs
sudo mkfs.ext4 "${LOOP_DEVICE}p3"

# mount
sudo mount "${LOOP_DEVICE}p3" /mnt

# cp in rootfs
sudo cp --remove-destination -fprv "${ROOTFS_DIR}"/* /mnt/

# cp in kernel modules
echo "Copying in kernel modules from ${DEPLOY_DIR}/modules/${BUILT_KERNEL_ID}"
sudo mkdir -p /mnt/lib/modules || true
sudo cp --remove-destination -fprv "${DEPLOY_DIR}/modules/${BUILT_KERNEL_ID}" "/mnt/lib/modules/${BUILT_KERNEL_ID}"

# sync & unmount
sudo umount /mnt

sudo sync "${LOOP_DEVICE}"

sudo losetup -d "${LOOP_DEVICE}"
# done?

echo "--- end scripts/image/build-depthcharge.sh ---"
