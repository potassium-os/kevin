#!/usr/bin/env bash

echo "--- start scripts/rootfs/chroot/base-setup.sh ---"

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

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/config.sh"

# end boilerplate

#
# set hostname
hostname kevin
echo kevin | tee /etc/hostname

#
# update apt cache
export DEBIAN_FRONTEND=noninteractive
apt-get -yq update

#
# debconf for console-setup
# TODO: this doesn't appear to work as expected
#       possibly because console-setup is already installed
debconf-set-selections -v /etc/preseed/console-setup.conf

# setup /etc/default/console-setup
# this does appear to work properly
cat >/etc/default/console-setup <<"EOF"
ACTIVE_CONSOLES="/dev/tty[1-6]"
CHARMAP="UTF-8"
CODESET="Lat15"
FONTFACE="VGA"
FONTSIZE="16x28"
VIDEOMODE=

EOF

# and finally a dpkg-reconfigure for it to pick up on changes
dpkg-reconfigure -f noninteractive console-setup

#
# debconf for locales
# TODO: this doesn't appear to work as expected either
debconf-set-selections -v /etc/preseed/locales.conf

# so we set it up manually
echo "LANG=\"en_US.UTF-8\"" | tee /etc/default/locale
echo "en_US.UTF-8 UTF-8" | tee -a /etc/locale.gen
echo "C.UTF-8 UTF-8" | tee -a /etc/locale.gen
locale-gen "en_US.UTF-8"

# and finally a dpkg-reconfigure
dpkg-reconfigure -f noninteractive locales

#
# cleanup preseed stuff
rm -rf /etc/preseed

#
# install selected packages
apt-get -yq install "${TARGET_ROOTFS_PACKAGES}"
apt-get -yq install "${TARGET_ROOTFS_EXTRA_PACKAGES}"

#
# install depthcharge-tools from src
cd /root
git clone --depth 1 --branch "${TARGET_ROOTFS_DEPTHCHARGE_TOOLS_TAG}" "${TARGET_ROOTFS_DEPTHCHARGE_REPO}" /root/depthcharge-tools
pip3 install --user -e /root/depthcharge-tools
rm -rf /root/depthcharge-tools
# add python3 to root PATH
# We want this to output $PATH without expansion
# shellcheck disable=SC2016
echo 'PATH="$(python3 -m site --user-base)/bin:\${PATH}"' >> /root/.profile

#
# set root password to potassium
sh -c 'echo root:potassium | chpasswd'

#
# run our target hook
. "${TARGET_CONF_DIR}/rootfs/scripts/base-setup-append.sh"

echo "--- end scripts/rootfs/chroot/base-setup.sh ---"
