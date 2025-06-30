#!/bin/bash

# Custom history file
export CUSTOM_HISTORY_FILE=$HOME/.fullhistory
gref() { grep "$@" ~/.fullhistory; }

if [[ -n ${ZSH_VERSION-} ]]; then
  # ZSH doesn't split command over multiple variables
  preexec_custom_history() {
    _timer_hist_run="$SECONDS"
    echo "$HOSTNAME:\"$PWD\" $$ $(date "+%Y-%m-%dT%H:%M:%S%z") $1" >> "$CUSTOM_HISTORY_FILE"
  }
else
  preexec_custom_history() {
    _timer_hist_run="$SECONDS"
    echo "$HOSTNAME:\"$PWD\" $$ $(date "+%Y-%m-%dT%H:%M:%S%z") $*" >> "$CUSTOM_HISTORY_FILE"
  }
fi

# Write the results of the last run to the logfile
precmd_custom_history() {
    local -i _exit=$?
    local -i _last_runtime=""
    if (( ${+_timer_hist_run} )); then
        _last_runtime=$(($SECONDS-$_timer_hist_run))
        unset _timer_hist_run
    fi
    echo "##EXIT## $HOSTNAME pid=$$ \$?=$_exit t=$_last_runtime" >> "$CUSTOM_HISTORY_FILE"
}
# Add it to the array of functions to be invoked each time.
preexec_functions+=(preexec_custom_history)
precmd_functions+=(precmd_custom_history)