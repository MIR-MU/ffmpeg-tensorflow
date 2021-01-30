#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset
set -o xtrace

# update packages & install requirements
sudo apt-get -qy update
sudo apt-get -qy install moreutils

# enable Dockers experimental features
if [[ -z "${DOCKER_CONFIG}" ]]; then
  export DOCKER_CONFIG="${TEMPORARY_DIRECTORY}/docker.$(date +%s)"
  mkdir -p ${DOCKER_CONFIG}
  touch ${DOCKER_CONFIG}/config.json
fi

sudo sh -c "jq -s 'add' ${DOCKER_CONFIG}/config.json ./.docker/config.json | sponge ${DOCKER_CONFIG}/config.json"
sudo sh -c "jq . ./.docker/daemon.json | sponge /etc/docker/daemon.json"
sudo service docker restart
