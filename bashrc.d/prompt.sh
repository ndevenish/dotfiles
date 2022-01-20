#!/bin/bash


export GIT_PS1_SHOWDIRTYSTATE="${GIT_PS1_SHOWDIRTYSTATE:-1}"

# Insert git_prompt if not present
if  [[ ! "$PS1" =~ __git_ps1 ]]; then
    if [[ -z "$(type -t __git_ps1)" ]]; then
        # shellcheck disable=SC1090
        source ~/.git-prompt.sh
    fi
    PS1="$(printf "%s" "$PS1" | sed 's|\\\$|\\[\\e[1;34m\\]\$\(__git_ps1)\\[\\e[0m\\]\\\$|')"
    export PS1
fi

# Add a magic "red for failure" prompt state if not there already
if [[ ! "$PS1" =~ 1\;31m\"\)\\]\\\$ ]]; then
    # This is escaped because at some point it gets unescaped in this sed
    # shellcheck disable=SC2016
    _red_dollar='\\[$([ $? -eq 0 ] || printf "\\e[1;31m")\\]\$\\[\\e[0m\\]'
    PS1="$(printf "%s" "$PS1" | sed 's/\\\$/'"$_red_dollar"'/')"
    export PS1
    unset _red_dollar
fi
