# potassium
Full Linux on Kevin

This repo defines targets and is a metarepo for other required things.

## Envvars you need/want to set (with defaults):

```bash
# Your target
# Currently only kevin is supported,
# and it will remain the default
TARGET="kevin"
# Target config (ex targets/kevin/target.conf)
# is read fairly early in the build process.
# You can specify things there instead of at runtime

# debug mode
# all it does right now is turn on
# set -x
DEBUG=false

# default TOP_DIR to where build.sh lives
TOP_DIR="${TOP_DIR:-$SCRIPT_DIR}"

# where we store build files
# you may want to override this to a tmpfs if your storage is slow
# and you have an assload of ram
BUILD_DIR="${TOP_DIR}/build"

# where to copy output files to
OUTPUT_DIR="${TOP_DIR}/output"

# do we rm -rf tmp/kernel/$TARGET before downloading?
CLEAN_KERNEL_DOWNLOAD="${CLEAN_KERNEL_DOWNLOAD:-false}"

# do we rm -rf tmp/uboot/$TARGET before downloading?
CLEAN_UBOOT_DOWNLOAD="${CLEAN_UBOOT_DOWNLOAD:-false}"

```
