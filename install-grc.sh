#!/bin/bash

# Install GRC - generic colorizer
# https://github.com/garabik/grc

set -e

echo ">> Installing GRC..."

if [ -d /usr/share/grc ]; then
  echo "GRC is already installed."
  exit 0
fi

sudo mkdir -p /usr/share/grc
sudo git clone https://github.com/garabik/grc.git /usr/share/grc

cd /usr/share/grc
sudo chmod +x install.sh
# install.sh sources itself, run in subshell to isolate
sudo bash install.sh

echo ">> GRC colorizer installed."
