  #while [[ $(kubectl get pods -l app=nginx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
  # sleep 1
  #done
  # kubectl -n kube-system get secret smb-csi-creds -o jsonpath='{.data}'
  # kubectl -n kube-system get secret smb-csi-creds -o jsonpath='{.data.username}' | base64 --decode
  # kubectl -n kube-system get secret smb-csi-creds -o jsonpath='{.data.password}' | base64 --decode

# https://kubernetes.io/docs/tasks/access-application-cluster/list-all-running-container-images/
# https://kubernetes.io/docs/reference/kubectl/quick-reference/
# https://jqlang.org/
# https://www.digitalocean.com/community/tutorials/how-to-transform-json-data-with-jq
# https://kubernetes.io/docs/reference/kubectl/jsonpath/
# https://github.com/json-path/JsonPath
# https://support.smartbear.com/alertsite/docs/monitors/api/endpoint/jsonpath.html
# https://docs.hevodata.com/sources/engg-analytics/streaming/rest-api/writing-jsonpath-expressions/
function vkube-k3s.get-pod-image-version() {
  # return container image version
  [[ -z $1 ]] && vlib.error-printf "Missing namespace parameter"
  [[ -z $2 ]] && vlib.error-printf "Missing pod name parameter"
  [[ -z $3 ]] && vlib.error-printf "Missing container image name without version parameter"

  # jsonpath filtering is not working !!! https://kubernetes.io/docs/reference/kubectl/jsonpath/
  # kubectl get pods -n synology-csi -l app=synology-csi-controller -o jsonpath='{.items[0].spec.containers[?(@.name=="csi-plugin")]}' | jq '.image'
  local image=$(eval "kubectl get pods -n $1 -l app=$2 -o jsonpath='{.items[0].spec.containers[?(@.name==\"$3\")]}' | jq '.image'")
  #echo "image=$image" >&3
  local ver="${image#*:}"
  ver="${ver/%\"/}"
  #echo "ver=$ver" >&3
  echo "$ver"
}
function vkube-k3s.get-storage-class-type() { # backup2-synology-csi-nfs-test
  # return container image version
  [[ -z $1 ]] && vlib.error-printf "Missing storage class name parameter"
  #vlib.trace "storage class=$1"
  if ! command kubectl get storageclass $1 &> /dev/null; then
    err_and_exit "Storage class '$1' is not found in cluster."  ${LINENO}
  fi
  #local yaml
  #yaml=$(kubectl get storageclass $1 -o yaml | yq '.metadata.labels[] | select(.name == "vkube/storage-type")')
  #yaml=$(kubectl get storageclass $1 -o yaml  | yq '.metadata.labels.vkube/storage-type')
  #vlib.trace "yaml=$yaml"
  local type
  type=$(kubectl get storageclass $1 -o yaml  | yq '.metadata.labels.vkube/storage-type')
  #vlib.trace "storage type=$type"
  #err_and_exit "Not implemented" ${LINENO}
  echo "$type"
}
function vkube-k3s.is-app-ready() {
  if [[ $(kubectl get pods -l app=$1 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; then
    return 1
  fi
  return 0
}
function vkube-k3s.check_cluster_plan_path() {
  vlib.trace "${args[--cluster-plan]}"
  if [[ -z ${args[--cluster-plan]} ]]; then
    vlib.error-printf "Flag --cluster-plan is required.\n" >&2
  fi
  # https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_07_01.html
  if [[ -a ${args[--cluster-plan]} ]]; then # file exists
    # shellcheck disable=SC2154
    k3s_settings=${args[--cluster-plan]}
  else # file is not exists
    if ! [[ ${args[--cluster-plan]} == *"/"* ]]; then # check if path is simple word
      # trying to find 'vkube-data' in folder with vkube script
      __tmp="${vkube_folder}/vkube-data/${args[--cluster-plan]}/${args[--cluster-plan]}.yaml"
      if [[ -a $__tmp ]]; then # file exists
        k3s_settings=$__tmp
      else
        # trying to find 'vkube-data' in current folder
        __tmp2="${PWD}/vkube-data/${args[--cluster-plan]}/${args[--cluster-plan]}.yaml"
        if [[ -a $__tmp ]]; then # file exists
          k3s_settings=$__tmp2
        else
          vlib.error-printf "Can't find cluster plan file based on cluster plan parameter '%s'\n  Checked files '%s'\n  and '%s'" "${args[--cluster-plan]}" "$__tmp" "$__tmp2" >&2
        fi
      fi
    else
      vlib.error-printf "Can't find file '%s' from cluster plan parameter.\n" "${args[--cluster-plan]}" >&2
    fi
  fi
  # find vkube data folder
  #echo $k3s_settings
  vkube_data_folder=$(dirname $k3s_settings)
  #echo $vkube_data_folder
}
function vkube-k3s.cluster_plan_read() {
  # YML,JSON,XML,LUA,TOML https://mikefarah.gitbook.io/yq/how-it-works
  # https://www.baeldung.com/linux/yq-utility-processing-yaml

  #source k3s-func.sh

  if [[ $(yq --exit-status 'tag == "!!map" or tag== "!!seq"' $k3s_settings > /dev/null) ]]; then
    err_and_exit "Error: Invalid format for YAML file: '$k3s_settings'." ${LINENO}
  fi

  # All root scalar settings from yaml file to bash variables
  # https://github.com/jasperes/bash-yaml
  # https://suriyakrishna.github.io/shell-scripting/2021/03/28/shell-scripting-yaml-configuration
  # https://www.baeldung.com/linux/yq-utility-processing-yaml
  eval "$( yq '.[] |(( select(kind == "scalar") | key + "='\''" + . + "'\''"))'  < $k3s_settings)"

  if ! test -e ~/tmp; then  mkdir ~/tmp;  fi
}
function vkube-k3s.install_tools() {
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
function gen_kube_vip_manifest() {
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
  run "line '$LINENO';ssh $node_name 'sudo mkdir -p /var/lib/rancher/k3s/server/manifests/'"
  run "line '$LINENO';ssh $node_name 'sudo mv ~/rbac.yaml /var/lib/rancher/k3s/server/manifests/rbac.yaml'"
  #run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo mv ~/kube-vip-node.yaml /var/lib/rancher/k3s/server/manifests/kube-vip-node.yaml'" || exit 1
}
function remove_kubernetes_first_node() {
  inf "Uninstalling k3s first node. (Line:$LINENO)\n"
  if [[ $2 -eq 1 ]]; then
    run "line '$LINENO';kubectl --kubeconfig ~/.kube/${cluster_name} delete daemonset kube-vip-ds -n kube-system"
    run "line '$LINENO';rm ~/.kube/${cluster_name}"
    run "line '$LINENO';ssh $node_name 'sudo rm -f /var/lib/rancher/k3s/server/tls/*'"
  fi
  run "line '$LINENO';ssh $node_name 'if sudo test -e /usr/local/bin/k3s-uninstall.sh; then sudo /usr/local/bin/k3s-uninstall.sh; fi'"
  run "line '$LINENO';ssh $node_name 'sudo rm -rf /var/lib/rancher /etc/rancher ~/.kube/*'"
  run "line '$LINENO';ssh $node_name 'sudo ip addr flush dev lo'"
  run "line '$LINENO';ssh $node_name 'sudo ip addr add 127.0.0.1/8 dev lo'"
}
function uninstall_node() {
  hl.blue "$((++install_step)). Remove k3s node $node_name($node_ip4). (Line:$LINENO)"
}
function install_first_node() {
  hl.blue "$((++install_step)). Bootstrap First k3s node $node_name($node_ip4). (Line:$LINENO)"
  # https://docs.dman.cloud/tutorial-documentation/k3sup-ha/  
  if ! test -e ~/.kube; then  mkdir ~/.kube;  fi
  remove_kubernetes_first_node $p_exist
    #if ! test -e ~/downloads; then mkdir ~/downloads; fi
    #if ! test -e "${HOME}/downloads/${k3s_ver}"; then 
    #  mkdir "${HOME}/downloads/${k3s_ver}";
    #  run "curl -L ${url} -o ${temp_binary}"
    #fi
  # https://kube-vip.io/docs/usage/k3s/
  # [Remotely Execute Multi-line Commands with SSH](https://thornelabs.net/posts/remotely-execute-multi-line-commands-with-ssh/)
  
  # https://docs.k3s.io/cli/certificate#certificate-authority-ca-certificates
  # https://github.com/k3s-io/k3s/blob/master/contrib/util/generate-custom-ca-certs.sh
  # https://blog.chkpwd.com/posts/k3s-ha-installation-kube-vip-and-metallb/
  if ! [ $node_is_control_plane -eq 1 ]; then err_and_exit "Error: First node has to be part of Control Plane: '$k3s_settings'." ${LINENO}; fi
  cluster_node_ip=$node_ip4
  if [ $kube_vip_use -eq 1 ]; then
    gen_kube_vip_manifest
  fi
  install_k3s_cmd_parm="server --token kuku --cluster-init --disable traefik --disable servicelb --write-kubeconfig-mode 644 --tls-san $cluster_node_ip"
  inf "Install k3s first node. (Line:$LINENO)\n"
  run "line '$LINENO';ssh $node_name 'curl -fL https://get.k3s.io > ~/install.sh;chmod 777 ~/install.sh'"
  run "line '$LINENO';ssh $node_name 'sudo INSTALL_K3S_VERSION=${k3s_ver} ~/install.sh ${install_k3s_cmd_parm}'"
  #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "sudo INSTALL_K3S_VERSION=${k3s_ver} ~/install.sh ${install_k3s_cmd_parm} <<< \"$node_root_password\""
  #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo curl -fL https://get.k3s.io <<< \"$node_root_password\" | INSTALL_K3S_VERSION=${k3s_ver} sh -s - ${install_k3s_cmd_parm}'"
  run "line '$LINENO';ssh $node_name 'sudo cp /etc/rancher/k3s/k3s.yaml ~/k3s.yaml'"
  run "line '$LINENO';ssh $node_name 'sudo chmod 777 ~/k3s.yaml'"
  run "line '$LINENO';scp -i ~/.ssh/$cert_name $node_user@$node_ip4:~/k3s.yaml ~/$cluster_name.yaml"
  run "line '$LINENO';yq -i '.clusters[0].cluster.server = \"https://${cluster_node_ip}:6443\"' ~/$cluster_name.yaml"
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
  run "line '$LINENO';ssh $node_name 'rm ~/k3s.yaml'"
  #kubectl wait --for=condition=Ready node/$node_name
  #echo "cluster_token=$cluster_token"
  cluster_token="$(ssh $node_name 'sudo cat /var/lib/rancher/k3s/server/token')"

  #while [[ $(kubectl get pods -l app=nginx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
  # sleep 1
  #done
}
function install_join_node() {
  hl.blue "$((++install_step)). Join k3s node $node_name($node_ip4). (Line:$LINENO)"
  # https://docs.k3s.io/installation/configuration#configuration-file
  #--token $cluster_token
  install_k3s_cmd_parm="server --disable traefik --disable servicelb --token kuku --tls-san $cluster_node_ip --server https://$cluster_node_ip:6443"
  run "line '$LINENO';ssh $node_name 'if sudo test -e /usr/local/bin/k3s-uninstall.sh; then /usr/local/bin/k3s-uninstall.sh; fi'"
  run "line '$LINENO';ssh $node_name 'if sudo test -e /usr/local/bin/k3s-agent-uninstall.sh; then /usr/local/bin/k3s-agent-uninstall.sh; fi'"

  #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'curl -fL https://get.k3s.io > ./install.sh;chmod 777 ./install.sh'"
  #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'INSTALL_K3S_VERSION=${k3s_ver} sudo ./install.sh ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"

  #K3S_URL=https://192.168.100.51:6443 K3S_TOKEN=K109836edbf7c2b660b8c7515867f6da9aa59f1c75c7e46066a78e7fb63f78a62ce::server:69a6d7584a18bf32238e6f4c5cb35624 echo qpalwoskQ4.. | sudo "./install.sh server --disable traefik --disable servicelb --write-kubeconfig-mode 644 --tls-san 192.168.100.50"

  run "line '$LINENO';ssh $node_name 'curl -fL https://get.k3s.io > ~/install.sh;chmod 777 ~/install.sh'"
  #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sudo '$HOME/install.sh ${install_k3s_cmd_parm}' <<< \"$node_root_password\""
  #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sudo './install.sh ${install_k3s_cmd_parm}' <<< ${node_root_password}"
  #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'curl -fL https://get.k3s.io > ./install.sh;chmod 777 ./install.sh'"
  #ssh vlad@192.168.100.52 -i /home/vlad/.ssh/id_rsa K3S_URL=https://192.168.100.51:6443 K3S_TOKEN=K109836edbf7c2b660b8c7515867f6da9aa59f1c75c7e46066a78e7fb63f78a62ce::server:69a6d7584a18bf32238e6f4c5cb35624 sudo '/home/vlad/install.sh server --disable traefik --disable servicelb --tls-san 192.168.100.50' <<< qpalwoskQ4..
  #ssh vlad@192.168.100.52 -i /home/vlad/.ssh/id_rsa INSTALL_K3S_VERSION=v1.32.2+k3s1 K3S_URL=https://192.168.100.51:6443 K3S_TOKEN=K109836edbf7c2b660b8c7515867f6da9aa59f1c75c7e46066a78e7fb63f78a62ce::server:69a6d7584a18bf32238e6f4c5cb35624 sudo '/home/vlad/install.sh server --disable traefik --disable servicelb --tls-san 192.168.100.50' <<< qpalwoskQ4..
  #echo ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "INSTALL_K3S_VERSION=${k3s_ver} sudo ~/install.sh ${install_k3s_cmd_parm} <<< ${node_root_password}"
  #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "sudo ./install.sh ${install_k3s_cmd_parm} <<< \"$node_root_password\""
  #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "INSTALL_K3S_VERSION=${k3s_ver} K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sudo '~/install.sh ${install_k3s_cmd_parm}' <<< ${node_root_password}"
  #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "INSTALL_K3S_VERSION=${k3s_ver} sudo ~/install.sh ${install_k3s_cmd_parm} <<< ${node_root_password}"
  run "line '$LINENO';ssh $node_name 'sudo INSTALL_K3S_VERSION=${k3s_ver} ./install.sh ${install_k3s_cmd_parm}'"

  #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'curl -fL https://get.k3s.io | K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sudo sh -s - ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"
  #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo curl -fL https://get.k3s.io | K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sh -s - ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"
  #kubectl get nodes
  # sudo journalctl -xeu k3s.service # check k3s log on node
  # ls /var/lib/ca-certificates/pem
  # ls -l /etc/ssl/certs
}
function wait_kubectl_can_connect_cluster() {
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
function _install_all() {
  i_node=0
  for node in "${nodes[@]}"; do
      eval "$( yq '.[] | ( select(kind == "scalar") | key + "='\''" + . + "'\''")' <<<$node)"
      #inf "          k3s_node: id='$node_id', ip4='$node_ip4', eth='$kube_vip_interface', control plane='$node_is_control_plane', worker='$node_is_worker', name='$node_name', user='$node_user'"
      # k3s installation
      if [[ $i_node -eq 0 ]]; then # first cluster node
      first_node_address=$node_ip4

      #node_root_password=""
      #vlib.read-password node_root_password "Please enter root password for cluster nodes:"
      #echo
      #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo rm -rfd /var/lib/kuku                                  <<< \"$node_root_password\"\""
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
      ((i_node++))
      if [ $i_node -eq $amount_nodes ]; then break; fi
  done
}
# function vkube-k3s.install-csi-driver() {
#   # $1 - usage
#   # $2 - install function
#   # $3 - delete function
#   # $4 - upgrade function

#   # if use
#   #   if is not running
#   #     install
#   #   else
#   #     if is not ready
#   #       delete
#   #       install
#   #     else 
#   #       if need upgrade
#   #         https://stackoverflow.com/questions/59967925/kubernetes-csi-driver-upgrade
#   #         delete ???
#   #         install
#   if [ $1 -eq 1 ]; then
#     eval $2
#   then
#   fi
# }
# function vkube-k3s.install-synology-csi() {
#   if [ $csi_synology_use -eq 1 ]; then
#     # https://www.youtube.com/watch?v=c6Qf9UeHld0
#     # https://github.com/Tech-Byte-Tips/Reference-Guides/tree/main/Installing%20the%20Synology%20CSI%20Driver%20with%20the%20Snapshot%20feature%20in%20k3s
#     # https://github.com/christian-schlichtherle/synology-csi-chart
#     # https://github.com/ryaneorth/k8s-scheduled-volume-snapshotter
#     # https://github.com/SynologyOpenSource/synology-csi
#     # https://www.talos.dev/v1.10/kubernetes-guides/configuration/synology-csi/

#     # https://github.com/democratic-csi/democratic-csi
#     # https://github.com/kubernetes-csi/csi-driver-iscsi

#     inf "synology-csi (Line:$LINENO)\n"
#     vlib.check-github-release-version 'synology-csi' https://api.github.com/repos/SynologyOpenSource/synology-csi/releases 'csi_synology_ver'
#     # echo $csi_synology_ver
#     if [[ $(kubectl get pods -l app=controller,app.kubernetes.io/name=synology-csi -n kube-system | wc -l) -eq 0 ]]; then # not installed yet
#       eval "csi_synology_secret_folder=$csi_synology_secret_folder"
#       vlib.check-data-for-secrets "$csi_synology_secret_folder"
#       run "line '$LINENO';helm repo add synology-csi-chart https://christian-schlichtherle.github.io/synology-csi-chart"
#       #run "line '$LINENO';helm install csi-synology synology-csi-chart/synology-csi --namespace kube-system --version $csi_synology_ver"
#       run "line '$LINENO';helm install csi-synology synology-csi-chart/synology-csi --namespace kube-system"
#       # kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/name=csi-driver-smb" --watch
#       # helm delete csi-synology --namespace kube-system
#       kubectl wait --for=create pod/busybox1 --timeout=60s
#     else # already installed
#       __get_json=$(kubectl get pods --all-namespaces -o json -l app=controller,app.kubernetes.io/name=synology-csi)
#       echo $__get_json | jq '[.[]|startwith("synology-csi")]'
#       if ! test vkube-k3s.is-app-ready "app=controller,app.kubernetes.io/name=synology-csi"; then
#       else
#       fi
#   #     if is not ready
#   #       delete
#   #       install
#   #     else 
#   #       if need upgrade
#   #         https://stackoverflow.com/questions/59967925/kubernetes-csi-driver-upgrade
#   #         delete ???
#   #         install



#       inf "... already installed. (Line:$LINENO)\n"
#     fi
# else
#     inf "Uninstalling synology-csi driver (Line:$LINENO)\n"
#   fi
#   (
#     function install() {
#     }
#     function delete() {
#     }
#   )
# }

function vkube-k3s.busybox-install() {
  declare _storage_classes=()
  if [[ -n ${args[--storage-class]} ]]; then
    vlib.trace "--storage-class=${args[--storage-class]}"
    eval "_storage_classes=(${args[--storage-class]:-})"
  elif [[ -n ${args[--synology-csi-plan]} ]]; then
    for csi_synology_host in "${csi_synology_hosts[@]}"; do
      err_and_exit "Not implemented" ${LINENO}
    done
  elif [[ -n ${args[--cluster-plan]} ]]; then
    err_and_exit "Not implemented" ${LINENO}
  fi


  for __s in "${_storage_classes[@]}"; do
  #local yaml
  #yaml=$(kubectl get storageclass $__storage_type -o yaml | yq '.metadata.labels[] | select(.name == "vkube/storage-type")')
  #yaml=$(kubectl get storageclass $__storage_type -o yaml)
  #vlib.trace "yaml=$yaml"

    vlib.trace "__s=$__s"
    # check storage class exists
    local __storage_type
    __storage_type="$(vkube-k3s.get-storage-class-type $__s)"
    vlib.trace "__storage_type=$__storage_type"

    # get storage class label vkube/storage-type
    #err_and_exit "Not implemented" ${LINENO}

    case $__storage_type in
      iscsi )
        err_and_exit "Not implemented" ${LINENO}
      ;;
      smb )
        err_and_exit "Not implemented" ${LINENO}
      ;;
      nfs )
        err_and_exit "Not implemented" ${LINENO}
      ;;
      synology-csi-iscsi )
        err_and_exit "Not implemented" ${LINENO}
      ;;
      synology-csi-smb )
        err_and_exit "Not implemented" ${LINENO}
      ;;
      synology-csi-nfs )
        err_and_exit "Not implemented" ${LINENO}
      ;;
      * )
        if [[ -z $__storage_type ]]; then
          err_and_exit "Storage class '$__s with label 'vkube/storage-type' is not found in kubernetes cluster" ${LINENO};
        else
          err_and_exit "Storage class '$__s with label 'vkube/storage-type: $$__storage_type' is not supported" ${LINENO};
        fi
    esac
  done

  txt="apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: busybox-pvc-nfs-csi
