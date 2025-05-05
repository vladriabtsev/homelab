#!/bin/bash
# Longhorn install
# ./install.sh version

source install-lib.sh

cert-manager-check-version()
{
  cert_manager_latest=$(curl -sL https://api.github.com/repos/cert-manager/cert-manager/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  cert_manager_ver="$1"
  if [ -z $cert_manager_ver ]; then cert_manager_ver=$cert_manager_latest; fi
  if ! [ "$cert_manager_latest" == "$cert_manager_ver" ]; then
    warn "Latest version of cert-manager: '$cert_manager_latest', but installing: '$cert_manager_ver'\n"
  fi
}
cert-manager-install-new()
{
  #echo $cert_manager_ver
  # https://cert-manager.io/docs/installation/helm/
  run "line $LINENO;helm repo add jetstack https://charts.jetstack.io --force-update"
  local dir="$(dirname "$0")"
  run "line $LINENO;helm install cert-manager jetstack/cert-manager --values $dir/values.yaml \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true \
  --set prometheus.enabled=false \
  --set webhook.timeoutSeconds=4 \
  --version $cert_manager_ver"

  # https://cert-manager.io/docs/reference/cmctl/
  if ! command -v cmctl version &> /dev/null; then
    echo -e " cert-manager CLI not found, installing ..."
    run "line '$LINENO';brew install cmctl"
  fi

  # https://cert-manager.io/docs/concepts/issuer/
  # https://cert-manager.io/docs/configuration/issuers/
  # https://cert-manager.io/docs/configuration/ca/
}
cert-manager-remove()
{
  # https://cert-manager.io/docs/installation/helm/
  run "line $LINENO;kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges --all-namespaces"
  run "line $LINENO;helm uninstall cert-manager -n cert-manager"

exit

  if ! command kubectl get deploy cert-manager-ui -n cert-manager-system &> /dev/null; then
    err_and_exit "Longhorn not installed yet."  ${LINENO} "$0"
  fi

  cert-manager_installed_ver=$( longhornctl version )
  if ! [ $cert-manager_installed_ver == $cert-manager_ver ]; then
    err_and_exit "Trying uninstall Longhorn version '$cert-manager_ver', but expected '$cert-manager_installed_ver'."  ${LINENO} "$0"
  fi

  # manually deleting stucked-namespace
  #kubectl get namespace "cert-manager-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/cert-manager-system/finalize -f -
  #kubectl get namespace "stucked-namespace" -o json \
  #  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  #  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

  # longhorn deleting-confirmation-flag
  # kubectl get lhs -n cert-manager-system
  # can be edit in k9s or apply deleting-confirmation-flag.yaml
  run "line "$LINENO";kubectl apply -f ./102-longhorn/deleting-confirmation-flag.yaml -n cert-manager-system"

  run "line "$LINENO";kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/$cert-manager_ver/uninstall/uninstall.yaml"
  #kubectl get job/cert-manager-uninstall -n cert-manager-system -w
  
  local wait_time=0
  local wait_period=10
  local wait_timeout=300
  until kubectl get job/cert-manager-uninstall -n cert-manager-system -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' | grep True ; 
  do 
    sleep $wait_period
    ((wait_time+=wait_period))
    if [[$wait_time -gt $wait_timeout]]; then
      err_and_exit "Timeout. Wait time $wait_time sec"  ${LINENO} "$0"
    fi
  done

  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$cert-manager_ver/deploy/longhorn.yaml"
  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$cert-manager_ver/uninstall/uninstall.yaml"
}
cert-manager-upgrade()
{
  #echo $cert_manager_ver
  # https://cert-manager.io/docs/installation/helm/
  run "line $LINENO;helm repo add jetstack https://charts.jetstack.io --force-update"
  run "line $LINENO;helm upgrade --reset-then-reuse-values --version $cert_manager_ver cert-manager jetstack/cert-manager -n cert-manager"
}
cert-manager-reinstall()
{
  #echo $cert_manager_ver
  # https://cert-manager.io/docs/installation/helm/
  run "line $LINENO;helm repo add jetstack https://charts.jetstack.io --force-update"
  run "line $LINENO;helm upgrade --reset-then-reuse-values --version $cert_manager_ver cert-manager jetstack/cert-manager -n cert-manager"
}
cert-manager-backup()
{
  # https://cert-manager.io/docs/devops-tips/backup/
  local dir="$(dirname "$1")"
  [[ -d $dir ]] || {
    err_and_exit "Directory $dir is not exists."  ${LINENO} "$0"
  }
  if [[ -f $1 ]]; then
    run.ui.ask "Backup file '$1' already exist. Override?" || exit 1
  fi
  #run "if ! test -e ~/backups; then mkdir ~/backups; fi"
  run kubectl get --all-namespaces -oyaml issuer,clusterissuer,cert > $1
}
cert-manager-restore()
{
  # https://cert-manager.io/docs/devops-tips/backup/
  [[ -f $1 ]] || {
    err_and_exit "Backup file '$1' is not exists."  ${LINENO} "$0"
  }
  run "kubectl apply -f <(awk '!/^ *(resourceVersion|uid): [^ ]+$/' $1)"
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
cert-manager installation script.

Options:
  -i version # Install cert-manager version on current default cluster
  -u version # Uninstall cert-manager version on current default cluster
  -g version # Upgrade cert-manager to version on current default cluster. One by one versions
  -G version # Reinstall/Upgrade cert-manager to version on current default cluster
  -b file # backup Longhorn
  -r file # restore Longhorn
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

while getopts "i:u:g:G:r:b:r:ovdh" opt
do
  case $opt in
    i )
      cert-manager-check-version "$OPTARG"
      cert-manager-install-new
    ;;
    u )
      cert-manager-check-version "$OPTARG"
      cert-manager-remove
    ;;
    g )
      cert-manager-check-version "$OPTARG"
      cert-manager-upgrade
    ;;
    G )
      cert-manager-check-version "$OPTARG"
      cert-manager-reinstall
    ;;
    b )
      cert-manager-backup "$OPTARG"
    ;;
    r )
      cert-manager-restore "$OPTARG"
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

