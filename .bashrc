export TERM=xterm-256color
# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color|*-256color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

#export TERM=screen-256color # tmux terminal description
#export TERM=screen-256color-bce # use if tmux is not clearing the background colors correctly
export GOROOT=/usr/local/go-1.23.4
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$HOME/.tmuxifier/bin:"$PATH:/snap/bin":$PATH
export EDITOR='nano'

source <(kubectl completion bash)
source <(velero completion bash)
alias v=velero
complete -F __start_velero v

#alias bashly='docker run --rm -it --user $(id -u):$(id -g) --volume "$PWD:/app" dannyben/bashly'

homelab() {
  # $1 - environment: k3s-test, k3s-HA
  cd /mnt/d//dev/homelab
  cp ~/.bashrc .bashrc
  source ealias.sh
  source k8s.sh
  #sudo cp k8s.sh /usr/local/bin/
#  if [ -z "$SSH_AUTH_SOCK" ]; then
#    eval "$(ssh-agent -s)" # start ssh agent
#    ssh-add ~/.ssh/id_rsa
#  fi
  if [ -n "$1" ]; then
    if [[ "$1" = "k3d-test" ]]; then
      cd vbash
      cd v-tests
      echo "For k3d-test: ./bats/bin/bats ./"
      echo "./bats/bin/bats ./vkube-k3s.bats --filter-tags tag:tagname"
      echo "  Tag names: secret, core, storage, storage-separate, storage-speed"
    elif [[ "$1" = "k3s-HA" ]]; then
      cd vbash
      ek k3s-HA
      if [ -n "$2" ]; then
        cd vkube-data
        cd k3s-HA
        cd apps
        cd "$2"
        ls
        echo "kubectl apply -k <kustomization directory>"
      else
        echo "Examples: ./vkube --cluster-plan k3s-HA k3s install --core --storage"
        echo "./vkube --cluster-plan k3s-HA k3s install --storage-classes-only"
        echo "./vkube --cluster-plan k3s-HA k3s storage-speed --storage-class office-synology-csi-nfs-tmp"
        echo "./vkube --cluster-plan k3s-HA k3s storage-speed --storage-class longhorn-nvme --distr busybox"
      fi
    elif [[ "$1" = "vkube" ]]; then
      cd vbash
      cd vkube.prj
      echo "Examples: bashly generate"
    else
      if [ -n "$1" ]; then
        echo "Warning: name of preconfigured environment '$1'. Expected: 'vkube', 'k3d-test', 'k3s-HA'"
      else
        echo "Not preconfigured environment is selected. Use 'vkube', 'k3d-test', 'k3s-HA' as parameter for 'homelab' script"
      fi
    fi
  fi
}
complete -o default -F __start_kubectl k
#[[ -f ~/.bashmatic/init.sh ]] && source ~/.bashmatic/init.sh
#export PATH="${PATH}:${BASHMATIC_HOME}/bin"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
export PATH=$HOME/.rubies/ruby-3.4.3/bin:$PATH
export VBASH=/mnt/d/dev/homelab/vbash
export BASHLY_SETTINGS_PATH=$VBASH/bashly-settings.yml
export MY_LOG_DIR=$VBASH/logs/
