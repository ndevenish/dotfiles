#!/bin/bash

# Custom history file
export CUSTOM_HISTORY_FILE=$HOME/.fullhistory
gref() { grep "$@" ~/.fullhistory; }
preexec_custom_history() {
  echo "$HOSTNAME $$ $(date "+%Y-%m-%dT%H:%M:%S%z") $*" >> "$CUSTOM_HISTORY_FILE"
}
# Add it to the array of functions to be invoked each time.
preexec_functions+=(preexec_custom_history)

