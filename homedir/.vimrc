set number
set paste
set ruler
syntax on
set backspace=indent,eol,start

" Higlight rogue extra spaces. From http://vim.wikia.com/wiki/Highlight_unwanted_spaces
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

" Requires vim7.3: Highlight out-of-range columns
let &colorcolumn="73,80,".join(range(100,999),",")

set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4

if has("autocmd")
  " If the filetype is Makefile then we need to use tabs
  " So do not expand tabs into space.
  autocmd FileType make   set noexpandtab
  " 50/72 rulers for git commits
  autocmd Filetype gitcommit let &colorcolumn="50,".join(range(80,888),",")

endif

let g:indentLine_char = '▏'

au BufRead,BufNewFile SConscript set filetype=python

" set background=dark

filetype plugin indent on

let g:rustfmt_autosave = 1

" Don't let indentLines hide the quotes in markdown or JSON
let g:vim_json_conceal=0
let g:markdown_syntax_conceal=0

