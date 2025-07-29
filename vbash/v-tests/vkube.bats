#!/usr/bin/env bats
# bats tests: ./bats/bin/bats ./
# bats tests: ./bats/bin/bats vkube.bats --filter-status failed
# ./bats/bin/bats ./vkube.bats --filter-tags tag:log

# https://bats-core.readthedocs.io/en/stable/tutorial.html#dealing-with-output
setup() {
  load 'test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'  
  load 'test_helper/bats-file/load'  
  load 'test_helper/bats-detik/lib/utils'  
  load 'test_helper/bats-detik/lib/detik'
  
  DETIK_CLIENT_NAME="kubectl" 

  set -e # exit on error
  source ../vkube-lib.bash
  
  # if [ -z "$SSH_AUTH_SOCK" ]; then
  #   eval "$(ssh-agent -s)" # start ssh agent
  #   ssh-add ~/.ssh/id_rsa
  # fi
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
  assert_output --partial 'vlib.bats'
}
@test "../vkube --unset exec \"ls\"" {
  # really not test --unset
  skip  "????"
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
  refute_output --partial 'vlib.bats'
  refute_output --partial '+['
}
@test "../vkube --verbose exec \"ls\"" {
  run ../vkube --verbose exec "ls"
  assert_success
  assert_output --partial 'ls'
  assert_output --partial 'vlib.bats'
  refute_output --partial '+['
}
@test "../vkube --xtrace exec \"ls\"" {
  run ../vkube --xtrace exec "ls"
  assert_success
  assert_output --partial 'vlib.bats'
  assert_output --partial '+ eval ls'
  assert_output --partial '++ ls'
}
@test "../vkube exec \"kuku\"" {
  bats_require_minimum_version 1.5.0
  run -127 ../vkube exec "kuku"
  # https://github.com/bats-core/bats-assert#partial-matching
  #echo '# text' >&3
  assert_failure
  assert_output --partial 'kuku: command not found'
}

@test "../vkube --log exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  [ -n "$MY_LOG_DIR" ]
  assert_dir_exists "$MY_LOG_DIR"
  run ../vkube --log exec "ls"

  assert_success

  assert_output --partial 'vlib.bats'

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube_exec_command.log"
  #assert_files_equal "${MY_LOG_DIR}vkube-exec.log" /path/to/file2
  assert_file_contains "${MY_LOG_DIR}vkube_exec_command.log" 'vlib.bats' grep # "" grep, egrep, pcregrep
}
@test "../vkube --log --unset exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  skip
  [ -n "$MY_LOG_DIR" ]
  assert_dir_exists "$MY_LOG_DIR"
  run ../vkube --log --unset exec "ls"

  assert_success

  refute_output --partial 'vlib.bats'

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube_exec_command.log"
  assert_file_not_contains "${MY_LOG_DIR}vkube_exec_command.log" 'vlib.bats' grep # "" grep, egrep, pcregrep
}
# bats test_tags=tag:log
@test "../vkube --log --noexec exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ../vkube --log --noexec exec "ls"

  assert_success

  refute_output --partial 'vlib.bats'
  refute_output --partial 'lc'
  refute_output --partial 'eval lc'

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube_exec_command.log"
  assert_file_not_contains "${MY_LOG_DIR}vkube_exec_command.log" 'src' grep # "" grep, egrep, pcregrep
  refute_output --partial 'ls'
  refute_output --partial 'eval ls' # --xtrace
}
@test "../vkube --log --verbose exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ../vkube --log --verbose exec "ls"

  assert_success

  assert_output --partial 'ls'
  assert_output --partial 'vlib.bats'
  refute_output --partial 'eval ls' # --xtrace

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube_exec_command.log"
  #assert_files_equal "${MY_LOG_DIR}vkube-exec.log" /path/to/file2
  assert_file_contains "${MY_LOG_DIR}vkube_exec_command.log" 'vlib.bats' grep # "" grep, egrep, pcregrep
  assert_file_contains "${MY_LOG_DIR}vkube_exec_command.log" 'ls' grep
  assert_file_not_contains "${MY_LOG_DIR}vkube_exec_command.log" 'eval ls' grep  # --xtrace
}
@test "../vkube --log --xtrace exec \"ls\" # log in MY_LOG_DIR with auto generated name" {
  [ ! -z $MY_LOG_DIR ]
  assert_dir_exists $MY_LOG_DIR
  run ../vkube --log --xtrace exec "ls"

  assert_success

  assert_output --partial '+ eval ls' # --xtrace
  assert_output --partial '++ ls'
  assert_output --partial 'vlib.bats'

  #echo "${MY_LOG_DIR}vkube-exec.log" >&3
  # https://github.com/bats-core/bats-file
  assert_file_exists "${MY_LOG_DIR}vkube_exec_command.log"
  #assert_files_equal "${MY_LOG_DIR}vkube-exec.log" /path/to/file2
  assert_file_contains "${MY_LOG_DIR}vkube_exec_command.log" 'vlib.bats' grep # "" grep, egrep, pcregrep
  assert_file_contains "${MY_LOG_DIR}vkube_exec_command.log" 'ls' grep
  assert_file_contains "${MY_LOG_DIR}vkube_exec_command.log" 'eval ls' grep  # --xtrace
}
@test "../vkube --log exec \"kuku\"" {
  bats_require_minimum_version 1.5.0
  run -127 ../vkube --log exec "kuku"
  # https://github.com/bats-core/bats-assert#partial-matching
  #echo '# text' >&3
  assert_failure
  assert_output --partial 'kuku: command not found'
  refute_output --partial '+['

  assert_file_contains "${MY_LOG_DIR}vkube_exec_command.log" 'kuku: command not found' grep
  assert_file_not_contains "${MY_LOG_DIR}vkube_exec_command.log" '+[' grep
}

