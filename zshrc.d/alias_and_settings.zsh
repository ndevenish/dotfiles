
bindkey -e

setopt autocd notify
setopt EXTENDED_HISTORY

setopt noautomenu
setopt nomenucomplete

# Allow inline comments
setopt interactivecomments

# This is annoying for things like conda
setopt noautoremoveslash

# Allow tab completion of paths after = e.g. --prefix=<path>
setopt magic_equal_subst

# BSD-style, safe to always set
export CLICOLOR=1
# Detect GNU vs BSD ls to turn on colours
if ls --color=auto >/dev/null 2>&1; then
    alias ls='ls --color=auto'
    alias ll='ls --color=auto -lh'
    alias lt='ls --color=auto -lrth'
else
    alias ll='ls -lh'
    alias lt='ls -lrth'
fi

# Set up a solarised-esque colour scheme
() {
    if [[ $(tty -s && tput colors) == 256 ]]; then
        # Setup a solarized colour scheme for ls-contrast
        local BLUE='38;5;33'
        local YELLOW='38;5;136'
        local MAGENTA='38;5;125'
        local PURPLE="$MAGENTA"
        local CYAN='38;5;37'
        local RED='38;5;160'
        local GREEN='38;5;64'

        if ls --color=auto >/dev/null 2>&1; then
            # GNU ls
            export LS_COLORS="rs=0:di=01;${BLUE}:ln=01;${CYAN}:mh=00:pi=40;33:so=01;${MAGENTA}:do=01;${MAGENTA}:bd=40;33;01:cd=40;33;01:or=40;${RED};01:mi=01;05;37;41:su=37;41:sg=30;43:ca=30;41:tw=30;42:ow=34;42:st=37;44:ex=01;${GREEN}:*.tar=01;${RED}:*.tgz=01;${RED}:*.arc=01;${RED}:*.arj=01;${RED}:*.taz=01;${RED}:*.lha=01;${RED}:*.lz4=01;${RED}:*.lzh=01;${RED}:*.lzma=01;${RED}:*.tlz=01;${RED}:*.txz=01;${RED}:*.tzo=01;${RED}:*.t7z=01;${RED}:*.zip=01;${RED}:*.z=01;${RED}:*.Z=01;${RED}:*.dz=01;${RED}:*.gz=01;${RED}:*.lrz=01;${RED}:*.lz=01;${RED}:*.lzo=01;${RED}:*.xz=01;${RED}:*.bz2=01;${RED}:*.bz=01;${RED}:*.tbz=01;${RED}:*.tbz2=01;${RED}:*.tz=01;${RED}:*.deb=01;${RED}:*.rpm=01;${RED}:*.jar=01;${RED}:*.war=01;${RED}:*.ear=01;${RED}:*.sar=01;${RED}:*.rar=01;${RED}:*.alz=01;${RED}:*.ace=01;${RED}:*.zoo=01;${RED}:*.cpio=01;${RED}:*.7z=01;${RED}:*.rz=01;${RED}:*.cab=01;${RED}:*.jpg=01;${MAGENTA}:*.jpeg=01;${MAGENTA}:*.gif=01;${MAGENTA}:*.bmp=01;${MAGENTA}:*.pbm=01;${MAGENTA}:*.pgm=01;${MAGENTA}:*.ppm=01;${MAGENTA}:*.tga=01;${MAGENTA}:*.xbm=01;${MAGENTA}:*.xpm=01;${MAGENTA}:*.tif=01;${MAGENTA}:*.tiff=01;${MAGENTA}:*.png=01;${MAGENTA}:*.svg=01;${MAGENTA}:*.svgz=01;${MAGENTA}:*.mng=01;${MAGENTA}:*.pcx=01;${MAGENTA}:*.mov=01;${MAGENTA}:*.mpg=01;${MAGENTA}:*.mpeg=01;${MAGENTA}:*.m2v=01;${MAGENTA}:*.mkv=01;${MAGENTA}:*.webm=01;${MAGENTA}:*.ogm=01;${MAGENTA}:*.mp4=01;${MAGENTA}:*.m4v=01;${MAGENTA}:*.mp4v=01;${MAGENTA}:*.vob=01;${MAGENTA}:*.qt=01;${MAGENTA}:*.nuv=01;${MAGENTA}:*.wmv=01;${MAGENTA}:*.asf=01;${MAGENTA}:*.rm=01;${MAGENTA}:*.rmvb=01;${MAGENTA}:*.flc=01;${MAGENTA}:*.avi=01;${MAGENTA}:*.fli=01;${MAGENTA}:*.flv=01;${MAGENTA}:*.gl=01;${MAGENTA}:*.dl=01;${MAGENTA}:*.xcf=01;${MAGENTA}:*.xwd=01;${MAGENTA}:*.yuv=01;${MAGENTA}:*.cgm=01;${MAGENTA}:*.emf=01;${MAGENTA}:*.axv=01;${MAGENTA}:*.anx=01;${MAGENTA}:*.ogv=01;${MAGENTA}:*.ogx=01;${MAGENTA}:*.aac=01;${CYAN}:*.au=01;${CYAN}:*.flac=01;${CYAN}:*.mid=01;${CYAN}:*.midi=01;${CYAN}:*.mka=01;${CYAN}:*.mp3=01;${CYAN}:*.mpc=01;${CYAN}:*.ogg=01;${CYAN}:*.ra=01;${CYAN}:*.wav=01;${CYAN}:*.axa=01;${CYAN}:*.oga=01;${CYAN}:*.spx=01;${CYAN}:*.xspf=01;${CYAN}:"
        fi
    fi
}


alias cdg='cd $(git rev-parse --show-toplevel)'

