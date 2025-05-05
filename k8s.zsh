# https://gist.github.com/rothgar/a2092f73b06465ddda0e855cc1f6ec2b

ealias kg='k get '
ealias kgp='k get po '
ealias kgn='k get no '
ealias kgd='k get deploy '
ealias krmp='k delete po '
ealias kdp='k describe po '
ealias uek='unset KUBECONFIG'
ealias uekns='unset KUBE_NAMESPACE'

# export kubeconfig
ek() {
    if [ -n "$1" ]; then
        CONFIG=$(rg --max-depth 3 -l '^kind: Config$' $HOME/.kube/ 2>/dev/null \
            | grep $1)
    else
        CONFIG=$(rg --max-depth 3 -l '^kind: Config$' $HOME/.kube/ $PWD 2>/dev/null | fzf --multi | tr '\n' ':')
    fi
    # echo file and remove trailing :
    echo ${CONFIG%:*}
    export KUBECONFIG=${CONFIG%:*}
    PROFILE=$(yq '.users[0].user.exec.env[0].value' $KUBECONFIG)
    REGION=$(yq '.users[0].user.exec.args' $KUBECONFIG | grep -A1 region | tail -1 | awk '{print $2}')
    awsp $PROFILE $REGION
}
 
# delete kubeconfig files that don't connect to a kubernetes cluster
clean-k() {
    export FILES=($(rg --max-depth 3 -l '^kind: Config$' $HOME/.kube/ $PWD ))
    for FILE in ${FILES[@]}; do
      echo "Checking $FILE"
      if [ $(timeout 3 kubectl cluster-info --kubeconfig=${FILE} 2> /dev/null ) ]; then
        echo "Removing $FILE"
        rm -f ${FILE}
      else
        echo "Skipping $FILE"
      fi
    done
}

# main k function
fn k() {
  if [ -n "$KUBE_NAMESPACE" ]; then
      kubectl --namespace "$KUBE_NAMESPACE" $@
  else
      kubectl $@
  fi
}
 
# helper for setting a namespace
# List namespaces, preview the pods within, and save as variable
function ekns() {
  namespaces=$(kubectl get ns -o=custom-columns=:.metadata.name)
  export KUBE_NAMESPACE=$(echo $namespaces | fzf --select-1 --preview "kubectl --namespace {} get pods")
  echo "Set namespace to $KUBE_NAMESPACE"
}
