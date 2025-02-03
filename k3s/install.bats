#!/usr/bin/env bats
# bash lib tests
# https://bats-core.readthedocs.io/en/stable/installation.html#linux-distribution-package-manager

setup() {
  load '~/bats-core/test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'  
  source ./install-lib.sh
  if [ "${BATS_TEST_NUMBER}" = 1 ];then
      echo "# --- TEST NAME IS $(basename ${BATS_TEST_FILENAME})" >&3
  fi    
  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  echo $DIR
  # make executables in src/ visible to PATH
  PATH="$DIR/../src:$PATH"
}
teardown() {
  echo "teardown"
  #rm -f /tmp/bats-tutorial-project-ran
}

@test "wait until command execution first error" {
  result=wait_for_condition -h -e true "ls /kuku"
  run echo kuku
  echo "$result"
  print "printf kuku"
  #run echo test failed
  #assert_output "test"
  [ "$result" -eq 0 ]
}

@test "addition using bc" {
  result="$(echo 2+2 | bc)"
  [ "$result" -eq 4 ]
}

@test "addition using dc" {
  result="$(echo 2 2+p | dc)"
  [ "$result" -eq 4 ]
}
