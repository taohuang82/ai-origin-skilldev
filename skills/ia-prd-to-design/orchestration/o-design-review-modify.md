# 设计评审修改 编排文件
# workflow_id: design-review-modify
# 对应 workflow-registry 中 id: design-review-modify

## 前置说明
本编排文件由 workflow-engine 在命中 design-review-modify 后调用。
在用户提供评审意见的前提下，对既有设计文件做定向修改。
编排直接通过 `@subagent名称` 调用 Subagent，本文件控制宏观流程、门禁与轻量校验。

## ⚠️ 多文件输出约定
修改对象为 subagent-registry 中声明的已有 artifact_file。
Subagent 落盘后，orchestration 负责更新 frontmatter。

---

## 强制读取

1. `config.yaml`（含 `design_artifacts` 文件名映射）
2. 本 Skill `SKILL.md` 路径约定
3. `registry/subagent-registry.yaml`（唯一派发 SSOT）
4. `registry/dependency-graph.yaml`（Review ImpactRouter 子要素级联影响计算）
5. `registry/element-registry.yaml`（子要素展开与存在性校验）
6. `spec/m-design-summary-merge.md`（多文件变更后刷新特性级 `design.md` 摘要引用时使用）
7. `spec/m-design-complete.md`（统一完成收尾）
8. `spec/m-us-design-linkback.md`（US 与设计交付物索引关联的调用契约，须在回填阶段前加载）

---

## 编排结构

本工作流按以下结构执行：

1. **读取公共依赖**：读取 `config.yaml`、`SKILL.md` 路径约定、`registry/subagent-registry.yaml`、`registry/dependency-graph.yaml` 与汇总 spec。
2. **解析修改上下文**：解析用户评审意见，映射 `review_items`、`source_affected_elements` 与 `modify_focus`。
3. **恢复执行画像**：从 `workspace/ongoing.md` 或交付物 frontmatter 恢复 `execution_profile`。
4. **Review ImpactRouter 扩展影响域**：以 `source_affected_elements` 为主触发要素，沿 TDD 要素依赖图扩展 `cascade_elements` 与 `candidate_elements`。
5. **定位执行序列**：以 `final_affected_elements` 作为修改序列，每个元素绑定目标 artifact、修改范围与影响来源。
6. **执行要素修改调度**：按依赖就绪批次执行受影响 `element_id`；同批前置依赖均已输出的多个 Subagent 可并行派发。
7. **刷新汇总与索引回链**：跨多文件或影响可追溯性时刷新 `{DESIGN_DIR}/design.md`，并在 `story.md` 存在时加载 `spec/m-us-design-linkback.md` 执行索引回链。
8. **状态收尾**：更新 `workspace/ongoing.md` 与交付物 frontmatter，输出一次 C/B/S/Q 操作菜单后终止响应。

---

## Phase 1：定位修改范围

1. 解析评审意见 → 映射到一个或多个 `source_affected_elements.element_id`（父级设计域）。
2. 若能定位具体子要素，写入 `source_sub_element_ids[]`；若只能定位父级，则从 `element-registry.yaml` 展开该父级全部子要素作为起点，并标记 `source_sub_element_ids_inferred=true`。
3. 为每个命中项设置：
   - `context.output_doc_path`（从 subagent-registry 读取 `artifact_file`）
   - `context.modify_focus`（章节、表格名或要点列表）
4. 构造 `ReviewDesignChange`：

```yaml
ReviewDesignChange:
  review_item_id: "{评审项 ID}"
  source_element_id: "{直接命中的父级设计域 element_id}"
  source_sub_element_ids: ["{可选，直接命中的子要素 id}"]
  change_summary: "{评审意见要求的修改摘要}"
  modify_focus: "{章节、表格名或要点列表}"
  evidence: "{评审意见原文片段}"
```

---

## Phase 1.5：Review ImpactRouter 影响扩展（子要素级）

目标：当评审意见修改某个 TDD 子要素时，识别需要同步检查或修改的其他 TDD 子要素，再聚合为父级 Subagent 调度任务，避免只改直接要素导致跨文件设计不一致。

