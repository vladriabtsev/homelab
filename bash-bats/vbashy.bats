#!/usr/bin/env bats
# k8s bash tests: bats ./../bash-bats/vbashly.bats --filter-status failed

setup() {
  #load '~/bats-core/test_helper/bats-support/load' # this is required by bats-assert!
  #load 'test_helper/bats-assert/load'  
  #load '~/bats-core/test_helper' # this is required by bats-assert!
  
  set -e # exit on error
  source /mnt/d/dev/homelab/bash-lib.sh

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

@test "vbashly ls" {
  run wait-for-success -p 2
  [ "$status" -ne 0 ]
  [ "${lines[0]}" = "Function 'wait-for-success' is expecting <bash command> parameter" ]
}
