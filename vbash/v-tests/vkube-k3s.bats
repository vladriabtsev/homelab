#!/usr/bin/env bats
# k8s bash tests: ./bats/bin/bats ./vkube-k3s.bats --filter-status failed
# k8s bash tests: ./bats/bin/bats ./vkube-k3s.bats --filter-tags tag:test
# k8s bash tests: ./bats/bin/bats ./vkube-k3s.bats --filter-tags tag:core
# k8s bash tests: ./bats/bin/bats ./vkube-k3s.bats --filter-tags tag:storage
# k8s bash tests: ./bats/bin/bats ./vkube-k3s.bats --filter-tags tag:storage-speed
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

  #vlib.bashly-init-error-handler

  # get the containing directory of this file
  # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
  # as those will point to the bats executable's location or the preprocessed file respectively
  DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
  echo $DIR
  # make executables in src/ visible to PATH
  PATH="$DIR/../src:$PATH"

  data_folder="./vkube-data/k3d-test"
}
#teardown() {
  #echo "teardown"
  #rm -f /tmp/bats-tutorial-project-ran
#}
# setup_file() {
#   # if kubectl cluster-info; then
#   #   echo "k3d cluster delete test" >&3
#   #   k3d cluster delete test
#   # fi
#   # if ! kubectl cluster-info; then
#   #   echo "k3d cluster create k3d-test --wait" >&3
#   #   k3d cluster create k3d-test --wait
#   # fi
# }
#teardown_file() {
#  k3d cluster delete test
#}

# https://bats-core.readthedocs.io/en/stable/writing-tests.html

# TODO tests for different kubernetes clusters
# https://spacelift.io/blog/kubeconfig

# https://rnemet.dev/posts/k3d/
# docker exec k3d-test-server-0 crictl images

#region secret
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-folder: without namespace" {
    run vkube-k3s.secret-create-from-folder
    echo "output=$output"
    assert_failure
    assert_output --partial "Missing namespace \$1 parameter"
    assert_output --partial "## C A L L   T R A C E ##"
  }
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-folder: without secret name" {
    run vkube-k3s.secret-create-from-folder test
    #echo "output=$output"
    assert_failure
    assert_output --partial "Missing secret name \$2 parameter"
    assert_output --partial "## C A L L   T R A C E ##"
  }
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-folder: without secret folder" {
    run vkube-k3s.secret-create-from-folder test test-secret
    #echo "output=$output"
    assert_failure
    assert_output --partial "Missing secret folder path \$3 parameter"
    assert_output --partial "## C A L L   T R A C E ##"
  }
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-folder: from not existing disk folder" {
    run vkube-k3s.secret-create-from-folder test test-secret ~/.test-not-exists
    #echo "output=$output" >&3
    assert_failure
    assert_output --partial "Can't find folder"
    assert_output --partial "## C A L L   T R A C E ##"
  }
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-folder: from empty disk folder" {
    run vkube-k3s.secret-create-from-folder test test-secret ~
    #echo "output=$output" >&3
    assert_failure
    assert_output --partial "Can't find user name file"
    assert_output --partial "## C A L L   T R A C E ##"
  }
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-folder: from disk folder with username and password" {
    # Required:
    # ~/.test/username.txt # with line 'username=test-user'
    # ~/.test/password.txt # with line 'password=test-password'
    run vkube-k3s.secret-create-from-folder test test-secret ~/.test
    #echo "output=$output" >&3
    assert_success
    assert_output --partial "secret/test-secret created"
  }
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-folder: from disk folder" {
    # Required:
    # ~/.test/username.txt # with line 'username=test-user'
    # ~/.test/password.txt # with line 'password=test-password'
    run kubectl delete secret test-secret -n test --ignore-not-found=true
    assert_success

    run vkube-k3s.secret-create-from-folder test test-secret ~/.test
    #echo "output=$output" >&3
    assert_success

    run kubectl get secret test-secret -n test
    assert_success
  }
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-pass-folder: from not existing path in 'pass' password store" {
    run vkube-k3s.secret-create-from-pass-folder test test-secret not-existing-store-folder
    #echo "output=$output" >&3
    assert_failure
    assert_output --partial "Can't find 'not-existing-store-folder/username.txt' record in 'pass' password store"
    assert_output --partial "## C A L L   T R A C E ##"
  }
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-pass-folder: from path in 'pass' password store" {
    # Required:
    # pass insert test/username.txt # enter password 'test-user'
    # pass insert test/password.txt # enter password 'test-password'
    run vkube-k3s.secret-create-from-pass-folder test test-secret test
    #echo "output=$output" >&3
    assert_success
  }
  #bats test_tags=tag:secret
  @test "vkube-k3s.secret-create-from-pass-folder: from password manager" {
    # Required:
    # ~/.test/username.txt # with line 'username=test-user'
    # ~/.test/password.txt # with line 'password=test-password'
    run kubectl delete secret test-secret -n test --ignore-not-found=true
    assert_success

    run vkube-k3s.secret-create-from-pass-folder test test-secret test
    #echo "output=$output" >&3
    assert_success

    run kubectl get secret test-secret -n test
    assert_success
  }
