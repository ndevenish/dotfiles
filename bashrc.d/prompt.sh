#!/bin/bash

# Add a magic "red for failure" prompt state
# This is escaped because at some point it gets unescaped in this sed

# _red_dollar='\\[$([ $? -eq 0 ] || printf "\\e[1;31m")\\]\$\\[\\e[0m\\]'
# export PS1="$(printf "%s" "$PS1" | sed 's/\\\$/'"$_red_dollar"'/')"
# unset _red_dollar