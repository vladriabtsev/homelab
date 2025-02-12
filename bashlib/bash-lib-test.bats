#!/usr/bin/env bats
# k8s bash tests: bats ./../bashlib/bash-lib-test.bats
# https://bats-core.readthedocs.io/en/stable/installation.html#linux-distribution-package-manager
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#run-test-other-commands
# https://github.com/ztombol/bats-docs?tab=readme-ov-file#installation

setup() {
  #load '~/bats-core/test_helper/bats-support/load' # this is required by bats-assert!
  #load 'test_helper/bats-assert/load'  
  #load '~/bats-core/test_helper' # this is required by bats-assert!
  
  set -e
  source ./../bash-lib.sh

  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  echo $DIR
  # make executables in src/ visible to PATH
  PATH="$DIR/../src:$PATH"
}
#teardown() {
  #echo "teardown"
  #rm -f /tmp/bats-tutorial-project-ran
#}

@test "wait-for-success: error if without parameters" {
  run wait-for-success
  #echo "echo always" >&3
  #echo "echo on error"
  #echo "output=$output"
  #echo "status=$status"
  #echo "${lines[0]}"
  #printf "$output"
  [ "$status" -ne 0 ]
  [ "${lines[0]}" = "Error: Call 'wait-for-success' without parameters" ]
}
@test "wait-for-success: with <bash command> parameter only" {
  run wait-for-success "ls ~"
  [ "$status" -eq 0 ]
}
@test "wait-for-success: error if without <bash command> parameter" {
  run wait-for-success -p 2
  [ "$status" -ne 0 ]
  [ "${lines[0]}" = "Function 'wait-for-success' is expecting <bash command> parameter" ]
}
@test "wait-for-success: waiting for success" {
  run wait-for-success -p 2 -t 3 "ls ~"
  [ "$status" -eq 0 ]
}
@test "wait-for-success: waiting for success timeout" {
  run wait-for-success -p 2 -t 3 "not-existing-command123"
  [ "$status" -ne 0 ]
}
@test "wait-for-error: error if without parameters" {
  run wait-for-error
  [ "$status" -ne 0 ]
  [ "${lines[0]}" = "Error: Call 'wait-for-error' without parameters" ]
}
@test "wait-for-error: with <bash command> parameter only" {
  run wait-for-error "ls /kuku/kuku"
  echo "status=$status"
  [ "$status" -eq 0 ]
}
@test "wait-for-error: error if without <bash command> parameter" {
  run wait-for-error -p 2
  [ "$status" -ne 0 ]
  [ "${lines[0]}" = "Function 'wait-for-error' is expecting <bash command> parameter" ]
}
@test "wait-for-error: waiting for error" {
  run wait-for-error -p 2 -t 3 "not-existing-command123"
  [ "$status" -eq 0 ]
}
@test "wait-for-error: waiting for error timeout" {
  run wait-for-error -p 2 -t 3 "ls ~"
  [ "$status" -ne 0 ]
}
