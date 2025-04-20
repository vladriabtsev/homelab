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
function vkube-k3s.install_tools()
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
remove_kubernetes_first_node()
{
  inf "Uninstalling k3s first node. (Line:$LINENO)\n"
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
install_first_node()
{
  if [ $opt_install_new -eq 1 ]; then
    hl.blue "$((++install_step)). Bootstrap First k3s node $node_name($node_ip4). (Line:$LINENO)"
  else
    hl.blue "$((++install_step)). Remove k3s node $node_name($node_ip4). (Line:$LINENO)"
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
    # https://docs.k3s.io/cli/certificate#certificate-authority-ca-certificates
    # https://github.com/k3s-io/k3s/blob/master/contrib/util/generate-custom-ca-certs.sh
    # https://blog.chkpwd.com/posts/k3s-ha-installation-kube-vip-and-metallb/
    if ! [ $node_is_control_plane -eq 1 ]; then err_and_exit "Error: First node has to be part of Control Plane: '$k3s_settings'." ${LINENO}; fi
    cluster_node_ip=$node_ip4
    if [ $kube_vip_use -eq 1 ]; then
      gen_kube_vip_manifest
    fi
    install_k3s_cmd_parm="server \
--token kuku \
--cluster-init \
--disable traefik \
--disable servicelb \
--write-kubeconfig-mode 644 \
--tls-san $cluster_node_ip"
    inf "Install k3s first node. (Line:$LINENO)\n"
    run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'curl -fL https://get.k3s.io > ~/install.sh;chmod 777 ~/install.sh'"
    run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S INSTALL_K3S_VERSION=${k3s_ver} ~/install.sh ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"
    #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "sudo -S INSTALL_K3S_VERSION=${k3s_ver} ~/install.sh ${install_k3s_cmd_parm} <<< \"$node_root_password\""
    #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S curl -fL https://get.k3s.io <<< \"$node_root_password\" | INSTALL_K3S_VERSION=${k3s_ver} sh -s - ${install_k3s_cmd_parm}'"
    run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S cp /etc/rancher/k3s/k3s.yaml ~/k3s.yaml <<< \"$node_root_password\"'"
    run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S chmod 777 ~/k3s.yaml <<< \"$node_root_password\"'"
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
    run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'rm ~/k3s.yaml'"
    #kubectl wait --for=condition=Ready node/$node_name
    #echo "cluster_token=$cluster_token"
    cluster_token="$(ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name echo \"$node_root_password\" | sudo -S cat /var/lib/rancher/k3s/server/token)"
  fi
  #while [[ $(kubectl get pods -l app=nginx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
  # sleep 1
  #done
}

install_join_node()
{
  if [ $opt_install_new -eq 1 ]; then
    hl.blue "$((++install_step)). Join k3s node $node_name($node_ip4). (Line:$LINENO)"
  else
    hl.blue "$((++install_step)). Remove k3s node $node_name($node_ip4). (Line:$LINENO)"
  fi
  # https://docs.k3s.io/installation/configuration#configuration-file
#--token $cluster_token \
  install_k3s_cmd_parm="server \
--disable traefik \
--disable servicelb \
--token kuku \
--tls-san $cluster_node_ip \
--server https://$cluster_node_ip:6443"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'if sudo -S test -e /usr/local/bin/k3s-uninstall.sh; then /usr/local/bin/k3s-uninstall.sh; fi <<< \"$node_root_password\"'"
  run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'if sudo -S test -e /usr/local/bin/k3s-agent-uninstall.sh; then /usr/local/bin/k3s-agent-uninstall.sh; fi <<< \"$node_root_password\"'"
  if [ $opt_install_new -eq 1 ]; then
    #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'curl -fL https://get.k3s.io > ./install.sh;chmod 777 ./install.sh'"
    #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'INSTALL_K3S_VERSION=${k3s_ver} sudo -S ./install.sh ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"

    #K3S_URL=https://192.168.100.51:6443 K3S_TOKEN=K109836edbf7c2b660b8c7515867f6da9aa59f1c75c7e46066a78e7fb63f78a62ce::server:69a6d7584a18bf32238e6f4c5cb35624 echo qpalwoskQ4.. | sudo -S "./install.sh server --disable traefik --disable servicelb --write-kubeconfig-mode 644 --tls-san 192.168.100.50"

    run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'curl -fL https://get.k3s.io > ~/install.sh;chmod 777 ~/install.sh'"
    #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sudo -S '$HOME/install.sh ${install_k3s_cmd_parm}' <<< \"$node_root_password\""
    #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sudo -S './install.sh ${install_k3s_cmd_parm}' <<< ${node_root_password}"
    #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'curl -fL https://get.k3s.io > ./install.sh;chmod 777 ./install.sh'"
    #ssh vlad@192.168.100.52 -i /home/vlad/.ssh/id_rsa K3S_URL=https://192.168.100.51:6443 K3S_TOKEN=K109836edbf7c2b660b8c7515867f6da9aa59f1c75c7e46066a78e7fb63f78a62ce::server:69a6d7584a18bf32238e6f4c5cb35624 sudo -S '/home/vlad/install.sh server --disable traefik --disable servicelb --tls-san 192.168.100.50' <<< qpalwoskQ4..
    #ssh vlad@192.168.100.52 -i /home/vlad/.ssh/id_rsa INSTALL_K3S_VERSION=v1.32.2+k3s1 K3S_URL=https://192.168.100.51:6443 K3S_TOKEN=K109836edbf7c2b660b8c7515867f6da9aa59f1c75c7e46066a78e7fb63f78a62ce::server:69a6d7584a18bf32238e6f4c5cb35624 sudo -S '/home/vlad/install.sh server --disable traefik --disable servicelb --tls-san 192.168.100.50' <<< qpalwoskQ4..
    #echo ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "INSTALL_K3S_VERSION=${k3s_ver} sudo -S ~/install.sh ${install_k3s_cmd_parm} <<< ${node_root_password}"
    #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "sudo -S ./install.sh ${install_k3s_cmd_parm} <<< \"$node_root_password\""
    #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "INSTALL_K3S_VERSION=${k3s_ver} K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sudo -S '~/install.sh ${install_k3s_cmd_parm}' <<< ${node_root_password}"
    #ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name "INSTALL_K3S_VERSION=${k3s_ver} sudo -S ~/install.sh ${install_k3s_cmd_parm} <<< ${node_root_password}"
    run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S INSTALL_K3S_VERSION=${k3s_ver} ./install.sh ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"

    #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'curl -fL https://get.k3s.io | K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sudo -S sh -s - ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"
    #run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo -S curl -fL https://get.k3s.io | K3S_URL=https://$first_node_address:6443 K3S_TOKEN=$cluster_token sh -s - ${install_k3s_cmd_parm} <<< \"$node_root_password\"'"
    #kubectl get nodes
    # sudo journalctl -xeu k3s.service # check k3s log on node
    # ls /var/lib/ca-certificates/pem
    # ls -l /etc/ssl/certs
  fi
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
