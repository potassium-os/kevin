#!/usr/bin/env bash

set -e

# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "$DIRNAME" || exit; pwd)
cd "$SCRIPT_DIR" || exit

POTASSIUM_TOP_DIR="${POTASSIUM_TOP_DIR:-$SCRIPT_DIR}"

BUILDENV_TAG="${BUILDENV_TAG:-"latest"}"

# get a shell inside the build env container, with your workdir mounted in.
docker run --rm -it \
    --volume "$POTASSIUM_TOP_DIR:/opt/workdir:rw" \
    ghcr.io/potassium-os/build-env:${BUILDENV_TAG} \
    /bin/bash
