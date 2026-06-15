# 特性级 `design.md` 汇总生成

在 **`effective_sequence` 中全部计划要素均已通过 `element-runner` 成功结束**（或本轮编排认定要素交付已就绪）之后，生成 **`{DESIGN_DIR}/design.md`**：**只保留摘要与引用**，不重复粘贴各要素交付文件中的实现细节。

编排与其它模块在执行汇总时 **必须严格按本文** 收集素材、校验门禁并落盘；本文是自洽约定，不依赖外部 Skill 文档。

---

## 触发与跳过

| 条件 | 行为 |
|------|------|
| 本轮有计划要素且已全部 runner 完成 | **必须执行**汇总（除非用户明确取消特性级 `design.md` 且团队另有约定） |
| 本轮无任何要素派发（极端空跑） | 可跳过；不得覆盖已有 `{DESIGN_DIR}/design.md` 除非用户确认 |

输出路径：**`{DESIGN_DIR}/design.md`**（与 Skill `DESIGN_FILE` 一致）。

路径约束：业务路径基于 `{DESIGN_DIR}` / `{WORKSPACE_ROOT}` 组装；禁止使用裸露的 `workspace/...` 相对路径代替仓库根解析。

## 设计原则（强制）

- 汇总文件仅输出设计摘要、事实与引用，禁止直接输出可执行具体代码（含完整类/方法体、脚本、SQL）。

---

## 汇总数据来源（按优先级）

1. **`arch_decisions`（架构决策）**  
   - 若存在 **`{DESIGN_DIR}/overall-design.md`**：从中提取已确认的整体架构决策与方向性结论。  
   - 若存在 **`{DESIGN_DIR}/shared-context.md`**：合并其中已标记为确认的决策条目（字段名以该文件当期模板为准，常见如决策事实、`decision_facts` 等）。  
   - 二者皆有则以 **overall-design 为叙述主轴**，shared-context 作补充且不与之冲突；冲突须暂停并请用户裁定。

2. **`affected_contexts`（受影响上下文）**  
   - 优先来自 **`{DESIGN_DIR}/shared-context.md`**（增量 / 探索流程常见）。  
   - 不存在该文件时可省略本节，或仅写「本轮未产出 shared-context」一行说明。

3. **设计缺口与待确认**  
   - 来自 **`shared-context.md`** 中的待确认项、缺口列表或等价章节。  
   - 无文件则从各要素汇总块中的 `pending` 合并（见下文），仍无则写「无」。

4. **各设计域摘要与引用**  
   - **优先**来自本轮每个已执行要素在 **会话完成输出** 中给出的统一结构块 **`## 汇总输入（供 design.md 合并）`**。  
   - **仅在**核对引用锚点或抽检一致性时，回看对应 **`context.output_doc_path`** 交付文件。

---

## 要素完成时必须产出的汇总结构块（强制）

每个 **`element_id` 对应的 runner 会话结束后**，执行 Agent 必须在完成摘要之后马上输出下列结构块：**标题字面量、字段名与子项顺序不得改动**。  
若编排采用「用户确认后再进入下一要素」的流程，则该结构块必须在进入下一要素之前已存在于会话中。

```markdown
## 汇总输入（供 design.md 合并）
- design_section: `{见下文「要素 → design.md 章节标题」映射表}`
- status: `changed` | `no-change` | `not-applicable`
- summary:
  - {至多少量条目；每条为一句可核对事实；须能在本域产出文件中定位}
- references:
  - `{DESIGN_DIR}/{文件名}.md` → `{一级或二级 Markdown 标题字面量}`
- pending:
  - {若无则写 `无`}
```

约定：

- `summary` 仅写已落盘或已在摘要中明确确认的事实，禁止臆测。
- `references` 每条须可定位到**真实存在的章节标题**；若本次评估为无变更，仍须至少保留一条指向交付文件或摘要结论的引用说明。
- `status = no-change` 或 `not-applicable` 时：`design.md` 对应域只记录「本次无需改动」或「不适用」，不得扩写成虚构变更。
- `pending` 汇总到 `design.md` 的「设计缺口与待确认」时与其它来源合并去重。

### 要素 → `design.md` 章节标题映射

用于填写结构块中的 `design_section`（标题字面量建议保持一致，便于模板渲染）：

| element_id（registry） | design_section |
|------------------------|----------------|
| architecture | `## 顶层架构与全局规范（greenfield only）` |
| data-model | `## 数据存储与模型` |
| api-contract | `## API 契约` |
| backend-impl | `## 后端处理逻辑` |
| integration | `## 异步处理与系统集成` |
| config | `## 配置、字典、安全与权限` |
| frontend | `## 前端展现与交互` |

说明：

- **`MODE ∈ {new-incremental, update}`** 且本轮未执行 `architecture` 时：省略模板中「顶层架构与全局规范」整节，或保留一节并写「本轮未变更架构文档（参见累积视图或基线）」——二选一须在团队内统一；默认 **省略该节**。
- **`CHANGE_SCOPE`** 导致某要素未纳入计划：对应域不产生汇总块；`design.md` 中不出现该域章节。
- 文件名以 **`config.yaml` → `design_artifacts`** 为准；上表为默认名（`architecture.md`、`data.md` 等）。

