## 增量 PRD 设计 Skill 方案 v2.0

> 适用：`ia-fe-to-prd` Skill 的 `incremental` 模式（`tp-incremental-build` workflow）
> 遵循：设计文档 Skill 构建规范 v1.2.0 / 引擎 v2.1.0
> 与 FE 增量方案（`docs/FE 增量高阶方案V1.0.md`）在架构上同构、术语对齐
> 取代：`docs/增量PRD分析Skill.md`（v1.0）

---

## 一、定位与边界

### 1.1 做什么

基于已完成的**基线 PRD 文档** + **新版本 FE 文档** + 用户对增量诉求的业务描述，通过变化点路由识别影响域，对每个受影响 PRD 要素生成增量内容（DELTA 标注），最终产出影响点清单与增量 PRD 草案，供人工确认后落盘。

### 1.2 不做什么

- **不读旧版 FE**：FE 与 PRD 已切干净，PRD 增量只读基线 PRD（作为增量基线）和新版 FE（作为业务事实来源）
- **不重新做需求类型判定**：基线 PRD frontmatter 中已记录 `requirement_type`，直接沿用
- **不绕过 ChangeRouter 直接基于关键词路由**：所有增量必须经过"变化点路由层"四步流程
- **不做实施级 Story 拆分细节**：Story 设计由 `story-design` 要素单独承担，本方案只输出 Story 概述/编号/AC 摘要

### 1.3 与 FE 增量方案的对比

| 共享                            | PRD 独有                                                | FE 独有                                                    |
| ----------------------------- | ----------------------------------------------------- | -------------------------------------------------------- |
| 5 步执行流程                       | 工程语言变化点（26 个）映射到 11 个 PRD 要素                          | 业务语言变化点（18 个）映射到 4 个 FE 要素                               |
| 两条铁律（有理有据 / 随时暂停）             | 有 `base_doc_path`（基线 PRD）和 `input_doc_path`（新版 FE）双输入 | 输入是用户对话的一句话需求                                            |
| ImpactPoint 数据结构              | 编号体系完整传递（FR-xx-xx-xxx、E-xxx、PAGE-xxx、AC-x）            | 不涉及 FR/E/PAGE 编号                                         |
| DELTA 格式（v1.2.0 修订：`change=`） | story-design 永远受影响                                    | original-requirement / requirement-type / glossary 永远受影响 |
| ChangeRouter 四步流程             |                                                       |                                                          |

---

## 二、整体流程

```
【输入】
  基线 PRD 文档（status=completed）
  新版本 FE 文档（status=completed，与基线 PRD 共享 project_name）
  用户对增量诉求的业务描述（对话）

      ↓

【ChangeRouter 四步流程】（orchestration Phase 1.5）
  Step 1：原子变化点识别（关键词初筛 → LLM 语义匹配 → 用户确认）
  Step 2：要素影响汇聚（certain / likely / conditional）
  Step 3：always_affected_in 要素强制补全（story-design）
  Step 4：dependency-graph 安全网校验

      ↓ effective_sequence + 初始 ImpactPoint 列表

【要素循环执行】（orchestration Phase 2，execution_mode=incremental）
  对 effective_sequence 中每个 PRD 要素：
    1. element-runner Phase 2 读基线 PRD 对应章节
    2. element-runner Phase 4 读 context.impact_analysis 中本要素相关变化点
    3. 沿 spec body 的「### incremental 模式」步骤生成 DELTA 标注内容
    4. 累积 ImpactPoint 列表（kind=modify 与 kind=forbid 共存）

      ↓

【影响点汇总 + 草案输出】（orchestration Phase 3）
  影响点清单（按 kind 分组展示：modify / forbid）
  增量 PRD 文档草案（含 DELTA 标注）

      ↓

【人工确认】（orchestration Phase 4）

      ↓

【最终增量 PRD 文档】
```

---

## 三、两条铁律（与 PRD 分析 v1.0、FE 增量方案共享）

### 铁律一：有理有据，不猜测

每条结论必须来自以下三种证据之一，其余一律视为猜测：

1. **新版本 FE 文档原文引用**：明确指出 FE 章节、表格行、Mermaid 节点
2. **基线 PRD 原文引用**：明确指出 PRD 章节、字段编号（FR-xx、E-xxx、PAGE-xxx）
3. **用户当次澄清回答**：在输出中标注"根据用户澄清：[关键信息]"

