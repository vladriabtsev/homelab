#!/usr/bin/env bash

# How do you write, import, use, and test libraries in Bash?
# https://gabrielstaples.com/bash-libraries/#gsc.tab=0
# https://opensource.com/article/20/6/bash-source-command
# https://github.com/awesome-lists/awesome-bash
# https://github.com/alebcay/awesome-shell
# https://github.com/SkypLabs/bsfl/tree/develop

function h2() {
  vlib.message-box "INFO" "$@" #"$(blue_bold)"
  #echo "$(blue_bold "$@")"
}
function inf() {
  echo "$(green_bold "$@")"
}
function warn() {
  echo "$(yellow_bold "$@")"
}
function bashly_step() {
  echo "[$(date -Is)]" "$@"
  echo blue_bold "$@"
}
function bashly_info() {
  echo " $(green "$@")"
}
function bashly_warn() {
  echo "  ==> $(yellow_bold "$@")"
}
# function bashly_err()
# {
#   echo "  ===> $(red_bold "$@")"
#   exit 1
# }
function echo_err() {
  echo "$(red_bold "$@")"
}
function warn-and-trace() {
  echo "$(yellow_bold "$@")"
  vlib.call-trace 1
}
function err_and_exit() {
  # if [ -z "$1" ]; then
  #   echo_err "Function err_and_exit is expecting error message as a first parameter"
  # fi
  # #caller.stack
  # #exit
  # if [ -z "$2" ]; then
  #   echo_err "Function err_and_exit is expecting \$LINENO as a second parameter"
  #   vlib.call-trace 1
  #   exit 1
  # fi
  # local call_lineno="$2"

  # if [ -z "$3" ]; then
  #   echo_err "$1 LINENO: $2"
  # else
  #   echo_err "$1 FUNCNAME: $3, LINENO: $2"
  # fi
  echo_err "$1"
  vlib.call-trace 1
  exit 1
}
function echo_red() {
  echo "$(red "$@")"
}
function echo_red_bold() {
  echo "$(red_bold "$@")"
}
function echo_green() {
  echo "$(green "$@")"
}
function echo_blue() {
  echo "$(blue "$@")"
}
function debug() {
 echo "Func BASH_SOURCE: ${!BASH_SOURCE[@]} ${BASH_SOURCE[@]}"
 echo "Func BASH_LINENO: ${!BASH_LINENO[@]} ${BASH_LINENO[@]}"
 echo "Func FUNCNAME: ${!FUNCNAME[@]} ${FUNCNAME[@]}"
 echo "Func LINENO: ${LINENO}"
}
function log() {
  local msg=$1
  now=$(date)
  i=${#FUNCNAME[@]}
  lineno=${BASH_LINENO[$i-2]}
  file=${BASH_SOURCE[$i-1]}
  echo "${now} $(hostname) $0:${lineno} ${msg}"
}
function vlib.call-trace() {
  LEN=${#BASH_LINENO[@]}
  INDEX_MAX=($LEN-1)
  #LEN2=${#BASH_SOURCE[@]}
  echo "##################### C A L L   T R A C E ##########################"
  local index_start=0
  if ! [[ -z $1 ]]; then index_start=$1; fi
  for (( INDEX=$index_start; INDEX<$INDEX_MAX; INDEX++ ))
  do
    if [[ ${INDEX} -gt 0 ]]; then
      # commands in stack trace
      echo " - file: ${BASH_SOURCE[${INDEX}+1]}, line: ${BASH_LINENO[${INDEX}]}, func: ${FUNCNAME[${INDEX}+1]}, command: ${FUNCNAME[${INDEX}]}"
    else
      # command that failed
      echo "source trace:"
      #echo_green "source trace:"
      echo " - file: ${BASH_SOURCE[${INDEX}+1]}, line: ${ERR_LINENO}, func: ${FUNCNAME[${INDEX}+1]}, command: ${BASH_COMMAND}"
    fi
  done
  echo "################# E N D   C A L L   T R A C E ######################"
}
function vlib.trace() {
  #echo "is trace: '$__is_trace'"
  [[ $__is_trace -eq 0 ]] && return 0
  if [[ ${#BASH_LINENO[@]} -gt 1 ]]; then
    echo "$(green 'Trace:') $(green "$@") # file: ${BASH_SOURCE[1]}, line: ${BASH_LINENO[0]}, func: ${FUNCNAME[1]}, from file: ${BASH_SOURCE[2]}, line: ${BASH_LINENO[1]}"
  else
    echo "$(green 'Trace:') $(green "$@") # file: ${BASH_SOURCE[1]}, line: ${BASH_LINENO[0]}, func: ${FUNCNAME[1]}"
  fi
}
function vlib.error-printf() {
  printf "$@" >&2
  printf "\n" >&2
  vlib.call-trace 2
  exit 1
}

#bashmatic.run() {
#  .run $@
#  return "${LibRun__LastExitCode}"
#}

# https://opensource.com/article/22/7/print-stack-trace-bash-scripts
function _trap_failure() {
  #echo "_trap_failure()"
  #set +xv # turns off debug logging, just in case
  ERR_LINENO=$1
  ERR_CODE=$2 # capture last command exit code
  if [[ ${ERR_CODE} != 0 ]]; then
    # only log stack trace if requested (set -e)
    # and last command failed
    #vlib.call-trace
    LEN=${#BASH_LINENO[@]}
    INDEX_MAX=($LEN-1)
    #LEN2=${#BASH_SOURCE[@]}
    echo "##################### F A I L U R E  T R A C E ###########################"
    echo "script ${BASH_SOURCE[$INDEX_MAX]} exited with error code: ${ERR_CODE}"
    #echo_red "script ${BASH_SOURCE[${INDEX_MAX}]} exited with error code: ${ERR_CODE}"
    echo "error trace ${BASH_SOURCE[1]}:"
    #echo_green "error trace ${BASH_SOURCE[1]}:"
    awk 'NR>L-4 && NR<L+4 { printf "%-5d%3s%s\n",NR,(NR==L?">>>":""),$0 }' L=$ERR_LINENO "${BASH_SOURCE[1]}"
    for (( INDEX=0; INDEX<$INDEX_MAX; INDEX++ ))
    do
      if [[ ${INDEX} -gt 0 ]]; then
        # commands in stack trace
        echo " - file: ${BASH_SOURCE[${INDEX}+1]}, line: ${BASH_LINENO[${INDEX}]}, func: ${FUNCNAME[${INDEX}+1]}, command: ${FUNCNAME[${INDEX}]}"
      else
        # command that failed
        echo "source trace:"
        #echo_green "source trace:"
        echo " - file: ${BASH_SOURCE[${INDEX}+1]}, line: ${ERR_LINENO}, func: ${FUNCNAME[${INDEX}+1]}, command: ${BASH_COMMAND}"
      fi
    done
    echo "################# E N D   F A I L U R E   T R A C E ######################"
  fi
  exit ${ERR_CODE}
}
function vlib.bashly-init-error-handler() {
  # https://www.baeldung.com/linux/debug-bash-script
  # https://phoenixnap.com/kb/bash-redirect-stderr-to-stdout

  # 5 Simple Steps On How To Debug a Bash Shell Script
  # https://www.shell-tips.com/bash/debug-script/#gsc.tab=0
  # trap 'echo "$BASH_COMMAND" failed with error code $?' ERR
  # https://gist.github.com/aguy/2359833
  # https://opensource.com/article/22/7/print-stack-trace-bash-scripts
  # https://github.com/hippyod-labs/shell-stack-trace-example/blob/main/stracktrace.sh
  # https://medium.com/@dirk.avery/the-bash-trap-trap-ce6083f36700
  # https://unix.stackexchange.com/questions/39623/trap-err-and-echoing-the-error-line
  # https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin-1
  set -E # errtrace
  set -T # functrace
  set -o pipefail

  ## Optional, but recommended to find true directory this script resides in
  # __SOURCE__="${BASH_SOURCE[0]}"
  # while [[ -h "${__SOURCE__}" ]]; do
  #     __SOURCE__="$(find "${__SOURCE__}" -type l -ls | sed -n 's@^.* -> \(.*\)@\1@p')"
  # done
  # __DIR__="$(cd -P "$(dirname "${__SOURCE__}")" && pwd)"
  #trap '_trap_failure "LINENO" "BASH_LINENO" "${BASH_COMMAND}" "${?}"' ERR
  trap '_trap_failure $LINENO $?' ERR

  current_pwd=${PWD}
  current_ps4=${PS4}
  #PS4='+[$0:$LINENO] '
  PS4='+[${BASH_SOURCE[1]}:$LINENO] '
  #echo $PS4

  # https://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
  trap 'set +xv; PS4=$current_ps4; cd "$current_pwd"' EXIT

  # https://opensource.com/article/22/7/print-stack-trace-bash-scripts

  # Bash Tips #2 – Splitting Shell Scripts to Improve Readability
  # https://blog.tratif.com/2023/01/27/bash-tips-2-splitting-shell-scripts-to-improve-readability/

  # Bash Tips #3 – Templating in Bash Scripts
  # https://blog.tratif.com/2023/01/27/bash-tips-3-templating-in-bash-scripts/

  # Bash Tips #4 – Error Handling in Bash Scripts
  # https://blog.tratif.com/2023/01/30/bash-tips-4-error-handling-in-bash-scripts/

}
function redirect-to-log-file {
  [[ $# -eq 1 ]] || ( echo_err "Only one parameter is expected" ${LINENO}; exit 1 )
  [ -z "$1" ] && ( echo_err "Expecting log file path as a parameter"; exit 1 )

  # https://tldp.org/LDP/abs/html/io-redirection.html
  # https://tldp.org/LDP/abs/html/ioredirintro.html
  # https://stackoverflow.com/questions/18460186/writing-outputs-to-log-file-and-console
  # https://askubuntu.com/questions/811439/bash-set-x-logs-to-file
  # https://tldp.org/LDP/abs/html/process-sub.html
  # https://www.gnu.org/software/bash/manual/bash.html#Process-Substitution
  
  # output stdout to console and to logfile
  # https://tldp.org/LDP/abs/html/ioredirintro.html
  # https://tldp.org/LDP/abs/html/io-redirection.html
  # https://tldp.org/LDP/abs/html/internal.html#EXECREF
  # https://tldp.org/LDP/abs/html/x17974.html#USINGEXECREF

  #exec > >(while read -r line; do printf '%s %s\n' "$(date --rfc-3339=seconds)" "$line" | tee -a "$1"; done)
  #exec 2> >(while read -r line; do printf '%s %s\n' "$(date --rfc-3339=seconds)" "$line" | tee -a "$1"; done >&2)

  # output stdout to console and to logfile, stderr to stdout
  exec &> >(tee -ia "$1")

  # Notice no leading $
  exec {FD}> "$1" {FD}>&1

  # If you want to append instead of wiping previous logs
  #exec {FD}>> "$1" {FD}>&1

  #exec 3>&1 1>"$1" 2>&1;
  
  export BASH_XTRACEFD="$FD"
  date --rfc-3339=seconds > "$1"
}
function vlib.bashly-init-command() {
  #debug
  # 5 Simple Steps On How To Debug a Bash Shell Script
  # https://www.shell-tips.com/bash/debug-script/#gsc.tab=0
  # trap '{ set +x; } 2>/dev/null; echo -n "[$(date) ${BASH_SOURCE[0]} ${BASH_LINENO[0]}] "; set -x' DEBUG
  # trap 'echo -n "[${BASH_SOURCE[0]} ${BASH_LINENO[0]}] "' DEBUG

  set -e

  [[ -z $args ]] || ( echo_err "Expecting bashly script when call bashly-init-command()"; exit 1 ) 
  #[[ $# -eq 1 ]] || err_and_exit "Only one parameter is expected" ${LINENO}

  __is_trace=0
  if [[ ${args[--trace]} || ${args[--debug]} ]]; then 
    __is_trace=1
  fi

  #local inarray=$(echo ${haystack[@]} | grep -ow "--framework" | wc -w)
  #if [[ -z ${args[--framework]} ]]; then
  #vlib.trace "framework=${args[--framework]}"
  case ${args[--framework]} in
    bashmatic )
      vlib.trace "Bashmatic framework"
      # [[ -f ~/.bashmatic/init.sh ]] || {
      #   echo "Can't find or install Bashmatic. Exiting."
      #   exit 1
      # }
      # # shellcheck disable=SC1090
      # source ~/.bashmatic/init.sh

      [[ -f $VBASH/bashmatic/init.sh ]] || {
        echo "Can't find or install Bashmatic. Exiting."
        exit 1
      }
      # shellcheck disable=SC1090
      source $VBASH/bashmatic/init.sh
      source "${VBASH}/vbashmatic.bash"
    ;;
    bsfl )
      vlib.trace "Bsfl framework"
      vlib.bashly-init-error-handler
      err_and_exit "Not implemented yet." ${LINENO} "$0"
    ;;
    none )
      vlib.trace "Pure bash without framework"
      vlib.bashly-init-error-handler
    ;;
    \? ) 
      err_and_exit "Wrong --framework argument ${args[framework-type]}. Expecting bashmatic, bsfl or none." ${LINENO} "$0"
    ;;
  esac
  # https://www.gnu.org/software/bash/manual/bash.html#The-Set-Builtin-1
  # https://tldp.org/LDP/abs/html/internal.html#EXECREF
  # https://github.com/kigster/bashmatic
  set +u
  __bashly_init_command_set=""
  __bashmatic_init_set=""
  if [[ ${args[--noerrexit]} ]]; then 
    set +e
  else
    __bashmatic_init_set="${__bashmatic_init_set} abort-on-error"
  fi
  if [[ ${args[--noexec]} ]]; then 
    __bashly_init_command_set="${__bashly_init_command_set}n"
    __bashmatic_init_set="${__bashmatic_init_set} dry-run-on"
  else
    __bashmatic_init_set="${__bashmatic_init_set} dry-run-off"
  fi
  if [[ ${args[--trace]} ]]; then 
    __is_trace=1
  fi
  if [[ ${args[--unset]} ]]; then 
    __bashly_init_command_set="${__bashly_init_command_set}u"
  fi
  if [[ ${args[--debug]} ]]; then
    __is_trace=1
    __bashly_init_command_set="${__bashly_init_command_set}vx"
    __bashmatic_init_set="${__bashmatic_init_set} show-command-on"
    __bashmatic_init_set="${__bashmatic_init_set} show-output-on"
    if [[ ${args[--noerrexit]} ]]; then 
      __bashmatic_init_set="${__bashmatic_init_set} ask-on-error"
    fi
  else
    if [[ ${args[--verbose]} ]]; then 
      __bashly_init_command_set="${__bashly_init_command_set}v"
      __bashmatic_init_set="${__bashmatic_init_set} show-command-on"
      __bashmatic_init_set="${__bashmatic_init_set} show-output-on"
    fi
    if [[ ${args[--xtrace]} ]]; then 
      __bashly_init_command_set="${__bashly_init_command_set}x"
      __bashmatic_init_set="${__bashmatic_init_set} show-command-on"
    fi
  fi

  # Bash Tips #1 – Logging in Shell Scripts
  # https://blog.tratif.com/2023/01/09/bash-tips-1-logging-in-shell-scripts/
  #echo "${args[--log]}"
  if [ -n "${args[--log]}" ]; then
    if [ -n "${MY_LOG_DIR}" ]; then
      local __command_action_name="${BASH_SOURCE[${#BASH_LINENO[@]}-1]}"
      __command_action_name="$(basename $__command_action_name)-${action}"
      #echo "${MY_LOG_DIR}${__command_action_name}.log"
      # log history
      # https://stackoverflow.com/questions/5789526/log-rotating-with-a-bash-script
      # https://unix.stackexchange.com/questions/231486/how-to-implement-logrotate-in-shell-script
      # https://superuser.com/questions/1105185/creating-a-bash-script-for-logrotation-with-date-in-foldername
      # https://askubuntu.com/questions/370571/how-can-i-automatically-rotate-archive-my-bash-history-logs
      redirect-to-log-file "${MY_LOG_DIR}${__command_action_name}.log"
    else
      echo_err "Environment variable MY_LOG_DIR is empty."
      exit 1
    fi
  elif [ -n "${args[--log-file]}" ]; then
    redirect-to-log-file "${args[log-file-path]}"
  fi

  # Bash Tips #2 – Splitting Shell Scripts to Improve Readability
  # https://blog.tratif.com/2023/01/27/bash-tips-2-splitting-shell-scripts-to-improve-readability/

  # Bash Tips #3 – Templating in Bash Scripts
  # https://blog.tratif.com/2023/01/27/bash-tips-3-templating-in-bash-scripts/

  # Bash Tips #4 – Error Handling in Bash Scripts
  # https://blog.tratif.com/2023/01/30/bash-tips-4-error-handling-in-bash-scripts/

  if [[ "$__bashly_init_command_set" != "" ]]; then 
    vlib.trace "__bashly_init_command_set=${__bashly_init_command_set}"
    #echo "-$__bashly_init_command_set"
    set "-${__bashly_init_command_set}"; 
  fi

  case ${args[--framework]} in
    bashmatic )
      vlib.trace "__bashmatic_init_set=${__bashmatic_init_set}"
      run.set-all "$__bashmatic_init_set"
    ;;
    bsfl )
      vlib.bashly-init-error-handler
      err_and_exit "Not implemented yet." ${LINENO} "$0"
    ;;
    \? ) err_and_exit "Wrong --framework argument ${args[framework-type]}. Expecting bashmatic or bsfl." ${LINENO} "$0"
    ;;
  esac
  #if [[ ${args[--verbose]} || ${args[--debug]} || ${args[--xtrace]} ]]; then
  #  inspect_args
  #fi
}
# https://www.baeldung.com/linux/compare-dot-separated-version-string
function vlib.vercomp() {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}
# shellcheck disable=SC2046
# shellcheck disable=SC2183
function vlib.ver { printf "%03d%03d%03d%03d" $(echo "$1" | tr '.' ' '); } # [ $(vlib.ver 10.9) -lt $(vlib.ver 10.10) ] && echo 1
function vlib.check-github-release-version() {
  usage="Usage: $(basename $0) name github_releases_url name_of_version_variable"
  if [ -z "$1" ]; then
    echo $usage
    err_and_exit "Missing first parameter"
  fi
  if [ -z "$2" ]; then
    echo $usage
    err_and_exit "Missing second parameter"
  fi
  if [ -z "$3" ]; then
    echo $usage
    err_and_exit "Missing third parameter"
  fi
  #longhorn_latest=$(curl -sL https://api.github.com/repos/longhorn/longhorn/releases | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  local latest=$(curl -sL $2 | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  if ! [ -z $latest ]; then
    eval local ver2=\"\$$3\"
    local ver=$ver2
    if [ -z $ver ]; then ver=$latest; fi
    if ! [ -z $ver2 ]; then
      if ! [ "$latest" == "$ver" ]; then
        warn "Latest version of $name: '$latest', but installing: '$ver'\n"
      fi
    fi
    eval "$3=$ver"
  fi
}
# Waits until the user presses any key to continue.
function vlib.press-any-key() {
  local prompt="$*"
  trap 'return 1' INT
  [[ -z ${prompt} ]] && prompt="Press any key to continue..."
  br
  printf "    ${prompt}  "
  read -r -s -n1 key
  # cursor.rewind
  # printf "                                                           "
  # cursor.up 2
  # cursor.rewind
  echo
}
function vlib.check-data-for-secrets() {
  # $1 - folder path with secret data
  [ -d "${HOME}/.ssh/k3s-HA-csi-synology-secrets" ] || err_and_exit "Can't find home folder."
  [ -d ~/.ssh/k3s-HA-csi-synology-secrets ] || err_and_exit "Can't find home folder."
  [ -d "$1" ] || err_and_exit "Can't find folder '$1'."
  [ -a "$1/username.txt" ] || err_and_exit "Can't find user name file '$1/username.txt'."
  [ -r "$1/username.txt" ] || err_and_exit "File '$1/username.txt' exists, but not readable."
  [ -a "$1/password.txt" ] || err_and_exit "Can't find user name file '$1/password.txt'."
  [ -r "$1/password.txt" ] || err_and_exit "File '$1/password.txt' exists, but not readable."
  return 0
}
function vlib.read-password() {
  local variable="$1"
  shift
  local text="$*"
  local user_input

  trap 'echo; echo Aborting at user request... ; echo; abort; return' int

  echo -n "${text}"
  #ask "${text}"
  # create a variable to hold the input
  read -s -i "*********" user_input
  # Check if string is empty using -z. For more 'help test'
  if [[ -z "${user_input}" ]]; then
    error "Sorry, I didn't get that. Please try again or press Ctrl-C to abort."
    return 1
  else
    eval "${variable}=\"${user_input}\""
    return 0
  fi
}
function vlib.read-user-input() {
  local variable="$1"
  shift
  local text="$*"
  local user_input

  trap 'echo; echo Aborting at user request... ; echo; abort; return' int

  ask "${text}"
  # create a variable to hold the input
  read user_input
  # Check if string is empty using -z. For more 'help test'
  if [[ -z "${user_input}" ]]; then
    error "Sorry, I didn't get that. Please try again or press Ctrl-C to abort."
    return 1
  else
    eval "export ${variable}=\"${user_input}\""
    return 0
  fi
}
function vlib.retry-command() {
  local command="$*"
  local retries=5

  n=0
  until [ $n -ge ${retries} ]; do
    [[ ${n} -gt 0 ]] && info "Retry number ${n}..."

    command && break # substitute your command here

    n=$(($n + 1))
    sleep 1
  done
}
function vlib.get-user-input() {
  vlib.retry-command run.ui.ask-user-value "${@}"
}
# Ask the user if they want to proceed, defaulting to Yes.
# Choosing no exits the program. The arguments are printed as a question.
function vlib.ask() {
  local question=$*
  local func="${LibRun__AskDeclineFunction}"

  # reset back to default
  export LibRun__AskDeclineFunction="${LibRun__AskDeclineFunction__Default}"

  echo
  inf "${bldcyn}${question}${clr} [Y/n] ${bldylw}"
  read a 2>/dev/null
  code=$?
  if [[ ${code} != 0 ]]; then
    error "Unable to read from STDIN."
    eval "${func} 12"
  fi
  echo
  if [[ ${a} == 'y' || ${a} == 'Y' || ${a} == '' ]]; then
    info "Yes"
    hr
    echo
  else
    info "Abort! 🛳   " >&2
    hr >&2
    echo
    eval "${func} 1"
  fi
}
function vlib.wait-for-success() {
  # https://earthly.dev/blog/jq-select/
  # https://www.baeldung.com/linux/bash-execute-variable-command

  local wait_timeout=300
  local wait_check_period=15
  local wait_error=0
  local wait_success=0

  usage="Usage: vlib.wait-for-success [OPTION] <bash command>
  Options:
    -t timeout # Wait up to 'timeout' seconds. Default timeout $wait_timeout seconds.
    -p period # Check period in seconds while waiting. Default check period $wait_check_period seconds.

    -o # show output of executed commands, not show is default
    -v # bashmatic verbose
    -d # bashmatic debug
  "
  if [ $# -eq "0" ]; then # Script invoked with no command-line args?
    echo "Error: Call 'vlib.wait-for-success' without parameters"
    echo "$usage"
    return 1 # Exit and explain usage.
  fi

  #echo "$#"
  #echo "$*"

  #echo "$OPTIND"

  local isopt=0
  while getopts "t:p:ov" opt
  do
    case $opt in
      t )
        isopt=1
        wait_timeout=$OPTARG
      ;;
      p )
        isopt=1
        wait_check_period=$OPTARG
      ;;
      o ) 
        isopt=1
        opt_show_output='show-output-on'
      ;;
      v ) 
        isopt=1
        verbose-on
      ;;
      \? ) 
      echo "Wrong parameter '$opt'"
      echo "For help: $(basename $0) -h"
      return 1
    esac
  done
  #echo "$OPTIND"
  if [[ $isopt -gt 0 ]]; then
    shift $((OPTIND-1))
  fi

  if [ -z "$1" ]; then
    echo "Function 'vlib.wait-for-success' is expecting <bash command> parameter"
    return 1
  fi

  echo "wait_timeout=$wait_timeout"
  echo "wait_check_period=$wait_check_period"
  echo "<bash command>='$1'"

  #set -x

  # https://linuxsimply.com/bash-scripting-tutorial/conditional-statements/if/if-command-fails/
  until eval "$1" &> /dev/null;
  do 
    echo "<bash command> returned='$?'"
    sleep $wait_check_period
    ((wait_time+=wait_check_period))
    echo "total wait time=$wait_time"
    if [[ $wait_time -gt $wait_timeout ]]; then
      echo "Timeout. Wait time ${wait_time} sec  ${LINENO} $0"
      return 1
    fi
  done
}
function vlib.wait-for-error() {
  # https://earthly.dev/blog/jq-select/
  # https://www.baeldung.com/linux/bash-execute-variable-command

  local wait_timeout=200
  local wait_check_period=15
  local wait_error=0
  local wait_success=0

  usage="Usage: vlib.wait-for-error [OPTION] <bash command>
  Options:
    -t timeout # Wait up to 'timeout' seconds. Default timeout $wait_timeout seconds.
    -p period # Check period in seconds while waiting. Default check period $wait_check_period seconds.

    -o # show output of executed commands, not show is default
    -v # bashmatic verbose
    -d # bashmatic debug
  "
  if [ $# -eq "0" ]; then # Script invoked with no command-line args?
    echo "Error: Call 'vlib.wait-for-error' without parameters"
    echo "$usage"
    return 1 # Exit and explain usage.
  fi

  local isopt=0
  while getopts "est:p:ov" opt
  do
    case $opt in
      t )
        isopt=1
        wait_timeout=$OPTARG
      ;;
      p )
        isopt=1
        wait_check_period=$OPTARG
      ;;
      o ) 
        isopt=1
        opt_show_output='show-output-on'
      ;;
      v ) 
        isopt=1
        verbose-on
      ;;
      \? ) 
      echo "Wrong parameter '$opt'"
      echo "For help: $(basename $0) -h"
      return 1
    esac
  done
  if [[ $isopt -gt 0 ]]; then
    shift $((OPTIND-1))
  fi

  if [ -z "$1" ]; then
    echo "Function 'vlib.wait-for-error' is expecting <bash command> parameter"
    return 1
  fi

  echo $wait_timeout
  echo $wait_check_period
  echo "$1"

  #set -x

  until ! eval "$1" &> /dev/null;
  do 
    echo $?
    sleep $wait_check_period
    ((wait_time+=wait_check_period))
    echo $wait_time
    if [[ $wait_time -gt $wait_timeout ]]; then
      echo "Timeout. Wait time ${wait_time} sec  ${LINENO} $0"
      return 1
    fi
  done
}
################################################################
#                     Box with message 
#
# Usage:
# txt="multi line
# text"
#
# vlib.message-box "TASK" "$txt" "84"
# vlib.message-box "INFO" "$txt" "123"
# vlib.message-box "ERROR" "$txt" "160"
#
# Idea from: https://gitlab.com/edmitry2010/obsidian-open-git/-/blob/main/bash/%D0%9E%D1%84%D0%BE%D1%80%D0%BC%D0%BB%D0%B5%D0%BD%D0%B8%D0%B5/bash%20-%20%D0%9A%D1%80%D0%B0%D1%81%D0%B8%D0%B2%D1%8B%D0%B5%20%D1%83%D0%B2%D0%B5%D0%B4%D0%BE%D0%BC%D0%BB%D0%B5%D0%BD%D0%B8%D1%8F,%20%D1%81%D0%B0%D0%BC%D1%8B%D0%B9%20%D0%BA%D0%BE%D0%BC%D0%BF%D0%B0%D0%BA%D1%82%D0%BD%D1%8B%D0%B9%20%D0%B2%D0%B0%D1%80%D0%B8%D0%B0%D0%BD%D1%82.md
function vlib.message-box() {
  local header_text="${1^^}"
  local message="$2"
  #local message=$(echo $2 | fold -sw $(($(tput cols) - 4))) # Максимальный размер текста, определяется размером терминала - 4
  local color="$3"
  local wide="$4"

  if [[ -n $color ]]; then
    local white=$"\e[38;5;"$color"m"
  else
    local white=$'\e[38;5;231m'
  fi

  local reset=$'\e[0m'
  local color

  case "$header_text" in
     INFO) color=$'\e[38;5;39m' ;;
       OK) color=$'\e[38;5;34m' ;;
     DONE) color=$'\e[38;5;34m' ;;
     WARN) color=$'\e[38;5;214m' ;;
    ERROR) color=$'\e[38;5;196m' ;;
    DEBUG) color=$'\e[38;5;244m' ;;
     TASK) color=$'\e[38;5;141m' ;;
     NOTE) color=$'\e[38;5;45m' ;;
        *) color=$'\e[38;5;244m' ;;
  esac

  # Split message into lines
  local IFS=$'\n'
  # shellcheck disable=SC2206
  local lines=($message)
  local max_length=0

  # Find max line length
  for line in "${lines[@]}"; do
    local len=${#line}
    if (( len > max_length )); then
      max_length=$len
    fi
  done

  (( max_length++ ))

  #max_length=$(tput cols)-4

  local header_padding=$(( max_length - ${#header_text} ))
  echo "${message}"
  local header=${message:0:header_padding}
  echo "${header}"

  # Print upper border
  local border=$(printf "%${max_length}s" "")
  if [[ -n $wide ]]; then
    echo -e "${color}╭ ${header_text} ${header//?/─}────╮"
    echo -e "│   ${border//?/ }   │"
  else
    echo -e "${color}╭─${white}${header_text}${color}${header//?/─}╮"
  fi

  # Print lines
  for line in "${lines[@]}"; do
    local padding=$(( max_length - ${#line} ))
    local padded_line="${white}${line}${white}$(printf "%${padding}s" " ")$color"
    if [[ -n $wide ]]; then
      echo -e "│   ${padded_line}   │"
    else
      echo -e "│ ${padded_line}│"
    fi
  done

  # Print bottom border
  if [[ -n $wide ]]; then
    echo -e "│   ${border//?/ }   │"
    echo -e "╰──${border//?/─}────╯${reset}"
  else
    echo -e "╰─${border//?/─}╯${reset}"
  fi

  #unset border line padding padded_line
}
