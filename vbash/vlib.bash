#!/usr/bin/env bash

# How do you write, import, use, and test libraries in Bash?
# https://gabrielstaples.com/bash-libraries/#gsc.tab=0
# https://opensource.com/article/20/6/bash-source-command
# https://github.com/awesome-lists/awesome-bash
# https://github.com/alebcay/awesome-shell
# https://github.com/SkypLabs/bsfl/tree/develop


#region var
function vlib.var.is-not-empty {
  [ $# -ne 1 ] && err_and_exit "Expecting one parameter"
  [ -z $1 ] && return 1
  [ ${#1} -eq 0 ] && return 1
  return 0
}
function vlib.var.has-be-not-empty {
  [ $# -ne 1 ] && err_and_exit "Expecting one parameter"
  [ -z $1 ] && err_and_exit "Parameter \$1 is not defined"
  [ ${#1} -eq 0 ] && err_and_exit "Parameter \$1 is empty"
  return 0
}
function vlib.var.only-one-has-be-not-empty {
  [ $# -ne 2 ] && err_and_exit "Expecting two parameters"
  [ -z $1 ] && [ -z $2 ] && err_and_exit "Both parameters \$1 and \$2 are not defined"
  [ ${#1} -eq 0 ] && [ ${#2} -eq 0 ] && err_and_exit "Both parameters \$1 and \$2 are empty"
  return 0
}
#endregion var

#region colors

# https://misc.flogisoft.com/bash/tip_colors_and_formatting
# https://misc.flogisoft.com/bash/tip_colors_and_formatting#terminals_compatibility

print_in_color() {
  local color="$1"
  shift
  if [[ -z ${NO_COLOR+x} ]]; then
    printf "$color%b\e[0m\n" "$*"
  else
    printf "%b\n" "$*"
  fi
}
red() { print_in_color "\e[31m" "$*"; }
green() { print_in_color "\e[32m" "$*"; }
yellow() { print_in_color "\e[33m" "$*"; }
blue() { print_in_color "\e[34m" "$*"; }
magenta() { print_in_color "\e[35m" "$*"; }
cyan() { print_in_color "\e[36m" "$*"; }
bold() { print_in_color "\e[1m" "$*"; }
underlined() { print_in_color "\e[4m" "$*"; }
red_bold() { print_in_color "\e[1;31m" "$*"; }
green_bold() { print_in_color "\e[1;32m" "$*"; }
yellow_bold() { print_in_color "\e[1;33m" "$*"; }
blue_bold() { print_in_color "\e[1;34m" "$*"; }
magenta_bold() { print_in_color "\e[1;35m" "$*"; }
cyan_bold() { print_in_color "\e[1;36m" "$*"; }
red_underlined() { print_in_color "\e[4;31m" "$*"; }
green_underlined() { print_in_color "\e[4;32m" "$*"; }
yellow_underlined() { print_in_color "\e[4;33m" "$*"; }
blue_underlined() { print_in_color "\e[4;34m" "$*"; }
magenta_underlined() { print_in_color "\e[4;35m" "$*"; }
cyan_underlined() { print_in_color "\e[4;36m" "$*"; }

# Foreground Colors (Text):
vlib_default='\e[39m'
vlib_black='\e[30m'
vlib_red='\e[31m'
vlib_green='\e[32m'
vlib_yellow='\e[33m'
vlib_blue='\e[34m'
vlib_magenta='\e[35m'
vlib_cyan='\e[36m'
vlib_white='\e[37m'

# Foreground Colors (Text):
vlib_bg_default='\e[49m'
vlib_bg_black='\e[40m'
vlib_bg_red='\e[41m'
vlib_bg_green='\e[42m'
vlib_bg_yellow='\e[43m'
vlib_bg_blue='\e[44m'
vlib_bg_magenta='\e[45m'
vlib_bg_cyan='\e[46m'
vlib_bg_white='\e[47m'

# Set style:
vlib_bold='\e[1m'
vlib_dim='\e[2m'
vlib_underlined='\e[4m'
vlib_blink='\e[5m'
vlib_reverse='\e[7m'
vlib_hidden='\e[8m'

# Reset style:
vlib_reset_bold='\e[21m'
vlib_reset_dim='\e[22m'
vlib_reset_underlined='\e[24m'
vlib_reset_blink='\e[25m'
vlib_reset_reverse='\e[27m'
vlib_reset_hidden='\e[28m'
vlib_reset='\e[0m'

function vlib.echo() {
  usage="Usage: vlib.echo [OPTION] 'message text'
  Options:
    -i indent # indent string
    -n # no reset after printing message
    -b # echo bold text
    -d # echo dimmed text
    -u # echo underlined text
    -l # echo blinked text
    -r # echo reversed text (invert the foreground and background colors)	
    -h # echo hidden text (useful for passwords)
    --fg=value # foreground color, expected values: black, red, 
               green, yellow, blue, magenta, cyan, white
    --bg=value # background color, expected values: black, red, 
               green, yellow, blue, magenta, cyan, white
  "
  local color
  local bgrd
  local reset=1
  local mod
  local indent=""
  OPTIND=0
  while getopts "nbdulrh-:i:" opt; do
    #echo "opt=$opt" >&3
    case $opt in
      - )
        case $OPTARG in
          fg=* )
            # echo "fg" >&3
            # echo "$OPTARG" >&3
            case $OPTARG in
              fg=black )
                color="${vlib_black}"
              ;;
              fg=red )
                color="${vlib_red}"
              ;;
              fg=green )
                color="${vlib_green}"
              ;;
              fg=yellow )
                color="${vlib_yellow}"
              ;;
              fg=blue )
                color="${vlib_blue}"
              ;;
              fg=magenta )
                color="${vlib_magenta}"
              ;;
              fg=cyan )
                color="${vlib_cyan}"
              ;;
              fg=white )
                color="${vlib_white}"
              ;;
              * ) 
                #echo "$OPTARG" >&3
                err_and_exit "Error: Wrong color parameter for foreground '--$OPTARG'\n$usage"
              ;;
            esac
          ;;
          bg=* )
            case $OPTARG in
              bg=black )
                bgrd="${vlib_bg_black}"
              ;;
              bg=red )
                bgrd="${vlib_bg_red}"
              ;;
              bg=green )
                bgrd="${vlib_bg_green}"
              ;;
              bg=yellow )
                bgrd="${vlib_bg_yellow}"
              ;;
              bg=blue )
                bgrd="${vlib_bg_blue}"
              ;;
              bg=magenta )
                bgrd="${vlib_bg_magenta}"
              ;;
              bg=cyan )
                bgrd="${vlib_bg_cyan}"
              ;;
              bg=white )
                bgrd="${vlib_bg_white}"
              ;;
              * ) 
                err_and_exit "Error: Wrong color parameter for background '--$OPTARG'\n$usage"
              ;;
            esac
          ;;
          * )
            err_and_exit "Invalid long option: --$OPTARG\n$usage"
          ;;
        esac
        ;;
      i )
        indent=$OPTARG
      ;;
      n )
        reset=0
      ;;
      b )
        mod="${vlib_bold}"
      ;;
      d )
        mod="${vlib_dim}"
      ;;
      u )
        mod="${vlib_underlined}"
      ;;
      l )
        mod="${vlib_blink}"
      ;;
      r )
        mod="${vlib_reverse}"
      ;;
      h )
        mod="${vlib_hidden}"
      ;;
      * ) 
        err_and_exit "Wrong parameter '$opt'\n$usage"
      ;;
    esac
  done
  #echo "OPTIND=$OPTIND" >&3
  shift $((OPTIND-1))
  #vlib.print "${color}" $reset "" "$*"
  if [[ -z $1 ]]; then
    echo
  else
    if [[ ${reset} -eq 1 ]]; then
      # echo "kuku1" >&3
      # echo "#=$#" >&3
      # echo "1=$1" >&3
      printf "${indent}${mod}${color}${bgrd}%b\e[0m\n" "$*"
    else
      printf "${indent}${mod}${color}${bgrd}%b\n" "$*"
    fi
  fi
}
function vlib.all-colors() {
  declare -a colors 
  colors=( "black" "red" "green" "yellow" "blue" "magenta" "cyan" "white" )
  for bcolor in "${colors[@]}"; do
    for color in "${colors[@]}"; do
      vlib.echo --bg=$bcolor --fg=$color "$color on $bcolor"
      vlib.echo --bg=$bcolor -b --fg=$color "$color bold on $bcolor"
      vlib.echo --bg=$bcolor -d --fg=$color "$color dim on $bcolor"
      vlib.echo --bg=$bcolor -u --fg=$color "$color underlined on $bcolor"
      vlib.echo --bg=$bcolor -l --fg=$color "$color blinked on $bcolor"
      vlib.echo --bg=$bcolor -r --fg=$color "$color reversed on $bcolor"
      vlib.echo --bg=$bcolor -h --fg=$color "$color hidden on $bcolor"
    done
  done

  #Background
  for clbg in {40..47} {100..107} 49 ; do
    #Foreground
    for clfg in {30..37} {90..97} 39 ; do
      #Formatting
      for attr in 0 1 2 4 5 7 ; do
        #Print the result
        echo -en "\e[${attr};${clbg};${clfg}m ^[${attr};${clbg};${clfg}m \e[0m"
      done
      echo #Newline
    done
  done  

  vlib.h1 red "h1. text"
  vlib.h2 red h2. text
  vlib.h3 red "h3. text"
  vlib.h4 red "h4. text"

  echo -e "Default \e[31mRed"
  # vlib.echo "default $(vlib.red)red $(vlib.green)green $(vlib.yellow)yellow $(vlib.blue)blue $(vlib.magenta)magenta $(vlib.cyan)cyan $(vlib.white)white $(vlib.reset)"
}

