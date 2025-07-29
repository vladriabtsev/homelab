# remote administration

## RDP

[Sysinternals Utilities Index](https://learn.microsoft.com/en-us/sysinternals/downloads/)

### [Remote Desktop Connection Manager v2.93](https://learn.microsoft.com/en-us/sysinternals/downloads/rdcman)

## [yazi](https://github.com/sxyazi/yazi) ???

[How To Use Yazi: An Awesome Terminal File Manager Written In Rust](https://www.youtube.com/watch?v=iKb3cHDD9hw)

## Microsoft Terminal, only from Windows

Install Windows Terminal from the [Microsoft Store](https://apps.microsoft.com/detail/9n0dx20hk701?hl=en-US&gl=US)

* [What is Windows Terminal?](https://learn.microsoft.com/en-us/windows/terminal/)
  * [Tutorial - Set up a custom prompt for PowerShell or WSL with Oh My Posh](https://learn.microsoft.com/en-us/windows/terminal/tutorials/custom-prompt-setup)
  * [Use the Command Palette](https://learn.microsoft.com/en-us/windows/terminal/install#invoke-the-command-palette)
  * [Set up custom actions like keyboard shortcuts to make the terminal feel natural to your preferences](https://learn.microsoft.com/en-us/windows/terminal/#custom-actions)
  * [Set up the default startup profile](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/startup)
  * [Customize the appearance: theme, color schemes, name and starting directory, background image, etc.](https://learn.microsoft.com/en-us/windows/terminal/customize-settings/color-schemes)
  * [Learn about the search feature](https://learn.microsoft.com/en-us/windows/terminal/search)
  * [Windows Terminal tips and tricks](https://learn.microsoft.com/en-us/windows/terminal/tips-and-tricks)
  * [Find tutorials on how to set up a customized command prompt, SSH profiles, or tab titles](https://learn.microsoft.com/en-us/windows/terminal/tutorials/custom-prompt-setup)
  * [A troubleshooting guide](https://learn.microsoft.com/en-us/windows/terminal/troubleshooting)
  * [Find a custom terminal gallery](https://learn.microsoft.com/en-us/windows/terminal/custom-terminal-gallery/custom-schemes)
* [How do I open the WSL CLI on Windows 10?](https://superuser.com/questions/1755766/how-do-i-open-the-wsl-cli-on-windows-10)
* [How do I get Windows 10 Terminal to launch WSL?](https://stackoverflow.com/questions/56765067/how-do-i-get-windows-10-terminal-to-launch-wsl)

## Kitty terminal, from many OS

[Kitty overview](https://sw.kovidgoyal.net/kitty/overview/#design-philosophy)

## Warp

## [WezTerm](https://wezterm.org/features.html)

## Tmux terminal multiplexer

* Install `sudo snap install tmux --classic`
* [Make tmux Pretty and Usable](https://hamvocke.com/blog/a-guide-to-customizing-your-tmux-conf/)
* [Oh my tmux!](https://github.com/gpakosz/.tmux)
  * 
* [Put All of Your Tmux Configs and Plugins in a .config/tmux Directory](https://nickjanetakis.com/blog/put-all-of-your-tmux-configs-and-plugins-in-a-config-tmux-directory)
  * Create folder ~/.config/tmux/plugins/tmp
  * Move file ~/.tmux.conf to ~/.config/tmux/tmux.conf
  * Instal [TPM](https://github.com/tmux-plugins/tpm)
    * `git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm`
    * Modify tmux.conf file according [TPM](https://github.com/tmux-plugins/tpm), but with changed Initialize TMUX plugin manager line `run '~/.config/tmux/plugins/tpm/tpm'`
* `tmux source-file ~/.config/tmux/tmux.conf` testing config file
  * C-b :, kill-server - to exit tmux
* Installing plugins
  * Add new plugin to ~/.config/tmux/tmux.conf with set -g @plugin '...'
  * Press prefix + I (capital i, as in Install) to fetch the plugin.
* Uninstalling plugins
  * Remove (or comment out) plugin from the list.
  * Press prefix + alt + u (lowercase u as in uninstall) to remove the plugin.

### Tmux Plugins

Plugin lists

* [tmux plugins](https://github.com/tmux-plugins/list)
* [Useful TMUX Plugins Which I Frequently Use At Work](https://medium.com/@hammad.ai/useful-tmux-plugins-which-i-frequently-use-at-work-41a9b46f7bcb)

Tmux Plugins

* [tmux-sensible](https://github.com/tmux-plugins/tmux-sensible)
* [tmux-git-autofetch](https://github.com/thepante/tmux-git-autofetch/)
  * `set -g @plugin 'thepante/tmux-git-autofetch'`
  * `set -g @git-autofetch-skip-paths ".*"` - Defines regex pattern to skip specific paths to autofetch. Default is empty.
  * `set -g @git-autofetch-scan-paths "~/Projects/.*|.*\/probandoski"` - Defines regex pattern for paths to enable autofetching. Higher priority than skip-paths pattern. Default is empty.
  * `set -g @git-autofetch-frequency "1"` - Set the fetching interval in minutes. Default is 3.
  * `set -g @git-autofetch-logging "true"` - Enables or disables debug logging. Default is false.
* [tmux-autoreload](https://github.com/b0o/tmux-autoreload)
  * `sudo apt install entr`
  * `set-option -g @tmux-autoreload-configs '~/.config/tmux/tmux.conf'`
  * `set-option -g @plugin 'b0o/tmux-autoreload'`
* [tmux-menus](https://github.com/jaclu/tmux-menus), the default trigger is '<prefix> + \'
  * `set -g @menus_config_file "~/.configs/tmux/tmux.conf"`
  * `set -g @menus_without_prefix 'Yes'` - now the default trigger is '\'
* [tmux-sidebar](https://github.com/tmux-plugins/tmux-sidebar) - it opens a tree directory listing for the current path
  * `set -g @plugin 'tmux-plugins/tmux-sidebar'`
  * prefix + Tab - toggle sidebar with a directory tree
  * prefix + Backspace - toggle sidebar and move cursor to it (focus it)
  * Options
    * How can I run some other command in the sidebar? `set -g @sidebar-tree-command 'ls -1'`
    * Can I have the sidebar on the right? `set -g @sidebar-tree-position 'right'`
    * I see the tree sidebar uses 'less' as a pager. I would like to use 'view'. `set -g @sidebar-tree-pager 'view -'`
    * The default sidebar width is 40 columns. I want the sidebar to be wider by default! `set -g @sidebar-tree-width '60'`
    * Can I colorize the tree directory listing in the sidebar? `set -g @sidebar-tree-command 'tree -C'`
* [tmux-copycat](https://github.com/tmux-plugins/tmux-copycat) - regex searches
  * `set -g @plugin 'tmux-plugins/tmux-copycat'`
  * prefix + / - regex search (strings work too). Grep is used for searching. Searches are case insensitive.
  * Predefined searches
    * prefix + ctrl-f - simple file search
    * prefix + ctrl-g - jumping over git status files (best used after git status command)
    * prefix + alt-h - jumping over SHA-1/SHA-256 hashes (best used after git log command)
    * prefix + ctrl-u - url search (http, ftp and git urls)
    * prefix + ctrl-d - number search (mnemonic d, as digit)
    * prefix + alt-i - ip address search
  * "Copycat mode" bindings
    * n - jumps to the next match
    * N - jumps to the previous match
      * To copy a highlighted match:
        * Enter - if you're using Tmux vi mode
        * ctrl-w or alt-w - if you're using Tmux emacs mode
* [tmux-yank](https://github.com/tmux-plugins/tmux-yank) - Copy to the system clipboard in tmux from Linux, macOS, Cygwin, WSL.
  * `set -g @plugin 'tmux-plugins/tmux-yank'`
  * Normal Mode
    * prefix–y — copies text from the command line to the clipboard.
    * prefix–Y — copy the current pane's current working directory to the clipboard.
  * Copy Mode
    * y — copy selection to system clipboard.
    * Y (shift-y) — "put" selection. Equivalent to copying a selection, and pasting it to the command line.
* [tmux-open](https://github.com/tmux-plugins/tmux-open) - opening highlighted selection directly from Tmux copy mode
  * `set -g @plugin 'tmux-plugins/tmux-open'`
  * In tmux copy mode
    * o - "open" a highlighted selection with the system default program. open for OS X or xdg-open for Linux.
    * Ctrl-o - open a highlighted selection with the $EDITOR
    * Shift-s - search the highlighted selection directly inside a search engine (defaults to google).
* [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) - saves all the little details from your tmux environment so it can be completely restored after a system restart
  * `set -g @plugin 'tmux-plugins/tmux-resurrect'`
  * prefix + Ctrl-s - save
  * prefix + Ctrl-r - restore
* [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) - continuous saving of tmux environment, automatic tmux start when computer/server is 
turned on, automatic restore when tmux is started
  * `set -g @continuum-restore 'on'`
  * `set -g @plugin 'tmux-plugins/tmux-continuum'`
* [tome](https://github.com/laktak/tome) - Playbooks are a simple but powerful tool for your shell and terminal apps.
  * `set -g @plugin 'laktak/tome'`
  * With tmux: press <tmux-prefix> p
  * With Vim only: run vim .playbook.sh or open a playbook file
* [tmux-logging](https://github.com/tmux-plugins/tmux-logging) - Logging of all output in the current pane
  * `set -g @plugin 'tmux-plugins/tmux-logging'`
  * `set -g history-limit 50000`
  * Logging
    * Toggle (start/stop) logging in the current pane: prefix + shift + p
    * File name format: tmux-#{session_name}-#{window_index}-#{pane_index}-%Y%m%dT%H%M%S.log
    * File path: $HOME (user home dir). Example file: tmux-screen-capture-my-session-0-1-20140527T165614.log
  * Screen Capture
    * Save visible text, in the current pane. Equivalent of a "textual screenshot". Key binding: prefix + alt + p
    * File name format: tmux-screen-capture-#{session_name}-#{window_index}-#{pane_index}-%Y%m%dT%H%M%S.log
  * Save complete history
    * Key binding: prefix + alt + shift + p
    * File name format: tmux-history-#{session_name}-#{window_index}-#{pane_index}-%Y%m%dT%H%M%S.log
  * Clear pane history with prefix + alt + c
* [tmux-sessionist](https://github.com/tmux-plugins/tmux-sessionist) - tmux utilities for manipulating tmux sessions.
  * `set -g @plugin 'tmux-plugins/tmux-sessionist'`
  * prefix + g - prompts for session name and switches to it.
  * prefix + C (shift + c) - prompt for creating a new session by name.
  * prefix + X (shift + x) - kill current session without detaching tmux.
  * prefix + S (shift + s) - switches to the last session.
  * prefix + @ - promote current pane into a new session.
  * prefix + ctrl-@ - promote current window into a new session.
  * prefix + t<secondary-key> - join currently marked pane (prefix + m) to current session/window, and switch to it. Secondary-keys
    * h, -, ": join horizontally
    * v, |, %: join vertically
    * f, @: join full screen
* [tmux-pain-control](https://github.com/tmux-plugins/tmux-pain-control) - controlling panes. Adds standard pane navigation bindings.
  * `set -g @plugin 'tmux-plugins/tmux-pain-control'`
  * Navigation
    * prefix + h and prefix + C-h select pane on the left
    * prefix + j and prefix + C-j select pane below the current one
    * prefix + k and prefix + C-k select pane above
    * prefix + l and prefix + C-l select pane on the right
  * Resizing panes
    * prefix + shift + h resize current pane 5 cells to the left
    * prefix + shift + j resize 5 cells in the down direction
    * prefix + shift + k resize 5 cells in the up direction
    * prefix + shift + l resize 5 cells to the right
  * Splitting panes
    * prefix + | split the current pane into two, left and right.
    * prefix + - split the current pane into two, top and bottom.
    * prefix + \ split current pane full width into two, left and right.
    * prefix + _ split current pane full height into two, top and bottom.
  * Swapping windows
    * prefix + < moves current window one position to the left
    * prefix + > moves current window one position to the right
* [tmux-fzf](https://github.com/sainnhe/tmux-fzf) - many ... [fzf environment variables](https://github.com/junegunn/fzf/#environment-variables)
  * `set -g @plugin 'sainnhe/tmux-fzf'`
  * To launch tmux-fzf, press prefix + F (Shift+F).

* ??? [tmux-better-mouse-mode](https://github.com/NHDaly/tmux-better-mouse-mode)
* ??? [tmux-tea](https://github.com/2KAbhishek/tmux-tea) - session manager, integrations with tmuxinator, fzf, zoxide
  * `set -g @plugin '2kabhishek/tmux-tea'`
* ??? [tmux-tilit](https://github.com/2KAbhishek/tmux-tilit) - tiling window manager features and intuitive keybindings
  * `set -g @plugin '2kabhishek/tmux-tilit'`
    * prefix + Alt + ←/↓/↑/→ Focus pane in direction
    * prefix + Alt + Shift + ←/↓/↑/→ Move pane in direction
    * prefix + Alt + h/j/k/l Resize pane in direction
* not working? [tmux2k](https://github.com/2KAbhishek/tmux2k) - enhance your tmux status bar
  * `set -g @plugin '2kabhishek/tmux2k'`
* ??? better than tmux-sidebar  [treemux](https://github.com/kiyoon/treemux)
* [extrakto ???](https://github.com/laktak/extrakto) - It is sort of a clipboard manager. It provides a search bar which fuzzy matches the text in your search query from your terminal session.
* [tmux-named-snapshot ???](https://github.com/spywhere/tmux-named-snapshot)
* [tmux-mighty-scroll ???](https://github.com/noscript/tmux-mighty-scroll)
* too much CPU [tmux-powerline](https://github.com/erikw/tmux-powerline) - hackable powerline status bar consisting of segments
  * ??? [Nerd Font](https://github.com/ryanoasis/nerd-fonts?tab=readme-ov-file#font-installation)
    * `curl -OL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz`
    * `set -g @plugin 'erikw/tmux-powerline'`
* depend on tmux-powerline [tmux-prefix-highlight](https://github.com/tmux-plugins/tmux-prefix-highlight) -  highlights when you press tmux prefix key.
  * `set -g @plugin 'tmux-plugins/tmux-prefix-highlight'`
  * `set -g status-right '#{prefix_highlight} | %a %Y-%m-%d %H:%M'`
  * `set -g @prefix_highlight_show_copy_mode 'on'`
* depend on tmux-powerline [tmux-mem-cpu-load](https://github.com/thewtex/tmux-mem-cpu-load)
  * `set -g @plugin 'thewtex/tmux-mem-cpu-load'`
  * `set -g status-right "#[fg=green]#($TMUX_PLUGIN_MANAGER_PATH/tmux-mem-cpu-load/tmux-mem-cpu-load --colors --powerline-right --interval 2)#[default]"`

### Tutorials

[manual page tmux](https://web.archive.org/web/20220308205829/https://man.openbsd.org/OpenBSD-current/man1/tmux.1)

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

### [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm)

* Install `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`


* https://medium.com/@hammad.ai/useful-tmux-plugins-which-i-frequently-use-at-work-41a9b46f7bcb
* https://qmacro.org/blog/posts/2023/11/10/til-two-tmux-plugin-manager-features/
  
Plugins

* tmux-sensible - provides a number of sensible defaults for Tmux, such as enabling mouse support and making it easier to split and resize panes.
* tmux-continuum - automatically saves and restores your Tmux sessions, so that you can pick up where you left off even if your computer crashes or you lose your connection.
* tmux-yank - allows you to copy and paste text to and from the system clipboard.
* tmux-powerline - provides a powerful and customizable status bar for Tmux.
* tmux-resurrect - allows you to resume a Tmux session after it has been killed or terminated.
* aw-watcher-tmux - keep a log of my activities.
* tmux-autoreload -  a “file watcher” designed for tmux.conf.
* tmux-cowboy - help you terminate unresponsive processes running within your terminal sessions.
* tmux-menus - TUI solution for context menu inside the terminal
* tmux-sidebar - provides you with a sidebar, which shows you your current working directory and, recursively, their inner contents and the contents of their subfolders.
* tmux-mighty-scroll - ???
* tmux-fzf - can perform operations with panes, windows or sessions like for example resize panes, create new or murder old sessions.
* tmux-named-snapshot - works as an extension of tmux-resurrect. It gives you the ability to save and restore sessions in your system.
* tmux-mem-cpu-load - useful when you are cutting it very close to the CPU/RAM usage.
* tmux-prefix-highlight - only highlights when you press TMUX prefix key. The highlight is shown in the status bar below a TMUX session.
* tome - playbook which stores multiple shell commands.
* tmux-logging - logs the activities which go inside a TMUX session.

### tmux projects

[Tmuxifier](https://github.com/jimeh/tmuxifier) !!?

* Install `git clone https://github.com/jimeh/tmuxifier.git ~/.tmuxifier`
* `tmuxifier new-session blog` This created a bash file blog.session.sh in which you can write the script for setting up your session.

[tmuxinator](https://github.com/tmuxinator/tmuxinator)

* Install `gem install tmuxinator`
* Install completion `wget https://raw.githubusercontent.com/tmuxinator/tmuxinator/master/completion/tmuxinator.bash -O /etc/bash_completion.d/tmuxinator.bash`
* Check default editor `echo $EDITOR`. Set editor `export EDITOR='nano'`
* Start new project `tmuxinator new [project]` or in current folder `tmuxinator new --local [project]`
  * --local ../k3s-ha for tmux k3s-ha cluster settings

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