证据不足时，**唯一合法的处理是暂停询问**。

### 铁律二：随时暂停，主动澄清

下列情况必须使用统一格式暂停：

| 触发情形 | 暂停时机 |
|---|---|
| 用户描述命中多个变化点，无法区分 | Step 1 |
| 单一变化点置信度为"低" | Step 1 |
| `conditional` 影响项的 condition 无法判断 | Step 2 |
| 受影响要素在基线 PRD 中无对应章节 | Step 4 / Step 5 |
| ImpactPoint 的 target_state 无法从证据中推出 | Step 5 |
| forbid 类影响点依赖外部系统知识，PRD 无记录 | Step 5 |
| 基线 PRD 与新版 FE 存在事实矛盾 | 任意步骤 |

**暂停格式**：

```
⏸ 分析暂停 — 需要澄清以下问题，才能继续 [Step X / 要素名 / 变化点编号]：

Q1：[具体问题]
背景：[为什么需要这个信息，不澄清会导致什么无法判断]

Q2：[具体问题]
背景：[同上]

请回答以上问题后，我将继续分析。
```

要求：同一次暂停的问题集中一次性提出；每个问题必须配"背景"；问题必须具体，禁止使用"请补充更多信息"这类泛化问句；收到回答后从暂停的步骤继续，并在输出中标注"根据用户澄清：[关键信息]"。

---

## 四、原子变化点完整清单（26 个）

> 与 `skills/ia-fe-to-prd/registry/atomic-change-registry.yaml` 完全一致。本节仅作可读视图，**不在本方案中重复维护**——任何新增/修改请直接改 YAML 注册表。

### 4.1 UI 类——用户界面变更（5 个）

| id | name | description_zh | detection_keywords |
|---|---|---|---|
| UI-01 | 新增按钮/操作入口 | 在某页面增加按钮或操作入口 | 增加按钮、新增按钮、加一个按钮、添加操作、新增入口 |
| UI-02 | 新增页面 | 增加一个全新的页面 | 新增页面、加一个页面、新页面 |
| UI-03 | 页面字段增减 | 在某页面增加或减少字段 | 增加字段、新增字段、去掉字段、字段调整 |
| UI-04 | 页面布局/样式调整 | 调整布局、样式、交互 | 布局调整、样式调整、改版、界面优化 |
| UI-05 | 页面流转关系变更 | 调整页面跳转关系 | 页面跳转、流转调整、跳转关系 |

### 4.2 DA 类——数据变更（5 个）

| id | name | description_zh | detection_keywords |
|---|---|---|---|
| DA-01 | 新增实体 | 增加新业务对象 | 新增实体、增加实体、新增对象 |
| DA-02 | 实体字段新增 | 已有实体增加属性字段 | 增加字段、实体加、属性增加 |
| DA-03 | 实体字段修改/删除 | 修改字段类型/改名/删除 | 字段改、改字段类型、删除字段 |
| DA-04 | 实体关系变更 | 调整实体间关联关系 | 关系调整、关联变化、多对多 |
| DA-05 | 实体状态流转变更 | 调整状态机 | 状态流转、新增状态、状态机 |

### 4.3 LG 类——业务逻辑变更（4 个）

| id | name | description_zh | detection_keywords |
|---|---|---|---|
| LG-01 | 业务规则新增 | 增加新业务规则 | 新增规则、增加规则、新规则 |
| LG-02 | 业务规则修改 | 调整规则阈值/条件 | 改规则、规则调整、阈值调整 |
| LG-03 | 计算逻辑变更 | 调整计算公式 | 计算逻辑、公式调整、算法变化 |
| LG-04 | 权限规则变更 | 调整角色对功能的访问权限 | 权限调整、角色权限、访问权限 |

### 4.4 PR 类——流程变更（5 个）

| id | name | description_zh | detection_keywords |
|---|---|---|---|
| PR-01 | 新增流程节点 | 流程中增加新环节 | 新增环节、增加节点、增加步骤 |
| PR-02 | 流程节点删除/合并 | 去掉或合并环节 | 去掉环节、合并步骤、简化流程 |
| PR-03 | 流程顺序调整 | 调整节点执行顺序 | 顺序调整、流程顺序 |
| PR-04 | 异常分支新增 | 增加异常处理分支 | 异常处理、驳回、撤回、超时 |
| PR-05 | 角色变更/职责调整 | 调整执行节点的角色 | 换角色、改角色、职责调整 |

