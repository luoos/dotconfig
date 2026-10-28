" ~/.vimrc — basic setup

" Start from Vim's own sensible defaults (macOS's system vimrc skips them)
unlet! skip_defaults_vim
source $VIMRUNTIME/defaults.vim

" --- Syntax & colors ---
syntax on
filetype plugin indent on
" Use the terminal's 16 ANSI colors (no termguicolors), so Vim follows
" whatever theme Ghostty uses — currently Breadog (light)
set notermguicolors
set background=light
colorscheme default
" Search matches: dark text on Breadog's tan (7); current match: light text on orange (11)
hi Search    cterm=NONE ctermfg=0  ctermbg=7
hi CurSearch cterm=bold ctermfg=15 ctermbg=11
hi IncSearch cterm=bold ctermfg=15 ctermbg=11

" --- Cursor shape: beam in insert, underline in replace, block in normal ---
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[2 q"
" Block when Vim starts; beam again on exit to match the shell's insert mode
let &t_ti .= "\<Esc>[2 q"
let &t_te .= "\<Esc>[6 q"
set ttimeout ttimeoutlen=10   " no lag leaving insert mode with Esc

" --- Editing ---
set number relativenumber
set cursorline
set expandtab tabstop=4 shiftwidth=4 softtabstop=4
set smartindent
set ignorecase smartcase hlsearch
set mouse=a
set clipboard=unnamed         " yank/paste use the macOS clipboard
set scrolloff=5
set signcolumn=auto
set undofile undodir=~/.vim/undo//
if !isdirectory(expand('~/.vim/undo')) | call mkdir(expand('~/.vim/undo'), 'p') | endif

" Ctrl-L also clears search highlight
nnoremap <silent> <C-l> :nohlsearch<CR><C-l>

" --- Reference lines for an AI agent (Claude Code etc.) ---
" <Space>a copies "@path#L12" (normal) or "@path#L12-20" (visual) to the clipboard;
" paste it into the agent running in another Ghostty split/tab.
let mapleader = ' '
function! s:CopyLineRef(l1, l2) abort
  let path = expand('%:.')   " relative to Vim's cwd, absolute if outside it
  if empty(path) | echohl WarningMsg | echo 'Buffer has no file' | echohl None | return | endif
  let ref = '@' . path . '#L' . a:l1 . (a:l1 == a:l2 ? '' : '-' . a:l2)
  call system('pbcopy', ref . ' ')
  echo 'Copied ' . ref
endfunction
nnoremap <silent> <leader>a :<C-u>call <SID>CopyLineRef(line('.'), line('.'))<CR>
xnoremap <silent> <leader>a :<C-u>call <SID>CopyLineRef(line("'<"), line("'>"))<CR>
