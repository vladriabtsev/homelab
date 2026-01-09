# Start using

* Install WSL
* Install Ubuntu
* Run
* [Install Ruby and RubyGems](https://www.ruby-lang.org/en/documentation/installation/)
  * `brew install ruby-install`
  * `ruby-install ruby`
* [Bashly](https://bashly.dev/)
  * `gem install bashly`
    * [How To Package And Distribute Ruby Applications As a Gem Using RubyGems](https://www.digitalocean.com/community/tutorials/how-to-package-and-distribute-ruby-applications-as-a-gem-using-rubygems)
    * [A step-by-step guide to building a Ruby gem from scratch](https://www.honeybadger.io/blog/create-ruby-gem/)
    * My version
      * [Get copy of bashly gem. Modify it.](https://github.com/vladriabtsev/bashly)
      * `cd homelab/vbash/bashly`
      * `gem build bashly.gemspec`
      * `gem install bashly-1.2.11.gem`
* [Install bashmatic](https://github.com/kigster/bashmatic?tab=readme-ov-file#installing-a-particular-version-or-a-branch)
  * `bash -c "$(curl -fsSL https://bashmatic.re1.re); bashmatic-install -q"`
  * or specific version `bash -c "$(curl -fsSL https://bashmatic.re1.re); bashmatic-install -q -b v3.4.1"` v3.3.0 v3.2.0
* `homelab vkube` - vkube development environment
* `bashly generate` - generate vkube script

* [Install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/)
  * `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"`
  * `curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"`
  * `echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check`
  * `sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl`
  * `chmod +x kubectl`, `mkdir -p ~/.local/bin`, `mv ./kubectl ~/.local/bin/kubectl`
  * `kubectl version --client`
* `homelab k3d-test` - k3d kubernetes
  * `k3d cluster delete test`
  * `../vkube --trace  --cluster-plan k3d-test k3s install` install test k3d test kubernetes
* [K9s installation](https://k9scli.io/topics/install/)
  * `brew install derailed/k9s/k9s`


?????????????????


Export path to bash scripts:

* `export VBASH=<your bash script path>`
* `export BASHLY_SETTINGS_PATH=$VBASH/bashly-settings.yml`
* `export MY_LOG_DIR=$VBASH/logs/`

Start script: `$VBASH/my-bash-script`

[Handle line ending:](https://docs.github.com/en/get-started/git-basics/configuring-git-to-handle-line-endings)

* `git config --global core.autocrlf false` - global
* use .gitattributes file to change by repository

* `git submodule add -f https://github.com/vladriabtsev/bashly ./bashly`
* `git submodule add -f https://github.com/vladriabtsev/bashmatic.git ./bashmatic`
* `git submodule add -f https://github.com/vladriabtsev/bsfl.git ./bsfl`

## vkube.prj

Generate updated bashly script:

* `cd $VBASH/vkube.prj`
* [Edit files](https://bashly.dev/)
* `bashly generate`

Run `../vkube k3s install ../k3s-HA.yaml`

### [Synology CSI Driver for Kubernetes](https://github.com/SynologyOpenSource/synology-csi)

* from home directory `git clone https://github.com/SynologyOpenSource/synology-csi.git`
* `cd synology-csi`
* `homelab`
* `cp config/client-info-template.yml config/client-info.yml`