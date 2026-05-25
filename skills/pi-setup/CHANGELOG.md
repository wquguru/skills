# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/) 风格的精简版。版本号遵循 [SemVer](https://semver.org/lang/zh-CN/)。

## [1.1.0] - 2026-05-20

### 新增

- **ZenMux 多模型聚合 provider 支持**。一个 key 同时接 Google / Anthropic / OpenAI / DeepSeek 等。skill 默认配置 Google Gemini 3.5 Flash 付费版 + 限免版（同一 provider 块，方便 Ctrl+L 切换）。
- **AskUserQuestion Q1 第 4 个选项**：`zenmux/google/gemini-3.5-flash`，选中后同时启用付费 + 限免两个模型，**不占额外问答槽位**（AskUserQuestion 单次最多 4 选项的硬上限下做的妥协设计）。
- **ZenMux 密钥探测**：扫 `~/.zenmux`、`~/.gemini-zenmux`、`~/.gemini-zenmux-new`、`~/.gemini-zenmux-key` 几个候选独立文件，以及 `ZENMUX_API_KEY` 环境变量，按检测结果生成 `apiKey` 字段（live env / awk 文件 / shell rc 三种形式）。
- **§7 验证新增 ZenMux curl 探针**：选了 ZenMux 时自动跑一次端点连通测试，验 key 有效性 + reasoning_effort 透传。
- **references/config-templates.md** 新增"models.json — ZenMux"完整模板，含 4 处不可省略字段（`compat.supportsDeveloperRole: false` / `thinkingLevelMap` 含 `xhigh: high` / `maxTokens: 65536` / `contextWindow: 1048576`）的解释。
- **references/troubleshooting.md** 新增 **坑 8**：Gemini 3.5 Flash 默认重 reasoning（`max_tokens` 给小直接 `finish_reason:length`、`content:""`）+ 认知坑（Pi footer 的 `R` 是 **cacheRead** 不是 reasoning_tokens，核对成本时不要乘 output 单价）。
- **通用 curl 探针**新增 ZenMux Gemini 端点段，覆盖基础连通 + 逐档 `reasoning_effort` 测试。

### 修订

- **SKILL.md description / 标题副文**改为三 provider 表述（DeepSeek + Ant-Ling + ZenMux）。
- **Q3 thinking 档说明**新增"Gemini 的 xhigh 在 thinkingLevelMap 里映射回 high"提示，避免用户期待 xhigh 在 Gemini 上有差异行为。
- **§4 写配置文件**改为"按选中 provider 合并写入同一 `providers` 对象"——多 provider 共存时不要相互覆盖。
- **8 个坑**：原 7 个坑数表述全部同步更新。

### 不做的事（有意）

- **不硬编码 Claude / GPT 等其它 ZenMux 模型 ID**：catalog 持续变化，skill 在最终报告里告诉用户"往 `zenmux.models` 数组追加，model ID 见 https://zenmux.ai"。
- **不替用户切 `defaultProvider`**：ZenMux 模型只加进 `enabledModels`，原有默认（Ring 或 DeepSeek）不动；切换走 Ctrl+L。
- **不内置 referral 链接**：skill 是工具不是营销渠道。

---

## [1.0.0] - 2026-05-17

### 首个发布

- **DeepSeek V4**（pi 内置 provider，1M ctx）+ **Ant-Ling Ring-2.6-1T**（自定义 OpenAI 兼容 provider，256K ctx）双 provider 配置。
- **AskUserQuestion 四问决策流**：Q1 启用哪些模型（multiSelect） / Q2 默认模型 / Q3 默认 thinking 档 / Q4 扩展集（全量 22 / 仅核心 / 跳过）。
- **多 shell 环境变量检测**：不假设 `~/.zshrc`，扫 zsh / bash / fish 各 rc 文件、独立密钥文件（如 `~/.deepseek`）、live env 三个来源；密钥不落明文 JSON，统一用 `!shell命令` 惰性读。
- **7 个已知坑诊断与修复**：
  - 坑 1：shell rc 变量未 export，pi 子进程读不到
  - 坑 2：Ant-Ling 拒 developer 角色，`compat.supportsDeveloperRole: false` 回退
  - 坑 3：pi 默认隐藏 xhigh 档，需在 `thinkingLevelMap` 显式定义
  - 坑 4：`contextWindow` / `maxTokens` 写小导致推理被截断
  - 坑 5：`defaultThinkingLevel` 是全局值，跨模型映射不一致
  - 坑 6：`@plannotator/pi-extension` × `@marckrenn/pi-sub-bar` `ctrl+alt+p` 快捷键冲突
  - 坑 7：误把 DeepSeek 写进 models.json 会固化旧值
- **精选扩展集**：22 个全量（功能 8 + TUI 9 + 行为 5，约 7.7K token）/ 5 个核心（mcp-adapter、web-access、subagents、fff、context-prune）/ 跳过扩展三档可选。
- **快捷键冲突自动修**：写 `~/.pi/agent/pi-sub-bar-settings.json` 把 `cycleProvider` 改 `ctrl+alt+s`。
- **验证流程**：JSON 校验 + `pi --list-models` + 启动模型 ping + 冲突复查 + curl 探针二分。
