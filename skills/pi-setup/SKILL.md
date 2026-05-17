---
name: pi-setup
description: This skill should be used when the user wants to install or configure Pi Agent (@earendil-works/pi-coding-agent) with DeepSeek (built-in provider) and Ant-Ling Ring-2.6-1T (custom OpenAI-compatible provider), including auth, models.json, settings.json, a curated extension set, and known-pitfall fixes. Triggers on "配置 pi"、"setup pi agent"、"pi 装一下"、"配 ring/deepseek 到 pi".
license: MIT
allowed-tools: "Read,Write,Edit,Bash,AskUserQuestion"
version: "1.0.0"
---

# Pi Setup

帮用户从零配置 Pi Agent，搭配 DeepSeek V4（内置）+ Ant-Ling Ring-2.6-1T（自定义 OpenAI 兼容 provider），装一套精选扩展，并自动规避 7 个已知坑。

用户输入的参数：$ARGUMENTS

## 核心原则

1. **检测优先**：每一步先探测现状（pi 是否已装、配置是否已存在、密钥在哪个 shell 文件），再决定动作。绝不盲目覆盖用户已有配置——发现已存在就 diff 给用户看，问是否覆盖。
2. **密钥不落明文**：pi 配置里只放 `!shell命令` 惰性读取，密钥留在用户原文件（`~/.deepseek`、shell rc 等）。
3. **交互确认关键选择**：用 AskUserQuestion 收集"启用哪些模型"等决策，不替用户拍板。
4. **环境变量靠检测提醒**：不假设是 `~/.zshrc`，扫所有候选文件 + 当前进程环境，按实际情况给针对性提示。

## 工作流程

### 1. 检测现状

并行跑这些探测，汇总成一张"现状表"：

```bash
which pi && pi --version                       # pi 是否已装、版本
ls -la ~/.pi/agent/ 2>/dev/null                # 现有配置文件
cat ~/.pi/agent/settings.json 2>/dev/null      # 现有 settings（packages/默认模型）
cat ~/.pi/agent/models.json 2>/dev/null        # 现有自定义 provider
echo $SHELL                                    # 用户默认 shell
```

把"已装/未装、哪些配置已存在、默认 shell"整理给用户，再继续。

### 2. 环境变量检测（不限 ~/.zshrc）

**这是本 skill 的重点。** 不要假设密钥在 `~/.zshrc`。按以下顺序探测每个所需变量（`DEEPSEEK_API_KEY`、`LING_API_KEY`，以及用户额外要的）：

```bash
# a) 当前进程环境（最权威——说明已 export 且生效）
printenv DEEPSEEK_API_KEY >/dev/null && echo "DEEPSEEK_API_KEY: in live env"
printenv LING_API_KEY >/dev/null && echo "LING_API_KEY: in live env"

# b) 独立密钥文件
[ -f ~/.deepseek ] && grep -l DEEPSEEK_API_KEY ~/.deepseek 2>/dev/null

# c) 扫所有常见 shell 启动文件 + 是否带 export
for f in ~/.zshrc ~/.zshenv ~/.zprofile ~/.bashrc ~/.bash_profile ~/.profile ~/.config/fish/config.fish ~/.deepseek; do
  [ -f "$f" ] && grep -nE 'DEEPSEEK_API_KEY|LING_API_KEY' "$f" 2>/dev/null | sed "s|^|$f:|"
done
```

按检测结果分情况提醒（写进最终报告）：

| 检测结果 | 提醒动作 |
|---|---|
| 变量在 live env | ✅ 可直接用 `apiKey: "VAR_NAME"`（最简单） |
| 在某 rc 文件且带 `export` | ✅ 新开 shell 生效；告知具体文件 |
| 在某 rc 文件但**无 `export`**（坑 1） | ⚠️ 子进程读不到，用 `!{shell} -ic 'echo $VAR'` 惰性读，或建议加 `export` |
| 在独立文件（如 `~/.deepseek`） | ✅ 用 `!awk` / `!grep` 从该文件提取 |
| 完全找不到 | ❗ 明确告诉用户该把哪个变量加到哪个文件（用其默认 shell 对应的 rc），给出可粘贴的行 |

