# sudo

[Run Arbitrarily Complex Commands Using sudo Over SSH](https://www.baeldung.com/linux/ssh-sudo-run-complex-commands)

[sudo over ssh](https://stackoverflow.com/questions/10310299/what-is-the-proper-way-to-sudo-over-ssh)

[sudo -S without history](https://superuser.com/questions/67765/sudo-with-password-in-one-command-line/67766#67766)

* `export HISTIGNORE='*sudo -S*'`
* `sudo -S <<< "<your_password>" command`
* `echo "<your_password>" | sudo -S -k whoami`
