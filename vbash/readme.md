# Start using

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

## bashmatic

[bashmatic](https://github.com/kigster/bashmatic?tab=readme-ov-file#installing-a-particular-version-or-a-branch)

* `bash -c "$(curl -fsSL https://bashmatic.re1.re); bashmatic-install -q -b v3.4.1"` v3.3.0 v3.2.0

## bashly - modified version

[Bashly](https://bashly.dev/)

[How To Package And Distribute Ruby Applications As a Gem Using RubyGems](https://www.digitalocean.com/community/tutorials/how-to-package-and-distribute-ruby-applications-as-a-gem-using-rubygems)

[A step-by-step guide to building a Ruby gem from scratch](https://www.honeybadger.io/blog/create-ruby-gem/)

Install

* [Install Ruby and RubyGems](https://www.ruby-lang.org/en/documentation/installation/)
  * `brew install ruby-install`
  * `ruby-install ruby`
* [Get copy of bashly gem. Modify it.](https://github.com/vladriabtsev/bashly)
* `cd homelab/vbash/bashly`
* `gem build bashly.gemspec`
* `gem install bashly-1.2.11.gem`

## vkube.prj

Generate updated bashly script:

* `cd $VBASH/vkube.prj`
* [Edit files](https://bashly.dev/)
* `bashly generate`

Run `../vkube cluster install ../k3s-ha.yaml`

### [Synology CSI Driver for Kubernetes](https://github.com/SynologyOpenSource/synology-csi)

* from home directory `git clone https://github.com/SynologyOpenSource/synology-csi.git`
* `cd synology-csi`
* `homelab`
* `cp config/client-info-template.yml config/client-info.yml`