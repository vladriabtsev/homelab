# ./bats/bin/bats ./bash.bats
# ./bats/bin/bats ./bash.bats --filter-tags tag:test

setup() {
  load 'test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'  
  load 'test_helper/bats-file/load'  
  
  set -e
  source ../vlib.bash

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

function function-with-associative-array() {
  declare -A array=()
  array["one"]="one value"
  test="[ "${#array[@]}" == "1" ]"
  echo "${test}" && eval "${test}" || exit 1
  test="[ "${!array[@]}" == "one" ]"
  echo "${test}" && eval "${test}" || exit 1
  test="[ "${array[@]}" == "one value" ]"
  echo "${test}" && eval "${test}" || exit 1
  test="[ "${array[one]}" == "one value" ]"
  echo "${test}" && eval "${test}" || exit 1
  test="[ "${array["one"]}" == "one value" ]"
  echo "${test}" && eval "${test}" || exit 1
  two="two"
  array["two"]="two value"
  test="[ "${#array[@]}" == "2" ]"
  echo "${test}" && eval "${test}" || exit 1
  test="[ "${array[two]}" == "two value" ]"
  echo "${test}" && eval "${test}" || exit 1
  test="[ "${array[$two]}" == "two value" ]"
  echo "${test}" && eval "${test}" || exit 1
}
# TODO remove dependency on password user entry
# bats test_tags=tag:test
@test "associative array" {
  declare -A array=()
  array["one"]="one value"
  [ "${#array[@]}" == "1" ]
  [ "${!array[@]}" == "one" ]
  [ "${array[@]}" == "one value" ]
  [ "${array[one]}" == "one value" ]
  [ "${array["one"]}" == "one value" ]
  [ "${array[kuku]}" != "one value" ]
  if ! [[ -v array[one] ]]; then
    fail 'if [[ -v array[one] ]] - fail'
  fi
  two="two"
  array["two"]="two value"
  [ "${#array[@]}" == "2" ]
  [ "${array[two]}" == "two value" ]
  [ "${array[$two]}" == "two value" ]
  [ "${array[${two}]}" == "two value" ]
  [ "${array["${two}"]}" == "two value" ]
  if ! [[ -v array[one] ]]; then
    fail 'if [[ -v array[one] ]] - fail'
  fi
  if [[ -v array[kuku] ]]; then
    fail 'if [[ -v array[kuku] ]] - fail'
  fi
  if ! [[ -v array[two] ]]; then
    fail 'if [[ -v array[two] ]] - fail'
  fi
  if ! [[ -v array["${two}"] ]]; then
    fail 'if [[ -v array[two] ]] - fail'
  fi
  run function-with-associative-array
  assert_success
}

# https://kodekloud.com/blog/return-value-from-bash-function/
function return-result-to-stream() {
  # $1 variable name
  local ret="func result"
  echo "${ret}"
}
@test "return from function to stream" {
  run return-result-to-stream
  assert_success
  assert_output "func result"
  [ "$output" == "func result" ]
  returned_value="$(return-result-to-stream)"
  [ "$returned_value" == "func result" ]
}
function return-result-to-global-variable() {
  # $1 variable name
  __return_result_to_global_variable='func result'
}
@test "return from function to global variable" {
  skip "is not working. Bats problem???"
  __return_result_to_global_variable="initial"
  run return-result-to-global-variable
  assert_success
  echo "__return_result_to_global_variable=$__return_result_to_global_variable" >&3
  [ "$__return_result_to_global_variable" == "func result" ]
}
function return-result-to-global-variable() {
  # $1 variable name
  eval "$1='func result'"
  eval local ver2=\"\$$1\"
  echo "$1='$ver2'" >&3
  echo "__global_variable_for_result inside function '$__global_variable_for_result'" >&3
}
@test "return from function to global variable2" {
  skip "is not working. Bats problem???"
  __global_variable_for_result="initial"
  run return-result-to-global-variable __global_variable_for_result
  assert_success
  echo "__global_variable_for_result outside function '$__global_variable_for_result'" >&3
  [ "$__global_variable_for_result" == "func result" ]
}


@test "bash -s EOF" {
  run bash -s << EOF
echo test
EOF
  assert_success
  assert_output "test"
  refute_output --partial "delimited by end-of-file"
}
@test "bash -s EOF failed" {
  bats_require_minimum_version 1.5.0
  run -127 bash -s << EOF
kuku
EOF
  echo "output=$output"
  assert_failure
  assert_output --partial "kuku: command not found"
  refute_output --partial "delimited by end-of-file"
}
@test "ssh k3s1 ls" {
  run ssh k3s1 ls
  assert_success
  refute_output --partial "delimited by end-of-file"
}
# https://thornelabs.net/posts/remotely-execute-multi-line-commands-with-ssh/
@test "ssh k3s1 EOF success" {
  run ssh k3s1 << EOF
echo test
EOF
  assert_success
  refute_output --partial "delimited by end-of-file"
}
@test "ssh k3s1 EOF failed" {
  bats_require_minimum_version 1.5.0
  run -127 ssh k3s1 << EOF
kuku
EOF
  echo "output=$output"
  assert_failure
  assert_output --partial "kuku: command not found"
  refute_output --partial "delimited by end-of-file"
}
# https://stackoverflow.com/questions/10310299/what-is-the-proper-way-to-sudo-over-ssh
# /etc/sudoers: user ALL=(ALL) NOPASSWD: ALL
@test "ssh k3s1 EOF sudo" {
  run ssh k3s1 << EOF
sudo ls
EOF
  assert_success
  refute_output --partial "delimited by end-of-file"
}
@test "ssh k3s1 EOF sudo failed" {
  run ssh k3s1 << EOF
sudo kuku
EOF
  echo "output=$output"
  assert_failure
  assert_output --partial "kuku: command not found"
  refute_output --partial "delimited by end-of-file"
}