shell rc 选择按 `$SHELL` 推导：zsh→`~/.zshrc`，bash→`~/.bashrc`(交互)/`~/.bash_profile`(登录)，fish→`~/.config/fish/config.fish`。

### 3. AskUserQuestion — 收集关键决策

用 **AskUserQuestion** 一次性问以下问题（能合并成一次调用就合并）：

**Q1 — 启用哪些模型**（`multiSelect: true`，引导用户全选）
- `deepseek-v4-pro`（DeepSeek V4 Pro，1M ctx，内置）
- `deepseek-v4-flash`（DeepSeek V4 Flash，1M ctx，内置，便宜）
- `ant-ling/Ring-2.6-1T`（蚂蚁 Ring 2.6 1T，256K ctx，自定义）
- 在 question 文案里写明"默认建议全选——它们都进 Ctrl+P 循环列表，不占额外上下文"

**Q2 — 默认模型**（单选，选项来自 Q1 已选项）
- 决定 `settings.json` 的 `defaultProvider` / `defaultModel`

**Q3 — 默认 thinking 级别**（单选）
- `xhigh`（最强推理，Ring 烧 token 多但质量高）/ `high` / `medium`（推荐通用）/ `off`
- 提示：这是全局值，跨模型映射不同（DeepSeek 的 minimal/low/medium 不支持会被 clamp）

**Q4 — 扩展集**（单选）
- 全量 22 个（功能 8 + TUI 9 + 行为 5，约 7.7k tokens）/ 仅核心（mcp-adapter、web-access、subagents、fff、context-prune）/ 跳过扩展

只问这些；不要追问 skill 类型之类的元问题——参数已明确。

### 4. 写配置文件

按用户选择生成。**所有 JSON 模板见** `references/config-templates.md`，**严格照抄**（尤其 `compat.supportsDeveloperRole: false` 和 `thinkingLevelMap`，这是坑 2/3 的修复）。

写之前若文件已存在：读出来 diff 给用户，确认后再覆盖。

- `~/.pi/agent/auth.json` → DeepSeek key（`!awk` 从 `~/.deepseek` 或检测到的位置惰性读），`chmod 600`
- `~/.pi/agent/models.json` → ant-ling provider（仅当用户选了 Ring）
- `~/.pi/agent/settings.json` → defaultProvider/Model、defaultThinkingLevel、enabledModels（用户在 Q1 选的）
- DeepSeek **不写 models.json**（内置，手配有害——见坑 7）

### 5. 装扩展

按 Q4 选择 `pi install`。命令清单见 `references/config-templates.md` 的"扩展安装"节。全局跳过 `pi-autoresearch`、`@vanillagreen/pi-extension-manager`、`@vanillagreen/pi-session-manager`。

### 6. 修扩展快捷键冲突（坑 6）

装了 `@plannotator/pi-extension` + `@marckrenn/pi-sub-bar` 时，写 `~/.pi/agent/pi-sub-bar-settings.json` 把 cycleProvider 改 `ctrl+alt+s`（模板在 references）。

### 7. 验证

```bash
cat ~/.pi/agent/models.json | python3 -m json.tool >/dev/null && echo "models.json valid"
pi --list-models | grep -iE 'Ring|deepseek-v4'
cd /tmp && pi --provider <默认provider> --model <默认model> -p "say pong" --no-extensions
pi -p "say hi" 2>&1 | grep -i conflict   # 无输出 = 快捷键冲突已解
```

任何一步 `400 Invalid Request Messages` 或截断、或其它异常，**先查** `references/troubleshooting.md`（7 个坑的现象→复现→根因→解法），按 curl 探针二分定位，再动手。

## 输出

完成后给用户一份报告：现状检测结果、环境变量提醒（按 §2 的表）、最终生成的文件清单、用户的模型/thinking 选择、验证结果、日常使用速查（Ctrl+L 切模型 / Shift+Tab 切 thinking / Ctrl+P 循环）。

配置文件直接落在 `~/.pi/agent/`，不产出到 Downloads。
