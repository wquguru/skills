# 配置模板（严格照抄）

> pi 配置目录 `~/.pi/agent/`。`!命令` 形式的 key：pi 取 stdout，进程内缓存一次，不会每请求都跑。

## auth.json — DeepSeek 密钥

密钥在独立文件 `~/.deepseek`（`DEEPSEEK_API_KEY=sk-...`）时：

```json
{
  "deepseek": {
    "type": "api_key",
    "key": "!awk -F= '/^DEEPSEEK_API_KEY=/{gsub(/[\"'\\''[:space:]]/, \"\", $2); print $2; exit}' ~/.deepseek"
  }
}
```

写后 `chmod 600 ~/.pi/agent/auth.json`。

密钥若检测到在 live env：可改用最简形式 `{"deepseek":{"type":"api_key","key":"DEEPSEEK_API_KEY"}}`（值是环境变量名）。
密钥若在某 rc 文件但未 export：用 `"key": "!zsh -ic 'echo $DEEPSEEK_API_KEY' 2>/dev/null | tail -1"`（shell 按用户实际 shell 替换）。

## models.json — Ant-Ling Ring（自定义 provider）

```json
{
  "providers": {
    "ant-ling": {
      "baseUrl": "https://api.ant-ling.com/v1",
      "api": "openai-completions",
      "apiKey": "!zsh -ic 'echo $LING_API_KEY' 2>/dev/null | tail -1",
      "authHeader": true,
      "compat": {
        "supportsDeveloperRole": false
      },
      "models": [
        {
          "id": "Ring-2.6-1T",
          "name": "Ant Ling Ring 2.6 1T",
          "reasoning": true,
          "thinkingLevelMap": {
            "minimal": "minimal",
            "low": "low",
            "medium": "medium",
            "high": "high",
            "xhigh": "xhigh"
          },
          "input": ["text"],
          "contextWindow": 262144,
          "maxTokens": 65536,
          "cost": { "input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0 }
        }
      ]
    }
  }
}
```

不可省略的两处（坑 2 / 坑 3 修复）：
- `compat.supportsDeveloperRole: false` —— 否则 Ant-Ling 拒 developer 角色，返回 `400 Invalid Request Messages`
- `thinkingLevelMap`（含 `"xhigh": "xhigh"`）—— 否则 pi 隐藏 xhigh 档

`apiKey` 的 `zsh` 按用户默认 shell 替换（bash→`bash -ic`，fish 需另写）。检测到 live env 时可简化为 `"LING_API_KEY"`。

## settings.json — 默认模型 + enabledModels

`enabledModels` 用用户在 AskUserQuestion Q1 多选的结果填充。Ring 必须用 `provider/id` 形式 `ant-ling/Ring-2.6-1T`（避免重名冲突）；DeepSeek 无歧义可省前缀。

```json
{
  "defaultProvider": "ant-ling",
  "defaultModel": "Ring-2.6-1T",
  "defaultThinkingLevel": "xhigh",
  "enabledModels": [
    "deepseek-v4-pro",
    "deepseek-v4-flash",
    "ant-ling/Ring-2.6-1T"
  ]
}
```

`pi install` 会自动往 settings.json 追加 `packages` 数组，不用手写。
DeepSeek **不进 models.json**（内置 provider，规格随 `pi update` 维护，手配会固化旧值——坑 7）。

## pi-sub-bar-settings.json — 解快捷键冲突（坑 6）

仅当同时装了 `@plannotator/pi-extension` 和 `@marckrenn/pi-sub-bar` 时需要：

```json
{ "keybindings": { "cycleProvider": "ctrl+alt+s" } }
```

结果：plannotator 保留 `ctrl+alt+p`，sub-bar cycleProvider 用 `ctrl+alt+s`，reset 格式仍 `ctrl+alt+r`。

## 扩展安装命令

### 全量（22 个，约 7.7k tokens）

```bash
# 功能扩展（8）
pi install npm:pi-mcp-adapter
pi install npm:pi-web-access
pi install npm:pi-btw
pi install npm:@tintinweb/pi-subagents
pi install npm:pi-goal
pi install npm:@juicesharp/rpiv-todo
pi install npm:@juicesharp/rpiv-ask-user-question
pi install npm:@plannotator/pi-extension
# TUI / UX（9）
pi install npm:@marckrenn/pi-sub-bar
pi install npm:@tmustier/pi-usage-extension
pi install git:github.com/fluxgear/pi-thinking-steps
pi install npm:pi-cache-graph
pi install npm:pi-context-usage
pi install npm:@ramarivera/pi-skill-selector
pi install npm:pi-fallback-provider
pi install npm:pi-command-history
pi install npm:pi-discord-remote
# Agent 行为（5）
pi install npm:pi-rtk-optimizer
pi install npm:pi-caveman
pi install npm:pi-context-prune
pi install npm:@ff-labs/pi-fff
pi install npm:pi-hashline-readmap
```

### 仅核心（约 2k tokens）

```bash
pi install npm:pi-mcp-adapter
pi install npm:pi-web-access
pi install npm:@tintinweb/pi-subagents
pi install npm:@ff-labs/pi-fff
pi install npm:pi-context-prune
```

### 全局始终跳过

- `git:github.com/davebcn87/pi-autoresearch`（全局没必要，要用 `pi install -l` 装项目级）
- `npm:@vanillagreen/pi-extension-manager`（很卡）
- `npm:@vanillagreen/pi-session-manager`（用处不大）
