#!/usr/bin/env bash

echo "--- start scripts/rootfs/chroot/depthcharge-tools.sh ---"

#
# check that we're in a chroot
if ! (ischroot)
then
  echo "This script meant to be run within a chroot!"
  exit 1
fi

# debug mode = set -x = loud
DEBUG="${DEBUG:-false}"
if $DEBUG; then
  set -exu
else
  set -eu
fi

# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
DEFAULT_TOP_DIR=$(dirname "${SCRIPT_DIR}/../../../.")
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

cd "${TOP_DIR}" || exit

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/config.sh"

# end boilerplate

pip3 install depthcharge-tools

echo "--- end scripts/rootfs/chroot/depthcharge-tools.sh ---"
