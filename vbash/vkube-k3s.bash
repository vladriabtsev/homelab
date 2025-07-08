#!/usr/bin/env bash

  #while [[ $(kubectl get pods -l app=nginx -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}' > /dev/null 2> /dev/null) != "True" ]]; do
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
function vkube-k3s.is-app-ready() {
  if [[ $(kubectl get pods -l app=$1 -o 'jsonpath={..status.conditions[?(@.type=="Ready")].status}') != "True" ]]; then
    return 1
  fi
  return 0
}
function vkube-k3s.check-cluster-plan-path() {
  if [[ -z ${args[--cluster-plan]} ]]; then
    err_and_exit "Flag --cluster-plan is required.\n"
  fi
  # https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_07_01.html
  if [[ -a ${args[--cluster-plan]} ]]; then # file exists
    # shellcheck disable=SC2154
    cluster_plan_file=${args[--cluster-plan]}
  else # file is not exists
    if ! [[ ${args[--cluster-plan]} == *"/"* ]]; then # check if path is simple word
      # trying to find 'vkube-data' in folder with vkube script
      __tmp="${vkube_folder}/vkube-data/${args[--cluster-plan]}/cluster-plan.yaml"
      if [[ -a $__tmp ]]; then # file exists
        cluster_plan_file=$__tmp
      else
        # trying to find 'vkube-data' in current folder
        __tmp2="${PWD}/vkube-data/${args[--cluster-plan]}/cluster-plan.yaml"
        if [[ -a $__tmp2 ]]; then # file exists
          cluster_plan_file=$__tmp2
        else
          err_and_exit "Can't find cluster plan file based on cluster plan parameter '${args[--cluster-plan]}'\n  Checked files '$__tmp'\n  and '$__tmp2'"
        fi
      fi
    else
      vlib.error-printf "Can't find file '%s' from cluster plan parameter.\n" "${args[--cluster-plan]}" >&2
    fi
  fi
  # find vkube data folder
  vkube_data_folder=$(dirname $cluster_plan_file)
  vlib.trace "vkube_data_folder=$vkube_data_folder"
}
function vkube-k3s.cluster-plan-read() {
  # YML,JSON,XML,LUA,TOML https://mikefarah.gitbook.io/yq/how-it-works
  # https://www.baeldung.com/linux/yq-utility-processing-yaml

  #source k3s-func.sh
  csi_driver_nfs_namespace="kube-system"
  csi_driver_smb_namespace="kube-system"

  if [[ $(yq --exit-status 'tag == "!!map" or tag== "!!seq"' $cluster_plan_file > /dev/null) ]]; then
    err_and_exit "Error: Invalid format for YAML file: '$cluster_plan_file'." ${LINENO}
  fi

  # All root scalar settings from yaml file to bash variables
  # https://github.com/jasperes/bash-yaml
  # https://suriyakrishna.github.io/shell-scripting/2021/03/28/shell-scripting-yaml-configuration
  # https://www.baeldung.com/linux/yq-utility-processing-yaml
  eval "$( yq '.[] |(( select(kind == "scalar") | key + "='\''" + . + "'\''"))'  < $cluster_plan_file)"

  if ! test -e ~/tmp; then  mkdir ~/tmp;  fi
}
function vkube-k3s.is-namespace-exist {
  [ -z "$1" ] && err_and_exit "Missing namespace name \$1 parameter."
  if ! (kubectl get namespace "$1" > /dev/null ); then return 1; fi
}
function vkube-k3s.namespace-create-if-not-exist {
  [ -z "$1" ] && err_and_exit "Missing namespace name \$1 parameter."
  if ! (kubectl get namespace "$1" > /dev/null ); then 
    kubectl create namespace "$1"; 
    sleep 10
  fi
}
function vkube-k3s.check-dir-data-for-secrets-with-trace() {
  [ -z "$1" ] && err_and_exit "Missing folder path \$1 parameter."
  if [ -d "$1" ]; then
    [ -a "$1/username.txt" ] || err_and_exit "Can't find user name file '$1/username.txt'."
    [ -r "$1/username.txt" ] || err_and_exit "File '$1/username.txt' exists, but not readable."
    [ -a "$1/password.txt" ] || err_and_exit "Can't find user name file '$1/password.txt'."
    [ -r "$1/password.txt" ] || err_and_exit "File '$1/password.txt' exists, but not readable."
  elif [ -a "$1" ]; then
    return 0
  else
    err_and_exit "Can't find folder or file '$path'."
  fi
  return 0
}
function vkube-k3s.check-dir-data-for-secrets() {
  [ -z "$1" ] && err_and_exit "Missing folder path \$1 parameter."
  if [ -d "$1" ]; then
    [ -a "$1/username.txt" ] || return 1
    [ -r "$1/username.txt" ] || return 1
    [ -a "$1/password.txt" ] || return 1
    [ -r "$1/password.txt" ] || return 1
  elif [ -a "$1" ]; then
    return 0
  else
    return 1
  fi
  return 0
}
function vkube-k3s.check-pass-data-for-secrets-with-trace() {
  [ -z "$1" ] && err_and_exit "Missing 'pass' password manager store folder name \$1 parameter."
  (vlib.is-pass-dir-exists "$1/username.txt") || err_and_exit "Can't find '$1/username.txt' record in 'pass' password store."
  (vlib.is-pass-dir-exists "$1/password.txt") || err_and_exit "Can't find '$1/password.txt' record in 'pass' password store."
  return 0
}
function vkube-k3s.check-pass-data-for-secrets() {
  [ -z "$1" ] && err_and_exit "Missing 'pass' password manager store folder name \$1 parameter."
  (vlib.is-pass-dir-exists "$1/username.txt") || return 1
  (vlib.is-pass-dir-exists "$1/password.txt") || return 1
  return 0
}
function vkube-k3s.secret-create {
  # https://kubernetes.io/docs/concepts/configuration/secret/
  # https://kubernetes.io/docs/tasks/configmap-secret/managing-secret-using-kubectl/
  # Create kubernetes secret
  #  $1 - kubernetes namespace where secret will be created
  #  $2 - kubernetes secret name
  #  $3 - folder path for secret data (username and password)
  #  $4 - folder of 'pass' password manager with two secret files (username.txt and password.txt) are expected inside path.
  vlib.trace "1=$1 2=$2 3=$3 4=$4"
  if [[ -z $3 && -z $4 ]]; then
    err_and_exit "Both dir folder path '\$3' and 'pass' password manager path '\$4' are empty. Expecting only one path."
  fi
  if [[ -n $3 && -n $4 ]]; then
    err_and_exit "Both dir folder path '\$3' and 'pass' password manager path '\$4' are not empty. Expecting only one path."
  fi
  if [[ -n $3 ]]; then
    vkube-k3s.secret-create-from-folder $1 $2 $3
  else
    vkube-k3s.secret-create-from-pass-folder $1 $2 $4
  fi
}
function vkube-k3s.secret-create-from-folder {
  #############################
  # Create kubernetes secret
  #  $1 - kubernetes namespace where secret will be created
  #  $2 - kubernetes secret name
  #  $3 - folder path for secret data (username and password)
  [ -z "$1" ] && err_and_exit "Missing namespace \$1 parameter."
  [ -z "$2" ] && err_and_exit "Missing secret name \$2 parameter."
  [ -z "$3" ] && err_and_exit "Missing secret folder path \$3 parameter."
  #echo "1='$1' 2='$2' 3='$3'" >&3
  eval local path=\"\$3\"
  #echo "path=$path" >&3
  vlib.trace "secret folder eval path=$path"
  vkube-k3s.check-dir-data-for-secrets-with-trace "$path"
  vkube-k3s.namespace-create-if-not-exist $1
  kubectl delete secret $2 -n $1 --ignore-not-found=true
  kubectl create secret generic $2 -n $1 --from-file=username=$path/username.txt --from-file=password=$path/password.txt
}
function vkube-k3s.secret-create-from-pass-folder {
  #############################
  # Create kubernetes secret
  #  $1 - kubernetes namespace where secret will be created
  #  $2 - kubernetes secret name
  #  $3 - folder of 'pass' password manager with two secret files (username.txt and password.txt) are expected inside path.
  [ -z "$1" ] && err_and_exit "Missing namespace \$1 parameter."
  [ -z "$2" ] && err_and_exit "Missing secret name \$2 parameter."
  [ -z "$3" ] && err_and_exit "Missing secret folder path \$3 parameter."
  vkube-k3s.check-pass-data-for-secrets-with-trace "$3"
  local username
  username="$(vlib.secret-get-text-from-pass $3/username.txt)"
  local password
  password="$(vlib.secret-get-text-from-pass $3/password.txt)"
  vkube-k3s.namespace-create-if-not-exist $1
  kubectl delete secret $2 -n $1 --ignore-not-found=true
  kubectl create secret generic $2 -n $1 --from-literal=username=$username --from-literal=password=$password
}
function vkube-k3s.get-node-admin-password() {
  local password
  if [[ -n $node_admin_password_secret_file_path ]]; then
    vlib.is-dir-exists-with-trace "$node_admin_password_secret_file_path"
    password="$(vlib.secret-get-text-from-file $node_admin_password_secret_file_path)"
  elif [[ -n $nodes_admin_password_secret_file_path ]]; then
    vlib.is-dir-exists-with-trace "$nodes_admin_password_secret_file_path"
    password="$(vlib.secret-get-text-from-file $nodes_admin_password_secret_file_path)"
  elif [[ -n $node_admin_password_secret_pass_path ]]; then
    vlib.is-pass-dir-exists-with-trace "$node_admin_password_secret_pass_path"
    password="$(vlib.secret-get-text-from-pass $node_admin_password_secret_pass_path)"
  elif [[ -n $nodes_admin_password_secret_pass_path ]]; then
    vlib.is-pass-dir-exists-with-trace "$nodes_admin_password_secret_pass_path"
    password="$(vlib.secret-get-text-from-pass $nodes_admin_password_secret_pass_path)"
  else
    err_and_exit "Node admin secret folder setting are missing. Both 'nodes_admin_password_secret_file_path' and 'node_admin_password_secret_file_path' are empty."
  fi
  echo "$password"
}
function vkube-k3s.install_tools() {
  # For testing purposes - in case time is wrong due to VM snapshots
  sudo timedatectl set-ntp off
  sudo timedatectl set-ntp on

  local _flag_precheck=0
  local ver_curr

  # Copy SSH certs to ~/.ssh and change permissions
  # if ! [[ -z $cert_name ]]; then
  #   run "line '$LINENO';cp $HOME/ssh/{$certName,$certName.pub} $HOME/.ssh"
  #   run "line '$LINENO';chmod 600 $HOME/.ssh/$certName"
  #   run "line '$LINENO';chmod 644 $HOME/.ssh/$certName.pub"
  #   # run "line '$LINENO';cp /home/$user/ssh/{$certName,$certName.pub} /home/$user/.ssh"
  #   # run "line '$LINENO';chmod 600 /home/$user/.ssh/$certName"
  #   # run "line '$LINENO';chmod 644 /home/$user/.ssh/$certName.pub"
  # fi

  # Check jq
  if ! echo '{"foo": 0}' | jq . &> /dev/null; then
    _flag_precheck=1
    err_and_exit "Tool 'jq' is not found. Need to be installed. See: https://github.com/jqlang/jq"
  # else
  #   ver_curr=$(jq | awk '/version/ {print $7}')
  #   vlib.trace "Current jq version=$ver_curr"
  #   vlib.check-github-release-version 'jq' https://api.github.com/repos/jqlang/jq/releases 'ver_curr'
  fi

  # Check kubectl
  # https://v1-32.docs.kubernetes.io/docs/tasks/tools/install-kubectl-linux/
  if ! command -v kubectl version > /dev/null 2> /dev/null; then
    _flag_precheck=1
    warn "Tool 'kubectl' is not found. Need to be installed.\n"
    # echo -e " Kubectl not found, installing ..."
    # run "line '$LINENO';curl -LO 'https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl'"
    # run "line '$LINENO';sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl"
  else
    ver_curr=$(kubectl version | awk '/Client Version:/ {print $3}')
    vlib.trace "Current kubectl version=$ver_curr"
    vlib.check-github-release-version 'kubectl' https://api.github.com/repos/kubernetes/kubernetes/releases 'ver_curr'
  fi

  # Check helm
  if ! command -v helm version &> /dev/null; then
    # echo -e " Helm not found, installing ..."
    # # run "line '$LINENO';curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"
    # # run "line '$LINENO';chmod 700 get_helm.sh"
    # # run "line '$LINENO';./get_helm.sh"
    # # run "line '$LINENO';rm ./get_helm.sh"
    # curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    # chmod 700 get_helm.sh
    # ./get_helm.sh
    # rm ./get_helm.sh

    _flag_precheck=1
    warn "Tool 'helm' is not found. Need to be installed.\n"
  else
    ver_curr=$(helm version | awk -F '\"' '{print $2}')
    vlib.trace "Current helm version=$ver_curr"
    vlib.check-github-release-version 'helm' https://api.github.com/repos/helm/helm/releases 'ver_curr'
  fi

  if [[ "$kubernetes_type" = "k3d" ]]; then
    # Install k3d
    if ! command -v k3d version &> /dev/null; then
      _flag_precheck=1
      warn "Tool 'k3d' is not found. Need to be installed.\n"
      # echo -e " k3d not found, installing ..."
      # if [ -z $k3d_ver ]; then # latest version
      #   wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
      # else # specific version
      #   wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG=$k3d_ver bash
      # fi
    else
      ver_curr=$(k3d version | awk '/k3d version/ {print $3}')
      vlib.trace "Current k3d version=$ver_curr"
      vlib.check-github-release-version 'k3d' https://api.github.com/repos/k3d-io/k3d/releases 'ver_curr'
      #ver_curr=$(k3d version | awk '/k3s version/ {print $2}')
    fi
  else
    # Install k3sup
    if ! command -v k3sup version &> /dev/null; then
      _flag_precheck=1
      warn "Tool 'k3sup' is not found. Need to be installed. See: https://github.com/alexellis/k3sup\n"
      # run "line '$LINENO';curl -sLS https://get.k3sup.dev | sh"
      # run "line '$LINENO';sudo install k3sup /usr/local/bin/"
    else
      ver_curr=$(k3sup version | awk '/Version:/ {print $2}')
      vlib.trace "Current k3sup version=$ver_curr"
      vlib.check-github-release-version 'k3sup' https://api.github.com/repos/alexellis/k3sup/releases 'ver_curr'
    fi
  fi

  # Install brew https://brew.sh/
  # if ! command -v brew help &> /dev/null; then
  #   err_and_exit "Homebrew not found, please install ..."  ${LINENO} "$0"
  #   #/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  #   #run "line '$LINENO';curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
  #   #run "line '$LINENO';chmod 700 install.sh"
  #   #run "line '$LINENO';./install.sh"
  #   #run "line '$LINENO';rm ./install.sh"
  # fi
  if [ -n "$_flag_precheck" ] && [ $_flag_precheck -eq 1 ]; then
    err_and_exit "Some tools are required to be installed."
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
  if ! [ $node_is_control_plane -eq 1 ]; then err_and_exit "Error: First node has to be part of Control Plane: '$cluster_plan_file'." ${LINENO}; fi
  cluster_node_ip=$node_ip4
  if [ -n "$kube_vip_use" ] && [ "$kube_vip_use" -eq 1 ]; then
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
function vkube-k3s.install() {
  start_time=$(date +%s)
  install_step=0

  local __install_all=1
  install_storage_at_least_one=0
  if [[ -n ${args[--core]} ]]; then
    install_core=1
    __install_all=0
  fi
  if [[ -n ${args[--storage]} ]]; then
    install_storage_at_least_one=1
    install_storage=1
    __install_all=0
  elif [[ -n ${args[--local]} || -n ${args[--csi-driver-nfs]} || -n ${args[--csi-driver-smb]} || -n ${args[--csi-synology]} || -n ${args[--longhorn]} || -n ${args[--nfs-subdir-external-provisioner-use]} ]]; then
    install_storage_at_least_one=1
    local_storage_use=0
    csi_driver_nfs_use=0
    nfs_subdir_external_provisioner_use=0
    csi_driver_smb_use=0
    csi_synology_use=0
    longhorn_use=0
    __install_all=0
  fi
  if [[ -n ${args[--local]} ]]; then
    install_storage_at_least_one=1
    local_storage_use=1
    __install_all=0
  fi
  if [[ -n ${args[--csi-driver-nfs]} ]]; then
    install_storage_at_least_one=1
    csi_driver_nfs_use=1
    __install_all=0
  fi
  if [[ -n ${args[--csi-driver-smb]} ]]; then
    install_storage_at_least_one=1
    csi_driver_smb_use=1
    __install_all=0
  fi
  if [[ -n ${args[--csi-synology]} ]]; then
    install_storage_at_least_one=1
    csi_synology_use=1
    __install_all=0
  fi
  if [[ -n ${args[--longhorn]} ]]; then
    install_storage_at_least_one=1
    longhorn_use=1
    __install_all=0
  fi
  if [[ -n ${args[--apps]} ]]; then
    install_apps=1
    __install_all=0
  fi
  if [[ ${__install_all} -eq 1 ]]; then
    install_core=1
    install_storage=1
    install_apps=1
  fi
  if [[ ${__install_storage} -eq 1 ]]; then
    install_storage_at_least_one=1
    install_storage=1
    local_storage_use=1
    csi_driver_nfs_use=1
    csi_driver_smb_use=1
    csi_synology_use=1
    longhorn_use=1
  fi
  # echo "      local_storage_use=$local_storage_use" >&3
  # echo "      csi_driver_nfs_use=$csi_driver_nfs_use" >&3
  # echo "      csi_driver_smb_use=$csi_driver_smb_use" >&3
  # echo "      csi_synology_use=$csi_synology_use" >&3
  # echo "      longhorn_use=$longhorn_use" >&3
  # echo "      install_storage_at_least_one=$install_storage_at_least_one" >&3

  local data_folder=$(dirname "${cluster_plan_file}")
  vlib.trace "data folder=$data_folder"

  vkube-k3s.install_tools

  # Amount of nodes
  if [[ $amount_nodes =~ ^[0-9]{1,3}$ && $amount_nodes -gt 0 ]]; then
    inf "               amount_nodes: '$amount_nodes'\n"
  else
    err_and_exit "Error: Invalid input for amount_nodes: '$amount_nodes'." ${LINENO}
  fi

  amount_nodes_max=$(yq '.node | length' < $cluster_plan_file)
  if [[ $amount_nodes -gt $amount_nodes_max ]]; then
    err_and_exit "Error: Amount of real nodes is less than requested. Real: '$amount_nodes_max', requested: '$amount_nodes'." ${LINENO}
  fi

  if [[ -n  $install_core ]]; then
    case $kubernetes_type in
      k3s )
        h2 "Install K3s cluster '$cluster_name' with $amount_nodes nodes. Cluster plan from '$cluster_plan_file' file. (Line:$LINENO)"
        # export KUBECONFIG=/mnt/d/dev/homelab/k3s/kubeconfig
        # kubectl config use-context local
        # kubectl get node -o wide

        # /usr/local/bin/k3s-uninstall.sh
        # /usr/local/bin/k3s-agent-uninstall.sh

        install-k3s
        export KUBECONFIG=~/.kube/$cluster_name
        run "line '$LINENO';wait_kubectl_can_connect_cluster"

        # https://kube-vip.io/docs/usage/cloud-provider/
        # https://kube-vip.io/docs/usage/cloud-provider/#install-the-kube-vip-cloud-provider
        if [ -n "$kube_vip_use" ] && [ "$kube_vip_use" -eq 1 ]; then
          hl.blue "$((++install_step)). Install the kube-vip Cloud Provider. (Line:$LINENO)"
          inf "kube-vip (Line:$LINENO)\n"
          run vlib.check-github-release-version 'kube-vip' https://api.github.com/repos/kube-vip/kube-vip/releases 'kube_vip_ver'
          #echo ${kube_vip_ver}
          if [[ $(kubectl get pods -lapp.kubernetes.io/name=kube-vip-ds,app.kubernetes.io/version=${kube_vip_ver} -n kube-system > /dev/null 2> /dev/null | wc -l) -eq 0 ]]; then
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
      ;;
      k3d )
        h2 "Install K3d cluster '$cluster_name' with $amount_nodes nodes. Cluster plan from '$cluster_plan_file' file. (Line:$LINENO)"
        run "line '$LINENO';k3d cluster create $cluster_name --wait"
        #export KUBECONFIG=~/.kube/$cluster_name
      ;;
      # k83 )
      #   vlib.trace "csi_synology_host_protocol_class_location=$csi_synology_host_protocol_class_location"
      # ;;
      * )
        err_and_exit "Unsupported kubernetes type '$kubernetes_type'. Expected: k3s, k3d" ${LINENO};
    esac
    inf "New kubernetes cluster '$cluster_name' is installed on servers described in cluster plan YAML file '$cluster_plan_file'\n"
    inf "To use kubectl: Run 'export KUBECONFIG=~/.kube/$cluster_name' or 'ek $cluster_name'\n"

    kubectl get nodes
  fi

  # p_skip=0
  # if test -e "${HOME}/.kube/${cluster_name}"; then 
  #   run.ui.ask "Cluster config '${cluster_name}' already exist. Uninstall and proceed new installation?" || p_skip=1
  #   #if [ $((opt_install_new || opt_install_remove || opt_install_upgrade)) -eq 1 ]; then
  #   #run.ui.press-any-key "Config for cluster '${cluster_name}' already exists. Override? (^C for cancel)"
  # fi
  # if [[ $p_skip -eq 0 ]]; then
  # fi

  if [[ $install_storage_at_least_one -eq 1 ]]; then
    install-storage
  fi

  return 0
  err_and_exit "exit" ${LINENO}


  # Longhorn
  # https://longhorn.io/docs/1.7.2/deploy/install/install-with-kubectl/
  hl.blue "$((++install_step)). Install Longhorn. (Line:$LINENO)"
  ./101-longhorn/install.sh -s "${cluster_plan_file}" -w "${node_root_password}" -t "${install_step}" -i $longhorn_ver

  # https://wiki.musl-libc.org/building-busybox
  # https://github.com/docker-library/repo-info/blob/master/repos/busybox/remote/musl.md
  ./102-busybox/install.sh -s "${cluster_plan_file}" -w "${node_root_password}" -t "${install_step}" -i $busybox_ver

  # Velero backup/restore
  hl.blue "$((++install_step)). Install Velero backup/restore. (Line:$LINENO)"
  #./velero/install.sh -s "${cluster_plan_file}" -w "${node_root_password}" -t "${install_step}" -i $longhorn_ver
  ./velero/install.sh -t "${install_step}" -i $velero_ver

  # Rancher
  hl.blue "$((++install_step)). Install Rancher. (Line:$LINENO)"
  ./105-rancher/install.sh -i $rancher_ver

  # pi-hole
  if [ -n "$pi_hole_use" ] && [ "$pi_hole_use" -eq 1 ]; then
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
  run "line '$LINENO';vkube-k3s.namespace-create-if-not-exist argocd"
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
  run "line '$LINENO';vkube-k3s.namespace-create-if-not-exist cattle-system"
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
function vkube-k3s.csi-synology-install() {
  vkube-k3s.check-cluster-plan-path
  hl.blue "$((++install_step)). Generate storage classes for synology csi driver. (Line:$LINENO)"
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
  local synology_csi_plan=${args[plan]}
  vlib.trace "vkube_data_folder=${vkube_data_folder}"
  if [[ -z $synology_csi_plan ]]; then
    synology_csi_plan="${vkube_data_folder}/cluster-storage-plan.yaml"
  fi
  vlib.trace "synology_csi_plan=${synology_csi_plan}"
  run "line '$LINENO';vlib.is-file-exists-with-trace '${synology_csi_plan}'"
  if [[ $(yq --exit-status 'tag == "!!map" or tag== "!!seq"' "${synology_csi_plan}" > /dev/null) ]]; then
    err_and_exit "Error: Invalid format for YAML file: '${synology_csi_plan}'." ${LINENO}
  fi
  # if [[ $(yamllint ${synology_csi_plan} > /dev/null) ]]; then
  #   err_and_exit "Error: Not valid csi synology plan file: '${synology_csi_plan}'." ${LINENO}
  # fi

  local data_folder=$(dirname "${synology_csi_plan}")
  vlib.trace "data folder=$data_folder"

  # Defaults
  # Root level scalar settings
  eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_" + key + "='\''" + . + "'\''")'  < "${synology_csi_plan}")"
  #vlib.trace "csi_synology_snapshot_use=${csi_synology_snapshot_use}"

  csi_synology_namespace="synology-csi"
  vlib.trace "csi_synology_namespace=${csi_synology_namespace}"
  run "line '$LINENO';vkube-k3s.namespace-create-if-not-exist $csi_synology_namespace"

  readarray csi_synology_hosts < <(yq -o=j -I=0 ".hosts[]" "${synology_csi_plan}")
  vlib.trace "storage hosts count=${#csi_synology_hosts[@]}"
  local txt=""
  local separator=""
  local storage_class=""
  i_host=-1

  #vlib.trace "default reclaimPolicy=$csi_synology_host_protocol_class_reclaimPolicy"
  declare -A host_names_dic=()
  for csi_synology_host in "${csi_synology_hosts[@]}"; do
    i_host+=1
    vlib.trace "storage host=$csi_synology_host"
    # Host level scalar settings
    eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host)"
    vlib.trace "storage host name=$csi_synology_host_name"
    if [[ -z $csi_synology_host_name ]]; then
      err_and_exit "Empty host name. Configuration YAML file: '${synology_csi_plan}'." ${LINENO}
    fi
    if [[ -v host_names_dic["${csi_synology_host_name}"] ]]; then
      vlib.trace "host names(${#host_names_dic[@]})=" "${!host_names_dic[@]}"
      err_and_exit "Host name is not unique. Configuration YAML file: '${synology_csi_plan}'. Host name '$csi_synology_host_name'." ${LINENO}
    fi
    host_names_dic["${csi_synology_host_name}"]='y'
    readarray csi_synology_host_protocols < <(echo $csi_synology_host | yq -o=j -I=0 ".protocols[]")
    vlib.trace "storage protocols count=${#csi_synology_host_protocols[@]}"
    if [[ ${#csi_synology_host_protocols[@]} -eq 0 ]]; then
      err_and_exit "There are no storage protocol for host. Configuration YAML file: '${synology_csi_plan}'. Host '$csi_synology_host_name'." ${LINENO}
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
        err_and_exit "Storage protocol name is not unique. Configuration YAML file: '${synology_csi_plan}'. Host name '$csi_synology_host_name'. Protocol name '$csi_synology_host_protocol_name'." ${LINENO}
      fi
      protocol_names["${csi_synology_host_protocol_name}"]='y'
      #readarray csi_synology_host_protocol_classes < <(yq -o=j -I=0 ".hosts[$i_host].protocols[$i_protocol].classes[]" "${synology_csi_plan}")
      readarray csi_synology_host_protocol_classes < <(echo $csi_synology_host_protocol | yq -o=j -I=0 ".classes[]")
      vlib.trace "storage classes count=${#csi_synology_host_protocol_classes[@]}"
      if [[ ${#csi_synology_host_protocol_classes[@]} -eq 0 ]]; then
        err_and_exit "There are no storage class for protocol. Configuration YAML file: '${synology_csi_plan}'. Host '$csi_synology_host_name'. Protocol '$csi_synology_host_protocol_name'." ${LINENO}
      fi
      #vlib.trace "reclaimPolicy=$csi_synology_host_protocol_class_reclaimPolicy"
      for csi_synology_host_protocol_class in "${csi_synology_host_protocol_classes[@]}"; do
        vlib.trace "storage class=$csi_synology_host_protocol_class"
        eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host)"
        eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_protocol_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host_protocol)"
        eval "$( yq '.[] | ( select(kind == "scalar") | "csi_synology_host_protocol_class_" + key + "='\''" + . + "'\''")' <<<$csi_synology_host_protocol_class)"
        vlib.trace "storage class name=$csi_synology_host_protocol_class_name"
        #vlib.trace "reclaimPolicy=$csi_synology_host_protocol_class_reclaimPolicy"
        if [[ -z $csi_synology_host_protocol_class_location ]]; then
          err_and_exit "Empty location. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        fi
        if [[ -z $csi_synology_host_protocol_class_reclaimPolicy ]]; then
          err_and_exit "Empty reclaimPolicy. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        fi
        if [[ -z $csi_synology_host_protocol_class_allowVolumeExpansion ]]; then
          err_and_exit "Empty allowVolumeExpansion. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        fi
        # if [[ -z $csi_synology_host_protocol_class_mountPermissions ]]; then
        #   err_and_exit "Empty mountPermissions. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        # fi
        case $csi_synology_host_protocol_name in
          synology-csi-iscsi )
            # Not working, but see next fix
            # https://github.com/SynologyOpenSource/synology-csi/pull/85/commits/bf76a99957e78bbb8ec6b1d640625942182d1924
            storage_class="$csi_synology_host_name-synology-csi-iscsi-$csi_synology_host_protocol_class_name"
            #region
            txt+="${separator}apiVersion: storage.k8s.io/v1 # line:${LINENO}
kind: StorageClass
metadata:
  name: $storage_class
  labels:
    vkube/storage-type: synology-csi-iscsi
  annotations:
    storageclass.kubernetes.io/is-default-class: \"false\"
provisioner: csi.san.synology.com
parameters: # https://github.com/SynologyOpenSource/synology-csi
  protocol: iscsi
  dsm: \"$csi_synology_host_dsm_ip4\"
  location: \"$csi_synology_host_protocol_class_location\" # if blank, the CSI driver will choose a volume on DSM with available storage to create the volumes
  csi.storage.k8s.io/fstype: '$csi_synology_host_protocol_class_fsType'
  formatOptions: '--nodiscard'
reclaimPolicy: $csi_synology_host_protocol_class_reclaimPolicy
allowVolumeExpansion: $csi_synology_host_protocol_class_allowVolumeExpansion
"
            # formatOptions
            # https://linux.die.net/man/8/mkfs
            # https://linux.die.net/man/8/mkfs.ext4
            #endregion
          ;;
          synology-csi-smb )
            #run "line '$LINENO';vlib.var.only-one-has-be-not-empty $csi_synology_host_protocol_secret_folder $csi_synology_host_protocol_secret_pass_folder"
            secret_folder_name=$(basename "$csi_synology_host_protocol_secret_folder")
            storage_class="$csi_synology_host_name-synology-csi-smb-$csi_synology_host_protocol_class_name"
            vlib.trace "secret_folder_name=$secret_folder_name"
            run "line '$LINENO';kubectl delete secret $secret_folder_name -n $csi_synology_namespace --ignore-not-found=true"
            # https://www.baeldung.com/ops/kubernetes-namespaces-common-secrets
            run "line '$LINENO';vkube-k3s.secret-create $csi_synology_namespace $secret_folder_name $csi_synology_host_protocol_secret_folder $csi_synology_host_protocol_secret_pass_folder"
            #region
            txt+="${separator}apiVersion: storage.k8s.io/v1 # line:${LINENO}
kind: StorageClass
metadata:
  name: $storage_class
  labels:
    vkube/storage-type: synology-csi-smb
provisioner: csi.san.synology.com
parameters: # https://github.com/SynologyOpenSource/synology-csi
  protocol: \"smb\"
  dsm: '$csi_synology_host_dsm_ip4'
  location: '$csi_synology_host_protocol_class_location' # if blank, the CSI driver will choose a volume on DSM with available storage to create the volumes
  csi.storage.k8s.io/node-stage-secret-name: $secret_folder_name
  csi.storage.k8s.io/node-stage-secret-namespace: $csi_synology_namespace
reclaimPolicy: $csi_synology_host_protocol_class_reclaimPolicy
allowVolumeExpansion: $csi_synology_host_protocol_class_allowVolumeExpansion
"
            #endregion
          ;;
          synology-csi-nfs )
            storage_class="$csi_synology_host_name-synology-csi-nfs-$csi_synology_host_protocol_class_name"
            #region
            txt+="${separator}apiVersion: storage.k8s.io/v1 # line:${LINENO}
kind: StorageClass
metadata:
  name: $storage_class
  labels:
    vkube/storage-type: synology-csi-nfs
provisioner: csi.san.synology.com
parameters: # https://github.com/SynologyOpenSource/synology-csi
  protocol: nfs
  dsm: \"$csi_synology_host_dsm_ip4\"
  location: \"$csi_synology_host_protocol_class_location\" # if blank, the CSI driver will choose a volume on DSM with available storage to create the volumes
  mountPermissions: \"$csi_synology_host_protocol_class_mountPermissions\"
mountOptions:
  - nfsvers=$csi_synology_host_protocol_class_mountOptions_nfsvers
reclaimPolicy: $csi_synology_host_protocol_class_reclaimPolicy
allowVolumeExpansion: $csi_synology_host_protocol_class_allowVolumeExpansion
"
            #endregion
            vlib.trace "csi_synology_host_protocol_class_location=$csi_synology_host_protocol_class_location"
          ;;
          * )
            err_and_exit "Unsupported storage protocol '$name'. Expected: ISCSI, SMB, NFS" ${LINENO};
        esac
        #region
        separator="---
