#!/bin/bash
# Longhorn install
# ./install.sh version

source install-lib.sh

rancher-check-version()
{
  rancher_latest=$(curl -sL https://api.github.com/repos/rancher/rancher/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  #run rancher_latest=$(curl -sL https://api.github.com/repos/rancher/rancher/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  #run rancher_latest=$(curl -sL https://api.github.com/repos/rancher/rancher/releases | jq -r '[ .[] | select(.prerelease == false) | .tag_name ] | max_by( split(".") | map(tonumber) )')
  #echo $rancher_latest
  rancher_ver="$1"
  if [ -z $rancher_ver ]; then rancher_ver=$rancher_latest; fi

  run "line ${LINENO};cert_manager_latest=$(curl -sL https://api.github.com/cert-manager/cert-manager/rancher/rancher/releases | jq -r '[ .[] | select(.prerelease == false) | .tag_name ] | .[0]')"
  if [ -z $cert_manager_ver ]; then cert_manager_ver=$cert_manager_latest; fi


  # Helm
  #run helm_latest=$(curl -sL https://api.github.com/repos/helm/helm/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  #echo $helm_latest
  #if [ -z $helm_ver ]; then helm_ver=$helm_latest; fi
}
rancher-install-new()
{
  if ! ($(helm version > /dev/null )); then
    # https://helm.sh/
    run "line $LINENO;curl -fsSL -o ~/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
    run "line $LINENO;chmod 700 ~/get_helm.sh"
    run "line $LINENO;./get_helm.sh"
    run "line $LINENO;rm ~/get_helm.sh"
  fi
  # Add Rancher Helm Repository
  run helm repo add rancher-latest https://releases.rancher.com/server-charts/latest > /dev/null
  run kubectl create namespace cattle-system > /dev/null

  # Step 13: Install Cert-Manager
  run "line $LINENO;kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/$cert_manager_ver/cert-manager.crds.yaml"
  run "line $LINENO;helm repo add jetstack https://charts.jetstack.io"
  run "line $LINENO;helm repo update"
  run "line $LINENO;helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version $cert_manager_ver"
  kubectl get pods --namespace cert-manager

exit
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



exit



  # https://longhorn.io/docs/1.7.2/advanced-resources/longhornctl/install-longhornctl/
  if ! ($(longhornctl version > /dev/null ) || $(longhornctl version) != $rancher_ver ); then
    # Download the release binary.
    run "line '$LINENO';curl -LO "https://github.com/longhorn/cli/releases/download/$rancher_ver/longhornctl-linux-${ARCH}""
    # Download the checksum for your architecture.
    run "line '$LINENO';curl -LO 'https://github.com/longhorn/cli/releases/download/$rancher_ver/longhornctl-linux-${ARCH}.sha256'"
    # Verify the downloaded binary matches the checksum.
    run line "$LINENO";echo "$(cat longhornctl-linux-${ARCH}.sha256 | awk '{print $1}') longhornctl-linux-${ARCH}" | sha256sum --check
    run "line '$LINENO';sudo install longhornctl-linux-${ARCH} /usr/local/bin/longhornctl;longhornctl version"
  fi
  longhornctl check preflight
  run.ui.ask "Preflight errors check is finished. Proceed new installation?" || exit 1
  if command kubectl get deploy rancher-ui -n rancher-system &> /dev/null; then
    err_and_exit "Longhorn already installed."  ${LINENO} "$0"
  fi
  run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/$rancher_ver/deploy/longhorn.yaml"
  #run "line "$LINENO";kubectl create -f ./102-longhorn/backup.yaml"
}
rancher-uninstall()
{
  if ! command kubectl get deploy rancher-ui -n rancher-system &> /dev/null; then
    err_and_exit "Longhorn not installed yet."  ${LINENO} "$0"
  fi

  rancher_installed_ver=$( longhornctl version )
  if ! [ $rancher_installed_ver == $rancher_ver ]; then
    err_and_exit "Trying uninstall Longhorn version '$rancher_ver', but expected '$rancher_installed_ver'."  ${LINENO} "$0"
  fi

  # manually deleting stucked-namespace
  #kubectl get namespace "rancher-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/rancher-system/finalize -f -
  #kubectl get namespace "stucked-namespace" -o json \
  #  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  #  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

  # longhorn deleting-confirmation-flag
  # kubectl get lhs -n rancher-system
  # can be edit in k9s or apply deleting-confirmation-flag.yaml
  run "line "$LINENO";kubectl apply -f ./102-longhorn/deleting-confirmation-flag.yaml -n rancher-system"

  run "line "$LINENO";kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/$rancher_ver/uninstall/uninstall.yaml"
  #kubectl get job/rancher-uninstall -n rancher-system -w
  
  local wait_time=0
  local wait_period=10
  local wait_timeout=300
  until kubectl get job/rancher-uninstall -n rancher-system -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' | grep True ; 
  do 
    sleep $wait_period
    ((wait_time+=wait_period))
    if [[$wait_time -gt $wait_timeout]]; then
      err_and_exit "Timeout. Wait time $wait_time sec"  ${LINENO} "$0"
    fi
  done

  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$rancher_ver/deploy/longhorn.yaml"
  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$rancher_ver/uninstall/uninstall.yaml"
}
rancher-backup()
{
  err_and_exit "Not implemented yet."  ${LINENO} "$0"
}
rancher-restore()
{
  err_and_exit "Not implemented yet."  ${LINENO} "$0"
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
Rancher installation script.

Options:
  -i version # Install Rancher version on current default cluster
  -u version # Uninstall Rancher version on current default cluster
  -g version # Upgrade Rancher to version on current default cluster
  -b # backup Rancher
  -r # restore Rancher
  -o # show output of executed commands, not show is default
  -v # bashmatic verbose
  -d # bashmatic debug
"
if [ $# -eq "$NO_ARGS" ] # Script invoked with no command-line args?
then
  err "Script invoked with no command-line args\n"
  printf "$usage"
  exit $E_OPTERROR # Exit and explain usage.
  # Usage: scriptname -options
  # Note: dash (-) necessary
fi

while getopts "i:r:u:ovdh" opt
do
  case $opt in
    i )
      rancher-check-version "$OPTARG"
      rancher-install-new
    ;;
    u )
      rancher-check-version "$OPTARG"
      rancher-uninstall
    ;;
    g )
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      rancher-check-version "$OPTARG"
      rancher-upgrade
    ;;
    b ) 
      # https://github.com/longhorn/longhorn/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/longhorn/longhorn/blob/master/enhancements/20220913-rancher-system-backup-restore.md
      rancher-backup
    ;;
    r ) 
      # https://github.com/longhorn/longhorn/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/longhorn/longhorn/blob/master/enhancements/20220913-rancher-system-backup-restore.md
      rancher-restore
    ;;
    o ) opt_show_output='show-output-on'
    ;;
    v ) verbose-on
    ;;
    d ) debug-on
    ;;
    h ) echo $usage
    exit 1
    ;;
    \? ) echo 'For help: ./install.sh -h'
    exit 1
  esac
