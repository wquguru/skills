# 故障排查：7 个已知坑

每个坑按 现象 → 复现 → 根因 → 解法 → 回退 组织。遇异常先对照这里，再用 curl 探针二分定位。

## 坑 1 — shell rc 里的变量没 export，pi 子进程读不到

- **现象**：交互 shell 里 `echo $LING_API_KEY` 有值，但 pi 报无 key。
- **复现**：`zsh -ic 'env | grep -c "^LING_API_KEY="'` 输出 `0` = 没 export。
- **根因**：非 `export` 的 shell 变量不进子进程环境。
- **解法**：models.json/auth.json 用 `!{shell} -ic 'echo $VAR' 2>/dev/null | tail -1` 惰性读（不改用户 rc）；或建议用户给那行加 `export`。
- **判断 shell**：按 `$SHELL`——zsh→`zsh -ic`，bash→`bash -ic`。

## 坑 2 — Ant-Ling 拒 `developer` 角色 → `400 Invalid Request Messages`

- **现象**：pi 调 Ring 一律 `400 Invalid Request Messages`，`--verbose` 看不到 body。
- **复现**：
  ```bash
  KEY=$(zsh -ic 'echo $LING_API_KEY' 2>/dev/null | tail -1)
  # developer 角色 → 400
  curl -s -X POST https://api.ant-ling.com/v1/chat/completions -H "Authorization: Bearer $KEY" \
    -H "Content-Type: application/json" \
    -d '{"model":"Ring-2.6-1T","messages":[{"role":"developer","content":"x"},{"role":"user","content":"hi"}],"max_tokens":20}'
  # system 角色 → OK
  ```
- **根因**：`reasoning: true` 让 pi 对推理模型默认用 OpenAI 新版 `developer` 角色发系统提示，Ant-Ling 不认。
- **解法**：models.json 加 `compat.supportsDeveloperRole: false`，pi 回退用 `system`。

## 坑 3 — pi 默认隐藏 `xhigh` 档

- **现象**：自定义推理模型只能选到 `high`，没有 `xhigh`，但 API 实测支持。
- **根因**：`@earendil-works/pi-ai/dist/models.js:38` —— `if (level === "xhigh") return mapped !== undefined`，xhigh 仅当 `thinkingLevelMap` 显式定义才暴露；其它档默认有。
- **解法**：models.json 写全 `thinkingLevelMap`，含 `"xhigh": "xhigh"`。
- **映射规则**：openai-completions 下 pi 把 thinking level 直接当 `reasoning_effort` 字面值发（`thinkingLevelMap[level] ?? level`）；`off` 不发该参数（Ring 仍输出 `<think>`，只是不指定 effort）。

## 坑 4 — contextWindow / maxTokens 占位值太小（影响最大）

- **现象**：xhigh 默认下回答经常被截断（`finish_reason: length`）；或上下文没满就被 compact。
- **根因**：`maxTokens` 设小 → 推理模型把预算烧在 `<think>` 上答案被切；`contextWindow` 设小 → 提前触发 auto-compaction。
- **解法**：Ring-2.6-1T 真实规格 `contextWindow: 262144`、`maxTokens: 65536`（原生 128K，YaRN 扩 256K；最大输出 ~66K）。已实测 Ant-Ling 接受 `max_completion_tokens: 65536`。
- **回退**：万一该端点只开原生 128K，长上下文会 API 报错——把 `contextWindow` 调回 `131072`，`/model` 命令即时重载不用重启。

## 坑 5 — `defaultThinkingLevel` 是全局的，跨模型映射不一致

- **现象**：同一 `xhigh` 默认，不同模型行为不同。
- **根因**：没有"每模型独立默认"。`xhigh` → Ring 发 `xhigh`；→ deepseek-v4-pro 发 `max`，且 deepseek 的 `minimal/low/medium` 是 `null`（不支持），设这些会被 clamp 到 `high`。
- **解法/提醒**：要某模型专属档位只能靠启动参数 `--thinking <level>` 或切进去 `Shift+Tab`。AskUserQuestion 选默认档时要把这点讲清楚。

## 坑 6 — 扩展快捷键冲突 `ctrl+alt+p`

- **现象**：启动报 `Extension shortcut conflict: 'ctrl+alt+p'`。
- **根因**：`@plannotator/pi-extension`（硬编码 `Key.ctrlAlt("p")`，不可配）与 `@marckrenn/pi-sub-bar`（cycleProvider，可配）抢键。
- **解法**：写 `~/.pi/agent/pi-sub-bar-settings.json`：`{"keybindings":{"cycleProvider":"ctrl+alt+s"}}`。让 plannotator 保留 `ctrl+alt+p`。
- **依据**：sub-bar 设置路径来自其源码 `src/paths.ts`（`getAgentDir()+/pi-sub-bar-settings.json`），`loadSettings` 与默认 merge，只写要改的字段即可。

## 坑 7 — 误以为 DeepSeek 也要手配 models.json

- **现象**：在 models.json 给 DeepSeek 写规格。
- **根因**：DeepSeek 是 pi 内置 provider，规格（ctx 1M / maxTokens 384000 / `thinkingFormat: deepseek` / `requiresReasoningContentOnAssistantMessages` / thinkingLevelMap）随 pi 版本维护。
- **解法**：DeepSeek 只在 auth.json 给 key，**绝不**进 models.json。手动覆盖会抄不准 + 固化旧值，`pi update` 不会帮你更新。

## 通用 curl 探针

```bash
KEY=$(zsh -ic 'echo $LING_API_KEY' 2>/dev/null | tail -1)

# 基础连通
curl -s -X POST https://api.ant-ling.com/v1/chat/completions \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d '{"model":"Ring-2.6-1T","messages":[{"role":"user","content":"say pong"}],"max_tokens":50}'

# 逐档测 reasoning_effort（minimal/low/medium/high/xhigh 全 OK，非法值 → 400）
for eff in minimal low medium high xhigh; do
  curl -s -X POST https://api.ant-ling.com/v1/chat/completions \
    -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
    -d "{\"model\":\"Ring-2.6-1T\",\"messages\":[{\"role\":\"user\",\"content\":\"hi\"}],\"max_completion_tokens\":30,\"reasoning_effort\":\"$eff\"}"
done
```

排查心法：pi 把 provider 错误压成一行，`--verbose` 也看不到 body。必须 curl 直接打端点，把变量（角色 / reasoning_effort / max_tokens 字段名）逐个单测二分，才能定位。
