# SSH

TODO: NEED TURN OFF PASSWORD AUTHENTICATION

[Run Arbitrarily Complex Commands Using sudo Over SSH](https://www.baeldung.com/linux/ssh-sudo-run-complex-commands)
[](https://www.cyberciti.biz/faq/linux-unix-osx-bsd-ssh-run-command-on-remote-machine-server/)
[Remotely Execute Multi-line Commands with SSH](https://thornelabs.net/posts/remotely-execute-multi-line-commands-with-ssh/)

[OpenSSH Server](https://ubuntu.com/server/docs/openssh-server)
[ssh-cheatsheet](https://grahamhelton.com/blog/ssh-cheatsheet/)
[OpenSSH for Absolute Beginners](https://youtu.be/3FKsdbjzBcc)
[Manuals](https://www.openssh.com/manual.html)
[Man](https://www.sudo.ws/docs/man/sudo.man/)
[SSH Agent Explained](https://smallstep.com/blog/ssh-agent-explained/)

Test SSH is installed: `ssh -V`
Check SSH server status: `sudo systemctl status ssh`
Check SSH server daemon status: `sudo systemctl status sshd`

Start SSH server: `sudo systemctl start ssh`
Stop SSH server: `sudo systemctl stop ssh`
Restart SSH server: `sudo systemctl restart ssh`
Enable SSH service (keep after reboot): `sudo systemctl enable ssh`

Test SSH port is open: `nc -vz host port`
Debug: `ssh -vvv [youruser]@[yourLinode]`

First SSH connection: `ssh user@host`, yes for fingerprint, password of the user on server

[SSH Agent Explained](https://smallstep.com/blog/ssh-agent-explained/)
[how-to-fix-could-not-open-a-connection-to-your-authentication-agent](https://www.geeksforgeeks.org/how-to-fix-could-not-open-a-connection-to-your-authentication-agent-in-git/)

eval "$(ssh-agent -s)" # start ssh agent
ssh-add ~/.ssh/id_rsa
echo $SSH_AUTH_SOCK
echo $SSH_AGENT_PID

ssh-add -l # list added keys
ssh-add -k # kill agent

## Use SSH Keys

Generate best keys on client machine: `ssh-keygen -t ed25519 -f ~/.ssh/my-key -C "my key"`, pathprase to protect key Q1, list files `ls .ssh`

Copy public key on remote machine: `ssh-copy-id -i ~/.ssh/my-key.pub user@host`

Client config file: `nano .ssh/config`
Host k3s1
     HostName 192.168.100.51
     IdentityFile ~/.ssh/my-key
     User user
Host k3s2
     HostName 192.168.100.52
     IdentityFile ~/.ssh/my-key
     User user
Host k3s3
     HostName 192.168.100.53
     IdentityFile ~/.ssh/my-key
     User user
Host router
     HostName 192.168.2.1
     IdentityFile ~/.ssh/my-key
     User user

SSH connection:

* `ssh k3s1`, other data will be taken from config file.
* `ssh k3s2`, other data will be taken from config file.
* `ssh k3s3`, other data will be taken from config file.
* `ssh router`, other data will be taken from config file.

Disable password authentication on server: `sudo nano /etc/ssh/sshd_config` change `ChallengeResponseAuthentication no`, `PasswordAuthentication no`, `PermitRootLogin no`

[sshd_config](https://man.freebsd.org/cgi/man.cgi?sshd_config(5)), LogLevel DEBUG (VERBOSE)

Reload ssh server settings: `sudo systemctl restart sshd`

SSH connection debug: `ssh -v user@host`, `ssh -vv user@host`, `ssh -vvv user@host`

SSH connection will not work: `ssh user@host`

192.168.100.52-53 still can connect by `ssh user@host` !!!!!!!

SSH server log: `journalctl -u ssh`, `journalctl -u ssh --since yesterday`, `journalctl -u ssh --since -3d --until -2d # logs from three days ago`, `journalctl -u ssh --since -1h # logs from the last hour`, `journalctl -u ssh --until "2022-03-12 07:00:00"`

To watch the ssh logs in realtime, use the follow flag: `journalctl -fu ssh`. Use Ctrl-C to exit out of the log monitor.

Last logged users: `lastlog`











Consider to use [Fail2ban](https://github.com/fail2ban/fail2ban) to ban hosts that cause multiple authentication errors.




ssh-copy-id -i ~/.ssh/tatu-key-ecdsa user@host