# on black
# bold on black
# underlined on black
# reversed on black

# error - red
# warning - yellow
# info - green, blue, magenta, cyan, white

function vlib.h1() {
  if [[ $# -eq 1 ]]; then
    vlib.echo -r "$1"
  elif [[ $# -eq 0 ]]; then
    vlib.echo
  else
    local color
    color=$1
    shift
    vlib.echo -r --fg=$color "$*"
  fi
}
function vlib.h2() {
  if [[ $# -eq 1 ]]; then
    vlib.echo -i "  " -u "$1"
  elif [[ $# -eq 0 ]]; then
    vlib.echo
  else
    local color
    color=$1
    shift
    vlib.echo -i "  " -u --fg=$color "$*"
  fi
}
function vlib.h3() {
  if [[ $# -eq 1 ]]; then
    vlib.echo -i "    " -b "$1"
  elif [[ $# -eq 0 ]]; then
    vlib.echo
  else
    local color
    color=$1
    shift
    vlib.echo -i "    " -b --fg=$color "$*"
  fi
}
function vlib.h4() {
  if [[ $# -eq 1 ]]; then
    vlib.echo -i "      " "$1"
  elif [[ $# -eq 0 ]]; then
    vlib.echo
  else
    local color
    color=$1
    shift
    vlib.echo -i "      " --fg=$color "$*"
  fi
}



# function vlib.h2() {
#   echo "$(blue_bold "$@")"
# }

#endregion colors

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
function warn-and-trace() {
  echo "$(yellow_bold "$@")"
  vlib.call-trace 1
}
function err_and_exit() {
  vlib.echo -b --fg=red "$1"
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
    echo "$(green 'Trace:') $(green "$@")"
    echo "  # file: ${BASH_SOURCE[1]}, line: ${BASH_LINENO[0]}, func: ${FUNCNAME[1]}"
    echo "  # file: ${BASH_SOURCE[2]}, line: ${BASH_LINENO[1]}, func: ${FUNCNAME[2]}"
  else
    echo "$(green 'Trace:') $(green "$@")"
    echo "  # file: ${BASH_SOURCE[1]}, line: ${BASH_LINENO[0]}, func: ${FUNCNAME[1]}"
  fi
}
function vlib.trace-no-stack() {
  #echo "is trace: '$__is_trace'"
  [[ $__is_trace -eq 0 ]] && return 0
  echo "$(green 'Trace:') $(green "$@")"
}
function vlib.trace-yellow() {
  #echo "is trace: '$__is_trace'"
  [[ $__is_trace -eq 0 ]] && return 0
  if [[ ${#BASH_LINENO[@]} -gt 1 ]]; then
    #echo "$(green 'Trace:') $(green "$@") # file: ${BASH_SOURCE[1]}, line: ${BASH_LINENO[0]}, func: ${FUNCNAME[1]}, from file: ${BASH_SOURCE[2]}, line: ${BASH_LINENO[1]}"
    echo "$(yellow 'Trace:') $(yellow "$@")"
    echo "  # file: ${BASH_SOURCE[1]}, line: ${BASH_LINENO[0]}, func: ${FUNCNAME[1]}"
    echo "  # file: ${BASH_SOURCE[2]}, line: ${BASH_LINENO[1]}, func: ${FUNCNAME[2]}"
  else
    echo "$(yellow 'Trace:') $(yellow "$@")"
    echo "  # file: ${BASH_SOURCE[1]}, line: ${BASH_LINENO[0]}, func: ${FUNCNAME[1]}"
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
  [[ $# -eq 1 ]] || err_and_exit "Only one parameter is expected"
  [ -z "$1" ] && err_and_exit "Expecting log file path as a parameter"

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
  exec {FD}>"$1" {FD}>&1

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

  [[ "${#args[@]}" -gt 0 ]] || err_and_exit "Expecting bashly script when call bashly-init-command()" 
  #[ -z $args ] && ( err_and_exit "Expecting bashly script when call bashly-init-command()"; exit 1 ) 
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
    * ) 
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
      vlib.trace "FUNCNAME[@]=${FUNCNAME[@]}"
      local __action_name="${FUNCNAME[1]}"
      vlib.trace "__action_name=$__action_name"
      #echo "${MY_LOG_DIR}${__scrip_dir}.log"
      # log history
      # https://stackoverflow.com/questions/5789526/log-rotating-with-a-bash-script
      # https://unix.stackexchange.com/questions/231486/how-to-implement-logrotate-in-shell-script
      # https://superuser.com/questions/1105185/creating-a-bash-script-for-logrotation-with-date-in-foldername
      # https://askubuntu.com/questions/370571/how-can-i-automatically-rotate-archive-my-bash-history-logs
      redirect-to-log-file "${MY_LOG_DIR}${__action_name}.log"
    else
      err_and_exit "Environment variable MY_LOG_DIR is empty."
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

  ##############################
  #   Debug variable changes   #
  ##############################
  # _monitored_variable_name="amount_nodes" # Change variable name as parameter
  # trap 'vlib._monitor_variable_change' DEBUG   # Uncomment 'trap' line
  # vlib.trace "_monitored_variable_name=$_monitored_variable_name"
}
vlib._monitor_variable_change() {
  local new_value
  local str="new_value=\"\${${_monitored_variable_name}}\""
  #vlib.trace-yellow "DEBUG str='$str'"
  eval "$str"
  #vlib.trace-yellow "DEBUG new_value='$new_value'"
  if [[ "${new_value}" != "${__old_monitored_variable}" ]]; then
    vlib.trace-yellow "Variable '$_monitored_variable_name' changed from '${__old_monitored_variable}' to '${new_value}'"
    __old_monitored_variable="${new_value}"
  fi
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
    err_and_exit "Missing \$1 - name"
  fi
  if [ -z "$2" ]; then
    echo $usage
    # Sample: https://api.github.com/repos/longhorn/longhorn/releases
    err_and_exit "Missing \$2 - github releases url"
  fi
  if [ -z "$3" ]; then
    echo $usage
    err_and_exit "Missing \$3 - name of global variable used to return latest version"
  fi
  #set -x
  local latest
  if [ -z "$4" ]; then
    latest=$(curl -sL $2 | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0]")
  else
    latest=$(curl -sL $2 | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0]")
  fi
  eval local ver2=\"\$$3\"
  local ver=$ver2
  if ! [ -z $latest ]; then
    if [ -z "$4" ]; then
      readarray -t releases < <(curl -sL $2 | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | .[0:3]")
    else
      readarray -t releases < <(curl -sL $2 | jq -r "[ .[] | select(.prerelease == false) | .tag_name ] | sort | reverse | .[0:3]")
    fi
    if [ -z $ver ]; then 
      ver=$latest; 
      inf "Requested version of '$1' is empty. Will use '$ver' version. Latest: ${releases[*]}\n"
    else
      if ! [ "$latest" == "$ver" ]; then
        warn "Requested version of '$1' is '$ver'. Latest: ${releases[*]}\n"
      else
        inf "Requested version of '$1' is '$ver'. Latest: ${releases[*]}\n"
      fi
    fi
    eval "$3=$ver"
  else
    if [ -z $ver ]; then 
      err_and_exit "Latest version of $1 is not found. Github URL: $2"
    else
      err_and_exit "Requested version of '$1' is '$ver'. Latest version of $1 is not found. Github URL: $2"
    fi
  fi
  #set +x
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
    err_and_exit "Error: Call 'vlib.wait-for-success' without parameters"
  fi

  #echo "$#"
  #echo "$*"

  OPTIND=0
  while getopts "t:p:ov" opt
  do
    case $opt in
      t )
        wait_timeout=$OPTARG
      ;;
      p )
        wait_check_period=$OPTARG
      ;;
      o ) 
        opt_show_output='show-output-on'
      ;;
      v ) 
        verbose-on
      ;;
      * ) 
      err_and_exit "Wrong parameter '$opt'"
    esac
  done
  shift $((OPTIND-1))

  if [ -z "$1" ]; then
    echo "Function 'vlib.wait-for-success' is expecting <bash command> parameter"
    return 1
  fi

  vlib.trace "wait_timeout=$wait_timeout"
  vlib.trace-no-stack "wait_check_period=$wait_check_period"
  vlib.trace-no-stack "<bash command>='$1'"

  #set -x

  # https://linuxsimply.com/bash-scripting-tutorial/conditional-statements/if/if-command-fails/
  until eval "$1" &> /dev/null;
  do 
    #echo "<bash command> returned='$?'"
    sleep $wait_check_period
    ((wait_time+=wait_check_period))
    vlib.trace-no-stack "total wait time=$wait_time"
    if [[ $wait_time -gt $wait_timeout ]]; then
      err_and_exit "Timeout. Wait time ${wait_time} sec"
    fi
  done
}
function vlib.wait-for-error() {
  # wait for error. If timeout exit script
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
    err_and_exit "Error: Call 'vlib.wait-for-error' without parameters"
  fi

  OPTIND=0
  while getopts "est:p:ov" opt
  do
    case $opt in
      t )
        wait_timeout=$OPTARG
      ;;
      p )
        wait_check_period=$OPTARG
      ;;
      o ) 
        opt_show_output='show-output-on'
      ;;
      v ) 
        verbose-on
      ;;
      * ) 
      err_and_exit "Wrong parameter '$opt'"
    esac
  done
  shift $((OPTIND-1))

  if [ -z "$1" ]; then
    echo "Function 'vlib.wait-for-error' is expecting <bash command> parameter"
    return 1
  fi

  vlib.trace "wait_timeout=$wait_timeout"
  vlib.trace-no-stack "wait_check_period=$wait_check_period"
  vlib.trace-no-stack "<bash command>='$1'"

  #set -x

  # echo "before until" >&3
  # echo "\$1=$1" >&3
  local exit_code
  eval "$1" &> /dev/null
  exit_code=$?
  # echo "exit_code=$exit_code" >&3
  until [ $exit_code -eq 0 ]
  do 
    # echo "starting" >&3
    sleep $wait_check_period
    ((wait_time+=wait_check_period))
    eval "$1" &> /dev/null
    exit_code=$?
    # echo "wait_time=$wait_time" >&3
    # echo "exit_code=$exit_code" >&3
    vlib.trace-no-stack "total wait time=$wait_time"
    if [[ $wait_time -gt $wait_timeout ]]; then
      err_and_exit "Timeout. Wait time ${wait_time} sec"
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
function vlib.is-file-exists {
  [ -z $1 ] && err_and_exit "Function 'vlib.is-file-exists' is expecting file path parameter"
  [ -f "$1" ] || return 1
  return 0
}
function vlib.is-file-exists-with-trace {
  [ -z $1 ] && err_and_exit "Function 'vlib.is-file-exists' is expecting file path parameter"
  [ -f "$1" ] || err_and_exit "Can't find '$1' file."
  return 0
}
function vlib.is-dir-exists {
  [ -z $1 ] && err_and_exit "Function 'vlib.is-dir-exists' is expecting dir path parameter"
  [ -d "$1" ] || return 1
  return 0
}
function vlib.is-dir-exists-with-trace {
  [ -z $1 ] && err_and_exit "Function 'vlib.is-dir-exists' is expecting dir path parameter"
  [ -d "$1" ] || err_and_exit "Can't find '$1' directory."
  return 0
}
#region secret
function vlib.is-pass-dir-exists {
  ################################################################
  #     'pass' password manager
  [ -z "$1" ] && err_and_exit "Function 'vlib.is-pass-dir-exists' is expecting 'pass' password manager path parameter"
  (pass "$1" > /dev/null ) || return 1
  local _secret="$(pass "$1")"
  [ -z $_secret ] && return 1
  return 0
}
function vlib.is-pass-dir-exists-with-trace {
  ################################################################
  #     'pass' password manager
  [ -z "$1" ] && err_and_exit "Function 'vlib.is-pass-dir-exists' is expecting 'pass' password manager path parameter"
  (vlib.is-pass-dir-exists "$1") || err_and_exit "Can't find '$1' record in 'pass' password store."
  local _secret="$(pass "$1")"
  [ -z $_secret ] && return 1
  return 0
}
function vlib.secret-get-text-from-pass {
  # Usage returned_value="$(vlib.secret-get-text-from-pass pass-path)"
  [ -z "$1" ] && err_and_exit "Function 'vlib.secret-get-text-from-pass' is expecting 'pass' password manager path parameter"
  local _secret
  local _old_setting=${-//[^e]/}
  set +e
  local _error=$(pass show $1 2>&1 1>/dev/null)
  #echo "_error=$_error" >&3
  [[ ${#_error} -eq 0 ]] && _secret="$(pass show $1)"
  #echo "_secret=$_secret" >&3
  if [[ -n "$_old_setting" ]]; then set -e; fi
  [[ ${#_error} -gt 0 ]] && err_and_exit "$_error"
  echo $_secret
}
function vlib.secret-get-text-from-file {
  [ -z "$1" ] && err_and_exit "Missing \$1 parameter with path to file with secret text."
  local _secret
  local _path
  #echo "_path=$1" >&3
  eval "_path=\"$1\""
  #echo "_path=$_path" >&3
  _path=$(realpath "$_path")
  #echo "_path=$_path" >&3
  [ -a "$_path" ] || err_and_exit "Can't find file '$1' (full path: '$_path')."
  [ -d "$_path" ] && err_and_exit "Path '$1' is a directory (full path: '$_path')."
  [ -r "$_path" ] || err_and_exit "File '$1' ('$_path') exists, but not readable."
  _secret=$(<"$_path")
  [[ ${#_secret} -gt 0 ]] || err_and_exit "File '$1' ('$_path') is empty."
  echo $_secret
}
function vlib.secret-get-text {
  #  $1 - file path for secret text
  #  $2 - path of 'pass' password manager with secret text.
  if [[ -z $1 && -z $2 ]]; then
    err_and_exit "Both file path '\$1' and 'pass' password manager path '\$2' are empty. Expecting only one path."
  fi
  if [[ -n $1 && -n $2 ]]; then
    err_and_exit "Both file path '\$1' and 'pass' password manager path '\$2' are not empty. Expecting only one path."
  fi
  if [[ -n $1 ]]; then
    vlib.secret-get-text-from-file $1
  else
    vlib.secret-get-text-from-pass $2
  fi
}
#endregion secret
function vlib.exec-command {
  # Usage: vlib.exec-command ls ~
  # https://unix.stackexchange.com/questions/444946/how-can-we-run-a-command-stored-in-a-variable
  [[ $# -eq 0 ]] && err_and_exit "Function 'vlib.exec-command' is expecting 'command' parameter to try execute"
  local _old_setting=${-//[^e]/}
  set +e
  "$@"
  [[ $? -ne 0 ]] && local _failed=1
  if [[ -n "$_old_setting" ]]; then set -e; fi
  [[ $_failed -eq 1 ]] && return 1
  return 0
}
function vlib.exec-command-and-trace {
  # Execute command and print call stack on error
  [[ $# -eq 0 ]] && err_and_exit "Function 'vlib.exec-command-and-trace' is expecting 'command' parameter to try execute"
  local _old_setting=${-//[^e]/}
  set +e
  "$@"
  [[ $? -ne 0 ]] && local _failed=1
  if [[ -n "$_old_setting" ]]; then set -e; fi
  [[ $_failed -eq 1 ]] && err_and_exit "Error while executing command '$@'"
  return 0
}
