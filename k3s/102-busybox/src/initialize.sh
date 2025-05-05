## initialize hook
##
## Any code here will be placed inside the `initialize()` function and called
## before running anything else.

# [[ -f ~/.bashmatic/init.sh ]] || {
#   echo "Can't find or install Bashmatic. Exiting."
#   exit 1
# }
#source ~/.bashmatic/init.sh
source ./../k8s.sh
source ./../vlib.bash
#set -x