spec:
  storageClassName: nfs-csi
  accessModes: 
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
"
txt="apiVersion: v1
kind: PersistentVolume
metadata:
    name: pv-smb-example-name
    namespace: smb-example-namespace # PersistentVolume and PersistentVolumeClaim must use the same namespace parameter
spec:
    capacity:
        storage: 100Gi
    accessModes:
        - ReadWriteMany
    persistentVolumeReclaimPolicy: Retain
    mountOptions:
        - dir_mode=0777
        - file_mode=0777
        - vers=3.0
    csi:
        driver: smb.csi.k8s.io
        readOnly: false
        volumeHandle: examplehandle  # make sure it's a unique id in the cluster
        volumeAttributes:
            source: \"//gateway-dns-name-or-ip-address/example-share-name\"
        nodeStageSecretRef:
            name: example-smbcreds
            namespace: smb-example-namespace
"
txt="apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: busybox-pvc-nfs-ext
spec:
  storageClassName: nfs-client
  accessModes: 
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
"
txt="kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: busybox-pvc-smb-csi
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 100Mi
  storageClassName: smb-csi
"
txt="apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 500Mi 
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: local-storage
  hostPath:
    path: /mnt/pv-data
"
txt="
"

  txt="apiVersion: apps/v1
kind: Deployment
metadata:
  name: busybox
  labels:
    app: busybox
