#!/bin/bash

# Check if we are sourced
(return 0 2>/dev/null) && sourced=true || sourced=false
if [[ $sourced == true ]]; then
    echo "Error: Installation script must be explicitly run, not sourced"
    return 1
fi

set -eu
# Explicitly handling hidden files here
shopt -s dotglob

# Make sure we weren't asked for usage
if [[ "${1:-}" == -h || "${1:-}" == "--help" ]]; then
    echo "Usage: ./install.sh [-h|--help]"
    exit 0
fi

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

# Cross-platform functions - commands to elide platform differences
if [[ "$OSTYPE" == "darwin"* ]]; then
    if command -v "python3" 1>/dev/null 2>&1; then
        python=python3
    elif command -v "python" 1>/dev/null 2>&1; then
        python=python
    else
        echo "${R}Error: Cannot find python - required on OSX for abspath${NC}"
        exit 1
    fi
    function readlink_resolve() {
        python -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$@"
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

########################################################################
# Make softlinks in $HOME to everything in homedir/*

echo -e "${BD}Installing/Updating existing .dotfiles links$NC\n"

echo "Softlinks to homedir:"
for item in "${DIR}"/homedir/*; do
    # If the target does not exist, link it
    link="$HOME/$(basename "$item")"
    printf "    ~%-20s    " "${link#"$HOME"}"
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
    elif [[ -d "$link" ]]; then
        echo "${R}Error: Target directory exists. Remove or merge manually.$NC"
        FAIL=$((FAIL + 1))
    else
        echo "${R}Unknown error: Cannot handle $link$NC"
        FAIL=$((FAIL + 1))
    fi
done

########################################################################
# Make a .gitconfig-local for the main gitconfig to point to

if [[ ! -f ~/.gitconfig-local ]]; then
    echo -e "\nCreating $B.gitconfig-local$NC"
    touch ~/.gitconfig-local
    echo "[init]
    templateDir = $HOME/.git-template
    " > ~/.gitconfig-local
    echo "    done."
else
    echo -e "\n$B.gitconfig-local$NC already exists, not recreating"
fi

########################################################################
# Updating shell init scripts to point to common utilities

insert_or_replace_integration_in_file() {
    # Usage: insert_or_replace_integration_in_file [-q] <filename> "<multi_line_text_to_replace>"
    #
    # The multi-line text should have a stable start and end line to delineate.
    # Args:
    #   -q  Do quietly - update without asking
    _quiet=""
    if [[ "$1" == "-q" ]]; then
        _quiet=true
        shift
    fi
    # Asks user to confirm if it's an update instead of a replacement
    file_to_inject="$1"
    lines_to_inject="$2"
    start_line="$(echo "$lines_to_inject" | head -n 1)"
    end_line="$(echo "$lines_to_inject" | tail -n 1)"

    if ! grep -sq "$start_line" "$file_to_inject"; then
        echo "    No existing integration, writing to $B~${file_to_inject#"$HOME"}$NC"
        # Easy case - there is no line in the file yet
        echo "$lines_to_inject" >> "$file_to_inject"
        echo "    Injected!"
    else
        echo "    Found existing integration in $B~${file_to_inject#"$HOME"}$NC"
        _working_file=$(mktemp)
        # We already have the lines in the file, and might be trying to update
        sed -n '/'"$start_line"'/q;p' "$file_to_inject" > "$_working_file"
        echo "$lines_to_inject" >> "$_working_file"
        sed '1,/^'"$end_line"'/d' "$file_to_inject" >> "$_working_file"

        if ! cmp -s "$file_to_inject" "$_working_file"; then
            echo "    There are changes to update:$W"
            diff -u "$file_to_inject" "$_working_file" \
            | tail -n +4 \
            | sed -E \
                -e 's/^(-.*)$/'"$R"'\1'"$W"'/' \
                -e 's/^(\+.*)$/'"$G"'\1'"$W"'/' \
                -e 's/^/        /' || true
            _basename="$(basename "$file_to_inject")"
            backup="$HOME/${_basename}.bak"
            echo
            read -p "$NC${BD}OK to proceed? [yN] $NC" -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo "$NC   Copying existing file to $B$backup$NC"
                (
                    cp "$file_to_inject" "$backup"
                    mv "$_working_file" "$file_to_inject"
                )
                echo "$NC$G   Successfully updated $BD$file_to_inject$NC"
            else
                echo "User declined to change. Skipping update."
            fi
        else
            echo "    This file is up-to-date!"
        fi
    fi
}

if [[ "$SHELL" == */bash ]]; then
    echo -e "\nThis users default shell is set to ${BD}bash$NC"

    # All target files to consider for initialization
    _all_inits=(~/.bash_profile ~/.bashrc_local ~/.bashrc ~/.profile)

    # shellcheck disable=SC2016
    init_block='# >>> .dotfiles integration >>>
# !! Contents within this block are managed by .dotfiles installer !!
for file in $(find "'"$DIR"'/bashrc.d" -name "*.sh" -o -name "*.bash" | sort -V); do
    source "$file"
done
export PATH=$PATH:'"$DIR"'/bin
# <<< .dotfiles integration <<<'

    start_line="$(echo "$init_block" | head -n 1)"
    # Try and find an existing file with this integration block
    # (grep will exit with error even if it found some results)
    _init_file="$(grep -slm1 "$start_line" "${_all_inits[@]}" 2>/dev/null)" || true
    if [[ -z "$_init_file" ]]; then
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
    fi
    if [[ -n "$_init_file" ]]; then
        insert_or_replace_integration_in_file "$_init_file" "$init_block"
    fi
elif [[ "$SHELL" == */zsh ]]; then
    echo -e "\nThis users default shell is set to ${BD}zsh$NC"

    # The Zsh init block
    # We want:
    #   - ZSH_CUSTOM for Oh-my-zsh custom plugins, managed by dotfiles
    #   - Custom zsh init scripts for things outside OMZ or unintegrated

    # shellcheck disable=SC2016
    init_block='# >>> .dotfiles integration >>>
# !! Contents within this block are managed by .dotfiles installer !!
DOTFILES_REPO="'"$DIR"'"
ZSH_CUSTOM='"$DIR"'/zsh_custom
for file in $(find "'"$DIR"'/zshrc.d" -name "*.zsh" | sort -V); do
    source "$file"
done
export PATH=$PATH:'"$DIR"'/bin
# <<< .dotfiles integration <<<'

    insert_or_replace_integration_in_file "$HOME/.zshrc" "$init_block"
fi
