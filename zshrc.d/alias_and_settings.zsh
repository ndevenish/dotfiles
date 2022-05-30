
bindkey -e

setopt autocd notify
setopt EXTENDED_HISTORY

setopt noautomenu
setopt nomenucomplete

# This is annoying for things like conda
setopt noautoremoveslash

# BSD-style, safe to always set
export CLICOLOR=1
# Detect GNU vs BSD ls to turn on colours
if ls --color=auto >/dev/null 2>&1; then
    alias ls='ls --color=auto'
    alias ll='ls --color=auto -lh'
    alias lt='ls --color=auto -lrth'
else
    alias ll='ls -lh'
    alias lt='ls -lrth'
fi
