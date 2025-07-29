#!/bin/bash
# Gitea install
# ./103-gitea/install.sh -s ./k3s-ha.yaml -i v1.7.2
# Gitea uninstall
# ./103-gitea/install.sh -u v1.7.2
# Gitea upgrade
# ./103-gitea/install.sh -g v1.7.3

source ./../vlib.bash

gitea-check-version()
{
  #gitea_latest=$(curl -sL https://api.github.com/repos/gitea/gitea/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  gitea_latest=$(curl -sL https://api.github.com/repos/gitea/gitea/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  gitea_ver="$1"
  if [ -z $gitea_ver ]; then gitea_ver=$gitea_latest; fi
  if ! [ -z $2 ]; then
    if ! [ "$gitea_latest" == "$gitea_ver" ]; then
      warn "Latest version of Gitea: '$gitea_latest', but installing: '$gitea_ver'\n"
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
      run "line '$LINENO';scp -i ~/.ssh/$cert_name ./101-gitea/dm_crypt_load.sh $node_user@$node_ip4:~/tmp/dm_crypt_load.sh"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'chmod 777 ~/tmp/dm_crypt_load.sh'"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name sudo -S sh -c '~/tmp/dm_crypt_load.sh' <<< \"$node_root_password\""
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'rm ~/tmp/dm_crypt_load.sh'"
    ;;
    2 )
      hl.blue "$parent_step$((++install_step)). Gitea node disks config settings for $node_name($node_ip4). (Line:$LINENO)"
      # https://stackoverflow.com/questions/73370812/how-to-add-annotations-to-kubernetes-node-using-patch-file
      # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_patch/
      # patch for node disk settings
      # https://gitea.io/docs/archives/1.3.1/advanced-resources/default-disk-and-node-config/#launch-gitea-with-multiple-disks

      # https://gitea.io/kb/tip-only-use-storage-on-a-set-of-nodes/
      if [[ $n_disks -eq 0 ]]; then
        run "line '$LINENO';kubectl label --overwrite nodes $node_name node.gitea.io/create-default-disk=true" # mounted disks are not included
      else
        run "line '$LINENO';kubectl label --overwrite nodes $node_name node.gitea.io/create-default-disk='config'" # mounted disks are not included
        local first=1
        local tmp=""
        local tmp2="" # only mounted disks
        #local tmp2="{\"path\":\"/var/lib/gitea\",\"allowScheduling\":true}" # mounted disks are not included
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
      # node gitea storage tags
      run "line '$LINENO';kubectl annotate --overwrite nodes $node_name node.gitea.io/default-node-tags='[\"storage\",$tmp]'"

      # node gitea disk config
      run "line '$LINENO';kubectl annotate --overwrite nodes $node_name node.gitea.io/default-disks-config='[$tmp2]'"
      node_disk_config["${node_name}"]="${tmp2}"

# metadata:
#   annotations:
#     node.gitea.io:
#       default-disks-config:
#       - path: /mnt/lh01
#         allowSheduling: 'true'
#       - path: /mnt/lh02
#         allowSheduling: 'true'

