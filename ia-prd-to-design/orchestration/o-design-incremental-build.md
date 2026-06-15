# 设计增量/更新 编排文件
# workflow_id: design-incremental-build
# 对应 workflow-registry 中 id: design-incremental-build
# 嵌入 TDD 高阶方案七步同构逻辑（v2.0.0）

## 前置说明
本编排文件由 workflow-engine 在命中 design-incremental-build 后调用。
在已有设计基线（DESIGN_HISTORICAL）上，通过 PRD 变更结构化路由（ChangeRouter），
基于 34 类原子变化点精确识别受影响设计要素，生成 DIP 影响点与 DELTA 增量标注。
实际要素内容生成完全交由 element-runner 执行，本文件只控制宏观流程。

## ⚠️ 多文件输出约定
本编排执行期间，每个要素对应 config.yaml → design_artifacts 中声明的主交付文件。
所有要素执行结果由 element-runner Phase 6 写入对应的输出文档。

---

## 强制读取

1. 本 Skill 根目录 `config.yaml`（含 `design_artifacts` 文件名映射、`extension_registry` 挂载点）
2. 本 Skill `SKILL.md` 中 **路径约定**（`WORKSPACE_ROOT`、`DESIGN_DIR`、`BASELINE_DESIGN_DIR`、`INCR_PRD_FILE`、`LEGACY_CONTEXT`、`DESIGN_ACCUM_FILE` 等路径变量）
3. `{WORKSPACE_ROOT}/workspace/ongoing.md`
4. `registry/atomic-change-registry.yaml`（34 个原子变化点定义）
5. `registry/change-element-mapping.yaml`（变化点 → 设计要素聚合映射）
6. `registry/dependency-graph.yaml`（`impact_edges` 用于安全网校验）
7. `registry/element-type-registry.yaml`（动态读取 chapter_info）
8. `engine/element-runner.md`（`incremental` 模式与 `context.base_doc_path` 约定）
9. `spec/m-design-knowledge-exploration.md`（现有知识库探索的步骤、产出结构与停止条件）
10. `spec/m-design-summary-merge.md`（全部要素完成后的特性级 `design.md` 汇总）

---

## 业务判定模型

本编排使用以下三维模型确定有效要素序列：

| 维度 | 取值 | 说明 |
|------|------|------|
| `MODE` | `new-incremental` / `update` | 与历史基线的关系 |
| `PROJECT_TYPE` | `TP` / `AP` / `AI` | 系统/能力类型 |
| `CHANGE_SCOPE` | `frontend` / `backend` / `fullstack` | 本次变更覆盖哪些层 |

禁止把 `PROJECT_TYPE` 当作前后端覆盖范围的代理。`CHANGE_SCOPE` 在知识探索收敛前不得假定取值。

**工程结构**：默认兼容单工程与 `backend/` + `frontend/` 双工程目录。`CHANGE_SCOPE` 包含 `backend` 时优先检索后端工程上下文；包含 `frontend` 时优先检索前端工程上下文；`fullstack` 时两侧均须检索。

**执行画像**（知识探索完成后确定）：

```yaml
execution_profile:
  has_frontend: true | false
  has_backend: true | false
  backend_variant: standard | ap
  enable_ai: false
```

---

## Phase 0：解析上下文（TDD 高阶 Step 0 环境准备）