#endregion secret

# bats test_tags=tag:core
@test "k3d core installation" {
  #if command -v k3d version &> /dev/null; then
  if k3d version &> /dev/null; then
    echo "      k3d cluster delete test" >&3
    run k3d cluster delete test
  fi
  echo "      Step $[step=$step+1]. ../vkube --cluster-plan k3d-test --trace k3s install --core" >&3
  run ../vkube --cluster-plan k3d-test --trace k3s install --core
  sleep 20
  assert_success

  # https://github.com/bats-core/bats-assert#partial-matching
  echo '         Testing...' >&3
  sleep 60
  DETIK_CLIENT_NAMESPACE="kube-system"
  echo '         Testing traefik' >&3
  run verify "there are 1 pods named '^traefik'"
  assert_success
  run try "at most 10 times every 30s to get pods named '^traefik' and verify that 'status' is 'running'"
  assert_success
  run verify "'status' is 'running' for pods named '^traefik'"
  assert_success

  run verify "there is 1 storageclass named 'local-path'"
  [ "$status" -eq 0 ]

  run vkube-k3s.is-namespace-exist "csi-nfs"
  [ "$status" -eq 1 ]
  run vkube-k3s.is-namespace-exist "csi-smb"
  [ "$status" -eq 1 ]
  run vkube-k3s.is-namespace-exist "synology-csi"
  [ "$status" -eq 1 ]
}

