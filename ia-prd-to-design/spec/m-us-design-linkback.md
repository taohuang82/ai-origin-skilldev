# US 与设计交付物索引关联（Story 设计引用回填）

在 **本 workflow 内计划要素已全部经 element-runner 完成**（或增量/评审场景下用户确认本轮设计交付已就绪），且 **特性目录下 `design.md` 已按 `spec/m-design-summary-merge.md` 生成或刷新**（评审流中用户明确跳过除外）之后，若特性目录存在 **US 载体文件**（默认 `{DESIGN_DIR}/story.md`），将 **多文件设计交付物及 `design.md` 摘要** 的可定位索引写回每个 US 的「设计引用」，语义与 **`ia-prd-to-design/subagents/ia-story-enricher.md`** 对齐；引用目标以 `config.yaml` → **`design_artifacts`** 所列主文件及 **`design.md`** 为主，而非仅依赖某一单文件。

---

## 触发与跳过

- **执行**：`STORY_FILE`（见本 Skill `SKILL.md`）存在且可读。
- **跳过**：无 US 载体文件时跳过本步骤，不报错。

---

## 强制读取（执行本步骤前）

1. 本 Skill `SKILL.md` 路径变量：`DESIGN_DIR`、`STORY_FILE`、`US_BATCH_SIZE`（默认 `4`）。
2. 本 Skill `config.yaml` → `design_artifacts`（确定各要素主文件名）。
3. 可选（同仓库已存在时）：`ia-prd-to-design/reference/story-structure.md`、`ia-prd-to-design/reference/design-to-story-mapping.md` — 与本文下文规则互为补充；**以本文「多文件引用」为准**。

---

## 产出禁码（强制）

写回 `story.md` 时 **禁止** 粘贴具体代码或 SQL；仅补充可定位的设计引用或缺口说明。

## 设计原则（强制）

- 本步骤仅输出 US 与设计文档的索引关联，禁止直接输出可执行具体代码（含完整类/方法体、脚本、SQL）。

---

## 增量从简（强制）

每条 US 的设计引用保持 **单行或可定位短链**；不复制各设计文件大段正文，不复述需求本文。

---

## 要素职责说明

- **不新增或修改** 各要素设计正文。
- 仅将 **已产出的设计文件** 中的可定位章节/表格/接口名等 **索引到** `story.md` 各 US。

---

## 输入

| 输入 | 说明 |
|------|------|
| `{DESIGN_DIR}/story.md` | US 载体；原地更新 |
| `{DESIGN_DIR}/{design_artifacts 各值}` | 本轮存在即参与索引（如 `architecture.md`、`data.md`、`backend-api.md` 等） |
| `{DESIGN_DIR}/design.md` | 若已由 `spec/m-design-summary-merge.md` 生成，**建议**列为总览入口（章节级引用） |
| `{DESIGN_DIR}/shared-context.md` | 若存在（常见：增量流程），可用于「待确认/决策事实」类引用 |
| `US_BATCH_SIZE` | 批大小，默认 `4` |

---

## 输出

- 原地更新：`{DESIGN_DIR}/story.md`
- 完成消息：`DONE: story.md design linkback`

---

## US 识别与写回边界（摘录）

与 `ia-prd-to-design/reference/story-structure.md` 一致：

1. **US 起始行**：优先匹配 `## US-xxx` / `## US xxx` / `### US-xxx` 等；以编号 + 标题层级唯一性为准。
2. **禁止改写** 既有 US 的 ID、标题、需求背景、验收标准。
3. **「设计引用」小节**：若已存在则 **原地更新**；否则插在该 US 块末尾（下一 US 之前）。
4. **批处理**：按 `US_BATCH_SIZE` 分批，每批完成后立即写回 `story.md`。

---

## 增量模式 DIP → US 映射协议（增量模式专属）

在增量模式（design-incremental-build）下，Phase 3B 须先执行以下映射逻辑：

1. **建立 US → DIP 映射**：依据各 DIP 的 `source_prd_change` 字段反查 PrdChange 的 `source_story`，
   将 DIP 关联到对应 US。
2. **全局视野**：映射需要所有 DIP 的 `source_prd_change` → `source_story` 全集，
   因此必须在所有要素的 DIP 收齐后（Phase 3A 完成后）才能启动。
3. **提取可定位索引**：对每个 US，从 DIP 的 `element` + `baseline_ref` + `target_state` 中提取
   设计文件名 + 章节标题 + 关键对象（表名/接口路径/组件名等）。
4. **去重合并**：同一 US 若被多个 DIP 引用相同设计文件章节，合并为一条。
5. **无 source_story 的 DIP**：主动识别模式（type_b/type_c）下 source_story 可能为空，
   此类 DIP 不参与 US 回填，仅体现在 design.md 影响点索引中。

---

## 多文件映射原则

引用须带 **文件名 + 可定位章节标题（或关键词）**，示例如下（按 US 关注点择优，不必枚举本轮未产出的文件）：

| US 关注点 | 优先引用文件（与 `design_artifacts` 键对应） |
|-----------|-----------------------------------------------|
| 总览/跨域入口 | `design.md`（若存在）→ 对应摘要章节 |
| 服务边界/部署/模块拓扑 | `architecture.md`（若存在） |
| 数据实体/字段 | `data.md` |
| 接口契约 | `backend-api.md` |
| 后端流程/规则 | `backend.md` |
| 前端页面/交互 | `frontend.md` |
| 外部系统/MQ/集成 | `integration.md` |
| 配置/字典/错误码/权限/NFR | `config.md` |
| 本轮探索结论/待确认 | `shared-context.md`（若存在） |

**写法模板**（每条 US 建议 2～4 条，单行优先）：

```markdown
### 设计引用
- API：`backend-api.md` → `## …`（接口/场景）
- 数据：`data.md` → `## …`（实体/字段）
- 后端：`backend.md` → `## …`（规则/流程）
```

若证据不足，追加 **`### 设计缺口/待确认`**（简述缺口与建议补充的设计章节），禁止臆造实现细节。

---

## 约束

- 仅允许原地更新 `story.md`；**禁止** 新建按 US 拆分的文件或目录。
- 避免跨 US 重复粘贴同一大段引用句；同一 US 内相同章节合并为一条。
- 不得将 Skill 目录当作业务根路径；一切路径相对 **`WORKSPACE_ROOT`** / `DESIGN_DIR` 解析。

---

## 完成标准

- 每个 US 均包含「设计引用」和/或「设计缺口/待确认」。
- `story.md` 已成功写回。
- 最终对外只输出：`DONE: story.md design linkback`
