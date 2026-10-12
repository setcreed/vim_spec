# macOS Vim 配置迁移

将现有 Vim 配置放进私有仓库。新 Mac 获取仓库后，运行一次安装脚本，即可配置 Vim 和下载插件。

仓库：https://github.com/setcreed/vim_spec

## 新 Mac 安装

需要 Vim、Git 和可访问 GitHub 的网络。先运行 `vim --version` 和 `git --version`。如果 macOS 提示缺少命令行开发工具，执行 `xcode-select --install`，完成系统安装后继续。

### 已配置 GitHub SSH 的电脑

```bash
mkdir -p ~/project
git clone git@github.com:setcreed/vim_spec.git ~/project/vim_spec
bash ~/project/vim_spec/install.sh
```

重新打开 Vim 即可。仓库必须保留在原位置，配置通过软链接指向仓库文件。迁移仓库位置后，在新位置重新执行 `bash install.sh`。

### 新电脑暂时没有配置 GitHub SSH

在浏览器登录 GitHub，打开上面的私有仓库，选择 **Code → Download ZIP**。解压到 `~/project/vim_spec`，然后执行：

```bash
bash ~/project/vim_spec/install.sh
```

ZIP 方式也能安装，但没有 Git 历史；需要持续同步时，再配置 GitHub 身份认证并使用克隆方式。

如果已经安装 GitHub CLI，也可以执行：

```bash
gh auth login
gh repo clone setcreed/vim_spec ~/project/vim_spec
bash ~/project/vim_spec/install.sh
```

## 安装脚本做什么

- 将 `~/.vimrc` 链接到仓库的 `vimrc`。
- 将 `~/.vim/autoload/plug.vim` 链接到随仓库提供的 vim-plug。
- 将原有同名文件或链接移动到 `~/.vim/config-backups/时间戳.随机后缀/`；输出实际备份位置。已有链接指向当前仓库时直接复用。
- 创建备份、交换文件和持久撤销目录，自动执行 `PlugInstall --sync` 并检查插件是否下载完成。
- 安装完成后检查可选格式化工具及 Universal Ctags，显示可用路径或安装提示；缺少可选工具不阻止基础安装。
- 每次保存独立安装日志到 `~/.vim/install-logs/`。Vim 启动或插件安装失败时，显示日志路径及最后 40 行；插件下载失败还保留下载详情文件，便于定位网络错误。
- 保留 `.vim` 中其他文件，包括已有插件和自定义主题。

不安装 Homebrew、全局开发工具，不上传本地编辑历史。插件来自各自 GitHub 仓库，下载版本取安装当时的上游版本；此项目不锁定插件版本。

首次安装前插件尚未下载时，配置使用 Vim 默认配色；安装完成后重新打开 Vim 加载 gruvbox。如果已有同名本地 gruvbox 配色，Vim 优先使用该文件。

网络中断后可重新运行安装脚本。脚本失败时不会输出安装完成；已建立的链接和已下载插件会保留，方便重试。

只检查当前终端能否找到可选工具，不安装或修改配置：

```bash
bash ~/project/vim_spec/scripts/check-tools.sh
```

工具检查按当前 PATH 判断，不扫描所有业务项目；提示缺少全局 Prettier 时，已经安装项目内 Prettier 的文件仍可格式化。

只安装配置、暂不联网下载插件：

```bash
bash ~/project/vim_spec/install.sh --skip-plugins
```

## 日常使用和同步

默认保留绝对行号，关闭相对行号。临时关闭全部行号：

```vim
:set nonumber norelativenumber
```

永久关闭时，将仓库 `vimrc` 中的 `set number` 改成 `set nonumber`。

| 快捷键 | 功能 |
| --- | --- |
| `jj` | 插入模式退出到普通模式 |
| `Esc` | 清除搜索高亮 |
| `Ctrl-h/j/k/l` | 切换窗口 |
| `F3` | 文件树 |
| `F8` | 代码大纲，需要 Universal Ctags |
| `F5` | 调用已有格式化命令，需要对应外部工具 |
| `Space`，然后 `w` | 保存当前文件 |
| `Space`，然后 `f` | 格式化当前文件，与 F5 相同 |
| `Space`，然后 `e`／`o` | 文件树／代码大纲，与 F3／F8 相同 |
| `Space`，然后 `n` | 切换当前窗口的全部行号；开启时使用绝对行号 |
| `Space`，然后 `h` | 清除搜索高亮 |
| 可视模式下 `Space`，然后 `y` | 将选中文字复制到 macOS 剪贴板，需要 Vim 的 `+clipboard` 支持 |
| 普通模式下 `Space`，然后 `p` | 从 macOS 剪贴板粘贴，需要 Vim 的 `+clipboard` 支持 |

空格前缀在普通模式下使用，两个键依次按，不需要同时按。原有 `jj`、功能键和窗口切换键保留。

