#!/usr/bin/env bash
## before hook
#inspect_args

# shellcheck source=/dev/null
source "${VBASH}/vlib.bash"

vkube_folder="$(dirname $0)"
vlib.trace "vkube_folder=$vkube_folder"