done
shift $((OPTIND-1))

exit


# https://longhorn.io/docs/1.7.2/deploy/install/install-with-kubectl/
install_step=$((install_step+1))
hl.blue "$install_step. Install Longhorn. (Line:$LINENO)"
rancher_latest=$(curl -sL https://api.github.com/repos/longhorn/longhorn/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
if [ -z $rancher_ver ]; then
  rancher_ver=$rancher_latest
fi
if ! [ "$rancher_latest" == "$rancher_ver" ]; then
  warn "Latest version of Longhorn: '$rancher_latest', but installing: '$rancher_ver'\n"
fi
run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/$rancher_ver/deploy/longhorn.yaml"
# https://longhorn.io/docs/1.7.2/advanced-resources/longhornctl/install-longhornctl/
if ! ($(longhornctl version > /dev/null ) || $(longhornctl version) != $rancher_ver ); then
  # Download the release binary.
  run "line '$LINENO';curl -LO "https://github.com/longhorn/cli/releases/download/$rancher_ver/longhornctl-linux-${ARCH}""
  # Download the checksum for your architecture.
  run line '$LINENO';curl -LO "https://github.com/longhorn/cli/releases/download/$rancher_ver/longhornctl-linux-${ARCH}.sha256"
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
--namespace rancher-system \
--watch

# Step 17: Print out confirmation

kubectl get nodes
kubectl get svc -n rancher-system

echo -e " \033[32;5mHappy Kubing! Access Longhorn through Rancher UI\033[0m"
