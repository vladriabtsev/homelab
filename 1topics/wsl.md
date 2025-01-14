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


## Remmina

`sudo apt update`
`sudo apt upgrade`
`sudo apt install remmina`
