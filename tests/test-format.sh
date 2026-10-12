#!/bin/bash
set -euo pipefail
repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
mkdir -p "$repo_dir/.tmp/tests"
test_dir="$(mktemp -d "$repo_dir/.tmp/tests/format.XXXXXX")"
export VIM_SPEC_HOME="$test_dir/home with spaces"
vim_path="$(command -v vim)"
bash "$repo_dir/install.sh" --skip-plugins
mkdir -p "$test_dir/bin"
cat > "$test_dir/bin/black" <<'SH'
#!/bin/bash
set -eu
test "$#" = 1
printf '%s\n' "$1" > "$VIM_SPEC_HOME/formatter-argument.log"
if [ "${VIM_SPEC_FORMAT_FAIL:-0}" = 1 ]; then
    echo 'mock formatting failed' >&2
    exit 1
fi
printf 'formatted\n' > "$1"
SH
chmod +x "$test_dir/bin/black"
export VIM_SPEC_TEST_TOOL="$test_dir/bin/black"
PATH="$test_dir/bin" "$vim_path" -N -i NONE -u "$VIM_SPEC_HOME/.vimrc" -es -S "$repo_dir/tests/test-format.vim"
cat > "$test_dir/bin/prettier" <<'SH'
#!/bin/bash
set -eu
for file_path do :; done
case "$0" in
    *project-a*) version='prettier-2' ;;
    *project-b*) version='prettier-3' ;;
    */prettier) version='global-prettier' ;;
    */goimports) version='goimports' ;;
    */gofmt) version='gofmt' ;;
esac
printf '%s\n' "$version|$PWD|$file_path" >> "$VIM_SPEC_HOME/tool-calls.log"
if [ "${VIM_SPEC_FORMAT_FAIL:-0}" = 1 ]; then
    echo 'mock tool failure' >&2
    exit 1
fi
printf '%s\n' "$version" > "$file_path"
SH
chmod +x "$test_dir/bin/prettier"
cp "$test_dir/bin/prettier" "$test_dir/bin/goimports"
cp "$test_dir/bin/prettier" "$test_dir/bin/gofmt"
for project in 'project-a with spaces' project-b project-c; do
    mkdir -p "$VIM_SPEC_HOME/$project/src" "$VIM_SPEC_HOME/$project/.git"
    printf '{}\n' > "$VIM_SPEC_HOME/$project/package.json"
done
for project in 'project-a with spaces' project-b; do
    mkdir -p "$VIM_SPEC_HOME/$project/node_modules/.bin"
    cp "$test_dir/bin/prettier" "$VIM_SPEC_HOME/$project/node_modules/.bin/prettier"
done
export VIM_SPEC_TEST_BIN="$test_dir/bin"
PATH="$test_dir/bin" "$vim_path" -N -i NONE -u "$VIM_SPEC_HOME/.vimrc" -es -S "$repo_dir/tests/test-project-format.vim"
echo '通过：格式化无效输入、缺失工具、失败保留缓冲区、保存未提交编辑、特殊字符文件名及成功重新加载。'
echo '通过：两个项目各自的 Prettier 版本、项目工作目录、全局回退及 Go 单次格式化。'
