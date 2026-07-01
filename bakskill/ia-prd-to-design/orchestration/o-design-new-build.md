# 从 PRD 新建完整技术设计 编排文件
# workflow_id: design-new-build
# 对应 workflow-registry 中 id: design-new-build

## 前置说明
本编排文件由 workflow-engine 在命中 design-new-build 后调用。
编排直接通过 `@subagent名称` 调用 Subagent 写设计正文；本文件控制宏观流程、门禁与轻量校验。

## ⚠️ 多文件输出约定
每个要素对应 subagent-registry 中声明的 artifact_file。
Subagent 落盘后，orchestration 负责更新 frontmatter。

---

## 强制读取

1. 本 Skill 根目录 `config.yaml`（含 `design_artifacts` 文件名映射）
2. 本 Skill `SKILL.md` 中 **路径约定**（`WORKSPACE_ROOT`、`DESIGN_DIR` 等路径变量）
3. `workspace/ongoing.md`
4. `registry/subagent-registry.yaml`（唯一派发 SSOT）
5. `spec/m-design-summary-merge.md`（全部要素完成后的特性级 `design.md` 汇总）
6. `spec/m-design-overall.md`（正式要素执行前的整体方向确认）
7. `spec/m-design-complete.md`（统一完成收尾）
8. `spec/m-us-design-linkback.md`（US 与设计交付物索引关联的调用契约，须在回填阶段前加载）

---

## 编排结构

本工作流按以下结构执行：

1. **读取公共依赖**：读取 `config.yaml`、`SKILL.md` 路径约定、`workspace/ongoing.md`、`registry/subagent-registry.yaml` 与汇总 spec。
2. **解析运行上下文**：建立 `WORKSPACE_ROOT`、`VERSION`、`FEATURE_SUBDIR`、`DESIGN_DIR`、`PRD_FILE`、`STORY_FILE`。
3. **确定执行画像与整体方向**：先确定 `CHANGE_SCOPE` / `execution_profile`，再调用 `@ia-overall-designer` 生成并确认 `{DESIGN_DIR}/overall-design.md`。
4. **生成执行序列**：从 `subagent-registry.yaml` 数据驱动生成 `effective_sequence`。
5. **执行要素调度**：按依赖就绪批次执行 `effective_sequence`；同批前置依赖均已输出的多个 `element_id` 可并行派发 Subagent。
6. **汇总与索引回链**：生成 `{DESIGN_DIR}/design.md`，并在 `story.md` 存在时加载 `spec/m-us-design-linkback.md` 执行索引回链。
7. **状态收尾**：更新 `workspace/ongoing.md` 与交付物 frontmatter，输出一次 C/B/S/Q 操作菜单后终止响应。

---

## 业务判定模型

本编排不在 workflow 文件内声明业务维度取值或分支矩阵。运行时判定必须遵从 `config.yaml`：

1. 从 `runtime_dimensions.project_type`、`runtime_dimensions.change_scope` 读取合法取值与序列过滤规则。
2. 从 `runtime_dimensions.project_type.backend_variant` 推导后端实现分支，并通过 `execution_profile.backend_variant` 与 `subagent-registry.yaml` 的 `select_when` 完成 Subagent 选择。
3. 从 `runtime_dimensions.change_scope.sequence_exclusions` 获取前端/后端覆盖范围对候选序列的影响。
4. `execution_profile` 字段集合以 `runtime_dimensions.execution_profile_fields` 为准。

禁止把项目类型当作前后端覆盖范围的代理。覆盖范围在进入可靠运行上下文之前不得假定取值。

**工程结构**：默认兼容单工程与双工程目录；具体检索侧由配置解析后的 `CHANGE_SCOPE` 与 `execution_profile` 驱动。

---

## Phase 0：解析上下文

1. 解析路径变量（定义见 SKILL.md 路径约定）：`VERSION`、`FEATURE_SUBDIR`、`DESIGN_DIR`、`PRD_FILE`、`STORY_FILE`。
2. 读取 `PRD_FILE` 校验可作为设计输入；将路径记入 `context.input_doc_path`（主输入为 PRD）。
3. 基于 PRD 的交付分层、功能/UI/API 表述与工程目录事实，确定 `CHANGE_SCOPE`：`frontend` / `backend` / `fullstack`。低置信时必须先询问用户确认。

当以下任一维度低置信时，必须先询问用户，不能直接进入 `overall-design`：