1. 解析路径变量（定义见 SKILL.md 路径约定）：`VERSION`、`FEATURE_SUBDIR`、`DESIGN_DIR`、`PRD_FILE`、`STORY_FILE`、`DESIGN_ACCUM_FILE`。
2. **解析 `DESIGN_HISTORICAL`（即 `BASELINE_DESIGN_DIR`）**：确认基线目录、各要素主交付文件路径（与 `config.yaml` → `design_artifacts` 命名一致）；将基线路径记入编排上下文，供 Phase 3 绑定 `context.base_doc_path`。
3. **解析 `INCR_PRD_FILE`**：默认等同 `PRD_FILE`；若增量 PRD 独立文件，须在 ongoing.md 或用户指定中解析。
4. **解析 `LEGACY_CONTEXT`**：扫描存量系统信息路径列表（DDL / OpenAPI / 代码索引）；缺位时标记降级为对话挖掘。
5. **一致性校验**：确认 `BASELINE_DESIGN_DIR` 可解析出与 `config.yaml` → `design_artifacts` 对齐的一套文件。
6. 读取 `PRD_FILE`（及变更说明，若有）作为对齐输入；将路径记入 `context.input_doc_path`。
7. 若本轮 PRD 相对基线仅有局部变更说明，仍须以完整 `prd.md` 或可追溯的差异入口为准，避免遗漏依赖边。

---

## Phase 1：现有知识库探索（强制先于要素执行）

按 `spec/m-design-knowledge-exploration.md` 执行受限探索：

1. 产出 `{DESIGN_DIR}/shared-context.md`（章节结构与禁码、导航字段见 reference）。
2. **存量系统信息收录**（增量模式必检）：按 reference 中"存量系统信息收录"章节执行，存在则路径记入 shared-context 作为 `evidence_source=legacy_system` 的依据来源，不存在则记录"存量信息缺位"标志。
3. **在探索收敛前不得假定 `CHANGE_SCOPE`**；依据 PRD 明文、`decision_facts` 与双工程检索结论确定 `CHANGE_SCOPE`，并与上述执行画像对齐。
4. 若 reference 规定的状态为需用户澄清（`NEEDS_USER_CLARIFICATION`），先完成澄清与回填，再进入后续 Phase。
5. 将 `shared-context.md` 路径作为下游共有输入保存在编排上下文。

---

## Phase 1.0：PRD 变更识别与原子变化点提取（TDD 高阶 Step 1）

**输入**：增量 PRD 文档（`INCR_PRD_FILE`）或简单需求描述

**输出**：PrdChange 列表 + AtomicChange 列表

> **设计要点**：变更登记与变化点识别合为一步。PRD 含 ImpactPoint 时可直接映射；
> 无 ImpactPoint 时需先拆解需求再主动识别。两条路径产出结构一致，后续 Phase 1.5～3B 无差异。

### 1.0.1 输入分类

| 类型 | 判断标准 | 处理路径 |
|------|---------|---------|
| **type_a** | `INCR_PRD_DOC` 检测为 true（含 DELTA 块 + ImpactPoint 清单） | → 直接提取（1.0.2） |
| **type_b** | 存在 PRD 文档有要素章节但无 ImpactPoint | → 主动识别（1.0.3） |
| **type_c** | 输入为一段话或几条要点，无 PRD 结构 | → 主动识别（1.0.3） |

顺序检测，首次命中即确定。

### 1.0.2 直接提取模式（type_a）

PRD 的 ImpactPoint 已携带"哪个要素变了 + 变了什么"，一步到位产出 PrdChange 和 AtomicChange。

对**每条 ImpactPoint / DELTA 块**：

1. **提取 PrdChange**：从 ImpactPoint 的影响要素声明中提取 prd_element、description、source_story，evidence_source=incr_prd
2. **映射 AtomicChange**：按 prd_element 初筛变化点类别（如 info-architecture → IA 类），用 detection_keywords 在 DELTA 块中匹配，确定具体变化点 ID
3. **证据收集**：引用增量 PRD 原文（ImpactPoint 编号 + DELTA 片段）作为 evidence
4. **置信度**：有 ImpactPoint + DELTA 原文支撑，confidence 默认 `high`
5. **用户确认**：同一 PrdChange 命中多个变化点时列出选项让用户选

**暂停触发**：
- DELTA 块描述模糊，无法确定变更类型
- 同一 PrdChange 命中多个变化点且无法消歧
- 命中置信度为"低"

### 1.0.3 主动识别模式（type_b / type_c）

输入无 ImpactPoint，需主动识别变化点。

**第一步：需求拆解**

