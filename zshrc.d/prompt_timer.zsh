# Adds timing information to each command. If longer than 20s, the
# variable $_last_time will be set to a humanish string (3h45m)
#
# This can be used in e.g. RPROMPT with:
#
#    $([[ -n $_last_time ]] && echo $_last_time)

pre_timer() {
    _timer="$SECONDS"
}
post_timer() {
    _last_time=""
    if (( ${+_timer} )); then
        per_exec=$(($SECONDS-$_timer))
        # Don't show anything if less than 20 seconds has elapsed
        if [[ $per_exec -lt 10 ]]; then
            return
        fi
        if [[ $per_exec -lt 60 ]]; then
            _last_time="${per_exec}s"
        else
            _exec_min="$(($per_exec / 60))"
            _exec_sec="$(($per_exec % 60))"
            if [[ $_exec_min -lt 60 ]]; then
                _last_time="${_exec_min}m${_exec_sec}s"
            else
                _exec_h="$(($_exec_min / 60))"
                _exec_min="$(($_exec_min % 60))"
                _exec_sec="$(($per_exec % 60))"
                _last_time="${_exec_h}h${_exec_min}m"
            fi
        fi
        unset _timer
    fi
}
preexec_functions+=(pre_timer)
precmd_functions+=(post_timer)

