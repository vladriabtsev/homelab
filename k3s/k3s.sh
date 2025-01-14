#!/bin/bash
# ./k3s.sh ./k3s.yaml

#if [[ -f "${BASHMATIC_INIT}" ]]; then source "${BASHMATIC_INIT}"; else source ${BASHMATIC_HOME}/init.sh; fi
debug-on
run.set-all abort-on-error show-command-on show-output-on
#run.set-all ask-on-error on-decline-exit

#bashmatic.validate-subshell || return 1
#source ${BASHMATIC_HOME}/init.sh
#bashmatic.bash.exit-unless-version-four-or-later

# Functions
err_and_exit()
{
  if [ -z "$1" ]; then
    err "Function err_exit is expecting error message as a first parameter"
  fi
  #caller.stack
  #exit
  if [ -z "$2" ]; then
    err "Function err_exit is expecting \$LINENO as a second parameter"
    exit
  fi
  local call_lineno="$2"

  if [ -z "$3" ]; then
    err "$1 LINENO: $2"
  else
    err "$1 FUNCNAME: $3, LINENO: $2"
  fi
  exit
}
install_k3s_tools()
{
    # For testing purposes - in case time is wrong due to VM snapshots
    sudo timedatectl set-ntp off
    sudo timedatectl set-ntp on

    # Copy SSH certs to ~/.ssh and change permissions
    if [[ -z $cert_name ]]; then
      run "cp /home/$user/ssh/{$certName,$certName.pub} /home/$user/.ssh"
      chmod 600 /home/$user/.ssh/$certName 
      chmod 644 /home/$user/.ssh/$certName.pub
    fi

    # Install k3sup to local machine if not already present
    if ! command -v k3sup version &> /dev/null; then
      run "curl -sLS https://get.k3sup.dev | sh"
      sudo install k3sup /usr/local/bin/
    fi

    # Install Kubectl if not already present
    if ! command -v kubectl version &> /dev/null; then
      echo -e " Kubectl not found, installing ..."
      curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
      sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
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
  if [ "$node_id" -eq "1" ]; then
    kvversion_latest=$(curl -sL https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
    #kvversion_latest=$(curl -SL --retry 3 https://api.github.com/repos/kube-vip/kube-vip/releases | jq -r ".[0].name")
    if [ -z $kube_vip_ver ]; then
      $kube_vip_ver=$kvversion_latest
    fi
    if ! [ "$kvversion_latest" == "$kube_vip_ver" ]; then
      inf "Latest version kube-vip: $kvversion_latest, but installing: $kube_vip_ver\n"
    fi
  fi
  if [ -z $kube_vip_interface ]; then
    err_and_exit "Error: Node kube_vip_interface is empty." ${LINENO}
  fi

  run "curl -o ~/tmp/rbac.yaml https://kube-vip.io/manifests/rbac.yaml" || exit 1
  run "echo "---" >> ~/tmp/rbac.yaml" || exit 1
  # https://kube-vip.io/docs/installation/flags/
  if [[ "$kube_vip_mode" == "ARP" ]]; then
    #--services \
    run "docker run --network host --rm ghcr.io/kube-vip/kube-vip:$kube_vip_ver manifest daemonset \
    --interface $kube_vip_interface \
    --address $kube_vip_address \
    --inCluster \
    --taint \
    --controlplane \
    --arp \
    --leaderElection \
    --enableNodeLabeling \
    >> ~/tmp/rbac.yaml" || exit 1
  else # BGP mode
    #--servicesElection
    run "docker run --network host --rm ghcr.io/kube-vip/kube-vip:$kube_vip_ver manifest daemonset \
    --interface $kube_vip_interface \
    --address $kube_vip_address \
    --inCluster \
    --taint \
    --controlplane \
    --bgp \
    --localAS 65000 \
    --bgpRouterID 192.168.0.2 \
    --bgppeers 192.168.0.10:65000::false,192.168.0.11:65000::false
    >> ~/tmp/rbac.yaml"
  fi
  if ! test -s ~/tmp/rbac.yaml; then echo "~/tmp/rbac.yaml file is empty"; fi
  #while [[ $(docker inspect -f {{.State.Running}} ghcr.io/kube-vip/kube-vip:$kube_vip_ver) == "true" ]]; do
  #  sleep 1
  #done
  #if ! test -s ~/tmp/kube-vip-node.yaml; then echo "~/tmp/kube-vip-node.yaml file is empty"; fi
  run "scp -i ~/.ssh/$cert_name ~/tmp/rbac.yaml $node_user@$node_ip4:~/rbac.yaml" || exit 1
  run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo mkdir -p /var/lib/rancher/k3s/server/manifests/'" || exit 1
  run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo mv ~/rbac.yaml /var/lib/rancher/k3s/server/manifests/rbac.yaml'" || exit 1
  #run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo mv ~/kube-vip-node.yaml /var/lib/rancher/k3s/server/manifests/kube-vip-node.yaml'" || exit 1
}
install_first_node()
{
    #if ! test -e ~/downloads; then mkdir ~/downloads; fi
    #if ! test -e "${HOME}/downloads/${k3s_ver}"; then 
    #  mkdir "${HOME}/downloads/${k3s_ver}";
    #  run "curl -L ${url} -o ${temp_binary}"
    #fi
  if ! test -e ~/.kube; then  mkdir ~/.kube;  fi
  if test -e "${HOME}/.kube/${cluster_name}"; then 
    #run.ui.press-any-key "Config for cluster '${cluster_name}' already exists. Override? (^C for cancel)"
    run.ui.ask "Cluster config '${cluster_name}' already exist. Uninstall and proceed new installation?" || exit 1
    run "kubectl --kubeconfig ~/.kube/${cluster_name} delete daemonset kube-vip-ds -n kube-system"
    run "rm ~/.kube/${cluster_name}" || exit 1
    run "ssh -T $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo rm -f /var/lib/rancher/k3s/server/tls/*'" || exit 1
    #run "ssh -T $node_user@$node_ip4 -i ~/.ssh/$cert_name  '/usr/local/bin/k3s-uninstall.sh'" || exit 1
  fi

  hl.blue "Step 0: Prepare node '$node_ip4'. (Line:$LINENO)"
  run "ssh -T $node_user@$node_ip4 -i ~/.ssh/$cert_name  'if test -e /usr/local/bin/k3s-uninstall.sh; then /usr/local/bin/k3s-uninstall.sh; fi'" || exit 1

  hl.blue "Step 1: Prepare Kube-VIP for HA. (Line:$LINENO)"
  # https://kube-vip.io/docs/usage/k3s/
  # [Remotely Execute Multi-line Commands with SSH](https://thornelabs.net/posts/remotely-execute-multi-line-commands-with-ssh/)
  inf "Clean Environment. (Line:$LINENO)\n"
  run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo rm -rf /var/lib/rancher /etc/rancher ~/.kube/*'" || exit 1
  run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo ip addr flush dev lo'" || exit 1
  run "ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo ip addr add 127.0.0.1/8 dev lo'" || exit 1
  inf "Upload kube-vip RBAC Manifest. (Line:$LINENO)\n"
  
  # Step 3: Generate a kube-vip DaemonSet Manifest
  if [[ $kube_vip_use -eq 1 ]]; then gen_kube_vip_manifest; fi

  hl.blue "Step 2: Bootstrap First k3s Node. (Line:$LINENO)"
  # https://docs.k3s.io/cli/certificate#certificate-authority-ca-certificates
  # https://github.com/k3s-io/k3s/blob/master/contrib/util/generate-custom-ca-certs.sh
  # https://blog.chkpwd.com/posts/k3s-ha-installation-kube-vip-and-metallb/
  if ! [[ $node_is_control_plane -eq 1 ]]; then err_and_exit "Error: First node has to be part of Control Plane: '$k3s_settings'." ${LINENO}; fi
  install_k3s_cmd_parm="server --cluster-init";
  cluster_config_ip=$node_ip4
  if [[ $kube_vip_use -eq 1 ]]; then
    install_k3s_cmd_parm="$install_k3s_cmd_parm \
    --disable traefik \
    --disable servicelb \
    --write-kubeconfig-mode 644 \
    --tls-san $kube_vip_address"
    cluster_config_ip=$kube_vip_address
  fi
  run "ssh -T $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${k3s_ver} sh -s - ${install_k3s_cmd_parm}'" || exit 1
  #run "ssh -T $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=${k3s_ver} INSTALL_K3S_EXEC="server" sh -'" || exit 1
  run "ssh -T $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo cp /etc/rancher/k3s/k3s.yaml ~/k3s.yaml'" || exit 1
  run "ssh -T $node_user@$node_ip4 -i ~/.ssh/$cert_name 'sudo chmod 777 ~/k3s.yaml'" || exit 1
  run "scp -i ~/.ssh/$cert_name $node_user@$node_ip4:./k3s.yaml ~/$cluster_name.yaml" || exit 1
  yq -i ".clusters[0].cluster.server = \"https://${cluster_config_ip}:6443\"" ~/$cluster_name.yaml
  cp ~/$cluster_name.yaml ~/.kube/$cluster_name
  #check_result $LINENO
  #run cp --backup=t ~/$cluster_name.yaml ~/.kube/$cluster_name
  chown $USER ~/.kube/$cluster_name
  #check_result $LINENO
  # https://ss64.com/bash/chmod.html
  chmod 600 ~/.kube/$cluster_name
  #check_result $LINENO
  rm ~/$cluster_name.yaml
  #check_result $LINENO
  run "ssh -T $node_user@$node_ip4 -i ~/.ssh/$cert_name 'rm ~/k3s.yaml'" || exit 1
  #while [[ $(kubectl get pods -l app=nginx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; do
  # sleep 1
  #done

  inf "To use kubectl: Run 'export KUBECONFIG=$HOME/.kube/$cluster_name' or 'ek $cluster_name'\n"

exit

  inf "Step 2: Bootstrap First k3s Node\n"
    # need sudo without password for $node_user: https://github.com/alexellis/k3sup/issues/298
  run k3sup install \
    --ip $node_ip4 \
    --sudo \
    --user $node_user \ 
    --tls-san $vip \
    --cluster \
    --k3s-version $k3s_ver \
    --k3s-extra-args "--disable traefik --disable servicelb --flannel-iface=$interface --node-ip=$first_node_address --node-taint node-role.kubernetes.io/master=true:NoSchedule" \
    --local-path $HOME/.kube/config \
    --ssh-key $HOME/.ssh/$cert_name \
    --context k3s-ha

  inf "Step 3: Download kube-vip\n"
  run curl -sO https://raw.githubusercontent.com/JamesTurland/JimsGarage/main/Kubernetes/K3S-Deploy/kube-vip
  run cat kube-vip | sed 's/$interface/'$interface'/g; s/$vip/'$vip'/g' > $HOME/kube-vip.yaml

  inf "echo_msg Step 4: Copy kube-vip.yaml to master1\n"
  run scp -i ~/.ssh/$certName $HOME/kube-vip.yaml $user@$master1:~/kube-vip.yaml

  inf "Step 5: Connect to Master1 and move kube-vip.yaml\n"
  run ssh $user@$master1 -i ~/.ssh/$certName "sudo mkdir -p /var/lib/rancher/k3s/server/manifests"
  run ssh $user@$master1 -i ~/.ssh/$certName "sudo mv kube-vip.yaml /var/lib/rancher/k3s/server/manifests/kube-vip.yaml"
}

################################
##         M A I N            ##
################################
[[ -f ~/.bashmatic/init.sh ]] || {
  echo "Can't find or install Bashmatic. Exiting."
  exit 1
}
source ~/.bashmatic/init.sh

if ! test -e ~/tmp; then  mkdir ~/tmp;  fi

# Check number parameters
if [[ $# -ne 1 ]]; then err_and_exit "Usage: ./k3s.sh setting.yaml." ${LINENO}; fi
k3s_settings=$1
h2 "Install K3s cluster according parameters from '$k3s_settings' file. (Line:$LINENO)"


# export KUBECONFIG=/mnt/d/dev/homelab/k3s/kubeconfig
# kubectl config use-context local
# kubectl get node -o wide

# /usr/local/bin/k3s-uninstall.sh
# /usr/local/bin/k3s-agent-uninstall.sh

# https://www.shell-tips.com/bash/debug-script/#gsc.tab=0
#set -v # Enabling verbose Mode (print every line before it's processed). +v for disable
#set -n # Syntax Checking Using noexec Mode. +n for disable
#set -x # Debugging Using xtrace Mode. +x for disable
#set -u # Identifying Unset Variables. +u for disable
# trap 'echo "Line- ${LINENO}: five_val=${five_val}, two_val=${two_val}, total=${total}" ' DEBUG
# apt install shellcheck # https://linuxsimply.com/bash-scripting-tutorial/error-handling-and-debugging/debugging/bash-shellcheck/#How_to_Install_ShellCheck_on_Ubuntu
# shellcheck ./k3s.sh

# Remove Windows CR from bash script
# sed -i -e 's/\r$//' scriptname.sh

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
  eval $(ssh-agent -t 2h) &>/dev/null
  ssh-add ~/.ssh/id_rsa
fi

# All root scalar settings
# https://github.com/jasperes/bash-yaml
# https://suriyakrishna.github.io/shell-scripting/2021/03/28/shell-scripting-yaml-configuration
# https://www.baeldung.com/linux/yq-utility-processing-yaml
eval "$( yq '.[] |(( select(kind == "scalar") | key + "='\''" + . + "'\''"))'  < $k3s_settings)"
#env $( yq '.[] |(( select(kind == "scalar") | key + "='\''" + . + "'\''"))'  < $k3s_settings)
install_k3s_tools

# Amount of nodes
if [[ $amount_nodes =~ ^[0-9]{1,3}$ && $amount_nodes -gt 0 ]]; then
  inf "      amount_nodes: '$amount_nodes'\n"
else
  err_and_exit "Error: Invalid input for amount_nodes: '$amount_nodes'." ${LINENO}
fi

amount_nodes_max=$(yq '.node | length' < $k3s_settings)
if [[ $amount_nodes -gt $amount_nodes_max ]]; then
  err_and_exit "Error: Amount of real nodes is less than requested. Real: '$amount_nodes_max', requested: '$amount_nodes'." ${LINENO}
fi

# K3S Version
if [[ $k3s_ver =~ ^v[1-2]\.[0-9]{1,2}\.[0-9]{1,2}\+((k3s1)|(rke2))$ ]]; then
  inf "           k3s_ver: '$k3s_ver'\n"
else
  err_and_exit "Error: Invalid input for k3s_ver: '$k3s_ver'." ${LINENO}
fi

if [[ $kube_vip_use -eq 1 ]]; then
  # Version of Kube-VIP to deploy
  if [[ $kube_vip_ver =~ ^v[0-9]{1,2}\.[0-9]{1,2}\.[0-9]{1,2}$ ]]; then
    inf "      kube_vip_ver: '$kube_vip_ver'\n"
  else
    err_and_exit "Error: Invalid input for kube_vip_ver: '$kube_vip_ver'." ${LINENO}
  fi

  # Kube-VIP mode
  if ! [[ "$kube_vip_mode" == "ARP" || "BGP" ]]; then
    err_and_exit "Error: Invalid kube_vip_mode: '$kube_vip_mode'. Expected 'ARP' or 'BGP'." ${LINENO}
  fi
  inf "      kube_vip_mode: '$kube_vip_mode'\n"
fi

# Nodes
#readarray nodes < <(yq '.nodes[] |= sort_by(.node_id)' < $k3s_settings)
readarray nodes < <(yq -o=j -I=0 '.node[]' < $k3s_settings)
for node in "${nodes[@]}"; do
  eval "$( yq '.[] | ( select(kind == "scalar") | key + "='\''" + . + "'\''")' <<<$node)"
  inf "          k3s_node: id='$node_id', ip4='$node_ip4', eth='$node_interface', master='$node_is_control_plane', worker='$node_is_worker', name='$node_name', user='$node_user'"
  # k3s installation
  if [[ $node_id -eq 1 ]]; then # first cluster node
    first_node_address=$node_ip4
    if [[ $first_node_address = "localhost" ]]; then
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
    echo "kuku"
  fi
done

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