"
        #endregion
        run "line '$LINENO';kubectl delete storageclass $storage_class --wait --ignore-not-found=true"
      done
    done
  done
  #set +x
  #vlib.trace "generated storage classes=\n$txt"
  run "line '$LINENO';echo '$txt' > '$data_folder/../generated-synology-csi-storage-classes.yaml'"
  #run "line '$LINENO';kubectl apply edit-last-applied -f '$data_folder/generated-storage-classes.yaml'"
  run "line '$LINENO';kubectl apply -f '$data_folder/../generated-synology-csi-storage-classes.yaml'"

  local deploy_k8s_version="v1.20"
  inf "synology-csi (Line:$LINENO)\n"
  #run vlib.check-github-release-version 'synology-csi' https://api.github.com/repos/SynologyOpenSource/synology-csi/releases 'csi_synology_ver'
  # echo $csi_synology_ver
  if [[ $(kubectl get pods -l app=controller,app.kubernetes.io/name=synology-csi -n $csi_synology_namespace > /dev/null 2> /dev/null | wc -l) -eq 0 ]]; then # not installed yet
    eval "csi_synology_folder_with_dsm_secrets=$csi_synology_folder_with_dsm_secrets"
    vlib.trace "csi_synology_folder_with_dsm_secrets=$csi_synology_folder_with_dsm_secrets"

    # /etc/synology/client-info.yml

    if kubectl get secret -n $csi_synology_namespace client-info-secret > /dev/null 2> /dev/null ; then
      run "line '$LINENO';kubectl delete secret -n $csi_synology_namespace client-info-secret --ignore-not-found=true"
    fi
    run "line '$LINENO';kubectl create secret -n $csi_synology_namespace generic client-info-secret --from-file="$csi_synology_folder_with_dsm_secrets/client-info.yml""
    #run "line '$LINENO';vkube-k3s.secret-create $csi_synology_namespace client-info-secret $csi_synology_folder_with_dsm_secrets/client-info.yml"
    run "line '$LINENO';kubectl apply -f $vkube_data_folder/synology-csi/kubernetes/$deploy_k8s_version"

    if [ -n "$csi_synology_snapshot_use" ] && [ "$csi_synology_snapshot_use" -eq 1 ]; then
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
  if [ -n "$csi_synology_snapshot_use" ] && [ "$csi_synology_snapshot_use" -eq 1 ]; then
    run "line '$LINENO';kubectl delete -f '$vkube_data_folder/synology-csi/kubernetes/$deploy_k8s_version/snapshotter/volume-snapshot-class.yml' --ignore-not-found"
    run "line '$LINENO';kubectl delete -f '$vkube_data_folder/synology-csi/kubernetes/$deploy_k8s_version/snapshotter/snapshotter.yaml' --ignore-not-found"
    run "line '$LINENO';kubectl delete -f '$vkube_data_folder/synology-csi/synology CRDs' --ignore-not-found"
  fi
}
function vkube-k3s.storage-speedtest-job-create() {
  [[ -z $1 ]] && err_and_exit "Missing \$1 namespace parameter"
  [[ -z $2 ]] && err_and_exit "Missing \$2 storage class name parameter"
  [[ -z $3 ]] && err_and_exit "Missing \$3 access mode parameter"
  #[[ -z $3 ]] && vlib.error-printf "Missing \$3 storage size parameter"
  [[ -z $vkube_data_folder ]] && err_and_exit "Missing \$data_folder"

  # https://www.talos.dev/v1.10/kubernetes-guides/configuration/synology-csi/

  #region read and write jobs
  txt="kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: $2-test-pvc
  namespace: $1
spec:
  storageClassName: $2
  accessModes:
  - $3
  resources:
    requests:
      storage: 5G
---
apiVersion: batch/v1
kind: Job
metadata:
  name: $2-write-read
  namespace: $1
spec:
  template:
    metadata:
      name: $2-write-read
      namespace: $1
      labels:
        app: $2-storage-speedtest
        job: write-read
    spec:
      containers:
      - name: write-read
        image: ubuntu:xenial
        command: ["sh", "-c"]
        args:
        - |
          # apt-get install -y iozone3
          # echo '  iozone -t1 -i0 -i2 -r1k -s1g -F /tmp/testfile:'
          # iozone -t1 -i0 -i2 -r1k -s1g -F /tmp/testfile
          echo '  Sequential writing results:'
          dd if=/dev/zero of=/mnt/pv/test.img bs=1G count=1 oflag=dsync
          echo '  Sequential reading results:'
          # flush buffers or disk caches #
          #echo 3 | tee /proc/sys/vm/drop_caches
          dd if=/mnt/pv/test.img of=/dev/null bs=8k
        volumeMounts:
        - mountPath: "/mnt/pv"
          name: test-volume
      volumes:
      - name: test-volume
        persistentVolumeClaim:
          claimName: $2-test-pvc
      restartPolicy: Never
"
  #endregion read and write jobs
  vkube-k3s.namespace-create-if-not-exist $1
  vlib.trace "jobs=$txt"
  #kubectl apply -f - <<<"${txt}"
  #run "line '$LINENO';echo '$txt' > '$vkube_data_folder/storage-speed/generated-$2-write-read-job.yaml'"
  #run "line '$LINENO';kubectl apply -f '$vkube_data_folder/storage-speed/generated-$2-write-read-job.yaml'"
  echo "$txt" > "$vkube_data_folder/storage-speed/generated-$2-write-read-job.yaml"
  kubectl apply -f "$vkube_data_folder/storage-speed/generated-$2-write-read-job.yaml"
}
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

  local txt=""
  local txt_init_args=""
  local txt_deploy=""
  local txt_deploy_vol=""
  local txt_deploy_vol_mount=""
  local separator=""
  
  #region
  txt_deploy+="apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${args[name]}
  namespace: ${args[--namespace]}
  labels:
    app: ${args[name]}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${args[name]}  
  template:
    metadata:
      labels:
        app: ${args[name]}
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
          #create mount directory
          #apk add open-iscsi
          #mkdir -p /usr/bin/env"
    #endregion

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
    #region
    txt+="${separator}apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${args[name]}-$__s-pvc
  namespace: ${args[--namespace]}
