#!/usr/bin/env bash

echo "--- start scripts/kernel/build.sh ---"

# debug mode = set -x = loud
DEBUG="${DEBUG:-false}"
if $DEBUG; then
  set -exu
else
  set -eu
fi

# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "$DIRNAME" || exit; pwd)

DEFAULT_TOP_DIR=`dirname "${SCRIPT_DIR}/../../."`
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

box_out "About to build kernel ${TARGET_KERNEL_TAG}"

# run download.sh
. "${TOP_DIR}/scripts/kernel/download.sh"


echo "--- end scripts/kernel/build.sh ---"
