# remote administration

## RDP

[Sysinternals Utilities Index](https://learn.microsoft.com/en-us/sysinternals/downloads/)

### [Remote Desktop Connection Manager v2.93](https://learn.microsoft.com/en-us/sysinternals/downloads/rdcman)

## [yazi](https://github.com/sxyazi/yazi) ???

[How To Use Yazi: An Awesome Terminal File Manager Written In Rust](https://www.youtube.com/watch?v=iKb3cHDD9hw)

## tmux terminal

[My Ultimate Tmux, Zsh, and NeoVim Coding Setup!](https://www.youtube.com/watch?v=u9_jei6Zg0k)

Tutorials

* [Getting-Started](https://github.com/tmux/tmux/wiki/Getting-Started) !!!
* https://www.youtube.com/watch?v=o7Dg1kmjhfQ
* https://man7.org/linux/man-pages/man1/tmux.1.html

- Standard
ctrl-b %	split the screen in half from left to right
ctrl-b "	split the screen in half from top to bottom
ctrl-b x	kill the current pane
ctrl-b d	detach from tmux, leaving everything running in the background
tmux attach -t 0
ctrl-b <arrow key>	switch to the pane in whichever direction you press
ctrl-b z	zoom current pane
ctrl-b N	next
ctrl-b P	previous
ctrl-b 5	pane number 5

ctrl-b c new window
ctrl-b 0 open window 0
ctrl-b,git rename window to git

ctrl-b : execute command

ctrl-b [ copy mode
PgDn, PgUp, G, g, left, top, right, down
space - start selecting text
ctrl-w or enter to copy selected text
ctrl-b ] paste text
? search to top
/ search to bottom
n, N navigation for search results
q quit copy mode

exit     close windows or pane

tmux ls - list sessions
tmux rename-session -t 0 git
tmux attach -t git
tmux new -s git
tmux kill-session -t git

- .tmux.conf  https://www.youtube.com/watch?v=bjBjZvZsgks

### Send prefix

set-option -g prefix C-a
unbind-key C-a
bind-key C-a send-prefix
 
### Use Alt-arrow keys to switch panes

bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D
 
### Shift arrow to switch windows

bind -n S-Left previous-window
bind -n S-Right next-window
 
### Mouse mode

setw -g mouse on
 
### Set easier window split keys

bind-key v split-window -h
bind-key h split-window -v
 
### Easy config reload

bind-key r source-file ~/.tmux.conf \; display-message "~/.tmux.conf reloaded."

### List of plugins

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'tmux-plugins/tmux-resurrect'

### Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)

run '~/.tmux/plugins/tpm/tpm'
- end .tmux.conf

ctrl-a v	split the screen in half from left to right
ctrl-a h	split the screen in half from top to bottom
alt <arrow key>	switch to the pane in whichever direction you press
shift-left	next
shift-right	previous
ctrl-a r	reload .tmux.conf
-- copy and paste https://github.com/tmux-plugins/tmux-yank

## bash configuration

* Change default shell: `chsh -s $(which bash)`
* Check `echo $SHELL`, `$SHELL --version`
* `cp /mnt/d//dev/homelab/.bashrc ~/.bashrc`

[How to Customize (and Colorize) Your Bash Prompt](https://www.baeldung.com/linux/customize-bash-prompt)

[Bash Prompt Customization](https://wiki.archlinux.org/title/Bash/Prompt_customization)

[Create a Temporary Change to the BASH Prompt](https://phoenixnap.com/kb/change-bash-prompt-linux#ftoc-heading-3)

[bash-prompt](https://ioflood.com/blog/bash-prompt/)

[bash manual](https://www.gnu.org/savannah-checkouts/gnu/bash/manual/bash.html#Controlling-the-Prompt)

## [zsh](https://ohmyz.sh/)

* Install: `sudo apt install zsh`, `zsh --version`
* Change default shell: `chsh -s $(which zsh)`
* Check `echo $SHELL`, `$SHELL --version`

[ZSH Documentation](https://zsh.sourceforge.io/Doc/)

[Zsh: The Developer's Dream Shell! Say Goodbye to Bash!](https://www.youtube.com/watch?v=5F4T_iTeN08)

[ohmyzsh](https://github.com/ohmyzsh/ohmyzsh): `sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"`

[Cheatsheet](https://github.com/ohmyzsh/ohmyzsh/wiki/Cheatsheet)

[Customization](https://github.com/ohmyzsh/ohmyzsh/wiki/Customization)

## Useful scripts for kubectl

* `sudo apt-get update`
* [ealias](https://github.com/politza/ealias): download and insert in `~/.bashrc` folder.
* [recursively searches the current directory](https://github.com/BurntSushi/ripgrep): `sudo apt-get install ripgrep`
* !!! no need [How to Install the Latest Emacs on Ubuntu](https://itsfoss.com/install-emacs-ubuntu/) `sudo apt install emacs`, check `emacs -nw`
* [YAML processor](https://github.com/mikefarah/yq): `sudo snap install yq`
* [fzf command-line fuzzy finder](https://github.com/junegunn/fzf): `sudo apt install fzf`
* [Getting started with the AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-getting-started.html): `sudo snap install aws-cli --classic`
* [AWSP - AWS Profile Switcher ???](https://github.com/johnnyopao/awsp): ``
* [???](https://github.com/jumpbox-academy/awsp)
* [AWS credential profile changer ???](https://github.com/antonbabenko/awsp/tree/master)

[How I use kubectl](https://www.youtube.com/watch?v=y5VkuO7nBEM)

Copy k8s.zsh into `$ZSH_CUSTOM` folder.

## [kubecolor](https://kubecolor.github.io/setup/install/)

## [zoxide](https://github.com/ajeetdsouza/zoxide)