spec:
  storageClassName: $__s
  accessModes: 
  - ${args[--access-mode]}
  resources:
    requests:
      storage: ${args[--storage-size]}
"
    #endregion
    case $__storage_type in
      iscsi )
        [[ "${access-mode}" == "ReadWriteMany" ]] && warn-and-trace "ReadWriteMany access mode is not supported for ISCSI"
        #err_and_exit "Not implemented" ${LINENO}
      ;;
      smb )
      ;;
      nfs ) # https://medium.com/@bastian.ohm/configuring-your-synology-nas-as-nfs-storage-for-kubernetes-cluster-5e668169e5a2
      ;;
      synology-csi-iscsi )
        [[ "${access-mode}" == "ReadWriteMany" ]] && warn-and-trace "ReadWriteMany access mode is not supported for ISCSI"
      ;;
      synology-csi-smb )
      ;;
      synology-csi-nfs )
      ;;
      * )
        if [[ -z $__storage_type ]]; then
          err_and_exit "Storage class '$__s with label 'vkube/storage-type' is not found in kubernetes cluster" ${LINENO};
        else
          err_and_exit "Storage class '$__s with label 'vkube/storage-type: $$__storage_type' is not supported" ${LINENO};
        fi
    esac
    #region
    separator="---
"
    txt_init_args+="
          mkdir -p /home/${args[name]}-$__s-vol && chown -R 999:999 /home/${args[name]}-$__s-vol"
    txt_deploy_vol+="
      - name: ${args[name]}-$__s-vol
        persistentVolumeClaim:
          claimName: ${args[name]}-$__s-pvc"
    txt_deploy_vol_mount+="
          - name: ${args[name]}-$__s-vol
            mountPath: /home/${args[name]}-$__s-vol # The mount point inside the container"
    #endregion
  done

  txt_deploy+="$txt_init_args"
  #region
  txt_deploy+="
      containers:
        - name: busybox
          image: busybox:musl
          imagePullPolicy: 'IfNotPresent'
          command:
            - 'sh'
            - '-c'
            - 'while true; do sleep 6000; done'
          resources:
            limits:
              memory: '128Mi'
              cpu: '100m'"
  txt_deploy+="
          volumeMounts:"
  txt_deploy+="$txt_deploy_vol_mount"
  txt_deploy+="
      volumes:"
  #endregion
  txt_deploy+="$txt_deploy_vol"
  vlib.trace "generated PVCs=\n$txt"
  run "line '$LINENO';vkube-k3s.namespace-create-if-not-exist ${args[--namespace]}"
  run "line '$LINENO';kubectl apply -f - <<<\"${txt}\""

  hl.blue "$parent_step$((++install_step)). Busybox installation. (Line:$LINENO)"
  run "line '$LINENO';kubectl apply -f - <<<\"${txt_deploy}\""
  
  err_and_exit "Not implemented" ${LINENO}


  # ${args[--storage-class]}

  # if ! [[ -e ${cluster_plan_file} ]]; then
  #   err_and_exit "Cluster plan file '${cluster_plan_file}' is not found" ${LINENO};
  # fi
  # #echo $node_root_password
  # if [[ -z $node_root_password ]]; then
  #   node_root_password=""
  #   vlib.read-password node_root_password "Please enter root password for cluster nodes:"
  #   echo
  # fi

  # hl.blue "$parent_step$((++install_step)). Busybox installation. (Line:$LINENO)"
  # if command kubectl get deploy busybox -n busybox-system &> /dev/null; then
  #   err_and_exit "Busybox already installed."  ${LINENO} "$0"
  # fi

  #region
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
  # https://overcast.blog/provisioning-kubernetes-local-persistent-volumes-full-tutorial-147cfb20ec27
  storageClassName: local-storage
  hostPath:
    path: /mnt/pv-data
