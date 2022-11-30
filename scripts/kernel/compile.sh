#!/usr/bin/env bash

echo "--- start scripts/kernel/compile.sh ---"

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

# cd to src dir
cd "${KERNEL_SRC_DIR}" || exit 1

# make toast
time make O="${KERNEL_OUTPUT_DIR}" -j$((`nproc`+2)) all

# setup modules
# first clean out old ones
rm -rfv "${KERNEL_OUTPUT_DIR}/lib/modules"
mkdir -p "${KERNEL_OUTPUT_DIR}/lib/modules"

# then package up new ones
make O="${KERNEL_OUTPUT_DIR}" INSTALL_MOD_PATH="${KERNEL_OUTPUT_DIR}" modules_install

echo "--- end scripts/kernel/compile.sh ---"
