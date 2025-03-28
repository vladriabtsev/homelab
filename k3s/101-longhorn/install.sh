#!/bin/bash
# Longhorn install
# ./101-longhorn/install.sh -s ./k3s-HA.yaml -i v1.7.2
# Longhorn uninstall
# ./101-longhorn/install.sh -u v1.7.2
# Longhorn upgrade
# ./101-longhorn/install.sh -g v1.7.3

source ./../bash-lib.sh

longhorn-check-version()
{
  #longhorn_latest=$(curl -sL https://api.github.com/repos/longhorn/longhorn/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  longhorn_latest=$(curl -sL https://api.github.com/repos/longhorn/longhorn/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  longhorn_ver="$1"
  if [ -z $longhorn_ver ]; then longhorn_ver=$longhorn_latest; fi
  if ! [ -z $2 ]; then
    if ! [ "$longhorn_latest" == "$longhorn_ver" ]; then
      warn "Latest version of Longhorn: '$longhorn_latest', but installing: '$longhorn_ver'\n"
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
  readarray disks < <(yq -o=j -I=0 ".node[$i_node].node_storage[]" < $k3s_settings)
  local i_disk=0
  for disk in "${disks[@]}"; do
    eval "$( yq '.[] | ( select(kind == "scalar") | key + "='\''" + . + "'\''")' <<<$disk)"
    node_storage_class_array[i_disk]=$storage_class
    node_disk_uuid_array[i_disk]=$disk_uuid
    node_mnt_path_array[i_disk]=$mnt_path
    ((i_disk++))
  done
  n_disks=$i_disk # Total disks
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
      run "line '$LINENO';scp -i ~/.ssh/$cert_name ./101-longhorn/dm_crypt_load.sh $node_user@$node_ip4:~/tmp/dm_crypt_load.sh"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'chmod 777 ~/tmp/dm_crypt_load.sh'"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name sudo -S sh -c '~/tmp/dm_crypt_load.sh' <<< \"$node_root_password\""
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'rm ~/tmp/dm_crypt_load.sh'"
    ;;
    2 )
      hl.blue "$parent_step$((++install_step)). Longhorn node disks config settings for $node_name($node_ip4). (Line:$LINENO)"
      # https://stackoverflow.com/questions/73370812/how-to-add-annotations-to-kubernetes-node-using-patch-file
      # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_patch/
      # patch for node disk settings
      # https://longhorn.io/docs/archives/1.3.1/advanced-resources/default-disk-and-node-config/#launch-longhorn-with-multiple-disks

      # https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/
      if [[ $n_disks -eq 0 ]]; then
        run "line '$LINENO';kubectl label --overwrite nodes $node_name node.longhorn.io/create-default-disk=true" # mounted disks are not included
      else
        run "line '$LINENO';kubectl label --overwrite nodes $node_name node.longhorn.io/create-default-disk='config'" # mounted disks are not included
        local first=1
        local tmp=""
        local tmp2="" # only mounted disks
        #local tmp2="{\"path\":\"/var/lib/longhorn\",\"allowScheduling\":true}" # mounted disks are not included
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
      # node longhorn storage tags
      run "line '$LINENO';kubectl annotate --overwrite nodes $node_name node.longhorn.io/default-node-tags='[\"storage\",$tmp]'"

      # node longhorn disk config
      run "line '$LINENO';kubectl annotate --overwrite nodes $node_name node.longhorn.io/default-disks-config='[$tmp2]'"
      node_disk_config["${node_name}"]="${tmp2}"
      # kubectl patch node k8s-worker-1 --type merge --patch-file /home/bino/k0s-sriwijaya/longhorn/lhpatch.yaml
    ;;
    * )
      err_and_exit "Expected parameters: 1 - mount, 2 - generate yaml" ${LINENO};
  esac
}
longhorn-install-new()
{
  if ! [[ -e ${k3s_settings} ]]; then
    err_and_exit "Cluster plan file '${k3s_settings}' is not found" ${LINENO};
  fi
  #echo $node_root_password
  if [[ -z $node_root_password ]]; then
    node_root_password=""
    read-password node_root_password "Please enter root password for cluster nodes:"
    echo
  fi
  if [[ -z $longhorn_ui_admin_name ]]; then
    longhorn_ui_admin_name=""
    read-password longhorn_ui_admin_name "Please enter Longhorn UI admin name:"
    echo
  fi
  if [[ -z $longhorn_ui_admin_password ]]; then
    longhorn_ui_admin_password=""
    read-password longhorn_ui_admin_password "Please enter Longhorn UI admin password:"
    echo
  fi

  declare -A node_disk_config

  readarray nodes < <(yq -o=j -I=0 '.node[]' < $k3s_settings)
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
  #wait-for-success "kubectl wait --for=condition=Ready pod/csi-attacher -n longhorn-system"
  #wait-for-success -t 1 "kubectl wait --for=condition=Ready pod/csi-attacher -n longhorn-system"
  #run wait-for-success -t 1 "kubectl wait --for=condition=Ready pod/csi-attacher -n longhorn-system"
  #run "wait-for-success -t 1 \"kubectl wait --for=condition=Ready pod/csi-attacher -n longhorn-system\""
  #run "wait-for-success -t 1 'kubectl wait --for=condition=Ready pod/csi-attacher -n longhorn-system'"
  #exit

  hl.blue "$parent_step$((++install_step)). Longhorn installation. (Line:$LINENO)"
  if command kubectl get deploy longhorn-ui -n longhorn-system &> /dev/null; then
    err_and_exit "Longhorn already installed."  ${LINENO} "$0"
  fi
  # https://longhorn.io/docs/1.7.2/advanced-resources/longhornctl/install-longhornctl/
  if ! ($(longhornctl version > /dev/null ) || $(longhornctl version) != $longhorn_ver ); then
    # Download the release binary.
    run "line '$LINENO';curl -LO "https://github.com/longhorn/cli/releases/download/$longhorn_ver/longhornctl-linux-${ARCH}""
    # Download the checksum for your architecture.
    run "line '$LINENO';curl -LO 'https://github.com/longhorn/cli/releases/download/$longhorn_ver/longhornctl-linux-${ARCH}.sha256'"
    # Verify the downloaded binary matches the checksum.
    run line "$LINENO";echo "$(cat longhornctl-linux-${ARCH}.sha256 | awk '{print $1}') longhornctl-linux-${ARCH}" | sha256sum --check
    run "line '$LINENO';sudo install longhornctl-linux-${ARCH} /usr/local/bin/longhornctl;longhornctl version"
  fi

  longhornctl check preflight
  run.ui.ask "Preflight errors check is finished. Proceed new installation?" || exit 1

  # https://longhorn.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-the-longhorn-deployment-yaml-file

  run "line '$LINENO';wget -O ~/tmp/longhorn.yaml https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/deploy/longhorn.yaml"
  # https://longhorn.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-kubectl
  # https://github.com/longhorn/longhorn/blob/master/chart/templates/default-setting.yaml
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    create-default-disk-labeled-nodes: true/' ~/tmp/longhorn.yaml"
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    deleting-confirmation-flag: true/' ~/tmp/longhorn.yaml"
  run "line '$LINENO';kubectl apply -f ~/tmp/longhorn.yaml"

  #run "line "$LINENO";kubectl create -f ./101-longhorn/backup.yaml"

  # https://fabianlee.org/2022/01/27/kubernetes-using-kubectl-to-wait-for-condition-of-pods-deployments-services/

  # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_wait/
  # https://kubernetes.io/docs/reference/kubectl/jsonpath/
  # https://stackoverflow.com/questions/53536907/kubectl-wait-for-condition-complete-timeout-30s
  run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=ready pod -l app=csi-attacher -n longhorn-system'"
  run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n longhorn-system'"
  # no need if cluster exist run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n longhorn-system'"
  # not working sometime run "line '$LINENO';wait-for-success 'kubectl rollout status deployment csi-attacher -n longhorn-system'"

  #run "helm upgrade longhorn longhorn/longhorn --namespace longhorn-system --values ./values.yaml --version $longhorn_ver"

  if ! test -e ~/downloads; then mkdir ~/downloads; fi
  run "line '$LINENO';curl https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/examples/storageclass.yaml -o ~/downloads/storageclass.yaml"
  # ssd storage class
  run "line '$LINENO';yq -i '
    .metadata.name = \"longhorn-ssd\" |
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
    .metadata.name = \"longhorn-nvme\" |
    .parameters.numberOfReplicas = \"3\" |
    .parameters.staleReplicaTimeout = \"2880\" |
    .parameters.fsType = \"ext4\" |
    .parameters.mkfsParams = \"-I 256 -b 4096 -O ^metadata_csum,^64bit\" |
    .parameters.diskSelector = \"nvme\" |
    .parameters.nodeSelector = \"storage,nvme\"
  ' ~/downloads/storageclass.yaml"
  run "line '$LINENO';kubectl create -f ~/downloads/storageclass.yaml"

  hl.blue "$parent_step$((++install_step)). Longhorn UI. (Line:$LINENO)"
  # Longhorn UI
  # https://github.com/longhorn/website/blob/master/content/docs/1.8.1/deploy/accessing-the-ui/longhorn-ingress.md
  # # https://kubernetes.github.io/ingress-nginx/examples/auth/basic/
  # htpasswd -c ${HOME}/tmp/auth $longhorn_ui_admin_name
  # run "line '$LINENO';echo \"${longhorn_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${longhorn_ui_admin_password})\" > ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n longhorn-system create secret generic basic-auth --from-file=${HOME}/tmp/auth"
  # run "line '$LINENO';rm ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n longhorn-system apply -f ./101-longhorn/longhorn-ui-auth-basic.yaml"

  # https://longhorn.io/docs/1.7.3/deploy/accessing-the-ui/longhorn-ingress/
  run "line '$LINENO';echo \"${longhorn_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${longhorn_ui_admin_password})\" > ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n longhorn-system create secret generic longhorn-ui-auth-basic --from-file=${HOME}/tmp/auth"
  run "line '$LINENO';rm ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n longhorn-system apply -f ./101-longhorn/longhorn-ui-auth-basic.yaml"

  run "line '$LINENO';kubectl expose deployment longhorn-ui --port=80 --type=LoadBalancer --name=longhorn-ui -n longhorn-system --target-port=http --load-balancer-ip=192.168.100.101"
  # kubectl expose deployment longhorn-ui --port=80 --type=LoadBalancer --name=longhorn-ui -n longhorn-system --target-port=http --load-balancer-ip=192.168.100.101
  # kubectl -n longhorn-system get svc
  # kubectl  -n longhorn-system describe svc longhorn-ui
  # kubectl delete service longhorn-ui -n longhorn-system

  kubectl get nodes
  kubectl get svc -n longhorn-system
  echo "Longhorn UI: check all disks on all nodes are available and schedulable !!!"

  #kubectl apply -f ./101-longhorn/test-pod-with-pvc.yaml

  # Tests
  # kubectl -n longhorn-system get replicas --output=jsonpath="{.items[?(@.status.volumeName==\"<THE VOLUME NAME YOU ARE CHECKING>\")].metadata.name}"
  # kubectl -n longhorn-system edit replicas
  # kubectl get volumes.longhorn.io pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c -o yaml -n longhorn-system
  # kubectl get replicas.longhorn.io -n longhorn-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.longhorn.io -n longhorn-system -o yaml
  # kubectl get engines.longhorn.io -n longhorn-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.longhorn.io -n longhorn-system -o yaml
  # Volumes ????

}
longhorn-uninstall()
{
  hl.blue "$parent_step$((++install_step)). Uninstalling Longhorn. (Line:$LINENO)"

  if ! command kubectl get deploy longhorn-ui -n longhorn-system &> /dev/null; then
    err_and_exit "Longhorn not installed yet."  ${LINENO} "$0"
  fi

  if ! command kubectl get deploy -l app.kubernetes.io/version=$longhorn_ver -n longhorn-system &> /dev/null; then
    err_and_exit "Trying uninstall Longhorn version '$longhorn_ver', but this version is not installed."  ${LINENO} "$0"
  fi

  # manually deleting stucked-namespace
  #kubectl get namespace "longhorn-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/longhorn-system/finalize -f -
  #kubectl get namespace "stucked-namespace" -o json \
  #  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  #  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

  # longhorn deleting-confirmation-flag
  # kubectl get lhs -n longhorn-system
  # can be edit in k9s or apply deleting-confirmation-flag.yaml
  local dir="$(dirname "$0")"
  #run "line $LINENO;kubectl -n longhorn-system patch -p '{\"value\": \"true\"}' --type=merge lhs deleting-confirmation-flag"
  #run "line $LINENO;helm uninstall longhorn -n longhorn-system"
  #run "line $LINENO;kubectl apply -f ./101-longhorn/deleting-confirmation-flag.yaml"

  run "line $LINENO;kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/uninstall/uninstall.yaml"
  #kubectl get job/longhorn-uninstall -n longhorn-system -w

  # https://medium.com/@sirtcp/how-to-resolve-stuck-kubernetes-namespace-deletions-by-cleaning-finalizers-38190bf3165f
  # Get all resorces
  #kubectl api-resources
  # Get all resorces for namespace
  #kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n longhorn-system

  # kubectl wait --for jsonpath='{.status.state}'=AtLatestKnown sub mysub -n myns --timeout=3m
  #run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=complete job/longhorn-uninstall -n longhorn-system'"
  run "line '$LINENO';kubectl wait --for=condition=complete job/longhorn-uninstall -n longhorn-system --timeout=5m"
  #run "line '$LINENO';wait-for-success \"kubectl get job/longhorn-uninstall -n longhorn-system -o jsonpath='{.status.conditions[?(@.type==\"Complete\")].status}' | grep True\""

  run "line '$LINENO';kubectl delete namespace longhorn-system"
  run "line '$LINENO';kubectl delete storageclass longhorn-ssd"
  run "line '$LINENO';kubectl delete storageclass longhorn-nvme"

exit

  local wait_time=0
  local wait_period=10
  local wait_timeout=300
  until kubectl get job/longhorn-uninstall -n longhorn-system -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' | grep True > /dev/null; 
  do 
    sleep $wait_period
    ((wait_time+=wait_period))
    if [[ $wait_time -gt $wait_timeout ]]; then
      err_and_exit "Timeout. Wait time $wait_time sec"  ${LINENO} "$0"
    fi
  done
  run "line '$LINENO';kubectl delete deployment longhorn-ui -n longhorn-system"
  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/uninstall/uninstall.yaml"

  local wait_time=0
  local wait_period=30
  local wait_timeout=600
  until ! command -v kubectl get pod -o json -n longhorn-system | jq '.items | length' &> /dev/null;  
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
  #run "line '$LINENO';kubectl -n longhorn-system delete crd nodes"

  run "line '$LINENO';kubectl delete namespace longhorn-system"
}
longhorn-upgrade()
{
  longhorn-backup

  run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/deploy/longhorn.yaml"
  run "line '$LINENO';wait-for-success 'kubectl rollout status deployment longhorn-driver-deployer -n longhorn-system'"
  run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n longhorn-system --timeout=5m'"

  # if timeout when upgrade
  longhorn-restore
}
longhorn-backup()
{
  # https://longhorn.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://longhorn.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/create-a-backup-via-csi/
  echo kuku
}
longhorn-restore()
{
  # https://longhorn.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://longhorn.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/restore-a-backup-via-csi/#restore-a-backup-that-has-no-associated-volumesnapshot
  echo kuku
}
check-longhorn-exclusive-params()
{
  if [[ longhorn_number_exclusive_params -gt 0 ]]; then
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
Longhorn installation script.

Options:
  -o # show output of executed commands, not show is default
  -v # bashmatic verbose
  -d # bashmatic debug
  -w nodeRootPassword # need if called from parent script
  -t parentScriptStep # need if called from parent script
  -s cluster_plan.yaml # cluster plan for new installation
Exclusive operation options:
  -i version # Install Longhorn version on current default cluster
  -u version # Uninstall Longhorn version on current default cluster
  -g version # Upgrade Longhorn to version on current default cluster
  -b # backup Longhorn
  -r # restore Longhorn
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
longhorn_number_exclusive_params=0
plan_is_provided=0
if ! [[ -z $k3s_settings ]]; then 
  $plan_is_provided=1; 
fi
while getopts "ovdhs:w:t:i:u:g:" opt
do
  case $opt in
    s )
      if [[ $plan_is_provided -eq 1 ]]; then err_and_exit "Cluster plan is provided already" ${LINENO} "$0"; fi
      k3s_settings="$OPTARG"
      plan_is_provided=1
      cluster_plan_read
    ;;
    w )
      node_root_password="$OPTARG"
    ;;
    t )
      parent_step="$OPTARG."
    ;;
    i )
      if [[ $plan_is_provided -eq 0 ]]; then err_and_exit "Cluster plan is not provided" ${LINENO} "$0"; fi
      if [[ $longhorn_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((longhorn_number_exclusive_params++))
      longhorn-check-version "$OPTARG" 1
      longhorn-install-new
    ;;
    u )
      if [[ $longhorn_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((longhorn_number_exclusive_params++))
      longhorn-check-version "$OPTARG"
      longhorn-uninstall
    ;;
    g )
      if [[ $longhorn_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((longhorn_number_exclusive_params++))
      longhorn-check-version "$OPTARG"
      longhorn-upgrade
    ;;
    b ) 
      if [[ $longhorn_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((longhorn_number_exclusive_params++))
      # https://github.com/longhorn/longhorn/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/longhorn/longhorn/blob/master/enhancements/20220913-longhorn-system-backup-restore.md
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      longhorn-backup
    ;;
    r ) 
      if [[ $longhorn_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((longhorn_number_exclusive_params++))
      # https://github.com/longhorn/longhorn/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/longhorn/longhorn/blob/master/enhancements/20220913-longhorn-system-backup-restore.md
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      longhorn-restore
    ;;
    o ) opt_show_output='show-output-on'
      if [[ $longhorn_number_exclusive_params -gt 0 ]]; then err_and_exit "-o has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
      run.set-all abort-on-error show-command-on $opt_show_output
    ;;
    #v ) verbose-on
    #  if [[ $longhorn_number_exclusive_params -gt 0 ]]; then err_and_exit "-v has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
    #;;
    #d ) debug-on
    #  if [[ $longhorn_number_exclusive_params -gt 0 ]]; then err_and_exit "-d has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
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
