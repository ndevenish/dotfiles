#!/bin/bash

# Check if we are sourced
(return 0 2>/dev/null) && sourced=true || sourced=false
if [[ $sourced == true ]]; then
    echo "Error: Installation script must be explicitly run, not sourced"
    return 1
fi

set -euo pipefail
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
        "$python" -c "import os, sys; print(os.path.realpath(sys.argv[1]))" "$@"
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
Y="$(printf "\033[33m")"
B="$(printf "\033[34m")"
GREY="$(printf "\033[37m")"
# M="$(printf "\033[35m")"
# C="$(printf "\033[36m")"
W="$(printf "\033[37m")"
# UL="$(printf "\033[4m")"
NC="$(printf "\033[0m")"

# Keep track of if something failed
FAIL=""

savex() {
    echo $- | grep -q x && SETX=-x || SETX=+x
}
loadx() {
    set "$SETX"
}

# Run a command and suppress output unless it errors
silently() {
    # Work out if -x is on and turn off if it is
    savex
    set +x
    if ! output="$("$@" 2>&1)"; then
        printf "${BD}${R}Error running${NC} %s${R}${BD}:\n${R}${output}${NC}\n" "$*"
        return 1
    fi
    loadx
}

########################################################################
# Validate that if we're a git repository, we checked out recursively

if [[ -e "$DIR/.git" ]]; then
    git_dir="$DIR/.git"
    if [[ -f "$DIR/.git" ]]; then
        # A worktree?
        git_dir="$(cut <.git -d' ' -f 2-)"
        if [[ ! -d "$git_dir" ]]; then
            echo "${Y}Warning: .git exists but cannot find root. No submodule checks."
        fi
    fi
    # Now we have the proper git dir location, check if our submodules are initialised
    if ! grep -q '\[submodule "' "$git_dir/config"; then
        echo "Repository not cloned recursively, updating...."
        git -C "$DIR" submodule init
        git -C "$DIR" submodule update
        echo
    fi
fi

########################################################################
# Make softlinks in $HOME to everything in homedir/*

echo -e "${BD}Installing/Updating existing .dotfiles links$NC\n"

function link_dir_contents() {
    local source="$1"
    local dest="$2"
    local indent="${3:-}"

    for item in "${source}"/*; do
        # Handle in-band signalling that isn't copied
        if [[ "$(basename "$item")" == ".external-folder" ]]; then
            continue
        fi

        # If the target does not exist, we need to construct
        target="${dest}/$(basename "$item")"
        printf "    %-24s " "$indent~${target#"$HOME"}"
        # If the source is an "external" folder and not present, create it
        if [[ ! -e "$target" && -f "$item/.external-folder" ]]; then
            mkdir -p "$target"
        fi

        if [[ ! -e "$target" ]]; then
            # If it doesn't exist, yet, then we just want a softlink
            ln -s "$item" "$target"
            echo "${indent}${G}New Link$NC"
        elif [[ -L "$target" ]]; then
            # Already a symbolic link - check it points to this
            _exist_link="$(readlink_resolve "$target")"
            if [[ "$(abspath "$_exist_link")" == "$item" ]]; then
                echo "${G}Existing Link$NC"
            else
                echo "${R}Link points to different file - $_exist_link$NC"
                FAIL=$((FAIL + 1))
            fi
        elif [[ -f "$target" ]]; then
            # Check if this file is the same as the source - if it is, then relink
            if cmp -s "$target" "$item"; then
                rm "$target"
                ln -s "$item" "$target"
                echo "$BD${G}Relinked existing (identical) file$NC"
            else
                echo "${R}File exists and does not match - cannot relink${NC}"
                FAIL=$((FAIL + 1))
            fi
        elif [[ -d "$target" && ! -d "$item" ]]; then
            echo "${R}Error: Target is a directory, expected a file. Remove or merge manually.$NC"
            FAIL=$((FAIL + 1))
        elif [[ -d "$target" && -f "$item/.external-folder" ]]; then
            # We want to recursively sublink in this folder
            echo "${G}External, recursing$NC"
            link_dir_contents "$item" "$target" "$indent    "
        elif [[ -d "$target" ]]; then
            echo "${R}Error: Target directory exists. Remove or merge manually.$NC"
            FAIL=$((FAIL + 1))
        else
            echo "${R}Unknown error: Cannot handle $target$NC"
            FAIL=$((FAIL + 1))
        fi
    done
}
echo "Softlinks to homedir:"

link_dir_contents "${DIR}"/homedir "$HOME"

########################################################################
# Make a .gitconfig-local for the main gitconfig to point to

if [[ ! -f ~/.gitconfig-local ]]; then
    echo -e "\nCreating $B.gitconfig-local$NC"
    touch ~/.gitconfig-local
    echo "[init]
    templateDir = $HOME/.git-template
    " >~/.gitconfig-local
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
        echo "$lines_to_inject" >>"$file_to_inject"
        echo "    Injected!"
    else
        echo "    Found existing integration in $B~${file_to_inject#"$HOME"}$NC"
        _working_file=$(mktemp)
        # We already have the lines in the file, and might be trying to update
        sed -n '/'"$start_line"'/q;p' "$file_to_inject" >"$_working_file"
        echo "$lines_to_inject" >>"$_working_file"
        sed '1,/^'"$end_line"'/d' "$file_to_inject" >>"$_working_file"

        if ! cmp -s "$file_to_inject" "$_working_file"; then
            echo "    There are changes to update:$W"
            diff -u "$file_to_inject" "$_working_file" |
                tail -n +4 |
                sed -E \
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
for file in $(find "'"$DIR"'/zshrc.d" -name "*.zsh" -o -name "*.sh" | sort -V); do
    source "$file"
done
export PATH=$PATH:'"$DIR"'/bin
# <<< .dotfiles integration <<<'

    insert_or_replace_integration_in_file "$HOME/.zshrc" "$init_block"
fi

########################################################################
# Tooling installs

# Work out how to download files
if command -v curl 1>/dev/null 2>&1; then
    download() {
        curl -fsSL "${1:?}"
    }
elif command -v wget 1>/dev/null 2>&1; then
    download() {
        wget -O - "${1:?}" 2>/dev/null
    }
fi

# Usage: get_github_release org/repo
get_github_release() {
    download "https://api.github.com/repos/$1/releases/latest" |
        grep tag_name |
        grep -Eo ': "([^"]+)"' |
        sed -e 's/"//g' -e 's/://g' -e 's/ //g'
}

# Computing artifact location
case "$(uname)" in
Linux)
    PLATFORM="linux"
    PLATFORM_FZF="linux"
    PLATFORM_RG="unknown-linux-gnu"
    PLATFORM_BAT="unknown-linux-gnu"
    PLATFORM_DIFFT="unknown-linux-musl"
    ;;
Darwin)
    PLATFORM="osx"
    PLATFORM_FZF="darwin"
    PLATFORM_RG="apple-darwin"
    PLATFORM_BAT="apple-darwin"
    PLATFORM_DIFFT="apple-darwin"
    ;;
*NT*)
    PLATFORM="win"
    PLATFORM_FZF="windows"
    PLATFORM_RG="pc-windows"
    PLATFORM_BAT="pc-windows-msvc"
    PLATFORM_DIFFT="pc-windows-msvc"
    ;;
esac

ARCH="$(uname -m)"
ARCH_FZF="$ARCH"
ARCH_RG="$ARCH"
ARCH_BAT="$ARCH"
case "$ARCH" in
aarch64)
    ARCH_FZF="arm64"
    ;;
ppc64le) ;;
arm64)
    ARCH_RG=aarch64
    ARCH_BAT=aarch64
    ;;
amd64)
    ARCH_RG=x86_64
    ARCH_BAT=x86_64
    ARCH="x86_64"
    ;;
x86_64 | i686)
    ARCH_FZF="amd64"
    ;;
*) ;;
esac

case "$PLATFORM-$ARCH" in
linux-aarch64 | linux-ppc64le | linux-x86_64 | osx-arm64 | osx-x86_64 | win-x86_64) ;; # pass
*)
    echo "Failed to detect your OS; $PLATFORM-$ARCH not recognised." >&2
    exit 1
    ;;
esac

echo
echo "${BD}Tooling fetch/update$NC"
echo

should_download_tool() {
    _name="$1"
    # If we have this somewhere that isn't ~/.local/bin, or if the
    # path in ~/.local/bin is a symlink, skip
    if _output="$(command -v $_name)" && [[ "$_output" != "$HOME/.local/bin/$_name" ]]; then
        printf "    %-14s" "$_name"
        echo "${GREY}SKIP (exists outside ~/.local/bin))${NC}"
        return 1
    elif [[ -L "~/.local/bin/$_name" ]]; then
        printf "    %-14s" "$_name"
        echo "${GREY}SKIP (~/.local/bin is symlink)${NC}"
        return 1
    fi
    return 0
}

printf "    %-14s" micromamba

if should_download_tool micromamba; then
    if ! _output=$(PREFIX_LOCATION=${MAMBA_ROOT_PREFIX:-"${HOME}/.cache/micromamba"} silently bash "$DIR/tools/install_micromamba.sh" </dev/null 2>&1); then
        echo "$BD${R}FAIL$NC"
        echo "$R$_output$NC"
    else
        echo "$BD${G}$(~/.local/bin/micromamba --version)$NC"
    fi
else
    echo "${GREY}SKIP (have mamba)${NC}"
fi

printf "    %-14s" uv
if ! _output=$(silently bash "$DIR/tools/install_uv.sh" </dev/null 2>&1); then
    echo "$BD${R}FAIL$NC"
    echo "$R$_output$NC"
else
    echo "$BD${G}$(~/.local/bin/uv --version | cut -d' ' -f 2)$NC"
fi

try_download_tool() {
    _name=$1
    _url=$2
    printf "    %-14s" "$_name"
    _tmp=$(mktemp -d)
    if ! _output="$(download "$_url" | tar -xzf - -C "$_tmp")"; then
        echo "$BD${R}FAIL$NC"
        echo "${R}Failed to download $_url$NC"
        echo "$R$_output$NC"
        return
    fi
    # Find the executable
    mkdir -p ~/.local/bin
    find "$_tmp" -name "$_name" | xargs -I% mv % ~/.local/bin

    if find "$_tmp" -name "*.1" >/dev/null 2>&1; then
        mkdir -p ~/.local/share/man/man1
        find "$_tmp" -name "*.1" | xargs -I% mv % ~/.local/share/man/man1
    fi
    echo "$BD${G}$(~/.local/bin/$_name --version | head -n 1)${NC}"
    rm -rf "$_tmp"
}

if should_download_tool fzf; then
    _fzf_version="$(get_github_release junegunn/fzf)"
    try_download_tool fzf "https://github.com/junegunn/fzf/releases/download/$_fzf_version/fzf-${_fzf_version#v*}-${PLATFORM_FZF}_${ARCH_FZF}.tar.gz"
fi

if should_download_tool bat; then
    _bat_version="$(get_github_release sharkdp/bat)"
    try_download_tool bat "https://github.com/sharkdp/bat/releases/download/$_bat_version/bat-${_bat_version}-${ARCH_BAT}-${PLATFORM_BAT}.tar.gz"
fi

if should_download_tool rg; then
    _rg_version="$(get_github_release BurntSushi/ripgrep)"
    try_download_tool rg "https://github.com/BurntSushi/ripgrep/releases/download/$_rg_version/ripgrep-${_rg_version#v*}-${ARCH_RG}-${PLATFORM_RG}.tar.gz"
fi

if should_download_tool difft; then
    _dt_version="$(get_github_release Wilfred/difftastic)"
    try_download_tool difft "https://github.com/Wilfred/difftastic/releases/download/$_dt_version/difft-${ARCH_BAT}-${PLATFORM_DIFFT}.tar.gz"
fi
