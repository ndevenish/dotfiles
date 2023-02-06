#!/bin/bash
#
# Setup a predefined environment.
#
# Searches the current directory and all parents directories for a file
# matching a predefined name, and then sources it if found.
setup() {
    start_dir=$(pwd)
    dir=$(pwd)
    valid_names=(setup.sh dials)
    while true; do
        for name in "${valid_names[@]}"; do
            if [[ -f "$dir/$name" ]]; then
                break
            fi
        done
        if [[ -f "$dir/$name" ]]; then
            echo -e "Sourcing \033[1m$dir/$name\033[0m\n"
            cd "$dir" || return
            # shellcheck disable=SC1090
            source "$dir/$name"
            cd "$start_dir" || return
            break
        else
            next_dir=$(dirname "$dir")
            if [[ "$next_dir" == "$dir" ]]; then
                echo -e "\033[1;31mError: Could not find setup script (${valid_names[*]}) in parent tree\033[0m"
                break
            fi
            dir="$next_dir"
        fi
    done
}

