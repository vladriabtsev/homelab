#!/usr/bin/env bash
#inspect_args

vlib.bashly-init-command
vlib.trace "$(inspect_args)"

# shellcheck disable=SC2154
eval "${args[command]}"
