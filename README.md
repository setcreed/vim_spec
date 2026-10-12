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
- 保留 `.vim` 中其他文件，包括已有插件和自定义主题。

不安装 Homebrew、全局开发工具，不上传本地编辑历史。插件来自各自 GitHub 仓库，下载版本取安装当时的上游版本；此项目不锁定插件版本。

首次安装前插件尚未下载时，配置使用 Vim 默认配色；安装完成后重新打开 Vim 加载 gruvbox。如果已有同名本地 gruvbox 配色，Vim 优先使用该文件。

网络中断后可重新运行安装脚本。脚本失败时不会输出安装完成；已建立的链接和已下载插件会保留，方便重试。

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

`F5` 沿用原配置的格式化实现；使用前先保存文件，文件路径应避免空格或 Shell 特殊字符。Go 使用 gofmt，Python 使用 black，JavaScript／TypeScript 使用 prettier。vim-go 的保存格式化依赖 goimports。上述工具未安装时，相关能力不能完整使用，但基础编辑和文件树不依赖它们。Mac 可能需要配合 Fn 键触发功能键。

提交配置修改前：

```bash
cd ~/project/vim_spec
bash -n install.sh tests/test-install.sh
bash tests/test-install.sh
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
