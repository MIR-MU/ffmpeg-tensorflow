#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

source ./environment/vars

docker tag miratmu/ffmpeg-tensorflow:"${DOCKER_TAG}" miratmu/ffmpeg-tensorflow:latest
docker push miratmu/ffmpeg-tensorflow:"${DOCKER_TAG}"
docker push miratmu/ffmpeg-tensorflow:latest
