# ./bats/bin/bats ./vlib-script-init.bats
setup() {
  load 'test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'  
  load 'test_helper/bats-file/load'  
  
  set -e
  source ../vlib.bash

#   # get the containing directory of this file
#   # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
#   # as those will point to the bats executable's location or the preprocessed file respectively
#   DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
#   echo $DIR
#   # make executables in src/ visible to PATH
#   PATH="$DIR/../src:$PATH"
}
#teardown() {
  #echo "teardown"
  #rm -f /tmp/bats-tutorial-project-ran
#}

@test "./script-1.sh 0" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  run ./script-1.sh 0
  assert_success
  #echo '# text' >&3
  #echo "# output=$output" >&3

  [ "${lines[0]}" = "script-1" ]
  [ "${lines[1]}" = "script-2" ]
  [ "${lines[2]}" = "script-3" ]
}
@test "./script-1-subshell.sh 0" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  run ./script-1-subshell.sh 0
  assert_success
  #echo '# text' >&3
  #echo "# output=$output" >&3

  [ "${lines[0]}" = "script-1" ]
  [ "${lines[1]}" = "script-2" ]
  [ "${lines[2]}" = "script-3" ]
}
@test "./script-1.sh 1" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  bats_require_minimum_version 1.5.0
  run -127 ./script-1.sh 1
  # https://github.com/bats-core/bats-assert#partial-matching
  assert_failure

  #echo "# output=$output" >&3

  assert_output --partial 'script ./script-1.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-1.sh:'
  assert_output --partial '>>>[[ "$1" == "1" ]] && unknown-command'
  assert_output --partial 'source trace:'
  assert_output --partial ' - file: ./script-1.sh, line: 12, func: main, command: unknown-command'
}
@test "./script-1-subshell.sh 1" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  bats_require_minimum_version 1.5.0
  run -127 ./script-1-subshell.sh 1
  # https://github.com/bats-core/bats-assert#partial-matching
  assert_failure

  #echo "# output=$output" >&3

  assert_output --partial 'script ./script-1-subshell.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-1-subshell.sh:'
  assert_output --partial '>>>[[ "$1" == "1" ]] && unknown-command'
  assert_output --partial 'source trace:'
  assert_output --partial ' - file: ./script-1-subshell.sh, line: 12, func: main, command: unknown-command'
}
@test "./script-1.sh 2" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  bats_require_minimum_version 1.5.0
  run -127 ./script-1.sh 2
  # https://github.com/bats-core/bats-assert#partial-matching
  assert_failure

  # assert_output "script-1"
  # assert_output "script-2"
  # refute_output "script-3"

  assert_output --partial 'script ./script-2.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-2.sh:'
  assert_output --partial '>>>[[ "$1" == "2" ]] && unknown-command'
  assert_output --partial 'source trace:'
  assert_output --partial ' - file: ./script-2.sh, line: 12, func: main, command: unknown-command'

  assert_output --partial 'script ./script-1.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-1.sh:'
  assert_output --partial '>>>./script-2.sh $1'
  assert_output --partial ' - file: ./script-1.sh, line: 13, func: main, command: ./script-2.sh $1'
}
@test "./script-1-subshell.sh 2" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  bats_require_minimum_version 1.5.0
  run -127 ./script-1-subshell.sh 2
  # https://github.com/bats-core/bats-assert#partial-matching
  assert_failure

  # assert_output "script-1"
  # assert_output "script-2"
  # refute_output "script-3"

  assert_output --partial 'script ./script-2.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-2.sh:'
  assert_output --partial '>>>[[ "$1" == "2" ]] && unknown-command'
  assert_output --partial 'source trace:'
  assert_output --partial ' - file: ./script-2.sh, line: 12, func: main, command: unknown-command'

  assert_output --partial 'script ./script-1-subshell.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-1-subshell.sh:'
  assert_output --partial '>>>./script-2.sh $1'
  assert_output --partial ' - file: ./script-1-subshell.sh, line: 13, func: main, command: ./script-2.sh $1'
}
@test "./script-1.sh 3" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  bats_require_minimum_version 1.5.0
  run -127 ./script-1.sh 3
  # https://github.com/bats-core/bats-assert#partial-matching
  assert_failure

  assert_output --partial 'script ./script-3.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-3.sh:'
  assert_output --partial '>>>[[ "$1" == "3" ]] && unknown-command'
  assert_output --partial 'source trace:'
  assert_output --partial ' - file: ./script-3.sh, line: 12, func: main, command: unknown-command'

  assert_output --partial 'script ./script-2.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-2.sh:'
  assert_output --partial '>>>./script-3.sh $1'
  assert_output --partial ' - file: ./script-2.sh, line: 13, func: main, command: ./script-3.sh $1'

  assert_output --partial 'script ./script-1.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-1.sh:'
  assert_output --partial '>>>./script-2.sh $1'
  assert_output --partial ' - file: ./script-1.sh, line: 13, func: main, command: ./script-2.sh $1'
}
@test "./script-lib.sh 0" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  run ./script-lib.sh 0
  assert_success
  #echo '# text' >&3
}
@test "./script-lib.sh 1" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  bats_require_minimum_version 1.5.0
  run -127 ./script-lib.sh 1
  # https://github.com/bats-core/bats-assert#partial-matching
  assert_failure

  assert_output --partial 'script ./script-lib.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-lib-1.bash:'
  assert_output --partial '>>>  [[ "$1" == "1" ]] && unknown-command'
  assert_output --partial 'source trace:'
  assert_output --partial ' - file: ./script-lib-1.bash, line: 9, func: script-1-exec, command: unknown-command'
  assert_output --partial ' - file: ./script-lib.sh, line: 16, func: main, command: script-1-exec'
}
@test "./script-lib.sh 2" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  bats_require_minimum_version 1.5.0
  run -127 ./script-lib.sh 2
  # https://github.com/bats-core/bats-assert#partial-matching
  assert_failure

  assert_output --partial 'script ./script-lib.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-lib-2.bash:'
  assert_output --partial '>>>  [[ "$1" == "2" ]] && unknown-command'
  assert_output --partial 'source trace:'
  assert_output --partial ' - file: ./script-lib-2.bash, line: 9, func: script-2-exec, command: unknown-command'
  assert_output --partial ' - file: ./script-lib-1.bash, line: 10, func: script-1-exec, command: script-2-exec'
  assert_output --partial ' - file: ./script-lib.sh, line: 16, func: main, command: script-1-exec'
}
@test "./script-lib.sh 3" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  bats_require_minimum_version 1.5.0
  run -127 ./script-lib.sh 3
  # https://github.com/bats-core/bats-assert#partial-matching
  assert_failure

  assert_output --partial 'script ./script-lib.sh exited with error code: 127'
  assert_output --partial 'error trace ./script-lib-3.bash:'
  assert_output --partial '>>>  [[ "$1" == "3" ]] && unknown-command'
  assert_output --partial 'source trace:'
  assert_output --partial ' - file: ./script-lib-3.bash, line: 6, func: script-3-exec, command: unknown-command'
  assert_output --partial ' - file: ./script-lib-2.bash, line: 10, func: script-2-exec, command: script-3-exec'
  assert_output --partial ' - file: ./script-lib-1.bash, line: 10, func: script-1-exec, command: script-2-exec'
  assert_output --partial ' - file: ./script-lib.sh, line: 16, func: main, command: script-1-exec'
}
