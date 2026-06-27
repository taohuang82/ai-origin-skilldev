# 设计续接恢复 编排文件
# workflow_id: design-resume
# 对应 workflow-registry 中 id: design-resume

## 前置说明
本编排文件由 workflow-engine 在命中 design-resume 后调用。
在存在未完成设计文档（status == "in_progress"）时，从断点处续接要素执行。
编排直接通过 `@subagent名称` 调用 Subagent，本文件控制宏观流程、门禁与轻量校验。

## ⚠️ 多文件输出约定
每个要素对应 subagent-registry 中声明的 artifact_file。
Subagent 落盘后，orchestration 负责更新 frontmatter。

---

## 强制读取

1. 本 Skill 根目录 `config.yaml`（含 `design_artifacts` 文件名映射）
2. 本 Skill `SKILL.md` 中 **路径约定**
3. `workspace/ongoing.md`
4. `registry/subagent-registry.yaml`（唯一派发 SSOT）
5. `spec/m-design-summary-merge.md`（全部要素完成后的特性级 `design.md` 汇总）
6. `spec/m-design-complete.md`（统一完成收尾）
7. `spec/m-us-design-linkback.md`（US 与设计交付物索引关联的调用契约，须在回填阶段前加载）

---

## 编排结构

本工作流按以下结构执行：

1. **读取公共依赖**：读取 `config.yaml`、`SKILL.md` 路径约定、`workspace/ongoing.md`、`registry/subagent-registry.yaml` 与汇总 spec。
2. **恢复断点上下文**：扫描 `{DESIGN_DIR}` 下 `status == "in_progress"` 的交付物，从 frontmatter 恢复 `stepsCompleted`、`last_element`、原始 workflow 与 `execution_profile`。
3. **重建执行序列**：按原始上下文重新生成全量序列，再排除已完成要素，得到 `resumed_sequence`。
4. **执行续接调度**：按依赖就绪批次执行 `resumed_sequence`；同批前置依赖均已输出的多个 `element_id` 可并行派发 Subagent。
5. **汇总与索引回链**：全部续接要素完成后刷新 `{DESIGN_DIR}/design.md`，并在 `story.md` 存在时加载 `spec/m-us-design-linkback.md` 执行索引回链。
6. **状态收尾**：更新 `workspace/ongoing.md` 与交付物 frontmatter，输出一次 C/B/S/Q 操作菜单后终止响应。

---

## Phase 0：续接状态恢复

1. 解析路径变量（定义见 SKILL.md 路径约定）：`VERSION`、`FEATURE_SUBDIR`、`DESIGN_DIR`。
2. 扫描 `{DESIGN_DIR}` 下设计交付文件的 frontmatter，找到 `status == "in_progress"` 的文档。
3. 从 frontmatter 还原 `stepsCompleted`、`last_element`，确定断点位置。
4. 恢复原始上下文（业务维度、覆盖范围、`execution_profile`），优先从交付文件 frontmatter 读取，补充从 `workspace/ongoing.md` 获取；维度合法性以 `config.yaml` 的 `runtime_dimensions` 为准。

---

## Phase 1：重建 effective_sequence

1. 从 `registry/subagent-registry.yaml` 动态读取全量要素，按原始上下文过滤；业务维度与序列排除规则必须读取 `config.yaml` 的 `runtime_dimensions`，不得引用其他 workflow 文件中的硬编码规则。
2. 排除 `stepsCompleted` 中已完成的要素，得到待续接序列。
3. artifact_file 从 subagent-registry 动态读取。

---

## Subagent 调用协议

本编排对每个 design 域 Subagent 直接执行以下协议。

### 调用前门禁

1. 从 `subagent-registry.yaml` 筛选 `element_id == 当前 element_id` 的条目。
2. 若有 `select_when`，与恢复后的 `execution_profile` 逐项匹配；零命中或多命中时暂停确认。
3. 检查 `depends_on` 中每个 `element_id` 对应的 artifact 文件已存在。
4. 检查 `force_read[]` 中所有路径对应的文件存在；不存在则阻断。
5. 检查 `force_read_by_mode`：仅当前 `EXECUTION_MODE` 命中时强制；不命中时跳过。
6. 检查 `optional_read[]`：存在则注入 Prompt，不存在不阻断。
7. 已存在于 `stepsCompleted` 的要素不得重复派发。
8. 按 `element_ids[]` 从 `element-registry.yaml` 解析 `prd_sources` 并透传 Prompt；只做元数据展开，不解释、不裁剪 PRD 章节规则。
9. 任一不满足时暂停，等待用户处理，不调用。

### Prompt 组装（resume 模式）

