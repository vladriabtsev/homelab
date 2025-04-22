#!/bin/bash

# shellcheck disable=SC1091
source ./script-lib-2.bash

function script-1-exec()
{
  echo "script-1-exec"
  [[ "$1" == "1" ]] && unknown-command
  script-2-exec $1
}
