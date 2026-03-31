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
HISTSIZE=50000
HISTFILESIZE=100000

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
source ~/.dircolors_cache # run the following to get the file: dircolors -b > ~/.dircolors_cache
# alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'

# colored GCC warnings and errors
#export GCC_COLORS='error=01;31:warning=01;35:note=01;36:caret=01;32:locus=01:quote=01'

# some more ls aliases
# alias ll='ls -alF'
# alias la='ls -A'
# alias l='ls -CF'


# if [ -f ~/.bash_aliases ]; then
#     . ~/.bash_aliases
# fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
# if ! shopt -oq posix; then
#   if [ -f /usr/share/bash-completion/bash_completion ]; then
#     . /usr/share/bash-completion/bash_completion
#   elif [ -f /etc/bash_completion ]; then
#     . /etc/bash_completion
#   fi
# fi

# End of ML4W presetup

export PATH="$HOME/.local/bin:$PATH"
# created with Claude. Account: Milobowler
fix() {
if [ $# -eq 1 ]; then
local last_cmd=$(fc -ln -1)
last_cmd=$(echo "$last_cmd" | sed 's/^[[:space:]]*//')
local new_cmd=$(echo "$last_cmd" | sed "s/^[^[:space:]]*/$1/")
# Add the corrected command to history
history -s "$new_cmd"
# Execute it
eval "$new_cmd"
else
echo "Usage: fix <correct-command>"
fi
}

# Windows Command Shortcuts
alias clip='wl-copy'
alias findstr='grep'
alias cls='clear'
alias del='rm'
alias ipconfig='ifconfig'
alias explorer='thunar'
alias hotspot='hotspot && clear'
alias buds='bluetoothctl connect A4:77:58:32:0C:74'
alias bose='bluetoothctl connect 78:2B:64:D1:7C:DD'
alias lock='hyprlock &'
alias nano='micro'
alias pwd='pwd | tee /dev/tty | wl-copy'
alias x='exit'
alias ls='eza --grid --color=always --icons=always --no-user'
alias lsl='eza --long --color=always --icons=always --no-user'
alias cat='bat --theme="Monokai Extended Origin" --paging=never'
alias bat='bat --theme="Monokai Extended Origin"'
alias hg="kitten hyperlinked-grep"
alias diff="kitten diff "
alias m="micro"
alias nv="nvim"
alias vi="nvim"
alias clipo="tee /dev/tty | wl-copy"

# Notify me on long commands
# created with Claude. Account: Milobowler
nt() {
	notify-send "Command completed" "Previous command finished"
}

# created with Claude. Account: Milobowler. Title: filtering directories and binary files from micro wildcard
microall() {
    local dir="${1:-.}"
    local files=()
    
    # Find all regular files (not directories) in the specified directory
    while IFS= read -r -d '' file; do
        # Check if file is text (using 'file' command)
        if file "$file" | grep -q "text"; then
            files+=("$file")
        fi
    done < <(find "$dir" -maxdepth 1 -type f -print0)
    
    # Open files in micro if any were found
    if [ ${#files[@]} -gt 0 ]; then
        micro "${files[@]}"
    else
        echo "No text files found in $dir"
    fi
}


export "MICRO_TRUECOLOR=1"

# --- Yazi Setup ---
export EDITOR="kitty nvim"

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && builtin cd -- "$cwd"
	rm -f -- "$tmp"
}

# --- Zoxide Setup ---
source ~/.zoxide-init.bash # run this command to create the file: "zoxide init bash > ~/.zoxide-init.bash"

# export NVM_DIR="$HOME/.nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

alias config='/usr/bin/git --git-dir=/home/shayan/.cfg/ --work-tree=/home/shayan'

# brew shellenv replacement. Run the following to get below: "/home/linuxbrew/.linuxbrew/bin/brew shellenv | clip"
export HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew";
export HOMEBREW_CELLAR="/home/linuxbrew/.linuxbrew/Cellar";
export HOMEBREW_REPOSITORY="/home/linuxbrew/.linuxbrew/Homebrew";
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin${PATH+:$PATH}";
[ -z "${MANPATH-}" ] || export MANPATH=":${MANPATH#:}";
export INFOPATH="/home/linuxbrew/.linuxbrew/share/info:${INFOPATH:-}";

function fuck () {
    TF_PYTHONIOENCODING=$PYTHONIOENCODING;
    export TF_SHELL=bash;
    export TF_ALIAS=fuck;
    export TF_SHELL_ALIASES=$(alias);
    export TF_HISTORY=$(fc -ln -10);
    export PYTHONIOENCODING=utf-8;
    TF_CMD=$(
        thefuck THEFUCK_ARGUMENT_PLACEHOLDER "$@"
    ) && eval "$TF_CMD";
    unset TF_HISTORY;
    export PYTHONIOENCODING=$TF_PYTHONIOENCODING;
    history -s $TF_CMD;
}

# See Dates in History
export HISTTIMEFORMAT='%F %T '
. "$HOME/.cargo/env"

#export GTK_THEME=Adwaita-dark

#use fzf for my ctrl + r
#  [ -f /usr/share/fzf/key-bindings.bash ] # && source /usr/share/fzf/key-bindings.bash
# source /usr/share/fzf/completion.bash
source ~/.fzf_static.bash
# Shellfirm
[[ -f ~/.bash-preexec.sh ]] && source ~/.bash-preexec.sh
[[ -f /home/shayan/Downloads/Git_Cloned/shellfirm/shell-plugins/shellfirm.plugin.sh ]] && source /home/shayan/Downloads/Git_Cloned/shellfirm/shell-plugins/shellfirm.plugin.sh

if [ "$TERM" = "linux" ]; then
  # TTY detected - use simplified config
  export STARSHIP_CONFIG=~/.config/starship-tty.toml
else
  # GUI Terminal - use default config
  export STARSHIP_CONFIG=~/.config/starship.toml
fi
eval "$(starship init bash)"
