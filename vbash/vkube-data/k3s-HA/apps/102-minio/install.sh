#!/bin/bash
# MinIO install
# ./102-minio/install.sh -s ./k3s-HA.yaml -i v1.7.2
# MinIO uninstall
# ./102-minio/install.sh -u v1.7.2
# MinIO upgrade
# ./102-minio/install.sh -g v1.7.3

source ./../vlib.bash

minio-check-version()
{
  #minio_latest=$(curl -sL https://api.github.com/repos/minio/minio/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  minio_latest=$(curl -sL https://api.github.com/repos/minio/minio/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  minio_ver="$1"
  if [ -z $minio_ver ]; then minio_ver=$minio_latest; fi
  if ! [ -z $2 ]; then
    if ! [ "$minio_latest" == "$minio_ver" ]; then
      warn "Latest version of MinIO: '$minio_latest', but installing: '$minio_ver'\n"
    fi
  fi
}
node_disks()
{
  declare -a -g node_storage_class_array
  declare -a -g node_disk_uuid_array
  declare -a -g node_mnt_path_array
  # https://mikefarah.gitbook.io/yq/usage/tips-and-tricks
  #echo $i_node
  readarray disks < <(yq -o=j -I=0 ".node[$i_node].node_storage[]" < $cluster_plan_file)
  local i_disk=0
  for disk in "${disks[@]}"; do
    eval "$( yq '.[] | ( select(kind == "scalar") | key + "='\''" + . + "'\''")' <<<$disk)"
    node_storage_class_array[i_disk]=$storage_class
    node_disk_uuid_array[i_disk]=$disk_uuid
    node_mnt_path_array[i_disk]=$mnt_path
    ((i_disk++))
  done
  n_disks=$i_disk # Total disks
  # for i in "${node_storage_class_array[@]}"; do
  #   echo $i
  # done
  # for i in "${node_disk_uuid_array[@]}"; do
  #   echo $i
  # done
  # for i in "${node_mnt_path_array[@]}"; do
  #   echo $i
  # done
  case $1 in
    1 )
      hl.blue "$parent_step$((++install_step)). Mount disks on node $node_name($node_ip4). (Line:$LINENO)"

      # Create initial .bak of current fstab file
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'if sudo -S ! test -e /etc/fstab.bak; then cp /etc/fstab /etc/fstab.bak; fi <<< \"$node_root_password\"'"
      # Get local copy of node's fstab
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'sudo -S 'cp /etc/fstab ~/fstab' <<< \"$node_root_password\"'"
      run "line '$LINENO';scp -i ~/.ssh/$cert_name $node_user@$node_ip4:~/fstab ~/fstab"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'sudo -S 'rm ~/fstab' <<< \"$node_root_password\"'"
      run "line '$LINENO';sed -i \"/UUID= /d\" ~/fstab"
      # fstab and mount directories
      for (( i=0; i < n_disks; i++ )); do
        # Delete previous fstab record and append new one
        run "line '$LINENO';sed -i \"/${node_disk_uuid_array[i]}/d\" ~/fstab"
        run "line '$LINENO';echo 'UUID=${node_disk_uuid_array[i]}  ${node_mnt_path_array[$i]} ext4  defaults  0  0' >> ~/fstab"
        # Create mount directory if not exists
        run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo -S sh -c 'if [ ! -e ${node_mnt_path_array[i]} ]; then mkdir ${node_mnt_path_array[i]}; fi' <<< '$node_root_password'\""
      done
      # Copy updated fstab to node
      run "line '$LINENO';scp -i ~/.ssh/$cert_name.pub ~/fstab $node_user@$node_ip4:~/fstab"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo -S mv ~/fstab /etc/fstab <<< '$node_root_password'\""
      # Remount all
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo -S mount -a <<< '$node_root_password'\""

      hl.blue "$parent_step$((++install_step)). Load dm_crypt module on node $node_name($node_ip4). (Line:$LINENO)"
      # https://linovox.com/use-modprobe-command-in-linux/
      # https://www.cyberciti.biz/faq/linux-how-to-load-a-kernel-module-automatically-at-boot-time/
      # https://www.baeldung.com/linux/kernel-module-load-boot
      # sudo systemctl start dm_crypt_load.service
      # sudo systemctl status dm_crypt_load.service
      # sudo systemctl enable dm_crypt_load.service
      # lsmod | grep dm_crypt
      # sudo modprobe dm_crypt
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"if [ ! -e ~/tmp ]; then mkdir ~/tmp; fi\""
      run "line '$LINENO';scp -i ~/.ssh/$cert_name ./101-minio/dm_crypt_load.sh $node_user@$node_ip4:~/tmp/dm_crypt_load.sh"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'chmod 777 ~/tmp/dm_crypt_load.sh'"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name sudo -S sh -c '~/tmp/dm_crypt_load.sh' <<< \"$node_root_password\""
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'rm ~/tmp/dm_crypt_load.sh'"
    ;;
    2 )
      hl.blue "$parent_step$((++install_step)). MinIO node disks config settings for $node_name($node_ip4). (Line:$LINENO)"
      # https://stackoverflow.com/questions/73370812/how-to-add-annotations-to-kubernetes-node-using-patch-file
      # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_patch/
      # patch for node disk settings
      # https://minio.io/docs/archives/1.3.1/advanced-resources/default-disk-and-node-config/#launch-minio-with-multiple-disks

      # https://minio.io/kb/tip-only-use-storage-on-a-set-of-nodes/
      if [[ $n_disks -eq 0 ]]; then
        run "line '$LINENO';kubectl label --overwrite nodes $node_name node.minio.io/create-default-disk=true" # mounted disks are not included
      else
        run "line '$LINENO';kubectl label --overwrite nodes $node_name node.minio.io/create-default-disk='config'" # mounted disks are not included
        local first=1
        local tmp=""
        local tmp2="" # only mounted disks
        #local tmp2="{\"path\":\"/var/lib/minio\",\"allowScheduling\":true}" # mounted disks are not included
        declare -A storage_classes
        for (( i=0; i < n_disks; i++ )); do
          if [[ $first -eq 0 ]]; then
            tmp2="${tmp2}, "
          fi
          tmp="${node_mnt_path_array[$i]}"
          tmpsc="${node_storage_class_array[$i]}"
          # https://documentation.suse.com/cloudnative/storage/1.9.0/en/nodes/default-disk-and-node-config.html
          storage_classes["${tmpsc}"]="${tmpsc}"
          tmp2="${tmp2}{\"path\": \"${tmp}\", \"allowSheduling\":true, \"tags\":[\"${tmpsc}\"]}" # \"storage\",
          first=0
        done
        # https://stackoverflow.com/questions/1494178/how-to-define-hash-tables-in-bash
        tmp=""
        first=1
        for _storage_class in "${!storage_classes[@]}"; do 
          #echo "$_storage_class - ${storage_classes[$_storage_class]}"
          if [[ $first -eq 0 ]]; then
            tmp="${tmp},"
          fi
          tmp="${tmp}\"${_storage_class}\""
          first=0
        done
      fi
      # node minio storage tags
      run "line '$LINENO';kubectl annotate --overwrite nodes $node_name node.minio.io/default-node-tags='[\"storage\",$tmp]'"

      # node minio disk config
      run "line '$LINENO';kubectl annotate --overwrite nodes $node_name node.minio.io/default-disks-config='[$tmp2]'"
      node_disk_config["${node_name}"]="${tmp2}"