spec:
  replicas: 1
  selector:
    matchLabels:
      app: busybox  
  template:
    metadata:
      labels:
        app: busybox
    spec:
      #securityContext: user for commands???
      #  runAsUser: 1030  # Use UID of nsf_user on Synology
      #  runAsGroup: 100  # Use GID user group on Synology
      initContainers:
      # https://kubernetes.io/docs/concepts/workloads/pods/init-containers/#differences-from-regular-containers
      - name: init
        image: busybox:musl
        # https://www.busybox.net/downloads/BusyBox.html
        # https://boxmatrix.info/wiki/BusyBox-Commands
        command: [ \"sh\", \"-c\" ]
        args:
        - |
          #create archive directory
          mkdir -p /home/mfs-csi && chown -R 999:999 /home/nfs-csi
          mkdir -p /home/mfs-ext && chown -R 999:999 /home/nfs-ext
          mkdir -p /home/smb-csi && chown -R 999:999 /home/smb-csi
      containers:
        - name: busybox
          image: busybox:musl
          imagePullPolicy: \"IfNotPresent\"
          #command: [ \"sh\", \"-c\" ]
          #args: [\"while true; do sleep 30; done;\"]
          #args:
          #- |
            #create directory for NFS volume
            #mkdir -p /home/nfs && chown -R 999:999 /home/nfs
          command:
            - \"sh\"
            - \"-c\"
            - \"while true; do sleep 6000; done\"
          resources:
            limits:
              memory: \"128Mi\"
              cpu: \"100m\"
          volumeMounts:
          #  - name: nvme-vol
          #    mountPath: /home/nvme # The mountpoint inside the container
          - name: nfs-csi-vol
            mountPath: /home/nfs-csi # The mountpoint inside the container
          - name: nfs-ext-vol
            mountPath: /home/nfs-ext # The mountpoint inside the container
          - name: smb-csi-vol
            mountPath: /home/smb-csi # The mountpoint inside the container
      volumes:
      # - name: nvme-vol
      #   persistentVolumeClaim:
      #     claimName: longhorn-nvme
      - name: nfs-csi-vol
        persistentVolumeClaim:
          claimName: busybox-pvc-nfs-csi
      - name: nfs-ext-vol
        persistentVolumeClaim:
          claimName: busybox-pvc-nfs-ext
      - name: smb-csi-vol
        persistentVolumeClaim:
          claimName: busybox-pvc-smb-csi
"

  # ${args[--storage-class]}

  # if ! [[ -e ${k3s_settings} ]]; then
  #   err_and_exit "Cluster plan file '${k3s_settings}' is not found" ${LINENO};
  # fi
  # #echo $node_root_password
  # if [[ -z $node_root_password ]]; then
  #   node_root_password=""
  #   vlib.read-password node_root_password "Please enter root password for cluster nodes:"
  #   echo
  # fi

  hl.blue "$parent_step$((++install_step)). Busybox installation. (Line:$LINENO)"
  if command kubectl get deploy busybox -n busybox-system &> /dev/null; then
    err_and_exit "Busybox already installed."  ${LINENO} "$0"
  fi
  exit 1
}
function vkube-k3s.busybox-uninstall() {
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

function vkube-k3s.csi-synology-install() {
  # https://www.youtube.com/watch?v=c6Qf9UeHld0
  # https://github.com/Tech-Byte-Tips/Reference-Guides/tree/main/Installing%20the%20Synology%20CSI%20Driver%20with%20the%20Snapshot%20feature%20in%20k3s
  # https://github.com/christian-schlichtherle/synology-csi-chart
  # https://github.com/ryaneorth/k8s-scheduled-volume-snapshotter
  # https://github.com/SynologyOpenSource/synology-csi
  # https://www.talos.dev/v1.10/kubernetes-guides/configuration/synology-csi/

  # https://github.com/democratic-csi/democratic-csi
  # https://github.com/kubernetes-csi/csi-driver-iscsi

  # https://stackoverflow.com/questions/2914220/bash-templating-how-to-build-configuration-files-from-templates-with-bash
  # https://blog.tratif.com/2023/01/27/bash-tips-3-templating-in-bash-scripts/
  #set -x
  if [[ $(yq v ${args[plan]} > /dev/null) ]]; then
    err_and_exit "Error: Not valid YAML file: '${args[plan]}'." ${LINENO}
  fi
  if [[ $(yq --exit-status 'tag == "!!map" or tag== "!!seq"' ${args[plan]} > /dev/null) ]]; then
    err_and_exit "Error: Invalid format for YAML file: '${args[plan]}'." ${LINENO}
  fi
  # if [[ $(yamllint ${args[plan]} > /dev/null) ]]; then
  #   err_and_exit "Error: Not valid csi synology plan file: '${args[plan]}'." ${LINENO}
  # fi

  local data_folder=$(dirname ${args[plan]})
  vlib.trace "data folder=$data_folder"

  # Defaults
  csi_synology_namespace="synology-csi"
  # Root level scalar settings
  eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_" + key + "='\''" + . + "'\''")'  < ${args[plan]})"

  if ! kubectl get namespace $csi_synology_namespace > /dev/null ; then 
    run "line '$LINENO';kubectl create namespace $csi_synology_namespace"
  fi

  readarray csi_synology_hosts < <(yq -o=j -I=0 ".hosts[]" ${args[plan]})
  vlib.trace "storage hosts count=${#csi_synology_hosts[@]}"
  local txt=""
  local separator=""
  i_host=-1

  #vlib.trace "default reclaimPolicy=$csi_synology_host_protocol_class_reclaimPolicy"
  declare -A host_names=()
  for csi_synology_host in "${csi_synology_hosts[@]}"; do
    i_host+=1
    vlib.trace "storage host=$csi_synology_host"
    # Host level scalar settings
    eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host)"
    vlib.trace "storage host name=$csi_synology_host_name"
    if [[ -z $csi_synology_host_name ]]; then
      err_and_exit "Empty host name. Configuration YAML file: '${args[plan]}'." ${LINENO}
    fi
    if [[ -v host_names["${csi_synology_host_name}"] ]]; then
      vlib.trace "host names(${#host_names[@]})=" "${!host_names[@]}"
      err_and_exit "Host name is not unique. Configuration YAML file: '${args[plan]}'. Host name '$csi_synology_host_name'." ${LINENO}
    fi
    host_names["${csi_synology_host_name}"]='y'
    readarray csi_synology_host_protocols < <(echo $csi_synology_host | yq -o=j -I=0 ".protocols[]")
    vlib.trace "storage protocols count=${#csi_synology_host_protocols[@]}"
    if [[ ${#csi_synology_host_protocols[@]} -eq 0 ]]; then
      err_and_exit "There are no storage protocol for host. Configuration YAML file: '${args[plan]}'. Host '$csi_synology_host_name'." ${LINENO}
    fi
    i_protocol=-1
    #vlib.trace "reclaimPolicy=$csi_synology_host_protocol_class_reclaimPolicy"
    declare -A protocol_names=()
    for csi_synology_host_protocol in "${csi_synology_host_protocols[@]}"; do
      i_protocol+=1
      vlib.trace "storage protocol=$csi_synology_host_protocol"
      eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host)"
      eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_protocol_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host_protocol)"
      vlib.trace "storage protocol name=$csi_synology_host_protocol_name"
      if [[ -v protocol_names["${csi_synology_host_protocol_name}"] ]]; then
        #echo "${!protocol_names[@]}" "${protocol_names[@]}"
        vlib.trace "protocol names(${#protocol_names[@]})=" "${!protocol_names[@]}"
        #vlib.trace "storage host=$csi_synology_host"
        #vlib.trace "storage protocol=$csi_synology_host_protocol"
        err_and_exit "Storage protocol name is not unique. Configuration YAML file: '${args[plan]}'. Host name '$csi_synology_host_name'. Protocol name '$csi_synology_host_protocol_name'." ${LINENO}
      fi
      protocol_names["${csi_synology_host_protocol_name}"]='y'
      #readarray csi_synology_host_protocol_classes < <(yq -o=j -I=0 ".hosts[$i_host].protocols[$i_protocol].classes[]" ${args[plan]})
      readarray csi_synology_host_protocol_classes < <(echo $csi_synology_host_protocol | yq -o=j -I=0 ".classes[]")
      vlib.trace "storage classes count=${#csi_synology_host_protocol_classes[@]}"
      if [[ ${#csi_synology_host_protocol_classes[@]} -eq 0 ]]; then
        err_and_exit "There are no storage class for protocol. Configuration YAML file: '${args[plan]}'. Host '$csi_synology_host_name'. Protocol '$csi_synology_host_protocol_name'." ${LINENO}
      fi
      #vlib.trace "reclaimPolicy=$csi_synology_host_protocol_class_reclaimPolicy"
      for csi_synology_host_protocol_class in "${csi_synology_host_protocol_classes[@]}"; do
        vlib.trace "storage class=$csi_synology_host_protocol_class"
        eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host)"
        eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_protocol_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host_protocol)"
        eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_protocol_class_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host_protocol_class)"
        vlib.trace "storage class name=$csi_synology_host_protocol_class_name"
        #vlib.trace "reclaimPolicy=$csi_synology_host_protocol_class_reclaimPolicy"
        case $csi_synology_host_protocol_name in
          ISCSI )
            txt+="${separator}apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  annotations:
    storageclass.kubernetes.io/is-default-class: \"false\"
  name: $csi_synology_host_name-synology-csi-iscsi-$csi_synology_host_protocol_class_name
  labels:
    vkube/storage-type: synology-csi-iscsi
provisioner: csi.san.synology.com
parameters:
  fsType: '$csi_synology_host_protocol_class_fsType'
  dsm: '$csi_synology_host_dsm_ip4'
  location: '$csi_synology_host_protocol_class_location'
  formatOptions: '--nodiscard'
reclaimPolicy: $csi_synology_host_protocol_class_reclaimPolicy
allowVolumeExpansion: $csi_synology_host_protocol_class_allowVolumeExpansion
"
          ;;
          SMB )
            run "line '$LINENO';kubectl create secret generic $csi_synology_host_name-synology-csi-smb-credentials -n $csi_synology_namespace --from-file=$csi_synology_host_protocol_secret_folder"
            txt+="${separator}apiVersion: v1
