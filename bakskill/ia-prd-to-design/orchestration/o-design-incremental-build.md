# 设计增量/更新 编排文件
# workflow_id: design-incremental-build
# 对应 workflow-registry 中 id: design-incremental-build
# 嵌入 TDD 高阶方案七步同构逻辑（v2.0.0）

## 前置说明
本编排文件由 workflow-engine 在命中 design-incremental-build 后调用。
通过 PRD 变更结构化路由（ChangeRouter），
基于 35 类原子变化点精确识别受影响设计要素，生成 DIP 影响点与 DELTA 增量标注。
编排直接通过 `@subagent名称` 调用 Subagent，本文件控制宏观流程、门禁与轻量校验。

## ⚠️ 多文件输出约定
每个要素对应 subagent-registry 中声明的 artifact_file。
Subagent 落盘后，orchestration 负责更新 frontmatter。

---

## 强制读取

1. 本 Skill 根目录 `config.yaml`（含 `design_artifacts` 文件名映射、`extension_registry` 挂载点）
2. 本 Skill `SKILL.md` 中 **路径约定**（`WORKSPACE_ROOT`、`DESIGN_DIR`、`INCR_PRD_FILE`、`LEGACY_CONTEXT`、`DESIGN_ACCUM_FILE` 等路径变量）
3. `{WORKSPACE_ROOT}/workspace/ongoing.md`
4. `registry/subagent-registry.yaml`（唯一派发 SSOT）
9. `spec/m-design-summary-merge.md`（全部要素完成后的特性级 `design.md` 汇总）
10. `spec/m-design-overall.md`（ChangeRouter 前的整体方向确认）
11. `spec/m-design-complete.md`（统一完成收尾）
12. `spec/m-us-design-linkback.md`（US 与设计交付物索引关联的调用契约，须在回填阶段前加载）

---

## 编排结构

本工作流按以下结构执行：

1. **读取公共依赖与增量注册表**：读取 `config.yaml`、`SKILL.md` 路径约定、`workspace/ongoing.md`、变化点 registry、依赖图、`subagent-registry.yaml` 与汇总 spec。
2. **解析运行上下文**：建立 `WORKSPACE_ROOT`、`VERSION`、`FEATURE_SUBDIR`、`DESIGN_DIR`、`PRD_FILE`、`INCR_PRD_FILE`、`LEGACY_CONTEXT`、`DESIGN_ACCUM_FILE`。
3. **探索并冻结执行画像**：先执行知识库探索与技术澄清，再确定 `CHANGE_SCOPE` 与 `execution_profile`。
4. **执行 ChangeRouter**：调用 `@ia-overall-designer` Stage-B，从 PRD 识别变化点、映射子要素影响、经依赖图校验，写入 `overall-design.md` §7 + ORCH 块。
5. **确认整体方案方向**：调用 `@ia-overall-designer` Stage-A，基于 `effective_sequence` 产出聚焦受影响的域的方向设计 `overall-design.md` §1–§6。
6. **展示并冻结执行计划**：从 `overall-design.md` §7 ORCH 块加载 `effective_sequence` 与 `display_summary`，展示模板等用户确认。
7. **执行要素调度**：按依赖就绪批次执行 `effective_sequence`；同批前置依赖均已输出的多个 `element_id` 可并行派发 Subagent，并注入影响分析。
8. **汇总与索引回链**：生成含变更说明、DIP 索引和引用的 `{DESIGN_DIR}/design.md`，并在 `story.md` 存在时加载 `spec/m-us-design-linkback.md` 执行索引回链。
9. **状态收尾**：更新 `workspace/ongoing.md`、`DESIGN_ACCUM_FILE` 与交付物 frontmatter，输出一次 C/B/S/Q 操作菜单后终止响应。

---

## 业务判定模型

本编排不在 workflow 文件内声明业务维度取值或分支矩阵。运行时判定必须遵从 `config.yaml`：

