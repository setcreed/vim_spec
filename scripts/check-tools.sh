#!/bin/bash
set -eu
echo '可选工具检查，缺失工具不会阻止基础配置安装：'
for tool in gofmt goimports black prettier; do
    if tool_path="$(command -v "$tool")"; then
        echo "可用：$tool -- $tool_path"
    else
        case "$tool" in
            gofmt) hint='brew install go' ;;
            goimports) hint='go install golang.org/x/tools/cmd/goimports@latest，并将安装目录加入 PATH' ;;
            black) hint='brew install black' ;;
            prettier) hint='项目内 npm install --save-dev --save-exact prettier，或 brew install prettier' ;;
        esac
        echo "提示：未找到 ${tool}；${hint}。"
    fi
done
if tool_path="$(command -v ctags)"; then
    version="$("$tool_path" --version 2>&1 || true)"
    case "$version" in
        *'Universal Ctags'*) echo "可用：Universal Ctags -- $tool_path" ;;
        *) echo "提示：$tool_path 不是 Universal Ctags，F8 建议安装 brew install universal-ctags，并检查 PATH。" ;;
    esac
else
    echo '提示：未找到 ctags；F8 需要 brew install universal-ctags。'
fi
echo '项目内的 Prettier 由 F5 按当前文件所在项目查找，以上 PATH 检查不扫描各个项目。'
