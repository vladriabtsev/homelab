#!/usr/bin/env bash

vlib.bashly-init-command

# shellcheck source=/dev/null
source "${VBASH}/vkube-k3s.bash"
vkube-k3s.check-cluster-plan-path
vkube-k3s.install
