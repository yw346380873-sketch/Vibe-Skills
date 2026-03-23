# 安装路径：高级 host / lane 参考

> 大多数用户先看两条主路径：
> - [`one-click-install-release-copy.md`](./one-click-install-release-copy.md)
> - [`manual-copy-install.md`](./manual-copy-install.md)

这份文档只解释当前真实支持边界。

## 当前支持面

暂时只支持两个宿主：

- `codex`
- `claude-code`

其中：

- `codex`：正式推荐路径
- `claude-code`：preview guidance 路径

`TargetRoot` 只是安装路径。
`HostId` / `--host` 才决定宿主语义。

## 推荐命令

### Codex

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId codex
pwsh -File .\check.ps1 -HostId codex -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host codex
bash ./check.sh --host codex --profile full --deep
```

### Claude Code

```powershell
pwsh -File .\scripts\bootstrap\one-shot-setup.ps1 -HostId claude-code
pwsh -File .\check.ps1 -HostId claude-code -Profile full -Deep
```

```bash
bash ./scripts/bootstrap/one-shot-setup.sh --host claude-code
bash ./check.sh --host claude-code --profile full --deep
```

## 必须说清楚的边界

### Codex

- 当前是最完整的 repo-governed 路径
- 建议范围只包括本地 `~/.codex` 设置、官方 MCP 注册和可选 CLI 依赖
- hook 当前因兼容性问题被冻结，不属于标准安装内容
- 如果需要 Codex 基础在线模型能力，去 `~/.codex/settings.json` 的 `env` 或本地环境变量里配置 `OPENAI_API_KEY`、`OPENAI_BASE_URL`
- 如果需要启用 Codex 下的治理 AI 在线层，还要额外在本地配置：
  - `VCO_AI_PROVIDER_URL`
  - `VCO_AI_PROVIDER_API_KEY`
  - `VCO_AI_PROVIDER_MODEL`
- `OPENAI_*` 不等于 `VCO_AI_PROVIDER_*`；前者是 Codex 基础在线 provider，后者是治理 AI 在线层
- 不要要求用户把密钥贴到聊天里

### Claude Code

- 这是 preview guidance，不是 full closure
- hook 当前因兼容性问题被冻结
- 安装器不再写 `settings.vibe.preview.json`
- 用户应自己打开 `~/.claude/settings.json`，只在 `env` 下补所需字段
- 常见字段：
  - `VCO_AI_PROVIDER_URL`
  - `VCO_AI_PROVIDER_API_KEY`
  - `VCO_AI_PROVIDER_MODEL`
- 如宿主连接需要，再补 `ANTHROPIC_BASE_URL`、`ANTHROPIC_AUTH_TOKEN`
- 不要要求用户把密钥贴到聊天里

## AI 治理层提示

对 `codex` 和 `claude-code`，如果本地还没配置好治理 AI 所需的 `url`、`apikey`、`model`，就不能描述成“已完成治理 AI online readiness”。

对 `codex`，这表示最多只能说基础在线 provider 已就绪，不能顺带宣称治理 AI 在线层也已就绪。

这些值必须由用户自己填进本地宿主配置或本地环境变量。
