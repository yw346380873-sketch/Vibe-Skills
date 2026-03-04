# TurboMax‑Balanced（Vector‑First Context）设计稿

更新时间：2026-03-04  
适用范围：仅在用户显式 `/vibe` 或 `$vibe` 时启用（`explicit_vibe_only=true`）  

## 背景 / 痛点

用户偏好 **“用更多 API 消耗换取更少往返与更快闭环”**（TurboMax），同时担心：

- 长对话/大 diff 全量注入会导致 **上下文腐烂**（噪声增大、证据漂移、误路由/误建议）。
- 新项目（greenfield）占比高：需要 **更快的“执行清单 + 关键确认点”** 输出，而不是保守到不敢用代码证据。

## 目标（Goals）

1. **更快闭环**：显式 vibe 时稳定启用 LLM 加速 overlay，并增加输出预算，减少二次追问。
2. **向量调度上下文**：允许代码证据进入上下文，但用 **向量检索/相似度** 选取“最相关的少量片段”，避免全量 diff 注入。
3. **不破坏治理边界**：默认仍是 advice-first（候选→用户确认），不自动替换 pack/skill（`allow_route_override=false`）。

## 非目标（Non‑Goals）

- 不做跨项目/跨会话的长期记忆（长期图记忆由 Cognee 负责，且是可选增强）。
- 不在仓库内持久化任何 API Key（只读环境变量）。
- 不把 LLM overlay 变成“强制路由器”；只提升 confirm_required、输出建议与 QA 推荐。

## 核心设计：三层上下文（Vector‑First）

### 1) state_store（默认）
用于会话进度、命令输出摘要、执行清单等最稳定信息。

### 2) ruflo（短期向量缓存，建议但不强依赖）
当运行时支持 `claude-flow`/`ruflo` MCP 时，用于存储 **Evidence Cards**（少量关键证据 + 来源定位），并在后续步骤用相似度检索召回 1–3 张卡片。

> 注：VCO 的路由脚本本身不依赖 ruflo；它属于执行/协作层的“可选增强”。

### 3) 代码证据注入（受控）
当需要 diff 证据时：

- 先拿到完整 diff（仅本地 git），再按文件/块切分成 chunks；
- 使用 embeddings 计算 prompt 与 chunks 的相似度（provider 可配置，默认使用火山 Ark multimodal embeddings 的 **text-only input**）；
- 仅注入 Top‑K chunks（例如 2–3 个），并在 `max_diff_chars` 内截断；
- 若 embeddings 不可用：退化为传统截断（head truncate）或仅 git status。

## TurboMax 参数策略（建议值）

### LLM Acceleration Overlay（`config/llm-acceleration-policy.json`）

- `trigger.top_k`: `3 → 5`
- `provider.max_output_tokens`: `900 → 1600`
- `provider.temperature`: `0.2 → 0.15`
- `context.max_diff_chars`: `9000 → 6000`（更节制）
- 新增 `context.vector_diff`：启用 embeddings 选择 diff chunks（大 diff 时生效）
  - embeddings provider：
    - `type=volc_ark`（默认）：`base_url=https://ark.cn-beijing.volces.com/api/v3` + `endpoint_path=/embeddings/multimodal`，env：`ARK_API_KEY`
    - `type=openai`（可选）：env：`OPENAI_API_KEY`
- 继续保持：
  - `activation.explicit_vibe_only=true`
  - `trigger.always_on_explicit_vibe=true`
  - `safety.allow_route_override=false`
  - `provider.store=false`

## 失败与退化（Fallback）

1. embeddings 调用失败 / model 不支持 / 无 API key：
   - 不阻塞 overlay 主流程；
   - 退化为 `max_diff_chars` 截断（或仅 status）。
2. git 不存在 / 非 git repo：
   - git 上下文为空（不注入 diff）。
3. LLM provider 不可用：
   - overlay abstain，不改变路由，仅保留原路由结果。

## 可观测性（Observability）

- 将 diff 选择模式（full/head/vector/fallback）记录到 `llm_acceleration_advice` 的 provider/notes 中（便于调参）。
- embeddings cache 仅写入 `outputs/runtime/`（gitignore），不入库。

## 风险与控制

- **速度 vs 质量**：启用向量选择会增加 embedding 调用，但减少“上下文噪声→误判→返工”的总耗时。
- **上下文腐烂**：通过 `max_diff_chars` + Top‑K chunk 注入 + 可选缓存上限，降低污染。
- **路由冲突**：保持 `allow_route_override=false`，只允许“确认升级/建议”，不强行换 pack。
