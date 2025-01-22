#!/bin/bash
# Longhorn install
# ./install.sh version

source install-lib.sh

longhorn-check-version()
{
  longhorn_latest=$(curl -sL https://api.github.com/repos/longhorn/longhorn/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  longhorn_ver="$1"
  if [ -z $longhorn_ver ]; then longhorn_ver=$longhorn_latest; fi
}
longhorn-install-new()
{
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
  run "line "$LINENO";kubectl apply -f ./102-longhorn/deleting-confirmation-flag.yaml -n longhorn-system"

  run "line "$LINENO";kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/uninstall/uninstall.yaml"
  #kubectl get job/longhorn-uninstall -n longhorn-system -w
  
  until kubectl get job/longhorn-uninstall -n longhorn-system -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' | grep True ; do sleep 10 ; done

  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/deploy/longhorn.yaml"
  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/uninstall/uninstall.yaml"
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
  -i version # Install Longhorn version on current default cluster
  -u version # Uninstall Longhorn version on current default cluster
  -g version # Upgrade Longhorn to version on current default cluster
  -b # backup Longhorn
  -r # restore Longhorn
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
      longhorn-check-version "$OPTARG"
      longhorn-install-new
    ;;
    u )
      longhorn-check-version "$OPTARG"
      longhorn-uninstall
    ;;
    g )
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      longhorn-check-version "$OPTARG"
      longhorn-upgrade
    ;;
    b )
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      longhorn-backup
    ;;
    r )
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      longhorn-restore
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

if ! [ "$longhorn_latest" == "$longhorn_ver" ]; then
  warn "Latest version of Longhorn: '$longhorn_latest', but installing: '$longhorn_ver'\n"
fi

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
