#!/usr/bin/env bash
vlib.bashly-init-command

# shellcheck source=/dev/null
source "${VBASH}/vkube-lib.bash"
vkube-lib.command-init

#csi_synology_ver=${args[release]}
#csi_synology_secret_folder=${args[--secret-folder]}
#csi_synology_snapshot_use=${args[--snapshot]}

vkube-lib.check-cluster-plan-path
vkube-lib.app-install "${args[container-name]}"
