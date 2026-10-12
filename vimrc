" ===================== Vim 基础配置 =====================
set nocompatible
" VIM_SPEC_HOME 仅用于隔离安装和测试，默认使用当前用户的主目录。
let s:home = empty($VIM_SPEC_HOME) ? expand('~') : $VIM_SPEC_HOME
let s:vim_dir = s:home . '/.vim'
execute 'set runtimepath^=' . escape(s:vim_dir, ' ,\\')

set encoding=utf-8
set fileencodings=utf-8,gbk
set termencoding=utf-8

set number                  " 绝对行号
" set relativenumber          " 相对行号，方便跳转
set cursorline              " 高亮当前行
set ruler                   " 右下角光标位置
set showcmd
set showmode

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

" ===================== 语言缩进适配 =====================
autocmd FileType go setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd FileType python setlocal tabstop=4 shiftwidth=4 softtabstop=4
autocmd FileType javascript,typescript,json,jsx,tsx setlocal tabstop=2 shiftwidth=2 softtabstop=2
autocmd FileType html,css,scss setlocal tabstop=2 shiftwidth=2 softtabstop=2

" ===================== 快捷键映射 =====================
inoremap jj <Esc>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" F5 快速格式化代码
nnoremap <F5> :call FormatCode()<CR>
function! FormatCode()
    if &filetype == 'go'
        :!gofmt -w %
    elseif &filetype == 'python'
        :!black %
    elseif &filetype == 'javascript' || &filetype == 'typescript'
        :!prettier --write %
    endif
    edit
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

" ===================== 插件单独配置 =====================
" NERDTree 快捷键 F3
nnoremap <F3> :NERDTreeToggle<CR>

" tagbar F8
nnoremap <F8> :TagbarToggle<CR>

" NERDTree 配置
let g:NERDTreeShowHidden = 1         " 显示隐藏文件 .git .env
let g:NERDTreeMouseMode = 2          " 支持鼠标点击目录
let g:NERDTreeIgnore = ['node_modules','dist'] " 忽略这些目录，不显示

" airline主题
" let g:airline_theme='gruvbox2'

" vim-go 自动运行goimports
let g:go_fmt_command = "goimports"
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