"
  #endregion

  #exit 1
  err_and_exit "Not implemented" ${LINENO}
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
function install-k3s() {
  
  case $kubernetes_type in
    k3s )
      # k3s Version
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
    ;;
    k3d )
      # k3d Version
      run vlib.check-github-release-version 'k3d' https://api.github.com/repos/k3d-io/k3d/releases 'k3d_ver'

      k3d_latest=$(curl -sL https://api.github.com/repos/k3d-io/k3d/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
      if [ -z $k3d_ver ]; then
        k3d_ver=$k3d_latest
      fi

      k3s_latest=$(curl -sL https://api.github.com/repos/k3s-io/k3s/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
      if [ -z $k3s_ver ]; then
        k3s_ver=$k3s_latest
      else
        run vlib.check-github-release-version 'k3sup' https://api.github.com/repos/alexellis/k3sup/releases 'k3s_ver'
      fi
      if [[ $k3s_ver =~ ^v[1-2]\.[0-9]{1,2}\.[0-9]{1,2}\+((k3s1)|(rke2))$ ]]; then
        inf "                    k3s_ver: '$k3s_ver'\n"
      else
        err_and_exit "Error: Invalid input for k3s_ver: '$k3s_ver'." ${LINENO}
      fi
      if ! [ "$k3s_latest" == "$k3s_ver" ]; then
        warn "Latest version of K3s: '$k3s_latest', but installing: '$k3s_ver'\n"
      fi

      local ver_curr
      ver_curr=$(k3sup version | awk '/Version:/ {print $2}')
      run vlib.check-github-release-version 'k3sup' https://api.github.com/repos/alexellis/k3sup/releases 'ver_curr'

    ;;
    * ) 
      err_and_exit "Error: Wrong 'kubernetes_type: $kubernetes_type' in cluster plan file. Expecting k3s or k3d."
    ;;
  esac
  
  # kube vip
  if [ -n "$kube_vip_use" ] && [ "$kube_vip_use" -eq 1 ]; then
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
  inf "               metal_lb_ver: '$metal_lb_ver'\n"
  if ! [ "$metal_lb_latest" == "$metal_lb_ver" ]; then
    warn "Latest version MetalLB: '$metal_lb_latest', but installing: '$metal_lb_ver'\n"
  fi

  # Nodes
  #readarray nodes < <(yq '.nodes[] |= sort_by(.node_id)' < $cluster_plan_file)
  readarray nodes < <(yq -o=j -I=0 '.node[]' < $cluster_plan_file)

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
}
#region Longhorn
longhorn-check-version()
{
  #longhorn_latest=$(curl -sL https://api.github.com/repos/longhorn/longhorn/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  longhorn_latest=$(curl -sL https://api.github.com/repos/longhorn/longhorn/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  longhorn_ver="$1"
  if [ -z $longhorn_ver ]; then longhorn_ver=$longhorn_latest; fi
  if ! [ -z $2 ]; then
    if ! [ "$longhorn_latest" == "$longhorn_ver" ]; then
      warn "Latest version of Longhorn: '$longhorn_latest', but installing: '$longhorn_ver'\n"
    fi
  fi
}
node_disks()
{
  declare -a -g node_storage_class_array
  declare -a -g node_disk_uuid_array
  declare -a -g node_mnt_path_array
  # https://mikefarah.gitbook.io/yq/usage/tips-and-tricks
  #echo $i_node
  readarray disks < <(yq -o=j -I=0 ".node[$i_node].node_storage[]" < $cluster_plan_file)
  local i_disk=0
  for disk in "${disks[@]}"; do
    eval "$( yq '.[] | ( select(kind == "scalar") | key + "='\''" + . + "'\''")' <<<$disk)"
    node_storage_class_array[i_disk]=$storage_class
    node_disk_uuid_array[i_disk]=$disk_uuid
    node_mnt_path_array[i_disk]=$mnt_path
    ((i_disk++))
  done
  n_disks=$i_disk # Total disks
  case $1 in
    1 )
      hl.blue "$parent_step$((++install_step)). Mount disks on node $node_name($node_ip4). (Line:$LINENO)"

      # Create initial .bak of current fstab file
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'if sudo -S ! test -e /etc/fstab.bak; then cp /etc/fstab /etc/fstab.bak; fi <<< \"$node_root_password\"'"
      # Get local copy of node's fstab
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'sudo -S 'cp /etc/fstab ~/fstab' <<< \"$node_root_password\"'"
      run "line '$LINENO';scp -i ~/.ssh/$cert_name $node_user@$node_ip4:~/fstab ~/fstab"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name  'sudo -S 'rm ~/fstab' <<< \"$node_root_password\"'"
      run "line '$LINENO';sed -i \"/UUID= /d\" ~/fstab"
      # fstab and mount directories
      for (( i=0; i < n_disks; i++ )); do
        # Delete previous fstab record and append new one
        vlib.trace "node_disk_uuid=${node_disk_uuid_array[$i]}"
        vlib.trace "node_mnt_path=${node_mnt_path_array[$i]}"
        run "line '$LINENO';sed -i \"\,${node_disk_uuid_array[$i]},d\" ~/fstab"
        run "line '$LINENO';sed -i \"\,${node_mnt_path_array[$i]},d\" ~/fstab"
        run "line '$LINENO';echo 'UUID=${node_disk_uuid_array[$i]}  ${node_mnt_path_array[$i]} ext4  defaults  0  0' >> ~/fstab"
        # Create mount directory if not exists
        run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo -S sh -c 'if [ ! -e ${node_mnt_path_array[i]} ]; then mkdir ${node_mnt_path_array[i]}; fi' <<< '$node_root_password'\""
      done
      # Copy updated fstab to node
      run "line '$LINENO';scp -i ~/.ssh/$cert_name.pub ~/fstab $node_user@$node_ip4:~/fstab"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo -S mv ~/fstab /etc/fstab <<< '$node_root_password'\""
      # Remount all
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"sudo -S mount -a <<< '$node_root_password'\""

      hl.blue "$parent_step$((++install_step)). Load dm_crypt module on node $node_name($node_ip4). (Line:$LINENO)"
      # https://linovox.com/use-modprobe-command-in-linux/
      # https://www.cyberciti.biz/faq/linux-how-to-load-a-kernel-module-automatically-at-boot-time/
      # https://www.baeldung.com/linux/kernel-module-load-boot
      # sudo systemctl start dm_crypt_load.service
      # sudo systemctl status dm_crypt_load.service
      # sudo systemctl enable dm_crypt_load.service
      # lsmod | grep dm_crypt
      # sudo modprobe dm_crypt
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name \"if [ ! -e ~/tmp ]; then mkdir ~/tmp; fi\""
      #run "line '$LINENO';scp -i ~/.ssh/$cert_name ./101-longhorn/dm_crypt_load.sh $node_user@$node_ip4:~/tmp/dm_crypt_load.sh"
      local txt
      run "line '$LINENO';(cat <<EOF1
