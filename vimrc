" ===================== Vim 基础配置 =====================
set nocompatible
" VIM_SPEC_HOME 仅用于隔离安装和测试，默认使用当前用户的主目录。
let s:home = empty($VIM_SPEC_HOME) ? expand('~') : $VIM_SPEC_HOME
let s:vim_dir = s:home . '/.vim'
if index(split(&runtimepath, ','), s:vim_dir) < 0
    execute 'set runtimepath^=' . escape(s:vim_dir, ' ,\\')
endif

set encoding=utf-8
set fileencodings=utf-8,gbk
set termencoding=utf-8

set number                  " 绝对行号
set norelativenumber
set cursorline              " 高亮当前行
set ruler                   " 右下角光标位置
set showcmd
set showmode
set laststatus=2

" iTerm2：鼠标交给终端选中文字，Esc 与组合映射分别设置等待时间。
set mouse=
set timeout timeoutlen=750
set ttimeout ttimeoutlen=100
set backspace=indent,eol,start
set wildmenu
set wildmode=longest:full,full
set splitbelow splitright

set expandtab
set tabstop=4
set softtabstop=4
set shiftwidth=4
set autoindent
set smartindent

set scrolloff=5
set sidescrolloff=5
set nowrap                  " 代码不自动折行（写代码推荐）

" 搜索
set ignorecase
set smartcase
set incsearch
set hlsearch
nnoremap <silent> <Esc> :nohlsearch<CR><Esc>

" 备份 & 持久撤销
set backup
let &backupdir = s:vim_dir . '/backup//'
let &directory = s:vim_dir . '/swap//'
set undofile
let &undodir = s:vim_dir . '/undo//'
call mkdir(s:vim_dir . '/backup', 'p', 0700)
call mkdir(s:vim_dir . '/swap', 'p', 0700)
call mkdir(s:vim_dir . '/undo', 'p', 0700)

" ===================== 快捷键映射 =====================
let mapleader = ' '
inoremap jj <Esc>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <silent> <leader>w :update<CR>
nnoremap <silent> <leader>f :call FormatCode()<CR>
nnoremap <silent> <leader>n :call ToggleLineNumbers()<CR>
nnoremap <silent> <leader>h :nohlsearch<CR>
if has('clipboard')
    " 显式使用系统剪贴板，普通删除和复制保留 Vim 原有寄存器行为。
    nnoremap <leader>y "+y
    xnoremap <leader>y "+y
    nnoremap <leader>p "+p
endif

function! ToggleLineNumbers() abort
    if &l:number || &l:relativenumber
        setlocal nonumber norelativenumber
    else
        setlocal number norelativenumber
    endif
endfunction

" F5 快速格式化代码
nnoremap <F5> :call FormatCode()<CR>

function! s:FindPrettier(directory) abort
    let l:dir = a:directory
    let l:project_dir = ''
    while 1
        if empty(l:project_dir) && (filereadable(l:dir . '/package.json')
            \ || filereadable(l:dir . '/.prettierignore'))
            let l:project_dir = l:dir
        endif
        let l:tool = l:dir . '/node_modules/.bin/prettier'
        if executable(l:tool)
            return [l:tool, empty(l:project_dir) ? l:dir : l:project_dir]
        endif
        let l:parent = fnamemodify(l:dir, ':h')
        if l:parent ==# l:dir || isdirectory(l:dir . '/.git') || filereadable(l:dir . '/.git')
            break
        endif
        let l:dir = l:parent
    endwhile
    return ['prettier', empty(l:project_dir) ? a:directory : l:project_dir]
endfunction

