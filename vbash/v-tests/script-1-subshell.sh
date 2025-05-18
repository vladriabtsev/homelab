#!/bin/bash
# $1: where execute unknown-command

#set -e #x

# shellcheck disable=SC1091
source script-lib-0.bash
source ../vlib.bash
vlib.bashly-init-command
(
echo "script-1"
[[ "$1" == "1" ]] && unknown-command
./script-2.sh $1
)
exit 0