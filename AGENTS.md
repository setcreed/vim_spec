# Vim 配置迁移项目

面向 macOS，将用户现有 Vim 配置迁移为可重复安装的私有 Git 仓库。

- `vimrc`：配置、快捷键和插件声明的唯一内容源。
- `vendor/plug.vim`：随仓库提供的 vim-plug，保留内嵌 MIT 许可；升级须注明来源。
- `install.sh`：创建配置软链接、备份被替换的文件并安装插件。不得整体替换或清空用户的 `.vim`。
- `scripts/check-plugins.vim`：安装结果检查。
- `tests/test-install.sh`：隔离安装回归检查。
- `README.md`：新 Mac 安装、同步、恢复及外部工具说明。
- `ROADMAP.md`：当前进度和验证记录。

迁移默认保留原有设置。测试使用项目 `.tmp/` 下的 `VIM_SPEC_HOME`，禁止直接修改真实用户配置。不得提交文件备份、撤销历史、交换文件、下载的插件或凭据。

验证入口：`bash -n install.sh tests/test-install.sh`、`bash tests/test-install.sh`；联网插件验证必须在隔离目录执行，失败不能宣称安装成功。GitHub 使用私有仓库，公开可见性必须由用户明确指定。