- `PROJECT_TYPE`
- 核心业务边界
- 前后端覆盖范围
- 关键集成
- 核心数据实体
4. 按 `config.yaml` 的 `runtime_dimensions.execution_profile_fields` 派生 `execution_profile`：
   - `has_frontend: CHANGE_SCOPE in [frontend, fullstack]`
   - `has_backend: CHANGE_SCOPE in [backend, fullstack]`
   - `backend_variant: PROJECT_TYPE == AP ? ap : standard`
   - `enable_ai: PROJECT_TYPE == AI and has_backend == true`
5. 若 `workflow.resume_mode == true`：
   - 从进行中交付物 frontmatter 还原 `effective_sequence` 与 `stepsCompleted`
   - 自未完成要素继续

---

## Phase 0A：整体方案概要与方向确认

在生成 `effective_sequence` 和调用任何 design 域 Subagent 前，必须先完成整体方向确认。

执行方式：按 `spec/m-design-overall.md` 的 **通用触发门禁**、**Prompt 组装：build 模式** 与 **确认门禁** 调用 `@ia-overall-designer`。

通过条件：`{DESIGN_DIR}/overall-design.md` 已生成，且用户已明确确认其可作为后续设计要素的方向基线。

---

## Phase 1A：执行计划展示与确认

在 `effective_sequence` 生成完成后，必须先展示执行计划并等待用户确认，才能进入 Phase 2。

```text
✅ 新建设计执行计划已生成

执行画像：
  MODE: build
  PROJECT_TYPE: {PROJECT_TYPE}
  CHANGE_SCOPE: {CHANGE_SCOPE}
  execution_profile: {execution_profile}

计划执行要素：
  {chapter_no}. {element_id} -> {artifact_file}

跳过要素：
  {element_id}: {跳过原因}

可选要素：
  {element_id}: {纳入 / 跳过 / 待确认}

依赖与强制读取：
  {element_id}: depends_on={...}, force_read={...}, optional_read={...}

[C] 开始执行  [B] 调整计划  [Q] 退出
```

- 用户选 `[C]`：冻结序列，进入 Phase 2
- 用户选 `[B]`：回到 Phase 1 调整
- 用户选 `[Q]`：退出

---

## Phase 2：要素执行循环（原编号上移）

## Phase 1：生成 effective_sequence

0. 前置要求：`{DESIGN_DIR}/overall-design.md` 已获得用户明确确认。
1. 从 `registry/subagent-registry.yaml` 读取全量 design 域条目（`dispatch_via` 不含 `orchestration-direct`，因此不包含 `ia-overall-designer`）。
2. 读取 `config.yaml` 的 `runtime_dimensions`，校验 `PROJECT_TYPE`、`CHANGE_SCOPE` 均为配置允许值。
3. 过滤 `dispatch_profile.project_types` 含 `PROJECT_TYPE` 的条目。
4. **MODE/Workflow 过滤**：按 `subagent-registry.yaml` 的 `dispatch_profile.workflows` 与 `dispatch_profile.execution_modes` 过滤；`EXECUTION_MODE=build` 不在声明中的要素排除。
5. **CHANGE_SCOPE 过滤**：按 `runtime_dimensions.change_scope.sequence_exclusions.{CHANGE_SCOPE}` 执行排除或用户确认策略。
6. **可选要素**：`optional: true` 的按用户选择纳入。
7. `effective_sequence` 每项包含：`element_id` / `name` / `artifact_file` / `chapter_no` / `depends_on` / `force_read` / `element_ids[]`。

---

## Subagent 调用协议

本编排对每个 design 域 Subagent 直接执行以下协议。

### 调用前门禁

1. 从 `subagent-registry.yaml` 筛选 `element_id == 当前 element_id` 的条目。
2. 若有 `select_when`，与 `execution_profile` 逐项匹配；零命中或多命中时暂停确认。
3. 检查 `depends_on` 中每个 `element_id` 对应的 artifact 文件已存在。
4. 检查 `force_read[]` 中所有路径对应的文件存在；不存在则阻断。
5. 检查 `force_read_by_mode`：仅当前 `EXECUTION_MODE` 命中时强制；不命中时跳过。
6. 检查 `optional_read[]`：存在则注入 Prompt，不存在不阻断。
7. 按 `element_ids[]` 从 `element-registry.yaml` 解析 `prd_sources` 并透传 Prompt；只做元数据展开，不解释、不裁剪 PRD 章节规则。

