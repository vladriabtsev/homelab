#!/usr/bin/env bats
# k8s bash tests: ./bats/bin/bats ./../v-tests/vlib.bats --filter-status failed
# k8s bash tests: ./bats/bin/bats ./../v-tests/vlib.bats --filter-tags tag:yaml
# https://bats-core.readthedocs.io/en/stable/installation.html#linux-distribution-package-manager
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#run-test-other-commands
# https://github.com/ztombol/bats-docs?tab=readme-ov-file#installation

setup() {
  #load '~/bats-core/test_helper/bats-support/load' # this is required by bats-assert!
  #load 'test_helper/bats-assert/load'  
  #load '~/bats-core/test_helper' # this is required by bats-assert!
  
  load 'test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'  

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

# https://www.baeldung.com/linux/compare-dot-separated-version-string
testvercomp() {
    vlib.vercomp $1 $2
    case $? in
        0) op='=';;
        1) op='>';;
        2) op='<';;
    esac
    if [[ $op != $3 ]]
    then
        echo "Fail: Expected '$3', Actual '$op', Arg1 '$1', Arg2 '$2'"
        exit 1
    else
        echo "Pass: '$1 $op $2'"
    fi
}
@test "vercomp" {
  run testvercomp 1 1 "="
  [ "$status" -eq 0 ]
  run testvercomp 2.1 2.2 "<"
  [ "$status" -eq 0 ]
  run testvercomp 3.0.4.10 3.0.4.2 ">"
  [ "$status" -eq 0 ]
  run testvercomp 3.2 3.2.1.9.8144 "<"
  [ "$status" -eq 0 ]
}

