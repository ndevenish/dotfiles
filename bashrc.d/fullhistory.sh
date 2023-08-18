#!/bin/bash

# Custom history file
export CUSTOM_HISTORY_FILE=$HOME/.fullhistory
gref() { grep "$@" ~/.fullhistory; }

if [[ -n ${ZSH_VERSION-} ]]; then
  # ZSH doesn't split command over multiple variables
  preexec_custom_history() {
    echo "$HOSTNAME:\"$PWD\" $$ $(date "+%Y-%m-%dT%H:%M:%S%z") $1" >> "$CUSTOM_HISTORY_FILE"
  }
else
  preexec_custom_history() {
    echo "$HOSTNAME:\"$PWD\" $$ $(date "+%Y-%m-%dT%H:%M:%S%z") $*" >> "$CUSTOM_HISTORY_FILE"
  }
fi
# Add it to the array of functions to be invoked each time.
preexec_functions+=(preexec_custom_history)