### Prompt 组装（build 模式）

```text
WORKFLOW_ID: design-new-build
EXECUTION_MODE: build
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
OVERALL_DESIGN_FILE: {DESIGN_DIR}/overall-design.md（若存在）
force_read[]: {subagent-registry.force_read[]}（路径变量已展开）
chapter_info:
  chapter_no: {subagent-registry.chapter_no}
  element_name: {element_name}

约束（强制）：
- 严格按 Subagent 自身 Step 0–5 执行
- 禁止跳过 Step 0；禁止写入 frontmatter
- Step 4 必须逐项输出自检报告（含 ❌ 标记）
- 必须返回 executed_sub_elements[] + ## 质量自检报告 + ## 汇总输入（供 design.md 合并）
- 禁止在返回载荷中粘贴 artifact 全文
```

新建设计模式不注入 `impact_analysis`，不设置 `modify_focus`。

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
5. 不通过 → [B] 重新调用 subagent（可附带问题清单）/ [Q] 退出。
6. 通过 → 汇总块追加至 `collected_summaries[]`。

### 汇总块透传

- 将 Subagent 返回的 `## 汇总输入（供 design.md 合并）` 结构块**原样** append 至 `collected_summaries[]`。
- 禁止 orchestration 改写汇总块内容。

### frontmatter 写入

- 本域落盘后，orchestration 负责 Read artifact 的 YAML frontmatter → 更新以下字段：
  - `stepsCompleted`：追加当前 element_id
  - `last_element`：更新为当前 element_id
  - `last_updated`：当前日期
  - `status`：全量完成后改为 "completed"
- 使用 Edit 工具精确匹配，禁止 Write 覆盖全文。
- Subagent 禁止写入 frontmatter。

---

## Phase 2：要素执行调度（原编号上移）

初始化编排上下文：

```yaml
collected_summaries: []
collected_artifacts: {}
execution_profile:
  has_frontend: true | false
  has_backend: true | false
  backend_variant: {按 config.yaml → runtime_dimensions.project_type.backend_variant 推导}
  enable_ai: {按 config.yaml 与上下文推导}
```

按依赖就绪批次调度 `effective_sequence`：

```
pending = effective_sequence
completed_elements = 已存在 artifact_file 的 element_id 集合

WHILE pending 非空:
  1. ready_batch = pending 中 depends_on 对应 artifact 均已存在或已在 completed_elements 的要素
  2. 若 ready_batch 为空：阻断并提示依赖缺口或 dependency cycle，不调用
  3. PARALLEL FOR entry IN ready_batch:
       a. 执行「Subagent 调用协议」→ 调用前门禁
       b. 执行「Subagent 调用协议」→ Prompt 组装 + Subagent 调用
  4. 等待 ready_batch 全部返回后，按 chapter_no 升序逐项执行：
       a. 执行「Subagent 调用协议」→ 轻量后置校验
       b. 执行「Subagent 调用协议」→ 汇总块透传 + frontmatter 写入
       c. 记录 artifact_file → collected_artifacts[]
       d. 将 element_id 加入 completed_elements，并从 pending 移除
```

---

## Phase 2A：汇总生成 `{DESIGN_DIR}/design.md`

在 Phase 2 **全部要素**均已成功结束后：

1. **必须严格按** `spec/m-design-summary-merge.md` Read `collected_summaries[]`，执行门禁自检后写入 `{DESIGN_DIR}/design.md`（摘要 + 引用，不冗长复述交付正文）。
2. 若门禁失败（结构块缺失、references 无法定位或与交付文件矛盾），按该 spec 的暂停策略处理，**不得**进入 Phase 2B。

---

## Phase 2B：US 与设计交付物索引关联（条件执行）

在 Phase 2A `design.md` 已成功生成或用户确认跳过后：

1. 若 `{DESIGN_DIR}/story.md` **不存在**，跳过本 Phase。
2. 若存在，**加载 `spec/m-us-design-linkback.md`**，按该规范执行本阶段；subagent 的调用方式、输入/输出契约与校验规则均以该规范为准（编排不在此重复声明）。
3. 执行完成后以该规范的完成消息为准（`DONE: story.md updated`，兼容历史文案）。

---

## Phase 3：完成收尾 + C/B/S/Q

1. 调用 `spec/m-design-complete.md` 执行统一收尾。
2. 输出 SKILL.md 完成提示模板。

⚠️ 输出操作菜单后立即终止响应，等待用户选择。
