" https://github.com/rhysd/dotfiles/blob/master/vimrc

" STARTUP:"{{{

" Initialisation"{{{
scriptencoding utf-8

" Prevent vim-tiny & vim-small
if !1 | finish | endif

" This is vim, not vi
set nocompatible
filetype off

function! s:get_SID()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_\zeget_SID$')
endfunction
let s:SID = s:get_SID()
delfunction s:get_SID
"}}}
" Vimrc augroup"{{{
augroup MyVimrc
  au!

  au! BufWritePost $MYVIMRC nested source $MYVIMRC
augroup END

command! -nargs=* Autocmd autocmd MyVimrc <args>
command! -nargs=* AutocmdFT autocmd MyVimrc Filetype <args>
"}}}
" Autocmdft"{{{
AutocmdFT vim highlight def link myVimAutocmd vimAutoCmd
AutocmdFT vim match myVimAutocmd /\<\(Autocmd\|AutocmdFT\)\>/
"}}}
" Map leader"{{{
let mapleader = ','
let g:mapleader = ','
let g:maplocalleader = 'm'
"}}}
" Helpers"{{{
" http://pastebin.com/dbgaHARn
" https://github.com/rhysd/dotfiles/blob/master/vimrc

" Create directory
function! s:create_dir(path)
  if !isdirectory(a:path)
    " Note: Not avaible on all systems. To check: if has('*mkdir')
    call mkdir(a:path, 'p')
  endif
endfunction

" Source files
function! SourceIfExist(path)
    if filereadable(a:path)
        execute 'source' a:path
    endif
endfunction

" Matchit.vim - matchpair
function! s:matchit(...)
    if !exists('s:matchit_loaded')
        runtime macros/matchit.vim
        let s:matchit_loaded = 1
    endif
    let default_pairs = [&matchpairs]
    let b:match_words = get(b:, 'match_words', '') . ',' . join(default_pairs, ',') . ',' . join(a:000, ',')
endfunction

" Echo errors
function! EchoError(...)
    echohl Error
    execute 'echomsg' join(map(copy(a:000), 'string(v:val)'), ' ')
    echohl None
endfunction
command! -nargs=+ EchoError call EchoError(<f-args>)
"}}}
" Git helpers "{{{
" git root"{{{
function! s:git_root_dir()
  if(system('git rev-parse --is-inside-work-tree') ==# "true\n")
    return system('git rev-parse --show-cdup')
  else
    echoerr 'current directory is outside git working tree'
  endif
endfunction
"}}}
" git add "{{{
function! s:git_add(fname)
  if ! filereadable(a:fname)
    echoerr 'file cannot be opened'
    return
  endif
  execute 'lcd' fnamemodify(a:fname, ':h')
  let result = system('git add '.a:fname)
  if v:shell_error
    echoerr 'failed to add: '.result
  else
    echo fnamemodify(a:fname, ':t') . ' is added:'
  endif
endfunction
command! -nargs=0 GitAddThisFile call <SID>git_add(expand('%:p'))
nnoremap <silent><Leader>ga :<C-u>GitAddThisFile<CR>
"}}}
" git blame "{{{
function! s:git_blame(fname, ...)
  execute 'lcd' fnamemodify(a:fname, ':p:h')
  let range = (a:0==0 ? line('.') : a:1.','.a:2)
  let errfmt = &errorformat
  set errorformat=.*
  cgetexpr system('git blame -L '.range.' '.fnamemodify(a:fname, ':p'))
  let &errorformat = errfmt
  Unite quickfix -no-start-insert
endfunction
command! -nargs=0 GitBlameThisLine call <SID>git_blame(expand('%'))
command! -range GitBlameRange call <SID>git_blame(expand('%'), <line1>, <line2>)
nnoremap <silent><Leader>gb :<C-u>GitBlameThisLine<CR>
vnoremap <silent><Leader>gb :GitBlameRange<CR>
"}}}
" git push"{{{
function! s:git_push(args)
  execute "QuickRun sh -cmd sh -src 'git push ".a:args."' -runner vimproc"
endfunction
command! -nargs=* GitPush call <SID>git_push(<q-args>)
nnoremap <Leader>gp :<C-u>GitPush<CR>
"}}}
" git commit"{{{
Autocmd VimEnter COMMIT_EDITMSG if getline(1) == '' | execute 1 | startinsert | endif

function! s:hubrowse(...)
  if !executable('hub')
    echoerr "'hub' command is not found"
    return
  endif

  let dir = expand('%:p:h')
  if a:0 > 1
    let repo = shellescape(a:1)
  else
    let repo = '--'
  endif

  let subcmd = a:000[-1]

  echom system(printf('cd %s && hub browse %s %s', shellescape(dir), repo, shellescape(subcmd)))
endfunction

command! -nargs=+ Hubrowse call <SID>hubrowse(<f-args>)
command! -nargs=* GitIssue call call("<SID>hubrowse", split("<args> issues"))
"}}}
"}}}
" Environment"{{{
"Detect OS"{{{
let s:is_windows = has('win16') || has('win32') || has('win64')
let s:is_cygwin = has('win32unix')
let s:is_mac = !s:is_windows && !s:is_cygwin
  \ && (has('mac') || has('macunix') || has('gui_macvim') ||
  \   (!executable('xdg-open') &&
  \     system('uname') =~? '^darwin'))
let s:is_unix = has('linux') || has('unix')
"}}}
" Detect Gui"{{{
let s:is_gui = has("gui_running")
let s:is_gui_macvim = has("gui_macvim")
let s:is_gui_linux = has("gui_gtk2")
"}}}
" Detect Vim"{{{
let s:is_starting = has('vim_starting')
"}}}
" Detect Term"{{{
let s:is_term_xterm = &term =~ "xterm*"
let s:is_term_dterm = &term =~ "dterm*"
let s:is_term_rxvt = &term =~ "rxvt*"
let s:is_term_screen = &term =~ "screen*"
let s:is_term_linux = &term =~ "linux"

if exists('$TMUX')
  set clipboard=
else
  set clipboard=unnamed                             "sync with OS clipboard
endif
"}}}
" For Windows"{{{

function! IsWindows()
  return s:is_windows
endfunction

if s:is_windows && !s:is_cygwin
  set shellslash
  let $HOME=$USERPROFILE
  set clipboard=unnamed
  behave mswin
  " ensure correct shell in gvim
  set shell=c:\windows\system32\cmd.exe
endif
"}}}
" For Linux"{{{

"}}}
" For Mac"{{{
function! IsMac()
  return !s:is_windows && !s:is_cygwin
    \ &&  (has('mac') || has('macunix') || has('gui_macvim') ||
    \     (!executable('xdg-open') &&
    \     system('uname') =~? '^darwin'))
endfunction

"}}}
"}}}
" Initialmessage"{{{
augroup InitialMessage
  au!

  autocmd VimEnter * echo "EnJoy vimming!"
augroup END
"}}}
" Variables"{{{

let $CACHE = expand('~/.cache')
call s:create_dir($CACHE)
let s:neobundle_dir = expand('$CACHE/neobundle')

let s:config_dir = fnameescape(expand('~/.vim'))
let s:cache_dir = $CACHE . '/.cache'

call s:create_dir(s:config_dir)
call s:create_dir(s:cache_dir)

" Private
let s:private_dir = s:cache_dir . '/.private'
call s:create_dir(s:private_dir)

" Backup, view, undo and swap directories
let s:backup_dir = s:cache_dir . '/backup'
let s:view_dir = s:cache_dir . '/view'
let s:undo_dir = s:cache_dir . '/undo'
let s:swap_dir = s:cache_dir . '/swap'
let s:tmp_dir = s:cache_dir . '/tmp'

call s:create_dir(s:backup_dir)
call s:create_dir(s:view_dir)
call s:create_dir(s:undo_dir)
call s:create_dir(s:swap_dir)
call s:create_dir(s:tmp_dir)

" My bundle
let s:my_bundles_dir = s:config_dir . '/bundle'
call s:create_dir(s:my_bundles_dir)


"}}}
" Encoding"{{{
" For Windows
if s:is_windows
    if has('multi_byte')
        set termencoding=cp850
        setglobal fileencoding=utf-8
        set fileencodings=ucs-bom,utf-8,utf-16le,cp1252,iso-8859-15
    endif

else
" For Unix-like
    set termencoding=utf-8
    set fileencoding=utf-8
    set fileformat=unix
endif
"}}}
 " Load before"{{{
" Use .vimrc.before config if available
call SourceIfExist($HOME.'/.vimrc.before')

" Use private config if available
call SourceIfExist($HOME.'/.vimrc.secret')

"}}}
"}}}

" CONFIG:"{{{
" Formatting"{{{
set autoindent smartindent
" Cf SetIndent in 'COMMANDS' in order to change these values
set tabstop=2 shiftwidth=2 softtabstop=2
set shiftround
set expandtab
set textwidth=0
set smarttab
set fileformats=unix,dos,mac
set formatoptions-=r
set formatoptions-=o

" Formatting mappings"{{{
nmap <leader>fef :call Preserve("normal gg=G")<CR>
nmap <leader>f$ :call StripTrailingWhitespace()<CR>
vmap <leader>s :sort<cr>
"}}}
" Indent multiple lines with TAB"{{{
"vmap <Tab> >
"vmap <S-Tab> <
"}}}
" Keep visual selection after identing"{{{
vnoremap < <gv
vnoremap > >gv
"nnoremap > >>
"nnoremap < <<
"}}}
" Remove the Windows ^M - when the encodings gets messed up"{{{
noremap <Leader>mm mmHmt:%s/<C-V><cr>//ge<cr>'tzt'm
"}}}
"}}}
" Search"{{{
set confirm
set ignorecase
set infercase
set smartcase
set hlsearch
set incsearch
set magic
set showmatch
set matchtime=2
set matchpairs+=<:>

" Sane regex"{{{
nnoremap / /\v
vnoremap / /\v
nnoremap ? ?\v
vnoremap ? ?\v
cnoremap s/ s/\v
"}}}
" To clear search highlighting rather than toggle it and off"{{{
"noremap <silent> <leader><space> :noh<CR>
noremap <silent> <leader><space> :set hlsearch! hlsearch?<cr>
"}}}
" ag using"{{{
if executable('ag')
  set grepprg=ag\ --nogroup\ --nocolor\ --column
else
  set grepprg=grep\ -rnH\ --exclude=tags\ --exclude-dir=.git\ --exclude-dir=node_modules
endif
"}}}
"}}}
" Shells"{{{
" VIM expects to be run from a POSIX shell."{{{
if $SHELL =~ '/fish$'
  set shell=sh
endif
"}}}
" Windows shell"{{{
if s:is_windows && !s:is_cygwin
  " ensure correct shell in gvim
  set shell=c:\windows\system32\cmd.exe
endif
"}}}
"}}}
" Display"{{{
set backspace=indent,eol,start
set hidden
set ttyfast
set showcmd
set scrolloff=5

" best vim-airline display
set noshowmode
set lazyredraw

set ruler
set rulerformat=%45(%12f%=\ %m%{'['.(&fenc!=''?&fenc:&enc).']'}\ %l-%v\ %p%%\ [%02B]%)
set laststatus=2
set statusline=%f:\ %{substitute(getcwd(),'.*/','','')}\ %m%=%{(&fenc!=''?&fenc:&enc).':'.strpart(&ff,0,1)}\ %l-%v\ %p%%\ %02B
set virtualedit& virtualedit+=block

"}}}
" Number"{{{
set number numberwidth=3
function! NumberToggle()
  if(&relativenumber == 1)
    set norelativenumber
    set number
  else
    set number
    set relativenumber
endif
endfunc
" Switch number/relativenumber
nnoremap <leader>; :call NumberToggle()<cr>
"}}}
" List and character"{{{
set list
if (&termencoding ==# 'utf-8' || &encoding ==# 'utf-8') && version >= 700
  set listchars=tab:›\ 
  set listchars+=eol:$
  set listchars+=trail:⋅
  set listchars+=extends:›
  set listchars+=precedes:‹
  set listchars+=nbsp:+

  set fillchars=stl:\ 
  set fillchars+=stlnc:\ 
  set fillchars+=vert:\|
  set fillchars+=fold:\⋅
  set fillchars+=diff:-
else
  set listchars=tab:\ \ 
  set listchars+=eol:$
  set listchars+=trail:~
  set listchars+=extends:>
  set listchars+=precedes:<
  set listchars+=nbsp:+

  set fillchars=stl:\ 
  set fillchars+=stlnc:\ 
  set fillchars+=vert:\|
  set fillchars+=fold:\-
  set fillchars+=diff:-
endif
set showbreak=↪\ 

"Invisible character colors
highlight NonText guifg=#4a4a59
highlight SpecialKey guifg=#4a4a59
"
" Switch list
nmap <leader>l :set list! list?<cr>
"}}}
" Help"{{{
set helplang=fr,en
set keywordprg=:help
" Cf SmartHelp in 'COMMANDS'
set keywordprg=SmartHelp
"}}}
" Treat break lines"{{{
set linebreak
" Breakindent"{{{
if exists('+breakindent')
  set wrap
  set breakindent
  set breakindentopt=shift:-4
  let &showbreak='↪ '
else
  set nowrap
endif
"}}}
" Navigate line by line through wrapped text (skip wrapped lines)."{{{
au BufReadPre * imap <UP> <ESC>gka
au BufReadPre * imap <DOWN> <ESC>gja
"}}}
" Navigate row by row through wrapped text."{{{
au BufReadPre * nmap k gk
au BufReadPre * nmap j gj
"}}}
" Treat long lines as break lines (useful when moving around in them)"{{{
nnoremap <silent> k :<C-U>execute 'normal!' (v:count>1 ? "m'".v:count.'k' : 'gk')<Enter>
nnoremap <silent> j :<C-U>execute 'normal!' (v:count>1 ? "m'".v:count.'j' : 'gj')<Enter>
"}}}
"}}}
" Errors"{{{
set noerrorbells
set novisualbell
set timeoutlen=500
set t_vb=
"}}}
" Time out on key codes but not mappings."{{{
" Basically this makes terminal Vim work sanely.
set notimeout
set ttimeout
set ttimeoutlen=10
"}}}
" Conceal"{{{
if has('conceal')
  set conceallevel=1
  set listchars+=conceal:Δ
endif
"}}}
" Ballooneval"{{{
if has('balloon_eval') && has('unix')
    set ballooneval
endif
"}}}
" Undos, Views, Backups, Swap"{{{
" Undos"{{{
if exists('+undofile')
  set undofile
  let &undodir = s:undo_dir
  set undolevels=2048
  set undoreload=65538
endif
"}}}
" Views"{{{
" Set viewdir"{{{
let &viewdir = s:view_dir
"}}}
function! MakeViewCheck() "{{{
    if has('quickfix') && &buftype =~ 'nofile' | return 0 | endif
    if expand('%') =~ '\[.*\]' | return 0 | endif
    if empty(glob(expand('%:p'))) | return 0 | endif
    if &modifiable == 0 | return 0 | endif
    if len($TEMP) && expand('%:p:h') == $TEMP | return 0 | endif
    if len($TMP) && expand('%:p:h') == $TMP | return 0 | endif

    let file_name = expand('%:p')
    for ifiles in g:skipview_files
        if file_name =~ ifiles
            return 0
        endif
    endfor

    return 1
endfunction "}}}
" Restore view"{{{
set viewoptions=folds,options,cursor,unix,slash     "unix/windows compatibility
" To preserve views of the files (includes folds)
if exists("g:loaded_restore_view")
    finish
endif
let g:loaded_restore_view = 1
"}}}
" Skip views"{{{
if !exists("g:skipview_files")
    let g:skipview_files = []
endif
"}}}
" Autoview"{{{
augroup AUTOVIEW
  " Autosave & Load Views (?* or *)."{{{
  "autocmd BufWritePost,WinLeave,BufWinLeave * if MakeViewCheck() | mkview | endif
  "autocmd BufWinEnter * if MakeViewCheck() | silent! loadview | endif
"}}}
augroup END
"}}}
"}}}
" Backups"{{{
" Don't create backup
set nobackup "Don't make a backup before overwriting a file
set nowritebackup "Don't make a backup before overwriting a file
set backup
set backupskip=/tmp/*,$TMPDIR/*,$TMP/*,$TEMP/*,$HOME/Private/*,s:private_dir/*,*test*,*temp*,*tmp*,*tst*,*~,*bak
let &backupdir = s:backup_dir "List of directories for the backup file
"}}}
" Swap files"{{{
set noswapfile
let &directory = s:swap_dir
"}}}
"}}}
" Wild menu completion"{{{

if has('wildmenu')
  set nowildmenu
  set wildmode=list:longest,full
  set wildoptions=tagfile
  set wildignorecase
  set wildignore+=.hg,.git,.svn,*.pyc,*.spl,*.o,*.out,*~,#*#,%*
  set wildignore+=*.jpg,*.jpeg,*.png,*.gif,*.zip,**/tmp/**,*.DS_Store
  set wildignore+=**/cache/??,**/cache/mustache,**/cache/media,**/logs/????
  set wildignore+=*/vendor/gems/*,*/vendor/cache/*,*/.sass-cache/*
  set wildcharm=<C-Z>
endif


"}}}
" Better completion"{{{
set complete=.,w,b,u,t
set completeopt=longest,menuone,preview
"}}}
" Folding"{{{
set foldenable
set foldmethod=marker
set foldlevelstart=0
set foldopen=block,hor,mark,percent,quickfix,tag,search

" Folding mappings"{{{
" Make zO recursively open whatever fold we're in, even if it's partially open."{{{
nnoremap zO zczO
nnoremap zr zr:echo &foldlevel<cr>
nnoremap zm zm:echo &foldlevel<cr>
nnoremap zR zR:echo &foldlevel<cr>
nnoremap zM zM:echo &foldlevel<cr>
"}}}
" Folding or unfolding"{{{

noremap [fold] <nop>
nmap <Space> [fold]
vmap <Space> [fold]

noremap [fold]j zj
noremap [fold]k zk
noremap [fold]n ]z
noremap [fold]p [z
noremap <silent>[fold]h :<C-u>call <SID>smart_foldcloser()<CR>
noremap [fold]l zo
noremap [fold]L zO
noremap [fold]a za
noremap [fold]m zM
noremap [fold]i zMzvzz
noremap [fold]r zR
noremap [fold]f zf
noremap [fold]d zd

"nnoremap <silent> <Space> @=(foldlevel('.')?'za':"\<Space>")<CR>
"vnoremap <Space> zf
"}}}
"}}}
" Autofolding"{{{
augroup Folding
    "au BufRead * normal zR
    "au BufRead *.vimrc normal zM
augroup END
"}}}
function! s:smart_foldcloser() "{{{
    if foldlevel('.') == 0
        norm! zM
        return
    endif

    let foldc_lnum = foldclosed('.')
    norm! zc
    if foldc_lnum == -1
        return
    endif
    if foldclosed('.') != foldc_lnum
        return
    endif
    norm! zM
endfunction
"}}}
function! NeatFoldText() "{{{
  let line = ' ' . substitute(getline(v:foldstart), '^\s*"\?\s*\|\s*"\?\s*{{' . '{\d*\s*', '', 'g') . ' '
  let lines_count = v:foldend - v:foldstart + 1
  let lines_count_text = '| ' . printf("%10s", lines_count . ' lines') . ' |'
  let foldchar = matchstr(&fillchars, 'fold:\zs.')
  let foldtextstart = strpart('+' . repeat(foldchar, v:foldlevel*2) . line, 0, (winwidth(0)*2)/3)
  let foldtextend = lines_count_text . repeat(foldchar, 8)
  let foldtextlength = strlen(substitute(foldtextstart . foldtextend, '.', 'x', 'g')) + &foldcolumn
  return foldtextstart . repeat(foldchar, winwidth(0)-foldtextlength) . foldtextend
endfunction
set foldtext=NeatFoldText()
"}}}
"}}}
" Windows"{{{
" Cf SmartSplit in 'COMMANDS'
set splitbelow
set splitright

" Close windows "{{{
function! s:close_window(winnr)
    if winbufnr(a:winnr) !=# -1
        execute a:winnr . 'wincmd w'
        execute 'wincmd c'
        return 1
    else
        return 0
    endif
endfunction

function! s:get_winnr_like(expr)
    let ret = []
    let winnr = 1
    while winnr <= winnr('$')
        let bufnr = winbufnr(winnr)
        if eval(a:expr)
            call add(ret, winnr)
        endif
        let winnr = winnr + 1
    endwhile
    return ret
endfunction

function! s:close_windows_like(expr, ...)
    let winnr_list = s:get_winnr_like(a:expr)
    " Close current window if current matches a:expr.
    " let winnr_list = s:move_current_winnr_to_head(winnr_list)
    if empty(winnr_list)
        return
    endif

    let first_only = exists('a:1')
    let prev_winnr = winnr()
    try
        for winnr in reverse(sort(winnr_list))
            call s:close_window(winnr)
            if first_only
                return 1
            endif
        endfor
        return 0
    finally
        " Back to previous window.
        let cur_winnr = winnr()
        if cur_winnr !=# prev_winnr && winbufnr(prev_winnr) !=# -1
            execute prev_winnr . 'wincmd w'
        endif
    endtry
endfunction
"}}}
" Close target windows "{{{
function! s:is_target_window(winnr)
    let target_filetype = ['ref', 'unite', 'vimfiler', 'vimshell']
    let target_buftype  = ['help', 'quickfix']
    let winbufnr = winbufnr(a:winnr)
    return index(target_filetype, getbufvar(winbufnr, '&filetype')) >= 0 ||
                \ index(target_buftype, getbufvar(winbufnr, '&buftype')) >= 0
endfunction

nnoremap <silent><C-q>
            \ :<C-u>call <SID>close_windows_like('s:is_target_window(winnr)')<CR>
inoremap <silent><C-q>
            \ <Esc>:call <SID>close_windows_like('s:is_target_window(winnr)')<CR>
nnoremap <silent><Leader>cp
            \ :<C-u>call <SID>close_windows_like('s:is_target_window(winnr)', 'first_only')<CR>
"}}}
" Window navigation"{{{
" Resize windows"{{{

nnoremap + <C-W>+
nnoremap _ <C-W>-
nnoremap = <C-W>>
nnoremap - <C-W><
"}}}
" Move between windows"{{{
if !exists('s:settings.switch_windows')
  nnoremap <C-h> <C-w>h
  nnoremap <C-j> <C-w>j
  nnoremap <C-k> <C-w>k
  nnoremap <C-l> <C-w>l
else
  map <C-J> <C-W>j<C-W>_
  map <C-k> <C-W>k<C-W>_
  map <C-h> <C-W>h<C-W>_
  map <C-l> <C-W>l<C-W>_
endif
"}}}
" Window split"{{{
" Vertcal split"{{{
nnoremap <leader>vv <C-w>v<C-w>l
"}}}
" Horizontal split"{{{
nnoremap <leader>ss <C-w>s
"}}}
" Vertically split all split"{{{
nnoremap <leader>vsa :vert sba<cr>
"}}}
"}}}
" Window killer"{{{
nnoremap <silent> Q :call CloseWindowOrKillBuffer()<cr>
"}}}
"}}}
"}}}
" Buffer and tab"{{{
" Buffer"{{{
" Quick buffer open"{{{
nnoremap gb :ls<cr>:e #
"}}}
" Close the current buffer"{{{
map <leader>bd :Bclose<cr>
"}}}
" Close all the buffers"{{{
map <leader>ba :1,1000 bd!<cr>
"}}}
" Switch CWD to the directory of the open buffer"{{{
map <leader>cd :cd %:p:h<cr>:pwd<cr>
"}}}
" Specify the behavior when switching between buffers "{{{
try
  set switchbuf=useopen,usetab,newtab
  set stal=2
catch
endtry
"}}}
" Remember info about open buffers on close"{{{
set viminfo^=%
"}}}
"}}}
" Tabs"{{{
" Useful mappings for managing tabs"{{{
map <leader>tn :tabnew<CR>
map <leader>tc :tabclose<CR>
map <leader>to :tabonly<CR>
map <leader>tm :tabmove
"}}}
" Opens a new tab with the current buffer's path"{{{
" Super useful when editing files in the same directory
map <leader>te :tabedit <c-r>=expand("%:p:h")<cr>/
"}}}
"}}}
" Delete current buffer"{{{
function! s:delete_current_buf()
    let bufnr = bufnr('%')
    bnext
    if bufnr == bufnr('%') | enew | endif
    silent! bdelete #
endfunction
nnoremap <C-w>d :<C-u>call <SID>delete_current_buf()<CR>
nnoremap <C-w>D :<C-u>bdelete<CR>
"}}}
""}}}
" Using the mouse on a terminal."{{{
if has('mouse')
  set mouse=a
  if has('mouse_sgr') || v:version > 703 ||
        \ v:version == 703 && has('patch632')
    set ttymouse=sgr
  else
    set ttymouse=xterm2
  endif

  " Paste.
  nnoremap <RightMouse> "+p
  xnoremap <RightMouse> "+p
  inoremap <RightMouse> <C-r><C-o>+
  cnoremap <RightMouse> <C-r>+
endif
"}}}
" Cursor"{{{
"
"" Cursorline"{{{
"" http://d.hatena.ne.jp/thinca/20090530/1243615055
"augroup cursor_line
"  au!
"  au VimEnter,WinEnter,BufWinEnter * setlocal cursorline
"  au WinLeave * setlocal nocursorline
"
""  Autocmd CursorMoved,CursorMovedI,WinLeave * setlocal nocursorline
""  Autocmd CursorHold,CursorHoldI,WinEnter * setlocal cursorline
"augroup END
""}}}
" Cursorcolumn"{{{
"set cursorcolumn
"let &colorcolumn=s:settings.max_column
"if exists('s:settings.no_cursorcolumn')
"  augroup cursor_column
"    au!
"
"    au!Autocmd CursorMoved,CursorMovedI,WinLeave * setlocal nocursorcolumn
"    Autocmd CursorHold,CursorHoldI,WinEnter * setlocal cursorcolumn
"  augroup END
"endif
""}}}

augroup my_cursor
  au!

  autocmd CursorMoved,CursorMovedI * call s:auto_cursorline('CursorMoved')
  autocmd CursorHold,CursorHoldI * call s:auto_cursorline('CursorHold')
  autocmd WinEnter * call s:auto_cursorline('WinEnter')
  autocmd WinLeave * call s:auto_cursorline('WinLeave')

  let s:cursorline_lock = 0
  function! s:auto_cursorline(event) "{{{
    if a:event ==# 'WinEnter'
      setlocal cursorline
      let s:cursorline_lock = 2
    elseif a:event ==# 'WinLeave'
      setlocal nocursorline
    elseif a:event ==# 'CursorMoved'
      if s:cursorline_lock
        if 1 < s:cursorline_lock
          let s:cursorline_lock = 1
        else
          setlocal nocursorline
          let s:cursorline_lock = 0
        endif
      endif
    elseif a:event ==# 'CursorHold'
      setlocal cursorline
      let s:cursorline_lock = 1
    endif
  endfunction "}}}
augroup END

" Jump to start and end of line"{{{
noremap H ^
noremap L $
vnoremap L g_
"}}}
" Change cursor position in insert mode"{{{
inoremap <C-h> <left>
inoremap <C-l> <right>
inoremap <C-u> <C-g>u<C-u>
"}}}
" Vimgrep"{{{
if mapcheck('<space>/') == ''
  nnoremap <space>/ :vimgrep //gj **/*<left><left><left><left><left><left><left><left>
endif
"}}}
"}}}
" ToHtml"{{{
function! VimrcTOHtml() "{{{
  TOhtml
  try
      silent exe '%s/&quot;\(\s\+\)\*&gt; \(.\+\)</"\1<a href="#\2" style="color: #bdf">\2<\/a></g'
  catch
  endtry

  try
      silent exe '%s/&quot;\(\s\+\)=&gt; \(.\+\)</"\1<a name="\2" style="color: #fff">\2<\/a></g'
  catch
  endtry

  exe ":write!"
  exe ":bd"
endfunction "}}}
" To export syntax highlighted code in html format."{{{
map <F6> :runtime! syntax/2html.vim
"}}}
"}}}
" Paste"{{{
" Toggle paste"{{{
map <F12> :set invpaste<CR>:set paste?<CR>
map <Leader>, :set invpaste<CR>:set paste?<CR>
"}}}
" Reselect last paste"{{{
nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'
"}}}
"}}}
" Chmod"{{{
if executable('chmod')
    Autocmd BufWritePost * call s:add_permission_x()

    function! s:add_permission_x()
        let file = expand('%:p')
        if getline(1) =~# '^#!' && !executable(file)
            silent! call vimproc#system('chmod a+x ' . shellescape(file))
        endif
    endfunction
endif
"}}}

" Customization"{{{
" ----------------------------------------------

" Html,Css, Sass, Scss, Haml {{{
AutocmdFT html,javascript
            \ if expand('%:e') ==# 'html' |
            \   nnoremap <buffer><silent><C-t>
            \       :<C-u>if &filetype ==# 'javascript' <Bar>
            \               setf html <Bar>
            \             else <Bar>
            \               setf javascript <Bar>
            \             endif<CR> |
            \ endif

AutocmdFT haml inoremap <expr> k getline('.')[col('.') - 2] ==# 'k' ? "\<BS>%" : 'k'
AutocmdFT haml SetIndent 2
AutocmdFT javascript nnoremap <buffer><silent><Leader>no :<C-u>VimShellInteractive node<CR>
Autocmd BufRead,BufNew,BufNewFile *.ejs setlocal ft=html

"
function! s:generate_html()
    if &filetype ==# 'haml' && executable('haml')
        let html = expand('%:p:r') . '.html'
        let cmdline = join(['haml', expand('%'), '>', html], ' ')
        call vimproc#system_bg(cmdline)
    endif
endfunction
Autocmd BufWritePost *.haml call <SID>generate_html()
"}}}
" Ruby {{{
AutocmdFT ruby SetIndent 2
AutocmdFT ruby inoremap <buffer><C-s> self.
AutocmdFT ruby inoremap <buffer>;; ::
AutocmdFT ruby nnoremap <buffer>[unite]r :<C-u>Unite ruby/require<CR>
AutocmdFT ruby call s:matchit()
Autocmd BufRead Guardfile setlocal filetype=ruby

let s:ruby_template = [ '#!/usr/bin/env ruby', '# encoding: utf-8', '', '' ]
Autocmd BufNewFile *.rb call append(0, s:ruby_template) | normal! G

function! s:start_irb()
    VimShell -split-command=vsplit
    VimShellSendString irb
    startinsert
endfunction
command! Irb call <SID>start_irb()

function! s:toggle_binding_pry()
    if getline('.') =~# '^\s*binding\.pry\s*$'
        normal! "_ddk
    else
        normal! obinding.pry
    endif
endfunction
AutocmdFT ruby nnoremap <buffer><silent><Leader>p :<C-u>call <SID>toggle_binding_pry()<CR>

function! s:exec_with_vimshell(cmd, ...)
    let cmdline = a:cmd . ' ' . expand('%:p') . ' ' . join(a:000)
    VimShell -split-command=vsplit
    execute 'VimShellSendString' cmdline
endfunction
AutocmdFT ruby nnoremap <buffer><silent><Leader>pr :<C-u>call <SID>exec_with_vimshell('ruby')<CR>

function! s:start_pry()
    VimShell -split-command=vsplit
    VimShellSendString pry -d coolline
endfunction
command! Pry call <SID>start_pry()
"}}}
" C++ {{{

" C++
set cinoptions& cinoptions+=:0,g0,N-1,m1

" -> decltype(expr)
function! s:open_online_cpp_doc()
    let l = getline('.')

    if l =~# '^\s*#\s*include\s\+<.\+>'
        let header = matchstr(l, '^\s*#\s*include\s\+<\zs.\+\ze>')
        if header =~# '^boost'
            execute 'OpenBrowser' 'http://www.google.com/cse?cx=011577717147771266991:jigzgqluebe&q='.matchstr(header, 'boost/\zs[^/>]\+\ze')
        else
            execute 'OpenBrowser' 'http://en.cppreference.com/mwiki/index.php?title=Special:Search&search='.matchstr(header, '\zs[^/>]\+\ze')
        endif
    else
        let cword = expand('<cword>')
        if cword ==# ''
            return
        endif
        let line_head = getline('.')[:col('.')-1]
        if line_head =~# 'boost::[[:alnum:]:]*$'
            execute 'OpenBrowser' 'http://www.google.com/cse?cx=011577717147771266991:jigzgqluebe&q='.cword
        elseif line_head =~# 'std::[[:alnum:]:]*$'
            execute 'OpenBrowser' 'http://en.cppreference.com/mwiki/index.php?title=Special:Search&search='.cword
        else
            normal! K
        endif
    endif
endfunction

AutocmdFT cpp nnoremap <silent><buffer>K :<C-u>call <SID>open_online_cpp_doc()<CR>
AutocmdFT cpp setlocal matchpairs+=<:>
AutocmdFT cpp inoremap <buffer>,  ,<Space>
AutocmdFT cpp inoremap <expr> e getline('.')[col('.') - 6:col('.') - 2] ==# 'const' ? 'expr ' : 'e'

let g:c_syntax_for_h = 1
" }}}
" Ctags "{{{
" ----------------------------------------------

set tags=./tags;/,~/.cache/.cache/.vimtags

" Make tags placed in .git/tags file available in all levels of a repository
let gitroot = substitute(system('git rev-parse --show-toplevel'), '[\n\r]', '', 'g')
if gitroot != ''
  let &tags = &tags . ',' . gitroot . '/.git/tags'
endif

" }}}
" Omnicomplete "{{{
" ----------------------------------------------
" To disable omni complete, add the following to your .vimrc.before.local file:
"   let g:billinux_no_omni_complete = 1
if !exists('g:billinux_no_omni_complete')
  if has("autocmd") && exists("+omnifunc")
    autocmd Filetype *
      \if &omnifunc == "" |
      \setlocal omnifunc=syntaxcomplete#Complete |
      \endif
  endif

  hi Pmenu  guifg=#000000 guibg=#F8F8F8 ctermfg=black ctermbg=Lightgray
  hi PmenuSbar  guifg=#8A95A7 guibg=#F8F8F8 gui=NONE ctermfg=darkcyan ctermbg=lightgray cterm=NONE
  hi PmenuThumb  guifg=#F8F8F8 guibg=#8A95A7 gui=NONE ctermfg=lightgray ctermbg=darkcyan cterm=NONE

  " Some convenient mappings
  inoremap <expr> <Esc>      pumvisible() ? "\<C-e>" : "\<Esc>"
  if exists('g:billinux_map_cr_omni_complete')
    inoremap <expr> <CR>     pumvisible() ? "\<C-y>" : "\<CR>"
  endif
  inoremap <expr> <Down>     pumvisible() ? "\<C-n>" : "\<Down>"
  inoremap <expr> <Up>       pumvisible() ? "\<C-p>" : "\<Up>"
  inoremap <expr> <C-d>      pumvisible() ? "\<PageDown>\<C-p>\<C-n>" : "\<C-d>"
  inoremap <expr> <C-u>      pumvisible() ? "\<PageUp>\<C-p>\<C-n>" : "\<C-u>"

  " Automatically open and close the popup menu / preview window
  au CursorMovedI,InsertLeave * if pumvisible() == 0|silent! pclose|endif
  set completeopt=menu,preview,longest
endif

" }}}
" Custom Colors"{{{
" ----------------------------------------------

" General GUI {{{
" No bold in gvim's error messages
highlight ErrorMsg     gui=NONE
" Whitespace
highlight SpecialKey   ctermfg=235  guifg=#30302c
" YAML scalar
highlight yamlScalar   ctermfg=250  guifg=#a8a897
" Last search highlighting and quickfix's current line
highlight Search       ctermfg=183  ctermbg=237
" Brakets and pairs
highlight MatchParen   ctermfg=220  ctermbg=237
" Markdown headers
highlight link htmlH1 Statement
" Mode message (insert, visual, etc)
highlight ModeMsg      ctermfg=240
" Visual mode selection
highlight Visual       ctermbg=236

" }}}
" Popup menu {{{
highlight Pmenu       ctermfg=245 ctermbg=235
highlight PmenuSel    ctermfg=236 ctermbg=248
highlight PmenuSbar   ctermbg=235
highlight PmenuThumb  ctermbg=238

" }}}
" Unite {{{
highlight uniteInputPrompt            ctermfg=237
highlight uniteCandidateMarker        ctermfg=143
highlight uniteCandidateInputKeyword  ctermfg=12

" }}}
" Grep {{{
highlight link uniteSource__Grep        Directory
highlight link uniteSource__GrepLineNr  qfLineNr
highlight uniteSource__GrepLine         ctermfg=245 guifg=#808070
highlight uniteSource__GrepFile         ctermfg=4   guifg=#8197bf
highlight uniteSource__GrepSeparator    ctermfg=5   guifg=#f0a0c0
highlight uniteSource__GrepPattern      ctermfg=1   guifg=#cf6a4c

" }}}
" Quickfix {{{
highlight UniteQuickFixWarning              ctermfg=1
highlight uniteSource__QuickFix             ctermfg=8
highlight uniteSource__QuickFix_Bold        ctermfg=249
highlight link uniteSource__QuickFix_File   Directory
highlight link uniteSource__QuickFix_LineNr qfLineNr

" }}}
" VimFiler {{{
highlight vimfilerNormalFile  ctermfg=245 guifg=#808070
highlight vimfilerClosedFile  ctermfg=249 guifg=#a8a897
highlight vimfilerOpenedFile  ctermfg=254 guifg=#e8e8d3
highlight vimfilerNonMark     ctermfg=239 guifg=#4e4e43
highlight vimfilerLeaf        ctermfg=235 guifg=#30302c

" }}}

"}}}
"}}}

"}}}

" NEOBUNDLE:"{{{

" Install neobundle.vim"{{{
if has('vim_starting')
  " Set runtimepath.
  if IsWindows()
    let &runtimepath = join([
          \ expand('~/.vim'),
          \ expand('$VIM/runtime'),
          \ expand('~/.vim/after')], ',')
  endif

  " Load neobundle.
  if isdirectory('neobundle.vim')
    set runtimepath^=neobundle.vim
  elseif finddir('neobundle.vim', '.;') != ''
    execute 'set runtimepath^=' . finddir('neobundle.vim', '.;')
  elseif &runtimepath !~ '/neobundle.vim'
    if ! isdirectory(expand(s:neobundle_dir))
      echon "Installing neobundle.vim..."
      silent call s:create_dir(s:neobundle_dir)
      execute printf('!git clone %s://github.com/Shougo/neobundle.vim.git',
                \ (exists('$http_proxy') ? 'https' : 'git'))
                \ s:neobundle_dir.'/neobundle.vim'
      echo "done."
      if v:shell_error
        echoerr "neobundle.vim installation has failed!"
        finish
      endif
    endif

    execute 'set rtp+='.s:neobundle_dir.'/neobundle.vim'
  endif
endif
"}}}


call neobundle#begin(expand(s:neobundle_dir))

" NeoBundles"{{{

" In your .vimrc.before.local file
  " list only the plugin groups you will use
  if ! exists('g:billinux_neobundle_groups')
      let g:billinux_neobundle_groups=['library', 'general', 'colorscheme', 'neocomplcache', 'programming', 'writing', 'html', 'php', 'javascript', 'python', 'ruby', 'json', 'cpp', 'go', 'scala', 'csv', 'yaml', 'markdown', 'testing', 'misc',]
  endif

      let s:enable_tern_for_vim = has('python') && executable('npm')
function! s:cache_bundles() "{{{

  NeoBundleFetch 'Shougo/neobundle.vim'

  " To override all the included bundles, add the following to your
  " .vimrc.bundles.local file:
  "   let g:override_billinux_neobundle = 1
  if ! exists("g:override_billinux_neobundle")

" Library"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'library')

      NeoBundle 'Shougo/vimproc.vim', {
        \ 'build' : {
        \     'windows' : 'tools\\update-dll-mingw',
        \     'cygwin'  : 'make -f make_cygwin.mak',
        \     'mac'     : 'make -f make_mac.mak',
        \     'linux'   : 'make',
        \     'unix'    : 'gmake',
        \   }
        \ }

      NeoBundle 'mattn/webapi-vim'
      NeoBundle 'MarcWeber/vim-addon-mw-utils'
      NeoBundle 'tomtom/tlib_vim'
      " apt-get install silversearcher-ag
      " OR git clone https://github.com/ggreer/the_silver_searcher ag && cd ag &&
      " ./build.sh && sudo make install

      NeoBundle 'rking/ag.vim'

    endif

  "}}}

" General"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'general')

      NeoBundle 'tomtom/tcomment_vim'
      NeoBundle 'tpope/vim-surround'
      NeoBundle 'tpope/vim-repeat'
      NeoBundle 'spf13/vim-autoclose'
      NeoBundleLazy 'kien/ctrlp.vim'
      NeoBundleLazy 'tacahiroy/ctrlp-funky'
      NeoBundle 'kristijanhusak/vim-multiple-cursors'
      NeoBundle 'tpope/vim-abolish.git'
      NeoBundle 'gcmt/wildfire.vim'
      NeoBundle 'kana/vim-smartinput'
      NeoBundle 'cohama/vim-smartinput-endwise'
      NeoBundle 'kana/vim-submode'
      NeoBundleLazy 'Lokaltog/powerline-fonts'

      NeoBundleLazy 'matchit.zip', { 'mappings': [[ 'nxo', '%', 'g%' ]]}

      if exists('g:billinux_use_airline')
        NeoBundle 'bling/vim-airline'
      else
        NeoBundle 'itchyny/lightline'
        "NeoBundle 'Lokaltog/powerline', {'rtp': 'powerline/bindings/vim/'}
      endif

      NeoBundleLazy 'nathanaelkane/vim-indent-guides'
      NeoBundleLazy 't9md/vim-quickhl' " quickly highlight <cword> or visually selected word

      NeoBundleLazy 'xolox/vim-session', {
        \ 'depends': 'xolox/vim-misc',
        \ 'augroup': 'PluginSession',
        \ 'autoload': {
        \ 'commands': [
        \   { 'name': [ 'OpenSession', 'CloseSession' ],
        \     'complete': 'customlist,xolox#session#complete_names' },
        \   { 'name': [ 'SaveSession' ],
        \     'complete': 'customlist,xolox#session#complete_names_with_suggestions' }
        \ ],
        \ 'functions': [ 'xolox#session#complete_names',
        \                'xolox#session#complete_names_with_suggestions' ],
        \ 'unite_sources': [ 'session', 'session/new' ]
        \ }}

      NeoBundleLazy 'farseer90718/vim-colorpicker', {
        \ 'disabled': ! has('python'),
        \ 'commands': 'ColorPicker'
        \ }

      NeoBundleLazy 'sjl/gundo.vim', {
        \ 'disabled': ! has('python'),
        \ 'autoload': { 'commands': [ 'GundoToggle' ] }
        \ }

  " Gui
  " ---

      NeoBundleLazy 'nathanaelkane/vim-indent-guides'

      NeoBundleLazy 'tyru/restart.vim', {
        \   'gui' : 1,
        \   'autoload' : {
        \     'commands' : 'Restart'
        \   }
        \ }

    endif

  "}}}

" Colorscheme"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'colorscheme')

      " Choose your colorscheme based on the time of day
      NeoBundleLazy 'daf-/vim-daylight'

      NeoBundle 'fatih/molokai'
      NeoBundleLazy 'flazz/vim-colorschemes'
      ""NeoBundleLazy 'altercation/vim-colors-solarized', {'gui' : 1}
      NeoBundle 'altercation/vim-colors-solarized'

      " 16-colors colorscheme
      NeoBundle 'chriskempson/base16-vim'

      " Xterm table colors
      NeoBundleLazy 'guns/xterm-color-table.vim', {
        \ 'autoload': {
        \   'commands': 'XtermColorTable'
        \ }
        \}

    endif

  "}}}

" Neocomplete, Neocomplcache, Youcompleteme"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'neocomplete')

      NeoBundle 'Shougo/neocomplete', {
        \ 'depends': 'Shougo/context_filetype.vim',
        \ 'disabled': ! has('lua'),
        \ 'insert': 1
        \ }

      NeoBundle 'rhysd/inu-snippets'

    elseif count(g:billinux_neobundle_groups, 'neocomplcache')

      NeoBundle 'Shougo/neocomplcache.vim'
      NeoBundle 'rhysd/inu-snippets'

    elseif count(g:billinux_neobundle_groups, 'youcompleteme')

      NeoBundle 'Valloric/YouCompleteMe'
      NeoBundle 'SirVer/ultisnips'
      NeoBundle 'honza/vim-snippets'

    elseif count(g:billinux_neobundle_groups, 'snipmate')

      NeoBundle 'garbas/vim-snipmate'
      NeoBundle 'honza/vim-snippets'

      " Source support_function.vim to support vim-snippets.
      call SourceIfExist(s:neobundle_dir.'/vim-snippets/snippets/support_functions.vim')

    endif

    if count(g:billinux_neobundle_groups, 'neocomplete') || count(g:billinux_neobundle_groups, 'neocomplcache')

      NeoBundleLazy 'Shougo/neosnippet.vim', {
        \ 'depends': 'Shougo/context_filetype.vim',
        \ 'insert': 1,
        \ 'filetypes': 'snippet',
        \ 'unite_sources': [
        \    'neosnippet', 'neosnippet/user', 'neosnippet/runtime'
        \ ]}

      NeoBundleLazy 'Shougo/neosnippet-snippets', {
        \ 'filetypes': 'snippet',
        \ }

    endif

  "}}}

" Programming"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'programming')

      NeoBundleLazy 'Shougo/vimshell', {
        \ 'autoload' : {
        \     'commands' : ['VimShell', 'VimShellSendString', 'VimShellCurrentDir', 'VimShellInteractive'],
        \     }
        \ }

      NeoBundleLazy 'Shougo/vimfiler.vim', {
        \ 'depends' : 'Shougo/unite.vim',
        \ 'autoload' : {
        \     'commands' : ['VimFiler', 'VimFilerCurrentDir',
        \                   'VimFilerBufferDir', 'VimFilerSplit',
        \                   'VimFilerExplorer', 'VimFilerDouble']
        \     }
        \ }

      NeoBundleLazy 'godlygeek/tabular'

      if executable('ctags')
        NeoBundleLazy 'majutsushi/tagbar'
      endif

      NeoBundleLazy 'koron/codic-vim', {
        \ 'autoload' : {
        \       'commands' : 'Codic',
        \   }
        \ }

    NeoBundleLazy 'rhysd/unite-codic.vim', {
        \ 'depends' : [
        \       'Shougo/unite.vim',
        \       'koron/codic-vim',
        \   ],
        \ 'autoload' : {
        \       'unite_sources' : 'codic',
        \   },
        \ }

      " Unite"{{{
      " -----

      NeoBundleLazy 'Shougo/unite-outline'
      NeoBundleLazy 'osyo-manga/unite-quickfix'
      NeoBundleLazy 'rhysd/quickrun-unite-quickfix-outputter'
      NeoBundleLazy 'Shougo/unite-help'
      NeoBundleLazy 'thinca/vim-unite-history'
      NeoBundleLazy 'ujihisa/unite-colorscheme'

      NeoBundleLazy 'Shougo/unite.vim', {
        \   'autoload' : {
        \     'commands' : [{'name': 'Unite', 'complete' : 'customlist,unite#complete_source'},
        \                   {'name': 'UniteWithBufferDir', 'complete' : 'customlist,unite#complete_source'},
        \                   {'name': 'UniteWithCursorWord', 'complete' : 'customlist,unite#complete_source'},
        \                   {'name': 'UniteWithWithInput', 'complete' : 'customlist,unite#complete_source'}]
        \   }
        \ }

      NeoBundleLazy 'sorah/unite-ghq', {
        \ 'autoload' : {
        \       'unite_sources' : 'ghq'
        \   }
        \ }

      NeoBundleLazy 'rhysd/unite-n3337', {
        \ 'autoload' : {'unite_sources' : 'n3337'}
        \ }
"}}}
    " Motion"{{{
    " ------

      NeoBundleLazy 'Lokaltog/vim-easymotion', {
        \ 'autoload' : {
        \       'mappings' : '<Plug>(easymotion-',
        \   }
        \ }

      NeoBundleLazy 'rhysd/clever-f.vim' " Extended f, F, t and T key mappings for Vim.
    "}}}
  " Git"{{{
    NeoBundleLazy 'tpope/vim-fugitive', {
      \ 'autoload' : {
      \       'commands' : ['Gstatus', 'Gcommit', 'Gwrite', 'Gdiff', 'Gblame', 'Git', 'Ggrep']
      \   }
      \ }

    NeoBundleLazy 'gregsexton/gitv', {
      \ 'depends': 'tpope/vim-fugitive',
      \ 'autoload': { 'commands': [ 'Gitv' ] }
      \ }

    NeoBundle 'mhinz/vim-signify'
    NeoBundleLazy 'thinca/vim-openbuf'

  "}}}
  " Browser"{{{
      NeoBundleLazy 'tyru/open-browser.vim', {
        \ 'autoload' : {
        \     'commands' : ['OpenBrowser', 'OpenBrowserSearch', 'OpenBrowserSmartSearch'],
        \     'mappings' : '<Plug>(openbrowser-',
        \   }
        \ }

      NeoBundleLazy 'tyru/open-browser-github.vim', {
        \ 'depends' : 'tyru/open-browser.vim',
        \ 'autoload' : {
        \       'commands' : ['OpenGithubFile', 'OpenGithubIssue', 'OpenGithubPullReq']
        \   }
        \ }
"}}}

    endif

  "}}}

" Html, Sass, Scss"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'html')

      NeoBundleLazy 'mattn/emmet-vim', {
        \ 'autoload': {
        \     'function_prefix': 'emmet',
        \     'filetypes': ['html', 'haml', 'xhtml', 'liquid', 'css', 'scss', 'sass'],
        \     'mappings' : ['i', '<Plug>(EmmetExpandAbbr)']
        \   }
        \ }

      NeoBundleLazy 'othree/html5.vim', {
        \ 'autoload' : {
        \     'filetypes' : ['html', 'xhtml'],
        \     'commands' : ['HtmlIndentGet']
        \   }
        \ }

      NeoBundleLazy 'othree/html5-syntax.vim', {
        \ 'autoload' : {
        \     'filetypes' : ['html', 'xhtml', 'jst', 'ejs'],
        \   }
        \ }

      NeoBundleLazy 'mustache/vim-mustache-handlebars', {
        \ 'autoload' : {
        \   'filetypes': ['html', 'mustache', 'hbs']
        \  }
        \ }

      NeoBundleLazy 'tpope/vim-haml', {
        \ 'autoload' : {
        \     'filetypes' : ['haml', 'sass', 'scss'],
        \   }
        \ }

      NeoBundleLazy 'digitaltoad/vim-jade', {
        \ 'autoload' : {
        \     'filetypes' : 'jade',
        \   }
        \ }

      NeoBundleLazy 'ap/vim-css-color', {
        \ 'autoload' : {
        \     'filetypes' :['sass', 'scss', 'less', 'css'],
        \   }
        \ }

      NeoBundleLazy 'hail2u/vim-css3-syntax', {
        \ 'autoload' : {
        \     'filetypes' :['sass', 'scss', 'less', 'css'],
        \   }
        \ }

      NeoBundleLazy 'wavded/vim-stylus', {
        \ 'autoload' : {
        \     'filetypes' :['sass', 'scss', 'css'],
        \   }
        \ }

      NeoBundleLazy 'groenewege/vim-less', {
          \ 'autoload' : {
          \   'filetypes' : 'less',
          \ }}

    endif

  "}}}

" Php"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'php')

      NeoBundleLazy 'StanAngeloff/php.vim', {
        \ 'autoload' : {
        \     'filetypes' : ['php'],
        \   }
        \ }

      NeoBundleLazy 'rayburgemeestre/phpfolding.vim', {
        \ 'autoload' : {
        \     'filetypes' : ['php'],
        \   }
        \ }

      NeoBundleLazy 'shawncplus/phpcomplete.vim', {
        \ 'autoload' : {
        \     'filetypes' : ['php'],
        \     'insert' : 1,
        \   }
        \ }

      NeoBundleLazy 'tobyS/pdv', {
      \ 'filetypes': 'php',
      \ 'depends': 'tobyS/vmustache'
      \ }

      NeoBundleLazy '2072/PHP-Indenting-for-VIm', {
      \ 'filetypes': 'php',
      \ 'directory': 'php-indent'
      \ }

      NeoBundleLazy 'arnaud-lb/vim-php-namespace', {
        \ 'autoload' : {
        \     'filetypes' : ['php'],
        \   }
        \ }

      NeoBundleLazy 'beyondwords/vim-twig', {
        \ 'autoload' : {
        \     'filetypes' : ['php'],
        \   }
        \ }

    endif

  "}}}

" Javascript"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'javascript')

      NeoBundleLazy 'pangloss/vim-javascript', {
        \ 'autoload': {
        \   'filetypes': 'javascript'
        \ }
        \}

      NeoBundleLazy 'jiangmiao/simple-javascript-indenter', {
        \ 'autoload' : {'filetypes' : 'javascript'}
        \ }

      NeoBundleLazy 'jelera/vim-javascript-syntax', {
        \ 'autoload' : {'filetypes' : 'javascript'}
        \ }

      " Require Nodejs and npm
      " # aptitude install nodejs
      " # curl https://www.npmjs.org/install.sh | sudo sh
      " node -v and npm -v
      if s:enable_tern_for_vim
        NeoBundleLazy 'marijnh/tern_for_vim', {
          \ 'build' : {
          \     'windows' : 'echo "Please build tern manually."',
          \     'cygwin'  : 'echo "Please build tern manually."',
          \     'mac'     : 'npm install',
          \     'unix'    : 'npm install',
          \   },
          \ 'disabled' : !executable('npm'),
          \ 'autoload' : {
          \     'functions' : ['tern#Complete', 'tern#Enable'],
          \     'filetypes' : 'javascript'
          \   },
          \ 'commands' : ['TernDef', 'TernDoc', 'TernType', 'TernRefs', 'TernRename']
          \ }

      else

        NeoBundleLazy 'mattn/jscomplete-vim', {
          \ 'autoload' : {'filetypes' : 'javascript'}
          \ }

      endif

    endif

  "}}}

" Python"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'python')

      NeoBundleLazy 'davidhalter/jedi-vim', {
        \ 'autoload' : {
        \     'filetypes' : 'python',
        \   }
        \ }

      NeoBundleLazy 'hynek/vim-python-pep8-indent', {
        \ 'autoload' : {
        \     'filetypes' : 'python',
        \   }
        \ }

    endif

  "}}}

" Ruby"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'ruby')

      NeoBundleLazy 'tpope/vim-rails', {
        \ 'autoload' : {'filetypes' : 'ruby'}
        \ }

      NeoBundleLazy 'basyura/unite-rails', {
        \ 'autoload' : {'filetypes' : 'ruby'}
        \ }

      NeoBundleLazy 'rhysd/vim-textobj-ruby', {
        \ 'autoload' : {'filetypes' : 'ruby'}
        \ }

      NeoBundleLazy 'rhysd/neco-ruby-keyword-args', {
        \ 'autoload' : {'filetypes' : 'ruby'}
        \ }

    endif

  "}}}

" Cpp"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'cpp')

      NeoBundleLazy 'vim-jp/cpp-vim', {
        \ 'autoload' : {'filetypes' : 'cpp'}
        \ }

      NeoBundleLazy 'Rip-Rip/clang_complete', {
        \ 'autoload' : {'filetypes' : ['c', 'cpp']}
        \ }

      NeoBundleLazy 'rhysd/vim-clang-format', {
        \ 'depends' : 'kana/vim-operator-user',
        \ 'autoload' : {'filetypes' : ['c', 'cpp', 'objc']}
        \ }

      NeoBundleLazy 'rhysd/clang-extent-selector.vim', {
        \ 'autoload' : {
        \       'filetypes' : ['c', 'cpp']
        \   }
        \ }

      NeoBundleLazy 'rhysd/clang-type-inspector.vim', {
        \ 'autoload' : {
        \       'filetypes' : ['c', 'cpp']
        \   }
        \ }

    endif

  "}}}

" Go"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'go')

      "NeoBundleLazy 'fatih/vim-go'
      NeoBundleLazy 'Blackrush/vim-gocode', {
        \ 'autoload' : {
        \       'filetypes' : ['go', 'markdown'],
        \       'commands' : 'Godoc',
        \   }
        \ }

      NeoBundleLazy 'rhysd/unite-go-import.vim', {
        \ 'autoload' : {
        \     'depends' : ['Shougo/unite.vim', 'Blackrush/vim-gocode'],
        \     'unite_sources' : 'go/import',
        \   }
        \ }

      NeoBundleLazy 'dgryski/vim-godef', {
        \ 'autoload' : {
        \     'filetypes' : 'go'
        \   }
        \ }

      NeoBundleLazy 'rhysd/vim-go-impl', {
        \ 'autoload' : {
        \     'filetypes' : 'go'
        \   }
        \ }

    endif

  "}}}

" Scala"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'scala')

      NeoBundleLazy 'derekwyatt/vim-scala', {
        \ 'autoload' : {
        \     'filetypes' : 'scala'
        \   }
        \ }

      NeoBundleLazy 'derekwyatt/vim-sbt', {
        \ 'autoload' : {
        \     'filetypes' : 'scala'
        \   }
        \ }

      NeoBundleLazy 'xptemplate', {
        \ 'autoload' : {
        \     'filetypes' : 'scala'
        \   }
        \ }
    endif

  "}}}

" Csv"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'csv')

      NeoBundleLazy 'chrisbra/csv.vim', {
        \ 'autoload' : {
        \     'filetypes' : 'csv'
        \   }
        \ }

    endif

  "}}}

" Yaml"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'yaml')

      NeoBundleLazy 'chase/vim-ansible-yaml', {
        \ 'autoload' : {
        \     'filetypes' : 'yaml'
        \   }
        \ }

    endif

  "}}}

" Markdown"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'markdown')

      NeoBundleLazy 'plasticboy/vim-markdown', {
        \ 'autoload' : {
        \     'filetypes' : ['markdown'],
        \   }
        \ }

      NeoBundleLazy 'kannokanno/previm', {
        \ 'depends' : 'tyru/open-browser.vim',
        \ 'autoload' : {
        \     'commands' : 'PrevimOpen',
        \     'filetypes' : 'markdown'
        \   }
        \ }

    endif

  "}}}

" Json"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'json')

      NeoBundleLazy 'elzr/vim-json', {
        \ 'autoload' : {'filetypes' : ['json', 'markdown']}
        \ }

    endif

  "}}}

" Writing"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'writing')

      NeoBundleLazy 'kana/vim-textobj-indent', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'ai'], ['xo', 'aI'], ['xo', 'ii'], ['xo', 'iI']]
        \   }
        \ }

      NeoBundleLazy 'kana/vim-textobj-line', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'al'], ['xo', 'il']]
        \   }
        \ }

      NeoBundleLazy 'rhysd/vim-textobj-wiw', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'am'], ['xo', 'im']]
        \   }
        \ }

      NeoBundleLazy 'sgur/vim-textobj-parameter', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'a,'], ['xo', 'i,']]
        \   }
        \ }

      NeoBundleLazy 'thinca/vim-textobj-between', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'af'], ['xo', 'if'], ['xo', '<Plug>(textobj-between-']]
        \   }
        \ }

      NeoBundleLazy 'thinca/vim-textobj-comment', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'ac'], ['xo', 'ic']]
        \   }
        \ }

      NeoBundleLazy 'rhysd/vim-textobj-word-column', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'av'], ['xo', 'aV'], ['xo', 'iv'], ['xo', 'iV']]
        \   }
        \ }

      NeoBundleLazy 'kana/vim-textobj-entire', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'ae'], ['xo', 'ie']]
        \   }
        \ }

      NeoBundleLazy 'kana/vim-textobj-fold', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'az'], ['xo', 'iz']]
        \ }
        \ }

      NeoBundleLazy 'rhysd/vim-textobj-anyblock', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'ab'], ['xo', 'ib']]
        \   }
        \ }

      NeoBundleLazy 'rhysd/vim-textobj-clang', {
        \ 'depends' : 'kana/vim-textobj-user',
        \ 'autoload' : {
        \       'mappings' : [['xo', 'a;'], ['xo', 'i;']]
        \   }
        \ }

    endif

  "}}}

" Testing"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'testing')

      command! -nargs=1 NeoBundleMyPlugin
        \ NeoBundle <args>, {
        \   'base' : '~/Dev/github.com/billinux',
        \   'type' : 'nosync',
        \ }

    "  NeoBundleMyPlugin 'libclang-vim'


    " Vim-scripts
      " NeoBundle 'Align'

    " A bundle in a git repo
      " NeoBundle 'git://git.wincent.com/command-t.git'

    endif

  "}}}

" Misc"{{{
" -------------------------------------------------------------------

    if count(g:billinux_neobundle_groups, 'misc')

      NeoBundleLazy 'thinca/vim-quickrun'


      " Tmux
      NeoBundleLazy 'zaiste/tmux.vim', {
        \ 'autoload' : {'filetypes' : 'tmux'}
        \ }

      NeoBundleLazy 'rbtnn/puyo.vim', {
        \ 'autoload' : {
        \       'commands' : 'Puyo'
        \   }
        \ }

      NeoBundleLazy 'thinca/vim-threes', {
        \ 'autoload' : {
        \       'commands' : 'ThreesStart'
        \   }
        \ }

      NeoBundleLazy 'itchyny/calendar.vim', {
        \ 'autoload' : {
        \       'commands' : {'name' : 'Calendar', 'complete' : 'customlist,calendar#argument#complete'},
        \   }
        \ }

      NeoBundleLazy 'rhysd/wandbox-vim', {
        \ 'autoload' : {
        \       'commands' : [{'name' : 'Wandbox', 'complete' : 'customlist,wandbox#complete_command'}, 'WandboxOptionList']
        \   }
        \ }

      NeoBundleLazy 'rhysd/open-pdf.vim', {
        \ 'autoload' : {
        \     'commands' : ['Pdf', 'PdfRead', 'PdfEdit', 'PdfCacheClean', 'PdfCacheReload'],
        \      'unite_sources' : ['pdf/history', 'pdf/search'],
        \   }
        \ }

      NeoBundleLazy 'cohama/agit.vim', {
        \   'autoload' : {
        \     'commands' : 'Agit'
        \   }
        \ }

      NeoBundleLazy 'vim-scripts/ZoomWin', {
        \ 'autoload' : {
        \     'commands' : 'ZoomWin'
        \     }
        \ }

      NeoBundleLazy 'glidenote/memolist.vim', {
        \ 'depends' : 'Shougo/vimfiler.vim',
        \ 'autoload' : {
        \     'commands' : ['MemoNew', 'MemoList', 'MemoGrep']
        \   }
        \ }

      NeoBundleLazy 'kana/vim-altr'

      NeoBundle 'rhysd/vim-numberstar'

" TweetVim"{{{
" -------------------------------------------------------------------

      NeoBundleLazy 'basyura/twibill.vim'
      NeoBundleLazy 'yomi322/neco-tweetvim'
      NeoBundleLazy 'rhysd/tweetvim-advanced-filter'
      NeoBundleLazy 'basyura/TweetVim', 'dev', {
        \ 'depends' :
        \     ['basyura/twibill.vim',
        \      'tyru/open-browser.vim',
        \      'yomi322/neco-tweetvim',
        \      'rhysd/tweetvim-advanced-filter'],
        \ 'autoload' : {
        \     'commands' :
        \         ['TweetVimHomeTimeline',
        \          'TweetVimMentions',
        \          'TweetVimSay',
        \          'TweetVimUserTimeline',
        \          'TweetVimUserStream']
        \     }
        \ }
    "}}}
      NeoBundleLazy 'sudo.vim'

    endif

  "}}}

  endif

""  NeoBundleCheck
""  NeoBundleSaveCache

endfunction "}}}

"}}}
" ReadOnly, use sudo.vim"{{{
Autocmd FileChangedRO * NeoBundleSource sudo.vim
Autocmd FileChangedRO * execute "command! W SudoWrite" expand('%')
"}}}
" Neobundleloadcache"{{{
if neobundle#has_cache()
  NeoBundleLoadCache
else
  call s:cache_bundles()
  NeoBundleSaveCache
endif
"}}}

call neobundle#end()

filetype plugin indent on     " required!
syntax enable

" Plugin installation check
NeoBundleCheck"


" Neobundleclearcache"{{{
Autocmd BufWritePost .vimrc,.gvimrc,*vimrc,*gvimrc NeoBundleClearCache
"}}}
" NeoBundle search bundle name"{{{
function! s:browse_neobundle_home(bundle_name)
    if match(a:bundle_name, '/') == -1
        let url = 'http://www.google.gp/search?q='.a:bundle_name
    else
        let url = 'https://github.com/'.a:bundle_name
    endif
    execute 'OpenBrowser' url
endfunction
command! -nargs=1 BrowseNeoBundleHome call <SID>browse_neobundle_home(<q-args>)
"}}}
" Neobundle maps"{{{
nnoremap <silent><Leader>nbu :<C-u>NeoBundleUpdate<CR>
nnoremap <silent><Leader>nbc :<C-u>NeoBundleClean<CR>
nnoremap <silent><Leader>nbi :<C-u>NeoBundleInstall<CR>
nnoremap <silent><Leader>nbl :<C-u>Unite output<CR>NeoBundleList<CR>
nnoremap <silent><Leader>nbd :<C-u>NeoBundleDocs<CR>
nnoremap <silent><Leader>nbh :<C-u>execute 'BrowseNeoBundleHome' matchstr(getline('.'), '\%[Neo]Bundle\%[Lazy]\s\+[''"]\zs.\+\ze[''"]')<CR>
"}}}

"}}}

" UI:"{{{
" Common settings
" ---------------
set t_Co=256

if &t_Co < 256
  exec 'colorscheme '.g:colorscheme_default
elseif strftime("%H") >=  5 && strftime("%H") <=  17
set background=light
try
  exec 'colorscheme '.g:colorscheme_morning
catch
  exec 'colorscheme '.g:colorscheme_default
endtry
else
set background=dark
try
  exec 'colorscheme '.g:colorscheme_evening
catch
  exec 'colorscheme '.g:colorscheme_default
endtry
endif

" Environment
" -----------
if s:is_mac
"  set guifont=Source\ Code\ Pro\ for\ Powerline:12
  set guifont=Meslo\ LG\ S\ Regular\ for\ Powerline:h12
"  set guifont=Menlo\ Regular\ for\ Powerline:h13

"  set transparency=10
"  set fuoptions=maxvert,maxhorz

elseif s:is_unix
  set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h11
elseif s:is_windows
  set guifont=Source\ Code\ Pro\ for\ Powerline:12
  set guifont=Bistream\ Vera\ Sans\ Mono\ for\ Powerline:h12
  set guifont=DejaVu\ Sans\ Mono\ for\ Powerline:h11,
  autocmd GUIEnter * simalt ~x
endif

" Gui
" ---
if s:is_gui

  set guioptions-=T

  if exists('s:settings.enable_gui_fullscreen')
    " open maximized
    set lines=999 columns=9999
  else
    set lines=30 columns=120
  endif

  if s:is_gui_macvim

    " Swipe to move between bufers :D
    map <silent> <SwipeLeft> :bprev<CR>
    map <silent> <SwipeRight> :bnext<CR>

    " Cmd+Shift+N = new buffer
    map <silent> <D-N> :enew<CR>

    " Cmd+t = new tab
    nnoremap <silent> <D-t> :tabnew<CR>

    " Cmd+w = close tab (this should happen by default)
    nnoremap <silent> <D-w> :tabclose<CR>

    " Cmd+1...9 = go to that tab
    map <silent> <D-1> 1gt
    map <silent> <D-2> 2gt
    map <silent> <D-3> 3gt
    map <silent> <D-4> 4gt
    map <silent> <D-5> 5gt
    map <silent> <D-6> 6gt
    map <silent> <D-7> 7gt
    map <silent> <D-8> 8gt
    map <silent> <D-9> 9gt

    " OS X probably has ctags in a weird place
    let g:tagbar_ctags_bin='/usr/local/bin/ctags'

  elseif s:is_gui_linux 

    " Alt+n = new buffer
    map <silent> <A-n> :enew<CR>

    " Alt+t = new tab
    nnoremap <silent> <A-t> :tabnew<CR>

    " Alt+w = close tab
    nnoremap <silent> <A-w> :tabclose<CR>

    " Alt+1...9 = go to that tab
    map <silent> <A-1> 1gt
    map <silent> <A-2> 2gt
    map <silent> <A-3> 3gt
    map <silent> <A-4> 4gt
    map <silent> <A-5> 5gt
    map <silent> <A-6> 6gt
    map <silent> <A-7> 7gt
    map <silent> <A-8> 8gt
    map <silent> <A-9> 9gt
  endif

else

" Terminal
" --------
  " Gnome
  " You have to modify font in Edit, Preferences and choose a powerline font
  if $COLORTERM == 'gnome-terminal'
    set t_Co=256 "why you no tell me correct colors?!?!
  endif

  " Dterm
  if s:is_term_dterm
    set tsl=0
  endif

  " Urxvt
  if s:is_term_rxvt
    let &t_SI = "\033]12;red\007"
    let &t_EI = "\033]12;green\007"
  endif

  " Screen
  if s:is_term_screen
    let &t_SI = "\033P\033]12;red\007\033\\"
    let &t_EI = "\033P\033]12;green\007\033\\"
  endif

  " iTerm
  if $TERM_PROGRAM == 'iTerm.app'
    " different cursors for insert vs normal mode
    if exists('$TMUX')
      set t_Co=256


      set ttymouse=sgr
      " execute 'silent !echo -e "\033kvim\033\\"'

      execute "set <xUp>=\e[1;*A"
      execute "set <xDown>=\e[1;*B"
      execute "set <xRight>=\e[1;*C"
      execute "set <xLeft>=\e[1;*D"

      execute "set <xHome>=\e[1;*H"
      execute "set <xEnd>=\e[1;*F"

      execute "set <Insert>=\e[2;*~"
      execute "set <Delete>=\e[3;*~"
      execute "set <PageUp>=\e[5;*~"
      execute "set <PageDown>=\e[6;*~"

      execute "set <xF1>=\e[1;*P"
      execute "set <xF2>=\e[1;*Q"
      execute "set <xF3>=\e[1;*R"
      execute "set <xF4>=\e[1;*S"

      execute "set <F5>=\e[15;*~"
      execute "set <F6>=\e[17;*~"
      execute "set <F7>=\e[18;*~"
      execute "set <F8>=\e[19;*~"
      execute "set <F9>=\e[20;*~"
      execute "set <F10>=\e[21;*~"
      execute "set <F11>=\e[23;*~"
      execute "set <F12>=\e[24;*~"

      execute "set t_kP=^[[5;*~"
      execute "set t_kN=^[[6;*~"

      let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=1\x7\<Esc>\\"
      let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=0\x7\<Esc>\\"
    else
      let &t_SI = "\<Esc>]50;CursorShape=1\x7"
      let &t_EI = "\<Esc>]50;CursorShape=0\x7"
    endif
  endif
endif
"}}}

" MAPPINGS"{{{
" Edit and source .vimrc"{{{
nmap <silent> <leader>ev :vsplit $MYVIMRC<CR>
nmap <silent> <leader>sv :source $MYVIMRC<CR>
"}}}
" Arrow keys"{{{
" Keep hands on the keyboard"{{{
inoremap jj <ESC>
inoremap kk <ESC>
inoremap jk <ESC>
inoremap kj <ESC>
"}}}
" Remap arrow keys"{{{
nnoremap <down> :bprev<CR>
nnoremap <up> :bnext<CR>
nnoremap <left> :tabnext<CR>
nnoremap <right> :tabprev<CR>
"}}}
""}}}
" Save and exit"{{{
" Fast saving"{{{
nnoremap <Leader>w :w<CR>
vnoremap <Leader>w <Esc>:w<CR>
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>
vnoremap <C-s> <Esc>:w<CR>

nnoremap <Leader>x :x<CR>
vnoremap <Leader>x <Esc>:x<C>
"}}}
" Fast exit"{{{
"nnoremap q :q!<cr>
nnoremap <leader>q :qa!<cr>
"}}}
"}}}
" Normal mode pressing * or # searches for the current selection"{{{
nnoremap <silent> n nzz
nnoremap <silent> N Nzz
nnoremap <silent> * *zz
nnoremap <silent> # #zz
nnoremap <silent> g* g*zz
nnoremap <silent> g# g#zz
nnoremap <silent> <C-o> <C-o>zz
nnoremap <silent> <C-i> <C-i>zz
"}}}
" Visual mode pressing * or # searches for the current selection"{{{
" Super useful! From an idea by Michael Naumann
vnoremap <silent> * :call VisualSelection('f')<CR>
vnoremap <silent> # :call VisualSelection('b')<CR>
"}}}
" Make Y consistent with C and D. See :help Y."{{{
nnoremap Y y$
"}}}
  " command-line window {{{
    nnoremap q: q:i
    nnoremap q/ q/i
    nnoremap q? q?i
  " }}}
" Vim dispatch"{{{
if neobundle#is_sourced('vim-dispatch')
  nnoremap <leader>tag :Dispatch ctags -R<cr>
endif
"}}}
" Move around windows "{{{
nnoremap <C-w>* <C-w>s*
nnoremap <C-w># <C-w>s#
nnoremap <silent><C-w>h :<C-u>call <SID>jump_window_wrapper('h', 'l')<CR>
nnoremap <silent><C-w>j :<C-u>call <SID>jump_window_wrapper('j', 'k')<CR>
nnoremap <silent><C-w>k :<C-u>call <SID>jump_window_wrapper('k', 'j')<CR>
nnoremap <silent><C-w>l :<C-u>call <SID>jump_window_wrapper('l', 'h')<CR>
"}}}
function! s:jump_window_wrapper(cmd, fallback) "{{{
  let old = winnr()
  execute 'normal!' "\<C-w>" . a:cmd

  if old == winnr()
    execute 'normal!' "999\<C-w>" . a:fallback
  endif
endfunction "}}}
" Visual selection of various text objects"{{{
nnoremap VV V
nnoremap Vit vitVkoj
nnoremap Vat vatV
nnoremap Vab vabV
nnoremap VaB vaBV
"}}}
"}}}

" COMMANDS {{{
command! -bang Q q<bang>
command! -bang QA qa<bang>
command! -bang Qa qa<bang>

command! Wrap :set tw=50 | :normal gggqG

command! Date :call setline('.', getline('.') . strftime('%Y/%m/%d (%a) %H:%M'))

command! -nargs=0 CalendarApp call <SID>open_calendar_app()
function! s:open_calendar_app() "{{{
  if s:is_mac
    call system('open -a Calendar.app')
  else
    OpenBrowser https://www.google.com/calendar/render
  endif
endfunction "}}}

command! -bang -nargs=1 SetIndent
  \ execute <bang>0 ? 'set' : 'setlocal'
  \         'tabstop='.<q-args>
  \         'shiftwidth='.<q-args>
  \         'softtabstop='.<q-args>

command! -nargs=? -complete=command SmartSplit call <SID>smart_split(<q-args>)
nnoremap <C-w><Space> :<C-u>SmartSplit<CR>
function! s:smart_split(cmd) "{{{
  if winwidth(0) > winheight(0) * 2
    vsplit
    if exists(':AdjustWindowWidth')
      AdjustWindowWidth
    endif
  else
    split
  endif

  if !empty(a:cmd)
    execute a:cmd
  endif
endfunction "}}}

command! -nargs=* -complete=help SmartHelp call <SID>smart_help(<q-args>)
nnoremap <silent><Leader>h :<C-u>SmartHelp<Space><C-l>
function! s:smart_help(args) "{{{
  try
    if winwidth(0) > winheight(0) * 2
      execute 'vertical topleft help ' . a:args
    else
      execute 'aboveleft help ' . a:args
    endif
  catch /^Vim\%((\a\+)\)\=:E149/
    echohl ErrorMsg
    echomsg "E149: Sorry, no help for " . a:args
    echohl None
  endtry
  if &buftype ==# 'help'
    if winwidth(0) < 80
      execute 'quit'
      execute 'tab help ' . a:args
    endif
    silent! AdjustWindowWidth --direction=shrink
  endif
endfunction "}}}

command! -nargs=0 Wc %s/.//nge

" Vimrc
command! Vimrc call s:edit_myvimrc()
function! s:edit_myvimrc() "{{{
  let ghq_root = expand(substitute(system('git config ghq.root'), '\n$', '', ''))
  if isdirectory(ghq_root . '/github.com/'.$USER.'/dotfiles')
    let vimrc = ghq_root . '/github.com/'.$USER.'/dotfiles/vimrc*'
    let gvimrc = ghq_root . '/github.com/'.$USER.'/dotfiles/gvimrc*'
  elseif isdirectory($HOME.'Github/dotfiles')
    let vimrc = expand('~/Github/dotfiles/vimrc*')
    let gvimrc = expand('~/Github/dotfiles/gvimrc*')
  else
    let vimrc = $MYVIMRC
    let gvimrc = $MYGVIMRC
  endif

  let files = ""
  if !empty($MYVIMRC)
    let files .= substitute(expand(vimrc), '\n', ' ', 'g')
  endif
  if !empty($MYGVIMRC)
    let files .= substitute(expand(gvimrc), '\n', ' ', 'g')
  endif

  execute "args " . files
endfunction "}}}

" Copy current path
command! CopyCurrentPath :call s:copy_current_path()
function! s:copy_current_path() "{{{
    if has('win32') || has('win64')
        let c = substitute(expand('%:p'), '\\/', '\\', 'g')
    elseif has('unix')
        let c = expand('%:p')
    endif

    if &clipboard ==# 'plus$'
        let @+ = c
    else
        let @* = c
    endif
endfunction "}}}

" Edit file in UTF-8
command! -bang -complete=file -nargs=? Utf8 edit<bang> ++enc=utf-8 <args>

"}}}

" AUTOCOMMANDS"{{{

" http://d.hatena.ne.jp/thinca/20090530/1243615055
Autocmd CursorMoved,CursorMovedI,WinLeave * setlocal nocursorline
Autocmd CursorHold,CursorHoldI,WinEnter * setlocal cursorline

" *.md filetype
Autocmd BufRead,BufNew,BufNewFile *.md,*.markdown,*.mkd setlocal ft=markdown
" http://mattn.kaoriya.net/software/vim/20140523124903.htm
let g:markdown_fenced_languages = [
      \  'coffee',
      \  'css',
      \  'erb=eruby',
      \  'javascript',
      \  'js=javascript',
      \  'json=javascript',
      \  'ruby',
      \  'sass',
      \  'xml',
      \  'vim',
      \]
" tmux
Autocmd BufRead,BufNew,BufNewFile *tmux.conf setlocal ft=tmux
" git config file
Autocmd BufRead,BufNew,BufNewFile gitconfig setlocal ft=gitconfig
" Gnuplot
Autocmd BufRead,BufNew,BufNewFile *.plt,*.plot,*.gnuplot setlocal ft=gnuplot
" Ruby
Autocmd BufRead,BufNew,BufNewFile Guardfile setlocal ft=ruby
" JSON
Autocmd BufRead,BufNew,BufNewFile *.json,*.jsonp setlocal ft=json
" jade
Autocmd BufRead,BufNew,BufNewFile *.jade setlocal ft=jade
" Go
Autocmd BufRead,BufNew,BufNewFile *.go setlocal ft=go
" vimspec
Autocmd BufRead,BufNew,BufNewFile *.vimspec setlocal ft=vim.vimspec

"------  PHP Filetype Settings  ------
" ,p = Runs PHP lint checker on current file
map <Leader>p :! php -l %<CR>

" ,P = Runs PHP and executes the current file
map <Leader>P :! php -q %<CR>

au FileType php set omnifunc=phpcomplete#CompletePHP
"

autocmd FileType php
    \ nnoremap <silent><buffer> <Leader>k :call pdv#DocumentCurrentLine()<CR>
"
Autocmd BufReadPost *
    \ if line("'\"") > 1 && line("'\"") <= line("$") |
    \   exe "normal! g`\"" |
    \ endif

" Hack #202:
" http://vim-users.jp/2011/02/hack202/
Autocmd BufWritePre * call s:auto_mkdir(expand('<afile>:p:h'), v:cmdbang)
function! s:auto_mkdir(dir, force)
    if !isdirectory(a:dir) && (a:force ||
                \    input(printf('"%s" does not exist. Create? [y/N]', a:dir)) =~? '^y\%[es]$')
        " call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
        call mkdir(a:dir, 'p')
    endif
endfunction
"
Autocmd BufWritePost
    \ * if &l:filetype ==# '' || exists('b:ftdetect')
    \ |   unlet! b:ftdetect
    \ |   filetype detect
    \ | endif

" git commit message
AutocmdFT gitcommit setlocal nofoldenable spell
AutocmdFT diff setlocal nofoldenable

" Higlight filetype {{{
let s:zenkaku_no_highlight_filetypes = []
"
Autocmd ColorScheme * highlight link ZenkakuSpace Error
Autocmd VimEnter,WinEnter * if index(s:zenkaku_no_highlight_filetypes, &filetype) == -1 | syntax match ZenkakuSpace containedin=ALL /　/ | endif
" }}}

"}}}

" PLUGINS:"{{{

" Library:"{{{

" Vimproc.vim {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vimproc.vim'))


endif

" }}}
" Webapi-vim {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/webapi-vim'))

endif

" }}}
" Vim-addon-mw-utils {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-addon-mw-utils'))

endif

" }}}
" Tlib_vim {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/tlib_vim'))

endif

" }}}
" Ag.vim {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/ag.vim'))

endif

" }}}

"}}}

" General:"{{{

" NerdTree "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/nerdtree'))

  let g:NERDTreeChDirMode=2
  let g:NERDChristmasTree=1

  nmap <leader>t :NeoBundleSource nerdtree<CR>:NERDTreeToggle<CR>

  " Exit vim if NERDTree is the last window open
  au bufenter * if (winnr("$")== 1 && exists("b:NERDTreeType") && b:NERDTreeType ==  "primary") | q | endif"

endif

" }}}
" Vim-surround "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-surround'))

endif

" }}}
" Vim-repeat "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-repeat'))

endif

" }}}
" Vim-autoclose "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-autoclose'))

endif

" }}}
" Ctrlp.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/ctrlp.vim'))

  let g:ctrlp_working_path_mode = 'ra'
  nnoremap <silent> <D-t> :CtrlP<CR>
  nnoremap <silent> <D-r> :CtrlPMRU<CR>
  let g:ctrlp_custom_ignore = {
      \ 'dir':  '\.git$\|\.hg$\|\.svn$',
      \ 'file': '\.exe$\|\.so$\|\.dll$\|\.pyc$' }

  " On Windows use "dir" as fallback command.
  if IsWindows()
    let s:ctrlp_fallback = 'dir %s /-n /b /s /a-d'
  elseif executable('ag')
    let s:ctrlp_fallback = 'ag %s --nocolor -l -g ""'
  elseif executable('ack-grep')
    let s:ctrlp_fallback = 'ack-grep %s --nocolor -f'
  elseif executable('ack')
    let s:ctrlp_fallback = 'ack %s --nocolor -f'
  else
    let s:ctrlp_fallback = 'find %s -type f'
  endif

  let g:ctrlp_user_command = {
      \ 'types': {
          \ 1: ['.git', 'cd %s && git ls-files . --cached --exclude-standard --others'],
          \ 2: ['.hg', 'hg --cwd %s locate -I .'],
      \ },
      \ 'fallback': s:ctrlp_fallback
  \ }

  " Ctrlp-funky "{{{
  " ----------------------------------------------
  if isdirectory(expand(s:neobundle_dir.'/ctrlp-funky'))
    " CtrlP extensions
    let g:ctrlp_extensions = ['funky']

    "funky
    nnoremap <Leader>fu :CtrlPFunky<Cr>
  endif

" }}}

endif

" }}}
" Vim-multiple-cursors "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-multiple-cursors'))

endif

" }}}
" Vim-session "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-session'))
endif
  let g:session_directory = s:cache_dir.'/session'
  let g:session_default_overwrite = 1
  let g:session_autosave = 'no'
  let g:session_autoload = 'no'
  let g:session_persist_colors = 0
  let g:session_menu = 0
set sessionoptions=blank,buffers,curdir,folds,tabpages,winsize

" }}}
" Vim-abolish "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-abolish'))

endif

" }}}
" Wildfire "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/wildfire'))

endif

" }}}
" vim-smartinput"{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-smartinput'))

  "
  call smartinput#map_to_trigger('i', '<Space>', '<Space>', '<Space>')
  call smartinput#define_rule({
              \   'at'    : '(\%#)',
              \   'char'  : '<Space>',
              \   'input' : '<Space><Space><Left>',
              \   })

  call smartinput#map_to_trigger('i', '<BS>', '<BS>', '<BS>')
  call smartinput#define_rule({
              \   'at'    : '( \%# )',
              \   'char'  : '<BS>',
              \   'input' : '<Del><BS>',
              \   })

  call smartinput#define_rule({
              \   'at'    : '{\%#}',
              \   'char'  : '<Space>',
              \   'input' : '<Space><Space><Left>',
              \   })

  call smartinput#define_rule({
              \   'at'    : '{ \%# }',
              \   'char'  : '<BS>',
              \   'input' : '<Del><BS>',
              \   })

  call smartinput#define_rule({
              \   'at'    : '\[\%#\]',
              \   'char'  : '<Space>',
              \   'input' : '<Space><Space><Left>',
              \   })

  call smartinput#define_rule({
              \   'at'    : '\[ \%# \]',
              \   'char'  : '<BS>',
              \   'input' : '<Del><BS>',
              \   })

  call smartinput#map_to_trigger('i', '<Plug>(physical_key_return)', '<CR>', '<CR>')
  "
  call smartinput#define_rule({
              \   'at'    : '\s\+\%#',
              \   'char'  : '<CR>',
              \   'input' : "<C-o>:call setline('.', substitute(getline('.'), '\\s\\+$', '', '')) <Bar> echo 'delete trailing spaces'<CR><CR>",
              \   })

  " Ruby
  call smartinput#map_to_trigger('i', '#', '#', '#')
  call smartinput#define_rule({
              \   'at'       : '\%#',
              \   'char'     : '#',
              \   'input'    : '#{}<Left>',
              \   'filetype' : ['ruby'],
              \   'syntax'   : ['Constant', 'Special'],
              \   })

  " Ruby
  call smartinput#map_to_trigger('i', '<Bar>', '<Bar>', '<Bar>')
  call smartinput#define_rule({
              \   'at' : '\%({\|\<do\>\)\s*\%#',
              \   'char' : '|',
              \   'input' : '||<Left>',
              \   'filetype' : ['ruby', 'dachs'],
              \    })

  "
  call smartinput#define_rule({
              \   'at' :       '<\%#>',
              \   'char' :     '<Space>',
              \   'input' :    '<Space><Space><Left>',
              \   'filetype' : ['cpp'],
              \   })
  call smartinput#define_rule({
              \   'at' :       '< \%# >',
              \   'char' :     '<BS>',
              \   'input' :    '<Del><BS>',
              \   'filetype' : ['cpp'],
              \   })

  "
  call smartinput#map_to_trigger('i', '*', '*', '*')
  call smartinput#define_rule({
              \   'at'       : '\/\%#',
              \   'char'     : '*',
              \   'input'    : '**/<Left><Left>',
              \   'filetype' : ['c', 'cpp'],
              \   })
  call smartinput#define_rule({
              \   'at'       : '/\*\%#\*/',
              \   'char'     : '<Space>',
              \   'input'    : '<Space><Space><Left>',
              \   'filetype' : ['c', 'cpp'],
              \   })
  call smartinput#define_rule({
              \   'at'       : '/* \%# */',
              \   'char'     : '<BS>',
              \   'input'    : '<Del><BS>',
              \   'filetype' : ['c', 'cpp'],
              \   })

  "
  call smartinput#map_to_trigger('i', ';', ';', ';')
  " 2
  call smartinput#define_rule({
              \   'at'       : ';\%#',
              \   'char'     : ';',
              \   'input'    : '<BS>::',
              \   'filetype' : ['cpp'],
              \   })
  " boost::
  call smartinput#define_rule({
              \   'at'       : '\<b;\%#',
              \   'char'     : ';',
              \   'input'    : '<BS>oost::',
              \   'filetype' : ['cpp'],
              \   })
  " std::
  call smartinput#define_rule({
              \   'at'       : '\<s;\%#',
              \   'char'     : ';',
              \   'input'    : '<BS>td::',
              \   'filetype' : ['cpp'],
              \   })
  " detail::
  call smartinput#define_rule({
              \   'at'       : '\%(\s\|::\)d;\%#',
              \   'char'     : ';',
              \   'input'    : '<BS>etail::',
              \   'filetype' : ['cpp'],
              \   })
  " enum
  call smartinput#define_rule({
              \   'at'       : '\%(\<struct\>\|\<class\>\|\<enum\>\)\s*\w\+.*\%#',
              \   'char'     : '{',
              \   'input'    : '{};<Left><Left>',
              \   'filetype' : ['cpp'],
              \   })
  " template
  call smartinput#define_rule({
              \   'at'       : '\<template\>\s*\%#',
              \   'char'     : '<',
              \   'input'    : '<><Left>',
              \   'filetype' : ['cpp'],
              \   })

  " Vim
  call smartinput#define_rule({
              \   'at'       : '\\\%(\|%\|z\)\%#',
              \   'char'     : '(',
              \   'input'    : '(\)<Left><Left>',
              \   'filetype' : ['vim'],
              \   'syntax'   : ['String'],
              \   })
  call smartinput#define_rule({
              \   'at'       : '\\[%z](\%#\\)',
              \   'char'     : '<BS>',
              \   'input'    : '<Del><Del><BS><BS><BS>',
              \   'filetype' : ['vim'],
              \   'syntax'   : ['String'],
              \   })
  call smartinput#define_rule({
              \   'at'       : '\\(\%#\\)',
              \   'char'     : '<BS>',
              \   'input'    : '<Del><Del><BS><BS>',
              \   'filetype' : ['vim'],
              \   'syntax'   : ['String'],
              \   })

  " my-endwise
  call smartinput#define_rule({
              \   'at'    : '\%#',
              \   'char'  : '<CR>',
              \   'input' : "<CR><C-r>=endwize#crend()<CR>",
              \   'filetype' : ['vim', 'ruby', 'sh', 'zsh', 'dachs'],
              \   })
  call smartinput#define_rule({
              \   'at'    : '\s\+\%#',
              \   'char'  : '<CR>',
              \   'input' : "<C-o>:call setline('.', substitute(getline('.'), '\\s\\+$', '', ''))<CR><CR><C-r>=endwize#crend()<CR>",
              \   'filetype' : ['vim', 'ruby', 'sh', 'zsh', 'dachs'],
              \   })
  call smartinput#define_rule({
              \   'at'    : '^#if\%(\|def\|ndef\)\s\+.*\%#',
              \   'char'  : '<CR>',
              \   'input' : "<C-o>:call setline('.', substitute(getline('.'), '\\s\\+$', '', ''))<CR><CR><C-r>=endwize#crend()<CR>",
              \   'filetype' : ['c', 'cpp'],
              \   })

  " \s=
  call smartinput#map_to_trigger('i', '=', '=', '=')
  call smartinput#define_rule(
      \ { 'at'    : '\s\%#'
      \ , 'char'  : '='
      \ , 'input' : '= '
      \ , 'filetype' : ['c', 'cpp', 'vim', 'ruby']
      \ })

  "
  call smartinput#define_rule(
      \ { 'at'    : '=\s\%#'
      \ , 'char'  : '='
      \ , 'input' : '<BS>= '
      \ , 'filetype' : ['c', 'cpp', 'vim', 'ruby']
      \ })

  "
  call smartinput#map_to_trigger('i', '~', '~', '~')
  call smartinput#define_rule(
      \ { 'at'    : '=\s\%#'
      \ , 'char'  : '~'
      \ , 'input' : '<BS>~ '
      \ , 'filetype' : ['c', 'cpp', 'vim', 'ruby']
      \ })

  " Vim
  call smartinput#map_to_trigger('i', '#', '#', '#')
  call smartinput#define_rule(
      \ { 'at'    : '=[~=]\s\%#'
      \ , 'char'  : '#'
      \ , 'input' : '<BS># '
      \ , 'filetype' : ['vim']
      \ })

  " Vim help
  call smartinput#define_rule(
      \ { 'at'    : '\%#'
      \ , 'char'  : '|'
      \ , 'input' : '||<Left>'
      \ , 'filetype' : ['help']
      \ })
  call smartinput#define_rule(
      \ { 'at'    : '|\%#|'
      \ , 'char'  : '<BS>'
      \ , 'input' : '<Del><BS>'
      \ , 'filetype' : ['help']
      \ })
  call smartinput#map_to_trigger('i', '*', '*', '*')
  call smartinput#define_rule(
      \ { 'at'    : '\%#'
      \ , 'char'  : '*'
      \ , 'input' : '**<Left>'
      \ , 'filetype' : ['help']
      \ })
  call smartinput#define_rule(
      \ { 'at'    : '\*\%#\*'
      \ , 'char'  : '<BS>'
      \ , 'input' : '<Del><BS>'
      \ , 'filetype' : ['help']
      \ })

endif

"}}}
" Vim-smartinput-endwise"{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-smartinput-endwise'))

  call smartinput_endwise#define_default_rules()

endif

"}}}
" Vim-submode "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-submode'))

endif

" }}}
" Gundo.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/gundo.vim'))
  nnoremap <Leader>gu  :GundoToggle<CR>
endif

" }}}
" Vim-colorpicker "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-colorpicker'))
  nmap <Leader>co :ColorPicker<CR>
endif

" }}}


if exists('g:billinux_use_airline')
  " Vim-airline"{{{
  " ----------------------------------------------
  if isdirectory(expand(s:neobundle_dir.'/vim-airline'))

    if ! s:is_gui
      let g:airline_theme = 'wombat'
    endif

    let g:airline_theme = 'badwolf'
    let g:airline#extensions#tabline#enabled = 1
    let g:airline#themes#molokai#palette = {}
    let g:airline_symbols = {}
    let g:airline_symbols.readonly = ''
    let g:airline_symbols.paste = 'ρ'

    if !exists('g:airline_powerline_fonts')
      let g:airline_powerline_fonts=1
    endif
    ""else
     "" " unicode symbols
     "" let g:airline_left_sep          =  '⮀'
     "" let g:airline_left_alt_sep      =  '⮁'
     "" let g:airline_right_sep         =  '⮂'
     "" let g:airline_right_alt_sep     =  '⮃'
     "" let g:airline_symbols.linenr = '␊'
     "" let g:airline_symbols.linenr = '⭡'
     "" let g:airline_symbols.branch     =  '⭠'
     "" let g:airline_symbols.readonly = ''
     "" let g:airline_symbols.paste = 'ρ'
   "" endif

    " Customization
  "  let g:airline_section_b = '%{strftime("%c")}'
  "  let g:airline_section_y = 'BN: %{bufnr("%")}'

  endif

  "}}}
else
  " Lightline "{{{
  " ----------------------------------------------
  if isdirectory(expand(s:neobundle_dir.'/lightline'))

  endif

  " }}}
endif

" Vm-indent-guides "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-indent-guides'))

  let s:bundle = neobundle#get("vim-indent-guides")
  function! s:bundle.hooks.on_post_source(bundle)
      let g:indent_guides_guide_size = 1
      let g:indent_guides_auto_colors = 1
      if !has('gui_running') && &t_Co >= 256
          let g:indent_guides_auto_colors = 0
          Autocmd VimEnter,Colorscheme * hi IndentGuidesOdd  ctermbg=233
          Autocmd VimEnter,Colorscheme * hi IndentGuidesEven ctermbg=240
      endif
      call indent_guides#enable()
  endfunction
  unlet s:bundle

endif

" }}}
" Restart.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/restart.vim'))

endif

" }}}

"}}}

" Colorscheme:"{{{

" Vim-daylight"{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-daylight'))

  let g:daylight_late_hour = 22
  let g:daylight_morning_hour = 6
  let g:daylight_afternoon_hour = 12
  let g:daylight_evening_hour = 18

  let g:daylight_morning_color_gvim = "Tomorrow"
  let g:daylight_afternoon_color_gvim = "solarized"
  let g:daylight_evening_color_gvim = "Tomorrow-Night"
  let g:daylight_late_color_gvim = "molokai"

  let g:daylight_morning_color_term = "Tomorrow"
  let g:daylight_afternoon_color_term = "mayansmoke"
  let g:daylight_evening_color_term = "Tomorrow-Night"
  let g:daylight_late_color_term = "molokai"

endif

"}}}


"}}}

" Neocomplete_Neocomplcache_Youcomplteme:"{{{

" Neocomplete, Neocomplcache, Youcomplteme"{{{

" Neocomplete {{{
" ----------------------------------------------
if count(g:billinux_neobundle_groups, 'neocomplete')

  "AutoComplPop
  let g:acp_enableAtStartup = 0
  let g:neocomplete#enable_at_startup = 1
  let g:neocomplete#enable_smart_case = 1
  let g:neocomplete#enable_fuzzy_completion = 1
  let g:neocomplete#enable_auto_delimiter = 1
  let g:neocomplete#min_keyword_length = 3
  let g:neocomplete#sources#syntax#min_keyword_length = 3
  let g:neocomplete#auto_completion_start_length = 2
  if !exists('g:neocomplete#keyword_patterns')
    let g:neocomplete#keyword_patterns = {}
  endif
  let g:neocomplete#keyword_patterns['default'] = '\h\w*'
  " ctags
  if executable('/usr/local/bin/ctags')
    let g:neocomplete#ctags_command = '/usr/local/bin/ctags'
  elseif executable('/usr/bin/ctags')
    let g:neocomplete#ctags_command = '/usr/bin/gctags'
  endif
  " Ruby
  let g:neocomplete#sources#file_include#exts
    \ = get(g:, 'neocomplete#sources#file_include#exts', {})
  let g:neocomplete#sources#file_include#exts.ruby = ['', 'rb']
  " Max list
  let g:neocomplete#max_list = 300
  " Dictionnaries
  let g:neocomplete#sources#dictionary#dictionaries = {
    \ 'default' : '',
    \ 'vimshell' : expand('~/.vimshell/command-history'),
    \ }
  " Delimiter
  if !exists('g:neocomplete#delimiter_patterns')
    let g:neocomplete#delimiter_patterns = {}
  endif
  let g:neocomplete#delimiter_patterns.vim = ['#']
  let g:neocomplete#delimiter_patterns.cpp = ['::']
  " Source include paths
  if !exists('g:neocomplete#sources#include#paths')
    let g:neocomplete#sources#include#paths = {}
  endif
  let g:neocomplete#sources#include#paths.cpp  = '.,/usr/local/include,/usr/local/opt/gcc49/lib/gcc/x86_64-apple-darwin13.1.0/4.9.0/include/c++,/usr/include'
  let g:neocomplete#sources#include#paths.c    = '.,/usr/include'
  let g:neocomplete#sources#include#paths.perl = '.,/System/Library/Perl,/Users/rhayasd/Programs'
  let g:neocomplete#sources#include#paths.ruby = expand('~/.rbenv/versions/2.0.0-p195/lib/ruby/2.0.0')
  " Include patterns
  let g:neocomplete#sources#include#patterns = { 'c' : '^\s*#\s*include', 'cpp' : '^\s*#\s*include', 'ruby' : '^\s*require', 'perl' : '^\s*use', }
  " Include regex
  let g:neocomplete#filename#include#exprs = {
    \ 'ruby' : "substitute(substitute(v:fname,'::','/','g'),'$','.rb','')"
    \ }
  " Omnicomplete
  AutocmdFT python setlocal omnifunc=pythoncomplete#Complete
  AutocmdFT html   setlocal omnifunc=htmlcomplete#CompleteTags
  AutocmdFT css    setlocal omnifunc=csscomplete#CompleteCss
  AutocmdFT xml    setlocal omnifunc=xmlcomplete#CompleteTags
  AutocmdFT php    setlocal omnifunc=phpcomplete#CompletePHP
  AutocmdFT c      setlocal omnifunc=ccomplete#Complete
  " Neocomplete source
  if !exists('g:neocomplete#sources#omni#input_patterns')
    let g:neocomplete#sources#omni#input_patterns = {}
  endif
  let g:neocomplete#sources#omni#input_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
  let g:neocomplete#sources#omni#input_patterns.c   = '\%(\.\|->\)\h\w*'
  let g:neocomplete#sources#omni#input_patterns.cpp = '\h\w*\%(\.\|->\)\h\w*\|\h\w*::'
  let g:neocomplete#sources#omni#input_patterns.javascript = '\%(\h\w*\|[^. \t]\.\w*\)'
  " Neocomplete
  let g:neocomplete#sources#vim#complete_functions = {
    \ 'Unite' : 'unite#complete_source',
    \ 'VimShellExecute' : 'vimshell#vimshell_execute_complete',
    \ 'VimShellInteractive' : 'vimshell#vimshell_execute_complete',
    \ 'VimShellTerminal' : 'vimshell#vimshell_execute_complete',
    \ 'VimShell' : 'vimshell#complete',
    \ 'VimFiler' : 'vimfiler#complete',
    \}
  let g:neocomplete#force_overwrite_completefunc = 1
  if !exists('g:neocomplete#force_omni_input_patterns')
    let g:neocomplete#force_omni_input_patterns = {}
  endif
  let g:neocomplete#force_omni_input_patterns.python = '\%([^. \t]\.\|^\s*@\|^\s*from\s.\+import \|^\s*from \|^\s*import \)\w*'
  " Neosnippet
  call neocomplete#custom#source('neosnippet', 'min_pattern_length', 1)
  " Neocomplete javascript
  let g:neocomplete#sources#omni#functions = get(g:, 'neocomplete#sources#omni#functions', {})
  if s:enable_tern_for_vim
      let g:neocomplete#sources#omni#functions.javascript = 'tern#Complete'
      let g:neocomplete#sources#omni#functions.coffee = 'tern#Complete'
      AutocmdFT javascript setlocal omnifunc=tern#Complete
  else
      let g:neocomplete#sources#omni#functions.javascript = 'jscomplete#CompleteJS'
      AutocmdFT javascript setlocal omnifunc=jscomplete#CompleteJS
  endif

  "Neocomplete mappings
  inoremap <expr><C-g> neocomplete#undo_completion()
  inoremap <expr><C-s> neocomplete#complete_common_string()
  " <Tab>: completion
  inoremap <expr><Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
  "<C-h>, <BS>: close popup and delete backword char.
  inoremap <expr><C-h> neocomplete#smart_close_popup()."\<C-h>"
  inoremap <expr><BS> neocomplete#smart_close_popup()."\<C-h>"
  inoremap <expr><C-y> neocomplete#cancel_popup()
  " HACK: This hack needs because of using both vim-smartinput and neocomplete
  " when <CR> is typed.
  "    A user types <CR> ->
  "    smart_close_popup() is called when pumvisible() ->
  "    <Plug>(physical_key_return) hooked by vim-smartinput is used
  imap <expr><CR> (pumvisible() ? neocomplete#smart_close_popup() : "")."\<Plug>(physical_key_return)"
  "
  Autocmd CmdwinEnter * inoremap <silent><buffer><Tab> <C-n>
  Autocmd CmdwinEnter * inoremap <expr><buffer><CR> (pumvisible() ? neocomplete#smart_close_popup() : "")."\<CR>"
  Autocmd CmdwinEnter * inoremap <silent><buffer><expr><C-h> col('.') == 1 ?
                                      \ "\<ESC>:quit\<CR>" : neocomplete#cancel_popup()."\<C-h>"
  Autocmd CmdwinEnter * inoremap <silent><buffer><expr><BS> col('.') == 1 ?
                                      \ "\<ESC>:quit\<CR>" : neocomplete#cancel_popup()."\<BS>"
  " }}}
  " Neocomplcache {{{
  " ----------------------------------------------
elseif count(g:billinux_neobundle_groups, 'neocomplcache')

  " AutoComplPop
  let g:acp_enableAtStartup = 0
  let g:neocomplcache_enable_at_startup = 1
  let g:neocomplcache_enable_smart_case = 1
  let g:neocomplcache_enable_underbar_completion = 1
  let g:neocomplcache_min_syntax_length = 3
  if !exists('g:neocomplcache_keyword_patterns')
    let g:neocomplcache_keyword_patterns = {}
  endif
  let g:neocomplcache_keyword_patterns['default'] = '\h\w*'
  " Max list
  let g:neocomplcache_max_list = 300
  let g:neocomplcache_max_keyword_width = 20
  " Dictionnaries
  let g:neocomplcache_dictionary_filetype_lists = {
              \ 'default' : '',
              \ 'vimshell' : expand('~/.vimshell/command-history'),
              \ }
  " Delimiter
  if !exists('g:neocomplcache_delimiter_patterns')
    let g:neocomplcache_delimiter_patterns = {}
  endif
  let g:neocomplcache_delimiter_patterns.vim = ['#']
  let g:neocomplcache_delimiter_patterns.cpp = ['::']
  " Include paths
  if !exists('g:neocomplcache_include_paths')
    let g:neocomplcache_include_paths = {}
  endif
  let g:neocomplcache_include_paths.cpp  = '.,/usr/local/include,/usr/local/opt/gcc49/lib/gcc/x86_64-apple-darwin13.1.0/4.9.0/include/c++,/usr/include'
  let g:neocomplcache_include_paths.c    = '.,/usr/include'
  let g:neocomplcache_include_paths.perl = '.,/System/Library/Perl,/Users/rhayasd/Programs'
  let g:neocomplcache_include_paths.ruby = expand('~/.rbenv/versions/2.0.0-p195/lib/ruby/2.0.0')
  " Include patterns
  let g:neocomplcache_include_patterns = { 'cpp' : '^\s*#\s*include', 'ruby' : '^\s*require', 'perl' : '^\s*use', }
  " Include regex
  let g:neocomplcache_include_exprs = {
    \ 'ruby' : "substitute(substitute(v:fname,'::','/','g'),'$','.rb','')"
    \ }
  " Enable omni completion.
  AutocmdFT python     setlocal omnifunc=pythoncomplete#Complete
  AutocmdFT javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  AutocmdFT html       setlocal omnifunc=htmlcomplete#CompleteTags
  AutocmdFT css        setlocal omnifunc=csscomplete#CompleteCss
  AutocmdFT xml        setlocal omnifunc=xmlcomplete#CompleteTags
  AutocmdFT php        setlocal omnifunc=phpcomplete#CompletePHP
  AutocmdFT c          setlocal omnifunc=ccomplete#Complete
  " Enable heavy omni completion.
  if !exists('g:neocomplcache_omni_patterns')
    let g:neocomplcache_omni_patterns = {}
  endif
  " let g:neocomplcache_omni_patterns.ruby = '[^. *\t]\.\h\w*\|\h\w*::'
  let g:neocomplcache_omni_patterns.php = '[^. \t]->\h\w*\|\h\w*::'
  let g:neocomplcache_omni_patterns.c   = '\%(\.\|->\)\h\w*'
  let g:neocomplcache_omni_patterns.cpp = '\h\w*\%(\.\|->\)\h\w*\|\h\w*::'
  " neocomplcache
  let g:neocomplcache_vim_completefuncs = {
    \ 'Unite' : 'unite#complete_source',
    \ 'VimShellExecute' : 'vimshell#vimshell_execute_complete',
    \ 'VimShellInteractive' : 'vimshell#vimshell_execute_complete',
    \ 'VimShellTerminal' : 'vimshell#vimshell_execute_complete',
    \ 'VimShell' : 'vimshell#complete',
    \ 'VimFiler' : 'vimfiler#complete',
    \}
  " ctags
  if executable('/usr/local/bin/ctags')
    let g:neocomplcache_ctags_program = '/usr/local/bin/ctags'
  elseif executable('/usr/bin/ctags')
    let g:neocomplcache_ctags_program = '/usr/bin/ctags'
  endif

  " neocomplcache
  inoremap <expr><C-g> neocomplcache#undo_completion()
  inoremap <expr><C-s> neocomplcache#complete_common_string()
  " <CR>: close popup and save indent.
  " <Tab>: completion
  inoremap <expr><Tab> pumvisible() ? "\<C-n>" : "\<Tab>"
  "<C-h>, <BS>: close popup and delete backword char.
              " inoremap <expr><C-h> neocomplcache#smart_close_popup()."\<C-h>"
              " inoremap <expr><BS> neocomplcache#smart_close_popup()."\<C-h>"
  inoremap <expr><C-y> neocomplcache#close_popup()
  " HACK: This hack needs because of using both vim-smartinput and neocomplcache
  " when <CR> is typed.
  "    A user types <CR> ->
  "    smart_close_popup() is called when pumvisible() ->
  "    <Plug>(physical_key_return) hooked by vim-smartinput is used
  imap <expr><CR> (pumvisible() ? neocomplcache#smart_close_popup() : "")."\<Plug>(physical_key_return)"
  " Tab
  Autocmd CmdwinEnter * inoremap <silent><buffer><Tab> <C-n>
  Autocmd CmdwinEnter * inoremap <expr><buffer><CR> (pumvisible() ? neocomplcache#smart_close_popup() : "")."\<CR>"
  Autocmd CmdwinEnter * inoremap <silent><buffer><expr><C-h> col('.') == 1 ?
                                      \ "\<ESC>:quit\<CR>" : neocomplcache#cancel_popup()."\<C-h>"
  Autocmd CmdwinEnter * inoremap <silent><buffer><expr><BS> col('.') == 1 ?
                                      \ "\<ESC>:quit\<CR>" : neocomplcache#cancel_popup()."\<BS>"
  " }}}
  " YouCompleteMe"{{{
  " ----------------------------------------------
  "  Compilation
  "  $>cd $HOME/.cache/neobundle/YouCompleteMe/third_party/ycmd
  "  $>./build.sh --clang-completer
elseif count(g:billinux_neobundle_groups, 'youcompleteme')

  let g:acp_enableAtStartup = 0

  " enable completion from tags
  let g:ycm_collect_identifiers_from_tags_files = 1

  " remap Ultisnips for compatibility for YCM
  let g:UltiSnipsExpandTrigger = '<C-j>'
  let g:UltiSnipsJumpForwardTrigger = '<C-j>'
  let g:UltiSnipsJumpBackwardTrigger = '<C-k>'

  " Enable omni completion.
  autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
  autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
  autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
  autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
  autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
  autocmd FileType haskell setlocal omnifunc=necoghc#omnifunc

  " Haskell post write lint and check with ghcmod
  " $ `cabal install ghcmod` if missing and ensure
  " ~/.cabal/bin is in your $PATH.
  if !executable("ghcmod")
    autocmd BufWritePost *.hs GhcModCheckAndLintAsync
  endif

  " For snippet_complete marker.
  if !exists("g:spf13_no_conceal")
    if has('conceal')
      set conceallevel=2 concealcursor=i
    endif
  endif

  " Disable the neosnippet preview candidate window
  " When enabled, there can be too much visual noise
  " especially when splits are used.
  set completeopt-=preview
"}}}
  " OmniCompletion"{{{
  " ----------------------------------------------
elseif !exists('g:billinux_no_omni_complete')
  " Enable omni-completion.
  autocmd FileType css setlocal omnifunc=csscomplete#CompleteCSS
  autocmd FileType html,markdown setlocal omnifunc=htmlcomplete#CompleteTags
  autocmd FileType javascript setlocal omnifunc=javascriptcomplete#CompleteJS
  autocmd FileType python setlocal omnifunc=pythoncomplete#Complete
  autocmd FileType xml setlocal omnifunc=xmlcomplete#CompleteTags
  autocmd FileType ruby setlocal omnifunc=rubycomplete#Complete
  autocmd FileType haskell setlocal omnifunc=necoghc#omnifunc

endif
"}}}
"}}}
" Neosnippet "{{{
" ----------------------------------------------
if count(g:billinux_neobundle_groups, 'neocomplete') ||
      \ count(g:billinux_neobundle_groups, 'neocomplcache')

" Use honza's snippets.
  let g:neosnippet#snippets_directory=s:neobundle_dir.'/vim-snippets/snippets'

  " Enable neosnippet snipmate compatibility mode
  let g:neosnippet#enable_snipmate_compatibility = 1 

  imap <expr><C-l> neosnippet#expandable() \|\| neosnippet#jumpable() ?
              \ "\<Plug>(neosnippet_jump_or_expand)" :
              \ "\<C-s>"
  smap <expr><C-l> neosnippet#expandable() \|\| neosnippet#jumpable() ?
              \ "\<Plug>(neosnippet_jump_or_expand)" :
              \ "\<C-s>"
  "
  imap <expr><C-S-l> neosnippet#expandable() \|\| neosnippet#jumpable() ?
              \ "\<Plug>(neosnippet_expand_or_jump)" :
              \ "\<C-s>"
  smap <expr><C-S-l> neosnippet#expandable() \|\| neosnippet#jumpable() ?
              \ "\<Plug>(neosnippet_expand_or_jump)" :
              \ "\<C-s>"
  " C++ & Python
  let g:neosnippet#disable_runtime_snippets = {'cpp' : 1, 'python' : 1, 'd' : 1}

endif

"}}}

"}}}

" Programming:"{{{

" VimShell "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vimshell'))

  nnoremap <silent><Leader>vs :<C-u>VimShell -split-command=vsplit<CR>
  nnoremap <Leader>vc :<C-u>VimShellSendString<Space>

  let s:bundle = neobundle#get("vimshell")
  function! s:bundle.hooks.on_source(bundle)
    "
    let g:vimshell_user_prompt = 'fnamemodify(getcwd(), ":~")'
    let g:vimshell_right_prompt = 'strftime("%Y/%m/%d %H:%M")'
    let g:vimshell_prompt = "(U'w'){ "
    " let g:vimshell_prompt = "(U^w^){ "
    " executable suffix
    let g:vimshell_execute_file_list = { 'pdf' : 'open', 'mp3' : 'open',
                                      \ 'jpg' : 'open', 'png' : 'open',
                                      \ }
    " zsh
    if filereadable(expand('~/.zsh/zsh_history'))
        let g:vimshell_external_history_path = expand('~/.zsh/zsh_history')
    endif

    " VimShell {{{
    " <C-n> <C-p>
    AutocmdFT vimshell nnoremap <buffer><silent><C-n> :<C-u>bn<CR>
    AutocmdFT vimshell nnoremap <buffer><silent><C-p> :<C-u>bp<CR>
    AutocmdFT vimshell nmap <buffer><silent>gn <Plug>(vimshell_next_prompt)
    AutocmdFT vimshell nmap <buffer><silent>gp <Plug>(vimshell_previous_prompt)
    " VimFiler
    AutocmdFT vimshell nnoremap <buffer><silent><Leader>ff :<C-u>VimFilerCurrentDir<CR>
    AutocmdFT vimshell inoremap <buffer><silent><C-s> <Esc>:<C-u>VimFilerCurrentDir<CR>
    "
    AutocmdFT vimshell imap <buffer><silent><C-j> <C-u>..<Plug>(vimshell_enter)
    " popd
    AutocmdFT vimshell imap <buffer><silent><C-p> <C-u>popd<Plug>(vimshell_enter)
    " git status
    AutocmdFT vimshell imap <buffer><silent><C-q> <C-u>git status -sb<Plug>(vimshell_enter)
    " zsh & bash <C-d>
    AutocmdFT vimshell imap <buffer><silent><expr><C-d> vimshell#get_cur_text()=='' ? "\<Esc>\<Plug>(vimshell_exit)" : "\<Del>"
    "
    AutocmdFT vimshell nnoremap <buffer>a GA
    " }}}
  endfunction
  unlet s:bundle

endif

  " }}}
" VimFiler "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vimfiler'))

  " VimFiler "{{{
  augroup LoadVimFiler
      autocmd!
      autocmd BufEnter,BufCreate,BufWinEnter * call <SID>load_vimfiler(expand('<amatch>'))
  augroup END

  " :edit {dir} & unite.vim
  function! s:load_vimfiler(path)
      if exists('g:loaded_vimfiler')
          autocmd! LoadVimFiler
          return
      endif

      let path = a:path
      " for ':edit ~'
      if fnamemodify(path, ':t') ==# '~'
          let path = expand('~')
      endif

      if isdirectory(path)
          NeoBundleSource vimfiler
      endif

      autocmd! LoadVimFiler
  endfunction

  "
  for arg in argv()
      if isdirectory(getcwd().'/'.arg)
          NeoBundleSource vimfiler.vim
          autocmd! LoadVimFiler
          break
      endif
  endfor
  "}}}

  let g:loaded_netrwPlugin = 1
  let g:vimfiler_as_default_explorer = 1
  let g:vimfiler_safe_mode_by_default = 0
  let g:vimfiler_split_command = 'vertical rightbelow vsplit'
  let g:vimfiler_execute_file_list = { '_' : 'vim', 'pdf' : 'open', 'mp3' : 'open', 'jpg' : 'open',
                                    \ 'png' : 'open',
                                    \ }
  let g:vimfiler_split_rule = 'botright'

  " vimfiler.vim
  " smart s mapping for edit or cd
  AutocmdFT vimfiler nmap <buffer><silent><expr> l vimfiler#smart_cursor_map(
              \ "\<Plug>(vimfiler_cd_file)",
              \ "\<Plug>(vimfiler_edit_file)")
  " jump to VimShell
  AutocmdFT vimfiler nnoremap <buffer><silent><Leader>vs
              \ :<C-u>VimShellCurrentDir<CR>
  " 'a'nother
  AutocmdFT vimfiler nmap <buffer><silent>a <Plug>(vimfiler_switch_to_another_vimfiler)
  " unite.vim
  AutocmdFT vimfiler nmap <buffer><silent><Tab> <Plug>(vimfiler_choose_action)
  " <Space> unite.vim
  AutocmdFT vimfiler nmap <buffer><silent>u [unite]
  " unite.vim file_mru
  AutocmdFT vimfiler nnoremap <buffer><silent><C-h> :<C-u>Unite file_mru directory_mru<CR>
  " unite.vim file
  AutocmdFT vimfiler
              \ nnoremap <buffer><silent>/
              \ :<C-u>execute 'Unite' 'file:'.vimfiler#get_current_vimfiler().current_dir.'/-default-action=open_or_vimfiler'<CR>
  " git
  AutocmdFT vimfiler nnoremap <buffer><expr>ga vimfiler#do_action('git_repo_files')

  nnoremap <Leader>f                <Nop>
  nnoremap <Leader>ff               :<C-u>VimFiler<CR>
  nnoremap <Leader>fs               :<C-u>VimFilerSplit<CR>
  nnoremap <Leader><Leader>         :<C-u>VimFiler<CR>
  nnoremap <Leader>fq               :<C-u>VimFiler -no-quit<CR>
  nnoremap <Leader>fh               :<C-u>VimFiler ~<CR>
  nnoremap <Leader>fc               :<C-u>VimFilerCurrentDir<CR>
  nnoremap <Leader>fb               :<C-u>VimFilerBufferDir<CR>
  nnoremap <silent><expr><Leader>fg ":\<C-u>VimFiler " . <SID>git_root_dir() . '\<CR>'
  nnoremap <silent><expr><Leader>fe ":\<C-u>VimFilerExplorer " . <SID>git_root_dir() . '\<CR>'
  nnoremap <Leader>fd               :<C-u>VimFilerDouble -tab<CR>

endif

" }}}
" Tabular "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/tabular'))

  nmap <Leader>a& :Tabularize /&<CR>
  vmap <Leader>a& :Tabularize /&<CR>
  nmap <Leader>a= :Tabularize /=<CR>
  vmap <Leader>a= :Tabularize /=<CR>
  nmap <Leader>a=> :Tabularize /=><CR>
  vmap <Leader>a=> :Tabularize /=><CR>
  nmap <Leader>a: :Tabularize /:<CR>
  vmap <Leader>a: :Tabularize /:<CR>
  nmap <Leader>a:: :Tabularize /:\zs<CR>
  vmap <Leader>a:: :Tabularize /:\zs<CR>
  nmap <Leader>a, :Tabularize /,<CR>
  vmap <Leader>a, :Tabularize /,<CR>
  nmap <Leader>a,, :Tabularize /,\zs<CR>
  vmap <Leader>a,, :Tabularize /,\zs<CR>
  nmap <Leader>a<Bar> :Tabularize /<Bar><CR>
  vmap <Leader>a<Bar> :Tabularize /<Bar><CR>

endif

" }}}
" Tagbar "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/tagbar'))

  nnoremap <silent> <leader>tt :TagbarToggle<CR>

  " If using go please install the gotags program using the following
  " go install github.com/jstemmer/gotags
  " And make sure gotags is in your path
  let g:tagbar_type_go = {
      \ 'ctagstype' : 'go',
      \ 'kinds'     : [  'p:package', 'i:imports:1', 'c:constants', 'v:variables',
          \ 't:types',  'n:interfaces', 'w:fields', 'e:embedded', 'm:methods',
          \ 'r:constructor', 'f:functions' ],
      \ 'sro' : '.',
      \ 'kind2scope' : { 't' : 'ctype', 'n' : 'ntype' },
      \ 'scope2kind' : { 'ctype' : 't', 'ntype' : 'n' },
      \ 'ctagsbin'  : 'gotags',
      \ 'ctagsargs' : '-sort -silent'
      \ }

endif

" }}}
  " Unite.vim {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/unite.vim'))

  let s:bundle = neobundle#get("unite.vim")
  function! s:bundle.hooks.on_source(bundle)
      "
      let g:unite_source_file_mru_filename_format = ''
      " most recently used
      let g:unite_source_file_mru_limit = 100
      " unite-grep
      let g:unite_source_grep_default_opts = "-Hn --color=never"
      " the silver searcher &  unite-grep
      if executable('ag')
          let g:unite_source_grep_command = 'ag'
          let g:unite_source_grep_default_opts = '--nocolor --nogroup --column'
          let g:unite_source_grep_recursive_opt = ''
      endif

      " Git {{{
      let git_repo = { 'description' : 'all file in git repository' }
      function! git_repo.func(candidate)
          if(system('git rev-parse --is-inside-work-tree') ==# "true\n" )
              execute 'args'
                      \ join( filter(split(system('git ls-files `git rev-parse --show-cdup`'), '\n')
                              \ , 'empty(v:val) || isdirectory(v:val) || filereadable(v:val)') )
          else
              echoerr 'Not a git repository!'
          endif
      endfunction

      call unite#custom#action('file', 'git_repo_files', git_repo)
      " }}}

      " VimFiler {{{
      let open_or_vimfiler = {
                  \ 'description' : 'open a file or open a directory with vimfiler',
                  \ 'is_selectable' : 1,
                  \ }
      function! open_or_vimfiler.func(candidates)
          for candidate in a:candidates
              if candidate.kind ==# 'directory'
                  execute 'VimFiler' candidate.action__path
                  return
              endif
          endfor
          execute 'args' join(map(a:candidates, 'v:val.action__path'), ' ')
      endfunction
      call unite#custom#action('file', 'open_or_vimfiler', open_or_vimfiler)
      "}}}

      " Finder for Mac
      if has('mac')
          let finder = { 'description' : 'open with Finder.app' }
          function! finder.func(candidate)
              if a:candidate.kind ==# 'directory'
                  call unite#util#system('open -a Finder '.a:candidate.action__path)
              endif
          endfunction
          call unite#custom#action('directory', 'finder', finder)
      endif

      call unite#custom#profile('source/quickfix,source/outline,source/line,source/line/fast,source/grep', 'context', {'prompt_direction' : 'top'})
      call unite#custom#profile('source/ghq', 'context', {'default_action' : 'vimfiler'})

      call unite#custom#profile('default', 'context', {
                  \ 'start_insert' : 1,
                  \ 'direction' : 'botright',
                  \ })

      " C-g
      AutocmdFT unite imap <buffer><C-g> <Plug>(unite_exit)
      AutocmdFT unite nmap <buffer><C-g> <Plug>(unite_exit)
      "
      AutocmdFT unite imap <buffer><C-w> <Plug>(unite_delete_backward_path)
      AutocmdFT unite nmap <buffer>h <Plug>(unite_delete_backward_path)
      "
      AutocmdFT unite inoremap <buffer><expr>p unite#smart_map("p", unite#do_action('preview'))
      " C-x
      AutocmdFT unite imap <buffer><C-x> <Plug>(unite_quick_match_default_action)
      " l
      AutocmdFT unite nmap <buffer>l <Plug>(unite_do_default_action)
      AutocmdFT unite imap <buffer><expr>l unite#smart_map("l", unite#do_action(unite#get_current_unite().context.default_action))
      "jj
      AutocmdFT unite imap <buffer><silent>jj <Plug>(unite_insert_leave)
  endfunction
  unlet s:bundle

  "unite.vim {{{
  nnoremap [unite] <Nop>
  xnoremap [unite] <Nop>
  nmap    ;u      [unite]
  xmap    ;u      [unite]
  map     <Space> [unite]
  " Unite
  nnoremap [unite]u                 :<C-u>Unite source<CR>
  "
  nnoremap <silent>[unite]<Space>   :<C-u>UniteWithBufferDir -buffer-name=files -vertical file directory file/new<CR>
  "
  nnoremap <silent>[unite]m         :<C-u>Unite file_mru directory_mru zsh-cdr file/new<CR>
  "
  nnoremap <silent>[unite]R       :<C-u>UniteWithBufferDir -no-start-insert file_rec/async -auto-resize<CR>
  "
  nnoremap <silent>[unite]b         :<C-u>Unite -immediately -no-empty -auto-preview buffer<CR>
  "
  nnoremap <silent>[unite]o         :<C-u>Unite outline -vertical -no-start-insert<CR>
  "
  nnoremap <silent>[unite]c         :<C-u>Unite output<CR>
  " grep
  nnoremap <silent>[unite]gr        :<C-u>Unite -no-start-insert grep<CR>
  " Unite
  nnoremap <silent>[unite]r         :<C-u>UniteResume<CR>
  " Unite
  nnoremap <silent>[unite]s         :<C-u>Unite source -vertical<CR>
  " NeoBundle
  nnoremap <silent>[unite]nb        :<C-u>Unite neobundle/update:all -auto-quit -keep-focus -log<CR>
  " Haskell Import
  AutocmdFT haskell nnoremap <buffer>[unite]hd :<C-u>Unite haddock<CR>
  AutocmdFT haskell nnoremap <buffer>[unite]ho :<C-u>Unite hoogle<CR>
  AutocmdFT haskell nnoremap <buffer><expr>[unite]hi
                      \        empty(expand("<cWORD>")) ? ":\<C-u>Unite haskellimport\<CR>"
                      \                                 :":\<C-u>UniteWithCursorWord haskellimport\<CR>"
  " Git
  nnoremap <silent><expr>[unite]fg  ":\<C-u>Unite file -input=".fnamemodify(<SID>git_root_dir(),":p")
  " alignta (visual)
  vnoremap <silent>[unite]aa        :<C-u>Unite alignta:arguments<CR>
  vnoremap <silent>[unite]ao        :<C-u>Unite alignta:options<CR>
  " C++
  AutocmdFT cpp nnoremap <buffer>[unite]i :<C-u>Unite file_include -vertical<CR>
  " help
  nnoremap <silent>[unite]hh        :<C-u>UniteWithInput help -vertical<CR>
  "
  nnoremap <silent>[unite]hc        :<C-u>Unite -buffer-name=lines history/command -start-insert<CR>
  nnoremap <silent>[unite]hs        :<C-u>Unite -buffer-name=lines history/search<CR>
  nnoremap <silent>[unite]hy        :<C-u>Unite -buffer-name=lines history/yank<CR>
  "
  nnoremap <silent>[unite]p         :<C-u>Unite file_rec:! file/new<CR>
  " unite-lines
  nnoremap <silent><expr> [unite]L line('$') > 5000 ?
              \ ":\<C-u>Unite -no-split -start-insert -auto-preview line/fast\<CR>" :
              \ ":\<C-u>Unite -start-insert -auto-preview line:all\<CR>"
  "
  nnoremap [unite]C :<C-u>Unite -auto-preview colorscheme<CR>
  " locate
  nnoremap <silent>[unite]l :<C-u>UniteWithInput locate<CR>
  "
  nnoremap <silent>[unite]/ :<C-u>execute 'Unite grep:'.expand('%:p').' -input='.escape(substitute(@/, '^\\v', '', ''), ' \')<CR>
  " ghq
  nnoremap <silent>[unite]gg :<C-u>Unite -start-insert -default-action=vimfiler ghq directory_mru<CR>
  " }}}

endif

" }}}
" Unite-n3337 "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/unite-n3337'))

  let g:unite_n3337_pdf = $HOME.'/Documents/C++/n3337.pdf'
  AutocmdFT cpp nnoremap <buffer>[unite]n :<C-u>Unite n3337<CR>

endif

"}}}
" EasyMotion "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/easymotion'))

  let g:EasyMotion_do_mapping = 0
  "map : <Plug>(easymotion-s2)

endif

" }}}
" Clever-f.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/clever-f.vim'))

endif

" }}}
" Vim-fugitive {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-fugitive'))

  nnoremap <Leader>gs :<C-u>Gstatus<CR>
  nnoremap <Leader>gC :<C-u>Gcommit -v<CR>
  function! s:fugitive_commit()
      ZoomWin
      Gcommit -v
      silent only
      if getline('.') == ''
          startinsert
      endif
  endfunction
  nnoremap <Leader>gc :<C-u>call <SID>fugitive_commit()<CR>
  nnoremap <Leader>gl :<C-u>QuickRun sh -src 'git log --graph --oneline'<CR>
  nnoremap <Leader>ge :<C-u>Gedit<CR>
  nnoremap <Leader>gr :<C-u>Gread<CR>
  nnoremap <Leader>gw :<C-u>Gwrite<CR>
  nnoremap <Leader>gd :<C-u>Gdiff<CR>
  nnoremap <Leader>gb :<C-u>Gblame<CR>
  nnoremap <Leader>gp :<C-u>Git push<CR>

  " Mnemonic _i_nteractive
  nnoremap <Leader>gi :<C-u>Git add -p %<CR>
  nnoremap <Leader>gg :<C-u>SignifyToggle<CR>


  let s:bundle = neobundle#get("vim-fugitive")
  function! s:bundle.hooks.on_post_source(bundle)
      doautoall fugitive BufReadPost
      AutocmdFT fugitiveblame nnoremap <buffer>? :<C-u>SmartHelp :Gblame<CR>
      AutocmdFT gitcommit     if expand('%:t') ==# 'index' | nnoremap <buffer>? :<C-u>SmartHelp :Gstatus<CR> | endif
  endfunction
  unlet s:bundle

endif

" }}}
" Gitv "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/gitv'))

endif

" }}}
" Vim-signify "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-signify'))

  let g:signify_vcs_list = ['git', 'svn']
  let g:signify_update_on_bufenter = 0
  let g:signify_update_on_focusgained = 0
  let g:signify_cursorhold_normal = 0
  let g:signify_cursorhold_insert = 0

endif

"}}}
" Open-browser.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/open-browser.vim'))

  nmap <Leader>o <Plug>(openbrowser-smart-search)
  xmap <Leader>o <Plug>(openbrowser-smart-search)
  nnoremap <Leader>O :<C-u>OpenGithubFile<CR>
  vnoremap <Leader>O :OpenGithubFile<CR>

endif

"}}}

"}}}

" Html_Css_Sass_Scss_Haml:"{{{

" Emmet-vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/emmet-vim'))

  let g:user_emmet_mode = 'ivn'
  let g:user_emmet_leader_key = '<C-Y>'
  let g:use_emmet_complete_tag = 1
  let g:user_emmet_settings = { 'lang' : 'fr' }

endif

"}}}
" Html5.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/html5'))

endif

" }}}
" Vim-haml "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-haml'))

endif

" }}}
" Vim-jade "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-jade'))

endif

" }}}

"}}}

" Php:"{{{

" PIV "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/piv'))
  let g:DisableAutoPHPFolding = 0
  let g:PIVAutoClose = 0

endif

" }}}
" Vim-php-namespace "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-php-namespace'))

endif

" }}}
" Vim-twig "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-twig'))

endif

" }}}

"}}}

" Javascript:"{{{

" Vim-javascript "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-javascript'))

endif

" }}}
" Simple-javascript "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/simple-javascript'))

endif

" }}}
" Vim-javascript-syntax "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-javascript-syntax'))

endif

" }}}

if s:enable_tern_for_vim
" Tern_for_vim "{{{
" ----------------------------------------------
  if isdirectory(expand(s:neobundle_dir.'/tern_for_vim'))

    let s:hooks = neobundle#get_hooks('tern_for_vim')
    function! s:hooks.on_source(bundle)
        call s:setup_tern()
    endfunction
    unlet s:hooks
    function! s:setup_tern()
        nnoremap <buffer><Leader>td :<C-u>TernDef<CR>
        nnoremap <buffer><Leader>tk :<C-u>TernDoc<CR>
        nnoremap <buffer><silent><Leader>tt :<C-u>TernType<CR>
        nnoremap <buffer><Leader>tK :<C-u>TernRefs<CR>
        nnoremap <buffer><Leader>tr :<C-u>TernRename<CR>
    endfunction

  endif

"}}}
else
" Jscomplete-vim "{{{
" ----------------------------------------------
  if isdirectory(expand(s:neobundle_dir.'/jscomplete'))

  endif

" }}}
endif

"}}}

" Python:"{{{

" Jedi-vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/jedi-vim'))

  let g:jedi#auto_initialization = 0
  let g:jedi#auto_vim_configuration = 0
  let g:jedi#popup_select_first = 0

  function! s:jedi_settings()
      nnoremap <buffer><Leader>jr :<C-u>call jedi#rename()<CR>
      nnoremap <buffer><Leader>jg :<C-u>call jedi#goto_assignments()<CR>
      nnoremap <buffer><Leader>jd :<C-u>call jedi#goto_definitions()<CR>
      nnoremap <buffer>K :<C-u>call jedi#show_documentation()<CR>
      nnoremap <buffer><Leader>ju :<C-u>call jedi#usages()<CR>
      nnoremap <buffer><Leader>ji :<C-u>Pyimport<Space>
      setlocal omnifunc=jedi#completions
      command! -nargs=0 JediRename call jedi#rename()
  endfunction

  AutocmdFT python call <SID>jedi_settings()

endif

" }}}
" Vim-python-pep8-indent "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-python-pep8-indent'))

endif

" }}}

"}}}

" Ruby:"{{{

" Unite-rails "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/unite-rails'))

  function! s:rails_mvc_name()
      let full_path = expand('%:p')
      if  full_path !~# '\/app\/'
          echoerr 'not rails MVC files'
      endif

      " controllers
      let base_name = expand('%:r')
      if base_name =~# '\w\+_controller'
          if  full_path !~# '\/controllers\/'
              echoerr 'not rails MVC files'
          endif
          return matchstr(base_name, '\w\+\ze_controller')
      endif

      " views
      if expand('%:e:e') == 'html.erb'
          return fnamemodify(full_path, ':h:t')
      endif

      " models
      if fnamemodify(full_path, ':h:t') == 'models'
          return base_name
      endif

      echoerr 'not rails MVC files'
  endfunction

  " unite-rails {{{
  command! -nargs=0 RModels      Unite rails/model -no-start-insert
  command! -nargs=0 RControllers Unite rails/controller -no-start-insert
  command! -nargs=0 RViews       Unite rails/view -no-start-insert
  command! -nargs=0 RMVC         Unite rails/model rails/controller rails/view
  command! -nargs=0 RHelpers     Unite rails/helpers -no-start-insert
  command! -nargs=0 RMailers     Unite rails/mailers -no-start-insert
  command! -nargs=0 RLib         Unite rails/lib -no-start-insert
  command! -nargs=0 RDb          Unite rails/db -no-start-insert
  command! -nargs=0 RConfig      Unite rails/config -no-start-insert
  command! -nargs=0 RLog         Unite rails/log -no-start-insert
  command! -nargs=0 RJapascripts Unite rails/javascripts -no-start-insert
  command! -nargs=0 RStylesheets Unite rails/stylesheets -no-start-insert
  command! -nargs=0 RBundle      Unite rails/bundle -no-start-insert
  command! -nargs=0 RGems        Unite rails/bundled_gem -no-start-insert
  command! -nargs=0 R            execute 'Unite rails/model rails/controller rails/view -no-start-insert -input=' . s:rails_mvc_name()
  "}}}

endif

"}}}
" Vim-textobj-ruby "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-textobj-ruby'))

endif

" }}}
" Neco-ruby-keyword-args "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/neco-ruby-keyword-args'))

endif

" }}}

"}}}

" Cpp:"{{{

" Cpp.vim {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/cpp.vim'))

endif

" }}}
" Clang_complete {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/clang_complete'))

  let g:clang_complete_auto = 0
  let g:clang_auto_select = 1
  " let g:clang_make_default_keymappings = 0

endif

" }}}
" Vim-clang-format {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-clang-format'))

endif

" }}}
" Vim-clang-extent-selectort.vim {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-clang-extent-selectort.vim'))

endif

" }}}
" Vim-clang-type-inspector.vim {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-clang-type-inspector.vim'))

endif

" }}}

"}}}

" Go: {{{

function! s:golang_settings()

  " Godoc
  nnoremap <buffer><silent>K :<C-u>execute 'Godoc' expand('<cword>')<CR>
  "   Note: 'fmt.Printf' -> 'fmt Printf'
  vnoremap <buffer><silent>K y:<C-u>execute 'Godoc' substitute(getreg('+'), '\.', ' ', 'g')<CR>
  "
  nnoremap <buffer><silent>:gi :<C-u>execute 'Import' expand('<cword>')<CR>
  "
  nnoremap <buffer>:gd :<C-u>Drop<Space>
  "
  nnoremap <buffer>:gf :<C-u>Fmt<CR>
  "
  inoremap <buffer><silent><C-g>i <C-o>:<C-u>execute 'Import' matchstr(getline('.')[:col('.')-1], '\h\w*\ze\W*$')<CR><Right>
  "
  setlocal noexpandtab
  let g:go_fmt_autofmt = 1
  nnoremap <buffer><Space>i :<C-u>Unite go/import<CR>
  let g:godef_split = 0
  let g:godef_same_file_in_same_window = 1

endfunction

AutocmdFT go call <SID>golang_settings()
AutocmdFT godoc nnoremap<buffer>q :<C-u>quit<CR>
AutocmdFT godoc nnoremap<buffer>d <C-d>
AutocmdFT godoc nnoremap<buffer>u <C-u>
" }}}

" Markdown:"{{{

" Previm {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/previm'))

  AutocmdFT markdown nnoremap <buffer><Leader>p :<C-u>PrevimOpen<CR>
  Autocmd BufWritePost *.md,*.markdown call previm#refresh()
  let g:previm_enable_realtime = 0

endif

"}}}

"}}}

" Json:"{{{


"}}}

" Writing:"{{{


"}}}

" Testing:"{{{


"}}}

" Misc:"{{{

" Vim-quickrun "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-quickrun'))

  "<Leader>r
  let g:quickrun_no_default_key_mappings = 1
  " quickrun_config
  let g:quickrun_config = get(g:, 'quickrun_config', {})
  "QuickRun
  let g:quickrun_config._ = {
    \ 'outputter' : 'unite_quickfix',
    \ 'split' : 'rightbelow 10sp',
    \ 'hook/hier_update/enable' : 1,
    \ 'runner/vimproc/updatetime' : 500,
    \ }
  "C++
  let g:quickrun_config.cpp = {
    \ 'command' : 'clang++',
    \ 'cmdopt' : '-std=c++1y -Wall -Wextra -O2',
    \ 'hook/quickrunex/enable' : 1,
    \ }
  let g:quickrun_config['cpp/llvm'] = {
    \ 'type' : 'cpp/clang++',
    \ 'exec' : '%c %o -emit-llvm -S %s -o -',
    \ }
  let g:quickrun_config['c/llvm'] = {
    \ 'type' : 'c/clang',
    \ 'exec' : '%c %o -emit-llvm -S %s -o -',
    \ }
  "
  let g:quickrun_config['cpp/preprocess/g++'] = { 'type' : 'cpp/g++', 'exec' : '%c -P -E %s' }
  let g:quickrun_config['cpp/preprocess/clang++'] = { 'type' : 'cpp/clang++', 'exec' : '%c -P -E %s' }
  let g:quickrun_config['cpp/preprocess'] = { 'type' : 'cpp', 'exec' : '%c -P -E %s' }
  "outputter
  let g:quickrun_unite_quickfix_outputter_unite_context = { 'no_empty' : 1 }
  " runner vimproc
  let g:quickrun_config['_']['runner/vimproc/updatetime'] = 500
  Autocmd BufReadPost,BufNewFile [Rr]akefile{,.rb}
    \ let b:quickrun_config = {'exec': 'rake -f %s'}
  " tmux
  let g:quickrun_config['tmux'] = {
    \ 'command' : 'tmux',
    \ 'cmdopt' : 'source-file',
    \ 'exec' : ['%c %o %s:p', 'echo "sourced %s"'],
    \ }

  let g:quickrun_config['llvm'] = {
    \   'exec' : 'llvm-as-3.4 %s:p -o=- | lli-3.4 - %a',
    \ }

  let g:quickrun_config['dachs'] = {
    \   'command' : './bin/dachs',
    \   'exec' : ['%c %o %s:p', '%s:p:r %a'],
    \ }

  let g:quickrun_config['dachs/llvm'] = {
    \   'type' : 'dachs',
    \   'cmdopt' : '--emit-llvm',
    \   'exec' : '%c %o %s:p',
    \ }


  "
  let g:quickrun_config['syntax/cpp/g++'] = {
    \ 'runner' : 'vimproc',
    \ 'outputter' : 'quickfix',
    \ 'command' : 'g++',
    \ 'cmdopt' : '-std=c++1y -Wall -Wextra -O2',
    \ 'exec' : '%c %o -fsyntax-only %s:p'
    \ }

  let g:quickrun_config['syntax/ruby'] = {
    \ 'runner' : 'vimproc',
    \ 'outputter' : 'quickfix',
    \ 'command' : 'ruby',
    \ 'exec' : '%c -c %s:p %o',
    \ }
  Autocmd BufWritePost *.rb QuickRun -type syntax/ruby

  if executable('jshint')
    let g:quickrun_config['syntax/javascript'] = {
        \ 'command' : 'jshint',
        \ 'outputter' : 'quickfix',
        \ 'exec'    : '%c %o %s:p',
        \ 'runner' : 'vimproc',
        \ 'errorformat' : '%f: line %l\, col %c\, %m',
        \ }
      Autocmd BufWritePost *.js QuickRun -type syntax/javascript
  endif

  let g:quickrun_config['syntax/haml'] = {
    \ 'runner' : 'vimproc',
    \ 'command' : 'haml',
    \ 'outputter' : 'quickfix',
    \ 'exec'    : '%c -c %o %s:p',
    \ 'errorformat' : 'Haml error on line %l: %m,Syntax error on line %l: %m,%-G%.%#',
    \ }
  Autocmd BufWritePost *.haml QuickRun -type syntax/haml

  if executable('pyflakes')
    let g:quickrun_config['syntax/python'] = {
      \ 'command' : 'pyflakes',
      \ 'exec' : '%c %o %s:p',
      \ 'outputter' : 'quickfix',
      \ 'runner' : 'vimproc',
      \ 'errorformat' : '%f:%l:%m',
      \ }
    Autocmd BufWritePost *.py QuickRun -type syntax/python
  endif

  if executable('go')
    let g:quickrun_config['syntax/go'] = {
        \ 'command' : 'go',
        \ 'exec' : '%c vet %o %s:p',
        \ 'outputter' : 'quickfix',
        \ 'runner' : 'vimproc',
        \ 'errorformat' : '%Evet: %.%\+: %f:%l:%c: %m,%W%f:%l: %m,%-G%.%#',
        \ }
      Autocmd BufWritePost *.go QuickRun -type syntax/go
  endif

  "QuickRun "{{{
  nnoremap <Leader>q  <Nop>
  nnoremap <silent><Leader>qr :<C-u>QuickRun<CR>
  vnoremap <silent><Leader>qr :QuickRun<CR>
  nnoremap <silent><Leader>qR :<C-u>QuickRun<Space>
  " clang
  let g:quickrun_config['cpp/clang'] = { 'command' : 'clang++', 'cmdopt' : '-stdlib=libc++ -std=c++11 -Wall -Wextra -O2' }
  AutocmdFT cpp nnoremap <silent><buffer><Leader>qc :<C-u>QuickRun -type cpp/clang<CR>
  " }}}

endif

" }}}
" Tmux.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/tmux.vim'))

endif

" }}}
" Puyo.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/puyo.vim'))

endif

" }}}
" Vim-threes "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-threes'))

endif

" }}}
" Calendar.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/calendar.vim'))

  let g:calendar_google_calendar = 1
  let g:calendar_date_endian = 'big'
  let g:calendar_first_day = 'sun_day'

  "
  AutocmdFT puyo,calendar Autocmd CursorHold,CursorHoldI,WinEnter <buffer> setlocal nocursorline

  AutocmdFT calendar nmap <buffer>l w
  AutocmdFT calendar nmap <buffer>h b

  nnoremap <silent><Leader>cw :<C-u>Calendar -view=week -split=horizontal -height=18<CR>

  if ! has('gui_running')
      let g:calendar_frame = 'default'
  endif

endif

" }}}
" Wandbox-vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/wandbox-vim'))

  let g:wandbox#echo_command = 'echomsg'
  let g:wandbox#default_compiler = get(g:, 'wandbox#default_compiler', {'cpp' : 'gcc-head,clang-head', 'ruby' : 'mruby'})
  noremap <Leader>wb :<C-u>Wandbox<CR>

endif

"}}}
" Open-pdf.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/open-pdf.vim'))

endif

" }}}
" Agit.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/agit.vim'))

  let g:puyo#updatetime = 500

endif

"}}}
" ZoomWin {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/zoomwin'))

  nnoremap <C-w>o :<C-u>ZoomWin<CR>

endif

"}}}
" Memolist.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/memolist.vim'))

  nnoremap <Leader>mn :<C-u>MemoNew<CR>
  nnoremap <silent><Leader>ml :<C-u>call <SID>memolist()<CR>
  nnoremap <Leader>mg :<C-u>execute 'Unite' 'grep:'.g:memolist_path '-auto-preview'<CR>

  if isdirectory(expand('~/Dropbox/memo'))
    let g:memolist_path = expand('~/Dropbox/memo')
  else
    if isdirectory(expand('~/.vim/memo'))
        call mkdir(expand('~/.vim/memo'), 'p')
    endif
    let g:memolist_path = expand('~/.vim/memo')
  endif

  let g:memolist_memo_suffix = 'md'
  let g:memolist_unite = 1
  let g:memolist_unite_option = '-auto-preview -no-start-insert'

  function! s:memolist()
    " delete swap files because they make unite auto preview hung up
    for swap in glob(g:memolist_path.'/.*.sw?', 1, 1)
        if swap !~# '^\.\+$' && filereadable(swap)
            call delete(swap)
        endif
    endfor

    MemoList
  endfunction

endif

"}}}
" Vim-altr "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-altr'))

  nnoremap <silent><C-w>a :<C-u>call altr#forward()<CR>
  nnoremap <silent><C-w>A :<C-u>call altr#back()<CR>

  let s:bundle = neobundle#get("vim-altr")
  function! s:bundle.hooks.on_source(bundle)
      " for vimrc
      if has('mac')
          call altr#define('.vimrc', '.gvimrc', '.mac.vimrc', '.mac.gvimrc')
      elseif has('win32') || has('win64')
          call altr#define('_vimrc', '_gvimrc')
      elseif has('unix')
          call altr#define('.vimrc', '.gvimrc', '.linux.vimrc', '.linux.gvimrc')
      endif
      call altr#define('dotfiles/vimrc', 'dotfiles/gvimrc',
                  \    'dotfiles/mac.vimrc', 'dotfiles/mac.gvimrc',
                  \    'dotfiles/linux.vimrc', 'dotfiles/linux.gvimrc')
      " ruby TDD
      call altr#define('%.rb', 'spec/%_spec.rb')
      " Rails TDD
      call altr#define('app/models/%.rb', 'spec/models/%_spec.rb', 'spec/factories/%s.rb')
      call altr#define('app/controllers/%.rb', 'spec/controllers/%_spec.rb')
      call altr#define('app/helpers/%.rb', 'spec/helpers/%_spec.rb')
  endfunction
  unlet s:bundle

endif

" }}}
" Vim-numberstar {{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-numberstar'))

  nnoremap <silent><expr>*  numberstar#key('*')
  nnoremap <silent><expr>#  numberstar#key('#')
  nnoremap <silent><expr>g* numberstar#key('g*')
  nnoremap <silent><expr>#* numberstar#key('#*')

endif

" }}}
" TweetVim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/tweetvim'))

  nnoremap <silent><Leader>tw :<C-u>TweetVimUserStream<CR>
  nnoremap <silent><Leader>th :<C-u>TweetVimHomeTimeline<CR>
  nnoremap <silent><Leader>tm :<C-u>TweetVimMentions<CR>
  nnoremap <silent><Leader>ts :<C-u>TweetVimSay<CR>
  nnoremap <silent><Leader>tu :<C-u>TweetVimUserTimeline<Space>
  let s:zenkaku_no_highlight_filetypes += ['tweetvim', 'tweetvim_say']

  " TweetVim
  let s:bundle = neobundle#get("TweetVim")
  function! s:bundle.hooks.on_source(bundle)
    " TweetVim
    if has('gui_running')
        let g:tweetvim_display_icon = 1
    endif
    let g:tweetvim_tweet_per_page = 60
    let g:tweetvim_async_post = 1
    let g:tweetvim_expand_t_co = 1

    command -nargs=1 TweetVimFavorites call tweetvim#timeline('favorites', <q-args>)

    "
    AutocmdFT tweetvim     setlocal nonumber
    "
    "
    AutocmdFT tweetvim_say nnoremap <buffer><silent><C-g>    :<C-u>q!<CR>
    AutocmdFT tweetvim_say inoremap <buffer><silent><C-g>    <C-o>:<C-u>q!<CR><Esc>
    "
    AutocmdFT tweetvim_say inoremap <buffer><silent><C-l>    <C-o>:<C-u>call unite#sources#tweetvim_tweet_history#start()<CR>
    " <Tab>
    AutocmdFT tweetvim_say iunmap   <buffer><Tab>
    "
    AutocmdFT tweetvim     nnoremap <buffer><Leader>s        :<C-u>TweetVimSay<CR>
    AutocmdFT tweetvim     nmap     <buffer>c                <Plug>(tweetvim_action_in_reply_to)
    AutocmdFT tweetvim     nnoremap <buffer>t                :<C-u>Unite tweetvim -no-start-insert -quick-match<CR>
    AutocmdFT tweetvim     nmap     <buffer><Leader>F        <Plug>(tweetvim_action_remove_favorite)
    AutocmdFT tweetvim     nmap     <buffer><Leader>d        <Plug>(tweetvim_action_remove_status)
    "
    AutocmdFT tweetvim     nmap     <buffer><Tab>            <Plug>(tweetvim_action_reload)
    AutocmdFT tweetvim     nmap     <buffer><silent>gg       gg<Plug>(tweetvim_action_reload)
    "
    AutocmdFT tweetvim     nmap     <buffer>f                <Plug>(tweetvim_action_page_next)
    AutocmdFT tweetvim     nmap     <buffer>b                <Plug>(tweetvim_action_page_previous)
    " favstar
    AutocmdFT tweetvim     nnoremap <buffer><Leader><Leader> :<C-u>call <SID>tweetvim_favstar()<CR>
    AutocmdFT tweetvim     nnoremap <buffer><Leader>u        :<C-u>call <SID>tweetvim_open_home()<CR>
    AutocmdFT tweetvim     nnoremap <buffer><Space><Space>   :<C-u>OpenBrowser https://twitter.com/i/connect<CR>
    "
    AutocmdFT tweetvim     nnoremap <buffer><silent>j        :<C-u>call <SID>tweetvim_vertical_move("j")<CR>zz
    AutocmdFT tweetvim     nnoremap <buffer><silent>k        :<C-u>call <SID>tweetvim_vertical_move("k")<CR>zz
    "
    AutocmdFT tweetvim     nnoremap <silent><buffer>gm       :<C-u>TweetVimMentions<CR>
    AutocmdFT tweetvim     nnoremap <silent><buffer>gh       :<C-u>TweetVimHomeTimeline<CR>
    AutocmdFT tweetvim     nnoremap <silent><buffer>gu       :<C-u>TweetVimUserTimeline<Space>
    AutocmdFT tweetvim     nnoremap <silent><buffer>gp       :<C-u>TweetVimUserTimeline Linda_pp<CR>
    AutocmdFT tweetvim     nnoremap <silent><buffer>gf       :<C-u>call <SID>open_favstar('')<CR>
    "
    AutocmdFT tweetvim     nunmap   <buffer>ff
    AutocmdFT tweetvim     nunmap   <buffer>bb
    "
    AutocmdFT tweetvim     nnoremap <buffer><Leader>au :<C-u>TweetVimAutoUpdate<CR>
    AutocmdFT tweetvim     nnoremap <buffer><Leader>as :<C-u>TweetVimStopAutoUpdate<CR>

    function! s:tweetvim_vertical_move(cmd) "{{{
      execute "normal! ".a:cmd
      let end = line('$')
      while getline('.') =~# '^[-~]\+$' && line('.') != end
          execute "normal! ".a:cmd
      endwhile
      "
      let line = line('.')
      if line == end
          call feedkeys("\<Plug>(tweetvim_action_page_next)")
      elseif line == 1
          call feedkeys("\<Plug>(tweetvim_action_page_previous)")
      endif
    endfunction "}}}

    function! s:tweetvim_favstar() "{{{
      let screen_name = matchstr(getline('.'),'^\s\zs\w\+')
      let route = empty(screen_name) ? 'me' : 'users/'.screen_name

      execute "OpenBrowser http://fr.favstar.fm/".route
    endfunction "}}}

    function! s:open_favstar(user)
      if empty(a:user)
          OpenBrowser http://fr.favstar.fm/me
      else
          execute "OpenBrowser http://fr.favstar.fm/users/" . a:user
      endif
    endfunction
    command! OpenFavstar call <SID>open_favstar(expand('<cword>'))

    function! s:tweetvim_open_home()
      let username = expand('<cword>')
      if username =~# '^[a-zA-Z0-9_]\+$'
          execute "OpenBrowser https://twitter.com/" . username
      endif
    endfunction

    " Tweet update"{{{
    let s:tweetvim_update_interval_seconds = 60
    let s:tweetvim_timestamp = localtime()
    function! s:tweetvim_autoupdate()
      let current = localtime()
      if current - s:tweetvim_timestamp > s:tweetvim_update_interval_seconds
          call feedkeys("\<Plug>(tweetvim_action_reload)")
          let s:tweetvim_timestamp = current
      endif
      call feedkeys(mode() ==# 'i' ? "\<C-g>\<Esc>" : "g\<Esc>", 'n')
    endfunction

    function! s:tweetvim_setup_autoupdate()
      augroup vimrc-tweetvim-autoupdate
          autocmd!
          autocmd CursorHold * call <SID>tweetvim_autoupdate()
      augroup END
    endfunction
    command! -nargs=0 TweetVimAutoUpdate call <SID>tweetvim_setup_autoupdate()
    command! -nargs=0 TweetVimStopAutoUpdate autocmd! vimrc-tweetvim-autoupdate

    SourceIfExist($HOME.'/.tweetvimrc')

  endfunction
  unlet s:bundle
  "}}}

endif

"}}}
" Vim-window-adjuster "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/vim-window-adjuster'))

  nnoremap <silent><C-w>r :<C-u>AdjustWindowWidth --margin=1 --direction=shrink<CR>
endif

"}}}
" Sudo.vim "{{{
" ----------------------------------------------
if isdirectory(expand(s:neobundle_dir.'/sudo.vim'))

endif

" }}}

"}}}


"}}}


" Vim: set ft=vim sw=2 ts=2 sts=2 ff=unix fenc=utf-8:
