#!/usr/bin/env bash
./vkube --cluster-plan k3s-HA k3s storage-speed --storage-class 'local-path'
./vkube --cluster-plan k3s-HA k3s storage-speed --storage-class office-csi-driver-smb-tmp
./vkube --cluster-plan k3s-HA k3s storage-speed --storage-class office-synology-csi-smb-tmp
./vkube --cluster-plan k3s-HA k3s storage-speed --storage-class office-synology-csi-nfs-tmp
./vkube --cluster-plan k3s-HA k3s storage-speed --storage-class longhorn-nvme
./vkube --cluster-plan k3s-HA k3s storage-speed --storage-class longhorn-ssd