1. 从 `runtime_dimensions.project_type`、`runtime_dimensions.change_scope` 读取合法取值与序列过滤规则。
2. 从 `runtime_dimensions.project_type.backend_variant` 推导后端实现分支，并通过 `execution_profile.backend_variant` 与 `subagent-registry.yaml` 的 `select_when` 完成 Subagent 选择。
3. 从 `runtime_dimensions.change_scope.sequence_exclusions` 获取前端/后端覆盖范围对候选序列的影响。
4. `execution_profile` 字段集合以 `runtime_dimensions.execution_profile_fields` 为准。

禁止把项目类型当作前后端覆盖范围的代理。覆盖范围在知识探索收敛前不得假定取值。

**工程结构**：默认兼容单工程与 `backend/` + `frontend/` 双工程目录。

**执行画像**：知识探索完成后按 `runtime_dimensions.execution_profile_fields` 生成，并向下游传递。

---

## Phase 0：解析上下文（TDD 高阶 Step 0 环境准备）

1. 解析路径变量：`VERSION`、`FEATURE_SUBDIR`、`DESIGN_DIR`、`PRD_FILE`、`STORY_FILE`、`DESIGN_ACCUM_FILE`。
2. **解析 `INCR_PRD_FILE`**：默认等同 `PRD_FILE`；若增量 PRD 独立文件，须在 ongoing.md 或用户指定中解析。
3. **解析 `LEGACY_CONTEXT`**：扫描存量系统信息路径列表；缺位时标记降级为对话挖掘。
4. 校验 `PRD_FILE` / `INCR_PRD_FILE` 存在且可读；**禁止**主 Agent Read 全文。
   PRD 变更识别由 `@ia-overall-designer` Stage-B 负责。
5. 增量对齐入口由 `@ia-overall-designer` Stage-B 负责解析，编排不代劳。

---

## Phase 1：现有知识库探索（强制先于要素执行）

**orchestration 直接调用** `@ia-dependency-analyzer`（`dispatch_via: orchestration-direct`，前台 Task，`run_in_background: false`）。

Prompt 须注入：`WORKFLOW_ID`、`EXECUTION_MODE: incremental`、`PRD_FILE`、`DESIGN_DIR`、`DESIGN_ACCUM_FILE`、`LEGACY_CONTEXT`、`output_doc_path: {DESIGN_DIR}/shared-context.md`。

通过条件与编排落地事项：

1. 产出 `{DESIGN_DIR}/shared-context.md`（章节结构与禁码、导航字段见 Subagent 返回约定）。
2. **存量系统信息收录**：按 Subagent 约定执行。
3. **在探索收敛前不得假定 `CHANGE_SCOPE`**；依据 PRD 明文、`decision_facts` 与双工程检索结论确定 `CHANGE_SCOPE`。
4. 若 Subagent 返回 `NEEDS_USER_CLARIFICATION`，先完成澄清与回填，再进入后续 Phase。
5. 仅当 Subagent 返回 `READY_FOR_OVERALL_DESIGN` 且 `resolution_confidence >= medium` 后，才可冻结 `CHANGE_SCOPE` 与 `execution_profile`。
6. 按 `config.yaml` 的 `runtime_dimensions.execution_profile_fields` 派生 `execution_profile`：
   - `has_frontend: CHANGE_SCOPE in [frontend, fullstack]`
   - `has_backend: CHANGE_SCOPE in [backend, fullstack]`
   - `backend_variant: PROJECT_TYPE == AP ? ap : standard`
   - `enable_ai: PROJECT_TYPE == AI and has_backend == true`
7. 将 `CHANGE_SCOPE`、`execution_profile` 与 `shared-context.md` 路径作为下游共有输入保存在编排上下文；同时写入 `shared-context.md` 的 `decision_facts` 或等价小节。

---

## Phase 1A：ChangeRouter（Subagent 执行，先于方向确认）