function! FormatCode() abort
    if &buftype !=# '' || empty(expand('%')) || &readonly || !&modifiable
        echomsg '格式化需要已命名、可写的普通文件。'
        return 0
    endif
    let l:formatters = {
        \ 'go': [executable('goimports') ? 'goimports' : 'gofmt', '-w'],
        \ 'python': ['black'],
        \ 'javascript': ['prettier', '--write'],
        \ 'javascriptreact': ['prettier', '--write'],
        \ 'typescript': ['prettier', '--write'],
        \ 'typescriptreact': ['prettier', '--write'],
        \ 'json': ['prettier', '--write'],
        \ }
    let l:command = get(l:formatters, &filetype, [])
    if empty(l:command)
        echomsg '当前文件类型没有配置格式化工具：' . &filetype
        return 0
    endif
    let l:format_dir = expand('%:p:h')
    if l:command[0] ==# 'prettier'
        let [l:command[0], l:format_dir] = s:FindPrettier(l:format_dir)
    endif
    if !executable(l:command[0])
        echomsg '请先安装格式化工具：' . l:command[0]
        return 0
    endif
    let l:view = winsaveview()
    " 手动格式化时避免 :update 再触发 vim-go 的保存格式化。
    let l:go_fmt = get(g:, 'go_fmt_autosave', 0)
    let l:go_imports = get(g:, 'go_imports_autosave', 0)
    try
        if &filetype ==# 'go'
            let g:go_fmt_autosave = 0
            let g:go_imports_autosave = 0
        endif
        update
    finally
        if &filetype ==# 'go'
            let g:go_fmt_autosave = l:go_fmt
            let g:go_imports_autosave = l:go_imports
        endif
    endtry
    let l:output = system('cd ' . shellescape(l:format_dir) . ' && '
        \ . join(map(copy(l:command), 'shellescape(v:val)'), ' ')
        \ . ' ' . shellescape(expand('%:p')))
    if v:shell_error != 0
        echomsg '格式化失败，保留当前缓冲区：' . l:output
        return 0
    endif
    silent edit
    call winrestview(l:view)
    return 1
endfunction

" ===================== vim-plug 插件区 =====================
call plug#begin(s:vim_dir . '/plugged')
" 迁移时自动安装原先放在本地的配色。
Plug 'morhetz/gruvbox'
" 文件树
Plug 'preservim/nerdtree'
" 底部状态栏（和starship搭配）
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
" 括号引号快速修改
Plug 'tpope/vim-surround'
" 自动补全括号
Plug 'jiangmiao/auto-pairs'
" 快速注释
Plug 'tpope/vim-commentary'
" 代码大纲
Plug 'preservim/tagbar'
" Go语言增强
Plug 'fatih/vim-go'
" JS/TS 语法增强
Plug 'pangloss/vim-javascript'
Plug 'HerringtonDarkholme/yats.vim'
call plug#end()

" ===================== 语言缩进适配 =====================
" 插件初始化后设置；重新加载配置不会累积自动命令。
augroup VimSpecIndent
    autocmd!
    autocmd FileType go setlocal noexpandtab tabstop=4 shiftwidth=4 softtabstop=0
    autocmd FileType python setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
    autocmd FileType javascript,javascriptreact,typescript,typescriptreact,json,html,css,scss setlocal expandtab tabstop=2 shiftwidth=2 softtabstop=2
augroup END

" ===================== 插件单独配置 =====================
" NERDTree 快捷键 F3
nnoremap <F3> :NERDTreeToggle<CR>
nnoremap <silent> <leader>e :NERDTreeToggle<CR>

" tagbar F8
nnoremap <F8> :TagbarToggle<CR>
nnoremap <silent> <leader>o :TagbarToggle<CR>

" NERDTree 配置
let g:NERDTreeShowHidden = 1         " 显示隐藏文件 .git .env
let g:NERDTreeMouseMode = 2          " 支持鼠标点击目录
let g:NERDTreeIgnore = ['node_modules','dist'] " 忽略这些目录，不显示

" airline主题
" let g:airline_theme='gruvbox2'

" vim-go 自动运行goimports
let g:go_fmt_command = "goimports"
let g:go_fmt_autosave = executable('goimports')
let g:go_imports_autosave = 0
" 保存与 F5 使用同一 PATH 中的工具，避免 GOPATH/bin 抢占不同版本。
let g:go_search_bin_path_first = 0
let g:go_auto_type_info = 1

" 配色
syntax enable
filetype plugin indent on
set background=dark
if has('termguicolors')
    set termguicolors
endif
" 首次安装时主题尚未下载，不阻止插件安装。
if !empty(globpath(&runtimepath, 'colors/gruvbox.vim'))
    colorscheme gruvbox
endif


let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#git#enabled = 1
