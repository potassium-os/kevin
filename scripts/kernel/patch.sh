#!/usr/bin/env bash

echo "--- start scripts/kernel/patch.sh ---"

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
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/defaults.sh"

# end boilerplate

# cd to src dir
cd "${KERNEL_SRC_DIR}" || exit 1

# apply patches
for x in $(ls ${TARGET_CONF_DIR}/kernel/patches/*.patch); do
	echo "Applying $x"
	patch -p1 --forward < $x || true
done

echo "--- end scripts/kernel/patch.sh ---"
