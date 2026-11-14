# 维护与验证

## 源码结构

本仓库是可直接检查和修改的 Skill 源码，无需构建：

```text
skills/codex-collab-switch/   唯一的 Skill
install.ps1 / uninstall.ps1  Windows 安装与可恢复卸载
install.sh / uninstall.sh    macOS/Linux 安装与可恢复卸载
tests/                      包结构、安装与交互验收案例
.github/workflows/ci.yml     三平台 CI
docs/                       面向用户与维护者的说明
MIGRATION.md                迁移旧的模式规则与 Skill 名称
LICENSE                     原项目 MIT 许可
```

Skill 入口负责动作路由和工作流；selection.md 管理模型选择和偏好；exit.md 管理退出时的代理状态。不要往 Skill 中加入固定模型目录，避免将某一版本型号作为永久事实。

## 修改后的检查

包检查只使用 Python 标准库：

```bash
python3 tests/test_package_contract.py
bash -n install.sh uninstall.sh
```

Windows 原生测试：

```powershell
powershell -NoProfile -File .\tests\test_windows_installer.ps1
```

如本机安装了 skill-creator 的验证器及 PyYAML：

```bash
python3 /path/to/skill-creator/scripts/quick_validate.py skills/codex-collab-switch
```

该标准验证器不是本仓库运行依赖，也不是本仓库自带文件。

## 测试覆盖

- 唯一 Skill 目录、入口与引用文件存在。
- Skill 的显式调用元数据与名称一致。
- 安装位置和 Legacy 兼容路径。
- POSIX 上的重复安装、覆盖备份、保守卸载和根路径拒绝。
- Windows 上的重复安装、差异拒绝、覆盖备份、用户修改保留、可恢复卸载和 Legacy 路径。

Windows 测试生成临时测试目录并打印路径，不安装到真实个人 Skill 目录。为便于检查与恢复，测试产物不会自动删除。POSIX 测试使用临时 HOME；Windows 跳过这些用例，使用原生 PowerShell 测试。

## 当前本地验证记录

发布源码准备时在 Windows 完成：包测试 9 项，其中 5 项通过、4 项 POSIX 用例跳过；PowerShell 原生安装测试通过；Git 空白检查通过。

以下尚未在本地完成，不能算作通过：

- 标准 quick_validate.py：缺少 PyYAML，网络下载依赖失败。
- Shell 语法/执行：本机 Git Bash 创建 signal pipe 时失败，Win32 error 5。
- 在实际目标客户端交互验证模型发现、纠错、思考强度、会话状态与停止代理。

源码包含 Ubuntu、macOS 和 Windows CI 配置；上传后应检查实际工作流结果。配置存在不代表各平台已经通过。

## 交互验收

请按 [behavioral-scenarios.md](../tests/behavioral-scenarios.md) 使用一次性测试项目，核对真实委派参数、代理状态和文件改动。模型目录可以采用测试夹具，但实际执行必须选择测试客户端真实支持的组合。

静态文本检查无法证明模型是否遵循指令。不要把某个词存在于 Markdown 当作纠错或退出已经通过行为测试；要检查选错型号时是否真的等待确认、退出后是否真的停止新委派。

## 版本维护建议

模型能力变化时优先依赖运行环境元数据，通常无需更新 Skill。客户端委派参数、停止代理 API 或 Skill 加载方式改变时，才调整对应适配指令并重新验收。保持协同状态只在聊天中，偏好只保存用户确认的型号与强度。

更新安装文件时注意归属标记、安装/卸载器和测试应保持一致。保留 MIT 许可证及原作者版权声明；不要把个人偏好、账号令牌、运行缓存或真实项目指令提交到仓库。