#region storage install and uninstall
  # bats test_tags=tag:storage-separate
  @test "storage: install-uninstall local" {
    skip "Not implemented yet"
    echo "      Step $[step=$step+1]. ../vkube --cluster-plan k3d-test --trace k3s install --local" >&3
    run ../vkube --cluster-plan k3d-test --trace k3s install --local
    sleep 10
    assert_success
    run verify "there is 1 storageclass named 'local-storage'"
	  [ "$status" -eq 0 ]

    #vkube-k3s.-internal-storage-speed-test "local-path"
    run ../vkube --cluster-plan k3d-test --trace k3s storage-speed-test "local-path" --csi-driver-nfs
  }
  # bats test_tags=tag:storage-separate
  # https://rudimartinsen.com/2024/01/09/nfs-csi-driver-kubernetes/
  # https://github.com/kubernetes-csi/csi-driver-nfs
  @test "storage: install-uninstall nfs" {
    echo "      Step $[step=$step+1]. ../vkube --cluster-plan k3d-test --trace k3s install --csi-driver-nfs" >&3
    run ../vkube --cluster-plan k3d-test --trace k3s install --csi-driver-nfs
    echo '         Testing...' >&3
    sleep 60
    DETIK_CLIENT_NAMESPACE="csi-nfs"
    echo '         Testing csi-nfs-node' >&3
    run try "at most 5 times every 30s to get pods named '^csi-nfs-node' and verify that 'status' is 'running'"
    assert_success
    echo '         Testing csi-nfs-controller' >&3
    run try "at most 5 times every 30s to get pods named '^csi-nfs-controller' and verify that 'status' is 'running'"
    assert_success

    #vkube-k3s.-internal-storage-speed-test "office-csi-driver-nfs-retain"
    run ../vkube --cluster-plan k3d-test --trace k3s storage-speed-test "office-csi-driver-nfs-retain" --csi-driver-nfs
    
    echo "      Step $[step=$step+1]. helm uninstall csi-driver-nfs -n csi-nfs" >&3
    run helm uninstall csi-driver-nfs -n csi-nfs
    sleep 10
    assert_success
    echo "      Step $[step=$step+1]. kubectl delete ns csi-nfs" >&3
    run kubectl delete ns csi-nfs
    sleep 10
    assert_success
  }
  # bats test_tags=tag:storage-separate
  # https://github.com/kubernetes-csi/csi-driver-nfs/tree/master/charts
  @test "storage: install-uninstall smb" {
    echo "      Step $[step=$step+1]. ../vkube --cluster-plan k3d-test --trace k3s install --csi-driver-smb" >&3
    run ../vkube --cluster-plan k3d-test --trace k3s install --csi-driver-smb
    echo '         Testing...' >&3
    sleep 60
    DETIK_CLIENT_NAMESPACE="csi-smb"
    echo '         Testing csi-smb-node' >&3
    run try "at most 5 times every 30s to get pods named '^csi-smb-node' and verify that 'status' is 'running'"
    assert_success
    echo '         Testing csi-smb-controller' >&3
    run try "at most 5 times every 30s to get pods named '^csi-smb-controller' and verify that 'status' is 'running'"
    assert_success

    #vkube-k3s.-internal-storage-speed-test "office-csi-driver-smb-tmp"
    run ../vkube --cluster-plan k3d-test --trace k3s storage-speed-test "office-csi-driver-smb-tmp" --csi-driver-nfs

    echo "      Step $[step=$step+1]. helm uninstall csi-driver-smb -n csi-smb" >&3
    run helm uninstall csi-driver-smb -n csi-smb
    sleep 10
    assert_success
    echo "      Step $[step=$step+1]. kubectl delete ns csi-smb" >&3
    run kubectl delete ns csi-smb
    sleep 10
    assert_success
  }
  # bats test_tags=tag:storage-separate
  @test "storage: install-uninstall synology-csi" {
    echo "      Step $[step=$step+1]. ../vkube --cluster-plan k3d-test --trace k3s install --csi-synology" >&3
    run ../vkube --cluster-plan k3d-test --trace k3s install --csi-synology
    echo '         Testing...' >&3
    sleep 30
    DETIK_CLIENT_NAMESPACE="synology-csi"
    echo '         Testing synology-csi-node' >&3
    run try "at most 5 times every 30s to get pods named '^synology-csi-node' and verify that 'status' is 'running'"
    assert_success
    echo '         Testing synology-csi-controller' >&3
    run try "at most 5 times every 30s to get pods named '^synology-csi-controller' and verify that 'status' is 'running'"
    assert_success

    #vkube-k3s.-internal-storage-speed-test "office-synology-csi-nfs-retain"
    run ../vkube --cluster-plan k3d-test --trace k3s storage-speed-test "office-synology-csi-nfs-retain" --csi-driver-nfs
    #vkube-k3s.-internal-storage-speed-test "office-synology-csi-smb-tmp"
    run ../vkube --cluster-plan k3d-test --trace k3s storage-speed-test "office-synology-csi-smb-tmp" --csi-driver-nfs

    # # https://github.com/SynologyOpenSource/synology-csi/pull/85
    # storage="office-synology-csi-iscsi-tmp"
    # echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
    # kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
    # kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true
    # run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
    # assert_success
    # echo '        Testing...' >&3
    # sleep 15
    # run try "at most 3 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
    # assert_success
    # kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
    # assert_success
    # echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3

    # # https://github.com/SynologyOpenSource/synology-csi/pull/85
    # storage="office-synology-csi-iscsi-retain"
    # echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
    # kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
    # kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true
    # run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
    # assert_success
    # echo '         Testing...' >&3
    # sleep 15
    # run try "at most 5 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
    # assert_success
    # kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
    # assert_success
    # echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3

    # echo "      Step $[step=$step+1]. helm uninstall csi-driver-nfs -n csi-nfs" >&3
    # run helm uninstall csi-driver-nfs -n csi-nfs
    # sleep 10
    # assert_success
    # echo "      Step $[step=$step+1]. kubectl delete ns csi-nfs" >&3
    # run kubectl delete ns csi-nfs
    # sleep 10
    # assert_success
  }
  # bats test_tags=tag:storage-separate
  @test "storage: install-uninstall longhorn" {
    
    if kubectl get ns/longhorn-system; then
      run ../vkube --cluster-plan k3d-test --trace k3s storage-speed-test "longhorn" --longhorn
    else
      skip "Longhorn is not installed. If it k3d then probably because open-iscsi is not supported in k3d"
    fi

    echo "      Step $[step=$step+1]. ../vkube --cluster-plan k3d-test --trace k3s install --longhorn" >&3
    run ../vkube --cluster-plan k3d-test --trace k3s install --longhorn

    echo '      Testing...' >&3
    sleep 60
    DETIK_CLIENT_NAMESPACE="synology-csi"
    echo '         Testing synology-csi-node' >&3
    run try "at most 5 times every 30s to get pods named '^synology-csi-node' and verify that 'status' is 'running'"
    assert_success
    echo '         Testing synology-csi-controller' >&3
    run try "at most 5 times every 30s to get pods named '^synology-csi-controller' and verify that 'status' is 'running'"
    assert_success

    #vkube-k3s.-internal-storage-speed-test "office-synology-csi-nfs-retain"
    run ../vkube --cluster-plan k3d-test --trace k3s storage-speed-test "office-synology-csi-nfs-retain" --csi-driver-nfs
    #vkube-k3s.-internal-storage-speed-test "office-synology-csi-smb-tmp"
    run ../vkube --cluster-plan k3d-test --trace k3s storage-speed-test "office-synology-csi-smb-tmp" --csi-driver-nfs

    # echo "      Step $[step=$step+1]. ../vkube --cluster-plan k3d-test --trace k3s uninstall --longhorn" >&3
    # run ../vkube --cluster-plan k3d-test --trace k3s uninstall --longhorn
    # sleep 10
    # assert_success
  }