#region apps

  # bats test_tags=tag:busybox
  @test "Can't app command without subcommand" {
    run ../vkube --trace --cluster-plan k3d-test app
    assert_failure
    #echo "output=$output" >&3
    assert_output --partial 'Usage:'
  }
  # bats test_tags=tag:busybox
  @test "Can't app install command without subcommand" {
    run ../vkube --trace --cluster-plan k3d-test app install
    assert_failure
    #echo "output=$output" >&3
    assert_output --partial 'Usage:'
  }
  # bats test_tags=tag:busybox
  @test "Can't app install busybox with storage class, but without mounting point" {
    run ../vkube --trace --cluster-plan k3d-test app install busybox -c local-path
    assert_failure
    #echo "output=$output" >&3
    assert_output --partial 'Expecting equal amount'
  }
  # bats test_tags=tag:busybox
  @test "Can't app install busybox with mounting point, but without storage class" {
    run ../vkube --trace --cluster-plan k3d-test app install busybox -m /mnt/local-path
    assert_failure
    #echo "output=$output" >&3
    assert_output --partial 'Expecting equal amount'
  }
  # bats test_tags=tag:busybox
  @test "Can't app install busybox with unknown storage class" {
    run ../vkube --trace --cluster-plan k3d-test app install busybox -c unknown-storage-class -m /mnt/local-path
    assert_failure
    #echo "output=$output" >&3
    assert_output --partial "Storage class 'unknown-storage-class' is not found in cluster"
  }
  # bats test_tags=tag:busybox
  @test "Can app install busybox without storage class" {
    run ../vkube --trace --cluster-plan k3d-test app install busybox
    assert_success
    #echo "output=$output" >&3

    DETIK_CLIENT_NAMESPACE="default"
    sleep 10
    # echo '         Verify there are 1 pods named ^busybox' >&3
    # run verify "there are 1 pods named '^busybox'"
    # assert_success

    #echo '         Verify that status is running' >&3
    run try "at most 10 times every 5s to get pods named '^busybox' and verify that 'status' is 'running'"
    assert_success
  }
  # bats test_tags=tag:busybox
  @test "Can't app install busybox in same namespace twice" {
    run ../vkube --trace --cluster-plan k3d-test app install busybox
    assert_failure
    #echo "output=$output" >&3
  }
  # bats test_tags=tag:busybox
  @test "Can uninstall deployment busybox" {
    run ../vkube --trace --cluster-plan k3d-test app uninstall deployment busybox
    assert_success
    #echo "output=$output" >&3

    DETIK_CLIENT_NAMESPACE="default"
    sleep 10
    #echo '         Verify there are 0 pods named ^busybox' >&3
    run verify "there are 1 pods named '^busybox'"
    assert_success

    # test namespace is deleted
    run vkube-lib.is-namespace-exist "default"
    [ "$status" -eq 0 ]
  }
  # bats test_tags=tag:busybox
  @test "Can app install busybox with storage class and in specified namespace" {
    run ../vkube --trace --cluster-plan k3d-test app -n busybox-test-namespace install busybox -c local-path -m /mnt/local-path
    assert_success
    #echo "output=$output" >&3

    # test is started in appropriate namespace
  }
  # bats test_tags=tag:busybox
  @test "Can't uninstall not installed deployment in empty namespace" {
    run ../vkube --trace --cluster-plan k3d-test app uninstall deployment busybox
    assert_failure
    #echo "output=$output" >&3

    # test uninstall with namespace deletion
  }
  # bats test_tags=tag:busybox
  @test "Can uninstall busybox with storage class and in specified namespace" {
    run ../vkube --trace --cluster-plan k3d-test app -n busybox-test-namespace uninstall deployment busybox
    assert_success
    #echo "output=$output" >&3

    # test uninstall with namespace deletion
  }
  # bats test_tags=tag:alpine
  @test "Can deploy general container in custom namespace" {
    run ../vkube --trace --cluster-plan k3d-test app -n alpine install general alpine
    sleep 10
    assert_success
    #echo "output=$output" >&3

    DETIK_CLIENT_NAMESPACE="alpine"
    sleep 10
    #echo '         Verify there is 1 deployment named ^alpine' >&3
    run verify "there are 1 deployment named '^alpine'"
    assert_success

    #echo '         Verify that status is running' >&3
    run try "at most 10 times every 5s to get pods named '^alpine' and verify that 'status' is 'running'"
    assert_success

    run vkube-lib.is-namespace-exist "alpine"
    [ "$status" -eq 0 ]
  }
  # bats test_tags=tag:alpine
  @test "Can deploy general container with custom deployment name in custom namespace" {
    run ../vkube --trace --cluster-plan k3d-test app -n alpine install general --deployment alpine2 alpine
    sleep 10
    assert_success
    #echo "output=$output" >&3

    DETIK_CLIENT_NAMESPACE="alpine"
    sleep 10
    #echo '         Verify there is 1 deployment named ^alpine2' >&3
    run verify "there are 1 deployment named '^alpine2'"
    assert_success

    #echo '         Verify that status is running' >&3
    run try "at most 10 times every 5s to get pods named '^alpine2' and verify that 'status' is 'running'"
    assert_success

    run vkube-lib.is-namespace-exist "alpine"
    [ "$status" -eq 0 ]
  }
  # bats test_tags=tag:alpine
  @test "Can uninstall deployment container in custom namespace" {
    run ../vkube --trace --cluster-plan k3d-test app -n alpine uninstall deployment alpine
    sleep 10
    assert_success
    #echo "output=$output" >&3

    DETIK_CLIENT_NAMESPACE="default"
    sleep 10
    #echo '         Verify there are 0 pods named ^alpine' >&3
    run verify "there are 0 pods named '^alpine'"
    assert_success

    run vkube-lib.is-namespace-exist "alpine"
    [ "$status" -eq 0 ]
  }
  # bats test_tags=tag:alpine
  @test "Can't uninstall not installed general container in custom namespace" {
    run ../vkube --trace --cluster-plan k3d-test app -n alpine uninstall deployment alpine
    sleep 10
    assert_failure
    #echo "output=$output" >&3

    assert_output --partial "Deployment 'alpine' is not installed yet in namespace 'alpine'"

    run vkube-lib.is-namespace-exist "alpine"
    [ "$status" -eq 0 ]
  }
  # bats test_tags=tag:alpine
  @test "Can't uninstall deployment if wrong namespace" {
    run ../vkube --trace --cluster-plan k3d-test app uninstall deployment alpine2
    sleep 10
    assert_failure
    #echo "output=$output" >&3

    assert_output --partial "Deployment 'alpine2' is not installed yet in namespace 'default'"

    run vkube-lib.is-namespace-exist "alpine"
    [ "$status" -eq 0 ]
  }
  # bats test_tags=tag:alpine
  @test "Delete namespace when last deployment uninstalled" {
    run ../vkube --trace --cluster-plan k3d-test app -n alpine uninstall deployment alpine2
    sleep 10
    assert_success
    #echo "output=$output" >&3

    run vkube-lib.is-namespace-exist "alpine"
    [ "$status" -eq 1 ]
  }

#endregion apps