### 4.5 IN 类——集成变更（4 个）

| id | name | description_zh | detection_keywords |
|---|---|---|---|
| IN-01 | 新增外部系统集成 | 与新外部系统对接 | 新增集成、对接、新增接口 |
| IN-02 | 集成方式调整 | API↔MQS 等方式调整 | 集成方式、改为接口、改为消息队列 |
| IN-03 | 接口字段/参数变更 | 接口入参出参调整 | 接口字段、参数调整 |
| IN-04 | 集成异常处理变更 | 降级、重试策略 | 重试、降级、失败处理 |

### 4.6 NF 类——非功能变更（3 个）

| id | name | description_zh | detection_keywords |
|---|---|---|---|
| NF-01 | 性能要求变更 | 响应时间、并发、吞吐 | 性能、响应时间、并发 |
| NF-02 | 安全/合规要求变更 | 加密、脱敏、合规 | 安全、加密、脱敏、合规、GDPR |
| NF-03 | 可用性/可靠性要求变更 | SLA / RTO / RPO | 可用性、SLA、RTO、RPO |

---

## 五、原子变化点 → PRD 要素影响映射

> 与 `skills/ia-fe-to-prd/registry/change-element-mapping.yaml` 完全一致。表格仅作 review 视图。

`impact_level` 三档：
- **certain**：一定影响，自动加入 effective_sequence
- **likely**：通常影响，默认加入但可由用户跳过
- **conditional**：条件影响，附带 condition 字段，按条件判断或交由用户决定

| 变化点 | 受影响要素（impact_level / 简要原因） |
|---|---|
| **UI-01** | ui-prototype（certain）/ feature-spec（certain，新按钮对应新子特性）/ permission-design（likely）/ scenario-solution（likely） |
| **UI-02** | ui-prototype（certain）/ app-architecture（certain）/ feature-spec（certain）/ permission-design（certain）/ scenario-solution（likely） |
| **UI-03** | ui-prototype（certain）/ info-architecture（certain，字段增减对应实体属性）/ feature-spec（likely） |
| **UI-04** | ui-prototype（certain） |
| **UI-05** | ui-prototype（certain）/ scenario-solution（likely） |
| **DA-01** | info-architecture（certain）/ feature-spec（certain，新实体需 CRUD 子特性）/ scenario-solution（likely） |
| **DA-02** | info-architecture（certain）/ ui-prototype（likely）/ feature-spec（likely） |
| **DA-03** | info-architecture（certain）/ ui-prototype（likely）/ feature-spec（likely）/ integration-design（conditional：若该字段曾用于外部接口参数映射） |
| **DA-04** | info-architecture（certain）/ feature-spec（likely）/ permission-design（conditional：若涉及数据权限范围） |
| **DA-05** | info-architecture（certain）/ feature-spec（certain）/ ui-prototype（likely） |
| **LG-01** | feature-spec（certain，新规则写入子特性业务规则列表）/ scenario-solution（likely） |
| **LG-02** | feature-spec（certain）/ config-design（conditional：若调整阈值是可配置项） |
| **LG-03** | feature-spec（certain）/ info-architecture（conditional：若新计算逻辑需要新字段） |
| **LG-04** | permission-design（certain）/ feature-spec（likely）/ scenario-solution（likely） |
| **PR-01** | feature-spec（certain）/ scenario-solution（certain）/ permission-design（likely）/ ui-prototype（likely） |
| **PR-02** | feature-spec（certain）/ scenario-solution（certain）/ ui-prototype（likely） |
| **PR-03** | scenario-solution（certain）/ feature-spec（likely） |
| **PR-04** | feature-spec（certain，异常分支增加新 AC）/ scenario-solution（certain） |
| **PR-05** | permission-design（certain）/ feature-spec（likely）/ scenario-solution（likely） |
| **IN-01** | integration-design（certain）/ app-architecture（certain）/ feature-spec（likely）/ scenario-solution（likely） |
| **IN-02** | integration-design（certain） |
| **IN-03** | integration-design（certain） |
| **IN-04** | integration-design（certain）/ nfr（likely） |
| **NF-01** | nfr（certain）/ app-architecture（conditional：若性能变化导致架构方案调整，如增加缓存层） |
| **NF-02** | nfr（certain）/ info-architecture（likely，脱敏规则可能新增字段标注）/ permission-design（likely） |
| **NF-03** | nfr（certain）/ integration-design（conditional：若 SLA 变更影响外部依赖处理策略） |

---

## 六、always_affected 要素

`element-type-registry.yaml` 中通过 `always_affected_in` 字段声明：

```yaml
- id: "story-design"
  always_affected_in: ["modify", "incremental"]
  reason: "每次增量都需追加/调整 Story，story 是 PRD 通往实施的唯一收口"
```

**只有 `story-design` 一个**。其它要素（含 product-positioning）不强制纳入，仅在 ChangeRouter 命中时执行。

> 与 FE 不同：FE 有 `original-requirement / requirement-type / glossary` 三个 always-affected，因为 FE 起始于业务侧的原始描述；PRD 起始于已成型的 FE 与基线 PRD，不需要重新提取需求来源或重判类型。

---

## 七、依赖图（cascade 安全网）

> 直接复用 `skills/ia-fe-to-prd/registry/dependency-graph.yaml` 中已定义的 `impact_edges`，作为 ChangeRouter Step 4 的安全网。

依赖图主要边（节选关键传导关系，完整版以 YAML 为准）：

```yaml
- source: app-architecture
  targets:
    - { element: info-architecture,    impact_type: direct,   reason: 特性边界变化影响实体归属 }
    - { element: feature-spec,         impact_type: direct,   reason: 子特性编号体系来源于应用架构 }
    - { element: permission-design,    impact_type: direct,   reason: 权限矩阵基于子特性清单 }
    - { element: integration-design,   impact_type: direct,   reason: 系统依赖表是集成设计的输入 }

- source: info-architecture
  targets:
    - { element: feature-spec,         impact_type: direct,   reason: 实体操作说明依赖实体定义 }
    - { element: scenario-solution,    impact_type: direct,   reason: 场景表中的操作实体来自信息架构 }

- source: feature-spec
  targets:
    - { element: permission-design,    impact_type: direct,   reason: 权限矩阵需要与子特性同步 }
    - { element: scenario-solution,    impact_type: direct,   reason: 场景串联依赖子特性清单 }
    - { element: story-design,         impact_type: direct,   reason: Story 直接从功能特性与 AC 拆分 }
```

**Step 4 用法**：对 ChangeRouter Step 1~3 产生的 effective_sequence 做闭包扩展，将每个已纳入要素的 direct 下游元素列出，输出"依赖图发现的额外影响要素"，由用户确认是否加入。

---

## 八、五步执行流程详解

> 与 PRD 分析 v1.0 的"5 Step"语义同构，与 FE 增量方案同构。Step 1~4 集中在 orchestration Phase 1.5，Step 5 是 orchestration Phase 2 的要素循环。

### Step 1：识别原子变化点

**输入**：用户对增量的业务描述（一句话或一段）+ 新版 FE 文档（用作证据来源）

**处理**：
1. **关键词初筛**：用 `atomic-change-registry.yaml` 中各变化点的 `detection_keywords` 在用户描述中做模糊匹配，得到候选集合
2. **LLM 语义匹配**：基于 `description_zh` 与 `examples` 做语义判断，从候选中精选
3. **证据收集**：每个变化点必须能引用以下之一作为 evidence：
   - 用户描述原文片段
   - 新版 FE 文档对应章节（章节名 + 引用片段）
4. **用户确认**：若同一描述命中多个变化点，列出选项让用户选

**暂停触发**：

- 同一句描述命中多个变化点且无法消歧
- 命中置信度为"低"
- 描述超出 26 个变化点的覆盖范围

**输出**：AtomicChange 列表，每项含 `id` / `evidence` / `confidence`。

---

### Step 2：要素影响汇聚

**输入**：Step 1 的 AtomicChange 列表

