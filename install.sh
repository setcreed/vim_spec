#!/bin/bash
set -euo pipefail
trap 'echo "安装失败。请检查网络、Vim 报错和文件权限，然后重新运行脚本。" >&2' ERR

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
target_home="${VIM_SPEC_HOME:-$HOME}"
skip_plugins=false
case "${1:-}" in
    '') ;;
    --skip-plugins) skip_plugins=true ;;
    *) echo '用法：bash install.sh [--skip-plugins]' >&2; exit 2 ;;
esac
if [ "$#" -gt 1 ]; then
    echo '参数过多。' >&2
    exit 2
fi
case "$target_home" in
    /*) ;;
    *) echo 'VIM_SPEC_HOME 必须是绝对路径。' >&2; exit 2 ;;
esac
for tool in vim git; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "缺少命令：$tool。请先安装，再运行脚本。" >&2
        exit 1
    fi
done

mkdir -p "$target_home/.vim/autoload"
backup_dir=''
link_file() {
    local source="$1" destination="$2" name="$3"
    if [ -L "$destination" ] && [ "$(readlink "$destination")" = "$source" ]; then
        return
    fi
    if [ -e "$destination" ] || [ -L "$destination" ]; then
        if [ -d "$destination" ] && [ ! -L "$destination" ]; then
            echo "目标是目录，停止安装：$destination" >&2
            exit 1
        fi
        if [ -z "$backup_dir" ]; then
            mkdir -p "$target_home/.vim/config-backups"
            backup_dir="$(mktemp -d "$target_home/.vim/config-backups/$(date +%Y%m%d-%H%M%S).XXXXXX")"
            chmod 700 "$backup_dir"
            echo "已有配置备份：$backup_dir"
        fi
        mv "$destination" "$backup_dir/$name"
    fi
    ln -s "$source" "$destination"
}

link_file "$repo_dir/vendor/plug.vim" "$target_home/.vim/autoload/plug.vim" plug.vim
link_file "$repo_dir/vimrc" "$target_home/.vimrc" vimrc

if [ "$skip_plugins" = true ]; then
    vim -N -i NONE -u "$target_home/.vimrc" -es '+qa'
    echo '配置已安装；插件安装已跳过。稍后运行 bash install.sh 安装插件。'
else
    vim -N -i NONE -u "$target_home/.vimrc" -es \
        '+PlugInstall --sync' -S "$repo_dir/scripts/check-plugins.vim" '+qa'
    echo '配置和插件安装完成。重新打开 Vim 即可使用。'
fi