### 输入

- `review_items[]`
- `source_affected_elements[]`
- `ReviewDesignChange[]`（含 `source_sub_element_ids[]`）
- `registry/dependency-graph.yaml`
- `registry/element-registry.yaml`
- `registry/subagent-registry.yaml`

### 扩展规则

1. 以所有 `ReviewDesignChange.source_sub_element_ids[]` 作为 `primary_sub_elements` 起点集合。
2. 遍历 `dependency-graph.yaml.impact_edges`，对 `direct` 边做子要素闭包扩展：
   - 从 `primary_sub_elements` 入队，逐个读取 `source.sub_element_id == current` 的 targets。
   - 若 target.`impact_type == direct` 且 target.`sub_element_id` 尚未访问，加入 `cascade_sub_elements` 并继续入队。
   - 若 target.`impact_type == indirect`，加入 `candidate_sub_elements`，仅提示，不自动执行。
   - 维护 `visited_sub_elements`，避免 dependency cycle 造成重复扩展。
3. 将 `primary_sub_elements` 与 `cascade_sub_elements` 按其在 `element-registry.yaml` 中解析出的 `parent_element_id` 聚合为 `final_affected_elements`：
   - 同一父级下多个子要素命中时，合并为一条 Subagent 调度任务，`sub_element_ids[]` 取并集。
   - 若子要素来自 `primary_sub_elements`，设置 `trigger_type=primary`。
   - 若子要素仅来自 `cascade_sub_elements`，设置 `trigger_type=cascade`，写入 `cascade_from`、`cascade_from_sub_element_ids[]`、`cascade_reason`。
   - 若父级同时含 primary 与 cascade 子要素，保留 `trigger_type=primary`，并将 cascade 来源写入 `cascade_from_sub_element_ids[]` 作为背景。
4. 对 `candidate_sub_elements` 输出确认菜单：

```text
🛡️ Review ImpactRouter 发现间接影响候选（子要素级）：
  - {target.sub_element_id}（parent={element-registry.parent_element_id}）← 来源 {source.sub_element_id}，原因：{reason}
是否加入本次评审修改范围？
  [Y] 全部加入  [N] 全部忽略  [S] 选择性加入
```

5. 用户选择加入的 `candidate_sub_elements` 视为 `trigger_type=cascade`，合并进对应父级的 `sub_element_ids[]`；其 indirect 下游不再自动继续扩展，除非用户明确要求继续分析。
6. **Registry 轻量校验**（阻断级）：
   - source / target 子要素都必须可解析于 `element-registry.yaml`
   - target.`sub_element_id` 解析出的 `parent_element_id` 必须能在 `subagent-registry.yaml` 找到派发对象
7. 若 `dependency-graph.yaml` 中出现的 target 父级不存在于 `subagent-registry.yaml`，阻断并提示 registry 不一致，不调用 Subagent。

### 输出

```yaml
final_affected_elements:
  - element_id: "data-model"
    domain: "data"
    parent_element_id: "data-model"
    sub_element_ids: [data-table]
    trigger_type: "primary"
    review_item_ids: ["RI-001"]
    modify_focus: "数据表字段兼容说明"
  - element_id: "api-contract"
    domain: "backend"
    parent_element_id: "api-contract"
    sub_element_ids: [be-api]
    trigger_type: "cascade"
    cascade_from: "data-model"
    cascade_from_sub_element_ids: [data-table]
    cascade_reason: "table fields drive API request/response fields"
    review_item_ids: ["RI-001"]
    modify_focus: "检查并同步与 data-table 修改相关的 API 入参出参"
    cascade_impact_type: "direct"
```

`final_affected_elements` 按 `subagent-registry.chapter_no` 升序排序；同一 `element_id` 被多个评审项命中时合并 `review_item_ids` 与 `sub_element_ids[]`，`modify_focus` 以列表形式保留全部来源。

---

## Subagent 调用协议

本编排对每个 design 域 Subagent 直接执行以下协议。

### 调用前门禁

