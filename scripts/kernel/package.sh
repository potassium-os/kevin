#!/usr/bin/env bash

echo "--- start scripts/kernel/package.sh ---"


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

# most of this logic blatently stolen from Cadmium repo

# cd to src dir
cd "${KERNEL_SRC_DIR}" || exit 1

# cd to dst dir
cd "${KERNEL_OUTPUT_DIR}" || exit 1

# cleanup old objects
rm -vf \
  kernel.its \
  cmdline \
  c_linux.lz4 \
  vmlinux.uimg \
  bootloader.bin \
  vmlinux.kpart \
  vmlinux.kpart.pad \
  "${DEPLOY_DIR}/vmlinux.kpart" \
  "${DEPLOY_DIR}/kmod.tar"

cp "${TARGET_CONF_DIR}/kernel/${TARGET_ARCH}.kernel.its" kernel.its
cp "${TARGET_CONF_DIR}/kernel/cmdline" cmdline

# cook a uimg
lz4 -z -f "arch/${TARGET_ARCH}/boot/Image" c_linux.lz4
mkimage -D "-I dts -O dtb -p 2048" -f kernel.its vmlinux.uimg

# make an empty file for bootloader stub
dd if=/dev/zero of=bootloader.bin bs=512 count=1 conv=fsync

# package/sign the kernel
vbutil_kernel \
	--pack vmlinux.kpart \
	--vmlinuz vmlinux.uimg \
	--arch "${TARGET_ARCH}" \
	--keyblock "${TARGET_KERNEL_SIGN_KEYBLOCK}" \
	--signprivate "${TARGET_KERNEL_SIGN_PRIVATE}" \
	--config "${TARGET_CONF_DIR}/kernel/cmdline" \
	--bootloader bootloader.bin

cp vmlinux.kpart "${DEPLOY_DIR}/vmlinux.kpart"

cd "${KERNEL_OUTPUT_DIR}/lib" || exit 1
sudo bsdtar \
  --create \
  --preserve-permissions \
  --numeric-owner \
  --directory="${KERNEL_OUTPUT_DIR}/lib" \
  --verbose \
  --file="${DEPLOY_DIR}/kmod.tar" \
	"./modules"

echo "--- end scripts/kernel/package.sh ---"
