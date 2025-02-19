#!/bin/bash
# ./install-k3s.sh -i new ./k3s-HA.yaml

source ./../k8s.sh
#source ./../bashlib/bash_lib.sh
#VLADNET_BASH_SOURCED

# https://web.archive.org/web/20230401201759/https://wiki.bash-hackers.org/scripting/debuggingtips
#export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

# https://www.shell-tips.com/bash/debug-script/#gsc.tab=0
# bash.pdf page: 73
#set -v # Enabling verbose Mode (print every line before it's processed). +v for disable
#set -n # Syntax Checking Using noexec Mode. +n for disable
#set -x # Debugging Using xtrace Mode. +x for disable
#set -u # Identifying Unset Variables. +u for disable
#set -e # Same as -o errexit
#set -u # Identifying Unset Variables. +u for disable
#set -u # Identifying Unset Variables. +u for disable

# trap 'echo "Line- ${LINENO}: five_val=${five_val}, two_val=${two_val}, total=${total}" ' DEBUG
# apt install shellcheck # https://linuxsimply.com/bash-scripting-tutorial/error-handling-and-debugging/debugging/bash-shellcheck/#How_to_Install_ShellCheck_on_Ubuntu
# shellcheck ./k3s.sh

# Remove Windows CR from bash script
# sed -i -e 's/\r$//' scriptname.sh

# Functions
install_tools()
{
    # For testing purposes - in case time is wrong due to VM snapshots
    sudo timedatectl set-ntp off
    sudo timedatectl set-ntp on

    # Copy SSH certs to ~/.ssh and change permissions
    if [[ -z $cert_name ]]; then
      run "line '$LINENO';cp /home/$user/ssh/{$certName,$certName.pub} /home/$user/.ssh"
      run "line '$LINENO';chmod 600 /home/$user/.ssh/$certName"
      run "line '$LINENO';chmod 644 /home/$user/.ssh/$certName.pub"
    fi

    # Install k3sup to local machine if not already present
    if ! command -v k3sup version &> /dev/null; then
      run "line '$LINENO';curl -sLS https://get.k3sup.dev | sh"
      run "line '$LINENO';sudo install k3sup /usr/local/bin/"
    fi

    # Install Kubectl if not already present
    if ! command -v kubectl version &> /dev/null; then
      echo -e " Kubectl not found, installing ..."
      run "line '$LINENO';curl -LO 'https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl'"
      run "line '$LINENO';sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
    fi

    # Install helm
    if ! command -v helm version &> /dev/null; then
      echo -e " Helm not found, installing ..."
      run "line '$LINENO';curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
      run "line '$LINENO';chmod 700 get_helm.sh"
      run "line '$LINENO';./get_helm.sh"
      run "line '$LINENO';rm ./get_helm.sh"
    fi

    # Install brew https://brew.sh/
    if ! command -v brew help &> /dev/null; then
      err_and_exit "Homebrew not found, please install ..."  ${LINENO} "$0"
      #/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      #run "line '$LINENO';curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
      #run "line '$LINENO';chmod 700 install.sh"
      #run "line '$LINENO';./install.sh"
      #run "line '$LINENO';rm ./install.sh"
    fi
}