1. 从 `subagent-registry.yaml` 筛选 `element_id == 当前 element_id` 的条目。
2. 若有 `select_when`，与 `execution_profile` 逐项匹配；零命中或多命中时暂停确认。
3. 检查当前 `element_id` 对应的 artifact 文件已存在。
4. 若 registry 声明 `depends_on`，检查其中每个 `element_id` 对应的 artifact 文件已存在。
5. 检查 `force_read[]` 中所有路径对应的文件存在；不存在则阻断。
6. 检查 `force_read_by_mode`：仅当前 `EXECUTION_MODE` 命中时强制；不命中时跳过。
7. 检查 `optional_read[]`：存在则注入 Prompt，不存在不阻断。
8. 检查 `modify_focus` 已明确到章节、表格名或要点列表；不明确时暂停确认。
9. 按 `element_ids[]` 从 `element-registry.yaml` 解析 `prd_sources` 并透传 Prompt；只做元数据展开，不解释、不裁剪 PRD 章节规则。
10. 任一不满足时暂停，等待用户处理，不调用。

### Prompt 组装（modify 模式）

```text
WORKFLOW_ID: design-review-modify
EXECUTION_MODE: modify
element_id: {当前 element_id}
domain: {final_affected_elements 条目的 domain}
parent_element_id: {final_affected_elements 条目的 parent_element_id}
target_sub_element_ids[]: {final_affected_elements 条目的 sub_element_ids[]}
SUBAGENT_NAME: {subagent-registry.name}
SKILL_ROOT: {SKILL_ROOT}
SPEC_ROOT: {SKILL_ROOT}/spec/
STANDARDS_ROOT: {SKILL_ROOT}/standards/
element_ids[]: {subagent-registry.element_ids[]}
prd_sources: {按 element_ids[] 从 element-registry.yaml 解析出的 required_sections / optional_sections / extraction_keys}
PRD_FILE: {PRD_FILE}
STORY_FILE: {STORY_FILE}（若存在）
output_doc_path: {DESIGN_DIR}/{artifact_file}
modify_focus: {modify_focus}
trigger_type: {primary | cascade}
impact_source_review_items: {review_item_ids[]}
cascade_from: {cascade_from，primary 为空}
cascade_from_sub_element_ids[]: {cascade_from_sub_element_ids[]，primary 为空}
cascade_reason: {cascade_reason，primary 为空}
cascade_impact_type: {direct | indirect | none}
OVERALL_DESIGN_FILE: {DESIGN_DIR}/overall-design.md（若存在）
force_read[]: {subagent-registry.force_read[]}（路径变量已展开）
chapter_info:
  chapter_no: {subagent-registry.chapter_no}
  element_name: {element_name}

约束（强制）：
- 严格按 Subagent 自身 Step 0–5 执行
- 若 `target_sub_element_ids[]` 非空，Subagent 只能处理这些子要素
- 禁止跳过 Step 0；禁止写入 frontmatter
- Step 4 必须逐项输出自检报告（含 ❌ 标记）
- 仅修改 modify_focus 命中分节；其余分节保留
- trigger_type=cascade 时，必须先判断本 artifact 是否确需改动；若无需改动，返回 `⏭️ SKIPPED: no downstream impact` 并说明依据
- 修改处追加：<!-- Modified: review_item={item_id}, op={op_type}, date={YYYY-MM-DD}, summary={修改摘要} -->
- 必须返回 executed_sub_elements[] + ## 质量自检报告 + ## 汇总输入（供 design.md 合并）
- 禁止在返回载荷中粘贴 artifact 全文
```

### Subagent 调用

- 调用方式：使用 `@{SUBAGENT_NAME}` 发起 subagent，并附带上方完整 Prompt 载荷
- 等待返回 `DONE` / `⏭️ ...`
- 失败/超时 → 暂停，可选 [B] 重新调用 / [Q] 退出
- 并行派发：同一 `ready_batch` 内的 Subagent 可同时发起；每个 Subagent 仍必须独立携带完整 Prompt 载荷与本要素的 `modify_focus`。

### 轻量后置校验

Subagent 返回后执行（不重读 spec/standards）：

