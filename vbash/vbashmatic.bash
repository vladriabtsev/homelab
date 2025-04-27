#!/usr/bin/env bash

# overrides for bashmatic
run.ui.ask() {
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
    info "${bldblu}Yes is selected."
    #info "Let's just hope it won't go nuclear on us :) 💥"
    hr
    echo
  else
    info "${bldred}Abort is selected!  🛳  " >&2
    hr >&2
    exit
    #echo
    #eval "${func} 1"
  fi
}

