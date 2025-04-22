#!/bin/bash

function script-3-exec()
{
  echo "script-3-exec"
  [[ "$1" == "3" ]] && unknown-command
  exit 0
}
