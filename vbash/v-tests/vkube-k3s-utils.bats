#!/usr/bin/env bats
# k8s bash tests: ./bats/bin/bats ./vkube-k3s-utils.bats --filter-status failed
# k8s bash tests: ./bats/bin/bats ./vkube-k3s-utils.bats --filter-tags tag:test

setup() {
  load 'test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'  
  load 'test_helper/bats-file/load'  
  
  set -e
  source ../vlib.bash
  source ../vkube-k3s.bash

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
# setup_file() {
#   #if kubectl cluster-info; then
#     k3d cluster delete test
#   #fi
#   if ! kubectl cluster-info; then
#     k3d cluster create test --wait
#   fi
# }
#teardown_file() {
#  k3d cluster delete test
#}

# bats test_tags=tag:test
# @test "bash -s EOF failed" {
#   run vkube-k3s.get-pod-image-version << EOF
# kuku
# EOF
#   echo "output=$output"
#   assert_failure
#   assert_output --partial "kuku: command not found"
#   refute_output --partial "delimited by end-of-file"
# }
# @test "bash -s EOF failed" {
#   bats_require_minimum_version 1.5.0
#   run -127 bash -s << EOF
# kuku
# EOF
#   echo "output=$output"
#   assert_failure
#   assert_output --partial "kuku: command not found"
#   refute_output --partial "delimited by end-of-file"
# }
