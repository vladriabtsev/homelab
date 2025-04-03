#!/bin/bash

source ./script-lib-3.bash

function script-2-exec()
{
  echo "script-2-exec"
  [[ "$1" == "2" ]] && unknown-command
  script-3-exec $1
}
