# Codex Collab Switch

一个用于 Codex 的对话内协同开关 Skill。默认由当前模型独立完成工作；用户明确开启后，由主模型负责规划和审查、执行模型负责实现；退出后恢复独立执行。

**一个 Skill，两个动作，执行模型和思考强度由用户选择。** 不绑定 Sol、Luna 或某个模型版本，不将协同模式写入项目的 `AGENTS.md`。

## 什么时候适合开启协同？

**本 Skill 提供的是协同开关，不保证节省额度、降低费用或加快任务。尚未完成独立执行与协同执行的对照实测。** 请按任务选择是否开启。

更值得尝试的场景：

| 场景 | 例子 | 为什么可以考虑协同 |
|---|---|---|
| 需求明确、范围集中的实现 | 在指定模块按既定接口增加一个功能，验收条件已确定 | 主模型能简洁交接，执行代理可以持续完成一块工作 |
| 规则清楚的重复实现 | 按同一规范修改一组已列出的文件，或补充边界明确的测试 | 有机会让执行代理承担较多实现工作，摊薄交接开销 |
| 执行过程会产生大量日志 | 对一个明确问题运行排查、测试与修复流程 | 执行上下文可放在子代理中，主对话保留需求、决策与审查结果 |
| 想比较不同模型的实际表现 | 对相似任务分别采用独立模式和指定执行模型 | 可以主动控制组合，比较质量、时间和可见用量 |

以下情况通常优先让当前主模型直接完成：

- 改几个字、调整一个配置、修复已经定位的一处小问题。
- 需求还在反复讨论，需要持续依赖完整聊天历史。
- 主模型已经读懂相关代码，直接修改很快就能完成。
- 每一步都依赖上一轮决策，需要频繁在主模型与执行代理之间往返。
- 无法清楚交代任务范围、相关文件和验收条件，或执行结果经常需要大幅返工。

### 为什么可能更费 token、更慢？