#endregion storage install and uninstall

# bats test_tags=tag:storage-classes-only
@test "storage-classes: regenerate" {
  echo "      Step $[step=$step+1]. ../vkube --force --cluster-plan k3d-test --trace k3s install --storage-classes-only" >&3
  run ../vkube --force --cluster-plan k3d-test --trace k3s install --storage-classes-only
  sleep 10
  assert_success
  run verify "there is 1 storageclass named 'local-storage'"
}

# bats test_tags=tag:storage
@test "k3d general storage installation" {
  echo "      Step $[step=$step+1]. ../vkube --force --cluster-plan k3d-test --trace k3s install --storage" >&3
  run ../vkube --force --cluster-plan k3d-test --trace k3s install --storage
  sleep 10
  assert_success

  # https://github.com/bats-core/bats-assert#partial-matching
  echo '      Testing...' >&3
  sleep 60

  DETIK_CLIENT_NAMESPACE="csi-nfs"
  echo '      Testing csi-nfs-node' >&3
  run try "at most 5 times every 30s to get pods named '^csi-nfs-node' and verify that 'status' is 'running'"
  assert_success
  echo '      Testing csi-nfs-controller' >&3
  run try "at most 5 times every 30s to get pods named '^csi-nfs-controller' and verify that 'status' is 'running'"
  assert_success

  DETIK_CLIENT_NAMESPACE="csi-smb"
  echo '      Testing csi-smb-node' >&3
  run try "at most 5 times every 30s to get pods named '^csi-smb-node' and verify that 'status' is 'running'"
  assert_success
  echo '      Testing csi-smb-controller' >&3
  run try "at most 5 times every 30s to get pods named '^csi-smb-controller' and verify that 'status' is 'running'"
  assert_success

  DETIK_CLIENT_NAMESPACE="synology-csi"
  echo '      Testing synology-csi-node' >&3
  run try "at most 5 times every 30s to get pods named '^synology-csi-node' and verify that 'status' is 'running'"
  assert_success
  echo '      Testing synology-csi-controller' >&3
  run try "at most 5 times every 30s to get pods named '^synology-csi-controller' and verify that 'status' is 'running'"
  assert_success
}

