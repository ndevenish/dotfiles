
# CTRL-R - Paste the selected command from history into the command line
fzf-fullhistory-widget() {
    # If fzf was not available at configure time, check now
    if ! command -v fzf; then
        zle history-incremental-search-backward
        return
    fi
    local reverser=tac
    if ! command -v tac >/dev/null 2>&1; then
        reverser=(tail -r)
    fi
    zle -U "$($reverser ~/.fullhistory \
        | grep -av '^##EXIT##' \
        | fzf --with-nth 3.. -n 2.. --tiebreak=index --preview 'echo {} | cut -d" " -f 4-' --preview-window=up,3,wrap --bind change:top \
        | cut -d" " -f 4- \
        | sed $'s/[ \t]*$//')"
    # Needed if we don't use fzf fullscreen
    zle reset-prompt
}

if [[ "${HISTORY}" == fzf ]] || ! command -v atuin >/dev/null 2>&1; then
    zle     -N   fzf-fullhistory-widget
    bindkey '^R' fzf-fullhistory-widget
fi