将输入拆解为独立的变更意图（Raw Intent, RI），每条 RI 描述一个可辨识的业务变化。
拆解原则：一条 RI 对应一个独立业务变化，粒度对齐"用户可独立验收的最小功能点"。
- type_b：从 PRD 各章节提取变化点
- type_c：从自然语言拆解

**第二步：对每条 RI 识别原子变化点**

1. **关键词初筛**：用 atomic-change-registry 的 detection_keywords 在 RI 描述中做模糊匹配，得到候选集合
2. **语义匹配**：对候选集合按变化点的 description_zh + examples 做语义判断，确认或排除
3. **证据收集**：每个识别出的变化点必须能引用以下之一作为 evidence，并标注 evidence_source：
   - `incr_prd`：增量 PRD 对应章节 + 引用片段（type_b 适用）
   - `baseline_design`：基线设计文件对应章节 + 引用片段
   - `dialog`：用户需求描述原文片段或澄清回答（type_c 适用）
4. **用户确认**：同一 RI 命中多个变化点时列出选项让用户选

**第三步：暂停澄清**

关键词初筛命中"可能涉及"但证据不足的域，汇总为澄清问题，按铁律二统一暂停格式输出。
澄清回答后补充变化点，evidence_source=dialog。

**第四步：构造 PrdChange + AtomicChange**

根据识别结果 + 澄清回答，同时构造两个列表。主动识别模式的约束：
- PrdChange.evidence_source 标记为 `dialog`（type_c）或 `incr_prd`（type_b）
- AtomicChange.confidence 默认上限 `medium`（用户逐条确认后可升 high）
- source_story 通常为空，Phase 3B 遇到时跳过回填或仅输出 DIP 清单

**暂停触发**：
- 同一 RI 命中多个变化点且无法消歧
- 命中置信度为"低"
- RI 描述明显超出 34 个变化点的覆盖范围

### 1.0.4 关键约束（两种模式共用）

| 约束 | 说明 |
|------|------|
| PrdChange 与 AtomicChange 一一对应 | 每条 PC 至少映射一个 AtomicChange；同一 PC 可映射多个 |
| 遵守铁律一 | 推导不出的必须暂停询问；所有结论标注 evidence_source |
| 遵守铁律二 | 置信度"低"或无法消歧时必须暂停澄清 |
| 变化点不得超出 34 个清单 | 超出覆盖范围时暂停说明 |

---

## Phase 1.5：变化点路由四步流程（TDD 高阶 Step 1.1 ~ 4，ChangeRouter）

### Step 1.1：原子变化点识别

1. 读取 `registry/atomic-change-registry.yaml`
2. 对每条 PC，按 `prd_element` 初筛类别，用 `detection_keywords` 精确匹配
3. 每条命中必须引用 evidence（增量 PRD 原文 / 基线设计 / 存量系统 / 用户对话）
4. 构建 AtomicChange 实例：
   - `id`：`{CATEGORY-NN}`（如 IA-01、FS-02）
   - `source_prd_change`：`PC-{xx}`
   - `evidence`：证据原文片段
   - `evidence_source`：`incr_prd` | `baseline_design` | `legacy_system` | `dialog`
   - `confidence`：`high` | `medium` | `low`
   - `open_question`：置信度非 high 时的待确认问题
5. **confidence 为 medium/low 时必须暂停**，向用户展示证据与待确认问题，等待确认后继续
6. 输出 `triggered_changes`（AtomicChange 列表），写入编排上下文

### Step 2：影响汇聚

1. 读取 `registry/change-element-mapping.yaml`
2. 对 `triggered_changes` 中每个变化点 change_id，查找 `affects` 列表
3. 按 impact_level 处理：
   - `certain` → 直接加入候选序列
   - `likely` → 标记为可跳过，默认加入
   - `conditional` → 检查 condition 条件，或交由用户决定
4. 合并去重，输出候选 `effective_sequence`

### Step 3：always_affected 标注