#region general storage speed tests

  # bats test_tags=tag:storage-speed
  @test "../vkube --cluster-plan k3d-test k3s storage-speed 'local-path'" {
    run ../vkube --cluster-plan k3d-test k3s storage-speed 'local-path' # >&3
    #echo "output=$output" >&3
  }

  # bats test_tags=tag:storage-speed
  @test "../vkube --cluster-plan k3d-test k3s storage-speed 'office-csi-driver-nfs-retain'" {
    run ../vkube --cluster-plan k3d-test k3s storage-speed 'office-csi-driver-nfs-retain'
    assert_success
    #echo "output=$output" >&3
  }

  # bats test_tags=tag:storage-speed
  @test "../vkube --cluster-plan k3d-test k3s storage-speed 'office-csi-driver-smb-tmp'" {
    run ../vkube --cluster-plan k3d-test k3s storage-speed 'office-csi-driver-smb-tmp'
    assert_success
    #echo "output=$output" >&3
  }

  # bats test_tags=tag:storage-speed
  @test "../vkube --cluster-plan k3d-test k3s storage-speed 'office-synology-csi-nfs-retain'" {
    run ../vkube --cluster-plan k3d-test k3s storage-speed 'office-synology-csi-nfs-retain'
    assert_success
    #echo "output=$output" >&3
  }

  # bats test_tags=tag:storage-speed
  @test "../vkube --cluster-plan k3d-test k3s storage-speed 'longhorn'" {
    if ! kubectl get ns/longhorn-system; then
      skip "Longhorn is not installed"
    fi
    run ../vkube --cluster-plan k3d-test k3s storage-speed 'longhorn'
    assert_success
    #echo "output=$output" >&3
  }

  # # bats test_tags=tag:storage-speed
  # @test "k3(s/d) general storage speed tests" {
  #   vkube-k3s.-internal-storage-speed-test "local-path"
  #   vkube-k3s.-internal-storage-speed-test "office-csi-driver-nfs-retain"
  #   vkube-k3s.-internal-storage-speed-test "office-csi-driver-smb-tmp"
  #   vkube-k3s.-internal-storage-speed-test "office-synology-csi-nfs-retain"
  #   vkube-k3s.-internal-storage-speed-test "office-synology-csi-smb-tmp"
  #   if kubectl get ns/longhorn-system; then
  #     vkube-k3s.-internal-storage-speed-test "longhorn"
  #   fi
  # }

#endregion general storage speed tests

