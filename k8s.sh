# https://gist.github.com/rothgar/a2092f73b06465ddda0e855cc1f6ec2b

alias my='k8s.sh '

alias kg='k get '
alias kgp='k get po '
alias kgn='k get no '
alias kgd='k get deploy '
alias krmp='k delete po '
alias kdp='k describe po '
alias uek='unset KUBECONFIG'
alias uekns='unset KUBE_NAMESPACE'

# wait-for-success()
# {
#   # https://earthly.dev/blog/jq-select/
#   # https://www.baeldung.com/linux/bash-execute-variable-command

#   local wait_timeout=100
#   local wait_check_period=10
#   local wait_error=0
#   local wait_success=0

#   usage="Usage: wait-for-success [OPTION] <bash command>
#   Options:
#     -t timeout # Wait up to 'timeout' seconds. Default timeout $wait_timeout seconds.
#     -p period # Check period in seconds while waiting. Default check period $wait_check_period seconds.

#     -o # show output of executed commands, not show is default
#     -v # bashmatic verbose
#     -d # bashmatic debug
#   "
#   if [ $# -eq "0" ]; then # Script invoked with no command-line args?
#     #err "Script `basename $0` invoked with no command-line args\n"
#     echo "Error: Call 'wait-for-success' without parameters"
#     echo "$usage"
#     return 1 # Exit and explain usage.
#   fi

#   while getopts "t:p:ov" opt
#   do
#     case $opt in
#       t )
#         wait_timeout=$OPTARG
#       ;;
#       p )
#         wait_check_period=$OPTARG
#       ;;
#       o ) opt_show_output='show-output-on'
#       ;;
#       v ) verbose-on
#       ;;
#       \? ) 
#       echo "Wrong parameter '$opt'"
#       echo "For help: `basename $0` -h"
#       return 1
#     esac
#   done
#   shift $((OPTIND-1))

#   if [ -z "$1" ]; then
#     echo "Function 'wait-for-success' is expecting <bash command> parameter"
#     return 1
#   fi

#   echo "wait_timeout=$wait_timeout"
#   echo "wait_check_period=$wait_check_period"
#   echo "<bash command>='$1'"

# set -x

#   # https://linuxsimply.com/bash-scripting-tutorial/conditional-statements/if/if-command-fails/
#   until eval "$1" &> /dev/null;
#   do 
#     echo "<bash command> returned='$?'"
#     sleep $wait_check_period
#     ((wait_time+=wait_check_period))
#     echo "total wait time=$wait_time"
#     if [[ $wait_time -gt $wait_timeout ]]; then
#       echo "Timeout. Wait time ${wait_time} sec  ${LINENO} $0"
#       return 1
#     fi
#   done
# }

# vlib.wait-for-error()
# {
#   # https://earthly.dev/blog/jq-select/
#   # https://www.baeldung.com/linux/bash-execute-variable-command

#   local wait_timeout=100
#   local wait_check_period=10
#   local wait_error=0
#   local wait_success=0

#   usage="Usage: vlib.wait-for-error [OPTION] <bash command>
#   Options:
#     -t timeout # Wait up to 'timeout' seconds. Default timeout $wait_timeout seconds.
#     -p period # Check period in seconds while waiting. Default check period $wait_check_period seconds.

#     -o # show output of executed commands, not show is default
#     -v # bashmatic verbose
#     -d # bashmatic debug
#   "
#   if [ $# -eq "0" ]; then # Script invoked with no command-line args?
#     #err "Script `basename $0` invoked with no command-line args\n"
#     echo "Error: Call 'vlib.wait-for-error' without parameters"
#     echo "$usage"
#     return 1 # Exit and explain usage.
#   fi

#   while getopts "est:p:ov" opt
#   do
#     case $opt in
#       t )
#         wait_timeout=$OPTARG
#       ;;
#       p )
#         wait_check_period=$OPTARG
#       ;;
#       o ) opt_show_output='show-output-on'
#       ;;
#       v ) verbose-on
#       ;;
#       \? ) 
#       echo "Wrong parameter '$opt'"
#       echo "For help: `basename $0` -h"
#       return 1
#     esac
#   done
#   shift $((OPTIND-1))

#   if [ -z "$1" ]; then
#     echo "Function 'vlib.wait-for-error' is expecting <bash command> parameter"
#     return 1
#   fi

#   echo $wait_timeout
#   echo $wait_check_period
#   echo "$1"

# set -x

#   until ! eval "$1" &> /dev/null;
#   do 
#     echo $?
#     sleep $wait_check_period
#     ((wait_time+=wait_check_period))
#     echo $wait_time
#     if [[ $wait_time -gt $wait_timeout ]]; then
#       echo "Timeout. Wait time ${wait_time} sec  ${LINENO} $0"
#       return 1
#     fi
#   done
# }

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
    export KUBECONFIGNAME="`basename $KUBECONFIG`"
    if [ -z $PS1OLD ]; then
        PS1OLD=$PS1
    fi
    if [ -n $KUBECONFIGNAME ]; then
        PS1=$KUBECONFIGNAME:$PS1OLD
    else
        PS1=$PS1OLD
    fi
    PROFILE=$(yq '.users[0].user.exec.env[0].value' $KUBECONFIG)
    REGION=$(yq '.users[0].user.exec.args' $KUBECONFIG | grep -A1 region | tail -1 | awk '{print $2}')
    #awsp $PROFILE $REGION
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
k() {
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

#$1 $2 $3 $4 $5 $6