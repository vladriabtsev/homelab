# bats-core

* [Welcome to bats-core’s documentation!](https://bats-core.readthedocs.io/en/stable/)
* [Bats-core: Bash Automated Testing System](https://github.com/bats-core/bats-core)
* [BATS (Bash Automated Testing System) for VSCode](https://github.com/bats-core/bats-vscode)
* [BATS Test Runner](https://github.com/kenherring/bats-test-runner)

Install bats:

* `git clone https://github.com/bats-core/bats-core.git`
* `cd bats-core`
* `./install.sh /usr/local`

Install into folder with my bash projects:

* `git submodule add https://github.com/bats-core/bats-core.git test/bats`
* `git submodule add https://github.com/bats-core/bats-support.git test/test_helper/bats-support`
* `git submodule add https://github.com/bats-core/bats-assert.git test/test_helper/bats-assert`
* `git submodule add https://github.com/bats-core/bats-file.git test/test_helper/bats-file`

Create `.bats/` subfolder in this folder for logs. Add `.bats/` in .gitignore file.
