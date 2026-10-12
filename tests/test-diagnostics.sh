#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
mkdir -p "$repo_dir/.tmp/tests"
test_dir="$(mktemp -d "$repo_dir/.tmp/tests/diagnostics.XXXXXX")"
mkdir -p "$test_dir/bin" "$test_dir/offline-bin"
PATH="$test_dir/bin" /bin/bash "$repo_dir/scripts/check-tools.sh" > "$test_dir/missing.log"
rg -q '未找到 black' "$test_dir/missing.log"
rg -q '未找到 prettier' "$test_dir/missing.log"
rg -q '未找到 ctags' "$test_dir/missing.log"
cat > "$test_dir/bin/ctags" <<'SH'
#!/bin/bash
echo 'usage: BSD ctags' >&2
exit 1
SH
chmod +x "$test_dir/bin/ctags"
PATH="$test_dir/bin" /bin/bash "$repo_dir/scripts/check-tools.sh" > "$test_dir/bsd.log"
rg -q '不是 Universal Ctags' "$test_dir/bsd.log"
cat > "$test_dir/bin/ctags" <<'SH'
#!/bin/bash
echo 'Universal Ctags test'
SH
for tool in gofmt goimports black prettier; do
    cp "$test_dir/bin/ctags" "$test_dir/bin/$tool"
done
PATH="$test_dir/bin" /bin/bash "$repo_dir/scripts/check-tools.sh" > "$test_dir/available.log"
rg -q '可用：Universal Ctags' "$test_dir/available.log"
rg -q '可用：black' "$test_dir/available.log"
cat > "$test_dir/offline-bin/git" <<'SH'
#!/bin/bash
if [ "${1:-}" = --version ]; then
    echo 'git version 2.50.0'
    exit 0
fi
echo 'fatal: simulated network offline' >&2
exit 1
SH
chmod +x "$test_dir/offline-bin/git"
if VIM_SPEC_HOME="$test_dir/offline-home" PATH="$test_dir/offline-bin:$PATH" /bin/bash "$repo_dir/install.sh" > "$test_dir/offline.log" 2>&1; then
    echo '失败：插件下载失败却报告安装成功。' >&2
    exit 1
fi
rg -q '插件安装失败' "$test_dir/offline.log"
rg -q 'simulated network offline' "$test_dir/offline.log"
if rg -q '配置和插件安装完成' "$test_dir/offline.log"; then
    echo '失败：错误输出包含安装完成。' >&2
    exit 1
fi
test -n "$(find "$test_dir/offline-home/.vim/install-logs" -name '*.plugins' -type f)"

vim_path="$(command -v vim)"
cat > "$test_dir/offline-bin/vim" <<SH
#!/bin/bash
exec "$vim_path" '+echoerr "simulated startup failure"' "\$@"
SH
chmod +x "$test_dir/offline-bin/vim"
if VIM_SPEC_HOME="$test_dir/startup-home" PATH="$test_dir/offline-bin:$PATH" /bin/bash "$repo_dir/install.sh" --skip-plugins > "$test_dir/startup.log" 2>&1; then
    echo '失败：配置启动失败却报告安装成功。' >&2
    exit 1
fi
rg -q 'simulated startup failure' "$test_dir/startup.log"
echo '通过：缺失工具不阻止检查、BSD／Universal Ctags 区分、断网和启动错误的实际原因与日志保留。'
