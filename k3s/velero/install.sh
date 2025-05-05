#!/bin/bash
# Velero install
# ./velero/install.sh -i v1.15.1
# Velero uninstall
# ./velero/install.sh -u v1.15.1
# Velero upgrade
# ./velero/install.sh -g v1.15.2

source ./../vlib.bash

velero-check-version()
{
  #velero_latest=$(curl -sL https://api.github.com/repos/velero/velero/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  velero_latest=$(curl -sL https://api.github.com/repos/vmware-tanzu/velero/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  velero_ver="$1"
  if [ -z $velero_ver ]; then velero_ver=$velero_latest; fi
  if ! [ -z $2 ]; then
    if ! [ "$velero_latest" == "$velero_ver" ]; then
      warn "Latest version of Velero: '$velero_latest', but installing: '$velero_ver'\n"
    fi
  fi
}
velero-cli()
{
    hl.blue "$parent_step$((++install_step)). Velero CLI installation. (Line:$LINENO)"
    # v version | awk '/Version:/ {print $2}'
    echo -e $1
    run "line '$LINENO';curl -L -s -o ~/tmp/velero-$velero_ver-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/$velero_ver/velero-$velero_ver-linux-amd64.tar.gz"
    #curl -L -s -o ~/tmp/velero-v1.15.1-linux-amd64.tar.gz https://github.com/vmware-tanzu/velero/releases/download/v1.15.1/velero-v1.15.1-linux-amd64.tar.gz
    run "line '$LINENO';tar -xvf ~/tmp/velero-$velero_ver-linux-amd64.tar.gz -C ~/tmp"
    #tar -xvf ~/tmp/velero-v1.15.1-linux-amd64.tar.gz -C ~/tmp
    run "line '$LINENO';sudo mv ~/tmp/velero-$velero_ver-linux-amd64/velero /usr/local/bin"
    #mv ~/tmp/velero-v1.15.1-linux-amd64/velero /usr/local/bin
}
velero-install-new()
{
  #echo $node_root_password
  # if [[ -z $node_root_password ]]; then
  #   node_root_password=""
  #   vlib.read-password node_root_password "Please enter root password for cluster nodes:"
  #   echo
  # fi

  #wait-for-success -t 1 "ls ~/"
  #wait-for-success
  #wait-for-success "kubectl wait --for=condition=Ready pod/csi-attacher -n velero-system"
  #wait-for-success -t 1 "kubectl wait --for=condition=Ready pod/csi-attacher -n velero-system"
  #run wait-for-success -t 1 "kubectl wait --for=condition=Ready pod/csi-attacher -n velero-system"
  #run "wait-for-success -t 1 \"kubectl wait --for=condition=Ready pod/csi-attacher -n velero-system\""
  #run "wait-for-success -t 1 'kubectl wait --for=condition=Ready pod/csi-attacher -n velero-system'"
  #exit

  # Install velero if not already present
  if ! command -v velero version &> /dev/null; then
    velero-cli " Velero CLI not found, installing ..."
  else
    local tmp=$(velero version | awk '/Version:/ {print $2}')
    if [[ $tmp != "${velero_ver}" ]]; then
      velero-cli " Found Velero CLI version ${tmp}, installing ${velero_ver} version ..."
    fi
  fi

exit

  if command kubectl get deploy velero-ui -n velero-system &> /dev/null; then
    err_and_exit "Velero already installed."  ${LINENO} "$0"
  fi
  # https://velero.io/docs/1.7.2/advanced-resources/veleroctl/install-veleroctl/
  if ! ($(veleroctl version > /dev/null ) || $(veleroctl version) != $velero_ver ); then
    # Download the release binary.
    run "line '$LINENO';curl -LO "https://github.com/velero/cli/releases/download/$velero_ver/veleroctl-linux-${ARCH}""
    # Download the checksum for your architecture.
    run "line '$LINENO';curl -LO 'https://github.com/velero/cli/releases/download/$velero_ver/veleroctl-linux-${ARCH}.sha256'"
    # Verify the downloaded binary matches the checksum.
    run line "$LINENO";echo "$(cat veleroctl-linux-${ARCH}.sha256 | awk '{print $1}') veleroctl-linux-${ARCH}" | sha256sum --check
    run "line '$LINENO';sudo install veleroctl-linux-${ARCH} /usr/local/bin/veleroctl;veleroctl version"
  fi

  veleroctl check preflight
  run.ui.ask "Preflight errors check is finished. Proceed new installation?" || exit 1

  # https://velero.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-the-velero-deployment-yaml-file

  run "line '$LINENO';wget -O ~/tmp/velero.yaml https://raw.githubusercontent.com/velero/velero/$velero_ver/deploy/velero.yaml"
  #run "line '$LINENO';cat ~/tmp/velero.yaml | yq   "
  # https://velero.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-kubectl
  # https://github.com/velero/velero/blob/master/chart/templates/default-setting.yaml
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    create-default-disk-labeled-nodes: true/' ~/tmp/velero.yaml"
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    deleting-confirmation-flag: true/' ~/tmp/velero.yaml"
  run "line '$LINENO';kubectl apply -f ~/tmp/velero.yaml"
  #run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/velero/velero/$velero_ver/deploy/velero.yaml"

  #run "line "$LINENO";kubectl create -f ./101-velero/backup.yaml"

  # https://fabianlee.org/2022/01/27/kubernetes-using-kubectl-to-wait-for-condition-of-pods-deployments-services/

  # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_wait/
  # https://kubernetes.io/docs/reference/kubectl/jsonpath/
  # https://stackoverflow.com/questions/53536907/kubectl-wait-for-condition-complete-timeout-30s
  run "line '$LINENO';vlib.wait-for-success 'kubectl wait --for=condition=ready pod -l app=csi-attacher -n velero-system'"
  # no need if cluster exist run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n velero-system'"
  # not working sometime run "line '$LINENO';wait-for-success 'kubectl rollout status deployment csi-attacher -n velero-system'"

  #helm repo add velero https://charts.velero.io
  #helm repo update
  #helm install velero velero/velero --version 1.7.2 \
  #  --namespace velero-system \
  #  --create-namespace \
  #  --set defaultSettings.createDefaultDiskLabeledNodes=true
  #  --values values.yaml
  #run "helm upgrade velero velero/velero --namespace velero-system --values ./values.yaml --version $velero_ver"

  if ! test -e ~/downloads; then mkdir ~/downloads; fi
  run "line '$LINENO';curl https://raw.githubusercontent.com/velero/velero/$velero_ver/examples/storageclass.yaml -o ~/downloads/storageclass.yaml"
  # ssd storage class
  run "line '$LINENO';yq -i '
    .metadata.name = \"velero-ssd\" |
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
    .metadata.name = \"velero-nvme\" |
    .parameters.numberOfReplicas = \"3\" |
    .parameters.staleReplicaTimeout = \"2880\" |
    .parameters.fsType = \"ext4\" |
    .parameters.mkfsParams = \"-I 256 -b 4096 -O ^metadata_csum,^64bit\" |
    .parameters.diskSelector = \"nvme\" |
    .parameters.nodeSelector = \"storage,nvme\"
  ' ~/downloads/storageclass.yaml"
  run "line '$LINENO';kubectl create -f ~/downloads/storageclass.yaml"

  hl.blue "$parent_step$((++install_step)). Velero UI. (Line:$LINENO)"
  # Velero UI
  # https://github.com/velero/website/blob/master/content/docs/1.8.1/deploy/accessing-the-ui/velero-ingress.md
  # # https://kubernetes.github.io/ingress-nginx/examples/auth/basic/
  # htpasswd -c ${HOME}/tmp/auth $velero_ui_admin_name
  # run "line '$LINENO';echo \"${velero_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${velero_ui_admin_password})\" > ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n velero-system create secret generic basic-auth --from-file=${HOME}/tmp/auth"
  # run "line '$LINENO';rm ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n velero-system apply -f ./101-velero/velero-ui-auth-basic.yaml"

  https://velero.io/docs/1.7.3/deploy/accessing-the-ui/velero-ingress/
  run "line '$LINENO';echo \"${velero_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${velero_ui_admin_password})\" > ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n velero-system create secret generic velero-ui-auth-basic --from-file=${HOME}/tmp/auth"
  run "line '$LINENO';rm ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n velero-system apply -f ./101-velero/velero-ui-auth-basic.yaml"

  run "line '$LINENO';kubectl expose deployment velero-ui --port=80 --type=LoadBalancer --name=velero-ui -n velero-system --target-port=http --load-balancer-ip=192.168.100.101"
  # kubectl expose deployment velero-ui --port=80 --type=LoadBalancer --name=velero-ui -n velero-system --target-port=http --load-balancer-ip=192.168.100.101
  # kubectl -n velero-system get svc
  # kubectl  -n velero-system describe svc velero-ui
  # kubectl delete service velero-ui -n velero-system

  # for node_name in "${!node_disk_config[@]}"; do
  #   echo "${node_name} - '{\"metadata\":{\"annotations\":{\"node.velero.io/default-disks-config\":[${node_disk_config[$node_name]}]}}}'"
  #   run "line '$LINENO';kubectl -n velero-system patch nodes $node_name -p '{\"metadata\":{\"annotations\":{\"node.velero.io/default-disks-config\":[${node_disk_config[$node_name]}]}}}'"
  #   #kubectl -n velero-system patch nodes node-1 -p '{"metadata":{"annotations":{"node.velero.io/default-disks-config":"[{\"path\":\"/var/lib/velero\",\"allowScheduling\":true}]"}}}'
  #   #velero-system patch nodes k3s2 -p '{\"metadata\":{\"annotations\":{\"node.velero.io/default-disks-config\":[${node_disk_config[$node_name]}]}}}'
  # done

  echo "Velero UI: check all disks on all nodes are available and schedulable !!!"

  #kubectl apply -f ./101-velero/test-pod-with-pvc.yaml

  # Tests
  # kubectl -n velero-system get replicas --output=jsonpath="{.items[?(@.status.volumeName==\"<THE VOLUME NAME YOU ARE CHECKING>\")].metadata.name}"
  # kubectl -n velero-system edit replicas
  # kubectl get volumes.velero.io pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c -o yaml -n velero-system
  # kubectl get replicas.velero.io -n velero-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.velero.io -n velero-system -o yaml
  # kubectl get engines.velero.io -n velero-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.velero.io -n velero-system -o yaml
  # Volumes ????

}
velero-uninstall()
{
  hl.blue "$parent_step$((++install_step)). Uninstalling Velero. (Line:$LINENO)"

  if ! command kubectl get deploy velero-ui -n velero-system &> /dev/null; then
    err_and_exit "Velero not installed yet."  ${LINENO} "$0"
  fi

  if ! command kubectl get deploy -l app.kubernetes.io/version=$velero_ver -n velero-system &> /dev/null; then
    err_and_exit "Trying uninstall Velero version '$velero_ver', but this version is not installed."  ${LINENO} "$0"
  fi

  # velero_installed_ver=$( veleroctl version )
  # if ! [ $velero_installed_ver == $velero_ver ]; then
  #   err_and_exit "Trying uninstall Velero version '$velero_ver', but expected '$velero_installed_ver'."  ${LINENO} "$0"
  # fi

  # manually deleting stucked-namespace
  #kubectl get namespace "velero-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/velero-system/finalize -f -
  #kubectl get namespace "stucked-namespace" -o json \
  #  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  #  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

  # velero deleting-confirmation-flag
  # kubectl get lhs -n velero-system
  # can be edit in k9s or apply deleting-confirmation-flag.yaml
  local dir="$(dirname "$0")"
  #run "line $LINENO;kubectl -n velero-system patch -p '{\"value\": \"true\"}' --type=merge lhs deleting-confirmation-flag"
  #run "line $LINENO;helm uninstall velero -n velero-system"
  #run "line $LINENO;kubectl apply -f ./101-velero/deleting-confirmation-flag.yaml"

  run "line $LINENO;kubectl create -f https://raw.githubusercontent.com/velero/velero/$velero_ver/uninstall/uninstall.yaml"
  #kubectl get job/velero-uninstall -n velero-system -w

  # https://medium.com/@sirtcp/how-to-resolve-stuck-kubernetes-namespace-deletions-by-cleaning-finalizers-38190bf3165f
  # Get all resorces
  #kubectl api-resources
  # Get all resorces for namespace
  #kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n velero-system

  # kubectl wait --for jsonpath='{.status.state}'=AtLatestKnown sub mysub -n myns --timeout=3m
  #run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=complete job/velero-uninstall -n velero-system'"
  run "line '$LINENO';kubectl wait --for=condition=complete job/velero-uninstall -n velero-system --timeout=5m"
  #run "line '$LINENO';wait-for-success \"kubectl get job/velero-uninstall -n velero-system -o jsonpath='{.status.conditions[?(@.type==\"Complete\")].status}' | grep True\""

  # crd_array=(backingimagedatasources backingimagemanagers backingimages backupbackingimages backups backuptargets /
  #   backupvolumes engineimages engines instancemanagers nodes orphans recurringjobs replicas settings sharemanagers /
  #   snapshots supportbundles systembackups systemrestores volumeattachments volumes)
  # for crd in "${crd_array[@]}"; do
  #   run "line '$LINENO';kubectl patch crd $crd -n velero-system -p '{"metadata":{"finalizers":[]}}' --type=merge"
  #   run "line '$LINENO';kubectl delete crd $crd -n velero-system"
  #   #run "line '$LINENO';kubectl delete crd $crd"
  # done

  run "line '$LINENO';kubectl delete namespace velero-system"
  run "line '$LINENO';kubectl delete storageclass velero-ssd"
  run "line '$LINENO';kubectl delete storageclass velero-nvme"

exit

  local wait_time=0
  local wait_period=10
  local wait_timeout=300
  until kubectl get job/velero-uninstall -n velero-system -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' | grep True > /dev/null; 
  do 
    sleep $wait_period
    ((wait_time+=wait_period))
    if [[ $wait_time -gt $wait_timeout ]]; then
      err_and_exit "Timeout. Wait time $wait_time sec"  ${LINENO} "$0"
    fi
  done
  run "line '$LINENO';kubectl delete deployment velero-ui -n velero-system"
  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/velero/velero/$velero_ver/uninstall/uninstall.yaml"

  local wait_time=0
  local wait_period=30
  local wait_timeout=600
  until ! command -v kubectl get pod -o json -n velero-system | jq '.items | length' &> /dev/null;  
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
  #run "line '$LINENO';kubectl -n velero-system delete crd nodes"

  run "line '$LINENO';kubectl delete namespace velero-system"
}
velero-upgrade()
{
  velero-backup

  run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/velero/velero/$velero_ver/deploy/velero.yaml"
  run "line '$LINENO';vlib.wait-for-success 'kubectl rollout status deployment velero-driver-deployer -n velero-system'"
  run "line '$LINENO';vlib.wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n velero-system --timeout=5m'"

  # if timeout when upgrade
  velero-restore
}
check-velero-exclusive-params()
{
  if [[ velero_number_exclusive_params -gt 0 ]]; then
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
Velero installation script.

Options:
  -o # show output of executed commands, not show is default
  -v # bashmatic verbose
  -d # bashmatic debug
  -w nodeRootPassword # need if called from parent script
  -t parentScriptStep # need if called from parent script
  -s cluster_plan.yaml # cluster plan for new installation
Exclusive operation options:
  -i version # Install Velero version on current default cluster
  -u version # Uninstall Velero version on current default cluster
  -g version # Upgrade Velero to version on current default cluster
  -b # backup Velero
  -r # restore Velero
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
velero_number_exclusive_params=0
plan_is_provided=0
if ! [[ -z $k3s_settings ]]; then 
  $plan_is_provided=1; 
fi
while getopts "ovdhw:t:i:u:g:" opt
do
  case $opt in
    w )
      node_root_password="$OPTARG"
    ;;
    t )
      parent_step="$OPTARG."
    ;;
    i )
      if [[ $velero_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((velero_number_exclusive_params++))
      velero-check-version "$OPTARG" 1
      velero-install-new
    ;;
    u )
      if [[ $velero_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((velero_number_exclusive_params++))
      velero-check-version "$OPTARG"
      velero-uninstall
    ;;
    g )
      if [[ $velero_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((velero_number_exclusive_params++))
      velero-check-version "$OPTARG"
      velero-upgrade
    ;;
    o ) opt_show_output='show-output-on'
      if [[ $velero_number_exclusive_params -gt 0 ]]; then err_and_exit "-o has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
      run.set-all abort-on-error show-command-on $opt_show_output
    ;;
    #v ) verbose-on
    #  if [[ $velero_number_exclusive_params -gt 0 ]]; then err_and_exit "-v has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
    #;;
    #d ) debug-on
    #  if [[ $velero_number_exclusive_params -gt 0 ]]; then err_and_exit "-d has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
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


# https://velero.io/docs/1.7.2/deploy/install/install-with-kubectl/
hl.blue "$parent_step$((++install_step)). Install Velero. (Line:$LINENO)"
velero_latest=$(curl -sL https://api.github.com/repos/velero/velero/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
if [ -z $velero_ver ]; then
  velero_ver=$velero_latest
fi
if ! [ "$velero_latest" == "$velero_ver" ]; then
  warn "Latest version of Velero: '$velero_latest', but installing: '$velero_ver'\n"
fi
run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/velero/velero/$velero_ver/deploy/velero.yaml"
# https://velero.io/docs/1.7.2/advanced-resources/veleroctl/install-veleroctl/
if ! ($(veleroctl version > /dev/null ) || $(veleroctl version) != $velero_ver ); then
  # Download the release binary.
  run "line '$LINENO';curl -LO "https://github.com/velero/cli/releases/download/$velero_ver/veleroctl-linux-${ARCH}""
  # Download the checksum for your architecture.
  run line '$LINENO';curl -LO "https://github.com/velero/cli/releases/download/$velero_ver/veleroctl-linux-${ARCH}.sha256"
  # Verify the downloaded binary matches the checksum.
  run line '$LINENO';echo "$(cat veleroctl-linux-${ARCH}.sha256 | awk '{print $1}') veleroctl-linux-${ARCH}" | sha256sum --check
  run line '$LINENO';sudo install veleroctl-linux-${ARCH} /usr/local/bin/veleroctl;veleroctl version
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

# Step 16: Install Velero (using modified Official to pin to Velero Nodes)
echo -e " \033[32;5mInstalling Velero - It can take a while for all pods to deploy...\033[0m"
kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/Velero/velero.yaml
kubectl get pods \
--namespace velero-system \
--watch

# Step 17: Print out confirmation

kubectl get nodes
kubectl get svc -n velero-system

echo -e " \033[32;5mHappy Kubing! Access Velero through Rancher UI\033[0m"
