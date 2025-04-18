#!/bin/bash
# $1: where execute unknown-command

#set -e #x

source ./script-lib-0.bash
source ../bash-lib.sbash
vlib.bashly-init-script

echo "script-2"
[[ "$1" == "2" ]] && unknown-command
./script-3.sh $1

exit 0