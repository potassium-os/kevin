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

DEFAULT_TOP_DIR=$(dirname "${SCRIPT_DIR}/../../.")
DEFAULT_TOP_DIR=$(cd "$DEFAULT_TOP_DIR" || exit 1; pwd)
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/config.sh"

# end boilerplate

# cd to rootfs dir
cd "${ROOTFS_DIR}" || exit 1

# setup chroot
sudo mount --bind /dev  "${ROOTFS_DIR}/dev"
sudo mount --bind /proc "${ROOTFS_DIR}/proc"
sudo mount --bind /sys  "${ROOTFS_DIR}/sys"
sudo mount --bind /run  "${ROOTFS_DIR}/run"

# enter chroot
# substutions below will be filled in outside of the chroot
# so no need to carry envvars inside of it
sudo chroot "${ROOTFS_DIR}" /bin/bash << END

echo "--- start scripts/rootfs/base-setup.sh chroot sub-script in ${ROOTFS_DIR} ---"

#
# debug mode = set -x = loud
DEBUG="${DEBUG:-false}"
if $DEBUG; then
  set -exu
else
  set -eu
fi

#
# set hostname
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
apt-get -yq install ${TARGET_ROOTFS_PACKAGES}
apt-get -yq install ${TARGET_ROOTFS_EXTRA_PACKAGES}

#
# install depthcharge-tools
cd /root
git clone --depth 1 --branch ${TARGET_ROOTFS_DEPTHCHARGE_TOOLS_TAG} ${TARGET_ROOTFS_DEPTHCHARGE_REPO} /root/depthcharge-tools
pip3 install --user -e /root/depthcharge-tools
rm -rf /root/depthcharge-tools
echo 'PATH="$(python3 -m site --user-base)/bin:\${PATH}"' >> /root/.profile

#
# set root password to root
sh -c 'echo root:potassium | chpasswd'

#
# create nonroot user and set password to ubuntu
useradd ubuntu || true
usermod -a -G sudo ubuntu
sh -c 'echo ubuntu:potassium | chpasswd'

echo "--- end scripts/rootfs/base-setup.sh chroot sub-script in ${ROOTFS_DIR}---"

END

sudo umount -f "${ROOTFS_DIR}/dev"  || lsof "${ROOTFS_DIR}/dev"
sudo umount -f "${ROOTFS_DIR}/proc" || lsof "${ROOTFS_DIR}/proc"
sudo umount -f "${ROOTFS_DIR}/sys"  || lsof "${ROOTFS_DIR}/sys"
sudo umount -f "${ROOTFS_DIR}/run"  || lsof "${ROOTFS_DIR}/run"

echo "--- end scripts/rootfs/base-setup.sh ---"