kind: Secret
metadata:
  name: $csi_synology_host_name-synology-csi-smb-credentials
  namespace: $csi_synology_namespace
type: Opaque
stringData:
  username: <username>  # DSM user account accessing the shared folder
  password: <password>  # DSM user password accessing the shared folder
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: $csi_synology_host_name-synology-csi-smb-$csi_synology_host_protocol_class_name
  labels:
    vkube/storage-type: synology-csi-smb
provisioner: csi.san.synology.com
parameters:
  protocol: \"smb\"
  dsm: '$csi_synology_host_dsm_ip4'
  location: '$csi_synology_host_protocol_class_location'
  csi.storage.k8s.io/node-stage-secret-name: \"synology-$csi_synology_host_name-csi-smb-credentials\"
  csi.storage.k8s.io/node-stage-secret-namespace: \"default\"
reclaimPolicy: $csi_synology_host_protocol_class_reclaimPolicy
allowVolumeExpansion: $csi_synology_host_protocol_class_allowVolumeExpansion
"
          ;;
          NFS )
            txt+="${separator}apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: $csi_synology_host_name-synology-csi-nfs-$csi_synology_host_protocol_class_name
  labels:
    vkube/storage-type: synology-csi-nfs
provisioner: csi.san.synology.com
parameters:
  protocol: \"nfs\"
  dsm: '$csi_synology_host_dsm_ip4'
  location: '$csi_synology_host_protocol_class_location'
  mountPermissions: \"$csi_synology_host_protocol_class_mountPermissions\"