**前置**：`{DESIGN_DIR}/shared-context.md` 已生成，`CHANGE_SCOPE` 与 `execution_profile` 已冻结。

**执行**：前台调用 `@ia-overall-designer`，`STAGE=change-router`。
Prompt 按 `spec/m-design-overall.md` → **Prompt 组装：change-router 模式**。
ChangeRouter 以 `shared-context.md` 中的架构上下文（技术栈、存量系统、决策事实）替代 overall-design §1–§6 作为路由依据。

**通过条件**：
- `{DESIGN_DIR}/overall-design.md` §7 已追加
- ORCH 块 (`<!-- ORCH:BEGIN change-router -->`) 存在且 YAML 可解析
- YAML 中 `status == READY_FOR_EXECUTION_PLAN_REVIEW`
- `effective_sequence` 非空（若空则说明无受影响的要素，直接进入收尾）

**澄清处理**：
- 若 Subagent 返回 `NEEDS_USER_CLARIFICATION`：主 Agent 转述澄清问题，等待用户答复后重派 Stage-B
- 重派时仅覆盖 §7 + ORCH 块

---

## Phase 1B：整体方案方向确认（基于影响域聚焦设计）

**前置**：ChangeRouter 已完成，`{DESIGN_DIR}/overall-design.md` §7 ORCH 块中的 `effective_sequence` 已就绪。

在方向设计前，先通过 ChangeRouter 明确哪些域受影响，再做**聚焦域的方向设计**而非全量设计。

执行方式：按 `spec/m-design-overall.md` 的 **通用触发门禁**、**incremental 追加门禁**、**Prompt 组装：incremental 模式 (Stage-A)** 与 **确认门禁** 调用 `@ia-overall-designer` (STAGE=direction)。
Stage-A 接收 `effective_sequence` 作为输入，仅对受影响的设计域产出方向级内容。

通过条件：`{DESIGN_DIR}/overall-design.md` §1–§6 已生成，且用户已明确确认其可作为方向依据。

---

## Phase 2：执行计划展示与确认

1. Read `{DESIGN_DIR}/overall-design.md` §7 ORCH 块
2. 解析 YAML 中的 `effective_sequence` / `excluded_elements` / `display_summary`
3. 注入到编排上下文 `context.impact_analysis`
4. 渲染展示模板：

以下模板变量**必须**从 ORCH 块的 `display_summary` 中直接取值，禁止重新计算：

输出如下模板，等待用户确认：

```text
✅ 设计增量影响域分析完成

受影响设计要素（按执行顺序）：
  {no}. {element_name}（{trigger_type}，子要素 {target_sub_element_ids[]}）

不涉及要素：{排除的要素及原因}

[C] 开始执行  [B] 重做 ChangeRouter  [Q] 退出
```

- 用户选 `[C]`：冻结 scope，进入 Phase 3
- 用户选 `[B]`：**回到 Phase 1A 重新执行 ChangeRouter**，完成后自动触发 Phase 1B 重新确认方向（因为方向设计依赖影响域输出）
- 用户选 `[Q]`：保存当前上下文到 ongoing.md 后退出

---

## Subagent 调用协议

本编排对每个 design 域 Subagent 直接执行以下协议。

### 调用前门禁

1. 从 `subagent-registry.yaml` 筛选 `element_id == 当前 element_id` 的条目。
2. 若有 `select_when`，与 `execution_profile` 逐项匹配；零命中或多命中时提示用户并按默认策略处理：零命中使用该 `element_id` 的基础条目，多命中选择 `priority` 最高的条目（未配置 `priority` 时取 registry 中排序最前的条目）。
3. 检查 `depends_on` 中每个 `element_id` 对应的 artifact 文件已存在。
4. 检查 `force_read[]` 中所有路径对应的文件存在；不存在则阻断。
5. 检查 `force_read_by_mode`：仅当前 `EXECUTION_MODE` 命中时强制；不命中时跳过。
6. 检查 `optional_read[]`：存在则注入 Prompt，不存在不阻断。
7. 按 `element_ids[]` 从 `element-registry.yaml` 解析 `prd_sources` 并透传 Prompt；只做元数据展开，不解释、不裁剪 PRD 章节规则。
8. 任一不满足时提示用户并执行默认处理；仅当必读依赖缺失且无法降级时阻断，不再暂停等待用户确认。

