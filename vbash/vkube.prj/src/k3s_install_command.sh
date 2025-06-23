#!/usr/bin/env bash
#inspect_args
#echo "$(inspect_args)" >&3

vlib.bashly-init-command
vlib.trace "$(inspect_args)"

# shellcheck source=/dev/null
source "${VBASH}/vkube-k3s.bash"
#echo "      vkube-k3s.install()" >&3
vkube-k3s.install