#region general storage speed tests ???
  # https://kubernetes.io/docs/concepts/storage/volumes/
  # # bats test_tags=tag:speed
  # @test "storage: local-path tests" {
  #   local storage="local-path"
  #   echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
  #   kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
  #   kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true

  #   run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
  #   assert_success

  #   echo '      Testing...' >&3
  #   sleep 15

  #   DETIK_CLIENT_NAMESPACE="storage-speedtest"
  #   run try "at most 5 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
  #   assert_success

  #   # https://stackoverflow.com/questions/55073453/wait-for-kubernetes-job-to-complete-on-either-failure-success-using-command-line
  #   kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
  #   assert_success
  #   echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3
  # } 
  # bats test_tags=tag:failed
  @test "storage: local-storage tests" {
    skip
    # https://overcast.blog/provisioning-kubernetes-local-persistent-volumes-full-tutorial-147cfb20ec27
    local storage="local-storage"
    echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
    kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
    kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true

    run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
    assert_success

    echo '      Testing...' >&3
    sleep 15

    DETIK_CLIENT_NAMESPACE="storage-speedtest"
    run try "at most 5 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
    assert_success

    # https://stackoverflow.com/questions/55073453/wait-for-kubernetes-job-to-complete-on-either-failure-success-using-command-line
    run kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
    assert_success
    echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3

    echo "output=$output" >&3
  } 
  # # bats test_tags=tag:speed-one
  # @test "storage: office-csi-driver-nfs-retain tests" {
  #   local storage="office-csi-driver-nfs-retain"
  #   echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
  #   kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
  #   kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true

  #   run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
  #   assert_success

  #   echo '      Testing...' >&3
  #   sleep 15

  #   DETIK_CLIENT_NAMESPACE="storage-speedtest"
  #   run try "at most 5 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
  #   assert_success

  #   # https://stackoverflow.com/questions/55073453/wait-for-kubernetes-job-to-complete-on-either-failure-success-using-command-line
  #   kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
  #   assert_success
  #   echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3
  # } 
  # # bats test_tags=tag:speed
  # @test "storage: office-csi-driver-smb-tmp tests" {
  #   local storage="office-csi-driver-smb-tmp"
  #   echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
  #   #kubectl delete -f "$data_folder/generated-$2-write-read.yaml" --ignore-not-found=true
  #   kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
  #   kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true

  #   run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
  #   assert_success

  #   echo '      Testing...' >&3
  #   sleep 15

  #   DETIK_CLIENT_NAMESPACE="storage-speedtest"
  #   run try "at most 5 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
  #   assert_success

  #   # https://stackoverflow.com/questions/55073453/wait-for-kubernetes-job-to-complete-on-either-failure-success-using-command-line
  #   kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
  #   assert_success
  #   echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3
  # } 
  # # bats test_tags=tag:failed
  # @test "storage: office-synology-csi-iscsi-tmp tests" {
  #   local storage="office-synology-csi-iscsi-tmp"
  #   echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
  #   kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
  #   kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true

  #   run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
  #   assert_success

  #   echo '      Testing...' >&3
  #   sleep 15

  #   DETIK_CLIENT_NAMESPACE="storage-speedtest"
  #   run try "at most 3 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
  #   assert_success

  #   # https://stackoverflow.com/questions/55073453/wait-for-kubernetes-job-to-complete-on-either-failure-success-using-command-line
  #   kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
  #   assert_success
  #   echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3
  # } 
  # # bats test_tags=tag:failed
  # @test "storage: office-synology-csi-iscsi-retain tests" {
  #   local storage="office-synology-csi-iscsi-retain"
  #   echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
  #   kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
  #   kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true

  #   run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
  #   assert_success

  #   echo '      Testing...' >&3
  #   sleep 15

  #   DETIK_CLIENT_NAMESPACE="storage-speedtest"
  #   run try "at most 5 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
  #   assert_success

  #   # https://stackoverflow.com/questions/55073453/wait-for-kubernetes-job-to-complete-on-either-failure-success-using-command-line
  #   kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
  #   assert_success
  #   echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3
  # } 
  # # bats test_tags=tag:speed
  # @test "storage: office-synology-csi-nfs-retain tests" {
  #   local storage="office-synology-csi-nfs-retain"
  #   echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
  #   kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
  #   kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true

  #   run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
  #   assert_success

  #   echo '      Testing...' >&3
  #   sleep 15

  #   DETIK_CLIENT_NAMESPACE="storage-speedtest"
  #   run try "at most 5 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
  #   assert_success

  #   # https://stackoverflow.com/questions/55073453/wait-for-kubernetes-job-to-complete-on-either-failure-success-using-command-line
  #   kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
  #   assert_success
  #   echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3
  # } 
  # # bats test_tags=tag:speed
  # @test "storage: office-synology-csi-smb-tmp tests" {
  #   local storage="office-synology-csi-smb-tmp"
  #   echo "      Step $[step=$step+1]. vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce" >&3
  #   kubectl delete job "${storage}-write-read" -n storage-speedtest --ignore-not-found=true
  #   kubectl delete pvc "${storage}-test-pvc" -n storage-speedtest --ignore-not-found=true

  #   run vkube-k3s.storage-speedtest-job-create storage-speedtest $storage ReadWriteOnce
  #   assert_success

  #   echo '      Testing...' >&3
  #   sleep 15

  #   DETIK_CLIENT_NAMESPACE="storage-speedtest"
  #   run try "at most 5 times every 30s to get pods named '^$storage-write-read' and verify that '.status.phase' is 'Succeeded'"
  #   assert_success

  #   # https://stackoverflow.com/questions/55073453/wait-for-kubernetes-job-to-complete-on-either-failure-success-using-command-line
  #   kubectl wait --for=condition=Completed job/${storage}-write-read -n storage-speedtest & completion_pid=$!
  #   assert_success
  #   echo "$(kubectl -n storage-speedtest logs -l app=$storage-storage-speedtest,job=write-read)" >&3
  # } 