### Prompt 组装（incremental 模式）

```text
WORKFLOW_ID: design-incremental-build
EXECUTION_MODE: incremental
element_id: {当前 element_id}
domain: {effective_sequence 条目的 domain}
parent_element_id: {effective_sequence 条目的 parent_element_id}
target_sub_element_ids[]: {effective_sequence 条目的 target_sub_element_ids[]}
trigger_type: {primary | cascade}
cascade_from_sub_element_ids[]: {cascade 来源子要素，primary 为空}
cascade_reason: {cascade 原因，primary 为空}
SUBAGENT_NAME: {subagent-registry.name}
SKILL_ROOT: {SKILL_ROOT}
SPEC_ROOT: {SKILL_ROOT}/spec/
STANDARDS_ROOT: {SKILL_ROOT}/standards/
element_ids[]: {subagent-registry.element_ids[]}
prd_sources: {按 element_ids[] 从 element-registry.yaml 解析出的 required_sections / optional_sections / extraction_keys}
PRD_FILE: {PRD_FILE}
STORY_FILE: {STORY_FILE}（若存在）
output_doc_path: {DESIGN_DIR}/{artifact_file}
OVERALL_DESIGN_FILE: {DESIGN_DIR}/overall-design.md（若存在）
force_read[]: {subagent-registry.force_read[]}（路径变量已展开）
chapter_info:
  chapter_no: {subagent-registry.chapter_no}
  element_name: {element_name}
impact_analysis:
  element_changes: {从 ORCH 块 effective_sequence 对应条目读取}
  change_expectation: {从 ORCH 块 impact_analysis.change_expectation 读取}
  reason: {从 ORCH 块 impact_analysis.reason 读取}

约束（强制）：
- 严格按 Subagent 自身 Step 0–5 执行
- 若 `target_sub_element_ids[]` 非空，Subagent 只能处理这些子要素
- `trigger_type=cascade` 时，Subagent 先判断本 artifact 是否确需修改；若无需修改，允许返回 `⏭️ SKIPPED: no downstream impact` 并说明依据
- 禁止跳过 Step 0；禁止写入 frontmatter
- Step 4 必须逐项输出自检报告（含 ❌ 标记）
- 必须返回 executed_sub_elements[] + ## 质量自检报告 + ## 汇总输入（供 design.md 合并）
- 禁止在返回载荷中粘贴 artifact 全文
- 须通过 impact_analysis 字段注入 change_expectation
- artifact 中须保留 `<!-- DELTA: ... -->` 块
```

### Subagent 调用

- 调用方式：使用 `@{SUBAGENT_NAME}` 发起 subagent，并附带上方完整 Prompt 载荷
- 等待返回 `DONE` / `⏭️ ...`
- 失败/超时 → 暂停，可选 [B] 重新调用 / [Q] 退出
- 并行派发：同一 `ready_batch` 内的 Subagent 可同时发起；每个 Subagent 仍必须独立携带完整 Prompt 载荷与本要素的 `impact_analysis`。

### 轻量后置校验

Subagent 返回后执行（不重读 spec/standards）：

