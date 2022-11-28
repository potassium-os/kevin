#!/usr/bin/env bash

echo "--- start scripts/image/build.sh ---"

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

case "${TARGET_BOOTLOADER}" in
  "depthcharge")
    . "${TOP_DIR}/scripts/iamge/build-depthcharge.sh"
  ;;

  *)
    echo "Unknown TARGET_BOOTLOADER"
    exit 1
esac

echo "--- end scripts/image/build.sh ---"
