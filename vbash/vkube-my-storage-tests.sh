#!/usr/bin/env bash

./vkube --cluster-plan k3s-HA k3s storage-speed 'local-path' --distr busybox
./vkube --cluster-plan k3s-HA k3s storage-speed office-csi-driver-smb-del --distr busybox
./vkube --cluster-plan k3s-HA k3s storage-speed office-synology-csi-smb-del --distr busybox
./vkube --cluster-plan k3s-HA k3s storage-speed office-synology-csi-nfs-del --distr busybox
./vkube --cluster-plan k3s-HA k3s storage-speed longhorn-nvme-del --distr busybox
./vkube --cluster-plan k3s-HA k3s storage-speed longhorn-ssd-del --distr busybox

./vkube --cluster-plan k3s-HA k3s storage-speed 'local-path'
./vkube --cluster-plan k3s-HA k3s storage-speed office-csi-driver-smb-del
./vkube --cluster-plan k3s-HA k3s storage-speed office-synology-csi-smb-del
./vkube --cluster-plan k3s-HA k3s storage-speed office-synology-csi-nfs-del
./vkube --cluster-plan k3s-HA k3s storage-speed longhorn-nvme-del
./vkube --cluster-plan k3s-HA k3s storage-speed longhorn-ssd-del

./vkube --cluster-plan k3s-HA k3s storage-speed longhorn-ssd-del