# metadata:
#   annotations:
#     node.minio.io:
#       default-disks-config:
#       - path: /mnt/lh01
#         allowSheduling: 'true'
#       - path: /mnt/lh02
#         allowSheduling: 'true'

# kubectl patch node k8s-worker-1 --type merge --patch-file /home/bino/k0s-sriwijaya/minio/lhpatch.yaml

    ;;
    * )
      err_and_exit "Expected parameters: 1 - mount, 2 - generate yaml" ${LINENO};
  esac
}
minio-install-new()
{
  if ! [[ -e ${cluster_plan_file} ]]; then
    err_and_exit "Cluster plan file '${cluster_plan_file}' is not found" ${LINENO};
  fi
  #echo $node_root_password
  if [[ -z $node_root_password ]]; then
    node_root_password=""
    vlib.read-password node_root_password "Please enter root password for cluster nodes:"
    echo
  fi
  if [[ -z $minio_ui_admin_name ]]; then
    minio_ui_admin_name=""
    vlib.read-password minio_ui_admin_name "Please enter MinIO UI admin name:"
    echo
  fi
  if [[ -z $minio_ui_admin_password ]]; then
    minio_ui_admin_password=""
    vlib.read-password minio_ui_admin_password "Please enter MinIO UI admin password:"
    echo
  fi

  declare -A node_disk_config

  readarray nodes < <(yq -o=j -I=0 '.node[]' < $cluster_plan_file)
  i_node=0
  for node in "${nodes[@]}"; do
    eval "$( yq '.[] | ( select(kind == "scalar") | key + "='\''" + . + "'\''")' <<<$node)"
    node_disks 1
    node_disks 2
    ((i_node++))
    if [ $i_node -eq $amount_nodes ]; then break; fi
  done

  #wait-for-success -t 1 "ls ~/"
  #wait-for-success
  #wait-for-success "kubectl wait --for=condition=Ready pod/csi-attacher -n minio-system"
  #wait-for-success -t 1 "kubectl wait --for=condition=Ready pod/csi-attacher -n minio-system"
  #run wait-for-success -t 1 "kubectl wait --for=condition=Ready pod/csi-attacher -n minio-system"
  #run "wait-for-success -t 1 \"kubectl wait --for=condition=Ready pod/csi-attacher -n minio-system\""
  #run "wait-for-success -t 1 'kubectl wait --for=condition=Ready pod/csi-attacher -n minio-system'"
  #exit

  hl.blue "$parent_step$((++install_step)). MinIO installation. (Line:$LINENO)"
  if command kubectl get deploy minio-ui -n minio-system &> /dev/null; then
    err_and_exit "MinIO already installed."  ${LINENO} "$0"
  fi
  # https://minio.io/docs/1.7.2/advanced-resources/minioctl/install-minioctl/
  if ! ($(minioctl version > /dev/null ) || $(minioctl version) != $minio_ver ); then
    # Download the release binary.
    run "line '$LINENO';curl -LO "https://github.com/minio/cli/releases/download/$minio_ver/minioctl-linux-${ARCH}""
    # Download the checksum for your architecture.
    run "line '$LINENO';curl -LO 'https://github.com/minio/cli/releases/download/$minio_ver/minioctl-linux-${ARCH}.sha256'"
    # Verify the downloaded binary matches the checksum.
    run line "$LINENO";echo "$(cat minioctl-linux-${ARCH}.sha256 | awk '{print $1}') minioctl-linux-${ARCH}" | sha256sum --check
    run "line '$LINENO';sudo install minioctl-linux-${ARCH} /usr/local/bin/minioctl;minioctl version"
  fi

  minioctl check preflight
  run.ui.ask "Preflight errors check is finished. Proceed new installation?" || exit 1

  # https://minio.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-the-minio-deployment-yaml-file

  run "line '$LINENO';wget -O ~/tmp/minio.yaml https://raw.githubusercontent.com/minio/minio/$minio_ver/deploy/minio.yaml"
  #run "line '$LINENO';cat ~/tmp/minio.yaml | yq   "
  # https://minio.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-kubectl
  # https://github.com/minio/minio/blob/master/chart/templates/default-setting.yaml
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    create-default-disk-labeled-nodes: true/' ~/tmp/minio.yaml"
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    deleting-confirmation-flag: true/' ~/tmp/minio.yaml"
  run "line '$LINENO';kubectl apply -f ~/tmp/minio.yaml"
  #run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/minio/minio/$minio_ver/deploy/minio.yaml"

  #run "line "$LINENO";kubectl create -f ./101-minio/backup.yaml"

  # https://fabianlee.org/2022/01/27/kubernetes-using-kubectl-to-wait-for-condition-of-pods-deployments-services/

  # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_wait/
  # https://kubernetes.io/docs/reference/kubectl/jsonpath/
  # https://stackoverflow.com/questions/53536907/kubectl-wait-for-condition-complete-timeout-30s
  run "line '$LINENO';vlib.wait-for-success 'kubectl wait --for=condition=ready pod -l app=csi-attacher -n minio-system'"
  # no need if cluster exist run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n minio-system'"
  # not working sometime run "line '$LINENO';wait-for-success 'kubectl rollout status deployment csi-attacher -n minio-system'"

  #helm repo add minio https://charts.minio.io
  #helm repo update
  #helm install minio minio/minio --version 1.7.2 \
  #  --namespace minio-system \
  #  --create-namespace \
  #  --set defaultSettings.createDefaultDiskLabeledNodes=true
  #  --values values.yaml
  #run "helm upgrade minio minio/minio --namespace minio-system --values ./values.yaml --version $minio_ver"

  if ! test -e ~/downloads; then mkdir ~/downloads; fi
  run "line '$LINENO';curl https://raw.githubusercontent.com/minio/minio/$minio_ver/examples/storageclass.yaml -o ~/downloads/storageclass.yaml"
  # ssd storage class
  run "line '$LINENO';yq -i '
    .metadata.name = \"minio-ssd\" |
    .parameters.numberOfReplicas = \"3\" |
    .parameters.staleReplicaTimeout = \"2880\" |
    .parameters.fsType = \"ext4\" |
    .parameters.mkfsParams = \"-I 256 -b 4096 -O ^metadata_csum,^64bit\" |
    .parameters.diskSelector = \"ssd\" |
    .parameters.nodeSelector = \"storage,ssd\"
  ' ~/downloads/storageclass.yaml"
  run "line '$LINENO';kubectl create -f ~/downloads/storageclass.yaml"
  # nvme storage class
  run "line '$LINENO';yq -i '
    .metadata.name = \"minio-nvme\" |
    .parameters.numberOfReplicas = \"3\" |
    .parameters.staleReplicaTimeout = \"2880\" |
    .parameters.fsType = \"ext4\" |
    .parameters.mkfsParams = \"-I 256 -b 4096 -O ^metadata_csum,^64bit\" |
    .parameters.diskSelector = \"nvme\" |
    .parameters.nodeSelector = \"storage,nvme\"
  ' ~/downloads/storageclass.yaml"
  run "line '$LINENO';kubectl create -f ~/downloads/storageclass.yaml"

  hl.blue "$parent_step$((++install_step)). MinIO UI. (Line:$LINENO)"
  # MinIO UI
  # https://github.com/minio/website/blob/master/content/docs/1.8.1/deploy/accessing-the-ui/minio-ingress.md
  # # https://kubernetes.github.io/ingress-nginx/examples/auth/basic/
  # htpasswd -c ${HOME}/tmp/auth $minio_ui_admin_name
  # run "line '$LINENO';echo \"${minio_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${minio_ui_admin_password})\" > ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n minio-system create secret generic basic-auth --from-file=${HOME}/tmp/auth"
  # run "line '$LINENO';rm ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n minio-system apply -f ./101-minio/minio-ui-auth-basic.yaml"

  https://minio.io/docs/1.7.3/deploy/accessing-the-ui/minio-ingress/
  run "line '$LINENO';echo \"${minio_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${minio_ui_admin_password})\" > ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n minio-system create secret generic minio-ui-auth-basic --from-file=${HOME}/tmp/auth"
  run "line '$LINENO';rm ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n minio-system apply -f ./101-minio/minio-ui-auth-basic.yaml"

  run "line '$LINENO';kubectl expose deployment minio-ui --port=80 --type=LoadBalancer --name=minio-ui -n minio-system --target-port=http --load-balancer-ip=192.168.100.101"
  # kubectl expose deployment minio-ui --port=80 --type=LoadBalancer --name=minio-ui -n minio-system --target-port=http --load-balancer-ip=192.168.100.101
  # kubectl -n minio-system get svc
  # kubectl  -n minio-system describe svc minio-ui
  # kubectl delete service minio-ui -n minio-system

  # for node_name in "${!node_disk_config[@]}"; do
  #   echo "${node_name} - '{\"metadata\":{\"annotations\":{\"node.minio.io/default-disks-config\":[${node_disk_config[$node_name]}]}}}'"
  #   run "line '$LINENO';kubectl -n minio-system patch nodes $node_name -p '{\"metadata\":{\"annotations\":{\"node.minio.io/default-disks-config\":[${node_disk_config[$node_name]}]}}}'"
  #   #kubectl -n minio-system patch nodes node-1 -p '{"metadata":{"annotations":{"node.minio.io/default-disks-config":"[{\"path\":\"/var/lib/minio\",\"allowScheduling\":true}]"}}}'
  #   #minio-system patch nodes k3s2 -p '{\"metadata\":{\"annotations\":{\"node.minio.io/default-disks-config\":[${node_disk_config[$node_name]}]}}}'
  # done

  echo "MinIO UI: check all disks on all nodes are available and schedulable !!!"

  #kubectl apply -f ./101-minio/test-pod-with-pvc.yaml

  # Tests
  # kubectl -n minio-system get replicas --output=jsonpath="{.items[?(@.status.volumeName==\"<THE VOLUME NAME YOU ARE CHECKING>\")].metadata.name}"
  # kubectl -n minio-system edit replicas
  # kubectl get volumes.minio.io pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c -o yaml -n minio-system
  # kubectl get replicas.minio.io -n minio-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.minio.io -n minio-system -o yaml
  # kubectl get engines.minio.io -n minio-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.minio.io -n minio-system -o yaml
  # Volumes ????

}
minio-uninstall()
{
  hl.blue "$parent_step$((++install_step)). Uninstalling MinIO. (Line:$LINENO)"

  if ! command kubectl get deploy minio-ui -n minio-system &> /dev/null; then
    err_and_exit "MinIO not installed yet."  ${LINENO} "$0"
  fi

  if ! command kubectl get deploy -l app.kubernetes.io/version=$minio_ver -n minio-system &> /dev/null; then
    err_and_exit "Trying uninstall MinIO version '$minio_ver', but this version is not installed."  ${LINENO} "$0"
  fi

  # minio_installed_ver=$( minioctl version )
  # if ! [ $minio_installed_ver == $minio_ver ]; then
  #   err_and_exit "Trying uninstall MinIO version '$minio_ver', but expected '$minio_installed_ver'."  ${LINENO} "$0"
  # fi

  # manually deleting stucked-namespace
  #kubectl get namespace "minio-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/minio-system/finalize -f -
  #kubectl get namespace "stucked-namespace" -o json \
  #  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  #  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

  # minio deleting-confirmation-flag
  # kubectl get lhs -n minio-system
  # can be edit in k9s or apply deleting-confirmation-flag.yaml
  local dir="$(dirname "$0")"
  #run "line $LINENO;kubectl -n minio-system patch -p '{\"value\": \"true\"}' --type=merge lhs deleting-confirmation-flag"
  #run "line $LINENO;helm uninstall minio -n minio-system"
  #run "line $LINENO;kubectl apply -f ./101-minio/deleting-confirmation-flag.yaml"

  run "line $LINENO;kubectl create -f https://raw.githubusercontent.com/minio/minio/$minio_ver/uninstall/uninstall.yaml"
  #kubectl get job/minio-uninstall -n minio-system -w

  # https://medium.com/@sirtcp/how-to-resolve-stuck-kubernetes-namespace-deletions-by-cleaning-finalizers-38190bf3165f
  # Get all resorces
  #kubectl api-resources
  # Get all resorces for namespace
  #kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n minio-system

  # kubectl wait --for jsonpath='{.status.state}'=AtLatestKnown sub mysub -n myns --timeout=3m
  #run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=complete job/minio-uninstall -n minio-system'"
  run "line '$LINENO';kubectl wait --for=condition=complete job/minio-uninstall -n minio-system --timeout=5m"
  #run "line '$LINENO';wait-for-success \"kubectl get job/minio-uninstall -n minio-system -o jsonpath='{.status.conditions[?(@.type==\"Complete\")].status}' | grep True\""

  # crd_array=(backingimagedatasources backingimagemanagers backingimages backupbackingimages backups backuptargets /
  #   backupvolumes engineimages engines instancemanagers nodes orphans recurringjobs replicas settings sharemanagers /
  #   snapshots supportbundles systembackups systemrestores volumeattachments volumes)
  # for crd in "${crd_array[@]}"; do
  #   run "line '$LINENO';kubectl patch crd $crd -n minio-system -p '{"metadata":{"finalizers":[]}}' --type=merge"
  #   run "line '$LINENO';kubectl delete crd $crd -n minio-system"
  #   #run "line '$LINENO';kubectl delete crd $crd"
  # done

  run "line '$LINENO';kubectl delete namespace minio-system"
  run "line '$LINENO';kubectl delete storageclass minio-ssd"
  run "line '$LINENO';kubectl delete storageclass minio-nvme"

exit

  local wait_time=0
  local wait_period=10
  local wait_timeout=300
  until kubectl get job/minio-uninstall -n minio-system -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' | grep True > /dev/null; 
  do 
    sleep $wait_period
    ((wait_time+=wait_period))
    if [[ $wait_time -gt $wait_timeout ]]; then
      err_and_exit "Timeout. Wait time $wait_time sec"  ${LINENO} "$0"
    fi
  done
  run "line '$LINENO';kubectl delete deployment minio-ui -n minio-system"
  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/minio/minio/$minio_ver/uninstall/uninstall.yaml"

  local wait_time=0
  local wait_period=30
  local wait_timeout=600
  until ! command -v kubectl get pod -o json -n minio-system | jq '.items | length' &> /dev/null;  
  do 
    sleep $wait_period
    ((wait_time+=wait_period))
    echo $wait_time
    if [[ $wait_time -gt $wait_timeout ]]; then
      err_and_exit "Timeout. Wait time $wait_time sec"  ${LINENO} "$0"
    fi
  done

  #kubectl patch crd <custome-resource-definition-name> -n <namespace> -p '{"metadata":{"finalizers":[]}}' --type=merge
  #kubectl delete crd <custome-resource-definition-name> -n <namespace>
  #run "line '$LINENO';kubectl -n minio-system delete crd nodes"

  run "line '$LINENO';kubectl delete namespace minio-system"
}
minio-upgrade()
{
  minio-backup

  run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/minio/minio/$minio_ver/deploy/minio.yaml"
  run "line '$LINENO';vlib.wait-for-success 'kubectl rollout status deployment minio-driver-deployer -n minio-system'"
  run "line '$LINENO';vlib.wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n minio-system --timeout=5m'"

  # if timeout when upgrade
  minio-restore
}
minio-backup()
{
  # https://minio.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://minio.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/create-a-backup-via-csi/
  echo kuku
}
minio-restore()
{
  # https://minio.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://minio.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/restore-a-backup-via-csi/#restore-a-backup-that-has-no-associated-volumesnapshot
  echo kuku
}
check-minio-exclusive-params()
{
  if [[ minio_number_exclusive_params -gt 0 ]]; then
    err_and_exit "Only one exclusive operation is allowed"  ${LINENO} "$0"
  fi
}

