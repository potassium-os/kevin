#!/usr/bin/env bash

echo "--- start build.sh ---"

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

DEFAULT_TOP_DIR=$(dirname "${SCRIPT_DIR}/../.")
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/config.sh"

# build steps to run (in order)
BUILD_STEPS=("kernel" "rootfs" "image")

# are we skipping any build steps?
# ex BUILD_SKIP_STEPS="uboot rootfs" ./build.sh
SKIP_STEPS=()
IFS=' ' read -r -a SKIP_STEPS <<< "${BUILD_SKIP_STEPS}"

MYUID=$(id)
echo "Running as [ ${MYUID} ]"

CLEAN_BUILD="${CLEAN_BUILD:-"false"}"
if [[ "${CLEAN_BUILD}" == "cleanall" ]]; then
  echo "--- CLEAN_BUILD is set, running \"rm -rfv ${TOP_DIR}/tmp\""
  sudo rm -rfv "${TOP_DIR}/tmp"
fi

# run each build step
for STEP in "${BUILD_STEPS[@]}"; do
  # if current step is NOT in KERNEL_BUILD_SKIP_STEPS
  if ! [[ " ${SKIP_STEPS[*]} " =~ " ${STEP} " ]]; then
    # run the step
    echo "About to run ${TOP_DIR}/scripts/build-steps/${STEP}.sh"
    . "${TOP_DIR}/scripts/build-steps/${STEP}.sh"
  else
    echo "Skipping build step: ${STEP}"
  fi
done

echo "--- end build.sh ---"
