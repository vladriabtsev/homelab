#!/usr/bin/env bats
# k8s bash tests: bats ./../bash-bats/bash-lib-test.bats --filter-status failed
# k8s bash tests: bats ./../bash-bats/bash-lib-test.bats --filter-tags tag:yaml
# https://bats-core.readthedocs.io/en/stable/installation.html#linux-distribution-package-manager
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#run-test-other-commands
# https://github.com/ztombol/bats-docs?tab=readme-ov-file#installation

setup() {
  #load '~/bats-core/test_helper/bats-support/load' # this is required by bats-assert!
  #load 'test_helper/bats-assert/load'  
  #load '~/bats-core/test_helper' # this is required by bats-assert!
  
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

# bats test_tags=tag:patch
@test "json: node patch" {
  local node_patch='{"metadata":{"annotations":{"node.longhorn.io":{"default-disks-config":[]}}}}'
  echo $node_patch
  echo $node_patch | jq --compact-output
  echo $node_patch | jq --compact-output '
    .metadata.annotations.["node.longhorn.io"].default-disks-config += ["kuku0"]
  '
  storageClass="$(curl https://raw.githubusercontent.com/longhorn/longhorn/v1.7.3/examples/storageclass.yaml)"
  [ ${#storageClass} -eq 0 ]
  [ ${#storageClass} -gt 10 ]
}
@test "text: count lines" {
  local txt="first line
second line
third line"
  #echo "$txt"
  #local cnt=$(echo "$txt" | grep -c "\n")
  local cnt=$(echo "$txt" | wc -l)
  #echo "$cnt"
  [ $cnt -eq 3 ]
}
@test "text: delete 'second line'" {
  local txt="first line
second line
third line"
  local txt2=$(echo "$txt" | sed '/second/d')
  #echo "$txt2"
  local cnt=$(echo "$txt2" | wc -l)
  [ $cnt -eq 2 ]
}
@test "text: delete two 'second line'" {
  local txt="first line
second line
second line
third line"
  local txt2=$(echo "$txt" | sed '/second/d')
  echo "$txt2"
  local cnt=$(echo "$txt2" | wc -l)
  [ $cnt -eq 2 ]
}
@test "text: delete 'second 99bb8649-3ded-404d-ad68-ce454262dfbb'" {
  local txt="first 2c30133e-3ab3-4171-bc9d-73bb9a50df3b
second 99bb8649-3ded-404d-ad68-ce454262dfbb
third ef31bf5a-97d4-4701-bc8d-12fc06ffc95d"
  local txt2=$(echo "$txt" | sed '/99bb8649-3ded-404d-ad68-ce454262dfbb/d')
  echo "$txt2"
  local cnt=$(echo "$txt2" | wc -l)
  [ $cnt -eq 2 ]
}
@test "wait-for-success: error if without parameters" {
  run vlib.wait-for-success
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
  run vlib.wait-for-success "ls ~"
  [ "$status" -eq 0 ]
}
@test "wait-for-success: error if without <bash command> parameter" {
  run vlib.wait-for-success -p 2
  [ "$status" -ne 0 ]
  [ "${lines[0]}" = "Function 'wait-for-success' is expecting <bash command> parameter" ]
}
@test "wait-for-success: waiting for success" {
  run vlib.wait-for-success -p 2 -t 3 "ls ~"
  [ "$status" -eq 0 ]
}
@test "wait-for-success: waiting for success timeout" {
  run vlib.wait-for-success -p 2 -t 3 "not-existing-command123"
  [ "$status" -ne 0 ]
}
@test "wait-for-error: error if without parameters" {
  run vlib.wait-for-error
  [ "$status" -ne 0 ]
  [ "${lines[0]}" = "Error: Call 'wait-for-error' without parameters" ]
}
@test "wait-for-error: with <bash command> parameter only" {
  run vlib.wait-for-error "ls /kuku/kuku"
  echo "status=$status"
  [ "$status" -eq 0 ]
}
@test "wait-for-error: error if without <bash command> parameter" {
  run vlib.wait-for-error -p 2
  [ "$status" -ne 0 ]
  [ "${lines[0]}" = "Function 'wait-for-error' is expecting <bash command> parameter" ]
}
@test "wait-for-error: waiting for error" {
  run vlib.wait-for-error -p 2 -t 3 "not-existing-command123"
  [ "$status" -eq 0 ]
}
@test "wait-for-error: waiting for error timeout" {
  run vlib.wait-for-error -p 2 -t 3 "ls ~"
  [ "$status" -ne 0 ]
}
