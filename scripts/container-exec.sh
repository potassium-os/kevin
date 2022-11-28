#!/usr/bin/env bash

set -e

# If the script wasn't sourced we need to set DIRNAME and SCRIPT_DIR
if ! (return 0 2>/dev/null)
then
  # where this .sh file lives
  DIRNAME=$(dirname "$0")
  SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
fi

DEFAULT_TOP_DIR=`dirname "${SCRIPT_DIR}/../."`
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/defaults.sh"

BUILDENV_TAG="${BUILDENV_TAG:-"latest"}"

docker run --rm -it \
  --volume "$TOP_DIR:/opt/workdir:rw" \
  --env TARGET="${TARGET}" \
  --env CLEAN_BUILD="${CLEAN_BUILD}" \
  --env BUILD_SKIP_STEPS="${BUILD_SKIP_STEPS}" \
  --env KERNEL_BUILD_SKIP_STEPS="${KERNEL_BUILD_SKIP_STEPS}" \
  --env ROOTFS_BUILD_SKIP_STEPS="${ROOTFS_BUILD_SKIP_STEPS}" \
  "ghcr.io/potassium-os/build-env-${TARGET_DISTRO}:${BUILDENV_TAG}" \
    /bin/bash -c "${@}"