**处理**：对每个变化点，查 `change-element-mapping.yaml` 的 `affects` 列表，按 `impact_level` 分别处理：
- `certain` → 直接加入 `effective_sequence`
- `likely` → 加入但标记可跳过，最终在 Step 4 由用户决定
- `conditional` → 根据 condition 判断；条件不能从证据中确认时暂停询问

**输出**：候选 `effective_sequence`（element_id 去重列表，保留每项的 source_changes 来源跟踪）。

---

### Step 3：always_affected 强制补全

**处理**：扫描 `element-type-registry.yaml`，将 `always_affected_in` 字段包含 `incremental` 的 element_id 强制加入 `effective_sequence`。

PRD 当前命中的：`story-design`。

---

### Step 4：dependency-graph 安全网校验

**处理**：遍历 `dependency-graph.yaml` 的 `impact_edges`，对 `effective_sequence` 中已有的每个 element：

1. 取出该 element 作为 source 时的所有 direct targets
2. 凡 target 不在 effective_sequence 中的，归入"安全网额外发现"清单
3. 向用户输出："以下要素通过依赖图被检测出可能受影响：[...]，是否加入？"
4. 用户确认后形成最终 effective_sequence

**注意**：indirect 边不强制加入，只作为提示。

**输出**：最终 `effective_sequence`（按 `element-type-registry.chapter_no` 排序）。

---

### Step 5：要素循环执行 + DELTA 生成 + ImpactPoint 累积

**输入**：最终 `effective_sequence` + base_prd_path + new_fe_path

**处理**：按 effective_sequence 顺序，对每个 element 调 `element-runner`，传入：

```yaml
element_id: <当前要素>
execution_mode: incremental
context:
  workflow_id: tp-incremental-build
  requirement_type: <从基线 PRD frontmatter 读>
  input_doc_path: <新版 FE 路径>
  output_doc_path: <增量 PRD 输出路径>
  base_doc_path:  <基线 PRD 路径>
  impact_analysis:
    triggered_changes: [...]
    effective_sequence: [...]
    cascade_warnings: [...]
    impact_points: []   # 累积式，每个要素执行后追加
  chapter_info: <从 element-type-registry 读>
```

每个 element 的 spec 在 `### incremental 模式` 子章节定义自己的执行步骤，统一遵循以下接口契约：

1. **读基线 PRD 对应章节**：通过 base_doc_path 定位到 chapter_info.l1_no 的章节
2. **筛选本要素相关变化点**：从 `context.impact_analysis.triggered_changes` 中筛出 `affects` 里包含当前 element_id 的变化点
3. **针对每个变化点对话挖掘细节**：沿用 build 模式的提问内核，但聚焦变更
4. **生成 DELTA 标注内容**：用 v1.2.0 修订的 DELTA 格式：
   ```html
   <!-- DELTA: change=UI-01, chapter=ui-prototype, op=add, level=certain -->
   ...增量内容（保留 Markdown 格式）...
   <!-- /DELTA -->
   ```
5. **累积 ImpactPoint**：每个 DELTA 对应一个 `kind=modify` 的 ImpactPoint；同时识别相邻的 `kind=forbid` 项

**ImpactPoint 数据结构**（与 v1.2.0 规范 3.7.3 节一致）：

```yaml
- id: "IP-001"
  source_change: "UI-01"
  trigger_type: "primary"     # primary | cascade
  cascade_rule: ""            # trigger_type=cascade 时填依赖图边的 reason
  element: "ui-prototype"
  kind: "modify"              # modify | forbid
  baseline_ref: "PRD §3.1 采购单列表页操作列"
  baseline_state: "操作列含：查看、编辑、删除"

  # kind=modify 时使用
  action: "修改"               # 新增 | 修改 | 删除 | 复用 | 不涉及
  target_state: "操作列新增'指定供应商'按钮，位于'编辑'之后"
  in_scope: ["§3.1 操作列定义"]
  out_of_scope: ["列表页其他列、查询条件区域"]

  # kind=forbid 时使用（与 modify 字段二选一，不混用）
  reason: ""
  consequence: ""
  adjacent_to: []
```

**Phase 6 写入**：element-runner 按规范在 PRD 输出文档中追加 DELTA 块，并将 ImpactPoint 写入 frontmatter 的 `impact_points` 列表。

---

## 九、人工确认环节

orchestration Phase 3 完成后输出草案，等待用户确认：

