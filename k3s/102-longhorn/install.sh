#!/bin/bash
# Longhorn install
# ./102-longhorn/install.sh -s ./k3s-HA.yaml -i v1.7.2
# Longhorn uninstall
# ./102-longhorn/install.sh -u v1.7.2
# Longhorn upgrade
# ./102-longhorn/install.sh -g v1.7.3

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
  install_step=$((install_step+1))
  if [ $1 -eq 1 ]; then
    hl.blue "$install_step. Mount disks on node $node_name($node_ip4). (Line:$LINENO)"
  fi
  if [ $1 -eq 2 ]; then
    hl.blue "$install_step. Longhorn node disks yaml settings for $node_name($node_ip4). (Line:$LINENO)"
  fi
  # Create initial .bak of current fstab file
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'if sudo -S ! test -e /etc/fstab.bak; then cp /etc/fstab /etc/fstab.bak; fi <<< \"$node_root_password\"'"
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
      # Get local copy of node's fstab
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'sudo -S 'cp /etc/fstab ~/fstab' <<< \"$node_root_password\"'"
      run "line '$LINENO';scp -i ~/.ssh/$cert_name $node_user@$node_ip4:~/fstab ~/fstab"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'sudo -S 'rm ~/fstab' <<< \"$node_root_password\"'"

      for (( i=0; i < n_disks; i++ )); do
        # Delete previous fstab record and append new one
        run "line '$LINENO';sed -i \"/${node_disk_uuid_array[i]}/d\" ~/fstab"
        run "line '$LINENO';echo 'UUID=${node_disk_uuid_array[i]}  ${node_mnt_path_array[i]} ext4  defaults  0  0' >> ~/fstab"
        # Create mount directory if not exists
        run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"if sudo -S ! [[ -e ${node_mnt_path_array[i]} ]]; then mkdir ${node_mnt_path_array[i]}; fi <<< '$node_root_password'\""
      done
      # Copy updated fstab to node
      run "line '$LINENO';scp -i ~/.ssh/$cert_name.pub ~/fstab $node_user@$node_ip4:~/fstab"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo -S mv ~/fstab /etc/fstab <<< '$node_root_password'\""
      # Remount all
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo -S mount -a <<< '$node_root_password'\""
    ;;
    2 )
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
  if [[ -z $node_root_password ]]; then
    node_root_password=""
    read-password node_root_password "Please enter root password for cluster nodes:"
    echo
  fi
  readarray nodes < <(yq -o=j -I=0 '.node[]' < $k3s_settings)
  i_node=0
  for node in "${nodes[@]}"; do
    eval "$( yq '.[] | ( select(kind == "scalar") | key + "='\''" + . + "'\''")' <<<$node)"
    node_disks 1
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
  if command kubectl get deploy longhorn-ui -n longhorn-system &> /dev/null; then
    err_and_exit "Longhorn already installed."  ${LINENO} "$0"
  fi
  run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/deploy/longhorn.yaml"
  #run "line "$LINENO";kubectl create -f ./102-longhorn/backup.yaml"

  # https://fabianlee.org/2022/01/27/kubernetes-using-kubectl-to-wait-for-condition-of-pods-deployments-services/

  # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_wait/
  # https://kubernetes.io/docs/reference/kubectl/jsonpath/
  # https://stackoverflow.com/questions/53536907/kubectl-wait-for-condition-complete-timeout-30s
  run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=ready pod -l app=csi-attacher -n longhorn-system'"
  # no need if cluster exist run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n longhorn-system'"
  # not working sometime run "line '$LINENO';wait-for-success 'kubectl rollout status deployment csi-attacher -n longhorn-system'"

  # Volumes ????

}
longhorn-uninstall()
{
  if ! command kubectl get deploy longhorn-ui -n longhorn-system &> /dev/null; then
    err_and_exit "Longhorn not installed yet."  ${LINENO} "$0"
  fi

  longhorn_installed_ver=$( longhornctl version )
  if ! [ $longhorn_installed_ver == $longhorn_ver ]; then
    err_and_exit "Trying uninstall Longhorn version '$longhorn_ver', but expected '$longhorn_installed_ver'."  ${LINENO} "$0"
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
  run "line $LINENO;kubectl -n longhorn-system patch -p '{\"value\": \"true\"}' --type=merge lhs deleting-confirmation-flag"
  #run "line $LINENO;helm uninstall longhorn -n longhorn-system"

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
while getopts "ovdhs:i:u:g:" opt
do
  case $opt in
    s )
      if [[ $plan_is_provided -eq 1 ]]; then err_and_exit "Cluster plan is provided already" ${LINENO} "$0"; fi
      k3s_settings="$OPTARG"
      plan_is_provided=1
      cluster_plan_read
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
  esac
done
shift $((OPTIND-1))

is_longhorn_install_direct=0
#if [[ $is_longhorn_install_direct -eq 1 ]]; then
run.set-all abort-on-error show-command-on $opt_show_output
#fi

# Check number parameters
if ! [[ $# -eq 1 ]]; then err_and_exit $usage ${LINENO}; fi


exit


# https://longhorn.io/docs/1.7.2/deploy/install/install-with-kubectl/
install_step=$((install_step+1))
hl.blue "$install_step. Install Longhorn. (Line:$LINENO)"
longhorn_latest=$(curl -sL https://api.github.com/repos/longhorn/longhorn/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
if [ -z $longhorn_ver ]; then
  longhorn_ver=$longhorn_latest
fi
if ! [ "$longhorn_latest" == "$longhorn_ver" ]; then
  warn "Latest version of Longhorn: '$longhorn_latest', but installing: '$longhorn_ver'\n"
fi
run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/deploy/longhorn.yaml"
# https://longhorn.io/docs/1.7.2/advanced-resources/longhornctl/install-longhornctl/
if ! ($(longhornctl version > /dev/null ) || $(longhornctl version) != $longhorn_ver ); then
  # Download the release binary.
  run "line '$LINENO';curl -LO "https://github.com/longhorn/cli/releases/download/$longhorn_ver/longhornctl-linux-${ARCH}""
  # Download the checksum for your architecture.
  run line '$LINENO';curl -LO "https://github.com/longhorn/cli/releases/download/$longhorn_ver/longhornctl-linux-${ARCH}.sha256"
  # Verify the downloaded binary matches the checksum.
  run line '$LINENO';echo "$(cat longhornctl-linux-${ARCH}.sha256 | awk '{print $1}') longhornctl-linux-${ARCH}" | sha256sum --check
  run line '$LINENO';sudo install longhornctl-linux-${ARCH} /usr/local/bin/longhornctl;longhornctl version
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

# Step 16: Install Longhorn (using modified Official to pin to Longhorn Nodes)
echo -e " \033[32;5mInstalling Longhorn - It can take a while for all pods to deploy...\033[0m"
kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/Longhorn/longhorn.yaml
kubectl get pods \
--namespace longhorn-system \
--watch

# Step 17: Print out confirmation

kubectl get nodes
kubectl get svc -n longhorn-system

echo -e " \033[32;5mHappy Kubing! Access Longhorn through Rancher UI\033[0m"
