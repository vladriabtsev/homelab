#!/usr/bin/env bats
# k8s bash tests: ./bats/bin/bats ./vkube-k3s.bats --filter-status failed
# k8s bash tests: ./bats/bin/bats ./vkube-k3s.bats --filter-tags tag:test
# https://bats-core.readthedocs.io/en/stable/installation.html#linux-distribution-package-manager
# https://bats-core.readthedocs.io/en/stable/writing-tests.html#run-test-other-commands
# https://github.com/ztombol/bats-docs?tab=readme-ov-file#installation

setup() {
  load 'test_helper/bats-support/load' # this is required by bats-assert!
  load 'test_helper/bats-assert/load'  
  load 'test_helper/bats-file/load'  
  load 'test_helper/bats-detik/lib/utils'  
  load 'test_helper/bats-detik/lib/detik'

  DETIK_CLIENT_NAME="kubectl" 
  
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
setup_file() {
  if kubectl cluster-info; then
    echo "k3d cluster delete test" >&3
    k3d cluster delete test
  fi
  if ! kubectl cluster-info; then
    echo "k3d cluster create test --wait" >&3
    k3d cluster create test --wait
  fi
}
#teardown_file() {
#  k3d cluster delete test
#}

@test "synology-csi installation integration tests" {
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  ##########################################################################################
  echo "      Step $[step=$step+1]. ../vkube --trace synology-csi install ../v-tests/synology-csi/synology-csi-plan1.yaml --secret-folder ~/.ssh/k3s-HA-csi-synology-secrets" >&3
  run ../vkube --trace synology-csi install ../v-tests/synology-csi/synology-csi-plan1.yaml --secret-folder "~/.ssh/k3s-HA-csi-synology-secrets"
  # https://github.com/bats-core/bats-assert#partial-matching
  #echo '# text' >&3
  assert_success

  sleep 10

  DETIK_CLIENT_NAMESPACE="synology-csi"
  # https://github.com/bats-core/bats-detik
  run try "at most 5 times every 30s to find 1 pods named 'synology-csi-node' with 'status' being 'running'"
  #run verify "there is 1 pod named 'synology-csi-node'"
  assert_success
  run try "at most 5 times every 30s to find 1 pods named 'synology-csi-controller' with 'status' being 'running'"
  assert_success
  run verify "there is 0 pod named 'synology-csi-snapshotter'"
  assert_success
  DETIK_CLIENT_NAMESPACE="default"
  run verify "there is 0 pod named 'snapshot-controller'"
  assert_success

  __synology_ver=$(vkube-k3s.get-pod-image-version synology-csi synology-csi-controller csi-plugin)
  [ "$status" -eq 0 ]
  echo "__synology_ver=$__synology_ver"
  [ "$__synology_ver" == "v1.2.0" ]

  # ##########################################################################################
  # echo "      Step $[step=$step+1]. Busybox with ISCSI, SMB, and NFS disks" >&3

  # ##########################################################################################
  # echo "      Step $[step=$step+1]. ../vkube --trace synology-csi uninstall" >&3
  # run ../vkube --trace synology-csi uninstall
  # # https://github.com/bats-core/bats-assert#partial-matching
  # #echo '# text' >&3
  # assert_success

  # sleep 10

  # DETIK_CLIENT_NAMESPACE="synology-csi"
  # run verify "there is 0 pod named 'synology-csi-node'"
  # assert_success
  # run verify "there is 0 pod named 'synology-csi-controller'"
  # assert_success
  # run verify "there is 0 pod named 'synology-csi-controller'"
  # assert_success
  # run verify "there is 0 pod named 'synology-csi-snapshotter'"
  # assert_success
  # DETIK_CLIENT_NAMESPACE="default"
  # run verify "there is 0 pod named 'snapshot-controller'"
  # assert_success
  
  # ##########################################################################################
  # run ../vkube --trace synology-csi install v1.1.3 --snapshot --secret-folder "~/.ssh/k3s-HA-csi-synology-secrets"
  # # https://github.com/bats-core/bats-assert#partial-matching
  # #echo '# text' >&3
  # assert_success

  # sleep 10

  # DETIK_CLIENT_NAMESPACE="synology-csi"
  # # https://github.com/bats-core/bats-detik
  # run verify "there is 1 pod named 'synology-csi-node'"
  # assert_success
  # run verify "'status' is 'running' for pods named 'synology-csi-node'"
  # assert_success
  # run verify "there is 1 pod named 'synology-csi-controller'"
  # assert_success
  # run verify "'status' is 'running' for pods named 'synology-csi-controller'"
  # assert_success
  # run try "at most 5 times every 30s to find 1 pods named 'synology-csi-snapshotter' with 'status' being 'running'"  
  # #run verify "there is 1 pod named 'synology-csi-snapshotter'"
  # assert_success
  # DETIK_CLIENT_NAMESPACE="default"
  # run try "at most 5 times every 30s to find 1 pods named 'snapshot-controller' with 'status' being 'running'"
  # # run verify "there is 1 pod named 'snapshot-controller'"
  # # assert_success
  # # run verify "'status' is 'running' for pods named 'snapshot-controller'"
  # # assert_success

  # __synology_ver=$(vkube-k3s.get-pod-image-version synology-csi synology-csi-controller csi-plugin)
  # echo "__synology_ver=$__synology_ver" >&3
  # [ "$__synology_ver" == "v1.1.3" ]

  # ##########################################################################################
  # run ../vkube --trace synology-csi upgrade v1.2.0
  # # https://github.com/bats-core/bats-assert#partial-matching
  # #echo '# text' >&3
  # assert_success
  
  # __synology_ver=$(vkube-k3s.get-pod-image-version synology-csi synology-csi-controller csi-plugin)
  # echo "__synology_ver=$__synology_ver" >&3
  # [ "$status" -eq "v1.2.0" ]

  # ##########################################################################################
  # run ../vkube --trace synology-csi downgrade v1.1.3
  # # https://github.com/bats-core/bats-assert#partial-matching
  # #echo '# text' >&3
  # assert_success

  # __synology_ver=$(vkube-k3s.get-pod-image-version synology-csi synology-csi-controller csi-plugin)
  # echo "__synology_ver=$__synology_ver" >&3
  # [ "$status" -eq "v1.1.3" ]

  # ##########################################################################################
  # run ../vkube --trace synology-csi upgrade
  # # https://github.com/bats-core/bats-assert#partial-matching
  # #echo '# text' >&3
  # assert_success

  # ##########################################################################################
  # run ../vkube --trace synology-csi uninstall --snapshot
  # # https://github.com/bats-core/bats-assert#partial-matching
  # #echo '# text' >&3
  # assert_success

  # sleep 10

  # DETIK_CLIENT_NAMESPACE="synology-csi"
  # run verify "there is 0 pod named 'synology-csi-node'"
  # assert_success
  # run verify "there is 0 pod named 'synology-csi-controller'"
  # assert_success
  # run verify "there is 0 pod named 'synology-csi-controller'"
  # assert_success
  # run verify "there is 0 pod named 'synology-csi-snapshotter'"
  # assert_success
  # DETIK_CLIENT_NAMESPACE="default"
  # run verify "there is 0 pod named 'snapshot-controller'"
  # assert_success
}
# bats test_tags=tag:test
@test "busybox installation integration tests" {
  echo "      Step $[step=$step+1]. ../vkube --trace busybox install test-busybox 1.37 --storage-class backup2-synology-csi-nfs-test" >&3
  run ../vkube --trace busybox install test-busybox 1.37 --storage-class backup2-synology-csi-nfs-test
  # https://github.com/bats-core/bats-assert#partial-matching
  #echo '# text' >&3
  assert_success

  sleep 10

  DETIK_CLIENT_NAMESPACE="default"
  run verify "there is 1 pod named 'test-busybox'"
  assert_success

  ___ver=$(vkube-k3s.get-pod-image-version default test-busybox busybox)
  [ "$status" -eq 0 ]
  [ "$___ver" == "1.37.0" ]

  #run ../vkube --trace busybox install mybusybox --storage-class backup2-nfs-test
  #run ../vkube --trace busybox install mybusybox --storage-class backup2-iscsi-test
  #run ../vkube --trace busybox install mybusybox --storage-class backup2-smb-test

  #run ../vkube --trace busybox install mybusybox --storage-class backup2-synology-csi-nfs-test
  #run ../vkube --trace busybox install mybusybox --storage-class backup2-synology-csi-smb-test
  #run ../vkube --trace busybox install mybusybox --storage-class backup2-synology-csi-iscsi-test

}