#!/bin/bash
# /etc/systemd/system/dm_crypt_load.service
[Unit]
Description=Load dm_crypt module for Longhorn
[Service]
Type=oneshot
ExecStart=/bin/sh -c \"modprobe dm_crypt\"
[Install]
WantedBy=multi-user.target
EOF2
mv ~/tmp/dm_crypt_load.service /etc/systemd/system/dm_crypt_load.service
systemctl enable dm_crypt_load.service
modprobe dm_crypt
EOF1
) | ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name -T \"cat > ~/tmp/dm_crypt_load.sh\""
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'chmod 777 ~/tmp/dm_crypt_load.sh'"
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name sudo -S sh -c '~/tmp/dm_crypt_load.sh' <<< \"$node_root_password\""
      run "line '$LINENO';ssh $node_user@$node_ip4 -i ~/.ssh/$cert_name 'rm ~/tmp/dm_crypt_load.sh'"
    ;;
    2 )
      hl.blue "$parent_step$((++install_step)). Longhorn node disks config settings for $node_name($node_ip4). (Line:$LINENO)"
      # https://stackoverflow.com/questions/73370812/how-to-add-annotations-to-kubernetes-node-using-patch-file
      # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_patch/
      # patch for node disk settings
      # https://longhorn.io/docs/archives/1.3.1/advanced-resources/default-disk-and-node-config/#launch-longhorn-with-multiple-disks

      # https://longhorn.io/kb/tip-only-use-storage-on-a-set-of-nodes/
      if [[ $n_disks -eq 0 ]]; then
        run "line '$LINENO';kubectl label --overwrite nodes $node_name node.longhorn.io/create-default-disk=true" # mounted disks are not included
      else
        run "line '$LINENO';kubectl label --overwrite nodes $node_name node.longhorn.io/create-default-disk='config'" # mounted disks are not included
        local first=1
        local tmp=""
        local tmp2="" # only mounted disks
        #local tmp2="{\"path\":\"/var/lib/longhorn\",\"allowScheduling\":true}" # mounted disks are not included
        declare -A storage_classes
        for (( i=0; i < n_disks; i++ )); do
          if [[ $first -eq 0 ]]; then
            tmp2="${tmp2}, "
          fi
          tmp="${node_mnt_path_array[$i]}"
          tmpsc="${node_storage_class_array[$i]}"
          # https://documentation.suse.com/cloudnative/storage/1.9.0/en/nodes/default-disk-and-node-config.html
          storage_classes["${tmpsc}"]="${tmpsc}"
          tmp2="${tmp2}{\"path\": \"${tmp}\", \"allowSheduling\":true, \"tags\":[\"${tmpsc}\"]}" # \"storage\",
          first=0
        done
        # https://stackoverflow.com/questions/1494178/how-to-define-hash-tables-in-bash
        tmp=""
        first=1
        for _storage_class in "${!storage_classes[@]}"; do 
          #echo "$_storage_class - ${storage_classes[$_storage_class]}"
          if [[ $first -eq 0 ]]; then
            tmp="${tmp},"
          fi
          tmp="${tmp}\"${_storage_class}\""
          first=0
        done
      fi
      # node longhorn storage tags
      run "line '$LINENO';kubectl annotate --overwrite nodes $node_name node.longhorn.io/default-node-tags='[\"storage\",$tmp]'"

      # node longhorn disk config
      run "line '$LINENO';kubectl annotate --overwrite nodes $node_name node.longhorn.io/default-disks-config='[$tmp2]'"
      node_disk_config["${node_name}"]="${tmp2}"
      # kubectl patch node k8s-worker-1 --type merge --patch-file /home/bino/k0s-sriwijaya/longhorn/lhpatch.yaml
    ;;
    * )
      err_and_exit "Expected parameters: 1 - mount, 2 - generate yaml" ${LINENO};
  esac
}