```text
WORKFLOW_ID: design-resume
EXECUTION_MODE: {从原始 workflow 恢复；build / incremental}
element_id: {当前 element_id}
SUBAGENT_NAME: {subagent-registry.name}
SKILL_ROOT: {SKILL_ROOT}
SPEC_ROOT: {SKILL_ROOT}/spec/
STANDARDS_ROOT: {SKILL_ROOT}/standards/
element_ids[]: {subagent-registry.element_ids[]}
prd_sources: {按 element_ids[] 从 element-registry.yaml 解析出的 required_sections / optional_sections / extraction_keys}
PRD_FILE: {PRD_FILE}
STORY_FILE: {STORY_FILE}（若存在）
output_doc_path: {DESIGN_DIR}/{artifact_file}
base_doc_path: {BASELINE_DESIGN_DIR}/{artifact_file}（原始 workflow 为 incremental 时必传）
OVERALL_DESIGN_FILE: {DESIGN_DIR}/overall-design.md（若存在）
force_read[]: {subagent-registry.force_read[]}（路径变量已展开）
chapter_info:
  chapter_no: {subagent-registry.chapter_no}
  element_name: {element_name}
impact_analysis:
  element_changes: {本要素相关的变化点列表，incremental 续接时必传}
  change_expectation: {每条压缩为一行：{change_id}: {description}（op={op}），incremental 续接时必传}
  reason: {evidence 摘要，incremental 续接时必传}

约束（强制）：
- 严格按 Subagent 自身 Step 0–5 执行
- 禁止跳过 Step 0；禁止写入 frontmatter
- Step 4 必须逐项输出自检报告（含 ❌ 标记）
- 必须返回 executed_sub_elements[] + ## 质量自检报告 + ## 汇总输入（供 design.md 合并）
- 禁止在返回载荷中粘贴 artifact 全文
- 若原始 workflow 为 incremental，须通过 impact_analysis 字段注入 change_expectation，且 artifact 中须保留 `<!-- DELTA: ... -->` 块
```

### Subagent 调用

- 调用方式：使用 `@{SUBAGENT_NAME}` 发起 subagent，并附带上方完整 Prompt 载荷
- 等待返回 `DONE` / `⏭️ ...`
- 失败/超时 → 暂停，可选 [B] 重新调用 / [Q] 退出
- 并行派发：同一 `ready_batch` 内的 Subagent 可同时发起；每个 Subagent 仍必须独立携带完整 Prompt 载荷。

### 轻量后置校验

Subagent 返回后执行（不重读 spec/standards）：

1. **汇总块结构完整性**：载荷须含字面量标题 `## 汇总输入（供 design.md 合并）`；缺失则阻断。
2. **自检报告存在性**：载荷须含 `## 质量自检报告`；缺失则阻断。
3. **空内容正则扫描**：Read artifact 文件，检查 Mermaid 无节点/连线、章节标题存在但正文为空、表格有表头无数据行。
4. **占位符正则扫描**：artifact 中不得出现 `[待补充]`、`TODO`、`XXX`、`待确认`、`示例值`。
5. **增量续接检查**：若原始 workflow 为 incremental，artifact 中须含 `<!-- DELTA: ... -->` 块；缺失则阻断。
6. 不通过 → [B] 重新调用 subagent（可附带问题清单）/ [Q] 退出。
7. 通过 → 汇总块追加至 `collected_summaries[]`。

### 汇总块透传

- 将 Subagent 返回的 `## 汇总输入（供 design.md 合并）` 结构块**原样** append 至 `collected_summaries[]`。
- 禁止 orchestration 改写汇总块内容。

### frontmatter 写入

- 本域落盘后，orchestration 负责 Read artifact 的 YAML frontmatter → 更新以下字段：
  - `stepsCompleted`：追加当前 element_id
  - `last_element`：更新为当前 element_id
  - `last_updated`：当前日期
  - `status`：全部续接要素完成后改为 "completed"
- 使用 Edit 工具精确匹配，禁止 Write 覆盖全文。
- Subagent 禁止写入 frontmatter。

---

## Phase 2：要素执行调度

初始化 `collected_summaries: []`；注入 `context.execution_profile`（Phase 0 已恢复）。

按依赖就绪批次调度续接序列（`stepsCompleted` 中已完成的要素跳过）：

```
pending = resumed_sequence - stepsCompleted
completed_elements = stepsCompleted ∪ 已存在 artifact_file 的 element_id 集合

WHILE pending 非空:
  1. ready_batch = pending 中 depends_on 对应 artifact 均已存在或已在 completed_elements 的要素
  2. 若 ready_batch 为空：阻断并提示依赖缺口或 dependency cycle，不调用
  3. PARALLEL FOR entry IN ready_batch:
       a. 执行「Subagent 调用协议」→ 调用前门禁
       b. 执行「Subagent 调用协议」→ Prompt 组装 + Subagent 调用
  4. 等待 ready_batch 全部返回后，按 chapter_no 升序逐项执行：
       a. 执行「Subagent 调用协议」→ 轻量后置校验
       b. 执行「Subagent 调用协议」→ 汇总块透传 + frontmatter 写入
       c. 将 element_id 加入 completed_elements，并从 pending 移除
```

---

## Phase 2A：汇总生成 `{DESIGN_DIR}/design.md`

在所有要素均已成功结束后：

1. 按 `spec/m-design-summary-merge.md` Read `collected_summaries[]`，写入 `{DESIGN_DIR}/design.md`。
2. 若门禁失败，按该 spec 暂停策略处理。

---

## Phase 2B：US 与设计交付物索引关联（条件执行）

1. 若 `{DESIGN_DIR}/story.md` 不存在，跳过。
2. 若存在，**加载 `spec/m-us-design-linkback.md`**，按该规范执行本阶段；subagent 的调用方式、输入/输出契约与校验规则均以该规范为准（编排不在此重复声明）。

---

## Phase 3：完成收尾 + C/B/S/Q

1. 调用 `spec/m-design-complete.md` 完成统一收尾。
2. 完成报告下一步建议只保留 `/iscit-dev-new story.md`。

⚠️ 输出操作菜单后立即终止响应，等待用户选择。
