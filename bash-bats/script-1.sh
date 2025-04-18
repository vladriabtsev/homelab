#!/bin/bash
# $1: where execute unknown-command

#set -e #x

source ./script-lib-0.bash
source ../vlib.bash
vlib.bashly-init-script

echo "script-1"
[[ "$1" == "1" ]] && unknown-command
./script-2.sh $1

exit 0