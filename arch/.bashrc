#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
alias ll='ls -lAh --color=auto --group-directories-first'
PS1='[\u@\h \W]\$ '

export PATH="$PATH:$HOME/go/bin"
export TERM=xterm-256color