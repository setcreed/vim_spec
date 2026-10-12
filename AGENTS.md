# Vim 配置迁移项目

面向 macOS，将用户现有 Vim 配置迁移为可重复安装的私有 Git 仓库。

- `vimrc`：配置、快捷键和插件声明的唯一内容源。
- `vendor/plug.vim`：随仓库提供的 vim-plug，保留内嵌 MIT 许可；升级须注明来源。
- `install.sh`：创建配置软链接、备份被替换的文件并安装插件。不得整体替换或清空用户的 `.vim`。
- `scripts/check-plugins.vim`：安装结果检查。
- `scripts/check-tools.sh`：只读检查 PATH 中的可选工具及 Universal Ctags，缺失只提示。
- `tests/test-install.sh`：隔离安装、配置加载及文件保存回归检查。
- `tests/test-format.sh`、`tests/test-format.vim`、`tests/test-project-format.vim`：格式化失败路径、项目工具选择、Go 单次调用及路径安全回归检查。
- `tests/test-diagnostics.sh`：工具缺失、ctags 类型、模拟断网及配置报错的诊断回归检查。
- `README.md`：新 Mac 安装、同步、恢复及外部工具说明。
- `ROADMAP.md`：当前进度和验证记录。

迁移默认保留原有设置。测试使用项目 `.tmp/` 下的 `VIM_SPEC_HOME`，禁止直接修改真实用户配置。不得提交文件备份、撤销历史、交换文件、下载的插件或凭据。

验证入口：`bash -n install.sh scripts/check-tools.sh tests/test-install.sh tests/test-format.sh tests/test-diagnostics.sh`，以及三个 `tests/test-*.sh` 脚本；联网插件验证必须在隔离目录执行，失败不能宣称安装成功。GitHub 使用私有仓库，公开可见性必须由用户明确指定。
