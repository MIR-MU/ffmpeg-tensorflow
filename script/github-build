#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

source ./environment/vars

docker build --compress --no-cache --force-rm --squash -t miratmu/ffmpeg-tensorflow:${DOCKER_TAG} .
