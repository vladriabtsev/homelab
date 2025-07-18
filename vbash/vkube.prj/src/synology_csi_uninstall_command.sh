#!/usr/bin/env bash
vlib.bashly-init-command

# shellcheck source=/dev/null
source "${VBASH}/vkube-k3s.bash"
vkube-k3s.command-init

#csi_synology_ver=${args[release]}
#csi_synology_secret_folder=${args[--secret-folder]}
csi_synology_snapshot_use=${args[--snapshot]}

vkube-k3s.check-cluster-plan-path
vkube-k3s.csi-synology-uninstall
