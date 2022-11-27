#!/bin/false

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
cd "$SCRIPT_DIR" || exit

DEFAULT_TOP_DIR=`dirname "${SCRIPT_DIR}/../../."`
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit; pwd)

# default TOP_DIR to SCRIPT_DIR
TOP_DIR="${TOP_DIR:-$SCRIPT_DIR}"

# where target config files and etc live
TARGETS_DIR="${TOP_DIR}/targets"

# default target
DEFAULT_TARGET="kevin"
TARGET="${TARGET:-$DEFAULT_TARGET}"

# target config dir
TARGET_CONF_DIR="${TARGETS_DIR}/${TARGET}"

# where we store build files
TMP_DIR="${TOP_DIR}/tmp"

# where to copy output files to
OUTPUT_DIR="${TOP_DIR}/output"

# do we rm -rf tmp/kernel/$TARGET before downloading?
CLEAN_KERNEL_DOWNLOAD="${CLEAN_KERNEL_DOWNLOAD:-false}"

# do we rm -rf tmp/uboot/$TARGET before downloading?
CLEAN_UBOOT_DOWNLOAD="${CLEAN_UBOOT_DOWNLOAD:-false}"

# load our target config
. "${TARGET_CONF_DIR}/target.conf"
