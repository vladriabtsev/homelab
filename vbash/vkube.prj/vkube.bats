#!/usr/bin/env bats
# bats tests: bats ./
# bats tests: bats vkube.bats --filter-status failed
# bats ./ --filter-tags tag:log

# https://bats-core.readthedocs.io/en/stable/tutorial.html#dealing-with-output
setup() {
  load '../../test/test_helper/bats-support/load' # this is required by bats-assert!
  load '../../test/test_helper/bats-assert/load'  
  load '../../test/test_helper/bats-file/load'  
  #load '~/bats-core/test_helper' # this is required by bats-assert!
  
  set -e # exit on error
  source /mnt/d/dev/homelab/vlib.bash
}
#teardown() {
  #echo "teardown"
  #rm -f /tmp/bats-tutorial-project-ran
#}

@test "../vkube exec \"ls\"" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  run ../vkube exec "ls"
  # https://github.com/bats-core/bats-assert#partial-matching
  #echo '# text' >&3
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vkube'
  assert_output --partial 'vkube.bats'
  refute_output --partial 'ls'
  refute_output --partial '+['
}
@test "../vkube --unset exec \"ls\"" {
  # really not test --unset
  skip  
  run ../vkube --unset exec "ls"
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vkube'
  assert_output --partial 'vkube.bats'
  refute_output --partial 'ls'
  refute_output --partial '+['
}
@test "../vkube --noexec exec \"ls\"" {
  run ../vkube --noexec exec "ls"
  assert_success
  refute_output --partial 'src'
}
@test "../vkube --verbose exec \"ls\"" {
  run ../vkube --verbose exec "ls"
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vkube'
  assert_output --partial 'vkube.bats'
  assert_output --partial 'ls'
  refute_output --partial '+['
}
@test "../vkube --xtrace exec \"ls\"" {
  run ../vkube --xtrace exec "ls"
  assert_success
  assert_output --partial 'src'
  assert_output --partial 'vkube'
  assert_output --partial 'vkube.bats'
  assert_output --partial '] ls'
  assert_output --partial '+['
}
@test "../vkube exec \"kuku\"" {
  bats_require_minimum_version 1.5.0
  run -127 ../vkube exec "kuku"
  # https://github.com/bats-core/bats-assert#partial-matching
  #echo '# text' >&3
  assert_failure
  assert_output --partial 'kuku: command not found'
  assert_output --partial '### F A I L U R E  T R A C E ###'
  assert_output --partial 'script ../vkube exited with error code: 127'
  assert_output --partial 'error trace ../vkube:'
  assert_output --partial '>>>'
  assert_output --partial 'source trace:'
  assert_output --partial '- file: ../vkube, line:'
  assert_output --partial '### E N D   F A I L U R E   T R A C E ###'
  refute_output --partial '+['
}

@test "../vkube --log exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ../vkube --log exec "ls"

  assert_success

  assert_output --partial 'src'
  assert_output --partial 'vkube'
  assert_output --partial 'vkube.bats'
  refute_output --partial 'ls'

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube-exec.log"
  #assert_files_equal "${MY_LOG_DIR}vkube-exec.log" /path/to/file2
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'src' grep # "" grep, egrep, pcregrep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'vkube' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'vkube.bats' grep
  assert_file_not_contains "${MY_LOG_DIR}vkube-exec.log" 'ls' grep
  assert_file_not_contains "${MY_LOG_DIR}vkube-exec.log" '+[' grep
}
@test "../vkube --log --unset exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  skip
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ../vkube --log --unset exec "ls"

  assert_success

  refute_output --partial 'src'

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube-exec.log"
  assert_file_not_contains "${MY_LOG_DIR}vkube-exec.log" 'src' grep # "" grep, egrep, pcregrep
}
# bats test_tags=tag:log
@test "../vkube --log --noexec exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ../vkube --log --noexec exec "ls"

  assert_success

  refute_output --partial 'src'
  refute_output --partial 'lc'
  refute_output --partial 'eval lc'

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube-exec.log"
  assert_file_not_contains "${MY_LOG_DIR}vkube-exec.log" 'src' grep # "" grep, egrep, pcregrep
  refute_output --partial 'ls'
  refute_output --partial 'eval ls' # --xtrace
}
@test "../vkube --log --verbose exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ../vkube --log --verbose exec "ls"

  assert_success

  assert_output --partial 'src'
  assert_output --partial 'vkube'
  assert_output --partial 'vkube.bats'
  assert_output --partial 'ls'
  refute_output --partial 'eval ls' # --xtrace

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube-exec.log"
  #assert_files_equal "${MY_LOG_DIR}vkube-exec.log" /path/to/file2
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'src' grep # "" grep, egrep, pcregrep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'vkube' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'vkube.bats' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'ls' grep
  assert_file_not_contains "${MY_LOG_DIR}vkube-exec.log" 'eval ls' grep  # --xtrace
}
@test "../vkube --log --xtrace exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ../vkube --log --xtrace exec "ls"

  assert_success

  assert_output --partial 'src'
  assert_output --partial 'vkube'
  assert_output --partial 'vkube.bats'
  assert_output --partial 'ls'
  assert_output --partial 'eval ls' # --xtrace

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube-exec.log"
  #assert_files_equal "${MY_LOG_DIR}vkube-exec.log" /path/to/file2
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'src' grep # "" grep, egrep, pcregrep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'vkube' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'vkube.bats' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'ls' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'eval ls' grep  # --xtrace
}
@test "../vkube --log exec \"kuku\"" {
  bats_require_minimum_version 1.5.0
  run -127 ../vkube --log exec "kuku"
  # https://github.com/bats-core/bats-assert#partial-matching
  #echo '# text' >&3
  assert_failure
  assert_output --partial 'kuku: command not found'
  assert_output --partial '### F A I L U R E  T R A C E ###'
  assert_output --partial 'script ../vkube exited with error code: 127'
  assert_output --partial 'error trace ../vkube:'
  assert_output --partial '>>>'
  assert_output --partial 'source trace:'
  assert_output --partial '- file: ../vkube, line:'
  assert_output --partial '### E N D   F A I L U R E   T R A C E ###'
  refute_output --partial '+['

  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'kuku: command not found' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" '### F A I L U R E  T R A C E ###' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'script ../vkube exited with error code: 127' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'error trace ../vkube:' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" '>>>' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'source trace:' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" 'file: ../vkube, line:' grep
  assert_file_contains "${MY_LOG_DIR}vkube-exec.log" '### E N D   F A I L U R E   T R A C E ###' grep
  assert_file_not_contains "${MY_LOG_DIR}vkube-exec.log" '+[' grep
}