格式化会先检查文件类型、文件状态及工具是否存在，然后保存当前编辑，调用外部工具；成功后重新加载结果并恢复滚动位置，失败时提示并保留当前缓冲区。工具已经运行但失败时，格式化前的编辑已保存到磁盘；外部工具自身可能改动文件，配置不自动回滚。未命名、只读、不可修改或特殊缓冲区会直接提示。路径中的空格和 Shell 特殊字符会正确转义。

Go 手动格式化优先使用 goimports 整理 import 并格式化，没有它时回退到 gofmt。F5 保存编辑时暂时关闭 vim-go 的保存格式化钩子，保存结束后恢复，随后只调用一次外部格式化工具；普通保存仍在启动时检测到 goimports 后自动格式化。手动与自动格式化均优先使用 PATH 中的工具，避免 vim-go 优先使用另一份 GOPATH/bin 工具。安装工具后重新打开 Vim。

Python 使用 black。JavaScript／TypeScript／JSX／TSX／JSON 从当前文件目录向上查找可执行的 `node_modules/.bin/prettier`，找到后使用该项目版本；查找在 Git 仓库边界或文件系统根目录停止，找不到时回退到 PATH 中的全局 prettier。不会通过 npx 自动下载工具。

Prettier 在距离文件最近的 `package.json` 或 `.prettierignore` 所在目录运行；未找到这些标记时，使用本地工具所在项目目录或文件目录。这样从其他目录启动 Vim，也能使用项目的忽略规则，不改变 Vim 本身的工作目录。项目可执行文件属于该项目的代码，使用前应信任当前项目。

语言缩进：Go 使用 Tab，显示宽度为 4；Python 使用 4 个空格；前端、JSON、HTML、CSS 和 SCSS 使用 2 个空格。

## F5／F8 需要的工具和安装方法

以下命令在 iTerm2 中执行。按自己使用的语言安装即可，不需要全部安装。安装脚本不会执行这些全局安装命令。

| 功能 | 文件类型 | 外部工具 | macOS 安装命令 |
| --- | --- | --- | --- |
| F5／`Space f` 格式化 | Go | 优先 goimports，缺失时用随 Go 提供的 gofmt | 没有 Go 时执行 `brew install go`；goimports 安装见下文 |
| F5／`Space f` 格式化 | Python | Black | `brew install black` |
| F5／`Space f` 格式化 | JS／TS／JSX／TSX／JSON | 优先项目内 Prettier，其次全局版本 | 项目内 `npm install --save-dev --save-exact prettier`；全局 `brew install prettier` |
| F8／`Space o` 代码大纲 | Tagbar 支持的语言 | Universal Ctags | `brew install universal-ctags` |

已安装 Homebrew 时，Python、前端格式化和代码大纲可以一起准备：

```bash
brew install black prettier universal-ctags
```

