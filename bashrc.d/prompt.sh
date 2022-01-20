#!/bin/bash

# Add a magic "red for failure" prompt state if not there already
if [[ ! "$PS1" =~ 1\;31m\"\)\\]\\\$ ]]; then
    # This is escaped because at some point it gets unescaped in this sed
    # shellcheck disable=SC2016
    _red_dollar='\\[$([ $? -eq 0 ] || printf "\\e[1;31m")\\]\$\\[\\e[0m\\]'
    PS1="$(printf "%s" "$PS1" | sed 's/\\\$/'"$_red_dollar"'/')"
    export PS1
    unset _red_dollar
fi