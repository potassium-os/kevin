#!/usr/bin/env bash

echo "--- start targets/kevin-lunar-cmdline/rootfs/scripts/chroot/base-setup-append.sh ---"

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

# Your setup here
# see scripts/rootfs/chroot/base-setup.sh for more info

echo "--- end targets/kevin-lunar-cmdline/rootfs/scripts/chroot/base-setup-append.sh ---"
