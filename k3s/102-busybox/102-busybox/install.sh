#!/bin/bash
# Busybox install
# ./102-busybox/install.sh -n busybox -s ./k3s-HA.yaml -i v1.7.2
# Busybox uninstall
# ./102-busybox/install.sh -n busybox -u v1.7.2

source ./../vlib.bash

busybox-check-version()
{
  #busybox_latest=$(curl -sL https://api.github.com/repos/busybox/busybox/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  busybox_latest=$(curl -sL https://api.github.com/repos/busybox/busybox/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  busybox_ver="$1"
  if [ -z $busybox_ver ]; then busybox_ver=$busybox_latest; fi
  if ! [ -z $2 ]; then
    if ! [ "$busybox_latest" == "$busybox_ver" ]; then
      warn "Latest version of Busybox: '$busybox_latest', but installing: '$busybox_ver'\n"
    fi
  fi
}
busybox-install-new()
{
  # https://wiki.musl-libc.org/building-busybox
  # https://github.com/docker-library/repo-info/blob/master/repos/busybox/remote/musl.md
  # https://kubernetes.io/docs/concepts/scheduling-eviction/

  # NFS subdir
  # https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/tree/master
  # https://hbayraktar.medium.com/how-to-setup-dynamic-nfs-provisioning-in-a-kubernetes-cluster-cbf433b7de29
  # https://geek-cookbook.funkypenguin.co.nz/kubernetes/persistence/nfs-subdirectory-provider/
  # https://sleeplessbeastie.eu/2024/01/04/how-to-install-nfs-subdir-external-provisioner/

  # NFS
  # https://github.com/kubernetes-csi/csi-driver-nfs
  # https://www.itwonderlab.com/kubernetes-nfs/

  # SMB
  # https://github.com/kubernetes-csi/csi-driver-smb/blob/master/deploy/example/e2e_usage.md
  # https://rguske.github.io/post/using-windows-smb-shares-in-kubernetes/
  # https://docs.aws.amazon.com/filegateway/latest/files3/use-smb-csi.html

  if ! [[ -e ${k3s_settings} ]]; then
    err_and_exit "Cluster plan file '${k3s_settings}' is not found" ${LINENO};
  fi
  #echo $node_root_password
  if [[ -z $node_root_password ]]; then
    node_root_password=""
    vlib.read-password node_root_password "Please enter root password for cluster nodes:"
    echo
  fi

  hl.blue "$parent_step$((++install_step)). Busybox installation. (Line:$LINENO)"
  if command kubectl get deploy busybox -n busybox-system &> /dev/null; then
    err_and_exit "Busybox already installed."  ${LINENO} "$0"
  fi

}
busybox-uninstall()
{
  hl.blue "$parent_step$((++install_step)). Uninstalling Busybox. (Line:$LINENO)"

  if ! command kubectl get deploy busybox -n busybox-system &> /dev/null; then
    err_and_exit "Busybox not installed yet."  ${LINENO} "$0"
  fi

  if ! command kubectl get deploy -l app.kubernetes.io/version=$busybox_ver -n busybox-system &> /dev/null; then
    err_and_exit "Trying uninstall Busybox version '$busybox_ver', but this version is not installed."  ${LINENO} "$0"
  fi

  # busybox_installed_ver=$( busyboxctl version )
  # if ! [ $busybox_installed_ver == $busybox_ver ]; then
  #   err_and_exit "Trying uninstall Busybox version '$busybox_ver', but expected '$busybox_installed_ver'."  ${LINENO} "$0"
  # fi

  # manually deleting stucked-namespace
  #kubectl get namespace "busybox-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/busybox-system/finalize -f -
  #kubectl get namespace "stucked-namespace" -o json \
  #  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  #  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

  # busybox deleting-confirmation-flag
  # kubectl get lhs -n busybox-system
  # can be edit in k9s or apply deleting-confirmation-flag.yaml
  local dir="$(dirname "$0")"
  #run "line $LINENO;kubectl -n busybox-system patch -p '{\"value\": \"true\"}' --type=merge lhs deleting-confirmation-flag"
  #run "line $LINENO;helm uninstall busybox -n busybox-system"
  #run "line $LINENO;kubectl apply -f ./101-busybox/deleting-confirmation-flag.yaml"

  run "line $LINENO;kubectl create -f https://raw.githubusercontent.com/busybox/busybox/$busybox_ver/uninstall/uninstall.yaml"
  #kubectl get job/busybox-uninstall -n busybox-system -w

  # https://medium.com/@sirtcp/how-to-resolve-stuck-kubernetes-namespace-deletions-by-cleaning-finalizers-38190bf3165f
  # Get all resorces
  #kubectl api-resources
  # Get all resorces for namespace
  #kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n busybox-system

  # kubectl wait --for jsonpath='{.status.state}'=AtLatestKnown sub mysub -n myns --timeout=3m
  #run "line '$LINENO';wait-for-success 'kubectl wait --for=condition=complete job/busybox-uninstall -n busybox-system'"
  run "line '$LINENO';kubectl wait --for=condition=complete job/busybox-uninstall -n busybox-system --timeout=5m"
  #run "line '$LINENO';wait-for-success \"kubectl get job/busybox-uninstall -n busybox-system -o jsonpath='{.status.conditions[?(@.type==\"Complete\")].status}' | grep True\""

  # crd_array=(backingimagedatasources backingimagemanagers backingimages backupbackingimages backups backuptargets /
  #   backupvolumes engineimages engines instancemanagers nodes orphans recurringjobs replicas settings sharemanagers /
  #   snapshots supportbundles systembackups systemrestores volumeattachments volumes)
  # for crd in "${crd_array[@]}"; do
  #   run "line '$LINENO';kubectl patch crd $crd -n busybox-system -p '{"metadata":{"finalizers":[]}}' --type=merge"
  #   run "line '$LINENO';kubectl delete crd $crd -n busybox-system"
  #   #run "line '$LINENO';kubectl delete crd $crd"
  # done

  run "line '$LINENO';kubectl delete namespace busybox-system"
  run "line '$LINENO';kubectl delete storageclass busybox-ssd"
  run "line '$LINENO';kubectl delete storageclass busybox-nvme"

  run "line '$LINENO';kubectl delete namespace busybox-system"
}
busybox-upgrade()
{
  busybox-backup

  run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/busybox/busybox/$busybox_ver/deploy/busybox.yaml"
  run "line '$LINENO';vlib.wait-for-success 'kubectl rollout status deployment busybox-driver-deployer -n busybox-system'"
  run "line '$LINENO';vlib.wait-for-success 'kubectl wait --for=condition=ready pod -l app=instance-manager -n busybox-system --timeout=5m'"

  # if timeout when upgrade
  busybox-restore
}
busybox-backup()
{
  # https://busybox.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://busybox.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/create-a-backup-via-csi/
  echo kuku
}
busybox-restore()
{
  # https://busybox.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://busybox.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/restore-a-backup-via-csi/#restore-a-backup-that-has-no-associated-volumesnapshot
  echo kuku
}
check-busybox-exclusive-params()
{
  if [[ busybox_number_exclusive_params -gt 0 ]]; then
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
Busybox installation script.

Options:
  -o # show output of executed commands, not show is default
  -v # bashmatic verbose
  -d # bashmatic debug
  -n namespace name
  -w nodeRootPassword # need if called from parent script
  -t parentScriptStep # need if called from parent script
  -s cluster_plan.yaml # cluster plan for new installation
Exclusive operation options:
  -i version # Install Busybox version on current default cluster
  -u version # Uninstall Busybox version on current default cluster
  -g version # Upgrade Busybox to version on current default cluster
  -b # backup Busybox
  -r # restore Busybox
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
busybox_number_exclusive_params=0
plan_is_provided=0
if ! [[ -z $k3s_settings ]]; then 
  $plan_is_provided=1; 
fi
while getopts "ovdhs:n:w:t:i:u:g:" opt
do
  case $opt in
    s )
      if [[ $plan_is_provided -eq 1 ]]; then err_and_exit "Cluster plan is provided already" ${LINENO} "$0"; fi
      k3s_settings="$OPTARG"
      plan_is_provided=1
      vlib.cluster_plan_read
    ;;
    n )
      local busybox_namespace="$OPTARG"
    ;;
    w )
      node_root_password="$OPTARG"
    ;;
    t )
      parent_step="$OPTARG."
    ;;
    i )
      if [[ $plan_is_provided -eq 0 ]]; then err_and_exit "Cluster plan is not provided" ${LINENO} "$0"; fi
      if [[ $busybox_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((busybox_number_exclusive_params++))
      busybox-check-version "$OPTARG" 1
      busybox-install-new
    ;;
    u )
      if [[ $busybox_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((busybox_number_exclusive_params++))
      busybox-check-version "$OPTARG"
      busybox-uninstall
    ;;
    g )
      if [[ $busybox_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((busybox_number_exclusive_params++))
      busybox-check-version "$OPTARG"
      busybox-upgrade
    ;;
    b ) 
      if [[ $busybox_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((busybox_number_exclusive_params++))
      # https://github.com/busybox/busybox/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/busybox/busybox/blob/master/enhancements/20220913-busybox-system-backup-restore.md
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      busybox-backup
    ;;
    r ) 
      if [[ $busybox_number_exclusive_params -gt 0 ]]; then err_and_exit "Only one exclusive operation is allowed" ${LINENO} "$0"; fi
      ((busybox_number_exclusive_params++))
      # https://github.com/busybox/busybox/blob/master/scripts/restore-backup-to-file.sh
      # https://github.com/busybox/busybox/blob/master/enhancements/20220913-busybox-system-backup-restore.md
      err_and_exit "Not implemented yet."  ${LINENO} "$0"
      busybox-restore
    ;;
    o ) opt_show_output='show-output-on'
      if [[ $busybox_number_exclusive_params -gt 0 ]]; then err_and_exit "-o has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
      run.set-all abort-on-error show-command-on $opt_show_output
    ;;
    #v ) verbose-on
    #  if [[ $busybox_number_exclusive_params -gt 0 ]]; then err_and_exit "-v has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
    #;;
    #d ) debug-on
    #  if [[ $busybox_number_exclusive_params -gt 0 ]]; then err_and_exit "-d has to be provided before exclusive operation parameter" ${LINENO} "$0"; fi
    #;;
    h ) echo $usage
    exit 1
    ;;
    \? ) echo 'For help: ./install.sh -h'
    exit 1
    ;;
  esac
done
