#!/usr/bin/env bash

echo "--- start scripts/kernel/configure.sh ---"

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

DEFAULT_TOP_DIR=`dirname "${SCRIPT_DIR}/../../."`
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/defaults.sh"

# end boilerplate

# cd to src dir
cd "${KERNEL_SRC_DIR}" || exit 1

# clean things up
make O="${KERNEL_OUTPUT_DIR}" -j$((`nproc`+0)) mrproper
make O="${KERNEL_OUTPUT_DIR}" -j$((`nproc`+0)) distclean

# make defconfig
make O="${KERNEL_OUTPUT_DIR}" defconfig

# cd to dest dir
cd "${KERNEL_OUTPUT_DIR}" || exit 1

# merge in our diffconfig
"${KERNEL_SRC_DIR}/scripts/kconfig/merge_config.sh" "${KERNEL_OUTPUT_DIR}/.config" "${TARGET_CONF_DIR}/kernel/diffconfig"

cp "${KERNEL_OUTPUT_DIR}/.config" "${KERNEL_OUTPUT_DIR}/.config.old"

# fix up the actual config from our new .config
make O="${KERNEL_OUTPUT_DIR}" oldconfig

echo "--- end scripts/kernel/configure.sh ---"
