# password managers

[The best password manager on Linux?](https://www.roboleary.net/apps/2022/07/11/best-password-manager-on-linux)

Password manager

* [GnuPG](https://www.gnupg.org/index.html)
  * [gpg(1) - Linux man page](https://linux.die.net/man/1/gpg)
  * [How to Encrypt and Decrypt Files Using GPG in Linux](https://www.tecmint.com/gpg-encrypt-decrypt-files/)
  * [File encryption and decryption made easy with GPG](https://www.redhat.com/en/blog/encryption-decryption-gpg)
* [pass](https://www.passwordstore.org/)
  * [How to Use Pass, a Command-Line Password Manager for Linux Systems](https://www.howtogeek.com/devops/how-to-use-pass-a-command-line-password-manager-for-linux-systems/)
  * Generate gpg key with my name `gpg --full-generate-key`
    * `gpg --list-public-keys`
    * `gpg --list-public-keys --keyid-format=long`
    * `gpg --list-secret-keys`
    * `gpg --list-secret-keys --keyid-format=long`
    * `gpg insert vlad`
  * `sudo apt-get install pass`
    * Use my name for placeholder-gpg-key `pass init placeholder-gpg-key`
    * Add password `pass insert placeholder-for-subdir/placeholder-user-name`
    * Get password `pass placeholder-for-subdir/placeholder-user-name`

[KeePassXC](https://keepassxc.org/) [KeePassXC](https://github.com/keepassxreboot/keepassxc)

[KeePass C#](https://keepass.info/)

## SSH

[How to provide password directly to the sudo su -<someuser> in shell scripting](https://superuser.com/questions/1351872/how-to-provide-password-directly-to-the-sudo-su-someuser-in-shell-scripting/1351876#1351876)

* Create a file, say pass
* Make the file accessible only to you: chmod go-rwx pass
* Make it executable to you: chmod u+x pass
* Edit the file and make it a script that prints your password:
  * `#!/bin/sh`
  * `printf '%s\n' 'yourpassword'`
* Now you can do this: `SUDO_ASKPASS="./pass" sudo -A su - someuser`

Note: in this case you provide password for sudo (not for su); use the one sudo wants.
