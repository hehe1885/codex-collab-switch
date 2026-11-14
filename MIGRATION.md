# 从 Sol Workflow Skills v02 迁移

v04 将 sol-only / sol-luna-workflow 合并为 codex-collab-switch，不再将执行模式写入项目文件，不绑定 Sol/Luna 或版本。

1. 使用旧版仓库的 uninstall.ps1 或 uninstall.sh（与原安装位置一致的 Legacy 参数）卸载旧 Skill；修改过的目录会跳过，需要自行审核。v04 卸载器只管理新名称，不能移除旧版。
2. 在曾启用旧模式的项目检查 AGENTS.override.md、AGENTS.md，以及之前被更新的 fallback 指令文件。若 AGENTS.md 有 `codex-execution-mode:bridge-target` 注释，也要检查对应的项目内文件。
3. 保留备份后，仅移除完整的 `<!-- codex-execution-mode:start -->` 到 `<!-- codex-execution-mode:end -->` 托管区块和相关 bridge-target 注释，保留其他内容。标记不成对、嵌套或来源不明时不要自动修改。不要跟随指向项目外或符号链接的 bridge 路径。
4. 安装 v04。重启客户端或新开对话，确认旧 Skill 不再出现在选择器、旧指令不再要求协同，再显式调用 codex-collab-switch。

项目指令不会因替换 Skill 自动消失。本包不会批量扫描或修改用户的其他项目。需要帮助时可以明确要求代理清理某个项目的旧托管区块。

## 从拆分版 v03 升级

如果安装过 collab-on / collab-off，请先用拆分版的卸载脚本卸载这两个 Skill，再安装 v04 的单个 codex-collab-switch。新安装器不会自动移除旧名称。新对话中通过同一个 Skill 指定“开启协同”或“退出协同”；仅调用名字不附带动作时会询问操作，不会自动开启。