```
=== 增量 PRD 影响域分析草案 ===

【一、原子变化点】
（AtomicChange 列表，含 evidence、confidence）

【二、受影响 PRD 要素总表】
要素名 | 触发类型（primary/cascade）| impact_level | 改动摘要

【三、不涉及要素说明】
要素名 | 不涉及原因 | 验证依据（基线 PRD 章节 / 新版 FE 章节）

【四、影响点明细 — modify 类（IP-xxx）】
（kind=modify 的 ImpactPoint 列表，含 baseline_state / target_state / in_scope / out_of_scope）

【五、影响点明细 — forbid 类（IP-xxx-forbid）】
（kind=forbid 的 ImpactPoint 列表，含 reason / consequence / adjacent_to）

【六、Story 增量】
（story-design 输出的 Story 编号、名称、AC 摘要）

=== 待确认问题汇总 ===
（分析过程中未暂停询问但仍存在的低置信度判断）

请确认：
1. 分析结论是否准确？有无遗漏或错误？
2. forbid 类影响点是否完整？有无需要补充的约束？
3. Story 拆分粒度是否合适？

确认后我将生成最终增量 PRD 文档。
```

---

## 十、最终交付物

用户确认后，orchestration Phase 4 写入最终增量 PRD 文档：

**目录与命名**：与基线 PRD 同目录、按 v1.2.0 规则生成新文件名（含日期戳）。

**文档结构**：

```markdown
---
（frontmatter：含 base_prd / new_fe / triggered_changes / impact_points / stepsCompleted ...）
---

## 0. 变更说明
- 基线 PRD：<path>
- 新版 FE：<path>
- 触发变化点：<UI-01, DA-02, ...>
- 本次变更范围摘要：<一段话>

## 1. 原子变化点清单
（AtomicChange 列表）

## 2. 受影响要素总表
（element 表）

## 3. 不涉及要素说明
（明确排除的要素及原因）

## 4. 各要素增量改动详情
（按 effective_sequence 顺序，每个 element 一段，含 DELTA 块）

### <章节编号> <element_name>
- 触发类型：primary / cascade
- 触发变化点：UI-01 / ...
- 基线章节：PRD §X.Y
- 影响点引用：IP-001 / IP-002

<!-- DELTA: change=UI-01, chapter=ui-prototype, op=add, level=certain -->
具体增量内容
<!-- /DELTA -->

## 5. 影响点清单（按 kind 分组）
### 5.1 modify 类
（IP-xxx）
### 5.2 forbid 类
（IP-xxx-forbid）

## 6. Story 增量
（story-design 输出）
```

---

## 十一、PRD 要素与适用的 incremental 处理摘要

> 给后续 spec 编写者快速参照。每个要素在 incremental 模式下的核心动作。

| 要素 | incremental 模式核心动作 |
|---|---|
| product-positioning | 通常不触发；若触发（NF-01 等）则更新指标/范围条目，DELTA 包裹 |
| app-architecture | 新增/废弃子特性节点；调整系统边界表；架构图增量重绘并 DELTA 包裹 |
| ui-prototype | 新增/调整页面、按钮、字段、Pageflow；DELTA 块包页面 / Pageflow 子段 |
| info-architecture | 新增/调整实体、字段、关系、状态；DELTA 包实体详情段落与 ER 图段 |
| feature-spec | 为受影响子特性新增/扩展 UIUX/实体/集成/规则/AC 5 项规格；FR 编号沿用应用架构 |
| permission-design | 在权限矩阵中按 FR-行 × 角色-列 增减权限单元 |
| integration-design | 新增/调整集成点条目，更新接口规格与异常策略 |
| config-design | 新增可配置项行；区分用户/IT 配置 |
| scenario-solution | 新增异常场景或修改既有场景步骤；场景集成图增量节点 |
| nfr | 直接改对应子表条目（性能/安全/隐私/易用性/可维护性） |
| story-design | always_affected_in；为本次增量产生的 FR 与 AC 全部生成 Story（同时更新独立 Story 文件） |

---

*本方案版本 v2.0，遵循设计文档 Skill 构建规范 v1.2.0。后续如新增原子变化点或调整影响映射，**只改 YAML 注册表**，不改本方案。本方案改动需同时同步 FE 增量方案，保持术语一致。*
