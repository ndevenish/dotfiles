#!/bin/bash

set -eu
# Explicitly handling hidden files here
shopt -s dotglob

########################################################################
# Get the location of this script
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
    DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$(cd -P "$(dirname "$SOURCE")" >/dev/null 2>&1 && pwd)"
########################################################################

if [[ "$OSTYPE" == "darwin"* ]]; then
    #alias readlink="readlink"
    if command -v "python3" 1>/dev/null 2>&1; then
        python=python3
    elif command -v "python" 1>/dev/null 2>&1; then
        python=python
    else
        echo "${R}Error: Cannot find python - required on OSX for abspath${NC}"
        exit 1
    fi
    function readlink_resolve() {
        readlink "$@"
    }
    function abspath() {
        "$python" -c "import os, sys; print(os.path.abspath(sys.argv[1]))" "$@"
    }
else
    function readlink_resolve() {
        readlink -f "$@"
    }
    function abspath() {
        readlink -f "$@"
    }
fi

BD="$(printf "\033[1m")"
R="$(printf "\033[31m")"
G="$(printf "\033[32m")"
# Y="$(printf "\033[33m")"
B="$(printf "\033[34m")"
# M="$(printf "\033[35m")"
# C="$(printf "\033[36m")"
W="$(printf "\033[37m")"
# UL="$(printf "\033[4m")"
NC="$(printf "\033[0m")"

# Keep track of if something failed
FAIL=""

echo -e "${BD}Installing/Updating existing .dotfiles links$NC\n"

echo "Softlinks to homedir:"
for item in "${DIR}"/homedir/*; do
    # If the target does not exist, link it
    link="$HOME/$(basename "$item")"
    printf "    ~%-20s    " "${link#$HOME}"
    if [[ ! -e "$link" && ! -d "$link" ]]; then
        ln -s "$item" "$link"
        echo "${G}New Link$NC"
    elif [[ -L "$link" ]]; then
        # Already a symbolic link - check it points to this
        _exist_link="$(readlink_resolve "$link")"
        if [[ "$(abspath "$_exist_link")" == "$item" ]]; then
            echo "${G}Existing Link$NC"
        else
            echo "${R}Link points to different file - $_exist_link$NC"
            FAIL=$((FAIL + 1))
        fi
    elif [[ -f "$link" ]]; then
        # Check if this file is the same as the target - if it is, then relink
        if cmp -s "$link" "$item"; then
            rm "$link"
            ln -s "$item" "$link"
            echo "$BD${G}Relinked existing (identical) file$NC"
        else
            echo "${R}File exists and does not match - cannot relink${NC}"
            FAIL=$((FAIL + 1))
        fi
    else
        echo "${R}Unknown error: Cannot handle $link$NC"
        FAIL=$((FAIL + 1))
    fi
done

echo -e "\nInjecting/Updating bash startup script"

# All target files to consider for initialization
_all_inits=(~/.bash_profile ~/.bashrc_local ~/.profile ~/.bashrc)

# shellcheck disable=SC2016
init_block='# >>> .dotfiles integration >>>
# !! Contents within this block are managed by .dotfiles installer !!
for file in $(find "'"$DIR"'/bashrc.d" -name "*.sh" | sort -V); do
  source "$file"
done
export PATH=$PATH:'"$DIR"'/bin
# <<< .dotfiles integration <<<'


# Try and find an existing file with this itegration block
# (grep will exit with error even if it found some results)
_init_file="$(grep -slm1 "# >>> .dotfiles integration >>>" "${_all_inits[@]}" 2>/dev/null)" || true
if [[ -z "$_init_file" ]]; then
    echo "    No existing integration"
    # Find the first init file in our list that exists
    for _init_file in "${_all_inits[@]}"; do
        if [[ -f "$_init_file" ]]; then
            break
        fi
    done
    # Fail if we found nothing
    if [[ -z "$_init_file" ]]; then
        echo "${R}Error: Could not find an init file to use from:"
        echo "${_all_inits[@]}"
        echo "$NC"
    fi
    echo "    Found $B~${_init_file#$HOME}$NC for injection"
    echo "$init_block" >> "$_init_file"
    echo "    Injected!"

else
    echo "    Found existing integration in $B~${_init_file#$HOME}$NC"
    _working_file=$(mktemp)
    sed -n '/# >>> .dotfiles integration >>>/q;p' "$_init_file" > "$_working_file"
    echo "$init_block" >> "$_working_file"
    sed '1,/^# <<< .dotfiles integration <<</d' "$_init_file" >> "$_working_file"

    if ! cmp -s "$_init_file" "$_working_file"; then
        echo "   There are changes to update:$W"
        diff "$_init_file" "$_working_file" \
        | sed -E \
            -e 's/^(<.*)$/'"$R"'\1'"$W"'/' \
            -e 's/^(>.*)$/'"$G"'\1'"$W"'/' \
            -e 's/^/        /' || true
        _basename="$(basename "$_init_file")"
        backup="$HOME/.backup_${_basename#.}"
        echo
        read -p "$NC${BD}OK to proceed? [yN] $NC" -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$NC   Copying existing file to $B$backup$NC"
            ( set -x
                cp "$_init_file" "$backup"
                mv "$_working_file" "$_init_file"
            )
        else
            echo "User declined to change. Skipping update."
        fi
    else
        echo "    This file is up-to-date!"
    fi
fi
