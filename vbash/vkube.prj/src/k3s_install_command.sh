#!/usr/bin/env bash
#inspect_args

vlib.bashly-init-command
vlib.trace "$(inspect_args)"

# shellcheck source=/dev/null
source "${VBASH}/vkube-k3s.bash"
vkube-k3s.install
