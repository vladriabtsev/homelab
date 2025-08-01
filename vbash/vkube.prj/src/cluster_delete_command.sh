#!/usr/bin/env bash

vlib.bashly-init-command

# shellcheck source=/dev/null
source "${VBASH}/vkube-lib.bash"
vkube-lib.command-init

#echo "      vkube-lib.install()" >&3
vkube-lib.delete
