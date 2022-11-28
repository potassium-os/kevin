#!/usr/bin/env bash

echo "--- start scripts/rootfs/base-setup.sh ---"

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

# setup chroot
sudo mount --rbind /dev "${ROOTFS_DIR}/dev"
sudo mount --rbind /proc  "${ROOTFS_DIR}/proc"
sudo mount --rbind /sys  "${ROOTFS_DIR}/sys"
sudo mount --rbind /run  "${ROOTFS_DIR}/run"

# enter chroot
sudo chroot "{ROOTFS_DIR}" /bin/bash << END
set -eu
echo "--- start scripts/rootfs/base-setup.sh chroot in ${ROOTFS_DIR} ---"

# setup the hostname
hostname kevin
echo "kevin" > /etc/hostname

# install some packages
apt-get -yq update
apt-get -yq install \
  locales \
  console-setup \
  git \
  curl \
  wget \
  network-manager \
  u-boot-tools \
  vboot-utils \
  cgpt \
  parted \
  gdisk \
  f2fs-tools \
  libudev-dev

# ???

echo "--- end scripts/rootfs/base-setup.sh chroot in ${ROOTFS_DIR}---"

END

sudo umount "${ROOTFS_DIR}/dev"
sudo umount "${ROOTFS_DIR}/proc"
sudo umount "${ROOTFS_DIR}/sys"
sudo umount "${ROOTFS_DIR}/run"

echo "--- end scripts/rootfs/base-setup.sh ---"