1. 若返回 `⏭️ SKIPPED: no downstream impact`：
   - 要求返回跳过依据，且依据必须引用 `cascade_from` / `cascade_reason` / artifact 现状之一。
   - 不执行 artifact 内容扫描，不写 frontmatter，不追加 `collected_summaries[]`。
   - 将 element_id 记录到 `skipped_cascade_elements[]`。
2. **汇总块结构完整性**：载荷须含字面量标题 `## 汇总输入（供 design.md 合并）`；缺失则阻断。
3. **自检报告存在性**：载荷须含 `## 质量自检报告`；缺失则阻断。
4. **空内容正则扫描**：Read artifact 文件，检查 Mermaid 无节点/连线、章节标题存在但正文为空、表格有表头无数据行。
5. **占位符正则扫描**：artifact 中不得出现 `[待补充]`、`TODO`、`XXX`、`待确认`、`示例值`。
6. **修改范围扫描**：确认改动仅落在 `modify_focus` 命中分节；越界则阻断。
7. 不通过 → [B] 重新调用 subagent（可附带问题清单）/ [Q] 退出。
8. 通过 → 汇总块追加至 `collected_summaries[]`。

### 汇总块透传

- 将 Subagent 返回的 `## 汇总输入（供 design.md 合并）` 结构块**原样** append 至 `collected_summaries[]`。
- 禁止 orchestration 改写汇总块内容。

### frontmatter 写入

- 本域落盘后，orchestration 负责 Read artifact 的 YAML frontmatter → 更新以下字段：
  - `last_modified`：当前日期
  - `review_items`：追加本次处理的评审项 ID
  - `last_updated`：当前日期
- 使用 Edit 工具精确匹配，禁止 Write 覆盖全文。
- Subagent 禁止写入 frontmatter。

---

## Phase 2：按要素修改调度

初始化 `collected_summaries: []`、`skipped_cascade_elements: []`；注入 `context.execution_profile`（从 ongoing 或交付 frontmatter 恢复）。

按依赖就绪批次调度受影响要素：

```
pending = final_affected_elements
existing_artifacts = 已存在 artifact_file 的 element_id 集合
completed_elements = []

WHILE pending 非空:
  1. ready_batch = pending 中满足以下条件的要素：
       - depends_on 对应 artifact 均存在于 existing_artifacts
       - depends_on 中若也在 pending/final_affected_elements，则必须已在 completed_elements 或 skipped_cascade_elements
  2. 若 ready_batch 为空：阻断并提示依赖缺口或 dependency cycle，不调用
  3. PARALLEL FOR element IN ready_batch:
       a. 执行「Subagent 调用协议」→ 调用前门禁
       b. 设置 modify_focus + trigger_type + cascade_from + cascade_reason（Phase 1/1.5 已填）
       c. 执行「Subagent 调用协议」→ Prompt 组装 + Subagent 调用
  4. 等待 ready_batch 全部返回后，按 chapter_no 升序逐项执行：
       a. 执行「Subagent 调用协议」→ 轻量后置校验
       b. 执行「Subagent 调用协议」→ 汇总块透传 + frontmatter 写入
       c. 将 element_id 加入 completed_elements，并从 pending 移除
```

---

## Phase 3：刷新汇总与 Story

若改动跨多文件：

- **特性级 `design.md`**：若本次修改影响跨域可追溯性，按 `spec/m-design-summary-merge.md` Read `collected_summaries[]` 更新 `{DESIGN_DIR}/design.md`。
- **US 同步（条件执行）**：若 `{DESIGN_DIR}/story.md` 存在，**加载 `spec/m-us-design-linkback.md`**，按该规范执行本阶段；subagent 的调用方式、输入/输出契约与校验规则均以该规范为准（编排不在此重复声明）。

---

## Phase 4：完成收尾 + C/B/S/Q

1. 调用 `spec/m-design-complete.md` 完成评审修改收尾。
2. 完成报告下一步建议只保留 `/iscit-dev-new story.md`。

⚠️ 输出操作菜单后立即终止响应，等待用户选择。
