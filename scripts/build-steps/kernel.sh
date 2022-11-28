#!/usr/bin/env bash

echo "--- start scripts/build-steps/kernel.sh ---"

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

echo "About to build kernel ${TARGET_KERNEL_TAG} for ${TARGET_ARCH}"

KERNEL_BUILD_STEPS=("download" "patch" "configure" "compile" "package")

KERNEL_BUILD_SKIP_STEPS="${KERNEL_BUILD_SKIP_STEPS:-\"\"}"

SKIP_STEPS=()
# specify as "download patch"
IFS=' ' read -r -a SKIP_STEPS <<< "${KERNEL_BUILD_SKIP_STEPS}"

# run each build step
for STEP in "${KERNEL_BUILD_STEPS[@]}"; do
  # if current step is in KERNEL_BUILD_SKIP_STEPS
  if ! [[ " ${SKIP_STEPS[*]} " =~ " ${STEP} " ]]; then
    # run the step
    echo "About to run ${TOP_DIR}/scripts/kernel/${STEP}.sh"
    . "${TOP_DIR}/scripts/kernel/${STEP}.sh"
  else
    echo "Skipping kernel build step: ${STEP}"
  fi
done

echo "--- end scripts/build-steps/kernel.sh ---"
