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
dd if=/dev/zero of="${IMAGE_NAME}" bs=1M count="${TARGET_IMAGE_SIZE}" status=progress conv=fsync

# losetup
LOOP_DEVICE=$(losetup -f)
sudo losetup "${LOOP_DEVICE}" "${IMAGES_DIR}/${IMAGE_NAME}"

# stolen from cadmium
# make partition table
sudo parted --script "${LOOP_DEVICE}" mklabel gpt # cgpt dislikes if i don't do that, so do that

# now this is _real_ partition table
# 73728 comes from: size of kernel partition(65536) + beginning of kernel partition(8192)
# 139264 comes from: size of B kernel partition(65536) + beginning of B kernel partition(73728)
sudo cgpt create "${LOOP_DEVICE}"
sudo cgpt add -i 1 -t kernel -b 8192		-s 65536 -l KernelA -S 1 -T 2 -P 10 "${LOOP_DEVICE}"
sudo cgpt add -i 2 -t kernel -b 73728	  -s 65536 -l KernelB -S 0 -T 2 -P  5 "${LOOP_DEVICE}"
sudo cgpt add -i 3 -t data   -b 139264  -s $(expr $(cgpt show "${LOOP_DEVICE}" | grep 'Sec GPT table' | awk '{print $1}') - 139264) -l Root "${LOOP_DEVICE}"
sudo sync
sudo partx -a "${LOOP_DEVICE}" >/dev/null 2>&1 || true # fails if something else added partitions
sudo sync

# dd in kernels
sudo dd if="${DEPLOY_DIR}/vmlinux-${BUILT_KERNEL_ID}.kpart" of="${LOOP_DEVICE}p1" bs=32M conv=notrunc
sudo dd if="${DEPLOY_DIR}/vmlinux-${BUILT_KERNEL_ID}.kpart" of="${LOOP_DEVICE}p2" bs=32M conv=notrunc

# mkfs
sudo mkfs.ext4 "${LOOP_DEVICE}p3"

# mount
sudo mount "${LOOP_DEVICE}p3" /mnt

# cp in rootfs
sudo cp -prv "${ROOTFS_DIR}"/* /mnt/

# cp in kernel modules
sudo cp -prv "${DEPLOY_DIR}/modules/${BUILT_KERNEL_ID}" /mnt/var/lib/modules/

# sync & unmount
sudo sync

sudo umount /mnt

sudo losetup -d "${LOOP_DEVICE}"
# done?

echo "--- end scripts/image/build-depthcharge.sh ---"
