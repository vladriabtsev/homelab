#!/usr/bin/env bash

# overrides for bashmatic
function .run.exec() {
  local command="$*"

  if ((INSPECT)) || [[ -n ${BASHMATIC_DEBUG} && ${LibRun__Verbose} -eq ${True} ]]; then
    run.inspect
  fi

  local __Previous__ShowCommandOutput=${LibRun__ShowCommandOutput}
  set +e
  local ts_start
  ts_start=$(millis)

  local tries=1

  .run.eval "${run_stdout}" "${run_stderr}" "${command}"

  while [[ -n ${LibRun__LastExitCode} && ${LibRun__LastExitCode} -ne 0 ]] &&
    [[ -n ${LibRun__RetryCount} && ${LibRun__RetryCount} -gt 0 ]]; do

    [[ ${tries} -gt 1 && ${__Previous__ShowCommandOutput} -eq ${True} ]] &&
      export LibRun__ShowCommandOutput=${False}

    .run.retry.enforce-max

    export LibRun__RetryCount="$((LibRun__RetryCount - 1))"
    [[ -n ${LibRun__RetrySleep} ]] && sleep "${LibRun__RetrySleep}"

    info "warning: command exited with code ${bldred}${LibRun__LastExitCode}" \
      "$(txt-info)and ${LibRun__RetryCount} retries left."

    .run.eval "${run_stdout}" "${run_stderr}" "${command}"

    tries=$((tries + 1))
  done

  local ts_end=$(millis)
  local duration=$(ruby -e "puts ${ts_end} - ${ts_start}")

  export LibRun__ShowCommandOutput=${__Previous__ShowCommandOutput}

  if [[ ${LibRun__LastExitCode} -eq 0 ]]; then
    run.post-command-with-output "${duration}"
    ui.closer.ok
    commands_completed=$((commands_completed + 1))
    echo
  else
    run.post-command-with-output "${duration}"
    ui.closer.not-ok
    echo
    local stderr_printed=false
    # Print stderr generated during command execution.
    [[ ${LibRun__ShowCommandOutput} -eq ${False} && -s ${run_stderr} ]] && {
      stderr_printed=true
      echo && stderr ${run_stderr}
    }

    if [[ ${LibRun__AskOnError} -eq ${True} ]]; then
      run.ui.ask 'Ignore this error and continue?'

    elif [[ ${LibRun__AbortOnError} -eq ${True} ]]; then
      export commands_failed=$((commands_failed + 1))
      error "Aborting, due to 'abort on error' being set to true."
      info "Failed command: ${bldylw}${command}"
      #echo

      vlib.call-trace 3
      echo

      [[ -s ${run_stdout} ]] && {
        echo && stdout ${run_stdout}
      }

      ${stderr_printed} || [[ -s ${run_stderr} ]] && {
        echo && stderr ${run_stderr}
      }

      printf "${clr}\n"
      exit ${LibRun__LastExitCode}
    else
      export commands_ignored=$((commands_ignored + 1))
    fi
  fi

  .run.initializer
  .run.cleanup

  printf "${clr}"
  return ${LibRun__LastExitCode}
}
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

