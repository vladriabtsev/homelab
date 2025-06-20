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

#bats test_tags=tag:secret
@test "vkube-k3s.secret-create: without namespace" {
  run vkube-k3s.secret-create
  #echo "output=$output"
  assert_failure
  assert_output --partial "Missing namespace \$1 parameter"
  assert_output --partial "## C A L L   T R A C E ##"
}
#bats test_tags=tag:secret
@test "vkube-k3s.secret-create: without secret name" {
  run vkube-k3s.secret-create test
  #echo "output=$output"
  assert_failure
  assert_output --partial "Missing secret name \$2 parameter"
  assert_output --partial "## C A L L   T R A C E ##"
}
#bats test_tags=tag:secret
@test "vkube-k3s.secret-create: without secret folder" {
  run vkube-k3s.secret-create test test-secret
  #echo "output=$output"
  assert_failure
  assert_output --partial "Missing secret folder path \$3 parameter"
  assert_output --partial "## C A L L   T R A C E ##"
}
#bats test_tags=tag:secret
@test "vkube-k3s.secret-create: from not existing path in 'pass' password store" {
  run vkube-k3s.secret-create test test-secret not-existing-store-folder
  #echo "output=$output" >&3
  assert_failure
  assert_output --partial "Can't find 'not-existing-store-folder/username.txt' record in 'pass' password store"
  assert_output --partial "## C A L L   T R A C E ##"
}
#bats test_tags=tag:secret
@test "vkube-k3s.secret-create: from path in 'pass' password store" {
  # Required:
  # pass insert test/username.txt # enter password 'test-user'
  # pass insert test/password.txt # enter password 'test-password'
  run vkube-k3s.secret-create test test-secret test
  #echo "output=$output" >&3
  assert_success
}

#bats test_tags=tag:secret
@test "vkube-k3s.secret-create: from not existing disk folder" {
  run vkube-k3s.secret-create test test-secret ~/.test-not-exists
  #echo "output=$output" >&3
  assert_failure
  assert_output --partial "Can't find folder '/home/vlad/.test-not-exists'"
  assert_output --partial "## C A L L   T R A C E ##"
}
#bats test_tags=tag:secret
@test "vkube-k3s.secret-create: from empty disk folder" {
  run vkube-k3s.secret-create test test-secret ~
  #echo "output=$output" >&3
  assert_failure
  assert_output --partial "Can't find user name file"
  assert_output --partial "## C A L L   T R A C E ##"
}
#bats test_tags=tag:secret
@test "vkube-k3s.secret-create: from disk folder with username and password" {
  # Required:
  # ~/.test/username.txt # with line 'username=test-user'
  # ~/.test/password.txt # with line 'password=test-password'
  run vkube-k3s.secret-create test test-secret ~/.test
  #echo "output=$output" >&3
  assert_success
}
