#!/usr/bin/env bash

echo "--- start scripts/kernel/download.sh ---"

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

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/defaults.sh"

# draw box around string for pretty output
. "${TOP_DIR}/scripts/common/drawbox.sh"

if ! command -v git &> /dev/null
then
    box_out "git is required for downloading kernel sources"
    exit 1
fi

KERNEL_SRC_DIR="${TMP_DIR}/${TARGET}/kernel-${TARGET_KERNEL_TAG}"

# if kernel src dir doesn't exist
# or if CLEAN_KERNEL_DOWNLOAD=true
if ([[ ! -d "${KERNEL_SRC_DIR}" ]] && [[ ! -L "${KERNEL_SRC_DIR}" ]]) || $CLEAN_KERNEL_DOWNLOAD
then
  # if it's CLEAN_KERNEL_DOWNLOAD, warn the user
  if $CLEAN_KERNEL_DOWNLOAD
  then
    box_out "CLEAN_KERNEL_DOWNLOAD is set, running \"rm -rf ${TMP_DIR}/${TARGET}/kernel-${TARGET_KERNEL_TAG}\""
    rm -rf "${TMP_DIR}/${TARGET}/kernel-${TARGET_KERNEL_TAG}"
  fi

  box_out "${KERNEL_SRC_DIR} does not exist, downloading kernel"

  mkdir -p "${KERNEL_SRC_DIR}"
  . "${TARGET_CONF_DIR}/kernel/build-hooks/pre-download.sh"
  # --depth 1 implies --single-branch
  git clone \
    --depth 1 \
    --branch "${TARGET_KERNEL_TAG}" \
    "${TARGET_KERNEL_REPO}" \
    "${KERNEL_SRC_DIR}"
  . "${TARGET_CONF_DIR}/kernel/build-hooks/post-download.sh"
fi

echo "--- end scripts/kernel/download.sh ---"
