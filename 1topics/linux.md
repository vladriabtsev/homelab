# Linux

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Linux](#linux)
  - [Useful links](#useful-links)
  - [General](#general)
  - [Directory and files](#directory-and-files)
  - [Disk](#disk)
  - [Network](#network)
  - [How to check if port is in use](#how-to-check-if-port-is-in-use)
    - [Testing if a port is open from a bash script](#testing-if-a-port-is-open-from-a-bash-script)

<!-- /code_chunk_output -->

## Useful links

[https://linuxhandbook.com/](https://linuxhandbook.com/)

[The 50 Most Popular Linux & Terminal Commands - Full Course for Beginners](https://www.youtube.com/watch?v=ZtqBQ68cfJc)

## General

- whoami #current user name
- man #manuals `q` for quit, `space` - next page
- clear #clear terminal screen `-x` to keep history on screen to scroll, Ctrl-l is shortcut for clear

## Directory and files

- pwd   # print working directory
- ls    # list context of directory
- cd    # change current working directory
- mkdir # create new directory
- touch # create new files
- rmdir # remove empty directory
- rm    # remove files or directories, including not empty by using flag -r
- open  # open file in UI Mac, need
- mv    # move or rename
- cp    # copy
- head  # print head of file
- tail  # print last lines of file
- date
- `>`   # redirecting standard output
- `>>`  # redirecting standard output and append file
- cat   # print all file or concatenate files, -n for line numbers
- less  # scrollable file view, 'q' for quit, '/my' to search for 'my', 'space' for page down, 'b' for page up, arrow keys to scroll, 'Shift-g' to open end of file, 'g' to open beginning of file, 'q' for quit
- echo  # print text or redirect your text to file
- wc    # count lines, words, bytes
- `|`   # piping command output to input of another command
- sort  # sorting and unique
- uniq  # unique or not unique, but compare only with next line
- expansions
  - `~` user home directory
  - `$` beginning of environmental variable
  - `*` any one or many characters
  - `?` any one character
  - `{}` each in comma separated value from list in curly braces
  - `.` current folder
  - `..` parent folder
- diff  # find difference of two files, '-y' view side by side, '-u' like Git
- find  # find file and folders, and execute command
- grep  # text search in files
- du    # disk usage by folders
- df    # disk usage by file system
- history # show history of all commands
  - '!12' # execute command under number 12 from history
- ps    # process status
  - ps # current user processes
  - ps ax # all processes
- top   # top intensive processes
- kill  # kill process by ID
- killall # kill processes by name
- job   # get running jobs, ^C to cancel and ^Z to stop running in foreground, add '&' at the end of command to run it in background
- bg    # resume job in background
- fg    # resume job in foreground
- gzip, gunzip  # compress files
- tar   # archive or unarchive, with or without compression, many files in single output file
- nano  # editor
- alias # `alias count='echo {1..365}'`, use " to resolve env variable at time alias definition and ' at time of invocation, create temporary alias for command with parameters, add in .bashrc to persist, `source .bashrc` to reload changes
- xarg  # pipe result previous command into parameters of next command
- ln    # link to file, hard link just another name for existing file data, soft link is link to another file name (even on another disk)
- who   # logged users
- su    # switch user
- sudo  # super user do
- passwd # change, disable, lock, delete, expire password
- chown # change owner and group owner of file or directory
- chmod # change permissions for file or directory, -rwxr--r-- (type, owner, owner group, other)

## Disk

## Network

## How to check if port is in use

[How to check if port is in use.](https://www.cyberciti.biz/faq/unix-linux-check-if-port-is-in-use-command/)

- `sudo netstat -tulpn | grep LISTEN` - deprecated
- `sudo ss -tulpn | grep LISTEN` - use instead netstat
- `sudo lsof -i -P -n | grep LISTEN`
- `sudo lsof -i:22 ## see a specific port such as 22 ##`
- `sudo nmap -sTU -O IP-address-Here`
- `less /etc/services` - list well known services (all)

### Testing if a port is open from a bash script

Test local port.

``` bash
#!/bin/bash
dest_box="aws-prod-server-42"
echo "Testing the ssh connectivity ... "
if ! (echo >/dev/tcp/$dest_box/22) &>/dev/null
then
    echo "$0 cannot connect to the $dest_box. Check your vpn connectivity."
else
    echo "Running the ansible playboook ..."
    ansible-playbook -i hosts --ask-vault-pass --extra-vars '@cluster.data.yml' main.yaml
fi
```

Test remote port.

``` bash
#!/bin/bash
dest_box="aws-prod-server-42"
timeout="5" # timeouts in seconds
echo "Testing the ssh connectivity in $timeout seconds ... "
# make sure 'nc' is installed, else die ..
if ! type -a nc &>/dev/null
then
    echo "$0 - nc command not found. Please install nc and run the script again."
    exit 1
fi
if !  nc -w "$timeout" -zv "${dest_box}" 22  &>/dev/null
then
    echo "$0 cannot connect to the $dest_box. Check your vpn connectivity."
    exit 1
else
    echo "Running the ansible playboook ..."
    ansible-playbook -i hosts --ask-vault-pass --extra-vars '@cluster.data.yml' main.yaml
fi
```

Python.

``` python
#!/usr/bin/python3
# Tested on Python 3.6.xx and 3.8.xx only (updated from Python 2.x)
import socket
 
# Create a new function 
def check_server_tcp_port(my_host_ip_name, my_tcp_port, timeout=5):
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.settimeout(timeout)
    try:
        s.connect((my_host_ip_name, my_tcp_port))
        print(f"TCP port {my_tcp_port} is open for the {my_host_ip_name}.")
        s.close()
        return True
    except socket.timeout:
        print(f"TCP port {my_tcp_port} is closed or timed out for the {my_host_ip_name}.")
        return False
 
# Test it 
check_server_tcp_port("localhost", 22)
check_server_tcp_port("192.168.2.20", 22)
```
