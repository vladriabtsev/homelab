#!/usr/bin/env bash

# shellcheck source=/dev/null
source "${VBASH}/vlib.bash"
vlib.bashly-init-command
# shellcheck source=/dev/null
source "${VBASH}/vkube-k3s.bash"

vkube-k3s.install