方案 A（外置收口）：增量设计只产出 DIP + 多文件 DELTA；开发 Task 拆分由 `ia-prd-to-tdd` 增量承接。本步跳过。

### Step 4：依赖图安全网校验

1. 遍历 `registry/dependency-graph.yaml` 的 `impact_edges`
2. 对 `effective_sequence` 中每个 source element，取 direct targets
3. 不在序列中的 target 归入安全网候选
4. 若安全网候选非空，输出交互：
   - `[Y]` 全部加入
   - `[S]` 选择性加入
   - `[N]` 跳过
5. 按 `chapter_no` 升序排列最终 `effective_sequence`

**MODE 过滤**（同步执行）：
- `new-incremental` / `update` 从序列移除 `architecture`（除非被 ChangeRouter 以 certain 命中）。

**CHANGE_SCOPE 过滤**（同步执行）：
- 仅 `backend`：移除 `frontend`。
- 仅 `frontend`：是否移除后端链由用户确认（默认保守：不自动剔除后端链）。
- `fullstack`：前后端链路均可进入；`config` / `integration` 仍按需。

---

## Phase 2：执行计划展示与确认（TDD 高阶 Step 5）

输出如下模板，等待用户确认：

```text
✅ 设计增量影响域分析完成

PRD 变更条目：
  PC-01: "{描述}" (← S-FR-xx-xx)
  PC-02: "{描述}" (← S-FR-xx-xx)

触发原子变化点：
  PC-01 → {change_id}({confidence})
  PC-02 → {change_id}({confidence})

受影响设计要素（按章节顺序）：
  {no}. {element_name}（{trigger_type}，触发 {source_changes}）
  ...
不涉及要素：{排除的要素及原因}

[C] 开始执行  [B] 重做 ChangeRouter  [Q] 退出
```

- 用户选 `[C]`：冻结 scope，进入 Phase 3
- 用户选 `[B]`：回到 Phase 1.0 重新执行
- 用户选 `[Q]`：保存当前上下文到 ongoing.md 后退出

---

## Phase 3：要素执行循环（TDD 高阶 Step 6）

对 `effective_sequence` 中每个 `element_id`：

```
FOR EACH element IN effective_sequence:
  1. 从 element-type-registry 动态读取 chapter_info：
     chapter_info = {
       l1_no: element.chapter_no_cn,
       element_name: element.name,
       sub_elements: element.sub_elements,
       backend_only: element.backend_only,
       chapter_label_style: element.chapter_label_style
     }
  2. 过滤本要素相关的变化点列表（element_changes）：
     从 triggered_changes 中筛选与本 element_id 关联的变化点子集
  3. 设置 context.output_doc_path = {DESIGN_DIR}/{config.design_artifacts[element_id]}
  4. 设置 context.base_doc_path = BASELINE_DESIGN_DIR 中该要素已有交付文件路径
     （若基线缺少该文件，须用户确认是否改为 build 或补齐基线，禁止静默空基线）
  5. 调用 element-runner(element_id, execution_mode="incremental", context)
     其中 context.impact_analysis 含：
     - prd_change_register
     - triggered_changes
     - effective_sequence
     - element_changes（本要素子集）
  6. element-runner 输出操作菜单后 FOR 循环挂起，等待用户选择
  7. 该要素会话结束前须按 spec/m-design-summary-merge.md 产出
     `## 汇总输入（供 design.md 合并）` 结构块；编排留存待 Phase 3A 合并
  8. 每个要素执行完毕后累积 DIP 到 context.impact_points
END FOR
```

---

## Phase 3A：汇总生成 `{DESIGN_DIR}/design.md`

在 Phase 3 **全部受影响要素**均已成功结束后：

1. **必须严格按** `spec/m-design-summary-merge.md` 收集本轮各要素会话中的汇总输入，执行门禁自检后写入或刷新 `{DESIGN_DIR}/design.md`。
2. **增量专属章节**（在标准汇总章节前追加）：

```markdown
## 0. 变更说明
- 基线设计目录：{BASELINE_DESIGN_DIR}
- 增量 PRD：{INCR_PRD_FILE}
- 存量系统信息：{LEGACY_CONTEXT 或 "未提供"}
- PRD 变更条目：{PC-01, PC-02, ...}
- 触发变化点：{change_ids}

