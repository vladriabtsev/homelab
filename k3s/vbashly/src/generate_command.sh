#!/usr/bin/env bash

# https://phoenixnap.com/kb/bash-trap-command
# https://man7.org/linux/man-pages/man7/signal.7.html
# https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
# https://emmer.dev/blog/resetting-the-working-directory-on-shell-script-exit/
# shellcheck disable=SC2064

vlib.bashly-init-command

# https://www.linuxbash.sh/post/logging-and-monitoring-from-bash-scripts
# https://man7.org/linux/man-pages/man1/logger.1.html

# # https://www.baeldung.com/linux/logging-bash-scripts
# exec 3>&1 4>&2
# trap 'exec 2>&4 1>&3' 0 1 2 3
# exec 1>log.out 2>&1
# # Everything below will go to the file 'log.out':

#set -x
# shellcheck disable=SC2168
local filename
# shellcheck disable=SC2168
local dir
# shellcheck disable=SC2154
for file in ${args[bashly_prj_dir]}; do
  #echo "file - $(basename ${file})"
  filename=$(basename "${file}")
  if [[ -d "$file" && $filename != "vbashly" ]]; then
    #echo dir $(dirname "$(realpath ${file})")
    if test -d "$file/src"; then
	  echo file "$file"
	  echo filename "$filename"
      dir=$(dirname "$(realpath "${file}")")
	  echo dir "$dir"
      #cmd [option] "$file" >> results.out
	fi
  fi
done