# kubectl patch node k8s-worker-1 --type merge --patch-file /home/bino/k0s-sriwijaya/gitea/lhpatch.yaml

    ;;
    * )
      err_and_exit "Expected parameters: 1 - mount, 2 - generate yaml" ${LINENO};
  esac
}
gitea-install-new()
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
  if [[ -z $gitea_ui_admin_name ]]; then
    gitea_ui_admin_name=""
    vlib.read-password gitea_ui_admin_name "Please enter Gitea UI admin name:"
    echo
  fi
  if [[ -z $gitea_ui_admin_password ]]; then
    gitea_ui_admin_password=""
    vlib.read-password gitea_ui_admin_password "Please enter Gitea UI admin password:"
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
  #wait-for-success "kubectl wait --for=condition=Ready pod/csi-attacher -n gitea-system"
  #wait-for-success -t 1 "kubectl wait --for=condition=Ready pod/csi-attacher -n gitea-system"
  #run wait-for-success -t 1 "kubectl wait --for=condition=Ready pod/csi-attacher -n gitea-system"
  #run "wait-for-success -t 1 \"kubectl wait --for=condition=Ready pod/csi-attacher -n gitea-system\""
  #run "wait-for-success -t 1 'kubectl wait --for=condition=Ready pod/csi-attacher -n gitea-system'"
  #exit

  hl.blue "$parent_step$((++install_step)). Gitea installation. (Line:$LINENO)"
  if command kubectl get deploy gitea-ui -n gitea-system &> /dev/null; then
    err_and_exit "Gitea already installed."  ${LINENO} "$0"
  fi
  # https://gitea.io/docs/1.7.2/advanced-resources/giteactl/install-giteactl/
  if ! ($(giteactl version > /dev/null ) || $(giteactl version) != $gitea_ver ); then
    # Download the release binary.
    run "line '$LINENO';curl -LO "https://github.com/gitea/cli/releases/download/$gitea_ver/giteactl-linux-${ARCH}""
    # Download the checksum for your architecture.
    run "line '$LINENO';curl -LO 'https://github.com/gitea/cli/releases/download/$gitea_ver/giteactl-linux-${ARCH}.sha256'"
    # Verify the downloaded binary matches the checksum.
    run line "$LINENO";echo "$(cat giteactl-linux-${ARCH}.sha256 | awk '{print $1}') giteactl-linux-${ARCH}" | sha256sum --check
    run "line '$LINENO';sudo install giteactl-linux-${ARCH} /usr/local/bin/giteactl;giteactl version"
  fi

  giteactl check preflight
  run.ui.ask "Preflight errors check is finished. Proceed new installation?" || exit 1

  # https://gitea.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-the-gitea-deployment-yaml-file

  run "line '$LINENO';wget -O ~/tmp/gitea.yaml https://raw.githubusercontent.com/gitea/gitea/$gitea_ver/deploy/gitea.yaml"
  #run "line '$LINENO';cat ~/tmp/gitea.yaml | yq   "
  # https://gitea.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-kubectl
  # https://github.com/gitea/gitea/blob/master/chart/templates/default-setting.yaml
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    create-default-disk-labeled-nodes: true/' ~/tmp/gitea.yaml"
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    deleting-confirmation-flag: true/' ~/tmp/gitea.yaml"
  run "line '$LINENO';kubectl apply -f ~/tmp/gitea.yaml"
  #run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/gitea/gitea/$gitea_ver/deploy/gitea.yaml"

  #run "line "$LINENO";kubectl create -f ./101-gitea/backup.yaml"

  # https://fabianlee.org/2022/01/27/kubernetes-using-kubectl-to-wait-for-condition-of-pods-deployments-services/

  # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_wait/
  # https://kubernetes.io/docs/reference/kubectl/jsonpath/
  # https://stackoverflow.com/questions/53536907/kubectl-wait-for-condition-complete-timeout-30s
  run "line '$LINENO';vlib.wait-for-success 'kubectl wait --for=condition=ready pod -l app=csi-attacher -n gitea-system'"
  # no need if cluster exist run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n gitea-system'"
  # not working sometime run "line '$LINENO';wait-for-success 'kubectl rollout status deployment csi-attacher -n gitea-system'"

  #helm repo add gitea https://charts.gitea.io
  #helm repo update
  #helm install gitea gitea/gitea --version 1.7.2 \
  #  --namespace gitea-system \
  #  --create-namespace \
  #  --set defaultSettings.createDefaultDiskLabeledNodes=true
  #  --values values.yaml
  #run "helm upgrade gitea gitea/gitea --namespace gitea-system --values ./values.yaml --version $gitea_ver"

  if ! test -e ~/downloads; then mkdir ~/downloads; fi
  run "line '$LINENO';curl https://raw.githubusercontent.com/gitea/gitea/$gitea_ver/examples/storageclass.yaml -o ~/downloads/storageclass.yaml"
  # ssd storage class
  run "line '$LINENO';yq -i '
    .metadata.name = \"gitea-ssd\" |
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
    .metadata.name = \"gitea-nvme\" |
    .parameters.numberOfReplicas = \"3\" |
    .parameters.staleReplicaTimeout = \"2880\" |
    .parameters.fsType = \"ext4\" |
    .parameters.mkfsParams = \"-I 256 -b 4096 -O ^metadata_csum,^64bit\" |
    .parameters.diskSelector = \"nvme\" |
    .parameters.nodeSelector = \"storage,nvme\"
  ' ~/downloads/storageclass.yaml"
  run "line '$LINENO';kubectl create -f ~/downloads/storageclass.yaml"

  hl.blue "$parent_step$((++install_step)). Gitea UI. (Line:$LINENO)"
  # Gitea UI
  # https://github.com/gitea/website/blob/master/content/docs/1.8.1/deploy/accessing-the-ui/gitea-ingress.md
  # # https://kubernetes.github.io/ingress-nginx/examples/auth/basic/
  # htpasswd -c ${HOME}/tmp/auth $gitea_ui_admin_name
  # run "line '$LINENO';echo \"${gitea_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${gitea_ui_admin_password})\" > ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n gitea-system create secret generic basic-auth --from-file=${HOME}/tmp/auth"
  # run "line '$LINENO';rm ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n gitea-system apply -f ./101-gitea/gitea-ui-auth-basic.yaml"

  https://gitea.io/docs/1.7.3/deploy/accessing-the-ui/gitea-ingress/
  run "line '$LINENO';echo \"${gitea_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${gitea_ui_admin_password})\" > ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n gitea-system create secret generic gitea-ui-auth-basic --from-file=${HOME}/tmp/auth"
  run "line '$LINENO';rm ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n gitea-system apply -f ./101-gitea/gitea-ui-auth-basic.yaml"

  run "line '$LINENO';kubectl expose deployment gitea-ui --port=80 --type=LoadBalancer --name=gitea-ui -n gitea-system --target-port=http --load-balancer-ip=192.168.100.101"
  # kubectl expose deployment gitea-ui --port=80 --type=LoadBalancer --name=gitea-ui -n gitea-system --target-port=http --load-balancer-ip=192.168.100.101
  # kubectl -n gitea-system get svc
  # kubectl  -n gitea-system describe svc gitea-ui
  # kubectl delete service gitea-ui -n gitea-system

  # for node_name in "${!node_disk_config[@]}"; do
  #   echo "${node_name} - '{\"metadata\":{\"annotations\":{\"node.gitea.io/default-disks-config\":[${node_disk_config[$node_name]}]}}}'"
  #   run "line '$LINENO';kubectl -n gitea-system patch nodes $node_name -p '{\"metadata\":{\"annotations\":{\"node.gitea.io/default-disks-config\":[${node_disk_config[$node_name]}]}}}'"
  #   #kubectl -n gitea-system patch nodes node-1 -p '{"metadata":{"annotations":{"node.gitea.io/default-disks-config":"[{\"path\":\"/var/lib/gitea\",\"allowScheduling\":true}]"}}}'
  #   #gitea-system patch nodes k3s2 -p '{\"metadata\":{\"annotations\":{\"node.gitea.io/default-disks-config\":[${node_disk_config[$node_name]}]}}}'
  # done

  echo "Gitea UI: check all disks on all nodes are available and schedulable !!!"

  #kubectl apply -f ./101-gitea/test-pod-with-pvc.yaml

  # Tests
  # kubectl -n gitea-system get replicas --output=jsonpath="{.items[?(@.status.volumeName==\"<THE VOLUME NAME YOU ARE CHECKING>\")].metadata.name}"
  # kubectl -n gitea-system edit replicas
  # kubectl get volumes.gitea.io pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c -o yaml -n gitea-system
  # kubectl get replicas.gitea.io -n gitea-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.gitea.io -n gitea-system -o yaml
  # kubectl get engines.gitea.io -n gitea-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.gitea.io -n gitea-system -o yaml
  # Volumes ????

}
gitea-uninstall()
{
  hl.blue "$parent_step$((++install_step)). Uninstalling Gitea. (Line:$LINENO)"

  if ! command kubectl get deploy gitea-ui -n gitea-system &> /dev/null; then
    err_and_exit "Gitea not installed yet."  ${LINENO} "$0"
  fi

  if ! command kubectl get deploy -l app.kubernetes.io/version=$gitea_ver -n gitea-system &> /dev/null; then
    err_and_exit "Trying uninstall Gitea version '$gitea_ver', but this version is not installed."  ${LINENO} "$0"
  fi

  # gitea_installed_ver=$( giteactl version )
  # if ! [ $gitea_installed_ver == $gitea_ver ]; then
  #   err_and_exit "Trying uninstall Gitea version '$gitea_ver', but expected '$gitea_installed_ver'."  ${LINENO} "$0"
  # fi

  # manually deleting stucked-namespace
  #kubectl get namespace "gitea-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/gitea-system/finalize -f -
  #kubectl get namespace "stucked-namespace" -o json \
  #  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  #  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

  # gitea deleting-confirmation-flag
  # kubectl get lhs -n gitea-system
  # can be edit in k9s or apply deleting-confirmation-flag.yaml
  local dir="$(dirname "$0")"
  #run "line $LINENO;kubectl -n gitea-system patch -p '{\"value\": \"true\"}' --type=merge lhs deleting-confirmation-flag"
  #run "line $LINENO;helm uninstall gitea -n gitea-system"
  #run "line $LINENO;kubectl apply -f ./101-gitea/deleting-confirmation-flag.yaml"

  run "line $LINENO;kubectl create -f https://raw.githubusercontent.com/gitea/gitea/$gitea_ver/uninstall/uninstall.yaml"
  #kubectl get job/gitea-uninstall -n gitea-system -w

  # https://medium.com/@sirtcp/how-to-resolve-stuck-kubernetes-namespace-deletions-by-cleaning-finalizers-38190bf3165f
  # Get all resorces
  #kubectl api-resources
  # Get all resorces for namespace
  #kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n gitea-system

  # kubectl wait --for jsonpath='{.status.state}'=AtLatestKnown sub mysub -n myns --timeout=3m
  #run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=complete job/gitea-uninstall -n gitea-system'"
  run "line '$LINENO';kubectl wait --for=condition=complete job/gitea-uninstall -n gitea-system --timeout=5m"
  #run "line '$LINENO';wait-for-success \"kubectl get job/gitea-uninstall -n gitea-system -o jsonpath='{.status.conditions[?(@.type==\"Complete\")].status}' | grep True\""

  # crd_array=(backingimagedatasources backingimagemanagers backingimages backupbackingimages backups backuptargets /
  #   backupvolumes engineimages engines instancemanagers nodes orphans recurringjobs replicas settings sharemanagers /
  #   snapshots supportbundles systembackups systemrestores volumeattachments volumes)
  # for crd in "${crd_array[@]}"; do
  #   run "line '$LINENO';kubectl patch crd $crd -n gitea-system -p '{"metadata":{"finalizers":[]}}' --type=merge"
  #   run "line '$LINENO';kubectl delete crd $crd -n gitea-system"
  #   #run "line '$LINENO';kubectl delete crd $crd"
  # done

  run "line '$LINENO';kubectl delete namespace gitea-system"
  run "line '$LINENO';kubectl delete storageclass gitea-ssd"
  run "line '$LINENO';kubectl delete storageclass gitea-nvme"

exit

  local wait_time=0
  local wait_period=10
  local wait_timeout=300
  until kubectl get job/gitea-uninstall -n gitea-system -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' | grep True > /dev/null; 
  do 
    sleep $wait_period
    ((wait_time+=wait_period))
    if [[ $wait_time -gt $wait_timeout ]]; then
      err_and_exit "Timeout. Wait time $wait_time sec"  ${LINENO} "$0"
    fi
  done
  run "line '$LINENO';kubectl delete deployment gitea-ui -n gitea-system"
  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/gitea/gitea/$gitea_ver/uninstall/uninstall.yaml"

  local wait_time=0
  local wait_period=30
  local wait_timeout=600
  until ! command -v kubectl get pod -o json -n gitea-system | jq '.items | length' &> /dev/null;  
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
  #run "line '$LINENO';kubectl -n gitea-system delete crd nodes"

  run "line '$LINENO';kubectl delete namespace gitea-system"
}
gitea-upgrade()
{
  gitea-backup

  run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/gitea/gitea/$gitea_ver/deploy/gitea.yaml"
  run "line '$LINENO';vlib.wait-for-success 'kubectl rollout status deployment gitea-driver-deployer -n gitea-system'"
  run "line '$LINENO';vlib.wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n gitea-system --timeout=5m'"

  # if timeout when upgrade
  gitea-restore
}
gitea-backup()
{
  # https://gitea.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://gitea.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/create-a-backup-via-csi/
  echo kuku
}
gitea-restore()
{
  # https://gitea.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://gitea.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/restore-a-backup-via-csi/#restore-a-backup-that-has-no-associated-volumesnapshot
  echo kuku
}
check-gitea-exclusive-params()
{
  if [[ gitea_number_exclusive_params -gt 0 ]]; then
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
Gitea installation script.

Options:
  -o # show output of executed commands, not show is default
  -v # bashmatic verbose
  -d # bashmatic debug
  -w nodeRootPassword # need if called from parent script
  -t parentScriptStep # need if called from parent script
  -s cluster_plan.yaml # cluster plan for new installation
Exclusive operation options:
  -i version # Install Gitea version on current default cluster
  -u version # Uninstall Gitea version on current default cluster
  -g version # Upgrade Gitea to version on current default cluster
  -b # backup Gitea
  -r # restore Gitea
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
gitea_number_exclusive_params=0
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
      if [[ $gitea_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((gitea_number_exclusive_params++))
      gitea-check-version "$OPTARG" 1
      gitea-install-new
    ;;
    u )
      if [[ $gitea_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((gitea_number_exclusive_params++))
      gitea-check-version "$OPTARG"
      gitea-uninstall
    ;;
    g )
      if [[ $gitea_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((gitea_number_exclusive_params++))
      gitea-check-version "$OPTARG"
      gitea-upgrade
    ;;
    b ) 
      if [[ $gitea_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((gitea_number_exclusive_params++))
      # https://github.com/gitea/gitea/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/gitea/gitea/blob/master/enhancements/20220913-gitea-system-backup-restore.md
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      gitea-backup
    ;;
    r ) 
      if [[ $gitea_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((gitea_number_exclusive_params++))
      # https://github.com/gitea/gitea/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/gitea/gitea/blob/master/enhancements/20220913-gitea-system-backup-restore.md
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      gitea-restore
    ;;
    o ) opt_show_output='show-output-on'
      if [[ $gitea_number_exclusive_params -gt 0 ]]; then err_and_exit "-o has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
      run.set-all abort-on-error show-command-on $opt_show_output
    ;;
    #v ) verbose-on
    #  if [[ $gitea_number_exclusive_params -gt 0 ]]; then err_and_exit "-v has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
    #;;
    #d ) debug-on
    #  if [[ $gitea_number_exclusive_params -gt 0 ]]; then err_and_exit "-d has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
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


# https://gitea.io/docs/1.7.2/deploy/install/install-with-kubectl/
hl.blue "$parent_step$((++install_step)). Install Gitea. (Line:$LINENO)"
gitea_latest=$(curl -sL https://api.github.com/repos/gitea/gitea/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
if [ -z $gitea_ver ]; then
  gitea_ver=$gitea_latest
fi
if ! [ "$gitea_latest" == "$gitea_ver" ]; then
  warn "Latest version of Gitea: '$gitea_latest', but installing: '$gitea_ver'\n"
fi
run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/gitea/gitea/$gitea_ver/deploy/gitea.yaml"
# https://gitea.io/docs/1.7.2/advanced-resources/giteactl/install-giteactl/
if ! ($(giteactl version > /dev/null ) || $(giteactl version) != $gitea_ver ); then
  # Download the release binary.
  run "line '$LINENO';curl -LO "https://github.com/gitea/cli/releases/download/$gitea_ver/giteactl-linux-${ARCH}""
  # Download the checksum for your architecture.
  run line '$LINENO';curl -LO "https://github.com/gitea/cli/releases/download/$gitea_ver/giteactl-linux-${ARCH}.sha256"
  # Verify the downloaded binary matches the checksum.
  run line '$LINENO';echo "$(cat giteactl-linux-${ARCH}.sha256 | awk '{print $1}') giteactl-linux-${ARCH}" | sha256sum --check
  run line '$LINENO';sudo install giteactl-linux-${ARCH} /usr/local/bin/giteactl;giteactl version
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

# Step 16: Install Gitea (using modified Official to pin to Gitea Nodes)
echo -e " \033[32;5mInstalling Gitea - It can take a while for all pods to deploy...\033[0m"
kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/Gitea/gitea.yaml
kubectl get pods \
--namespace gitea-system \
--watch

# Step 17: Print out confirmation

kubectl get nodes
kubectl get svc -n gitea-system

echo -e " \033[32;5mHappy Kubing! Access Gitea through Rancher UI\033[0m"