## A. 影响点索引
| DIP 编号 | 来源 PC | 来源变化点 | 触发类型 | 受影响要素 | action | baseline_ref |
|----------|--------|----------|---------|----------|--------|--------------|
```

3. **DIP 全局重编号**：将各要素内临时编号的 DIP 统一重编为 `DIP-001`、`DIP-002`、... 的全局序号。
4. 将 `prd_change_register`、`triggered_changes`、`impact_points` 等全局寄存字段**仅在此处**写入 design.md。
5. 若门禁失败，按该 reference 暂停策略处理，**不得**进入 Phase 3B。

---

## Phase 3A-1：草案审阅与确认（TDD 高阶 §11.1 同构）

**前置条件**：Phase 3A `design.md` 已成功生成。

**处理**：输出完整草案供用户审阅，格式如下：

---

=== 增量设计影响域分析草案 ===

【一、PRD 变更条目】
PC-01: {描述} / 来源 {source_story} / 状态：已分析
PC-02: {描述} / 来源 {source_story} / 状态：已分析

【二、原子变化点】
PC-01 → {change_id}({confidence}, evidence_source={source})
PC-02 → {change_id}({confidence}, evidence_source={source})

【三、受影响设计要素总表】
| 要素 | 触发类型 | 触发变化点 | 改动摘要 |
|------|---------|----------|---------|

【四、不涉及要素说明】
| 要素 | 不涉及原因 | 验证依据 |
|------|-----------|---------|

【五、影响点清单（DIP）】
DIP-001 [primary, source_change={id}, source_prd_change={pc}]
  element: {element_id}
  baseline_ref: {基线章节}
  baseline_state: {基线现状}
  action: 新增|修改|删除
  target_state: {目标状态}
  target_state_evidence: {四档之一}
  compatibility_note: {兼容说明}
  boundary_constraints:
    - target: {禁止改动对象}
      reason: {原因}
      consequence: {后果}
      evidence: {依据}

DIP-002 [...]

【六、US 设计引用预览】
（Phase 3B 待执行，此处列出 DIP.source_prd_change → PrdChange.source_story 的预估关联）

=== 待确认问题汇总 ===

请确认：
1. 分析结论是否准确？有无遗漏或错误？
2. 影响点的边界约束是否完整？
3. 兼容性说明是否充分？
4. US 设计引用预览是否覆盖全部关联设计章节？

[Y] 确认，继续 Phase 3B  [B] 修正后重新汇总  [Q] 退出

---

- 用户选 `[Y]`：进入 Phase 3B
- 用户选 `[B]`：回到 Phase 3 对指定要素重新执行 element-runner
- 用户选 `[Q]`：保存当前上下文到 ongoing.md 后退出

---

## Phase 3B：US 与设计交付物索引关联（条件执行）

在 Phase 3A `design.md` 已成功生成或用户确认跳过后：

1. 若 `{DESIGN_DIR}/story.md` **不存在**，跳过本 Phase。
2. 若存在，**必须严格按** `spec/m-us-design-linkback.md` 执行：将本轮已更新/产出的多文件设计交付物（以 `config.yaml` → `design_artifacts` 为准，含 `shared-context.md` 及 `design.md`）的可定位索引写回各 US。
3. 执行完成后以该 reference 的完成消息为准（`DONE: story.md design linkback`）。

---

## Phase 4：完成收尾（TDD 高阶 Step 7 可选收口）

1. 更新 `{WORKSPACE_ROOT}/workspace/ongoing.md` 与 `DESIGN_ACCUM_FILE`（跨版本累积视图）。
2. 输出 SKILL.md 中定义的增量模式完成提示模板。
3. 增量设计产物已齐备，建议下游接续 `ia-prd-to-tdd` 增量工作流。
