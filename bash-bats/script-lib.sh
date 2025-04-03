#!/bin/bash

#set -e #x

source ./script-lib-0.bash
source ./script-lib-1.bash
source ./script-lib-2.bash
source ./script-lib-3.bash
source ../bash-lib.sh
bashly-init-script

# $1: where execute unknown-command
echo "script-lib.sh"

script-1-exec $1

exit 0
