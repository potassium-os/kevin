#!/usr/bin/env bash

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
cd "$SCRIPT_DIR" || exit 1

DEFAULT_TOP_DIR="${SCRIPT_DIR}"
TOP_DIR="${TOP_DIR:-$DEFAULT_TOP_DIR}"

# load common functions
# default variables
. "${TOP_DIR}/scripts/common/config.sh"

# draw box around string for pretty output
. "${TOP_DIR}/scripts/common/drawbox.sh"

LOGO=$(cat <<END

  ╔════════════════════════════╗  
  ║                            ║  
  ║                            ║  
  ║                            ║  
  ║          ██╗  ██╗          ║
  ║          ██║ ██╔╝          ║
  ║          █████╔╝           ║
  ║          ██╔═██╗           ║
  ║          ██║  ██╗          ║
  ║          ╚═╝  ╚═╝          ║  
  ║                            ║  
  ║                            ║  
  ║                            ║  
  ╚════════════════════════════╝  
  Potassium ${VERSION}
  
END
)

echo "${LOGO}"

BUILD_ENV=$(env)

# tell the user what we're about to do
box_out "
Target Name:            ${TARGET_ID}
Target Flavor:          ${TARGET_FLAVOR}
Target Distro:          ${TARGET_DISTRO}
Distro Codename:        ${TARGET_DISTRO_CODENAME}
Rootfs Type:            ${TARGET_ROOT_FS}
Kernel Repo:            ${TARGET_KERNEL_REPO}
Kernel Tag:             ${TARGET_KERNEL_TAG}
Target Distro:          ${TARGET_DISTRO}
Target Distro Codename: ${TARGET_DISTRO_CODENAME}
"

# make the toast
time . "${TOP_DIR}/scripts/container-exec.sh" "/opt/workdir/scripts/build.sh"
