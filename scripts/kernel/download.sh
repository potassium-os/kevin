#!/usr/bin/env bash

echo "--- start scripts/kernel/download.sh ---"

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

# check for git
if ! command -v git &> /dev/null
then
    echo "git is required for downloading kernel sources"
    exit 1
fi

# if it's CLEAN_KERNEL_DOWNLOAD, warn the user
if $CLEAN_KERNEL_DOWNLOAD
then
  echo "CLEAN_KERNEL_DOWNLOAD is set, running \"rm -rf ${SRC_DIR}/kernel-${TARGET_KERNEL_TAG}\""
  rm -rf "${SRC_DIR}/kernel-${TARGET_KERNEL_TAG}"
fi

# if kernel src dir doesn't exist
# or if CLEAN_KERNEL_DOWNLOAD=true
if [[ ! -d "${KERNEL_SRC_DIR}" ]] && [[ ! -L "${KERNEL_SRC_DIR}" ]]; then
  echo "${KERNEL_SRC_DIR} does not exist, downloading kernel source"

  rm -rf "${SRC_DIR}/kernel-${TARGET_KERNEL_TAG}"

  # clone the repo
  # --depth 1 implies --single-branch
  git clone \
    --depth 1 \
    --branch "${TARGET_KERNEL_TAG}" \
    "${TARGET_KERNEL_REPO}" \
    "${KERNEL_SRC_DIR}"
  
  cd "${KERNEL_SRC_DIR}" || exit 1
fi

if $UPDATE_KERNEL_SOURCES; then
  echo "UPDATE_KERNEL_SOURCES is set, updating kernel source in ${KERNEL_SRC_DIR}"
  cd "${KERNEL_SRC_DIR}" || exit 1

  # pull in changes
  # TODO: make this better
  git pull
fi

echo "--- end scripts/kernel/download.sh ---"