longhorn-install() {
  hl.blue "$parent_step$((++install_step)). Longhorn installation. (Line:$LINENO)"
  if ! [[ -e ${cluster_plan_file} ]]; then
    err_and_exit "Cluster plan file '${cluster_plan_file}' is not found" ${LINENO};
  fi

  if command kubectl get deploy longhorn-ui -n longhorn-system &> /dev/null; then
    err_and_exit "Longhorn already installed."  ${LINENO} "$0"
  fi

  longhorn_ui_admin_name=$(vlib.secret-get-text $longhorn_ui_admin_name_secret_file_path $longhorn_ui_admin_name_secret_pass_path)
  longhorn_ui_admin_password=$(vlib.secret-get-text $longhorn_ui_admin_password_secret_file_path $longhorn_ui_admin_password_secret_pass_path)

  declare -A node_disk_config

  readarray nodes < <(yq -o=j -I=0 '.node[]' < $cluster_plan_file)
  i_node=0
  for node in "${nodes[@]}"; do
    eval "$( yq '.[] | ( select(kind == "scalar") | key + "='\''" + . + "'\''")' <<<$node)"
    readarray disks < <(yq -o=j -I=0 ".node[$i_node].node_storage[]" < $cluster_plan_file)
    vlib.trace "disk amount=${#disks[@]}"
    if [[ ${#disks[@]} -gt 0 ]]; then
      node_root_password=$(vkube-k3s.get-node-admin-password)
      node_disks 1
      node_disks 2
    fi
    ((i_node++))
    if [ $i_node -eq $amount_nodes ]; then break; fi
  done

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

  # https://longhorn.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-the-longhorn-deployment-yaml-file

  run "line '$LINENO';wget -O ~/tmp/longhorn.yaml https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/deploy/longhorn.yaml"
  # https://longhorn.io/docs/1.7.2/advanced-resources/deploy/customizing-default-settings/#using-kubectl
  # https://github.com/longhorn/longhorn/blob/master/chart/templates/default-setting.yaml
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    create-default-disk-labeled-nodes: true/' ~/tmp/longhorn.yaml"
  run "line '$LINENO';sed -i 's/default-setting.yaml: |-/default-setting.yaml: |-\n    deleting-confirmation-flag: true/' ~/tmp/longhorn.yaml"
  run "line '$LINENO';kubectl apply -f ~/tmp/longhorn.yaml"

  #run "line "$LINENO";kubectl create -f ./101-longhorn/backup.yaml"

  # https://fabianlee.org/2022/01/27/kubernetes-using-kubectl-to-wait-for-condition-of-pods-deployments-services/

  # https://kubernetes.io/docs/reference/kubectl/generated/kubectl_wait/
  # https://kubernetes.io/docs/reference/kubectl/jsonpath/
  # https://stackoverflow.com/questions/53536907/kubectl-wait-for-condition-complete-timeout-30s
  run "line '$LINENO';vlib.wait-for-success -t 600 'kubectl get deployment longhorn-driver-deployer -n longhorn-system'"
  #run "line '$LINENO';sleep 120"
  run "line '$LINENO';kubectl wait --for=condition=Available deployment/longhorn-driver-deployer -n longhorn-system --timeout=30m"
  run "line '$LINENO';sleep 200"
  run "line '$LINENO';kubectl wait --for=condition=Available deployment/csi-attacher -n longhorn-system --timeout=30m"
  run "line '$LINENO';kubectl wait --for=condition=Available deployment/csi-provisioner -n longhorn-system --timeout=30m"
  run "line '$LINENO';kubectl wait --for=condition=Available deployment/csi-resizer -n longhorn-system --timeout=30m"
  run "line '$LINENO';kubectl wait --for=condition=Available deployment/csi-snapshotter -n longhorn-system --timeout=30m"

  #run "helm upgrade longhorn longhorn/longhorn --namespace longhorn-system --values ./values.yaml --version $longhorn_ver"

  if ! test -e ~/downloads; then mkdir ~/downloads; fi
  run "line '$LINENO';curl https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/examples/storageclass.yaml -o ~/downloads/storageclass.yaml"
  # ssd storage class
  run "line '$LINENO';yq -i '
    .metadata.name = \"longhorn-ssd\" |
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
    .metadata.name = \"longhorn-nvme\" |
    .parameters.numberOfReplicas = \"3\" |
    .parameters.staleReplicaTimeout = \"2880\" |
    .parameters.fsType = \"ext4\" |
    .parameters.mkfsParams = \"-I 256 -b 4096 -O ^metadata_csum,^64bit\" |
    .parameters.diskSelector = \"nvme\" |
    .parameters.nodeSelector = \"storage,nvme\"
  ' ~/downloads/storageclass.yaml"
  run "line '$LINENO';kubectl create -f ~/downloads/storageclass.yaml"

  hl.blue "$parent_step$((++install_step)). Longhorn UI. (Line:$LINENO)"
  # Longhorn UI
  # https://github.com/longhorn/website/blob/master/content/docs/1.8.1/deploy/accessing-the-ui/longhorn-ingress.md
  # # https://kubernetes.github.io/ingress-nginx/examples/auth/basic/
  # htpasswd -c ${HOME}/tmp/auth $longhorn_ui_admin_name
  # run "line '$LINENO';echo \"${longhorn_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${longhorn_ui_admin_password})\" > ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n longhorn-system create secret generic basic-auth --from-file=${HOME}/tmp/auth"
  # run "line '$LINENO';rm ${HOME}/tmp/auth"
  # run "line '$LINENO';kubectl -n longhorn-system apply -f ./101-longhorn/longhorn-ui-auth-basic.yaml"

  # https://longhorn.io/docs/1.7.3/deploy/accessing-the-ui/longhorn-ingress/
  run "line '$LINENO';echo \"${longhorn_ui_admin_name}:$(openssl passwd -stdin -apr1 <<< ${longhorn_ui_admin_password})\" > ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n longhorn-system create secret generic longhorn-ui-auth-basic --from-file=${HOME}/tmp/auth"
  #run "line '$LINENO';vkube-k3s.secret-create longhorn-system longhorn-ui-auth-basic ${HOME}/tmp/auth"
  run "line '$LINENO';rm ${HOME}/tmp/auth"
  run "line '$LINENO';kubectl -n longhorn-system apply -f ./101-longhorn/longhorn-ui-auth-basic.yaml"

  run "line '$LINENO';kubectl expose deployment longhorn-ui --port=80 --type=LoadBalancer --name=longhorn-ui -n longhorn-system --target-port=http --load-balancer-ip=192.168.100.101"
  # kubectl expose deployment longhorn-ui --port=80 --type=LoadBalancer --name=longhorn-ui -n longhorn-system --target-port=http --load-balancer-ip=192.168.100.101
  # kubectl -n longhorn-system get svc
  # kubectl  -n longhorn-system describe svc longhorn-ui
  # kubectl delete service longhorn-ui -n longhorn-system

  kubectl get nodes
  kubectl get svc -n longhorn-system
  echo "Longhorn UI: check all disks on all nodes are available and schedulable !!!"

  #kubectl apply -f ./101-longhorn/test-pod-with-pvc.yaml

  # Tests
  # kubectl -n longhorn-system get replicas --output=jsonpath="{.items[?(@.status.volumeName==\"<THE VOLUME NAME YOU ARE CHECKING>\")].metadata.name}"
  # kubectl -n longhorn-system edit replicas
  # kubectl get volumes.longhorn.io pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c -o yaml -n longhorn-system
  # kubectl get replicas.longhorn.io -n longhorn-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.longhorn.io -n longhorn-system -o yaml
  # kubectl get engines.longhorn.io -n longhorn-system | grep pvc-3cc715b2-aaa2-4c1d-a788-ffc71905874c
  # kubectl get replicas.longhorn.io -n longhorn-system -o yaml
  # Volumes ????

}
longhorn-uninstall()
{
  hl.blue "$parent_step$((++install_step)). Uninstalling Longhorn. (Line:$LINENO)"

  if ! command kubectl get deploy longhorn-ui -n longhorn-system &> /dev/null; then
    err_and_exit "Longhorn not installed yet."  ${LINENO} "$0"
  fi

  if ! command kubectl get deploy -l app.kubernetes.io/version=$longhorn_ver -n longhorn-system &> /dev/null; then
    err_and_exit "Trying uninstall Longhorn version '$longhorn_ver', but this version is not installed."  ${LINENO} "$0"
  fi

  # manually deleting stucked-namespace
  #kubectl get namespace "longhorn-system" -o json | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" | kubectl replace --raw /api/v1/namespaces/longhorn-system/finalize -f -
  #kubectl get namespace "stucked-namespace" -o json \
  #  | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/" \
  #  | kubectl replace --raw /api/v1/namespaces/stucked-namespace/finalize -f -

  # longhorn deleting-confirmation-flag
  # kubectl get lhs -n longhorn-system
  # can be edit in k9s or apply deleting-confirmation-flag.yaml
  local dir="$(dirname "$0")"
  #run "line $LINENO;kubectl -n longhorn-system patch -p '{\"value\": \"true\"}' --type=merge lhs deleting-confirmation-flag"
  #run "line $LINENO;helm uninstall longhorn -n longhorn-system"
  #run "line $LINENO;kubectl apply -f ./101-longhorn/deleting-confirmation-flag.yaml"

  run "line $LINENO;kubectl create -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/uninstall/uninstall.yaml"
  #kubectl get job/longhorn-uninstall -n longhorn-system -w

  # https://medium.com/@sirtcp/how-to-resolve-stuck-kubernetes-namespace-deletions-by-cleaning-finalizers-38190bf3165f
  # Get all resorces
  #kubectl api-resources
  # Get all resorces for namespace
  #kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get --show-kind --ignore-not-found -n longhorn-system

  run "line '$LINENO';kubectl wait --for=condition=complete job/longhorn-uninstall -n longhorn-system --timeout=5m"

  run "line '$LINENO';kubectl delete namespace longhorn-system"
  run "line '$LINENO';kubectl delete storageclass longhorn-ssd"
  run "line '$LINENO';kubectl delete storageclass longhorn-nvme"

exit

  local wait_time=0
  local wait_period=10
  local wait_timeout=300
  until kubectl get job/longhorn-uninstall -n longhorn-system -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' | grep True > /dev/null; 
  do 
    sleep $wait_period
    ((wait_time+=wait_period))
    if [[ $wait_time -gt $wait_timeout ]]; then
      err_and_exit "Timeout. Wait time $wait_time sec"  ${LINENO} "$0"
    fi
  done
  run "line '$LINENO';kubectl delete deployment longhorn-ui -n longhorn-system"
  run "line '$LINENO';kubectl delete -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/uninstall/uninstall.yaml"

  local wait_time=0
  local wait_period=30
  local wait_timeout=600
  until ! command -v kubectl get pod -o json -n longhorn-system | jq '.items | length' &> /dev/null;  
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
  #run "line '$LINENO';kubectl -n longhorn-system delete crd nodes"

  run "line '$LINENO';kubectl delete namespace longhorn-system"
}
longhorn-upgrade()
{
  longhorn-backup

  run "line '$LINENO';kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/$longhorn_ver/deploy/longhorn.yaml"
  run "line '$LINENO';vlib.wait-for-success 'kubectl rollout status deployment longhorn-driver-deployer -n longhorn-system'"
  run "line '$LINENO';kubectl wait --for=condition=ready pod -l app=instance-manager -n longhorn-system --timeout=5m"

  # if timeout when upgrade
  longhorn-restore
}
longhorn-backup()
{
  # https://longhorn.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://longhorn.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/create-a-backup-via-csi/
  echo kuku
}
longhorn-restore()
{
  # https://longhorn.io/docs/archives/1.2.4/concepts/#31-how-backups-work
  # https://longhorn.io/docs/archives/1.2.4/snapshots-and-backups/csi-snapshot-support/restore-a-backup-via-csi/#restore-a-backup-that-has-no-associated-volumesnapshot
  echo kuku
}
check-longhorn-exclusive-params()
{
  if [[ longhorn_number_exclusive_params -gt 0 ]]; then
    err_and_exit "Only one exclusive operation is allowed"  ${LINENO} "$0"
  fi
}
#endregion

function install-storage() {
  hl.blue "$((++install_step)). Install general the csi storage drivers. (Line:$LINENO)"
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

  if [ -n "$local_storage_use" ] && [ "$local_storage_use" -eq 1 ]; then
    inf "local (Line:$LINENO)\n"
    #region local storage
    run "line '$LINENO';kubectl apply -f - <<<\"apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner # indicates that this StorageClass does not support automatic provisioning
volumeBindingMode: WaitForFirstConsumer\""
    #endregion local storage
  fi
  if [ -n "$csi_driver_nfs_use" ] && [ "$csi_driver_nfs_use" -eq 1 ]; then
    inf "csi-driver-nfs (Line:$LINENO)\n"
    # https://github.com/kubernetes-csi/csi-driver-nfs
    # https://rudimartinsen.com/2024/01/09/nfs-csi-driver-kubernetes/
    # https://microk8s.io/docs/how-to-nfs
    run vlib.check-github-release-version 'csi_driver_nfs' https://api.github.com/repos/kubernetes-csi/csi-driver-nfs/releases 'csi_driver_nfs_ver'
    #echo ${csi_driver_nfs_ver:1}
    if [[ $(kubectl get pods -lapp=csi-nfs-controller,app.kubernetes.io/version=${csi_driver_nfs_ver:1} -n ${csi_driver_nfs_namespace} > /dev/null 2> /dev/null | wc -l) -eq 0 ]]; then
      run "line '$LINENO';vkube-k3s.namespace-create-if-not-exist $csi_driver_nfs_namespace"
      # eval "csi_driver_nfs_secret_folder=$csi_driver_nfs_secret_folder"
      # run "line '$LINENO';vkube-k3s.check-data-dir-for-secrets '$csi_driver_nfs_secret_folder'"
      run "line '$LINENO';helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts"
      vlib.trace "csi_driver_nfs_ver=$csi_driver_nfs_ver"
      run "line '$LINENO';helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs -n ${csi_driver_nfs_namespace} --version $csi_driver_nfs_ver"
      # kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/name=csi-driver-nfs" --watch
    else
      inf "... already installed. (Line:$LINENO)\n"
    fi
  fi
  if [ -n "$csi_driver_smb_use" ] && [ "$csi_driver_smb_use" -eq 1 ]; then
    inf "csi-driver-smb (Line:$LINENO)\n"
    # https://github.com/kubernetes-csi/csi-driver-smb/blob/master/deploy/example/e2e_usage.md
    # https://rguske.github.io/post/using-windows-smb-shares-in-kubernetes/
    # https://docs.aws.amazon.com/filegateway/latest/files3/use-smb-csi.html
    run vlib.check-github-release-version 'csi_driver_smb' https://api.github.com/repos/kubernetes-csi/csi-driver-smb/releases 'csi_driver_smb_ver'
    #echo $csi_driver_smb_ver
    if [[ $(kubectl get pods -lapp=csi-smb-controller,app.kubernetes.io/version=${csi_driver_smb_ver:1} -n ${csi_driver_smb_namespace} > /dev/null 2> /dev/null | wc -l) -eq 0 ]]; then
      run "line '$LINENO';vkube-k3s.namespace-create-if-not-exist $csi_driver_smb_namespace"
      #       if [[ -n $csi_driver_smb_secret_folder ]]; then
      #         eval "csi_driver_smb_secret_folder=$csi_driver_smb_secret_folder"
      #         vkube-k3s.vkube-k3s.check-dir-data-for-secrets "$csi_driver_smb_secret_folder"
      #         run "line '$LINENO';kubectl create secret generic smb-csi-creds -n ${csi_driver_smb_namespace} --from-file=$csi_driver_smb_secret_folder"
      #       elif [[ -n $csi_driver_smb_secret_pass_folder ]]; then
      #         vkube-k3s.secret-create-from-pass-folder "$csi_driver_smb_secret_folder"
      #       else
      #         err_and_exit "Both 'csi_driver_smb_secret_folder' and 'csi_driver_smb_secret_pass_folder' are empty in cluster plan '$cluster_plan_file'"
      #       fi
      run "line '$LINENO';helm repo add csi-driver-smb https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts"
      run "line '$LINENO';helm install csi-driver-smb csi-driver-smb/csi-driver-smb -n ${csi_driver_smb_namespace} --version $csi_driver_smb_ver"
      # kubectl --namespace=kube-system get pods --selector="app.kubernetes.io/name=csi-driver-smb" --watch
      # https://kubernetes.io/docs/concepts/configuration/secret/
      # https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/
      # https://medium.com/@ravipatel.it/mastering-kubernetes-secrets-a-comprehensive-guide-b0304818e32b
      # run "line '$LINENO';if ! test -e $csi_driver_smb_secret_folder; then  mkdir $csi_driver_smb_secret_folder; fi"
      # if kubectl get secret -n $csi_synology_namespace smb-csi-creds > /dev/null ; then
      #   run "line '$LINENO';kubectl delete secret -n $csi_synology_namespace smb-csi-creds"
      # fi
      # run "line '$LINENO';kubectl create secret generic smb-csi-creds -n ${csi_driver_smb_namespace} --from-file=$csi_driver_smb_secret_folder"
    else
      inf "... already installed. (Line:$LINENO)\n"
    fi
    # kubectl -n kube-system get secret smb-csi-creds -o jsonpath='{.data}'
    # kubectl -n kube-system get secret smb-csi-creds -o jsonpath='{.data.username}' | base64 --decode
    # kubectl -n kube-system get secret smb-csi-creds -o jsonpath='{.data.password}' | base64 --decode
    # kubectl -n kube-system edit secrets smb-csi-creds
    # kubectl delete secret smb-csi-creds -n kube-system
  fi
  if [ -n "$csi_synology_use" ] && [ "$csi_synology_use" -eq 1 ]; then
    vkube-k3s.csi-synology-install
  fi
  if [ -n "$nfs_subdir_external_provisioner_use" ] && [ "$nfs_subdir_external_provisioner_use" -eq 1 ]; then
    inf "nfs-subdir-external-provisioner (Line:$LINENO)\n"
    run vlib.check-github-release-version 'nfs_subdir_external_provisioner' https://api.github.com/repos/kubernetes-sigs/nfs-subdir-external-provisioner/releases 'nfs_subdir_external_provisioner_ver'
    #echo $nfs_subdir_external_provisioner_ver
    #if [[ $(kubectl get pods -lapp=csi-smb-controller,app.kubernetes.io/version=$nfs_subdir_external_provisioner_ver -n kube-system > /dev/null 2> /dev/null | wc -l) -eq 0 ]]; then
    if [[ $(kubectl get pods -lapp=nfs-subdir-external-provisioner -n kube-system > /dev/null 2> /dev/null | wc -l) -eq 0 ]]; then
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
  
  hl.blue "$((++install_step)). Generate storage classes for general csi drivers. (Line:$LINENO)"
  # GENERATED STORAGE CLASSES AND INSTALL PROPER DRIVERS
  local txt=""
  local separator=""
  local storage_class=""
  local secret_folder_name=""
  local secret_name=""

  #vlib.trace "default reclaimPolicy=$csi_synology_host_protocol_class_reclaimPolicy"
  declare -A host_names_dic=()
  #declare -A folder_cred_dic=()
  readarray storage_servers < <(yq -o=j -I=0 '.storage_servers[]' < $cluster_plan_file)
  vlib.trace "storage servers count=${#storage_servers[@]}"
  for storage_server in "${storage_servers[@]}"; do
    # Host level scalar settings
    eval "$( yq '.[] | ( select(kind == "scalar") | "storage_server_" + key + "='\''" + . + "'\''")' <<<$storage_server)"
    vlib.trace "storage server name=$storage_server_name"
    if [[ -z $storage_server_name ]]; then
      err_and_exit "Empty host name. Configuration YAML file: '${cluster_plan_file}'." ${LINENO}
    fi
    if [[ -v host_names_dic["${storage_server_name}"] ]]; then
      vlib.trace "host names(${#host_names_dic[@]})=" "${!host_names_dic[@]}"
      err_and_exit "Host name is not unique. Configuration YAML file: '${cluster_plan_file}'. Host name '$storage_server_name'." ${LINENO}
    fi
    host_names_dic["${storage_server_name}"]='y'
    readarray storage_server_protocols < <(echo $storage_server | yq -o=j -I=0 ".protocols[]")
    vlib.trace "storage protocols count=${#storage_server_protocols[@]}"
    if [[ ${#storage_server_protocols[@]} -eq 0 ]]; then
      err_and_exit "There are no storage protocol for host. Configuration YAML file: '${cluster_plan_file}'. Host '$storage_server_name'." ${LINENO}
    fi
    i_protocol=-1
    #vlib.trace "reclaimPolicy=$storage_server_protocol_class_reclaimPolicy"
    declare -A protocol_names=()
    #echo "storage_server_name=$storage_server_name"  >&3
    for storage_server_protocol in "${storage_server_protocols[@]}"; do
      i_protocol+=1
      vlib.trace "storage protocol=$storage_server_protocol"
      eval "$( yq '.[] | ( select(kind == "scalar") | "storage_server_" + key + "='\''" + . + "'\''")' <<<$storage_server)"
      eval "$( yq '.[] | ( select(kind == "scalar") | "storage_server_protocol_" + key + "='\''" + . + "'\''")' <<<$storage_server_protocol)"
      vlib.trace "storage protocol name=$storage_server_protocol_name"
      if [[ -z $storage_server_protocol_name ]]; then
        err_and_exit "Empty protocol name. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'." ${LINENO}
      fi
      if [[ -v protocol_names["${storage_server_protocol_name}"] ]]; then
        #echo "${!protocol_names[@]}" "${protocol_names[@]}"
        vlib.trace "protocol names(${#protocol_names[@]})=" "${!protocol_names[@]}"
        #vlib.trace "storage host=$storage_server"
        #vlib.trace "storage protocol=$storage_server_protocol"
        err_and_exit "Storage protocol name is not unique. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol name '$storage_server_protocol_name'." ${LINENO}
      fi
      protocol_names["${storage_server_protocol_name}"]='y'
      readarray storage_server_protocol_classes < <(echo $storage_server_protocol | yq -o=j -I=0 ".classes[]")
      vlib.trace "storage classes count=${#storage_server_protocol_classes[@]}"
      if [[ ${#storage_server_protocol_classes[@]} -eq 0 ]]; then
        err_and_exit "There are no storage class for protocol. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'." ${LINENO}
      fi
      #vlib.trace "reclaimPolicy=$storage_server_protocol_class_reclaimPolicy"
      for storage_server_protocol_class in "${storage_server_protocol_classes[@]}"; do
        vlib.trace "storage class=$storage_server_protocol_class"
        eval "$( yq '.[] | ( select(kind == "scalar") | "storage_server_" + key + "='\''" + . + "'\''")' <<<$storage_server)"
        eval "$( yq '.[] | ( select(kind == "scalar") | "storage_server_protocol_" + key + "='\''" + . + "'\''")' <<<$storage_server_protocol)"
        eval "$( yq '.[] | ( select(kind == "scalar") | "storage_server_protocol_class_" + key + "='\''" + . + "'\''")' <<<$storage_server_protocol_class)"
        vlib.trace "storage class name=$storage_server_protocol_class_name"
        #vlib.trace "reclaimPolicy=$storage_server_protocol_class_reclaimPolicy"
        if [[ -z $storage_server_protocol_secret_folder && -z $storage_server_protocol_secret_pass_folder ]]; then
          err_and_exit "Both 'secret_folder' and 'secret_pass_folder' are empty. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        fi
        if [[ -n $storage_server_protocol_secret_folder && -n $storage_server_protocol_secret_pass_folder ]]; then
          err_and_exit "Both 'secret_folder' and 'secret_pass_folder' are not empty. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        fi
        if [[ -z $storage_server_protocol_class_location ]]; then
          err_and_exit "Empty location. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        fi
        if [[ -z $storage_server_protocol_class_reclaimPolicy ]]; then
          err_and_exit "Empty reclaimPolicy. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        fi
        if [[ -z $storage_server_protocol_class_allowVolumeExpansion ]]; then
          err_and_exit "Empty allowVolumeExpansion. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        fi
        # if [[ -z $storage_server_protocol_class_mountPermissions ]]; then
        #   err_and_exit "Empty mountPermissions. Configuration YAML file: '${cluster_plan_file}'. Storage server '$storage_server_name'. Protocol '$storage_server_protocol_name'. Storage class '$storage_server_protocol_class_name'." ${LINENO}
        # fi
        
        # if ! [[ -v folder_cred_dic["${secret_folder_name}"] ]]; then
        #     vlib.trace "secret_folder_name=$secret_folder_name"
        #     if kubectl get secret -n $csi_synology_namespace $secret_folder_name > /dev/null ; then
        #       run "line '$LINENO';kubectl delete secret -n $csi_synology_namespace $secret_folder_name"
        #     fi
        #     # https://www.baeldung.com/ops/kubernetes-namespaces-common-secrets
        #     run "line '$LINENO';kubectl create secret generic $secret_folder_name -n $csi_synology_namespace --from-file=$storage_server_protocol_secret_folder"
        #   folder_cred_dic["${secret_folder_name}"]='y'
        # fi
        
        #echo "  storage_server_protocol_name=$storage_server_protocol_name"  >&3
        case $storage_server_protocol_name in
          csi-driver-nfs )
            #echo "      csi-driver-nfs use=$csi_driver_nfs_use"  >&3
            if [ -n "$csi_driver_nfs_use" ] && [ "$csi_driver_nfs_use" -eq 1 ]; then
              secret_name="storage-${storage_server_name}-csi-driver-nfs"
              run vkube-k3s.secret-create "$csi_driver_nfs_namespace" "$secret_name" "$storage_server_protocol_secret_folder" "$storage_server_protocol_secret_pass_folder"

              # run "line '$LINENO';kubectl delete secret -n $csi_driver_nfs_namespace $secret_folder_name --ignore-not-found=true"
              # # https://www.baeldung.com/ops/kubernetes-namespaces-common-secrets
              # if [[ -z $storage_server_protocol_secret_folder ]]; then
              #   secret_folder_name=$(basename "$storage_server_protocol_secret_folder")
              #   run "line '$LINENO';vkube-k3s.secret-create-from-folder $csi_driver_nfs_namespace $secret_folder_name $storage_server_protocol_secret_folder"
              # elif [[ -z $storage_server_protocol_secret_pass_folder ]]; then
              #   run "line '$LINENO';vkube-k3s.secret-create-from-pass $csi_driver_nfs_namespace $storage_server_protocol_secret_pass_folder $storage_server_protocol_secret_pass_folder"
              # fi
              #run "line '$LINENO';kubectl create secret generic $secret_folder_name -n csi-nfs --from-file=$storage_server_protocol_secret_folder"
              #run "line '$LINENO';vkube-k3s.secret-create csi-nfs $secret_folder_name $storage_server_protocol_secret_folder"

              storage_class="$storage_server_name-csi-driver-nfs-$storage_server_protocol_class_name"
              #echo "        storage_class=$storage_class"  >&3
              [[ -z $storage_class ]] && err_and_exit "Storage class name is empty. Cluster plan: '$cluster_plan_file'. Storage server: '$storage_server_name'. Protocol name: '$storage_server_protocol_name'"
              #region
              txt+="${separator}apiVersion: storage.k8s.io/v1 # line:${LINENO}
kind: StorageClass
metadata:
  name: $storage_class
  labels:
    vkube/storage-type: csi-driver-nfs
provisioner: nfs.csi.k8s.io
parameters: # https://github.com/kubernetes-csi/csi-driver-nfs
"
              if [[ -n "$storage_server_ip4" ]]; then
                txt+="  server: $storage_server_ip4"
              else
                txt+="  server: $storage_server_name"
              fi
              txt+="
  share: \"$storage_server_protocol_class_location\"
  # csi.storage.k8s.io/provisioner-secret is only needed for providing mountOptions in DeleteVolume
  # csi.storage.k8s.io/provisioner-secret-name: \"mount-options\"
  # csi.storage.k8s.io/provisioner-secret-namespace: \"default\"
  # ??? mountPermissions: \"$storage_server_protocol_class_mountPermissions\"
reclaimPolicy: $storage_server_protocol_class_reclaimPolicy
volumeBindingMode: Immediate
#allowVolumeExpansion: $storage_server_protocol_class_allowVolumeExpansion
mountOptions:
  - hard
  - nfsvers=$storage_server_protocol_class_mountOptions_nfsvers
"
              #endregion
              vlib.trace "storage_server_protocol_class_location=$storage_server_protocol_class_location"
            else
              continue
            fi
          ;;
          csi-driver-smb )
            #echo "      csi-driver-smb use=$csi_driver_smb_use"  >&3
            if [ -n "$csi_driver_smb_use" ] && [ "$csi_driver_smb_use" -eq 1 ]; then
              vlib.trace "secret_folder_name=$secret_folder_name"
              vlib.trace "storage_server_protocol_class_smb_vers=$storage_server_protocol_class_smb_vers"
              secret_name="storage-${storage_server_name}-csi-driver-smb"
              run vkube-k3s.secret-create "$csi_driver_smb_namespace" "$secret_name" "$storage_server_protocol_secret_folder" "$storage_server_protocol_secret_pass_folder"

              # run "line '$LINENO';kubectl delete secret -n $csi_driver_smb_namespace $secret_folder_name --ignore-not-found=true"
              # # https://www.baeldung.com/ops/kubernetes-namespaces-common-secrets
              # if [[ -z $storage_server_protocol_secret_folder ]]; then
              #   secret_folder_name=$(basename "$storage_server_protocol_secret_folder")
              #   run "line '$LINENO';vkube-k3s.secret-create-from-folder $csi_driver_smb_namespace $secret_folder_name $storage_server_protocol_secret_folder"
              # elif [[ -z $storage_server_protocol_secret_pass_folder ]]; then
              #   run "line '$LINENO';vkube-k3s.secret-create-from-pass $csi_driver_smb_namespace $storage_server_protocol_secret_pass_folder $storage_server_protocol_secret_pass_folder"
              # fi

              storage_class="$storage_server_name-csi-driver-smb-$storage_server_protocol_class_name"
              #echo "        storage_class=$storage_class"  >&3
              [[ -z $storage_class ]] && err_and_exit "Storage class name is empty. Cluster plan: '$cluster_plan_file'. Storage server: '$storage_server_name'. Protocol name: '$storage_server_protocol_name'"
              #region
              txt+="${separator}apiVersion: storage.k8s.io/v1 # line:${LINENO}
kind: StorageClass
metadata:
  name: $storage_class
  labels:
    vkube/storage-type: csi-driver-smb
provisioner: smb.csi.k8s.io # https://github.com/kubernetes-csi/csi-driver-smb/blob/master/docs/csi-debug.md
parameters: # https://github.com/kubernetes-csi/csi-driver-smb/blob/master/docs/driver-parameters.md
  source: //$storage_server_name$storage_server_protocol_class_location
  # source: //smb-server.default.svc.cluster.local/share
  # if csi.storage.k8s.io/provisioner-secret is provided, will create a sub directory
  # with PV name under source
  csi.storage.k8s.io/provisioner-secret-name: $secret_name
  csi.storage.k8s.io/provisioner-secret-namespace: $csi_driver_smb_namespace
  csi.storage.k8s.io/node-stage-secret-name: $secret_name
  csi.storage.k8s.io/node-stage-secret-namespace: $csi_driver_smb_namespace
reclaimPolicy: $storage_server_protocol_class_reclaimPolicy
volumeBindingMode: Immediate
allowVolumeExpansion: $storage_server_protocol_class_allowVolumeExpansion
mountOptions: # https://linux.die.net/man/8/mount.cifs
# https://www.filecloud.com/supportdocs/fcdoc/latest/server/filecloud-administrator-guide/installing-filecloud-server/mounting-cifs-and-nfs-shares/mount-a-cifs-share-on-ubuntu-for-filecloud
  - dir_mode=0777
  - file_mode=0777
  - uid=1001
  - gid=1001"
              if [[ -n "$storage_server_ip4" ]]; then
                txt+="
  - ip=$storage_server_ip4"
              fi
              if [[ -n "$storage_server_protocol_class_smb_vers" ]]; then
                txt+="
  - vers=$storage_server_protocol_class_smb_vers"
              fi
              txt+="
  - noperm
  - mfsymlinks
  - cache=strict
  - noserverino  # required to prevent data corruption
"
              #endregion
            else
              continue
            fi
          ;;
          * )
            echo "      unknown"  >&3
            err_and_exit "Unsupported storage protocol '$name'. Expected: csi-driver-smb or csi-driver-nfs" ${LINENO};
        esac
        #region
        separator="---
"
        #endregion
        [[ -z $storage_class ]] && err_and_exit "Storage class name is empty. Cluster plan: '$cluster_plan_file'. Storage server: '$storage_server_name'. Protocol name: '$storage_server_protocol_name'"
        run "line '$LINENO';kubectl delete storageclass $storage_class --wait --ignore-not-found=true"
      done
    done
  done
  #set +x
  #echo "txt=$txt"  >&3
  if [[ ${#txt} -gt 0 ]]; then
    #vlib.trace "generated storage classes=\n$txt"
    run "line '$LINENO';echo '$txt' > '$vkube_data_folder/generated-csi-driver-nfs-smb-storage-classes.yaml'"
    #run "line '$LINENO';kubectl apply edit-last-applied -f '$vkube_data_folder/generated-storage-classes.yaml'"
    run "line '$LINENO';kubectl apply -f '$vkube_data_folder/generated-csi-driver-nfs-smb-storage-classes.yaml'"
  fi
  #run "line '$LINENO';kubectl apply -f $VBASH/../k3s/storage-classes.yaml"
  case $kubernetes_type in
    k3s )
      if [ -n "$longhorn_use" ] && [ "$longhorn_use" -eq 1 ]; then
        longhorn-install
      fi
    ;;
    k3d )
      if [ -n "$longhorn_use" ] && [ "$longhorn_use" -eq 1 ]; then
        longhorn-install
      fi
    ;;
    * )
    ;;
  esac
}
function vkube-k3s.-internal-storage-speed-test() {
  # $1 - storage driver
  local storage_class="$1"
  #vlib.h1 "Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce"
  vlib.h2  "Deleting previous speed test job for storage class '$storage_class'..."
  kubectl delete job '${storage}-write-read' -n storage-speedtest --ignore-not-found=true
  kubectl delete pvc '${storage}-test-pvc' -n storage-speedtest --ignore-not-found=true
  sleep 5
  #vlib.wait-for-error -p 5 -t 300 "kubectl get job ${storage_class}-write-read -n storage-speedtest"
  vlib.h2  "Creating speed test job for storage class '$storage_class'..."
  vkube-k3s.storage-speedtest-job-create storage-speedtest $storage_class ReadWriteOnce
  sleep 15
  #vlib.wait-for-success -p 10 -t 200 "kubectl get job ${storage_class}-write-read -n storage-speedtest"
  # https://stackoverflow.com/questions/55073453/wait-for-kubernetes-job-to-complete-on-either-failure-success-using-command-line
  #run "line '$LINENO';kubectl --timeout=600s wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!"
  vlib.h2  "Waiting job completition..."
  kubectl --timeout=600s wait --for=condition=Completed job/${storage_class}-write-read -n storage-speedtest & completion_pid=$!
  vlib.echo -b --fg=green "$(kubectl -n storage-speedtest logs -l app=$storage_class-storage-speedtest,job=write-read)"
}
function vkube-k3s.storage-speed-test {
  #hl.blue "$((++install_step)). Storage class speed test. (Line:$LINENO)"
  vkube-k3s.-internal-storage-speed-test "${args[--storage-class]}"
}
function vkube-k3s.command-init() {
  vkube-k3s.check-cluster-plan-path

  vkube-k3s.cluster-plan-read
}