# If we don't have fzf available, don't configure
if ! command -v fzf >/dev/null 2>&1; then
    return
fi

# CTRL-R - Paste the selected command from history into the command line
fzf-fullhistory-widget() {
    local reverser=tac
    if ! command -v tac >/dev/null 2>&1; then
        reverser='tail -r'
    fi
    zle -U "$($reverser ~/.fullhistory \
        | fzf --with-nth 3.. -n 2.. --tiebreak=index --preview 'echo {} | cut -d" " -f 4-' --preview-window=up,3,wrap --bind change:top \
        | cut -d" " -f 4- \
        | sed $'s/[ \t]*$//')"
    # Needed if we don't use fzf fullscreen
    zle reset-prompt
}
zle     -N   fzf-fullhistory-widget
bindkey '^R' fzf-fullhistory-widget