子代理有自己的模型调用和工具调用。交接说明、重复读取文件、主模型审查以及返工都会产生开销。官方明确说明，子代理工作流比类似的单代理执行消耗更多 token；独立任务并行和隔离执行上下文是其价值所在。[OpenAI 子代理说明](https://learn.chatgpt.com/docs/agent-configuration/subagents)

**协同使用一个执行代理，流程是“主模型定范围和验收标准 → 执行代理实现并运行检查 → 主模型集中审查”。** 主模型默认每个任务集中审查一次，重点核对主流程和验收标准。需要返工时，默认只安排一次定点复查。追加审查聚焦尚未满足的验收项、实质风险或用户要求的验证。尚未实测这些规则能减少多少开销。

总 token、实际费用和订阅额度也要分开看：不同模型的单价或额度计量可能不同，总 token 增加不能单独证明更贵，也不能证明节省了主模型额度。不要套用其他人的节省比例。

建议先选少量有代表性的相似任务，对比独立模式与协同模式的完成时间、结果质量、返工次数及可见用量。没有按模型分项的用量数据时，就不能可靠声称节省了某个模型的额度。开启后觉得交接不划算，可以在当前对话输入“退出协同”。

## 快速使用

### Codex 桌面端：在哪里选择 Skill？

1. 安装完成后，新开一个 Codex 对话，在底部的**聊天输入框输入 `$`**。
2. 输入或搜索 `codex-collab-switch`；如果出现候选列表，选择这个 Skill。
3. 在选中的 Skill 后面输入“开启协同”，发送消息。按提示选择执行模型和思考强度。
4. 想退出时，再次选择该 Skill，输入“退出协同”并发送；在已加载该 Skill 的当前对话，也可以直接说“退出协同”。

如果输入 `$` 后没有找到它，先确认安装路径，再**新开对话或重启 Codex**后重试。Skill 文件应直接位于以下任一位置（不要把两个版本同时安装）：

- Windows：`%USERPROFILE%\.agents\skills\codex-collab-switch\SKILL.md`，或 `%USERPROFILE%\.codex\skills\codex-collab-switch\SKILL.md`。
- macOS / Linux：`~/.agents/skills/codex-collab-switch/SKILL.md`，或 `~/.codex/skills/codex-collab-switch/SKILL.md`。

如果仍未出现，检查 Codex 的 Skills 设置以及实际使用的 `CODEX_HOME`。本 Skill 仅显式调用，单独输入普通任务不会自动开启协同。

### 命令示例

Codex CLI / IDE 扩展也可在输入框输入 `$` 选择 Skill，或使用以下形式：

```text
$codex-collab-switch 开启协同
$codex-collab-switch 开启协同，用 6luna，high
$codex-collab-switch 退出协同
```

仅调用 Skill 而不说明动作时，会询问要开启还是退出，不会自动开启。讨论、引用这些命令不会切换模式。调用方式可参考 [OpenAI 官方 Skill 文档](https://learn.chatgpt.com/docs/build-skills)。

## 核心行为

| 场景 | 行为 |
|---|---|
| 安装完成，尚未开启 | 当前对话模型独立执行，本 Skill 不要求委派 |
| 明确开启，尚未完成选择 | 等待选择或纠错确认，不启动执行代理 |
| 型号和强度已确认 | 当前对话进入协同，明确显示完整型号和强度 |
| 协同期间继续提交任务 | 能独立交接的实质性实现交给执行代理。已定位的小改动或交接会大量重复定位的任务可由主模型直接完成 |
| 用户退出 | 停止新委派，处理正在运行的代理后恢复独立执行 |
| 新开普通对话 | 默认独立，不从偏好文件自动开启 |
| 用户保存默认组合 | 只保存执行模型和强度，下次仍需主动开启 |

主模型始终沿用用户当前对话选择的模型和思考强度。Skill 不替用户切换主模型。分叉/复制历史的隔离边界见下文“能力与限制”。

## 安装

### 只下载单个 Skill（推荐）

打开 [Releases](https://github.com/hehe1885/codex-collab-switch/releases/latest)，下载附件 **`codex-collab-switch-skill-v1.1.zip`**。这份附件仅包含一个 `codex-collab-switch` 文件夹（含 Skill 指令、引用文件、元数据和 MIT 许可），不包含仓库安装脚本和测试。

解压后将整个 `codex-collab-switch` 文件夹放入 `~/.agents/skills/`。Windows 对应 `%USERPROFILE%\.agents\skills\`。最终应直接出现 `~/.agents/skills/codex-collab-switch/SKILL.md`，不要多套一层同名目录。重启 Codex 后从 Skill 选择器选择。已存在同名目录时先备份，再替换。

Release 页面中 GitHub 自动附带的 “Source code (zip/tar.gz)” 是完整仓库源码；只想安装 Skill 请下载上面指定的 Skill 附件。

### 从源码安装

先取得源码：

```bash
git clone https://github.com/hehe1885/codex-collab-switch.git
cd codex-collab-switch
```

Windows PowerShell：

```powershell
powershell -NoProfile -File .\install.ps1
```

macOS / Linux：

```bash
./install.sh
```

安装只复制一个目录：

```text
skills/
└── codex-collab-switch/
    ├── SKILL.md
    ├── agents/openai.yaml
    ├── references/selection.md
    ├── references/exit.md
    └── .codex-collab-switch-v1.0
```

默认目标是 `~/.agents/skills/codex-collab-switch`。Windows 下 `~` 对应用户目录。客户端未立即显示 Skill 时，重启客户端后再检查。

旧客户端需要 `.codex/skills` 时，可以明确使用兼容路径：

```powershell
powershell -NoProfile -File .\install.ps1 -Legacy
```

```bash
./install.sh --legacy
```

兼容路径使用 `${CODEX_HOME}/skills`，未设置 CODEX_HOME 时使用 `~/.codex/skills`。不要同时安装到两个位置，以免选择器显示同名 Skill。

### 更新与卸载

相同内容重复安装不会重复复制。目标内容不同会停止；审核差异后再使用覆盖参数：

```powershell
powershell -NoProfile -File .\install.ps1 -Force
powershell -NoProfile -File .\uninstall.ps1
```

```bash
./install.sh --force
./uninstall.sh
```

覆盖安装会先将旧目录移动到相应根目录的 `skill-backups`；卸载也采用可恢复移动。目标有用户修改、额外文件或缺少归属标记时，卸载器会跳过。Legacy 安装的更新与卸载也要附带对应 Legacy 参数。

安装和卸载不会修改 `config.toml`，不会创建 custom agent，不会自动清理其他项目的指令、旧 Skill 或已保存的执行偏好。停止当前聊天的协同请使用“退出协同”，不要把卸载当成停止正在运行代理的手段。

## 模型简称与纠错

候选来自**当前运行环境明确支持作为子代理调用的模型**，不是公开 GPT 型号清单。以下仅为规则示例，不承诺你的账户或客户端具有这些型号。

| 输入 | 前提 | 处理 |
|---|---|---|
| `6.1sol` / `6.1 sol` | 存在 `gpt-6.1-sol` | 唯一匹配时直接识别 |
| `6luna` / `6 luna` | 存在 `gpt-6-luna` | 唯一匹配时直接识别 |
| `6.1luna` | 没有该型号，但存在相近的 `gpt-6-luna` | 询问是否指后者，等用户确认 |
| `6.1terre` | 存在 `gpt-6.1-terra` | 提出拼写纠正，等用户确认 |
| `sol` | 有多个 Sol 版本 | 列出匹配版本，让用户选择 |

大小写、空格和分隔符可以归一化；版本数字与小数点不会被忽略。凡是纠正拼写、改变版本或存在多个候选，都不能擅自替换。

思考强度按所选模型支持的档位展示。某模型支持 `max`，不代表所有模型都支持。已输入的强度会在型号纠错时保留并校验，不支持就重新选择，不静默降档。

## 保存默认组合

用户明确说“保存为默认组合”后，才保存偏好。路径为 `${CODEX_HOME}/collab-switch/preferences.json`，未设置 CODEX_HOME 时为 `~/.codex/collab-switch/preferences.json`。

示例数据：

```json
{
  "model": "gpt-6-luna",
  "reasoning_effort": "high"
}
```

数据只表示“以后显式开启时优先用哪个组合”，不保存协同开启状态。下次开启会重新验证可用性；模型下线或强度失效时要求重新选择，不自动升级到所谓最新版。偏好保存失败时会报告，当前对话已确认的选择仍然有效。

## 能力与限制

- 这是指令型 Skill，运行逻辑由 Codex 读取 Markdown 后执行，不是独立后台程序或客户端级别的强制开关。Skill 运行不依赖 Python、Node.js 或 Git；安装脚本使用 Shell/PowerShell，维护者测试使用 Python。
- 需要客户端支持子代理，并允许显式指定执行模型和推理强度。若没有这些能力，会说明无法启用协同，不静默改用默认模型。
- 客户端无法提供模型目录时，会说明限制，要求完整型号和强度；这些属于用户指定、尚未验证的参数。执行失败会报告，不会谎称已成功开启。
- 当前对话状态依靠聊天指令及上下文摘要维持，不写入项目文件。可识别的分叉或复制对话需要重新开启；无法识别对话身份时，不能可靠隔离继承的历史。
- 若有更高优先级规则限制委派，Skill 不会绕过。独立执行默认仅约束本工作流，不代表能覆盖客户端其他规则。
- 退出会尝试中断执行代理；如果运行环境无法确认停止，会说明状态并避免并发修改同一文件，不会直接丢弃已有改动。
- 协同存在交接、重复读文件和审查开销，不承诺一定更快或更省额度。

## 文档与源码

| 文件 | 内容 |
|---|---|
| [SKILL.md](skills/codex-collab-switch/SKILL.md) | 单个 Skill 的路由、模式边界和协同流程 |
| [模型选择规则](skills/codex-collab-switch/references/selection.md) | 能力发现、简称识别、纠错确认和偏好 |
| [退出规则](skills/codex-collab-switch/references/exit.md) | 停止委派、处理中间结果和恢复独立执行 |
| [使用示例与常见问题](docs/USAGE.md) | 完整交互示例和故障处理 |
| [迁移说明](MIGRATION.md) | 从原版和双 Skill 版本迁移 |
| [维护与验证](docs/DEVELOPMENT.md) | 源码结构、测试和当前验证边界 |
| [交互验收案例](tests/behavioral-scenarios.md) | 在目标客户端验证实际行为 |

## 来源与许可

基于 [Sol Workflow Skills](https://github.com/qyy3369-hue/sol-workflow-skills) 改造，保留原项目 MIT 许可证和版权声明。主要变化为：合并为一个 Skill、取消项目模式持久化、解除模型版本绑定、增加执行模型/思考强度选择及简称纠错。详见 [LICENSE](LICENSE)。
