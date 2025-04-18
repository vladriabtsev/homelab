# Start using

Export path to bash scripts:

* `export VBASH=<your bash script path>`
* `export BASHLY_SETTINGS_PATH=$VBASH/bashly-settings.yaml`
* `export MY_LOG_DIR=$VBASH/logs/`

Generate bashly script:

* `cd $VBASH/vkube.prj`
* `bashly generate`

Start script: `$VBASH/my-bash-script`

## My bashly gem

[How To Package And Distribute Ruby Applications As a Gem Using RubyGems](https://www.digitalocean.com/community/tutorials/how-to-package-and-distribute-ruby-applications-as-a-gem-using-rubygems)

[A step-by-step guide to building a Ruby gem from scratch](https://www.honeybadger.io/blog/create-ruby-gem/)

Install

* [Install Ruby and RubyGems](https://www.ruby-lang.org/en/documentation/installation/)
  * `brew install ruby-install`
  * `ruby-install ruby`
* Get my copy of bashly gem. Modify it.
* `cd homelab/vbash/bashly`
* `gem build bashly.gemspec`
* `gem install bashly-1.2.11.gem`
