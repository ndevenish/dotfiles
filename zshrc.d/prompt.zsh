#!/bin/zsh

# Need prompt substitution for username and git
setopt PROMPT_SUBST

# Show dirty state in git branches
export GIT_PS1_SHOWDIRTYSTATE=1
export GIT_PS1_SHOWCOLORHINTS=1

########################################################################
# Hostname - only show if logged in remotely

if [[ -n "$SSH_CLIENT" ]]; then
    _hostname="%m "
fi

########################################################################
# Username - if we have an EXPECTED_USER, only show when matches

# Only show the user if it is different from "expected".
# The definition of expected is expected to be defined locally
if [[ -z "${EXPECTED_USER:-}" ]]; then
    # No expected user. Always show user.
    _user_host_name="%n@${_hostname% } "
else
    # Only show user if it is different from expected
    # shellcheck disable=SC2016
    _user_host_name='$([[ $USER == $EXPECTED_USER ]] && echo "'"$_hostname"'" || echo "%n@'"${_hostname% }"' ")'""
fi

########################################################################
# Git part of prompt

if [[ -n "$DOTFILES_REPO" ]]; then
    local original="$DOTFILES_REPO/common/git-prompt.sh"
    local rewritten="$DOTFILES_REPO/common/git-prompt.sh.rewrite"
    if [[ ! -f $rewritten ]]; then
    #  || "$(stat -c%Y $rewritten)" -lt "$(stat -c%Y $original)"
        cat "$original" | \
            sed -e 's/%F{red}/%F{160}/g' \
                -e 's/%F{green}/%F{64}/g' \
                -e 's/%F{blue}/%F{33}/g' > $rewritten
    fi
    # # Check the file timestamp and if it needs to be regenerated
    # (( $(stat -c%Y git-prompt.sh)
    source "$rewritten"
    _git='%B$(__git_ps1 "(%s) ")%b'
fi

########################################################################
########################################################################
# Form the actual prompt
########################################################################
########################################################################

_red_cwd="%B%F{red}%1~%f%b"
_red_prompt_for_failure="%(?.%#.%B%F{red}%#%f%b)"

PROMPT="$_user_host_name$_red_cwd $_git$_red_prompt_for_failure "
RPROMPT='%F{white}%B# %b$([[ -n $_last_time ]] && echo "($_last_time) ")%*%f'

# # Debugging spacing issues
# echo "PARTS"
# echo "_hostname:       _${_hostname}_"
# echo "_user_host_name: _${_user_host_name}_"
# echo "_git:            _${_git}_"
# echo "_red_cwd:        _${_red_cwd}_"
# echo "_red_prompt_for_failure: _${_red_prompt_for_failure}_"