# bats test_tags=tag:patch
@test "json: node patch" {
  skip
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

#region text
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
#endregion text

#region wait-for 
  @test "wait-for-success: error if without parameters" {
    run vlib.wait-for-success
    #echo "echo always" >&3
    #echo "echo on error"
    #echo "output=$output"
    #echo "status=$status"
    #echo "${lines[0]}"
    #printf "$output"
    [ "$status" -ne 0 ]
    [ "${lines[0]}" = "Error: Call 'vlib.wait-for-success' without parameters" ]
  }
  @test "wait-for-success: with <bash command> parameter only" {
    run vlib.wait-for-success "ls ~"
    [ "$status" -eq 0 ]
  }
  @test "wait-for-success: error if without <bash command> parameter" {
    run vlib.wait-for-success -p 2
    #printf "$output"
    [ "$status" -ne 0 ]
    [ "${lines[0]}" = "Function 'vlib.wait-for-success' is expecting <bash command> parameter" ]
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
    [ "${lines[0]}" = "Error: Call 'vlib.wait-for-error' without parameters" ]
  }
  @test "wait-for-error: with <bash command> parameter only" {
    run vlib.wait-for-error "ls /kuku/kuku"
    echo "status=$status"
    [ "$status" -eq 0 ]
  }
  @test "wait-for-error: error if without <bash command> parameter" {
    run vlib.wait-for-error -p 2
    [ "$status" -ne 0 ]
    [ "${lines[0]}" = "Function 'vlib.wait-for-error' is expecting <bash command> parameter" ]
  }
  @test "wait-for-error: waiting for error" {
    run vlib.wait-for-error -p 2 -t 3 "not-existing-command123"
    [ "$status" -eq 0 ]
  }
  @test "wait-for-error: waiting for error timeout" {
    run vlib.wait-for-error -p 2 -t 3 "ls ~"
    [ "$status" -ne 0 ]
  }
#endregion wait-for 

#region dir
  # bats test_tags=tag:dir
  @test "vlib.is-dir-exists: error without parameters" {
    run vlib.is-dir-exists
    #echo "output=$output" >&3
    #echo "status=$status" >&3
    assert_failure
    [ "$status" -eq 1 ]
    assert_output --partial "Function 'vlib.is-dir-exists' is expecting dir path parameter"
  }
  # bats test_tags=tag:dir
  @test "vlib.is-dir-exists: existing path" {
    run vlib.is-dir-exists "${HOME}"
    assert_success
    [ "$status" -eq 0 ]
    [ "$output" = "" ]
  }
  # bats test_tags=tag:dir
  @test "vlib.is-dir-exists: not existing path" {
    run vlib.is-dir-exists "${HOME}tmp"
    assert_failure
    [ "$status" -eq 1 ]
    [ "$output" = "" ]
  }
  # bats test_tags=tag:dir
  @test "vlib.get-secret-string: not existing path" {
    run vlib.get-secret-string "~/not-exist"
    assert_failure
    #echo "output=$output" >&3
    [ "$status" -eq 1 ]
    assert_output --partial "Can't find file '~/not-exist'"
  }
  # bats test_tags=tag:dir
  @test "vlib.get-secret-string: existing dir path without file (~)" {
    run vlib.get-secret-string "~"
    #echo "output=$output" >&3
    assert_failure
    [ "$status" -eq 1 ]
    assert_output --partial "Can't find file '~'"
  }
  # bats test_tags=tag:dir
  @test "vlib.get-secret-string: existing dir path without file (\$HOME)" {
    run vlib.get-secret-string "\${HOME}"
    #echo "output=$output" >&3
    assert_failure
    [ "$status" -eq 1 ]
    assert_output --partial "'\${HOME}' is a directory (full path: '${HOME}')"
  }
  # bats test_tags=tag:dir
  @test "vlib.get-secret-string: existing dir path without file (HOME)" {
    run vlib.get-secret-string "${HOME}"
    #echo "output=$output" >&3
    assert_failure
    [ "$status" -eq 1 ]
    assert_output --partial "'${HOME}' is a directory (full path: '${HOME}')"
  }
  # bats test_tags=tag:dir
  @test "vlib.get-secret-string: existing empty file" {
    run vlib.get-secret-string "./test-empty-file.txt"
    #echo "output=$output" >&3
    assert_failure
    assert_output --partial "v-tests/test-empty-file.txt') is empty"
  }
  # bats test_tags=tag:dir
  @test "vlib.get-secret-string: existing not empty file" {
    run vlib.get-secret-string "./test-not-empty-file.txt"
    #echo "output=$output" >&3
    assert_success
    [ "$output" = "test-secret-from-file" ]
  }
#endregion dir

#region 'pass' password manager
  # bats test_tags=tag:pass
  @test "vlib.is-pass-dir-exists: error without parameters" {
    # pass insert test/exists-pass-dir-test # enter password 'test-password'
    run vlib.is-pass-dir-exists
    assert_failure
    [ "$status" -eq 1 ]
    assert_output --partial "Function 'vlib.is-pass-dir-exists' is expecting 'pass' password manager path parameter"
  }
  # bats test_tags=tag:pass
  @test "vlib.is-pass-dir-exists: existing path" {
    # pass insert test/exists-pass-dir-test # enter password 'test-password'
    run vlib.is-pass-dir-exists test/exists-pass-dir-test
    #echo "output=$output" >&3
    assert_success
    [ "$output" = "" ]
  }
  # bats test_tags=tag:pass
  @test "vlib.is-pass-dir-exists: not existing path" {
    run vlib.is-pass-dir-exists test/exists-pass-dir-test-tmp
    assert_failure
    [ "$status" -eq 1 ]
    #echo "output=$output" >&3
    assert_output --partial "Error: test/exists-pass-dir-test-tmp is not in the password store."
  }
  # bats test_tags=tag:pass
  @test "vlib.pass-get-secret: get secret for not existing path" {
    run vlib.pass-get-secret test/exists-pass-dir-test-tmp
    # echo "_secret=$_secret" >&3
    # echo "output=$output" >&3
    # echo "status=$status" >&3
    assert_failure
    [ "$status" -eq 1 ]
    assert_output --partial "Error: test/exists-pass-dir-test-tmp is not in the password store"
    assert_output --partial "## C A L L   T R A C E ##"
  }
  # bats test_tags=tag:pass
  @test "vlib.pass-get-secret: get secret for not existing path into variable" {
    local _secret
    bats_require_minimum_version 1.5.0
    run -127 "_secret=\"$(vlib.pass-get-secret test/exists-pass-dir-test-tmp)\""
    # echo "_secret=$_secret" >&3
    # echo "output=$output" >&3
    # echo "status=$status" >&3
    assert_failure
    #[ "$status" -eq 1 ]
    assert_output --partial "Error: test/exists-pass-dir-test-tmp is not in the password store"
    assert_output --partial "## C A L L   T R A C E ##"
  }
  # bats test_tags=tag:pass
  @test "vlib.pass-get-secret: get secret for existing path" {
    local _secret
    run vlib.pass-get-secret test/exists-pass-dir-test
    # echo "output=$output" >&3
    # echo "status=$status" >&3
    # echo "_secret=$_secret" >&3
    assert_success
    [ "$output" = "test-password" ]
  }
  # bats test_tags=tag:pass
  @test "vlib.pass-get-secret: get secret for existing path into variable" {
    local _secret
    _secret="$(vlib.pass-get-secret test/exists-pass-dir-test)"
    # echo "output=$output" >&3
    # echo "status=$status" >&3
    # echo "_secret=$_secret" >&3
    # assert_success
    # [ "$status" -eq 0 ]
    [ "$_secret" = "test-password" ]
  }
#endregion 'pass' password manager

#region 'try-exec-command'
  # bats test_tags=tag:exec-command-try
  @test "vlib.exec-command: ls expecting success" {
    run vlib.exec-command ls
    assert_success
    [ "$status" -eq 0 ]
  }
  # bats test_tags=tag:exec-command-try
  @test "vlib.exec-command: 'ls /unknown-folder' expecting failure" {
    run vlib.exec-command 'ls /unknown-folder'
    assert_failure
    [ "$status" -eq 1 ]
  }
#endregion 'try-exec-command'

#region 'exec-command-and-trace'
  # bats test_tags=tag:exec-command-and-trace
  @test "vlib.exec-command-and-trace: ls expecting success" {
    run vlib.exec-command-and-trace ls
    # echo "output=$output" >&3
    # echo "status=$status" >&3
    assert_success
    [ "$status" -eq 0 ]
  }
  # bats test_tags=tag:exec-command-and-trace
  @test "vlib.exec-command-and-trace: 'ls /unknown-folder' expecting failure" {
    run vlib.exec-command-and-trace 'ls /unknown-folder'
    assert_failure
    [ "$status" -eq 1 ]
  }
#endregion 'exec-command-and-trace'
