#!/usr/bin/env bash

if ! command -v fzf >/dev/null 2>&1; then
    return
fi

bind '"\C-r": "\C-x1\e^\er"'
bind -x '"\C-x1": __fzf_history';

__fzf_history ()
{
    __ehc "$(tail -r ~/.fullhistory \
        | fzf --with-nth 3.. -n 2.. --tiebreak=index --preview 'echo {} | cut -d" " -f 4-' --preview-window=up,3,wrap --bind change:top \
        | cut -d" " -f 4- \
        | sed 's/[ \t]*$//')"
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