已有 Go 时不要重复安装；通过 `command -v gofmt` 检查即可。Homebrew 会为 Black 和 Prettier 安装所需的 Python／Node 依赖。安装方式分别见 [Go](https://formulae.brew.sh/formula/go)、[Black](https://formulae.brew.sh/formula/black)、[Prettier](https://formulae.brew.sh/formula/prettier) 和 [Universal Ctags](https://formulae.brew.sh/formula/universal-ctags) 的官方 Formula 页面。

没有 Homebrew 时，先按 [Homebrew 官方安装说明](https://docs.brew.sh/Installation) 安装，并完成安装器提示的 `brew shellenv` 配置；Apple Silicon 默认目录是 `/opt/homebrew`，Intel 默认是 `/usr/local`。

**F8 不可使用 macOS 自带的 BSD ctags。** 安装完成后执行：

```bash
command -v ctags
ctags --version
```

版本输出应包含 `Universal Ctags`。如果仍指向 `/usr/bin/ctags`，先在当前 iTerm2 会话中执行以下命令，再重新打开 Vim：

```bash
export PATH="$(brew --prefix)/bin:$PATH"
rehash
```

永久生效应按 Homebrew 安装器提示将 `brew shellenv` 加入 `~/.zprofile`；不要覆盖已有 Shell 配置。BSD ctags 不兼容 Tagbar，见 [Tagbar 官方依赖说明](https://github.com/preservim/tagbar)。

可选：安装 goimports 后，F5 优先使用它，普通保存也自动整理 import 和格式化；没有它时 F5 使用 gofmt：

```bash
go install golang.org/x/tools/cmd/goimports@latest
```

默认安装到 `$(go env GOPATH)/bin`，需要将此目录加入 PATH。若设置了 GOBIN，则以 `go env GOBIN` 为准。默认情况下当前会话可以执行：

```bash
export PATH="$(go env GOPATH)/bin:$PATH"
```

需要持久生效时，将对应 PATH 设置合并到 `~/.zshrc`，再重新打开 iTerm2 和 Vim。安装命令见 [goimports 官方文档](https://pkg.go.dev/golang.org/x/tools/cmd/goimports)。

按已安装工具执行检查：

```bash
command -v gofmt black prettier ctags goimports
black --version
prettier --version
ctags --version
```

gofmt 没有 `--version` 参数，检查其路径即可。在 Vim 内还可以执行 `:echo executable('black')`，结果为 `1` 表示当前 Vim 的 PATH 能找到它；其他工具同理。安装后重新打开 Vim，在对应类型的文件里按 F5 或 F8 检查功能。F8 依赖的 Tagbar 插件由项目安装脚本安装；不需要先手动生成 tags 文件。

## iTerm2 使用建议

- 默认关闭 Vim 鼠标接管，方便在终端拖选文字并用 `Command + C` 复制。需要在 Vim 中用鼠标定位时，执行 `:set mouse=a`；恢复终端选择则执行 `:set mouse=`。终端拖选只复制屏幕上可见的内容，复制完整代码段优先使用可视模式下的 `Space y`。
- macOS 剪贴板只通过显式快捷键操作，普通 `y`、`d` 保持 Vim 寄存器行为，避免普通删除覆盖系统剪贴板。可运行 `vim --version` 检查 `+clipboard`；没有此支持时相关快捷键不启用。
- 保持 `Command + C`／`Command + V` 由 iTerm2 处理。Vim 的剪贴板快捷键无需绑定 Command 键。
- 如果需要用 Option 作为 Alt，在 **Settings → Profiles → 当前 Profile → Keys → General** 中将 Left Option Key 设为 `Esc+`，Right Option Key 可以保留 Normal 以输入特殊字符。本配置没有额外绑定 Alt 组合键，因此这项是可选设置，参考 [iTerm2 官方按键文档](https://iterm2.com/documentation-preferences-profiles-keys.html)。
- F3／F5／F8 被 macOS 功能键截获时，可以使用 Fn 组合键，也可以直接使用 `Space e`／`Space f`／`Space o`。
- Vim 支持时启用真彩色，不硬编码 `TERM` 或旧式终端转义序列。按键编码等待时间为 100 毫秒，`jj` 等映射等待时间为 750 毫秒；远程高延迟连接出现特殊键识别问题时，可以调高 `ttimeoutlen`。参数含义参考 [Vim 选项文档](https://vimhelp.org/options.txt.html)。

安装脚本不修改 iTerm2 Profile、Shell 配置或系统键盘设置。

提交配置修改前：

```bash
cd ~/project/vim_spec
bash -n install.sh scripts/check-tools.sh tests/test-install.sh tests/test-format.sh tests/test-diagnostics.sh
bash tests/test-install.sh
bash tests/test-format.sh
bash tests/test-diagnostics.sh
git add vimrc
git commit -m 'feat: 更新 Vim 编辑设置以同步到其他电脑'
git push
```

另一台电脑更新配置：

```bash
cd ~/project/vim_spec
git pull --ff-only
bash install.sh
```

重新打开 Vim 加载更新。不要在未处理本地修改时覆盖配置。安装脚本不会自动提交、推送或执行 `PlugUpdate`；已有插件保持原版本。需要更新插件时，在 Vim 内执行 `:PlugUpdate`。

## 恢复安装前的文件

找到安装时输出的备份目录。退出 Vim 后，将当前配置链接重命名保存，再将备份文件移回原位置。下面以 `.vimrc` 为例；将第一行替换成实际备份目录，并确认备份中确实存在 `vimrc`：

```bash
backup_dir="$HOME/.vim/config-backups/实际备份目录名"
if [ -e "$backup_dir/vimrc" ] || [ -L "$backup_dir/vimrc" ]; then
    mv -n "$HOME/.vimrc" "$HOME/.vimrc.vim-spec-link"
    if [ ! -e "$HOME/.vimrc" ] && [ ! -L "$HOME/.vimrc" ]; then
        mv "$backup_dir/vimrc" "$HOME/.vimrc"
    fi
fi
```

`plug.vim` 同理：备份文件是备份目录内的 `plug.vim`，原位置是 `~/.vim/autoload/plug.vim`。初次安装前不存在的文件没有备份；需要停用时，可将相应链接重命名保留。恢复操作不会删除下载的插件、撤销历史或其他用户文件。

## 项目维护

规则见 `AGENTS.md`，进度及验证记录见 `ROADMAP.md`。临时验证数据位于 `.tmp/`，不进入仓库。通过 `VIM_SPEC_HOME=/绝对路径` 可将安装目标切换到隔离目录；正常使用不设置此变量。

`vendor/plug.vim` 复制自本机正在使用的 vim-plug，保留文件内完整 MIT 许可，不代表最新上游版本。插件安装行为参考 [vim-plug 官方说明](https://github.com/junegunn/vim-plug)。gruvbox 通过 [上游插件仓库](https://github.com/morhetz/gruvbox) 安装，不将原本本地主题副本纳入仓库。
