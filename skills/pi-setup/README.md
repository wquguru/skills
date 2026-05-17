# pi-setup

帮助配置 Pi Agent（`@earendil-works/pi-coding-agent`）的 Claude Code Skill：DeepSeek V4（内置 provider）+ Ant-Ling Ring-2.6-1T（自定义 OpenAI 兼容 provider）+ 精选扩展，并自动规避 7 个已知坑。

## 特性

- **检测优先**：先探测 pi 是否已装、配置是否存在、密钥在哪，再动作；不盲目覆盖。
- **环境变量智能检测**：不假设 `~/.zshrc`——扫 live env、独立密钥文件、所有常见 shell rc，按实际情况和是否 `export` 给针对性提醒。
- **AskUserQuestion 交互确认**：启用哪些模型（多选，引导全选）、默认模型、默认 thinking 档、扩展集。
- **密钥不落明文**：pi 配置只放 `!shell命令` 惰性读取，密钥留在用户原文件。
- **内置 7 坑修复**：developer 角色 400、xhigh 隐藏、ctx/maxTokens 截断、快捷键冲突等。

## 使用方法

在 Claude Code 中说"配置 pi"、"setup pi agent"、"把 ring/deepseek 配到 pi" 等即可触发；也可手动 `/pi-setup`。

## 目录结构

```
pi-setup/
├── SKILL.md                          # 工作流：检测→环境变量提醒→AskUserQuestion→写配置→装扩展→验证
├── README.md
└── references/
    ├── config-templates.md           # 全部 JSON 模板 + 扩展安装命令（严格照抄）
    └── troubleshooting.md            # 7 个坑：现象→复现→根因→解法→回退 + curl 探针
```

## 前提

- Node.js / npm（装 pi 用）
- DeepSeek key（在 `~/.deepseek` 或环境变量）
- Ant-Ling/Ling key（`LING_API_KEY`，在某 shell rc 或环境变量）—— 仅启用 Ring 时需要

## 维护

- Version: 1.0.0
- License: MIT
