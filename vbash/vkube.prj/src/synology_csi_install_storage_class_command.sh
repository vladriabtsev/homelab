#!/usr/bin/env bash
vlib.bashly-init-command

# shellcheck source=/dev/null
source "${VBASH}/vkube-k3s.bash"
vkube-k3s.command-init

#csi_synology_ver=${args[release]}
csi_synology_storage_class_name=${args[name]}
csi_synology_storage_class_protocol=${args[--protocol]}
csi_synology_storage_class_sinology_ip=${args[--sinology-ip]}
csi_synology_storage_class_volume=${args[--volume]}

vkube-k3s.csi-synology-storage-class-install
