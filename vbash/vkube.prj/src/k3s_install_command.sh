#!/usr/bin/env bash

vlib.bashly-init-command

# shellcheck source=/dev/null
source "${VBASH}/vkube-k3s.bash"
vkube-k3s.command-init

#echo "      vkube-k3s.install()" >&3
vkube-k3s.install
