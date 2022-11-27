#!/bin/false

# debug mode = set -x = loud
DEBUG="${DEBUG:-false}"
if $DEBUG; then
  set -exu
else
  set -eu
fi

# If the script wasn't sourced we eed to set DIRNAME and SCRIPT_DIR
if ! (return 0 2>/dev/null)
then
  # where this .sh file lives
  DIRNAME=$(dirname "$0")
  SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
fi

DEFAULT_TOP_DIR=`dirname "${SCRIPT_DIR}/../../."`
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)

# default TOP_DIR to SCRIPT_DIR
TOP_DIR="${TOP_DIR:-$SCRIPT_DIR}"

# setup version (used in logo, lol)
VERSION="$(cd ${TOP_DIR} && git rev-parse HEAD)"

if [[ $(git diff --stat) != '' ]]; then
  VERSION="${VERSION}-dirty"
fi

# where target config files and etc live
TARGETS_DIR="${TOP_DIR}/targets"

# default target
DEFAULT_TARGET="kevin"
TARGET="${TARGET:-$DEFAULT_TARGET}"

# target config dir
TARGET_CONF_DIR="${TARGETS_DIR}/${TARGET}"

# where we store build files
TMP_DIR="${TOP_DIR}/tmp/${TARGET}"
mkdir -p "${TMP_DIR}"

# where to put sources
SRC_DIR="${TMP_DIR}/src"
mkdir -p "${SRC_DIR}"

# where to copy output files to
OUTPUT_DIR="${TMP_DIR}/dst"
mkdir -p "${OUTPUT_DIR}"

# do we rm -rf tmp/kernel/$TARGET before downloading?
CLEAN_KERNEL_DOWNLOAD="${CLEAN_KERNEL_DOWNLOAD:-false}"

# do we run "git pull" on the kernel repo dir?
UPDATE_KERNEL_SOURCES="${UPDATE_KERNEL_SOURCES:-false}"

# do we rm -rf tmp/uboot/$TARGET before downloading?
CLEAN_UBOOT_DOWNLOAD="${CLEAN_UBOOT_DOWNLOAD:-false}"

# load our target config
. "${TARGET_CONF_DIR}/target.conf"

# arch and cross_compile vars for make
ARCH="${TARGET_ARCH}"
CROSS_COMPILE="${TARGET_CROSS_COMPILE}"
export ARCH="${TARGET_ARCH}"
export CROSS_COMPILE="${TARGET_CROSS_COMPILE}"

KERNEL_SRC_DIR="${SRC_DIR}/kernel-${TARGET_KERNEL_TAG}"
KERNEL_OUTPUT_DIR="${OUTPUT_DIR}/kernel-${TARGET_KERNEL_TAG}"
