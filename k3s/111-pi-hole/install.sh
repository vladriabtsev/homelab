#!/bin/bash
# pi-hole install
# ./101-pi-hole/install.sh -s ./k3s-ha.yaml -i v1.7.2
# pi-hole uninstall
# ./101-pi-hole/install.sh -u v1.7.2
# pi-hole upgrade
# ./101-pi-hole/install.sh -g v1.7.3

source ./../vlib.bash

pi-hole-check-version()
{
  pi_hole_latest=$(curl -sL https://api.github.com/repos/pi-hole/pi-hole/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  pi_hole_ver="$1"
  if [ -z $pi_hole_ver ]; then pi_hole_ver=$pi_hole_latest; fi
  if ! [ "$pi_hole_latest" == "$pi_hole_ver" ]; then
    warn "Latest version of pi-hole: '$pi_hole_latest', but installing: '$pi_hole_ver'\n"
  fi
}
pi-hole-install-new()
{

  kubectl create namespace pihole
  kubectl apply -f ./101-pi-hole/svc-pihole-tcp.yml
  kubectl apply -f ./101-pi-hole/svc-pihole-udp.yml
  kubectl get svc pihole-tcp -n pihole
  kubectl get svc pihole-udp -n pihole
  kubectl apply -f ./101-pi-hole/pvc-pihole.yml
  kubectl apply -f ./101-pi-hole/secret-pihole-webpassword.yaml
  kubectl apply -f ./101-pi-hole/configmap-pihole-custom-dnsmasq.yml
  kubectl apply -f ./101-pi-hole/deployment-pihole.yml

  # https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/pihole.md
  run "line $LINENO;kubectl apply -f pihole-namespace.yml"
  run "line $LINENO;kubectl create secret generic pihole-password \
    --from-literal EXTERNAL_DNS_PIHOLE_PASSWORD=pi-hole-passWord"

exit

  # https://github.com/pi-hole/pi-hole/#one-step-automated-install
  run "line $LINENO;wget -O basic-install.sh https://install.pi-hole.net"
  run "line $LINENO;sudo bash basic-install.sh"
  run "line $LINENO;rm basic-install.sh"

exit

  run "line $LINENO;helm repo add jetstack https://charts.jetstack.io --force-update"
  local dir="$(dirname "$0")"
  run "line $LINENO;helm install pi-hole jetstack/pi-hole --values $dir/values.yaml \
  --namespace pi-hole \
  --create-namespace \
  --set crds.enabled=true \
  --set prometheus.enabled=false \
  --set webhook.timeoutSeconds=4 \
  --version $pi_hole_ver"

  # https://pi-hole.io/docs/reference/cmctl/
  if ! command -v cmctl version &> /dev/null; then
    echo -e " pi-hole CLI not found, installing ..."
    run "line '$LINENO';brew install cmctl"
  fi

  # https://pi-hole.io/docs/concepts/issuer/
  # https://pi-hole.io/docs/configuration/issuers/
  # https://pi-hole.io/docs/configuration/ca/
}
pi-hole-remove()
{
  # https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/pihole.md
  run "line $LINENO;kubectl delete secret pihole-password"

exit

  if ! command kubectl get deploy pi-hole-ui -n pi-hole-system &> /dev/null; then
    err_and_exit "Longhorn not installed yet."  ${LINENO} "$0"
  fi

  pi-hole_installed_ver=$( longhornctl version )
  if ! [ $pi-hole_installed_ver == $pi-hole_ver ]; then
    err_and_exit "Trying uninstall Longhorn version '$pi-hole_ver', but expected '$pi-hole_installed_ver'."  ${LINENO} "$0"
  fi

  # manually deleting stucked-namespace
  #kubectl get namespace "pi-hole-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/pi-hole-system/finalize -f -
  #kubectl get namespace "stucked-namespace" -o json \
  #  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  #  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

  # longhorn deleting-confirmation-flag
  # kubectl get lhs -n pi-hole-system
  # can be edit in k9s or apply deleting-confirmation-flag.yaml
  run "line "$LINENO";kubectl apply -f ./102-longhorn/deleting-confirmation-flag.yaml -n pi-hole-system"

  run "line "$LINENO";kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/$pi-hole_ver/uninstall/uninstall.yaml"
  #kubectl get job/pi-hole-uninstall -n pi-hole-system -w
  
  local wait_time=0
  local wait_period=10
  local wait_timeout=300
  until kubectl get job/pi-hole-uninstall -n pi-hole-system -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' | grep True ; 
  do 
    sleep $wait_period
    ((wait_time+=wait_period))
    if [[$wait_time -gt $wait_timeout]]; then
      err_and_exit "Timeout. Wait time $wait_time sec"  ${LINENO} "$0"
    fi
  done

  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$pi-hole_ver/deploy/longhorn.yaml"
  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$pi-hole_ver/uninstall/uninstall.yaml"
}
pi-hole-upgrade()
{
  #echo $pi_hole_ver
  # https://pi-hole.io/docs/installation/helm/
  run "line $LINENO;helm repo add jetstack https://charts.jetstack.io --force-update"
  run "line $LINENO;helm upgrade --reset-then-reuse-values --version $pi_hole_ver pi-hole jetstack/pi-hole -n pi-hole"
}
pi-hole-reinstall()
{
  #echo $pi_hole_ver
  # https://pi-hole.io/docs/installation/helm/
  run "line $LINENO;helm repo add jetstack https://charts.jetstack.io --force-update"
  run "line $LINENO;helm upgrade --reset-then-reuse-values --version $pi_hole_ver pi-hole jetstack/pi-hole -n pi-hole"
}
pi-hole-backup()
{
  # https://pi-hole.io/docs/devops-tips/backup/
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
pi-hole-restore()
{
  # https://pi-hole.io/docs/devops-tips/backup/
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
pi-hole installation script.

Options:
  -i version # Install pi-hole version on current default cluster
  -u version # Uninstall pi-hole version on current default cluster
  -g version # Upgrade pi-hole to version on current default cluster. One by one versions
  -G version # Reinstall/Upgrade pi-hole to version on current default cluster
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
      pi-hole-check-version "$OPTARG"
      pi-hole-install-new
    ;;
    u )
      pi-hole-check-version "$OPTARG"
      pi-hole-remove
    ;;
    g )
      pi-hole-check-version "$OPTARG"
      pi-hole-upgrade
    ;;
    G )
      pi-hole-check-version "$OPTARG"
      pi-hole-reinstall
    ;;
    b )
      pi-hole-backup "$OPTARG"
    ;;
    r )
      pi-hole-restore "$OPTARG"
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