mountOptions:
  - nfsvers='$csi_synology_host_protocol_class_mountOptions_nfsvers'
reclaimPolicy: $csi_synology_host_protocol_class_reclaimPolicy
allowVolumeExpansion: $csi_synology_host_protocol_class_allowVolumeExpansion
"
          ;;
          * )
            err_and_exit "Unsupported storage protocol '$name'. Expected: ISCSI, SMB, NFS" ${LINENO};
        esac
        separator="---
"
      done
    done
  done
  #set +x
  vlib.trace "generated storage classes=\n$txt"
  run "line '$LINENO';echo '$txt' > '$data_folder/generated-storage-classes.yaml'"
  #run "line '$LINENO';kubectl apply edit-last-applied -f '$data_folder/generated-storage-classes.yaml'"
  run "line '$LINENO';kubectl apply -f '$data_folder/generated-storage-classes.yaml'"

  local deploy_k8s_version="v1.20"
  inf "synology-csi (Line:$LINENO)\n"
  #vlib.check-github-release-version 'synology-csi' https://api.github.com/repos/SynologyOpenSource/synology-csi/releases 'csi_synology_ver'
  # echo $csi_synology_ver
  if [[ $(kubectl get pods -l app=controller,app.kubernetes.io/name=synology-csi -n synology-csi | wc -l) -eq 0 ]]; then # not installed yet
    eval "csi_synology_host_folder_with_dsm_secrets=$csi_synology_host_folder_with_dsm_secrets"

    # /etc/synology/client-info.yml

    #run "line '$LINENO';if ! ($(kubectl get namespace synology-csi > /dev/null )); then kubectl create namespace synology-csi; fi"
    if kubectl get secret -n $csi_synology_namespace client-info-secret > /dev/null ; then
      run "line '$LINENO';kubectl delete secret -n $csi_synology_namespace client-info-secret"
    fi
    run "line '$LINENO';kubectl create secret -n $csi_synology_namespace generic client-info-secret --from-file="$csi_synology_host_folder_with_dsm_secrets/client-info.yml""
    run "line '$LINENO';kubectl apply -f $vkube_data_folder/synology-csi/kubernetes/$deploy_k8s_version"

    if [ $csi_synology_snapshot_use -eq 1 ]; then
      inf "Snapshort CRD and controller (Line:$LINENO)\n"
      run "line '$LINENO';kubectl apply -f '$vkube_data_folder/synology-csi/synology CRDs'"
      run "line '$LINENO';kubectl apply -f '$vkube_data_folder/synology-csi/kubernetes/$deploy_k8s_version/snapshotter/snapshotter.yaml'"
      run "line '$LINENO';kubectl apply -f '$vkube_data_folder/synology-csi/kubernetes/$deploy_k8s_version/snapshotter/volume-snapshot-class.yml'"
    fi

    # kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/name=csi-driver-smb" --watch
    # helm delete csi-synology --namespace kube-system
    #kubectl wait --for=create pod/busybox1 --timeout=60s
  else # already installed
    __get_json=$(kubectl get pods --all-namespaces -o json -l app=controller,app.kubernetes.io/name=synology-csi)
    echo $__get_json | jq '[.[]|startwith("synology-csi")]'
    #if ! test vkube-k3s.is-app-ready "app=controller,app.kubernetes.io/name=synology-csi"; then
    #else
    #fi
