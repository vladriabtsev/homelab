#!/usr/bin/env bats
# bats tests: bats ./
# bats tests: bats vbashly.bats --filter-status failed

# https://bats-core.readthedocs.io/en/stable/tutorial.html#dealing-with-output
setup() {
  load '../../test/test_helper/bats-support/load' # this is required by bats-assert!
  load '../../test/test_helper/bats-assert/load'  
  load '../../test/test_helper/bats-file/load'  
  #load '~/bats-core/test_helper' # this is required by bats-assert!
  
  set -e # exit on error
  source /mnt/d/dev/homelab/bash-lib.sh
}
#teardown() {
  #echo "teardown"
  #rm -f /tmp/bats-tutorial-project-ran
#}

@test "./vbashly exec \"ls\"" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  run ./vbashly exec "ls"
  # https://github.com/bats-core/bats-assert#partial-matching
  echo '# text' >&3
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vbashly'
  assert_output --partial 'vbashly.bats'
  refute_output --partial 'ls'
  refute_output --partial '+['
}

@test "./vbashly --unset exec \"ls\"" {
  run ./vbashly --unset exec "ls"
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vbashly'
  assert_output --partial 'vbashly.bats'
  refute_output --partial 'ls'
  refute_output --partial '+['
}

@test "./vbashly --noexec exec \"ls\"" {
  run ./vbashly --noexec exec "ls"
  assert_success
  refute_output --partial 'src'
}

@test "./vbashly --verbose exec \"ls\"" {
  run ./vbashly --verbose exec "ls"
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vbashly'
  assert_output --partial 'vbashly.bats'
  assert_output --partial 'ls'
  refute_output --partial '+['
}

@test "./vbashly --xtrace exec \"ls\"" {
  run ./vbashly --xtrace exec "ls"
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vbashly'
  assert_output --partial 'vbashly.bats'
  assert_output --partial '] ls'
  assert_output --partial '+['
}

@test "./vbashly --log exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ./vbashly --log exec "ls"
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vbashly'
  assert_output --partial 'vbashly.bats'
  refute_output --partial 'ls'
  refute_output --partial '+['

  echo "${MY_LOG_DIR}vbashly-exec.log" >&3
  assert_file_exists "${MY_LOG_DIR}vbashly-exec.log"
}

@test "./vbashly --log kuku._log exec \"ls\" # log in MY_LOG_DIR with provided name" {
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ./vbashly --log kuku._log exec "ls"
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vbashly'
  assert_output --partial 'vbashly.bats'
  refute_output --partial 'ls'
  refute_output --partial '+['
}

@test "./vbashly --log ./kuku._log exec \"ls\" # log in current directory with provided name" {
  run ./vbashly --log ./kuku._log exec "ls"
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vbashly'
  assert_output --partial 'vbashly.bats'
  refute_output --partial 'ls'
  refute_output --partial '+['
}

@test " -127 ./vbashly exec \"unknown\"" {
  bats_require_minimum_version 1.5.0
  run -127 ./vbashly exec "unknown"
  assert_failure
  #assert_output --partial 'kuku: command not found'
  assert_output --partial 'Error occurred in'
  assert_output --partial '>>>'
  assert_output --partial 'exit_code:'
  assert_output --partial 'last_command:'
  assert_output --partial 'lines_history:'
  assert_output --partial 'function_trace'
  assert_output --partial 'source_trace'
  assert_output --partial '../../bash-lib.sh'
  assert_output --partial './vbashly'
  refute_output --partial '+['
}

@test "./vbashly" {
  run ./vbashly
  printf "$output"
  [ $status -eq 0 ]
  printf "${lines[0]}"
  # https://github.com/bats-core/bats-assert#partial-matching
  assert_success
  #assert_output --partial 'src'
  #assert_output --partial 'vbashly'
  #assert_output --partial 'vbashly.bats'
  #[ "${lines[0]}" = "Function 'wait-for-success' is expecting <bash command> parameter" ]
}
