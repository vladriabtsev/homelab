# WSL

[How to install Linux on Windows with WSL](https://learn.microsoft.com/en-us/windows/wsl/install)

Version: `wsl -l -v`

[Working across Windows and Linux file systems](https://learn.microsoft.com/en-us/windows/wsl/filesystems)



WSL is accessible as wsl$, the path is your distribution name (wsl -l -q).

Windows Explore: `\\wsl$\`


Unregister the distribution and deletes the root filesystem: `wsl --unregister Alpine`



[Map a network drive in Windows](https://support.microsoft.com/en-us/windows/map-a-network-drive-in-windows-29ce55d1-34e3-a7e2-4801-131475f9557d)

Windows startup folder contains script executed at startup:
`%SystemRoot%\explorer.exe "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"`

[How do I run a PowerShell script when the computer starts?](https://stackoverflow.com/questions/20575257/how-do-i-run-a-powershell-script-when-the-computer-starts)

## SSH to WSL

[How to SSH into WSL2 on Windows 10 from an external machine](https://www.hanselman.com/blog/how-to-ssh-into-wsl2-on-windows-10-from-an-external-machine)
[WSL 2 Setup for SSH Remote Access](https://medium.com/@wuzhenquan/windows-and-wsl-2-setup-for-ssh-remote-access-013955b2f421)
[Configuring SSH access into WSL 1 and WSL 2](https://jmmv.dev/2022/02/wsl-ssh-access.html)

## Remmina

`sudo apt update`
`sudo apt upgrade`
`sudo apt install remmina`
