#!/usr/bin/env bash
#inspect_args

# shellcheck source=/dev/null
source "${VBASH}/vlib.bash"
vlib.trace "$(inspect_args)"

vlib.bashly-init-command
# shellcheck source=/dev/null
source "${VBASH}/vkube-k3s.bash"

vkube-k3s.csi-synology-install