gen_kube_vip_manifest()
{
  #local version
  #run "curl -o ~/tmp/rbac.yaml https://kube-vip.io/manifests/rbac.yaml" || exit 1
  #run "scp -i ~/.ssh/$cert_name ~/tmp/rbac.yaml $node_user@$node_ip4:~/rbac.yaml" || exit 1
  #run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo mkdir -p /var/lib/rancher/k3s/server/manifests/'" || exit 1
  #run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo mv ~/rbac.yaml /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml'" || exit 1
  
  #run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo curl -O https://kube-vip.io/manifests/rbac.yaml'" || exit 1
  #run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo mkdir -p /var/lib/rancher/k3s/server/manifests/'" || exit 1
  #run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo mv rbac.yaml /var/lib/rancher/k3s/server/manifests/kube-vip-rbac.yaml'" || exit 1
  
  
  inf "Generate a kube-vip DaemonSet Manifest. (Line:$LINENO)\n"
  # https://kube-vip.io/docs/installation/daemonset/#generating-a-manifest
  # https://gist.github.com/dmancloud/3bdb3fdf2eaa3e2d42428f4a90de67a9
  #if [ "$node_id" -eq "1" ]; then
  #fi
  if [ -z $kube_vip_interface ]; then
    err_and_exit "Error: Node kube_vip_interface is empty." ${LINENO} `basename $0`
  fi

  run "line '$LINENO';curl -o ~/tmp/rbac.yaml https://kube-vip.io/manifests/rbac.yaml"
  echo "---" >> ~/tmp/rbac.yaml
  # https://kube-vip.io/docs/installation/flags/
  if [[ "$kube_vip_mode" == "ARP" ]]; then
    #--services \
    run "line '$LINENO';docker run --network host --rm ghcr.io/kube-vip/kube-vip:$kube_vip_ver manifest daemonset \
    --interface $kube_vip_interface \
    --address $kube_vip_address \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --arp \
    --leaderElection \
    --enableNodeLabeling \
    >> ~/tmp/rbac.yaml"
  else # BGP mode
    err_and_exit "Not implemented yet" ${LINENO}
    #--servicesElection
    run "line '$LINENO';docker run --network host --rm ghcr.io/kube-vip/kube-vip:$kube_vip_ver manifest daemonset \
    --interface $kube_vip_interface \
    --address $kube_vip_address \
    --inCluster \
    --taint \
    --controlplane \
    --services \
    --bgp \
    --localAS 65000 \
    --bgpRouterID 192.168.0.2 \
    --bgppeers 192.168.0.10:65000::false,192.168.0.11:65000::false
    >> ~/tmp/rbac.yaml"
  fi
  if ! test -s ~/tmp/rbac.yaml; then echo "~/tmp/rbac.yaml file is empty"; echo "$LINENO"; exit 1; fi
  #while [[ $(docker inspect -f {{.State.Running}} ghcr.io/kube-vip/kube-vip:$kube_vip_ver) == "true" ]]; do
  #  sleep 1
  #done
  #if ! test -s ~/tmp/kube-vip-node.yaml; then echo "~/tmp/kube-vip-node.yaml file is empty"; fi
  run "line '$LINENO';scp -i ~/.ssh/$cert_name ~/tmp/rbac.yaml $node_user@$node_ip4:~/rbac.yaml"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S mkdir -p /var/lib/rancher/k3s/server/manifests/ <<< \"$node_root_password\"'"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S mv ~/rbac.yaml /var/lib/rancher/k3s/server/manifests/rbac.yaml <<< \"$node_root_password\"'"
  #run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo mv ~/kube-vip-node.yaml /var/lib/rancher/k3s/server/manifests/kube-vip-node.yaml'" || exit 1
}
install_kube_vip()
{
  #inf "Upload kube-vip RBAC Manifest. (Line:$LINENO)\n"
  if [[ $kube_vip_use -eq 1 ]]; then gen_kube_vip_manifest; fi

  # https://docs.k3s.io/cli/certificate#certificate-authority-ca-certificates
  # https://github.com/k3s-io/k3s/blob/master/contrib/util/generate-custom-ca-certs.sh
  # https://blog.chkpwd.com/posts/k3s-ha-installation-kube-vip-and-metallb/
  if ! [ $node_is_control_plane -eq 1 ]; then err_and_exit "Error: First node has to be part of Control Plane: '$k3s_settings'." ${LINENO}; fi
  install_k3s_cmd_parm="server";
  cluster_config_ip=$node_ip4
  if [ $kube_vip_use -eq 1 ]; then
    install_k3s_cmd_parm="$install_k3s_cmd_parm \
    --cluster-init \
    --disable traefik \
    --disable servicelb \
    --write-kubeconfig-mode 644 \
    --tls-san $kube_vip_address"
    cluster_config_ip=$kube_vip_address
  fi
  inf "Install k3s first node. (Line:$LINENO)\n"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'curl -fL https://get.k3s.io > ./install.sh;chmod 777 ./install.sh'"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'INSTALL_K3S_VERSION=${k3s_ver} sudo -S ./install.sh ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"
  #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S curl -fL https://get.k3s.io <<< \"$node_root_password\" | INSTALL_K3S_VERSION=${k3s_ver} sh -s - ${install_k3s_cmd_parm}'"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'echo \"$node_root_password\" | sudo -S cp /etc/rancher/k3s/k3s.yaml ~/k3s.yaml'"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'echo \"$node_root_password\" | sudo -S chmod 777 ~/k3s.yaml'"
  run "line '$LINENO';scp -i ~/.ssh/$cert_name $node_user@$node_ip4:./k3s.yaml ~/$cluster_name.yaml"
  run "line '$LINENO';yq -i '.clusters[0].cluster.server = \"https://${cluster_config_ip}:6443\"' ~/$cluster_name.yaml"
  run "line '$LINENO';cp ~/$cluster_name.yaml ~/.kube/$cluster_name"
  #check_result $LINENO
  #run cp --backup=t ~/$cluster_name.yaml ~/.kube/$cluster_name
  run "line '$LINENO';chown $USER ~/.kube/$cluster_name"
  #check_result $LINENO
  # https://ss64.com/bash/chmod.html
  run "line '$LINENO';chmod 600 ~/.kube/$cluster_name"
  #check_result $LINENO
  run "line '$LINENO';rm ~/$cluster_name.yaml"
  #check_result $LINENO
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'rm ~/k3s.yaml'"
  cluster_token="$(ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name echo \"$node_root_password\" | sudo -S cat /var/lib/rancher/k3s/server/node-token)"
}
remove_kubernetes_first_node()
{
  if [[ $2 -eq 1 ]]; then
    run "line '$LINENO';kubectl --kubeconfig ~/.kube/${cluster_name} delete daemonset kube-vip-ds -n kube-system"
    run "line '$LINENO';rm ~/.kube/${cluster_name}"
    run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S rm -f /var/lib/rancher/k3s/server/tls/* <<< \"$node_root_password\"'"
  fi
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'if sudo -S test -e /usr/local/bin/k3s-uninstall.sh; then /usr/local/bin/k3s-uninstall.sh; fi <<< \"$node_root_password\"'"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S rm -rf /var/lib/rancher /etc/rancher ~/.kube/* <<< \"$node_root_password\"'"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S ip addr flush dev lo <<< \"$node_root_password\"'"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S ip addr add 127.0.0.1/8 dev lo <<< \"$node_root_password\"'"
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
install_first_node()
{
  install_step=$((install_step+1))
  if [ $opt_install_new -eq 1 ]; then
    hl.blue "$install_step. Bootstrap First k3s node $node_name($node_ip4). (Line:$LINENO)"
  else
    hl.blue "$install_step. Remove k3s node $node_name($node_ip4). (Line:$LINENO)"
  fi
  # https://docs.dman.cloud/tutorial-documentation/k3sup-ha/  
  if ! test -e ~/.kube; then  mkdir ~/.kube;  fi
  p_exist=0
  if test -e "${HOME}/.kube/${cluster_name}"; then 
    if [ $opt_install_new -eq 1 ]; then
      run.ui.ask "Cluster config '${cluster_name}' already exist. Uninstall and proceed new installation?" || exit 1
    fi
    p_exist=1
    #if [ $((opt_install_new || opt_install_remove || opt_install_upgrade)) -eq 1 ]; then
    #run.ui.press-any-key "Config for cluster '${cluster_name}' already exists. Override? (^C for cancel)"
  fi
  remove_kubernetes_first_node $p_exist
    #if ! test -e ~/downloads; then mkdir ~/downloads; fi
    #if ! test -e "${HOME}/downloads/${k3s_ver}"; then 
    #  mkdir "${HOME}/downloads/${k3s_ver}";
    #  run "curl -L ${url} -o ${temp_binary}"
    #fi
  # https://kube-vip.io/docs/usage/k3s/
  # [Remotely Execute Multi-line Commands with SSH](https://thornelabs.net/posts/remotely-execute-multi-line-commands-with-ssh/)
  if [ $opt_install_new -eq 1 ]; then
    # Step 3: Generate a kube-vip DaemonSet Manifest
    install_kube_vip
  fi
  #while [[ $(kubectl get pods -l app=nginx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
  # sleep 1
  #done
}

remove_install_join_node_k3s()
{
  #echo $cluster_token
  install_k3s_cmd_parm=""
  if [[ $node_is_control_plane -eq 1 ]]; then
    install_k3s_cmd_parm="server";
    if [[ $kube_vip_use -eq 1 ]]; then
      install_k3s_cmd_parm="$install_k3s_cmd_parm \
      --disable traefik \
      --disable servicelb \
      --write-kubeconfig-mode 644 \
      --tls-san $kube_vip_address"
    fi
  fi
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'sudo -S if test -e /usr/local/bin/k3s-uninstall.sh; then /usr/local/bin/k3s-uninstall.sh; fi <<< \"$node_root_password\"'"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'sudo -S if test -e /usr/local/bin/k3s-agent-uninstall.sh; then /usr/local/bin/k3s-agent-uninstall.sh; fi <<< \"$node_root_password\"'"
  if [ $opt_install_new -eq 1 ]; then
    run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S curl -fL https://get.k3s.io | K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sh -s - ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"
  fi
}
install_join_node()
{
  install_step=$((install_step+1))
  if [ $opt_install_new -eq 1 ]; then
    hl.blue "$install_step. Join k3s node $node_name($node_ip4). (Line:$LINENO)"
  else
    hl.blue "$install_step. Remove k3s node $node_name($node_ip4). (Line:$LINENO)"
  fi
  run remove_install_join_node_k3s
}

install_check_start()
{
  # YML,JSON,XML,LUA,TOML https://mikefarah.gitbook.io/yq/how-it-works
  # https://www.baeldung.com/linux/yq-utility-processing-yaml

  #source k3s-func.sh

  if [[ $(yq --exit-status 'tag == "!!map" or tag== "!!seq"' $k3s_settings > /dev/null) ]]; then
    err_and_exit "Error: Invalid format for YAML file: '$k3s_settings'." ${LINENO}
  fi

  # SSH agent to enter id_rsa password only one time
  # https://rabexc.org/posts/pitfalls-of-ssh-agents
  # https://github.com/ccontavalli/ssh-ident
  ssh-add -l &>/dev/null
  if [ "$?" == 2 ]; then
    eval $(ssh-agent -s -t 2h) &>/dev/null
    ssh-add ~/.ssh/id_rsa
  fi

  # All root scalar settings from yaml file to bash variables
  # https://github.com/jasperes/bash-yaml
  # https://suriyakrishna.github.io/shell-scripting/2021/03/28/shell-scripting-yaml-configuration
  # https://www.baeldung.com/linux/yq-utility-processing-yaml
  eval "$( yq '.[] |(( select(kind == "scalar") | key + "='\''" + . + "'\''"))'  < $k3s_settings)"

  if ! test -e ~/tmp; then  mkdir ~/tmp;  fi

}
wait_kubectl_can_connect_cluster()
{
  # wait until cluster is ready
  timeout=160
  timeout_step=20
  duration=0
  until kubectl get nodes > /dev/null 2>&1
  do
    sleep $timeout_step
    ((duration=duration+timeout_step))
    if [ $duration -gt $timeout ]; then 
      err_and_exit "Error: Cluster is not started in $timeout seconds." ${LINENO}
    fi
  done
}

################################
##         M A I N            ##
################################
usage="Usage: `basename $0` [OPTION]... cluster_plan.yaml
Kubernetes K3s cluster installation script. 
Cluster plan is described in YAML text file.

Options:
  -i type # Install kubernetes on each node, default install only some services
     where type:
        new     # for new installation with uninstalling if already installed on node
        remove  # uninstall on each node
        upgrade # upgrade cluster on each node
        join    # join additional nodes
  -o # show output of executed commands, not show is default
  -v # bashmatic verbose
  -d # bashmatic debug
"

opt_show_output='show-output-off'
opt_ktype='k3s'
opt_install_remove=0
opt_install_new=0
opt_install_upgrade=0 

NO_ARGS=0 
E_OPTERROR=85

ARCH="amd64"

if [ $# -eq "$NO_ARGS" ] # Script invoked with no command-line args?
then
  echo $usage
  exit $E_OPTERROR # Exit and explain usage.
  # Usage: scriptname -options
  # Note: dash (-) necessary
fi

[[ -f ~/.bashmatic/init.sh ]] || {
  echo "Can't find or install Bashmatic. Exiting."
  exit 1
}
source ~/.bashmatic/init.sh

# run.set-next [options]
#   dry-run-on

while getopts "i:ovdk:h" opt
do
  case $opt in
    i )
      case $OPTARG in
        new ) opt_install_new=1;;
        remove ) opt_install_remove=1;;
        upgrade ) opt_install_upgrade=1
          err_and_exit "Not implemented yet: -i '$OPTARG'" ${LINENO}
        ;;
        join )
          err_and_exit "Not implemented yet: -i '$OPTARG'" ${LINENO}
        ;;
        * ) 
          err_and_exit "Wrong parameter argument: -i '$OPTARG'" ${LINENO}
      esac
    ;;
    o ) opt_show_output='show-output-on'
    ;;
    v ) verbose-on
    ;;
    d ) debug-on
    ;;
    k ) process option -b
    $OPTARG #is the option's argument
    ;;
    h ) echo $usage
    exit 1
    ;;
    \? ) echo 'For help: ./install-k3s.sh -h'
    exit 1
  esac
done
shift $((OPTIND-1))
#echo "Remaining args are: <${@}>"
run.set-all abort-on-error show-command-on $opt_show_output

# Check number parameters
if ! [[ $# -eq 1 ]]; then err_and_exit $usage ${LINENO}; fi

start_time=$(date +%s)
install_step=0
k3s_settings=$1

install_check_start

if [[ $opt_install_remove -eq 1 ]]; then
  h2 "Remove K3s cluster with $amount_nodes nodes. Cluster plan from '$k3s_settings' file. (Line:$LINENO)"
else
  h2 "Install K3s cluster with $amount_nodes nodes. Cluster plan from '$k3s_settings' file. (Line:$LINENO)"
fi

# export KUBECONFIG=/mnt/d/dev/homelab/k3s/kubeconfig
# kubectl config use-context local
# kubectl get node -o wide

# /usr/local/bin/k3s-uninstall.sh
# /usr/local/bin/k3s-agent-uninstall.sh

install_tools

# Amount of nodes
if [[ $amount_nodes =~ ^[0-9]{1,3}$ && $amount_nodes -gt 0 ]]; then
  inf "               amount_nodes: '$amount_nodes'\n"
else
  err_and_exit "Error: Invalid input for amount_nodes: '$amount_nodes'." ${LINENO}
fi

amount_nodes_max=$(yq '.node | length' < $k3s_settings)
if [[ $amount_nodes -gt $amount_nodes_max ]]; then
  err_and_exit "Error: Amount of real nodes is less than requested. Real: '$amount_nodes_max', requested: '$amount_nodes'." ${LINENO}
fi

# K3S Version
k3s_latest=$(curl -sL https://api.github.com/repos/k3s-io/k3s/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
if [ -z $k3s_ver ]; then
  k3s_ver=$k3s_latest
fi
if [[ $k3s_ver =~ ^v[1-2]\.[0-9]{1,2}\.[0-9]{1,2}\+((k3s1)|(rke2))$ ]]; then
  inf "                    k3s_ver: '$k3s_ver'\n"
else
  err_and_exit "Error: Invalid input for k3s_ver: '$k3s_ver'." ${LINENO}
fi
if ! [ "$k3s_latest" == "$k3s_ver" ]; then
  warn "Latest version of K3s: '$k3s_latest', but installing: '$k3s_ver'\n"
fi

# kube vip
if [[ $kube_vip_use -eq 1 ]]; then
  #kvversion_latest=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
  kvversion_latest=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  if [ -z $kube_vip_ver ]; then
    $kube_vip_ver=$kvversion_latest
  fi
  # Version of Kube-VIP to deploy
  if [[ $kube_vip_ver =~ ^v[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
    inf "               kube_vip_ver: '$kube_vip_ver'\n"
  else
    err_and_exit "Error: Invalid input for kube_vip_ver: '$kube_vip_ver'." ${LINENO}
  fi
  if ! [ "$kvversion_latest" == "$kube_vip_ver" ]; then
    warn "Latest version kube-vip: '$kvversion_latest', but installing: '$kube_vip_ver'\n"
  fi

  # kube-vip-cloud-provider
  #kvcloudversion_latest=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip-cloud-provider/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  #if [ -z $kube_vip_cloud_provider_ver ]; then
  #  $kube_vip_cloud_provider_ver=$kvcloudversion_latest
  #fi
  #inf "kube_vip_cloud_provider_ver: '$kube_vip_cloud_provider_ver'\n"
  #if ! [ "$kvcloudversion_latest" == "$kube_vip_cloud_provider_ver" ]; then
  #  warn "Latest version kube-vip-cloud-provider: '$kvcloudversion_latest', but installing: '$kube_vip_cloud_provider_ver'\n"
  #fi

  # Kube-VIP mode
  if ! [[ "$kube_vip_mode" == "ARP" || "BGP" ]]; then
    err_and_exit "Error: Invalid kube_vip_mode: '$kube_vip_mode'. Expected 'ARP' or 'BGP'." ${LINENO}
  fi
  inf "              kube_vip_mode: '$kube_vip_mode'\n"
fi

# MetalLB
#metal_lb_latest=$(curl -sL https://api.github.com/repos/metallb/metallb/releases | jq -r ".[0].tag_name")
metal_lb_latest=$(curl -sL https://api.github.com/repos/metallb/metallb/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
if [ -z $metal_lb_ver ]; then
  $metal_lb_ver=$metal_lb_latest
fi
inf "               metal_lb_ver: '$kube_vip_cloud_provider_ver'\n"
if ! [ "$metal_lb_latest" == "$metal_lb_ver" ]; then
  warn "Latest version MetalLB: '$metal_lb_latest', but installing: '$metal_lb_ver'\n"
fi

if [ $((opt_install_new || opt_install_remove || opt_install_upgrade)) -eq 1 ]; then # install on nodes
  # Nodes
  #readarray nodes < <(yq '.nodes[] |= sort_by(.node_id)' < $k3s_settings)
  readarray nodes < <(yq -o=j -I=0 '.node[]' < $k3s_settings)

  i_node=0
  for node in "${nodes[@]}"; do
    eval "$( yq '.[] | ( select(kind == "scalar") | key + "='\''" + . + "'\''")' <<<$node)"
    #inf "          k3s_node: id='$node_id', ip4='$node_ip4', eth='$kube_vip_interface', control plane='$node_is_control_plane', worker='$node_is_worker', name='$node_name', user='$node_user'"
    # k3s installation
    if [[ $i_node -eq 0 ]]; then # first cluster node
      first_node_address=$node_ip4

      node_root_password=""
      read-password node_root_password "Please enter root password for cluster nodes:"
      echo
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo -S rm -rfd /var/lib/kuku                                  <<< \"$node_root_password\"\""
      if [[ $first_node_address = "localhost" ]]; then
        err_and_exit "Not implemented yet" ${LINENO}
        k3sup install --local --local-path ~/.kube/local \
          --k3s-version $k3s_ver #\
          #--k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=$master1 --node-taint node-role.kubernetes.io/master=true:NoSchedule"
        inf "Updated kube config file is created: ~/.kube/local "
        inf "Config from file '~/.kube/local' is exported. Use 'ek local' to set local in KUBECONFIG env"
        inf "To uninstall: '/usr/local/bin/k3s-uninstall.sh' and may be restart computer"
      else
        install_first_node
      fi
    else # additional node join cluster
        install_join_node
    fi
    node_disks 1
    ((i_node++))
    if [ $i_node -eq $amount_nodes ]; then break; fi
  done
  if [ $opt_install_remove -eq 1 ]; then
    unset KUBECONFIG
    #rm $HOME/.kube/$cluster_name
    inf "Kubernetes cluster '$cluster_name' is uninstalled from servers described in cluster plan YAML file '$k3s_settings'\n"
    exit 1
  fi
  export KUBECONFIG=$HOME/.kube/$cluster_name
  run "line '$LINENO';wait_kubectl_can_connect_cluster"
  if [ $opt_install_new -eq 1 ]; then
    inf "New kubernetes cluster '$cluster_name' is installed on servers described in cluster plan YAML file '$k3s_settings'\n"
    inf "To use kubectl: Run 'export KUBECONFIG=$HOME/.kube/$cluster_name' or 'ek $cluster_name'\n"
  fi
  if [ $opt_install_upgrade -eq 1 ]; then
    inf "Kubernetes cluster '$cluster_name' is updated on servers described in cluster plan YAML file '$k3s_settings'\n"
  fi
fi

# https://kube-vip.io/docs/usage/cloud-provider/
# https://kube-vip.io/docs/usage/cloud-provider/#install-the-kube-vip-cloud-provider
install_step=$((install_step+1))
hl.blue "$install_step. Install the kube-vip Cloud Provider. (Line:$LINENO)"
run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml"
#run kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/$kube_vip_cloud_provider_ver/deploy/kube-vip-cloud-controller.yaml
run "line '$LINENO';kubectl create configmap -n kube-system kubevip --from-literal range-global=$kube_vip_lb_range"

# Longhorn
# https://longhorn.io/docs/1.7.2/deploy/install/install-with-kubectl/
install_step=$((install_step+1))
hl.blue "$install_step. Install Longhorn. (Line:$LINENO)"
./102-longhorn/install.sh -i $longhorn_ver

exit

# Rancher
install_step=$((install_step+1))
hl.blue "$install_step. Install Rancher. (Line:$LINENO)"
./105-rancher/install.sh -i $rancher_ver

# pi-hole
if [[ $pi_hole_use -eq 1 ]]; then
  install_step=$((install_step+1))
  hl.blue "$install_step. Install Pi-hole. (Line:$LINENO)"
  ./101-pi-hole/install.sh -i $pi_hole_ver
fi


# longhorn_latest=$(curl -sL https://api.github.com/repos/longhorn/longhorn/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
# if [ -z $longhorn_ver ]; then
#   longhorn_ver=$longhorn_latest
# fi
# if ! [ "$longhorn_latest" == "$longhorn_ver" ]; then
#   warn "Latest version of Longhorn: '$longhorn_latest', but installing: '$longhorn_ver'\n"
# fi
# run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/deploy/longhorn.yaml"
# # https://longhorn.io/docs/1.7.2/advanced-resources/longhornctl/install-longhornctl/
# if ! ($(longhornctl version > /dev/null ) || $(longhornctl version) != $longhorn_ver ); then
#   # Download the release binary.
#   run "line '$LINENO';curl -LO "https://github.com/longhorn/cli/releases/download/$longhorn_ver/longhornctl-linux-${ARCH}""
#   # Download the checksum for your architecture.
#   run line '$LINENO';curl -LO "https://github.com/longhorn/cli/releases/download/$longhorn_ver/longhornctl-linux-${ARCH}.sha256"
#   # Verify the downloaded binary matches the checksum.
#   run line '$LINENO';echo "$(cat longhornctl-linux-${ARCH}.sha256 | awk '{print $1}') longhornctl-linux-${ARCH}" | sha256sum --check
#   run line '$LINENO';sudo install longhornctl-linux-${ARCH} /usr/local/bin/longhornctl;longhornctl version
# fi

# https://argo-cd.readthedocs.io/en/stable/
install_step=$((install_step+1))
hl.blue "$install_step. Install Argo CD. (Line:$LINENO)"
argo_cd_latest=$(curl -sL https://api.github.com/repos/argoproj/argo-cd/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
if [ -z $argo_cd_ver ]; then
  argo_cd_ver=$argo_cd_latest
fi
if ! ($(kubectl get namespace argocd > /dev/null )); then kubectl create namespace argocd; fi
kubectl "line '$LINENO';kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/$argo_cd_ver/manifests/install.yaml"
kubectl "line '$LINENO';kubectl apply -f ./argocd/svc.yaml"




end_time=$(date +%s)
echo "Elapsed Time: $(($end_time-$start_time)) seconds"
exit

# https://ranchermanager.docs.rancher.com/getting-started/installation-and-upgrade/install-upgrade-on-a-kubernetes-cluster
install_step=$((install_step+1))
hl.blue "$install_step. Install Rancher. (Line:$LINENO)"
rancher_latest=$(curl -sL https://api.github.com/repos/rancher/rancher/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
if [ -z $rancher_ver ]; then
  rancher_ver=$rancher_latest
fi
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
#if ! [ "$rancher_latest" == "$rancher_ver" ]; then
#  warn "Latest version of Rancher: '$rancher_latest', but installing: '$rancher_ver'\n"
#fi
if ! ($(kubectl get namespace cattle-system > /dev/null )); then kubectl create namespace cattle-system; fi
# helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
#run kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/deploy/longhorn.yaml

install_step=$((install_step+1))
hl.blue "$install_step. Install Metallb. (Line:$LINENO)"
run kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
run kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/$metal_lb_ver/config/manifests/metallb-native.yaml
run kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=component=controller \
                --timeout=120s
kubectl apply -f ipAddressPool.yaml
kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/l2Advertisement.yaml



kubectl get nodes
kubectl get svc
kubectl get pods --all-namespaces -o wide

exit

  run ssh -t $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo curl -fL https://get.k3s.io | INSTALL_K3S_VERSION=${k3s_ver} sh -s - ${install_k3s_cmd_parm}'





exit

#read -p "Local K3s installation (y/n): " k3s_local_install
#if [[ "$k3s_local_install" =~ [^yn] ]]; then
#  echo "Error: Invalid input."
#  exit 1
#fi

#############################################
#            DO NOT EDIT BELOW              #
#############################################

exit


# Create SSH Config file to ignore checking (don't use in production!)
sed -i '1s/^/StrictHostKeyChecking no\n/' ~/.ssh/config

#add ssh keys for all nodes
for node in "${all[@]}"; do
  ssh-copy-id $user@$node
done

# Install policycoreutils for each node
for newnode in "${all[@]}"; do
  ssh $user@$newnode -i ~/.ssh/$certName sudo su <<EOF
  NEEDRESTART_MODE=a apt install policycoreutils -y
  exit
EOF
  echo -e " \033[32;5mPolicyCoreUtils installed!\033[0m"
done

# Step 1: Bootstrap First k3s Node
mkdir ~/.kube
k3sup install \
  --ip $master1 \
  --user $user \
  --tls-san $vip \
  --cluster \
  --k3s-version $k3sVersion \
  --k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=$master1 --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
  --merge \
  --sudo \
  --local-path $HOME/.kube/config \
  --ssh-key $HOME/.ssh/$certName \
  --context k3s-ha
echo -e " \033[32;5mFirst Node bootstrapped successfully!\033[0m"

# Step 2: Install Kube-VIP for HA
kubectl apply -f https://kube-vip.io/manifests/rbac.yaml

# Step 3: Download kube-vip
curl -sO https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/kube-vip
cat kube-vip | sed 's/$interface/'$interface'/g; s/$vip/'$vip'/g' > $HOME/kube-vip.yaml

# Step 4: Copy kube-vip.yaml to master1
scp -i ~/.ssh/$certName $HOME/kube-vip.yaml $user@$master1:~/kube-vip.yaml


# Step 5: Connect to Master1 and move kube-vip.yaml
ssh $user@$master1 -i ~/.ssh/$certName <<- EOF
  sudo mkdir -p /var/lib/rancher/k3s/server/manifests
  sudo mv kube-vip.yaml /var/lib/rancher/k3s/server/manifests/kube-vip.yaml
EOF

# Step 6: Add new master nodes (servers) & workers
for newnode in "${masters[@]}"; do
  k3sup join \
    --ip $newnode \
    --user $user \
    --sudo \
    --k3s-version $k3sVersion \
    --server \
    --server-ip $master1 \
    --ssh-key $HOME/.ssh/$certName \
    --k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=$newnode --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
    --server-user $user
  echo -e " \033[32;5mMaster node joined successfully!\033[0m"
done

# add workers
for newagent in "${workers[@]}"; do
  k3sup join \
    --ip $newagent \
    --user $user \
    --sudo \
    --k3s-version $k3sVersion \
    --server-ip $master1 \
    --ssh-key $HOME/.ssh/$certName \
    --k3s-extra-args "--node-label \"longhorn=true\" --node-label \"worker=true\""
  echo -e " \033[32;5mAgent node joined successfully!\033[0m"
done

# Step 7: Install kube-vip as network LoadBalancer - Install the kube-vip Cloud Provider
kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml

# Step 8: Install Metallb
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
# Download ipAddressPool and configure using lbrange above
curl -sO https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/ipAddressPool
cat ipAddressPool | sed 's/$lbrange/'$lbrange'/g' > $HOME/ipAddressPool.yaml

# Step 9: Test with Nginx
kubectl apply -f https://raw.githubusercontent.com/inlets/inlets-operator/master/contrib/nginx-sample-deployment.yaml -n default
kubectl expose deployment nginx-1 --port=80 --type=LoadBalancer -n default

echo -e " \033[32;5mWaiting for K3S to sync and LoadBalancer to come online\033[0m"

while [[ $(kubectl get pods -l app=nginx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
   sleep 1
done

# Step 10: Deploy IP Pools and l2Advertisement
kubectl wait --namespace metallb-system \
                --for=condition=ready pod \
                --selector=component=controller \
                --timeout=120s
kubectl apply -f ipAddressPool.yaml
kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/l2Advertisement.yaml

kubectl get nodes
kubectl get svc
kubectl get pods --all-namespaces -o wide

echo -e " \033[32;5mHappy Kubing! Access Nginx at EXTERNAL-IP above\033[0m"

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
