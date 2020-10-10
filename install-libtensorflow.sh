#!/bin/bash
set -e

apt-get update -qq
apt-get -y --no-install-recommends install wget
wget -O - https://storage.googleapis.com/tensorflow/libtensorflow/"$1".tar.gz | tar xzvC /usr/local
rm -rf /var/lib/apt/lists/*