################################
##         M A I N            ##
################################
NO_ARGS=0 
E_OPTERROR=85

parent_step=""

[[ -f ~/.bashmatic/init.sh ]] || {
  echo "Can't find or install Bashmatic. Exiting."
  exit 1
}
source ~/.bashmatic/init.sh

usage="Usage: `basename $0` [OPTION]...
MinIO installation script.

Options:
  -o # show output of executed commands, not show is default
  -v # bashmatic verbose
  -d # bashmatic debug
  -w nodeRootPassword # need if called from parent script
  -t parentScriptStep # need if called from parent script
  -s cluster_plan.yaml # cluster plan for new installation
Exclusive operation options:
  -i version # Install MinIO version on current default cluster
  -u version # Uninstall MinIO version on current default cluster
  -g version # Upgrade MinIO to version on current default cluster
  -b # backup MinIO
  -r # restore MinIO
  cluster_plan.yaml # cluster plan settings
"
if [ $# -eq "$NO_ARGS" ] # Script invoked with no command-line args?
then
  err "Script invoked with no command-line args\n"
  printf "$usage"
  exit $E_OPTERROR # Exit and explain usage.
  # Usage: scriptname -options
  # Note: dash (-) necessary
fi
minio_number_exclusive_params=0
plan_is_provided=0
if ! [[ -z $cluster_plan_file ]]; then 
  $plan_is_provided=1; 
fi
while getopts "ovdhs:w:t:i:u:g:" opt
do
  case $opt in
    s )
      if [[ $plan_is_provided -eq 1 ]]; then err_and_exit "Cluster plan is provided already" ${LINENO} "$0"; fi
      cluster_plan_file="$OPTARG"
      plan_is_provided=1
      vlib.cluster_plan_read
    ;;
    w )
      node_root_password="$OPTARG"
    ;;
    t )
      parent_step="$OPTARG."
    ;;
    i )
      if [[ $plan_is_provided -eq 0 ]]; then err_and_exit "Cluster plan is not provided" ${LINENO} "$0"; fi
      if [[ $minio_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((minio_number_exclusive_params++))
      minio-check-version "$OPTARG" 1
      minio-install-new
    ;;
    u )
      if [[ $minio_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((minio_number_exclusive_params++))
      minio-check-version "$OPTARG"
      minio-uninstall
    ;;
    g )
      if [[ $minio_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((minio_number_exclusive_params++))
      minio-check-version "$OPTARG"
      minio-upgrade
    ;;
    b ) 
      if [[ $minio_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((minio_number_exclusive_params++))
      # https://github.com/minio/minio/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/minio/minio/blob/master/enhancements/20220913-minio-system-backup-restore.md
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      minio-backup
    ;;
    r ) 
      if [[ $minio_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((minio_number_exclusive_params++))
      # https://github.com/minio/minio/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/minio/minio/blob/master/enhancements/20220913-minio-system-backup-restore.md
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      minio-restore
    ;;
    o ) opt_show_output='show-output-on'
      if [[ $minio_number_exclusive_params -gt 0 ]]; then err_and_exit "-o has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
      run.set-all abort-on-error show-command-on $opt_show_output
    ;;
    #v ) verbose-on
    #  if [[ $minio_number_exclusive_params -gt 0 ]]; then err_and_exit "-v has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
    #;;
    #d ) debug-on
    #  if [[ $minio_number_exclusive_params -gt 0 ]]; then err_and_exit "-d has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
    #;;
    h ) echo $usage
    exit 1
    ;;
    \? ) echo 'For help: ./install.sh -h'
    exit 1
    ;;
  esac
done
#shift $((OPTIND-1))

exit


# https://minio.io/docs/1.7.2/deploy/install/install-with-kubectl/
hl.blue "$parent_step$((++install_step)). Install MinIO. (Line:$LINENO)"
minio_latest=$(curl -sL https://api.github.com/repos/minio/minio/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
if [ -z $minio_ver ]; then
  minio_ver=$minio_latest
fi
if ! [ "$minio_latest" == "$minio_ver" ]; then
  warn "Latest version of MinIO: '$minio_latest', but installing: '$minio_ver'\n"
fi
run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/minio/minio/$minio_ver/deploy/minio.yaml"
# https://minio.io/docs/1.7.2/advanced-resources/minioctl/install-minioctl/
if ! ($(minioctl version > /dev/null ) || $(minioctl version) != $minio_ver ); then
  # Download the release binary.
  run "line '$LINENO';curl -LO "https://github.com/minio/cli/releases/download/$minio_ver/minioctl-linux-${ARCH}""
  # Download the checksum for your architecture.
  run line '$LINENO';curl -LO "https://github.com/minio/cli/releases/download/$minio_ver/minioctl-linux-${ARCH}.sha256"
  # Verify the downloaded binary matches the checksum.
  run line '$LINENO';echo "$(cat minioctl-linux-${ARCH}.sha256 | awk '{print $1}') minioctl-linux-${ARCH}" | sha256sum --check
  run line '$LINENO';sudo install minioctl-linux-${ARCH} /usr/local/bin/minioctl;minioctl version
fi

# Step 11: Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

# Step 12: Add Rancher Helm Repository
helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
kubectl create namespace cattle-system

# Step 13: Install Cert-Manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
--namespace cert-manager \
--create-namespace \
--version v1.13.2
kubectl get pods --namespace cert-manager

# Step 14: Install Rancher
helm install rancher rancher-latest/rancher \
 --namespace cattle-system \
 --set hostname=rancher.my.org \
 --set bootstrapPassword=admin
kubectl -n cattle-system rollout status deploy/rancher
kubectl -n cattle-system get deploy rancher

# Step 15: Expose Rancher via Loadbalancer
kubectl get svc -n cattle-system
kubectl expose deployment rancher --name=rancher-lb --port=443 --type=LoadBalancer -n cattle-system
kubectl get svc -n cattle-system

# Profit: Go to Rancher GUI
echo -e " \033[32;5mHit the url… and create your account\033[0m"
echo -e " \033[32;5mBe patient as it downloads and configures a number of pods in the background to support the UI (can be 5-10mins)\033[0m"

# Step 16: Install MinIO (using modified Official to pin to MinIO Nodes)
echo -e " \033[32;5mInstalling MinIO - It can take a while for all pods to deploy...\033[0m"
kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/MinIO/minio.yaml
kubectl get pods \
--namespace minio-system \
--watch

# Step 17: Print out confirmation

kubectl get nodes
kubectl get svc -n minio-system

echo -e " \033[32;5mHappy Kubing! Access MinIO through Rancher UI\033[0m"
