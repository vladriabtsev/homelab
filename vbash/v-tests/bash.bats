# bats ./bash.bats

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
