cols() {
    #!/usr/bin/env bash

    printf "\e[0m   0 (No color)\n"
    printf "\e[0m1;30 \033[1;30mGRAY\t\e[0m  37 \033[0;37mLIGHT_GRAY\n"
    printf "\e[0m  31 \033[0;31mRED\t\e[0m1;31 \033[1;31mLIGHT_RED\n"
    printf "\e[0m  32 \033[0;32mGREEN\t\e[0m1;32 \033[1;32mLIGHT_GREEN\n"
    printf "\e[0m  33 \033[0;33mYELLOW\t\e[0m1;33 \033[1;33mLIGHT_YELLOW\n"
    printf "\e[0m  34 \033[0;34mBLUE\t\e[0m1;34 \033[1;34mLIGHT_BLUE\n"
    printf "\e[0m  35 \033[0;35mPURPLE\t\e[0m1;35 \033[1;35mLIGHT_PURPLE\n"
    printf "\e[0m  36 \033[0;36mCYAN\t\e[0m1;36 \033[1;36mLIGHT_CYAN\n"
    printf "\e[0m  37 \033[1;37mWHITE\t\e[0m  30 \033[0;30mBLACK\n"
}

box() {
    echo "\
    ─  │  ┌ ┬ ┐
    ┄  ┆  ├ ┼ ┤ ╲ ╱
    ┈  ┊  └ ┴ ┘

    ━  ┃  ┏ ┳ ┓ ┏ ┯ ┓ ┏ ┳ ┓ ┏ ┯ ┓
    ┅  ┇  ┣ ╋ ┫ ┣ ┿ ┫ ┠ ╂ ┨ ┠ ┼ ┨
    ┉  ┋  ┗ ┻ ┛ ┗ ┷ ┛ ┗ ┻ ┛ ┗ ┷ ┛"
}
