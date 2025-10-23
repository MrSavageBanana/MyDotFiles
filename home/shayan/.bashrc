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
export PATH=$PATH:$HOME/go/bin

eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

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

# created with Claude. Account: Milobowler
# Replace first N words of last command
# Usage: / <replacement words>
# Examples:
#   After "npm install lodash":
#   / yarn add        → runs: yarn add lodash
#   / pnpm            → runs: pnpm install lodash
#   /yarn add         → runs: yarn add lodash (no space needed)
/() {
if [ $# -ge 1 ]; then
local last_cmd=$(fc -ln -1)
last_cmd=$(echo "$last_cmd" | sed 's/^[[:space:]]*//')

# Split last command into array
local -a last_words=($last_cmd)

# Get number of replacement words provided
local replace_count=$#

# Build new command: replacement words + remaining words from old command
local new_cmd="$@"
for ((i=replace_count; i<${#last_words[@]}; i++)); do
new_cmd="$new_cmd ${last_words[$i]}"
done

eval "$new_cmd"
else
echo "Usage: / <replacement-words>"
fi
}

# Windows Command Shortcuts
alias clip='wl-copy'
alias findstr='grep'
alias cls='clear'
alias del='rm'
alias ipconfig='ifconfig'
alias explorer='nautilus'
alias buds='bluetoothctl connect A4:77:58:32:0C:74'
alias bose='bluetoothctl connect 78:2B:64:D1:7C:DD'
alias lock='hyprlock &'
alias nano='micro'
alias pwd='pwd | tee /dev/tty | wl-copy'

# Notify me on long commands
# created with Claude. Account: Milobowler
ntfy() {
    "$@"
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        notify-send "Command Completed ✓" "Command finished successfully: $*"
    else
        notify-send "Command Failed ✗" "Command failed with code $exit_code: $*"
    fi
    return $exit_code
}

# Notify when an already-running process completes (FOREGROUND version)
ntfy-pid() {
    local pid=$1
    if [ -z "$pid" ]; then
        echo "Error: No PID provided"
        return 1
    fi

    local process_name
    process_name=$(ps -p "$pid" -o comm= 2>/dev/null)
    if [ -z "$process_name" ]; then
        echo "Error: Process $pid not found"
        return 1
    fi

    # choose terminal emulator; if none found, print verbose error
    if command -v gnome-terminal &>/dev/null; then
        term_cmd="gnome-terminal -- bash -c"
    elif command -v xterm &>/dev/null; then
        term_cmd="xterm -e bash -c"
    else
        echo "Error: No supported terminal emulator found (gnome-terminal, xterm)"
        return 1
    fi

    local watcher_pid_file="/tmp/ntfy_watcher_$pid"

    # Launch a new terminal that watches the PID (keeps messages inside that window)
    $term_cmd "
        echo \$$ > '$watcher_pid_file'
        echo 'Watching PID $pid ($process_name)...'
        echo 'This window will close when the process completes.'
        echo ''
        while kill -0 $pid 2>/dev/null; do sleep 1; done
        # small delay to let process fully exit
        sleep 0.5
        # notify user (no exit-code introspection here)
        notify-send 'Process Completed' '$process_name (PID: $pid) finished'
        rm -f '$watcher_pid_file'
        echo ''
        echo 'Process completed. Press Enter to close...'
        read
    " &

    return 0
}

# Easy notification - resume in foreground; minimal output
notif() {
    # get most recent stopped job line
    local stopped_line
    stopped_line=$(jobs -l | awk '/Stopped/ {line=$0} END{print line}')

    if [ -z "$stopped_line" ]; then
        echo "Error: No stopped job found"
        return 1
    fi

    local pid cmd watcher_pid_file existing_count
    pid=$(printf '%s' "$stopped_line" | awk '{print $2}')
    cmd=$(printf '%s' "$stopped_line" | awk '{for(i=4;i<=NF;i++) printf "%s ", $i; print ""}' | sed 's/[[:space:]]*$//')

    watcher_pid_file="/tmp/ntfy_watcher_$pid"

    # count existing watchers
    set -- /tmp/ntfy_watcher_*
    if [ -e "$1" ]; then
        existing_count=$#
    else
        existing_count=0
    fi

    # set up background watcher only if we have a valid PID
    (
        echo $$ > "$watcher_pid_file"

        # Wait until the process is gone
        while kill -0 "$pid" 2>/dev/null; do
            sleep 1
        done
        sleep 0.2

        # Detect if process exited normally
        # If process is gone because of Ctrl+C or kill, its exit status >128 (signal)
        local exit_code
        exit_code=$(ps -o stat= -p "$pid" 2>/dev/null | grep -q 'Z' && echo 0 || echo $?)
        # Skip notification if process was interrupted (nonzero exit code)
        if ! ps -p "$pid" &>/dev/null; then
            # double-check it's really gone, then skip notifying if user interrupted it
            # Only notify if the process completed naturally (SIG0 -> gone cleanly)
            if [ "$exit_code" -eq 0 ]; then
                notify-send "Command Completed" "Command finished: $cmd"
            fi
        fi

        rm -f "$watcher_pid_file"
    ) & disown   # disown to stop "[N]+ Done" messages

    # Minimal success message
    if [ "$existing_count" -ge 1 ]; then
        echo "You'll be notified when this command is complete. PID: $pid"
    else
        echo "You'll be notified when this command is complete"
    fi

    # resume job in foreground
    fg
}

# Cancel all active notification watchers and optionally resume any stopped job
notif-cancel() {
    # make globbing safe
    shopt -s nullglob
    local files=(/tmp/ntfy_watcher_*)
    if [ ${#files[@]} -eq 0 ]; then
        shopt -u nullglob
        echo "No active notification watchers found"
        return 0
    fi

    local watcher_pid watched_pid count=0
    for watcher_file in "${files[@]}"; do
        if [ -f "$watcher_file" ]; then
            watcher_pid=$(cat "$watcher_file" 2>/dev/null || true)
            watched_pid=$(echo "$watcher_file" | grep -oP '\d+$')
            if [ -n "$watcher_pid" ] && kill -0 "$watcher_pid" 2>/dev/null; then
                kill "$watcher_pid" 2>/dev/null || true
            fi
            rm -f "$watcher_file"
            count=$((count+1))
        fi
    done
    shopt -u nullglob

    # minimal cancel message
    if [ $count -gt 0 ]; then
        echo "You'll no longer be notified when this command is complete"
    else
        echo "No active notification watchers found"
    fi

    # if there's a stopped job, resume it silently (fg will take over the terminal)
    local stopped_line
    stopped_line=$(jobs -l | awk '/Stopped/ {line=$0} END{print line}')
    if [ -n "$stopped_line" ]; then
        fg
    fi
}

# Cancel a specific notification watcher (by watched PID)
notif-cancel-pid() {
    local pid=$1
    if [ -z "$pid" ]; then
        echo "Error: No PID provided"
        return 1
    fi

    local watcher_file="/tmp/ntfy_watcher_$pid"
    if [ ! -f "$watcher_file" ]; then
        echo "Error: No notification watcher found for PID $pid"
        return 1
    fi

    local watcher_pid
    watcher_pid=$(cat "$watcher_file" 2>/dev/null || true)
    if [ -n "$watcher_pid" ] && kill -0 "$watcher_pid" 2>/dev/null; then
        kill "$watcher_pid" 2>/dev/null || true
    fi
    rm -f "$watcher_file"

    echo "You'll no longer be notified when this command is complete"

    # resume stopped job if that PID corresponds to a stopped job
    local job_info
    job_info=$(jobs -l | grep "Stopped" | grep -F "$pid")
    if [ -n "$job_info" ]; then
        fg
    fi
}

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="/usr/bin:$PATH"
export PATH=$PATH:$HOME/go/bin
