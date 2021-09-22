#!/usr/bin/env bash

if ! command -v fzf >/dev/null 2>&1; then
    return
fi

# Detect line editing available, and only use bind if it can work
if [[ "$(set -o | grep 'emacs\|\bvi\b' | cut -f2 | tr '\n' ':')" != 'off:off:' ]]; then
    bind '"\C-r": "\C-x1\e^\er"'
    bind -x '"\C-x1": __fzf_history';
fi


__fzf_history ()
{
    local reverser=tac
    if ! command -v tac >/dev/null 2>&1; then
        reverser='tail -r'
    fi
    __ehc "$($reverser ~/.fullhistory \
        | fzf --with-nth 3.. -n 2.. --tiebreak=index --preview 'echo {} | cut -d" " -f 4-' --preview-window=up,3,wrap --bind change:top \
        | cut -d" " -f 4- \
        | sed $'s/[ \t]*$//')"
}

__ehc()
{
if
        [[ -n $1 ]]
then
        bind '"\er": redraw-current-line'
        bind '"\e^": magic-space'
        READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${1}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
        READLINE_POINT=$(( READLINE_POINT + ${#1} ))
else
        bind '"\er":'
        bind '"\e^":'
fi
}

