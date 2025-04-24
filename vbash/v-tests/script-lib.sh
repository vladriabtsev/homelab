#!/bin/bash

#set -e #x

# shellcheck disable=SC1091
source ./script-lib-0.bash
source ./script-lib-1.bash
source ./script-lib-2.bash
source ./script-lib-3.bash
source ../vlib.bash
vlib.bashly-init-command

# $1: where execute unknown-command
echo "script-lib.sh"

script-1-exec $1

exit 0
