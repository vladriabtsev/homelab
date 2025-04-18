#!/usr/bin/env bash
## initialize hook
##
## Any code here will be placed inside the `initialize()` function and called
## before running anything else.
##
## You can safely delete this file if you do not need it.

# shellcheck source=/dev/null
source "${VBASH}/vlib.bash"
# [[ -f ~/.bashmatic/init.sh ]] || {
# #[[ -f "${VBASH}/libs/bashmatic/init.sh" ]] || {
#   echo "Can't find or install Bashmatic. Exiting."
#   exit 1
# }
# set +e
# source ~/.bashmatic/init.sh

vlib.bashly-init-script

# shellcheck source=/dev/null
#source "${VBASH}/libs/bashmatic/init.sh"

#set -e