---

## 统一汇总协议（合并规则）

1. **收集**：编排必须先收集本轮每个已执行要素会话中的 **`## 汇总输入（供 design.md 合并）`**；缺失则不得进入写盘步骤。
2. **摘要**：`design.md` 中每一条「摘要」级正文只能改编自结构块中的 `summary`，禁止脱离结构块对整个交付文件另写一套自由发挥的结论。
3. **引用**：`design.md` 中每一条「引用」须对应结构块中的 `references`，并保留 **文件名 → 章节标题** 的可跳转定位形式。
4. **状态**：尊重结构块 `status`；`no-change` / `not-applicable` 不得写成虚假增量描述。
5. **一致性**：若结构块与交付文件事实不一致、引用无法在目文件中解析、或整块缺失，**须暂停**，回到对应要素补齐或更正后再汇总。
6. **门禁（汇总前自检）**：  
   - 每个已派发要素均有汇总结构块；  
   - `references` 指向的路径存在且标题存在（抽检不一致则全量复核）；  
   - `pending` 已合并入「设计缺口与待确认」或明示「无」。

若门禁失败：**暂停并向用户列出证据路径**，选项包括：回补汇总块 / 修正交付文件后再汇总 / 用户书面确认接受不完整汇总后继续。

---

## `design.md` 模板示例

下列章节按需出现（未执行的要素域整节省略）。一级标题可按版本替换 `{VERSION}`。

```markdown
# {VERSION} 技术设计

## 0. 变更说明（增量专属）
- 基线设计目录：{path}
- 增量 PRD：{path}
- 存量系统信息：{path 或 "未提供"}
- PRD 变更条目：{PC-01, PC-02, ...}
- 触发变化点：{change_ids}
- 本次变更范围摘要

## A. 影响点索引（增量专属）
| DIP 编号 | 来源 PC | 来源变化点 | 触发类型 | 受影响要素 | action | baseline_ref |
|----------|--------|----------|---------|----------|--------|--------------|

> 以上两章仅在增量模式（design-incremental-build）下出现；新建模式省略。

## 架构决策
{从 overall-design.md / shared-context.md 已确认决策归纳}

## 受影响上下文
{来自 shared-context.md；无文件则省略本节前两处标题之一或标注不适用}

## 顶层架构与全局规范（greenfield only）
- 摘要：
  - ...
- 引用：
  - `architecture.md` → `{关键章节标题}`

## 数据存储与模型
- 摘要：
  - ...
- 引用：
  - `data.md` → `{关键章节标题}`

## API 契约
- 摘要：
  - ...
- 引用：
  - `backend-api.md` → `{关键章节标题}`

## 后端处理逻辑
- 摘要：
  - ...
- 引用：
  - `backend.md` → `{关键章节标题}`

## 前端展现与交互
- 摘要：
  - ...
- 引用：
  - `frontend.md` → `{关键章节标题}`

## 异步处理与系统集成
- 摘要：
  - ...
- 引用：
  - `integration.md` → `{关键章节标题}`

## 配置、字典、安全与权限
- 摘要：
  - ...
- 引用：
  - `config.md` → `{关键章节标题}`

## 设计缺口与待确认
{合并 shared-context 待确认项与各要素 pending}
```

---

## 草案审阅输出格式（增量模式专属，Phase 3A-1）

在增量模式下，`design.md` 汇总完成后、US 回填前（Phase 3A → Phase 3A-1），
须输出完整草案供用户审阅。

**草案章节来源**：

| 草案章节 | 内容来源 |
|---------|---------|
| 一、PRD 变更条目 | context.prd_change_register |
| 二、原子变化点 | context.triggered_changes（含 evidence_source） |
| 三、受影响设计要素总表 | effective_sequence（含触发类型和变化点） |
| 四、不涉及要素说明 | effective_sequence 的补集（含排除原因和验证依据） |
| 五、影响点清单（DIP） | context.impact_points（含 boundary_constraints 和 compatibility_note） |
| 六、US 设计引用预览 | DIP.source_prd_change → PrdChange.source_story 的预估关联 |

**审阅交互**：
- `[Y]` 确认，进入 Phase 3B
- `[B]` 修正后重新汇总
- `[Q]` 保存并退出

**约束**：草案必须完整列出所有 DIP，禁止因数量多而截断。

---

## 与其它步骤的先后顺序（编排约定）

在 **`spec/m-us-design-linkback.md`** 之前执行本文汇总：**先生成 `{DESIGN_DIR}/design.md`，再进行 Story 设计引用回填**，以便 US 可同时索引摘要文件与各要素交付文件。

---

## 完成消息（可选）

汇总写盘并自检通过后，可向用户宣告：**特性级 `design.md` 已按摘要引用协议生成**，并列出 `{DESIGN_DIR}/design.md`。
