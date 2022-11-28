#!/usr/bin/env bash

echo "--- start scripts/rootfs/debootstrap.sh ---"

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

# cd to rootfs dir
cd "${ROOTFS_DIR}" || exit 1

# get a shell inside the build env container, with your workdir mounted in.
docker run --rm -it \
    --volume "$POTASSIUM_TOP_DIR:/opt/workdir:rw" \
    "${TARGET_DEBOOTSTRAP_HELPER_CONTAINER}" \
    /bin/bash -c "set -exu && debootstrap ${TARGET_DISTRO_CODENAME} ${ROOTFS_DIR}"

echo "--- end scripts/rootfs/debootstrap.sh ---"