#     if is not ready
#       delete
#       install
#     else 
#       if need upgrade
#         https://stackoverflow.com/questions/59967925/kubernetes-csi-driver-upgrade
#         delete ???
#         install
    inf "... already installed. (Line:$LINENO)\n"
  fi
}
function vkube-k3s.csi-synology-uninstall() {
  local deploy_k8s_version="v1.20"
  inf "Uninstall synology-csi (Line:$LINENO)\n"
  run "line '$LINENO';kubectl delete -f '$vkube_data_folder/synology-csi/kubernetes/$deploy_k8s_version' --ignore-not-found"
  if [ $csi_synology_snapshot_use -eq 1 ]; then
    run "line '$LINENO';kubectl delete -f '$vkube_data_folder/synology-csi/kubernetes/$deploy_k8s_version/snapshotter/volume-snapshot-class.yml' --ignore-not-found"
    run "line '$LINENO';kubectl delete -f '$vkube_data_folder/synology-csi/kubernetes/$deploy_k8s_version/snapshotter/snapshotter.yaml' --ignore-not-found"
    run "line '$LINENO';kubectl delete -f '$vkube_data_folder/synology-csi/synology CRDs' --ignore-not-found"
  fi
}
function vkube-k3s.install() {
  start_time=$(date +%s)
  install_step=0

  vkube-k3s.cluster_plan_read

  h2 "Install K3s cluster with $amount_nodes nodes. Cluster plan from '$k3s_settings' file. (Line:$LINENO)"

  # export KUBECONFIG=/mnt/d/dev/homelab/k3s/kubeconfig
  # kubectl config use-context local
  # kubectl get node -o wide

  # /usr/local/bin/k3s-uninstall.sh
  # /usr/local/bin/k3s-agent-uninstall.sh

  vkube-k3s.install_tools

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

  # Nodes
  #readarray nodes < <(yq '.nodes[] |= sort_by(.node_id)' < $k3s_settings)
  readarray nodes < <(yq -o=j -I=0 '.node[]' < $k3s_settings)

  if test -e "${HOME}/.kube/${cluster_name}"; then 
    # https://www.geeksforgeeks.org/bash-script-read-user-input/
    while true; do
      read -p "Cluster config '${cluster_name}' already exist. Uninstall and proceed new installation? [y/n]" yesno
      case $yesno in
        [Yy]* ) 
          _install_all
          break
        ;;
        [Nn]* )
          break
        ;;
        * ) echo "Answer either yes or no!";;
      esac
    done
  else
    _install_all
  fi

  # p_skip=0
  # if test -e "${HOME}/.kube/${cluster_name}"; then 
  #   run.ui.ask "Cluster config '${cluster_name}' already exist. Uninstall and proceed new installation?" || p_skip=1
  #   #if [ $((opt_install_new || opt_install_remove || opt_install_upgrade)) -eq 1 ]; then
  #   #run.ui.press-any-key "Config for cluster '${cluster_name}' already exists. Override? (^C for cancel)"
  # fi
  # if [[ $p_skip -eq 0 ]]; then
  # fi

  export KUBECONFIG=~/.kube/$cluster_name
  run "line '$LINENO';wait_kubectl_can_connect_cluster"

  inf "New kubernetes cluster '$cluster_name' is installed on servers described in cluster plan YAML file '$k3s_settings'\n"
  inf "To use kubectl: Run 'export KUBECONFIG=~/.kube/$cluster_name' or 'ek $cluster_name'\n"

  kubectl get nodes

  hl.blue "$((++install_step)). Install the storage drivers and classes. (Line:$LINENO)"
  # if use
  #   if is not running
  #     install
  #   else
  #     if is not ready
  #       delete
  #       install
  #     else 
  #       if need upgrade
  #         https://stackoverflow.com/questions/59967925/kubernetes-csi-driver-upgrade
  #         delete ???
  #         install

  # https://kubernetes.io/docs/tasks/access-application-cluster/list-all-running-container-images/
  # https://kubernetes.io/docs/reference/kubectl/quick-reference/
  # https://kubernetes.io/docs/reference/kubectl/jsonpath/
  # kubectl get deployment csi-smb-controller -o=jsonpath='{$.spec.template.spec.containers[:1].image}' -n kube-system
  # kubectl get pods --all-namespaces -o jsonpath="{..image}"
  # kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" -l app=controller,app.kubernetes.io/name=synology-csi
  # kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*] | select(.metadata.name | test("")).image}" -l app=controller,app.kubernetes.io/name=synology-csi
  # kubectl get pod csi-smb-controller -o=jsonpath='{$.spec.template.spec.containers[:1].image}' -n kube-system

  # kubectl get pods --all-namespaces -l app=controller,app.kubernetes.io/name=synology-csi -o yaml | grep image:

  if [ $csi_synology_use -eq 1 ]; then
    vkube-k3s.csi-synology-install
  fi

  if [ $csi_driver_smb_use -eq 1 ]; then
    inf "csi-driver-smb (Line:$LINENO)\n"
    # https://github.com/kubernetes-csi/csi-driver-smb/blob/master/deploy/example/e2e_usage.md
    # https://rguske.github.io/post/using-windows-smb-shares-in-kubernetes/
    # https://docs.aws.amazon.com/filegateway/latest/files3/use-smb-csi.html
    vlib.check-github-release-version 'csi_driver_smb' https://api.github.com/repos/kubernetes-csi/csi-driver-smb/releases 'csi_driver_smb_ver'
    #echo $csi_driver_smb_ver
    if [[ $(kubectl get pods -lapp=csi-smb-controller,app.kubernetes.io/version=${csi_driver_smb_ver:1} -n kube-system | wc -l) -eq 0 ]]; then
      eval "csi_driver_smb_secret_folder=$csi_driver_smb_secret_folder"
      vlib.check-data-for-secrets "$csi_driver_smb_secret_folder"
      run "line '$LINENO';helm repo add csi-driver-smb https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts"
      run "line '$LINENO';helm install csi-driver-smb csi-driver-smb/csi-driver-smb --namespace kube-system --version $csi_driver_smb_ver"
      # kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/name=csi-driver-smb" --watch
      # https://kubernetes.io/docs/concepts/configuration/secret/
      # https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
      # https://medium.com/@ravipatel.it/mastering-kubernetes-secrets-a-comprehensive-guide-b0304818e32b
      run "line '$LINENO';if ! test -e $csi_driver_smb_secret_folder; then  mkdir $csi_driver_smb_secret_folder; fi"
      run "line '$LINENO';kubectl create secret generic smb-csi-creds -n kube-system --from-file=$csi_driver_smb_secret_folder"
    else
      inf "... already installed. (Line:$LINENO)\n"
    fi
    # kubectl -n kube-system get secret smb-csi-creds -o jsonpath='{.data}'
    # kubectl -n kube-system get secret smb-csi-creds -o jsonpath='{.data.username}' | base64 --decode
    # kubectl -n kube-system get secret smb-csi-creds -o jsonpath='{.data.password}' | base64 --decode
    # kubectl -n kube-system edit secrets smb-csi-creds
    # kubectl delete secret smb-csi-creds -n kube-system
  fi
  if [ $csi_driver_nfs_use -eq 1 ]; then
    inf "csi-driver-nfs (Line:$LINENO)\n"
    vlib.check-github-release-version 'csi_driver_nfs' https://api.github.com/repos/kubernetes-csi/csi-driver-nfs/releases 'csi_driver_nfs_ver'
    #echo ${csi_driver_nfs_ver:1}
    if [[ $(kubectl get pods -lapp=csi-nfs-controller,app.kubernetes.io/version=${csi_driver_nfs_ver:1} -n kube-system | wc -l) -eq 0 ]]; then
      eval "csi_driver_nfs_secret_folder=$csi_driver_nfs_secret_folder"
      vlib.check-data-for-secrets "$csi_driver_nfs_secret_folder"
      run "line '$LINENO';helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
      run "line '$LINENO';helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version $csi_driver_nfs_ver"
      # kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/name=csi-driver-nfs" --watch
    else
      inf "... already installed. (Line:$LINENO)\n"
    fi
  fi
  if [ $nfs_subdir_external_provisioner_use -eq 1 ]; then
    inf "nfs-subdir-external-provisioner (Line:$LINENO)\n"
    vlib.check-github-release-version 'nfs_subdir_external_provisioner' https://api.github.com/repos/kubernetes-sigs/nfs-subdir-external-provisioner/releases 'nfs_subdir_external_provisioner_ver'
    #echo $nfs_subdir_external_provisioner_ver
    #if [[ $(kubectl get pods -lapp=csi-smb-controller,app.kubernetes.io/version=$nfs_subdir_external_provisioner_ver -n kube-system | wc -l) -eq 0 ]]; then
    if [[ $(kubectl get pods -lapp=nfs-subdir-external-provisioner -n kube-system | wc -l) -eq 0 ]]; then
      run "line '$LINENO';helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/"
      # helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --namespace kube-system --set image.tag=4.0.18 --set nfs.server=192.168.100.227 --set nfs.path=/volume1/k8s-nfs-ext
      run "line '$LINENO';helm install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner --namespace kube-system \
      --set nfs.server=$nfs_subdir_external_provisioner_server \
      --set nfs.path=$nfs_subdir_external_provisioner_server_path"
      #  --set image.tag=$nfs_subdir_external_provisioner_ver \
      # kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/name=nfs-subdir-external-provisioner" --watch
    else
      inf "... already installed. (Line:$LINENO)\n"
    fi
  fi
  run "line '$LINENO';kubectl apply -f $VBASH/../k3s/storage-classes.yaml"

  # https://kube-vip.io/docs/usage/cloud-provider/
  # https://kube-vip.io/docs/usage/cloud-provider/#install-the-kube-vip-cloud-provider
  if [ $kube_vip_use -eq 1 ]; then
    hl.blue "$((++install_step)). Install the kube-vip Cloud Provider. (Line:$LINENO)"
    inf "kube-vip (Line:$LINENO)\n"
    vlib.check-github-release-version 'kube-vip' https://api.github.com/repos/kube-vip/kube-vip/releases 'kube_vip_ver'
    #echo ${kube_vip_ver}
    if [[ $(kubectl get pods -lapp.kubernetes.io/name=kube-vip-ds,app.kubernetes.io/version=${kube_vip_ver} -n kube-system | wc -l) -eq 0 ]]; then
      run "line '$LINENO';helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
      run "line '$LINENO';helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version $csi_driver_nfs_ver"
      # kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/name=csi-driver-nfs" --watch
      run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml"
      #run kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/$kube_vip_cloud_provider_ver/deploy/kube-vip-cloud-controller.yaml
      run "line '$LINENO';kubectl create configmap -n kube-system kubevip --from-literal range-global=$kube_vip_lb_range"
    else
      inf "... already installed. (Line:$LINENO)\n"
    fi
  fi

  # Longhorn
  # https://longhorn.io/docs/1.7.2/deploy/install/install-with-kubectl/
  hl.blue "$((++install_step)). Install Longhorn. (Line:$LINENO)"
  ./101-longhorn/install.sh -s "${k3s_settings}" -w "${node_root_password}" -t "${install_step}" -i $longhorn_ver

  # https://wiki.musl-libc.org/building-busybox
  # https://github.com/docker-library/repo-info/blob/master/repos/busybox/remote/musl.md
  ./102-busybox/install.sh -s "${k3s_settings}" -w "${node_root_password}" -t "${install_step}" -i $busybox_ver

  # Velero backup/restore
  hl.blue "$((++install_step)). Install Velero backup/restore. (Line:$LINENO)"
  #./velero/install.sh -s "${k3s_settings}" -w "${node_root_password}" -t "${install_step}" -i $longhorn_ver
  ./velero/install.sh -t "${install_step}" -i $velero_ver

  exit

  # Rancher
  hl.blue "$((++install_step)). Install Rancher. (Line:$LINENO)"
  ./105-rancher/install.sh -i $rancher_ver

  # pi-hole
  if [[ $pi_hole_use -eq 1 ]]; then
  hl.blue "$((++install_step)). Install Pi-hole. (Line:$LINENO)"
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
  hl.blue "$((++install_step)). Install Argo CD. (Line:$LINENO)"
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
  hl.blue "$((++install_step)). Install Rancher. (Line:$LINENO)"
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

  hl.blue "$((++install_step)). Install Metallb. (Line:$LINENO)"
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

  # exit

  # run ssh -t $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo curl -fL https://get.k3s.io | INSTALL_K3S_VERSION=${k3s_ver} sh -s - ${install_k3s_cmd_parm}'





  # exit

  # #read -p "Local K3s installation (y/n): " k3s_local_install
  # #if [[ "$k3s_local_install" =~ [^yn] ]]; then
  # #  echo "Error: Invalid input."
  # #  exit 1
  # #fi

  # #############################################
  # #            DO NOT EDIT BELOW              #
  # #############################################

  # exit


  # # Create SSH Config file to ignore checking (don't use in production!)
  # sed -i '1s/^/StrictHostKeyChecking no\n/' ~/.ssh/config

  # #add ssh keys for all nodes
  # for node in "${all[@]}"; do
  # ssh-copy-id $user@$node
  # done

  # # Install policycoreutils for each node
  # for newnode in "${all[@]}"; do
  # ssh $user@$newnode -i ~/.ssh/$certName sudo su <<EOF
  # NEEDRESTART_MODE=a apt install policycoreutils -y
  # exit
  # EOF
  # echo -e " \033[32;5mPolicyCoreUtils installed!\033[0m"
  # done

  # # Step 1: Bootstrap First k3s Node
  # mkdir ~/.kube
  # k3sup install \
  # --ip $master1 \
  # --user $user \
  # --tls-san $vip \
  # --cluster \
  # --k3s-version $k3sVersion \
  # --k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=$master1 --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
  # --merge \
  # --sudo \
  # --local-path $HOME/.kube/config \
  # --ssh-key $HOME/.ssh/$certName \
  # --context k3s-ha
  # echo -e " \033[32;5mFirst Node bootstrapped successfully!\033[0m"

  # # Step 2: Install Kube-VIP for HA
  # kubectl apply -f https://kube-vip.io/manifests/rbac.yaml

  # # Step 3: Download kube-vip
  # curl -sO https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/kube-vip
  # cat kube-vip | sed 's/$interface/'$interface'/g; s/$vip/'$vip'/g' > $HOME/kube-vip.yaml

  # # Step 4: Copy kube-vip.yaml to master1
  # scp -i ~/.ssh/$certName $HOME/kube-vip.yaml $user@$master1:~/kube-vip.yaml


  # # Step 5: Connect to Master1 and move kube-vip.yaml
  # ssh $user@$master1 -i ~/.ssh/$certName <<- EOF
  # sudo mkdir -p /var/lib/rancher/k3s/server/manifests
  # sudo mv kube-vip.yaml /var/lib/rancher/k3s/server/manifests/kube-vip.yaml
  # EOF

  # # Step 6: Add new master nodes (servers) & workers
  # for newnode in "${masters[@]}"; do
  # k3sup join \
  #     --ip $newnode \
  #     --user $user \
  #     --sudo \
  #     --k3s-version $k3sVersion \
  #     --server \
  #     --server-ip $master1 \
  #     --ssh-key $HOME/.ssh/$certName \
  #     --k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=$newnode --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
  #     --server-user $user
  # echo -e " \033[32;5mMaster node joined successfully!\033[0m"
  # done

  # # add workers
  # for newagent in "${workers[@]}"; do
  # k3sup join \
  #     --ip $newagent \
  #     --user $user \
  #     --sudo \
  #     --k3s-version $k3sVersion \
  #     --server-ip $master1 \
  #     --ssh-key $HOME/.ssh/$certName \
  #     --k3s-extra-args "--node-label \"longhorn=true\" --node-label \"worker=true\""
  # echo -e " \033[32;5mAgent node joined successfully!\033[0m"
  # done

  # # Step 7: Install kube-vip as network LoadBalancer - Install the kube-vip Cloud Provider
  # kubectl apply -f https://raw.githubusercontent.com/kube-vip/kube-vip-cloud-provider/main/manifest/kube-vip-cloud-controller.yaml

  # # Step 8: Install Metallb
  # kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
  # kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.13.12/config/manifests/metallb-native.yaml
  # # Download ipAddressPool and configure using lbrange above
  # curl -sO https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/ipAddressPool
  # cat ipAddressPool | sed 's/$lbrange/'$lbrange'/g' > $HOME/ipAddressPool.yaml

  # # Step 9: Test with Nginx
  # kubectl apply -f https://raw.githubusercontent.com/inlets/inlets-operator/master/contrib/nginx-sample-deployment.yaml -n default
  # kubectl expose deployment nginx-1 --port=80 --type=LoadBalancer -n default

  # echo -e " \033[32;5mWaiting for K3S to sync and LoadBalancer to come online\033[0m"

  # while [[ $(kubectl get pods -l app=nginx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
  # sleep 1
  # done

  # # Step 10: Deploy IP Pools and l2Advertisement
  # kubectl wait --namespace metallb-system \
  #                 --for=condition=ready pod \
  #                 --selector=component=controller \
  #                 --timeout=120s
  # kubectl apply -f ipAddressPool.yaml
  # kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/l2Advertisement.yaml

  # kubectl get nodes
  # kubectl get svc
  # kubectl get pods --all-namespaces -o wide

  # echo -e " \033[32;5mHappy Kubing! Access Nginx at EXTERNAL-IP above\033[0m"

  # # Step 11: Install helm
  # curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  # chmod 700 get_helm.sh
  # ./get_helm.sh

  # # Step 12: Add Rancher Helm Repository
  # helm repo add rancher-latest https://releases.rancher.com/server-charts/latest
  # kubectl create namespace cattle-system

  # # Step 13: Install Cert-Manager
  # kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.crds.yaml
  # helm repo add jetstack https://charts.jetstack.io
  # helm repo update
  # helm install cert-manager jetstack/cert-manager \
  # --namespace cert-manager \
  # --create-namespace \
  # --version v1.13.2
  # kubectl get pods --namespace cert-manager

  # # Step 14: Install Rancher
  # helm install rancher rancher-latest/rancher \
  # --namespace cattle-system \
  # --set hostname=rancher.my.org \
  # --set bootstrapPassword=admin
  # kubectl -n cattle-system rollout status deploy/rancher
  # kubectl -n cattle-system get deploy rancher

  # # Step 15: Expose Rancher via Loadbalancer
  # kubectl get svc -n cattle-system
  # kubectl expose deployment rancher --name=rancher-lb --port=443 --type=LoadBalancer -n cattle-system
  # kubectl get svc -n cattle-system

  # # Profit: Go to Rancher GUI
  # echo -e " \033[32;5mHit the url… and create your account\033[0m"
  # echo -e " \033[32;5mBe patient as it downloads and configures a number of pods in the background to support the UI (can be 5-10mins)\033[0m"

  # # Step 16: Install Longhorn (using modified Official to pin to Longhorn Nodes)
  # echo -e " \033[32;5mInstalling Longhorn - It can take a while for all pods to deploy...\033[0m"
  # kubectl apply -f https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/Longhorn/longhorn.yaml
  # kubectl get pods \
  # --namespace longhorn-system \
  # --watch

  # # Step 17: Print out confirmation

  # kubectl get nodes
  # kubectl get svc -n longhorn-system

  # echo -e " \033[32;5mHappy Kubing! Access Longhorn through Rancher UI\033[0m"




}