1. **汇总块结构完整性**：载荷须含字面量标题 `## 汇总输入（供 design.md 合并）`；缺失则阻断。
2. **自检报告存在性**：载荷须含 `## 质量自检报告`；缺失则阻断。
3. **空内容正则扫描**：Read artifact 文件，检查 Mermaid 无节点/连线、章节标题存在但正文为空、表格有表头无数据行。
4. **占位符正则扫描**：artifact 中不得出现 `[待补充]`、`TODO`、`XXX`、`待确认`、`示例值`。
5. **DELTA 块检查**：artifact 中须含 `<!-- DELTA: ... -->` 块；缺失则阻断。
6. 不通过 → [B] 重新调用 subagent（可附带问题清单）/ [Q] 退出。
7. 通过 → 汇总块追加至 `collected_summaries[]`，DIP 累积至 `context.impact_points`。

### 汇总块透传

- 将 Subagent 返回的 `## 汇总输入（供 design.md 合并）` 结构块**原样** append 至 `collected_summaries[]`。
- 禁止 orchestration 改写汇总块内容。

### frontmatter 写入

- 本域落盘后，orchestration 负责 Read artifact 的 YAML frontmatter → 更新以下字段：
  - `stepsCompleted`：追加当前 element_id
  - `last_element`：更新为当前 element_id
  - `last_updated`：当前日期
  - `status`：全部受影响要素完成后改为 "completed"
- 使用 Edit 工具精确匹配，禁止 Write 覆盖全文。
- Subagent 禁止写入 frontmatter。

---

## Phase 3：要素执行调度（TDD 高阶 Step 6）

初始化编排上下文：

```yaml
collected_summaries: []
execution_profile: { ... }  # 与 Phase 1 知识探索收敛结果一致
```

按依赖就绪批次调度 `effective_sequence`：
（effective_sequence 来自 Phase 2 解析的 ORCH 块）

```
pending = effective_sequence
completed_elements = 已存在 artifact_file 的 element_id 集合

WHILE pending 非空:
  1. ready_batch = pending 中 depends_on 对应 artifact 均已存在或已在 completed_elements 的要素
  2. 若 ready_batch 为空：阻断并提示依赖缺口或 dependency cycle，不调用
  3. PARALLEL FOR entry IN ready_batch:
       a. 过滤本要素相关的变化点列表（element_changes）
       b. 执行「Subagent 调用协议」→ 调用前门禁
       c. 执行「Subagent 调用协议」→ Prompt 组装 + Subagent 调用
  4. 等待 ready_batch 全部返回后，按 chapter_no 升序逐项执行：
       a. 执行「Subagent 调用协议」→ 轻量后置校验（含 DELTA 块检查）
       b. 执行「Subagent 调用协议」→ 汇总块透传 + frontmatter 写入
       c. 累积 DIP 到 context.impact_points
       d. 将 element_id 加入 completed_elements，并从 pending 移除
```

---

## Phase 3A：汇总生成 `{DESIGN_DIR}/design.md`

在 Phase 3 **全部受影响要素**均已成功结束后：

1. **必须严格按** `spec/m-design-summary-merge.md` Read `collected_summaries[]`，写入 `{DESIGN_DIR}/design.md`。
2. **增量专属章节**（在标准汇总章节前追加）包含变更说明和影响点索引表。
3. **DIP 全局重编号**：将各要素内临时编号的 DIP 统一重编为全局序号。
4. 若门禁失败，按该 reference 暂停策略处理，**不得**进入 Phase 3B。

---

## Phase 3B：US 与设计交付物索引关联（条件执行）

1. 若 `{DESIGN_DIR}/story.md` **不存在**，跳过本 Phase。
2. 若存在，**加载 `spec/m-us-design-linkback.md`**，按该规范执行本阶段；subagent 的调用方式、输入/输出契约与校验规则均以该规范为准（编排不在此重复声明）。

---

## Phase 4：完成收尾 + C/B/S/Q

1. 调用 `spec/m-design-complete.md` 完成统一收尾；本轮不更新 `DESIGN_ACCUM_FILE`。
2. 输出 SKILL.md 增量模式完成提示模板。

⚠️ 输出操作菜单后立即终止响应，等待用户选择。
