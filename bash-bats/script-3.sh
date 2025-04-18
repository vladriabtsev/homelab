#!/bin/bash
# $1: where execute unknown-command

#set -e #x

source ./script-lib-0.bash
source ../vlib.bash
vlib.bashly-init-script

echo "script-3"
[[ "$1" == "3" ]] && unknown-command

exit 0