#endregion general storage tests ???

# bats test_tags=tag:longhorn
@test "k3d longhorn installation" {
  skip "Not working yet? Or not supported?"
  echo "      Step $[step=$step+1]. ../vkube --cluster-plan k3d-test --trace k3s install --longhorn" >&3

  node_root_password="kuku"
  # vlib.read-password node_root_password "Please enter root password for cluster nodes:"
  # echo
  longhorn_ui_admin_name="kuku"
  # vlib.read-password longhorn_ui_admin_name "Please enter Longhorn UI admin name:"
  # echo
  longhorn_ui_admin_password="kuku"
  # vlib.read-password longhorn_ui_admin_password "Please enter Longhorn UI admin password:"
  # echo

  run ../vkube --cluster-plan k3d-test --trace k3s install --longhorn
  assert_success

  sleep 10

  # https://github.com/bats-core/bats-assert#partial-matching
  echo '      Testing...' >&3
  sleep 60

  assert_failure

  DETIK_CLIENT_NAMESPACE="synology-csi"
  echo '      Testing synology-csi-node' >&3
  run try "at most 5 times every 30s to get pods named '^synology-csi-node' and verify that 'status' is 'running'"
  assert_success
  # run verify "there are 2 pods named '^synology-csi-node'"
  # assert_success
  echo '      Testing synology-csi-controller' >&3
  run try "at most 5 times every 30s to get pods named '^synology-csi-controller' and verify that 'status' is 'running'"
  assert_success
  # run verify "there are 4 pods named '^synology-csi-controller'"
  # assert_success
} 

@test "synology-csi installation integration tests" {
  skip
  # https://bats-core.readthedocs.io/en/stable/writing-tests.html
  ##########################################################################################
  echo "      Step $[step=$step+1]. ../vkube --trace synology-csi install ../v-tests/cluster-storage-plan.yaml --secret-folder ~/.ssh/k3s-HA-csi-synology-secrets" >&3
  run ../vkube --trace synology-csi install ../v-tests/cluster-storage-plan.yaml --secret-folder "~/.ssh/k3s-HA-csi-synology-secrets"
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
@test "busybox installation integration tests" {
  skip
  echo "      Step $[step=$step+1]. ../vkube --trace busybox install test-busybox" >&3
  run ../vkube --trace busybox install test-busybox

  #echo "      Step $[step=$step+1]. ../vkube --trace busybox install test-busybox-nfs office-synology-csi-nfs-test" >&3
  #run ../vkube --trace busybox install test-busybox-nfs office-synology-csi-nfs-test

  echo "      Step $[step=$step+1]. ../vkube --trace busybox install test-busybox-iscsi office-synology-csi-iscsi-test-tmp" >&3
  run ../vkube --trace busybox install test-busybox-iscsi office-synology-csi-iscsi-test-tmp

  # echo "      Step $[step=$step+1]. ../vkube --trace busybox install test-busybox-iscsi office-synology-csi-iscsi-test" >&3
  # run ../vkube --trace busybox install test-busybox-iscsi office-synology-csi-iscsi-test


  echo "      Step $[step=$step+1]. ../vkube --trace busybox install test-busybox 1.37 backup2-synology-csi-nfs-test" >&3
  #run ../vkube --trace busybox install test-busybox 1.37 backup2-synology-csi-nfs-test
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

  #run ../vkube --trace busybox install mybusybox backup2-nfs-test
  #run ../vkube --trace busybox install mybusybox backup2-iscsi-test
  #run ../vkube --trace busybox install mybusybox backup2-smb-test

  #run ../vkube --trace busybox install mybusybox backup2-synology-csi-nfs-test
  #run ../vkube --trace busybox install mybusybox backup2-synology-csi-smb-test
  #run ../vkube --trace busybox install mybusybox backup2-synology-csi-iscsi-test

}

