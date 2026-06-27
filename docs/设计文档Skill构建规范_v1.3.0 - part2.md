
### Layer 4 — 场景编排层

> **核心约束**：orchestration 只负责宏观流程控制（初始化、要素循环顺序、完成收尾），不得直接操作文档内容，不得包含要素执行细节，所有要素执行必须通过 element-runner。
>
> **v1.2.0 新增**：modify/incremental 模式的 orchestration 可以读取 Layer 3.5 的场景路由数据进行二级路由。

---

#### 3.4.1 orchestration/o-{workflow-id}.md

**用途**：特定场景的工作流宏观编排。

**命名规则**：文件名中的 `{workflow-id}` 必须与 `workflow-registry.yaml` 中对应 workflow 的 `id` 字段完全一致。

**依赖**：
- `engine/element-runner.md`（要素执行的唯一调用入口）
- `registry/workflow-registry.yaml`（获取 element_sequence）
- `registry/element-type-registry.yaml`（动态读取 chapter_info）
- 输出文档（创建/读取 frontmatter）
- （v1.2.0 新增）`registry/atomic-change-registry.yaml` 和 `change-element-mapping.yaml`（modify/incremental 模式）
- （v1.2.0 新增）`registry/dependency-graph.yaml`（modify/incremental 模式作为安全网）

**内容结构（强制约束）**：

```markdown
# {场景名称} 编排文件
# workflow_id: {workflow-id}
# 对应 workflow-registry 中 id: {workflow-id}

## 前置说明
本编排文件由 workflow-engine 在命中 {workflow-id} 后调用。
实际要素内容生成完全交由 element-runner 执行，本文件只控制宏观流程。

## ⚠️ 单一文档强制约束
本编排文件执行期间，有且只有一个输出文档存在。
所有要素执行结果由 element-runner Phase 6 追加写入该文档，不得另建任何中间文档。

---

## Phase 0：续接检查（若此 workflow 支持续接恢复）

## Phase 1：初始化

1. 创建/定位输出文档
2. 写入初始 frontmatter
3. 确认有效要素序列（**v1.2.0：从 element-type-registry 动态读取，含 chapter_info**）
4. 其他初始化操作

## Phase 1.5：变化点路由（仅 modify/incremental 模式）⚠️ v1.2.0 新增

按 3.5.3 节的四步流程：
1. 变化点识别
2. 要素影响汇聚
3. always_affected 要素补全
4. dependency-graph 安全网校验

得到 effective_sequence。

## Phase 2：要素循环

按 effective_sequence（build 模式）或 经过场景路由后的序列（modify/incremental 模式），循环执行：

FOR EACH element IN effective_sequence:
  1. 从 element-type-registry 读取 chapter_info：
     chapter_info = {
       l1_no: element.chapter_no_cn,
       element_name: element.name,
       sub_elements: element.sub_elements,
       backend_only: element.backend_only,
       chapter_label_style: element.chapter_label_style
     }
  2. 调用 element-runner，传入 element_id、execution_mode、context（含 chapter_info）
  3. 处理返回信号（C/B/S/Q/SKIP）
     # ⚠️ v1.2.1 显式挂起规则：
     # element-runner 输出操作菜单后，FOR 循环必须挂起，本次响应立即终止。
     # 禁止在同一响应中预判信号并继续循环。
     # 必须等待用户下一条消息到达，由消息内容决定信号值后再继续。

## Phase 2.5：全局收口（可选，仅 incremental / modify 模式下特定 Skill 启用）

**触发条件**：当 orchestration 的 effective_sequence 中存在"全局收口型要素"时启用。全局收口型要素的特征：其 Spec 的 `## 执行步骤 → incremental 模式` 明确声明"需要等所有其他要素的 ImpactPoint 全部收齐后执行"。

> **典型场景**：`story-design` 要素（PRD Skill）——Story 拆分与合并决策需要全局视野，必须在所有功能性要素产出 ImpactPoint 后才能做出合理判定。

**执行规则**：

1. **前置检查**：Phase 2 要素循环必须完全结束（所有非全局收口型要素均已执行并写入 frontmatter.impact_points），才可进入本阶段
2. **ImpactPoint 全集传递**：从 frontmatter.impact_points 读取全集，作为 `context.impact_analysis.impact_points` 传入全局收口型要素的 element-runner 调用
3. **调用 element-runner**：与普通要素执行相同，通过 element-runner 执行，遵循六阶段流程
4. **顺序约束**：全局收口型要素在 element-type-registry 中的 chapter_no 可以是最大值，但 orchestration **禁止**在 Phase 2 要素循环中按 chapter_no 顺序提前触发它；必须由 Phase 2.5 统一处理
5. **多个全局收口要素**：若存在多个，按 chapter_no 升序在 Phase 2.5 中依次执行

**orchestration 实现模板**：

```
## Phase 2.5：全局收口（若 effective_sequence 含全局收口型要素）

IF effective_sequence 中存在 always_affected 且 Spec 声明 require_full_impact_points=true 的要素:
  FOR EACH such_element IN （按 chapter_no 升序）:
    1. 从 frontmatter.impact_points 读取完整列表，追加到 context.impact_analysis.impact_points
    2. 调用 element-runner（element_id=such_element.id, execution_mode, context）
    3. 处理返回信号（C/B/S/Q）
```

## Phase 3：完成收尾

1. 跨要素全局一致性检查
2. 更新 ongoing.md 中的状态
3. 输出 SKILL.md 中定义的完成提示模板
```

**禁止在 orchestration 文件中出现**：
- 任何具体要素的执行步骤；
- 任何对 spec/*.md 的直接读取；
- 对 frontmatter 除初始写入之外的直接修改；
- 任何业务内容的直接生成；
- **v1.2.0 新增**：硬编码的章节映射表（必须从 element-type-registry 动态读取）；
- **v1.2.1 新增**：在 element-runner 返回操作菜单信号后、用户下一条消息到达前，继续执行 FOR 循环的任何动作。

---

### Layer 5 — 设计实现层

#### 3.6.1 spec/_template.md（v1.2.0 字段升级）

**用途**：新建 Spec 文件时的必须参考模板。

**v1.2.0 完整 frontmatter**：

```markdown
---
# ── 必填字段 ─────────────────────────────────────────────────
module_id: "{m-doc-type-element-id}"   # 与文件名一致（不含 .md）
implements: "{element-id}"             # 与 element-type-registry 中的 id 一致
for_type: ["{类型1}"]                  # 适用需求类型
execution_mode: ["{mode1}", "{mode2}"]  # 适用执行模式
status: "active"                       # active / planned

# ── v1.2.0 必填字段 ──────────────────────────────────────────
for_scenario: ["专题需求", "优化需求"] # 适用场景

# ── 可选字段 ─────────────────────────────────────────────────
extend_ref: "extend:{element-id}"      # 用户扩展挂载点
dual_input_mode: false                 # v1.2.0：是否支持多源输入（如文档抽取 + 对话）
output_contract_version: "1.0.0"       # v1.2.0：仅当本 Spec 产出契约性 artifact 时声明
---

# {module_id} — {要素名称}

> {一句话说明本要素的核心产出和价值}

---

## 目标
**目标说明**
**输出物**
**成功标准**

---

## 前置条件
**依赖要素**
| 依赖要素 element_id | 原因 |
|----------------------|------|

**必要输入**

**跳过条件**（可选）

---

## 约束

### 格式规范
| standard_id | 规范说明 |
|-------------|---------|

### 设计约束
| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|---------|

---

## 执行步骤

### build 模式
**Step 1:** `[自动/交互]` ...

### modify 模式（若 execution_mode 包含 modify）
**Step 1:** `[自动]` ...

### incremental 模式（若 execution_mode 包含 incremental）
**Step 1:** `[自动]` ...

---

## 追问维度（可选）
## 完整性检查（可选）
## 强制质量检查
## 输出骨架
```

**特殊情况：backend_only 要素**

对于 element-type-registry 中标记 `backend_only: true` 的要素，其 Spec 的 `## 输出骨架` 章节应写明：

```markdown
## 输出骨架

> ⚠️ 本要素 backend_only=true，element-runner Phase 6 仅更新 frontmatter，不写入文档正文。

**写入位置**：
- 输出文档 frontmatter 字段：`{字段名}: {取值范围}`
- workspace/ongoing.md 字段（若需要）：`{字段名}: {取值范围}`

（无文档正文骨架）
```

**Spec 文件结构约束说明**：

| 章节 | 是否必填 | 内容来源 | 被 element-runner 哪个 Phase 读取 |
|---|---|---|---|
| Frontmatter | 必填 | 路由元数据 | Phase 1 |
| ## 目标 | 必填 | 要素目标、输出物、成功标准 | 不被引擎读取（供人类理解） |
| ## 前置条件 | 必填 | 依赖要素表格、必要输入列表、跳过条件 | Phase 2 |
| ## 约束 → ### 格式规范 | 必填（无规范时写空表格） | standard_id 引用表格 | Phase 3 |
| ## 约束 → ### 设计约束 | 必填（无约束时写空表格） | 约束规则表格 | Phase 5 |
| ## 执行步骤 | 必填 | 按 execution_mode 分支的 Step 序列 | Phase 4 |
| ## 追问维度 | 可选 | 对话式要素的追问角度 | Phase 4（被执行步骤引用） |
| ## 完整性检查 | 可选 | 信息完整性 checklist | Phase 4 |
| ## 强制质量检查 | 必填 | 质量红线 checklist | Phase 5（补充约束） |
| ## 输出骨架 | 必填 | 输出内容的 Markdown 模板（backend_only 时为说明） | Phase 4 |

---

#### 3.6.2 standards/{standard-id}-standard.md

**用途**：系统内置设计规范文件。定义特定输出格式（如 ER 图、架构图、表格样式）的具体规则、正确示例、错误示例和验证检查点。可被用户私有扩展覆盖。

**定位**：规范资产层。被 standards-loader 加载后注入给 element-runner Phase 3/5 使用，是要素执行时的"格式约束库"。

**依赖**：
- 被 `engine/standards-loader.md` Level 2 加载（当用户扩展未覆盖时）
- 被 `registry/standards-registry.yaml` 注册（提供 id 和 file_path 映射）
- 被 `spec/*.md` 的 `## 约束 → ### 格式规范` 表格引用（standard_id 列）
- 用户扩展覆盖：若 `workspace/extend-rule/INDEX.md` 中存在同名 standard_id 映射，则本文件被屏蔽（用户扩展优先级更高）

**内容结构（强制约束）**：

```markdown
---
standard_id: "{standard-id}"    # [必填] 与 standards-registry 中 id 一致
name: "{规范名称}"               # [必填] 人类可读名称
version: "{版本号}"              # [必填] 规范版本号（便于追溯和兼容性判断）
---

# {standard-id} — {规范名称}

## 适用范围
{说明本规范适用于哪些要素、哪些场景、哪些输出格式}

## 规则定义

### {规则分类1}
{具体规则描述，包含正确示例和错误示例}

```示例
{正确格式的实际示例代码块}
```

```错误示例
{不符合规范的示例，标注错误原因}
```

### {规则分类2}
{按需要继续添加规则分类}

## 禁止事项

- {明确禁止的做法1}
- {明确禁止的做法2}

## 验证检查点

- [ ] {可自动验证的检查项1}
- [ ] {可自动验证的检查项2}
- [ ] {需要人工确认的检查项}
```

**注意事项**：
- `standard_id` 必须与文件名中的 `{standard-id}` 一致（如文件名 `er-diagram-standard.md` 则 frontmatter 中 `standard_id: "er-diagram-standard"`）
- 规范内容应具体可验证，避免抽象描述（如"ER图必须清晰"应改为"ER图节点必须包含主键标注"）
- 示例代码块应使用实际 Markdown 或 Mermaid 语法，便于 element-runner Phase 5 自动验证
- 用户扩展覆盖时，本文件完全被屏蔽（不会合并），如需部分覆盖请在用户扩展文件中手动复制保留部分
- 禁止在规范文件中包含执行逻辑或 Prompt 指令（规范只描述"验证什么"，element-runner Phase 5 决定"如何验证"）
- 版本号建议使用语义化版本（如 1.0.0），规范内容变更时更新版本号并记录变更日志

---

#### 3.6.3 workspace/extend-rule/INDEX.md

**用途**：用户私有规范扩展索引文件。定义 standard_id 到用户自定义规范文件的映射，实现"用户扩展 > 系统内置"的规范优先级，无需修改 Skill 核心文件即可覆盖任意规范。

**定位**：用户扩展层入口。被 standards-loader Level 1 优先查询，若找到映射则直接加载用户文件，屏蔽系统内置规范。

**依赖**：
- 被 `engine/standards-loader.md` Level 1 读取（最高优先级查询）
- 被 `config.yaml` 的 `standards.extend_index` 字段声明路径
- 用户自定义文件依赖：表格中"自定义规范文件路径"列指向的文件必须存在，否则 standards-loader 报错

**内容结构（强制约束）**：

```markdown
# 用户规范扩展索引

本索引定义用户自定义规范对系统内置规范的覆盖关系。
standards-loader 按本索引映射优先加载用户扩展文件，内置规范被屏蔽。

| standard_id | 自定义规范文件路径 | 覆盖原因 |
|-------------|-------------------|----------|
| {standard-id} | workspace/extend-rule/{custom-file}.md | {为什么要覆盖内置规范，如企业特定格式要求} |
```

**注意事项**：
- `standard_id` 必须与 `registry/standards-registry.yaml` 中某个已注册的 id 对齐（仅能覆盖已存在的规范）
- 自定义规范文件必须遵循与系统内置规范相同的结构（包含适用范围/规则定义/禁止事项/验证检查点）
- 一旦在本索引中添加映射，对应系统内置规范完全被屏蔽（不会合并），如需部分保留请在自定义文件中手动复制
- 自定义规范文件路径建议使用相对路径（相对于 Skill 根目录），便于跨环境迁移
- 禁止在本索引中包含任何规范内容或验证逻辑（只存映射关系）
- 新增扩展后无需修改任何 Skill 核心文件（这是热插拔设计的核心价值）
- 删除扩展映射即可恢复使用系统内置规范（移除表格对应行即可）

---

### 3.7 模式定义（v1.2.0 新增）

本节正式定义 build / modify / incremental 三种 execution_mode 的语义、数据结构和输出格式。

#### 3.7.1 build 模式

**语义**：从零开始全量生成。无基线文档，按 Spec 的 `## 执行步骤 → ### build 模式` 分支顺序执行。

**Context 字段使用**：
- `output_doc_path`：必填，新建文档路径
- `input_doc_path`：可选，上游 artifact 路径
- `base_doc_path`：不使用
- `modify_focus`：不使用
- `impact_analysis`：不使用

**输出**：完整章节内容，追加写入 output_doc_path

---

#### 3.7.2 modify 模式

**语义**：基于评审意见对已完成文档做局部修改。有基线文档（即被修改文档），根据 modify_focus 定位修改点。

**Context 字段使用**：
- `output_doc_path`：必填，被修改文档路径（同 base_doc_path）
- `base_doc_path`：必填，被修改文档路径
- `modify_focus`：必填，定位修改点的数据（schema 见下）

**modify_focus Schema（v1.2.0 正式化）**：

```yaml
modify_focus:
  - item_id: "REVIEW-001"               # 评审条目编号
    chapter: "5.2"                      # 受影响章节编号
    element_id: "feature-spec"          # 受影响要素 ID
    description: "FR-01-02 的验收标准缺少 Error Path"
    op_type: "add" | "modify" | "delete"
```

**修改标注格式**：

修改的段落末尾追加 HTML 注释（人类可读，机器可解析）：

```html
<!-- Modified: review_item=REVIEW-001, op=modify, date=2026-05-07, summary={修改摘要} -->
```

---

#### 3.7.3 incremental 模式

**语义**：基于历史版本生成新版本，保留历史内容并叠加增量。有历史基线文档（base_doc_path）和新输出文档（output_doc_path）。

**Context 字段使用**：
- `output_doc_path`：必填，新版本文档路径
- `base_doc_path`：必填，历史基线文档路径
- `impact_analysis`：必填，变化点路由结果

**RR（原始需求）运行时 Schema**：

增量模式下，用户的每条业务描述必须先结构化为 RR 条目，再进行变化点识别。RR 列表写入输出文档 frontmatter 的 `requirement_register` 字段，作为追溯链的根节点（RR → 原子变化点 → ImpactPoint）。

```yaml
# RR 运行时实例 Schema（v1.3.0）
RR:
  id:          "RR-{序号}"            # 全局递增，如 RR-01、RR-02
  description: "用户原文，一字不改"   # 严禁改写或摘要
  source:      "对话输入 | 文档片段"  # 来源
  status:      "已分析 | 待澄清"      # 分析状态
```

**impact_analysis Schema**：

```yaml
impact_analysis:
  requirement_register:                 # 本次增量的原始需求列表（同步写入输出文档 frontmatter）
    - id: "RR-01"
      description: "..."               # 用户原文
      source: "对话输入 | 文档片段"
      status: "已分析 | 待澄清"

  triggered_changes:                    # 运行时识别出的 AtomicChange 实例列表（v1.3.0：使用运行时实例结构）
    - id: "UI-01"                       # 原子变化点 ID，引用 atomic-change-registry
      source_requirement: "RR-01"       # 触发本变化点的原始需求
      evidence: "证据原文片段"
      evidence_source: "..."            # 具体档位由 Skill 方案文档声明
      confidence: "high | medium | low"
      open_question: ""                 # 置信度非 high 时的待确认问题

  effective_sequence:                   # 经变化点路由后的有效要素序列
    - element_id: "ui-prototype"
      impact_level: "certain"
      source_changes: ["UI-01"]         # 触发此要素进入序列的变化点列表（v1.3.0 新增）
    - element_id: "feature-spec"
      impact_level: "likely"
      source_changes: ["UI-01", "DA-02"]

  cascade_warnings:                     # dependency-graph 安全网发现的额外影响
    - element_id: "story-design"
      reason: "always_affected_in incremental"

  impact_points: []                     # ImpactPoint 实例列表；由 incremental orchestration 在要素循环中累积写入
```

**ImpactPoint 数据结构（v1.3.0 修订）**：

ImpactPoint 是"变化点对要素的具体影响落点"统一抽象。v1.3.0 废弃 `kind` 字段，统一为单一结构：变更内容与边界约束是同一影响点的两个侧面，`boundary_constraints` 作为可选子字段嵌入，不再独立成条目。

```yaml
ImpactPoint:
  id:                  "IP-{全局序号}"    # 全局编号，跨要素连续递增，如 IP-001
  source_requirement:  "RR-{xx}"          # 来源原始需求编号；多条需求合并触发时用列表
  source_change:       "{change_id}"      # 来源原子变化点 ID（来自 atomic-change-registry）
  trigger_type:        "primary | cascade" # primary=变化点直接触发；cascade=依赖图传导触发
  cascade_rule:        ""                 # trigger_type=cascade 时填依赖图边的 reason；primary 时置空
  element:             "{element_id}"     # 受影响的要素 ID（来自 element-type-registry）

  # ─── 变更落点 ──────────────────────────────────────────────
  baseline_ref:        "{基线章节引用，如 PRD §X.Y / FE §X.Y / 活动名称}"
  baseline_state:      "{基线现状原文；基线无对应内容时写'基线无对应章节/字段'}"
  action:              "新增 | 修改 | 删除 | 复用 | 不涉及"
  target_state:        "{变更后目标状态}"
  target_state_evidence: "{证据来源；具体档位枚举值由各 Skill 方案文档声明，见下方说明}"
  in_scope:            ["明确包含的对象列表（活动名/功能名/字段名/页面名等）"]
  out_of_scope:        ["明确排除的同类对象列表"]
  out_of_scope_reason: "{为什么这些对象不受影响；FE 增量模式必填；PRD 增量模式推荐填写}"

  # ─── 边界约束（可选，当存在"绝对不能改"的对象时填写）──────
  boundary_constraints:
    - target:      "{禁止改动的对象（实体名/字段名/接口名/规则编号等）}"
      reason:      "{禁止原因，如：现有依赖 | 合规约束 | 架构边界 | 历史数据风险}"
      consequence: "{若违反会发生什么}"
      evidence:    "{依据来源（基线章节路径 / 用户澄清说明）}"
```

**`target_state_evidence` / `evidence_source` 档位说明**：

规范不固定枚举值，各 Skill 方案文档是档位的权威声明源。当前已知声明：

| Skill | 字段 | 档位定义 |
|---|---|---|
| ia-fe-generator（FE 增量）| `target_state_evidence` | `baseline_fe`（来自基线 FE 文档）/ `dialog`（来自用户澄清） |
| ia-fe-to-prd（PRD 增量）| `target_state_evidence` | `fe_doc`（来自新版 FE 文档）/ `baseline_prd`（来自基线 PRD）/ `dialog`（来自用户澄清） |
| AtomicChange 实例（所有 Skill）| `evidence_source` | 同上，各 Skill 声明 |

新增 Skill 时，在 Skill 方案文档的"铁律一"或等效章节中声明本 Skill 的档位枚举，无需修改本规范。

**与旧术语的对应关系（v1.3.0 更新）**：

| 旧概念（v1.0 / v1.2.x）| 新概念（v1.3.0）|
|---|---|
| ChangePoint（CP-xxx） | ImpactPoint（IP-xxx，action 字段表达变更性质） |
| ForbiddenItem（FB-xxx） | ImpactPoint.boundary_constraints[]（嵌入相邻 ImpactPoint 的子字段） |
| `kind: "modify"` 字段 | 已废弃；变更性质改由 `action` 字段表达 |
| `kind: "forbid"` 字段 | 已废弃；禁止项改由 `boundary_constraints[]` 子字段表达 |
| IP-xxx-forbid 独立编号 | 已废弃；边界约束随主体 IP-xxx 编号，不再独立编号 |
| `adjacent_to` 字段 | 已废弃；boundary_constraints 直接嵌入对应 IP，天然与主体相邻 |
| 改动点清单 + 禁止改动项清单（两张表）| 影响点清单（统一列表，boundary_constraints 作为可选子字段）|

**DELTA 格式（v1.2.0 修订，引擎接口契约）**：

增量内容必须用 DELTA 标注块包裹：

```html
<!-- DELTA: change={change_id}, chapter={element_id}, op={add|modify|delete}, level={certain|likely|conditional} -->
...增量内容（保留 Markdown 格式）...
<!-- /DELTA -->
```

**字段说明**：
- `change`：触发增量的原子变化点 ID（来自 atomic-change-registry）
- `chapter`：受影响要素 ID
- `op`：操作类型（add/modify/delete）
- `level`：影响置信度（certain/likely/conditional）

> **历史兼容性提示（v2.1.0 引擎）**：旧版本 DELTA 注释使用 `scene=` 字段。当前引擎只识别 `change=`。如有存量 incremental 文档需要做一次性迁移，使用正则替换：`scene=([A-Z]{2}-\d{2})` → `change=$1`。

---

## 第四章 扩展规范

### 4.1 新增 Skill（同类设计文档 Skill）

**必须遵守的步骤**：

1. **复制目录结构**：按本规范第二章的标准目录结构创建新 Skill 目录；
2. **从权威源拷贝引擎**：执行 `cp docs/engine-canonical/*.md skills/{new-skill}/engine/`，禁止手写引擎文件；
3. **从模板创建文件**：
   - SKILL.md：参照 3.1.1 节内容结构填写
   - config.yaml：参照 3.1.2 节内容结构填写
   - registry/*.yaml：按新 Skill 的场景和要素重新填写
   - orchestration/*.md：按新 Skill 的场景数量创建
   - spec/*.md：每个要素创建一个文件，基于 `spec/_template.md` 填写
4. **验证完整性**：参照附录 B 合规性自检清单逐项检查。

### 4.2 新增场景（现有 Skill 新增 workflow）

**必须遵守的步骤**：

1. 在 `registry/workflow-registry.yaml` 中新增 workflow 条目（`status: planned` 先占位，实现后改 `active`）；
2. 在 `orchestration/` 下新建对应编排文件；
3. 若新场景需要新的输入类型，在 `registry/input-type-registry.yaml` 中新增；
4. 若新场景是 modify/incremental 模式且需要场景路由，在 `config.yaml.extension_registry` 中声明并创建对应注册表（详见 4.8 节）；
5. 在 `engine/workflow-engine.md` 中**无需修改**；
6. 验证 priority 不与现有 workflow 重复。

**禁止**：为新场景在 element-runner.md 中添加 if/else 分支判断。

### 4.3 新增要素（现有 Skill 新增输出章节）

**必须遵守的步骤**：

1. 在 `registry/element-type-registry.yaml` 中新增要素条目，**v1.2.0 必填字段**：
   - chapter_no_cn
   - chapter_label_style
   - sub_elements（如有子章节）
   - backend_only（如适用）
2. 基于 `spec/_template.md` 创建对应 spec 文件；
3. 在 `registry/spec-template-registry.yaml` 中新增映射条目；
4. 若新要素需要新规范，在 `standards/` 中新建规范文件，并在 `registry/standards-registry.yaml` 中注册；
5. 在对应 orchestration 的 `element_sequence` 中添加新要素；
6. **禁止**修改 element-runner.md。

### 4.4 已有要素的 Spec 规格扩展

1. 确定修改目标：执行步骤问题 → ## 执行步骤；约束规则问题 → ## 约束；输出格式问题 → ## 输出骨架 或 standards/
2. 层级约束：仅在 Layer 5 修改，禁止修改 Layer 2
3. 关联同步：若涉及 frontmatter 或 standard_id 引用，同步更新对应注册表
4. 版本记录：结构性改动时更新 frontmatter 的 version

### 4.5 设计规范扩展

1. 文件位置：`workspace/extend-rule/`，命名 `{standard-id}-standard.md`
2. 索引注册：必须在 `workspace/extend-rule/INDEX.md` 添加映射
3. 覆盖优先级：用户扩展高于内置
4. 禁止：直接修改 `standards/` 下文件；引用不存在路径；包含执行逻辑

### 4.6 排查和修复 Skill 问题

| 症状 | 定位层 | 修改目标文件 |
|------|--------|-------------|
| Skill 未正确触发 | Layer 1 / Layer 3 | SKILL.md 触发词；workflow-registry trigger_keywords |
| 进入了错误的 workflow | Layer 2 / Layer 3 | workflow-engine 消歧逻辑；workflow-registry input_signature |
| 用户指定的 workflow 未被识别 | Layer 2 | workflow-engine.md Phase 1.5 |
| 章节编号错乱 | Layer 3 | element-type-registry chapter_no_cn / sub_elements |
| 要素执行顺序错误 | Layer 3 / Layer 4 | workflow-registry element_sequence；orchestration 循环逻辑 |
| 要素跳过条件不正确 | Layer 5 | spec/{m-xxx}.md 的 ## 前置条件 → 跳过条件 |
| 要素输出格式不符合预期 | Layer 5 | spec/{m-xxx}.md 的 ## 输出骨架 或 ## 约束 |
| 追问逻辑不合理 | Layer 5 | spec/{m-xxx}.md 的 ## 执行步骤 或 ## 追问维度 |
| 规范格式不正确 | Layer 5 | standards/{standard-id}-standard.md |
| 状态写入错误 | Layer 2 | element-runner.md 的 Phase 6 |
| 路径引用错误 | Layer 1 | config.yaml |
| 引擎在两个 Skill 表现不一致 | Layer 2 | docs/engine-canonical/，并同步到所有 Skill |
| 增量变化点识别不准 | Layer 3.5 | atomic-change-registry / change-element-mapping |
| 跨 Skill artifact 不兼容 | 第六章 | output-contract.yaml / config.yaml.upstream_dependencies |

---

### 4.7 引擎共享与同步机制（v1.2.0 新增）

**核心原则**：所有同类设计文档 Skill 共享同一份引擎权威源。引擎是共享资产，单 Skill 不得擅自修改。

#### 4.7.1 权威源位置

`docs/engine-canonical/` 是引擎的唯一权威源，包含：
- `element-runner.md`
- `workflow-engine.md`
- `standards-loader.md`
- `ENGINE-VERSION`（纯文本文件，内容为当前引擎版本号，如 `2.0.0`）
- `README.md`（说明同步规则）

#### 4.7.2 同步策略：物理拷贝

**策略**：每个 Skill 的 `engine/*.md` 是 `docs/engine-canonical/*.md` 的物理拷贝。

**同步操作**：当权威源更新后，手动执行：

```bash
cp docs/engine-canonical/element-runner.md skills/{skill-name}/engine/
cp docs/engine-canonical/workflow-engine.md skills/{skill-name}/engine/
cp docs/engine-canonical/standards-loader.md skills/{skill-name}/engine/
cp docs/engine-canonical/ENGINE-VERSION skills/{skill-name}/engine/
```

**适用前提**：单一维护者或小团队（可以靠人工纪律保证同步）。如果团队规模扩大，可升级到 git submodule 或自动化构建脚本。

#### 4.7.3 版本字段

引擎三个文件的开头必须包含 `engine_version` 元信息：

```markdown
## 引擎元信息
engine_version: "2.0.0"
spec_compliance: "v1.2.0"
```

`docs/engine-canonical/ENGINE-VERSION` 文件内容为权威版本号字符串。

#### 4.7.4 启动校验（推荐）

SKILL.md 启动序列建议加入引擎版本校验步骤：

```markdown
## 启动序列
1. 读取 config.yaml
2. ⚠️ 校验 engine/element-runner.md 中的 engine_version 与 docs/engine-canonical/ENGINE-VERSION 一致
   - 若不一致：输出警告"⚠️ 引擎版本与权威源不一致，请同步：cp docs/engine-canonical/* skills/{skill-name}/engine/"
   - 不阻断执行，但建议立即同步
...
```

#### 4.7.5 修改流程

**禁止**：直接修改 Skill 内的 `engine/*.md`。

**正确流程**：
1. 修改 `docs/engine-canonical/` 下的对应文件
2. 更新 `docs/engine-canonical/ENGINE-VERSION`（递增版本号）
3. 同步拷贝到所有受影响的 Skill
4. 在每个 Skill 中跑一次启动校验，确认版本一致

---

### 4.8 变化点路由层扩展（v1.2.0 新增）

当某 modify/incremental 工作流需要变化点路由能力时：

1. 在 `config.yaml.extension_registry` 中声明：
   ```yaml
   extension_registry:
     atomic_changes: "registry/atomic-change-registry.yaml"
     change_element_mapping: "registry/change-element-mapping.yaml"
     dependency_graph: "registry/dependency-graph.yaml"
   ```
2. 创建三个注册表文件（schema 见 3.5.1、3.5.2、3.3.6.1）
3. 在 element-type-registry 中为相关要素添加 `always_affected_in` 字段
4. 在 orchestration 中按 3.5.3 节的四步流程实现变化点路由

**禁止**：跳过变化点路由层直接基于关键词写硬编码路由逻辑。

---

## 第五章 禁止事项汇总（红线清单）

以下行为在任何情况下均不得发生，是本规范的绝对约束：

### 5.1 内容错放红线

| 禁止行为 | 正确做法 |
|---|---|
| 在 `element-runner.md` 中写特定要素的执行步骤或追问话术 | 写在 `spec/{m-xxx}.md` 的 `## 执行步骤` 中 |
| 在 element-runner Phase 5 中出现 `element_id == "xxx"` 式的专项检查 | 将验证规则写入对应 Spec |
| **v1.2.0：在 element-runner 中硬编码特定客户端工具名（如 AskUserQuestion）** | 由 Spec 的 `## 执行步骤` 自定义交互方式 |
| 在 `orchestration/` 中直接生成或写入文档内容 | 通过调用 element-runner 执行 |
| 在 `orchestration/` 中读取 `spec/*.md` | 只有 element-runner 读取 Spec |
| **v1.2.0：在 `orchestration/` 中硬编码章节映射表** | 从 element-type-registry 动态读取 chapter_info |
| **v1.2.1：element-runner 输出操作菜单后在同一响应中继续执行** | 输出菜单后立即终止响应，等待用户下一条消息 |
| 在 `workflow-engine.md` 中出现 if requirement_type == 'TP' 等硬编码 | 判断逻辑放入 `workflow-registry.yaml` |
| 在 `SKILL.md` 中包含具体要素的执行逻辑 | 执行逻辑全部在 Layer 5 |
| 在 `registry/*.yaml` 中包含 Prompt 指令或自然语言执行步骤 | Registry 只存元数据 |
| 在 Spec Frontmatter 中存放约束规则 | 约束规则写在 Spec Body 的 `## 约束` 章节 |

### 5.2 状态写入红线

| 禁止行为 | 正确做法 |
|---|---|
| 在 element-runner Phase 6 之外更新 stepsCompleted、last_element、status | 仅在 Phase 6 统一更新 |
| orchestration 直接修改输出文档 frontmatter 状态字段 | 由 element-runner Phase 6 负责 |
| 任何文件私自创建新的状态文件 | 状态只存在 ongoing.md 和输出文档 frontmatter |
| **v1.2.0：跨命名空间互写 ongoing.md** | FE Skill 不写 prd: 字段，反之亦然 |

### 5.3 注册表红线

| 禁止行为 | 正确做法 |
|---|---|
| 在 element-type-registry 中注册未实现的要素占位符 | 未实现要素不注册，实现后再加 |
| spec-template-registry 中的 implements 与 element-type-registry 的 id 不一致 | 两者必须严格对齐 |
| workflow-registry 中引用不存在的 orchestration 文件 | 先建 orchestration 文件再注册 active |
| **v1.2.0：未在 config.yaml.extension_registry 中声明的 .yaml 文件被引擎或 orchestration 加载** | 所有扩展注册表必须显式声明 |

### 5.4 引擎共享红线（v1.2.0 新增）

| 禁止行为 | 正确做法 |
|---|---|
| 直接修改 Skill 内的 engine/*.md | 修改 docs/engine-canonical/ 后同步拷贝 |
| 引擎文件缺少 engine_version 字段 | 必须包含元信息块 |
| 不同 Skill 的引擎版本不一致仍发布 | 修改后必须同步到所有 Skill |

---

## 第六章 跨 Skill 协同规范（v1.2.0 新增）

本章规范多个同类 Skill 之间的依赖、契约、衔接行为。当一个 Skill 消费另一个 Skill 的产物（如 PRD Skill 读 FE Skill 的输出）时，必须遵循本章约束。

---

### 6.1 上下游 artifact 契约

每个 Skill 在根目录创建 `output-contract.yaml`，正式声明输出 artifact 的契约。

**Schema**：

```yaml
output_contract_version: "1.0.0"        # 契约版本号
skill_id: "ia-fe-generator"

frontmatter_schema:
  required_fields:
    - name: "workflow_id"
      type: "string"
      values: ["tp-new-build", "tp-incremental-build", "fe-review-modify"]
    - name: "requirement_type"
      type: "string"
      values: ["TP", "AP", "AI", "IT"]
    - name: "status"
      type: "string"
      values: ["in_progress", "completed"]
    - name: "project_name"
      type: "string"
    - name: "stepsCompleted"
      type: "list[string]"
      description: "已完成的 element_id 列表"
    - name: "last_element"
      type: "string"
    - name: "last_updated"
      type: "string"
      format: "YYYY-MM-DD"

content_schema:
  guaranteed_chapters:                   # 承诺一定存在的章节
    - chapter_no: 1
      element_id: "original-requirement"
      sub_elements_guaranteed: ["关键信息提取矩阵"]
    - chapter_no: 4
      element_id: "business-process"
      sub_elements_guaranteed: ["活动总览", "活动明细", "角色清单", "业务规则"]
    - chapter_no: 5
      element_id: "business-function"
      sub_elements_guaranteed: ["功能清单"]

versioning_policy:
  - "新增章节、新增字段：minor 版本递增（1.0 → 1.1）"
  - "删除章节、删除字段、字段语义变更：major 版本递增（1.0 → 2.0）"
  - "下游 Skill 的 min_contract_version 用 ^ 语义（兼容 minor 升级）"
```

---

### 6.2 下游消费方的依赖声明

每个消费上游 artifact 的 Skill，在 `config.yaml` 中声明：

```yaml
upstream_dependencies:
  - skill_id: "ia-fe-generator"
    min_contract_version: "1.0.0"
    consumed_chapters:
      - source_chapter: "活动明细"
        used_by_elements: ["app-architecture", "info-architecture", "feature-spec"]
      - source_chapter: "角色清单"
        used_by_elements: ["permission-design"]
```

---

### 6.3 兼容性检查

下游 Skill 的 workflow-engine 在 Phase 1 增加：
1. 读取上游 artifact 的 frontmatter
2. 提取 `output_contract_version` 字段
3. 与 `config.yaml.upstream_dependencies[*].min_contract_version` 对比
4. 不兼容时输出警告，建议用户升级上游 Skill 或降级当前 Skill

---

### 6.4 工作流编排（多 Skill 串行）

明确：FE → PRD → Design 这种多 Skill 工作流是**人在回路**的设计，不是自动化的。

每个 Skill 在 `## 完成提示模板` 中给出"建议下一步"，由用户决定是否启动下游 Skill：

```text
✅ ia-fe-generator 已完成

输出文件: workspace/requirements/I20260507/FE-项目名-20260507.md
契约版本: 1.0.0

建议下一步:
  ia-fe-to-prd I20260507
```

---

### 6.5 可选 Skill 依赖

当某 Spec 需要调用其他 Skill（但该 Skill 可能不可用）时，必须遵循以下模式：

**1. 在 config.yaml 声明**：

```yaml
optional_skill_dependencies:
  - skill_id: "iscit-req2proto"
    purpose: "生成 HTML 可交互原型"
    required_for_elements: ["ui-prototype"]
    fallback_strategy: "ask_user"        # ask_user | skip | error
```

**2. 在对应 Spec 的 `## 执行步骤` 中明确降级 UX**：

```markdown
**Step N: 调用可选 Skill** `[交互]`

1. 探测目标 Skill 是否可用
2. 可用 → 调用并验证产出
3. 不可用 → 按 fallback_strategy 执行：
   - ask_user：向用户说明并提供选项（[A] 跳过 / [B] 手动降级方案 / [Q] 退出）
   - skip：自动跳过本步骤，记录日志
   - error：终止当前要素执行
```

**禁止**：模型自行决定"我用降级方案吧"——必须显式声明策略，且 ask_user 策略必须等待用户选择。

---

## 附录 A：各文件一览速查表（v1.2.0 更新）

| 文件路径                                     | 所属层              | 格式                   | 核心用途           | 修改触发场景                  |
| ---------------------------------------- | ---------------- | -------------------- | -------------- | ----------------------- |
| **docs/engine-canonical/*.md**           | Layer 2（权威源）     | Markdown             | 引擎权威源          | 引擎升级时                   |
| **docs/engine-canonical/ENGINE-VERSION** | Layer 2（权威源）     | 纯文本                  | 引擎版本号          | 同上                      |
| SKILL.md                                 | Layer 1          | Markdown+Frontmatter | 入口触发、全局约束      | Skill 名称/触发词/全局约束变化     |
| config.yaml                              | Layer 1          | YAML                 | 路径配置中心         | 新增输出目录、新增挂载点            |
| **output-contract.yaml**                 | Layer 1（v1.2 新增） | YAML                 | 输出 artifact 契约 | 输出格式变更                  |
| workspace/ongoing.md                     | Layer 1（运行时）     | YAML                 | 项目状态锚点         | 运行时由 workflow-engine 维护 |
| engine/*.md                              | Layer 2          | Markdown             | 引擎（拷贝自权威源）     | 仅通过同步操作修改               |
| registry/workflow-registry.yaml          | Layer 3（标准）      | YAML                 | 工作流注册          | 新增/修改场景                 |
| registry/element-type-registry.yaml      | Layer 3（标准）      | YAML                 | 要素元数据注册        | 新增/修改要素                 |
| registry/spec-template-registry.yaml     | Layer 3（标准）      | YAML                 | Spec 路由映射      | 新增 Spec 文件              |
| registry/input-type-registry.yaml        | Layer 3（标准）      | YAML                 | 输入类型探测规则       | 新增输入类型                  |
| registry/standards-registry.yaml         | Layer 3（标准）      | YAML                 | 规范字典           | 新增规范文件                  |
| **registry/dependency-graph.yaml**       | Layer 3（扩展）      | YAML                 | 级联影响关系         | modify/incremental 场景   |
| **registry/atomic-change-registry.yaml** | Layer 3.5（扩展）    | YAML                 | 原子变化点目录        | incremental 场景          |
| **registry/change-element-mapping.yaml** | Layer 3.5（扩展）    | YAML                 | 变化点到要素映射       | incremental 场景          |
| orchestration/o-{workflow-id}.md         | Layer 4          | Markdown             | 场景宏观编排         | 新增场景、调整执行顺序             |
| spec/_template.md                        | Layer 5          | Markdown             | Spec 创建模板      | Spec 结构规范调整             |
| spec/m-{doc}-{element}.md                | Layer 5          | Markdown             | 要素规格书          | 要素实现细节调整                |
| standards/{id}-standard.md               | Layer 5          | Markdown             | 系统内置规范         | 规范规则更新                  |
| workspace/extend-rule/INDEX.md           | Layer 5          | Markdown             | 用户扩展索引         | 用户自定义覆盖规范               |

---

## 附录 B：架构合规性自检清单（v1.2.0 更新）

在提交任何 Skill 新建或修改前，按以下清单逐项自检：

**Layer 1 合规**
- [ ] SKILL.md 包含完整 Frontmatter（name/description/version/spec_compliance）
- [ ] SKILL.md 不含具体要素执行逻辑
- [ ] **v1.2.1**：SKILL.md 全局执行约束包含"操作菜单终止规则"条目
- [ ] config.yaml 包含所有必填字段，路径均使用相对路径
- [ ] **v1.2.0**：config.yaml 包含 spec_compliance 字段
- [ ] **v1.2.0**：所有扩展注册表已在 extension_registry 区块声明
- [ ] **v1.2.0**：output-contract.yaml 已创建（如果 Skill 输出供下游消费的 artifact）

**Layer 2 合规**
- [ ] workflow-engine.md 无任何业务类型硬编码
- [ ] element-runner.md 无任何特定要素实现细节
- [ ] **v1.2.0**：element-runner.md 无任何特定客户端工具名硬编码（如 AskUserQuestion）
- [ ] element-runner.md 状态写入仅在 Phase 6
- [ ] orchestration 调用 element-runner 时，chapter_info 参数已完整填充
- [ ] **v1.2.1**：element-runner.md Phase 6 操作菜单后包含"响应硬终止规则"声明
- [ ] **v1.2.0**：本 Skill 的 engine/*.md 内容与 docs/engine-canonical/ 完全一致
- [ ] **v1.2.0**：engine/*.md 包含 engine_version 字段，与 docs/engine-canonical/ENGINE-VERSION 一致

**Layer 3 合规**
- [ ] element-type-registry 中无 `status: planned` 的占位要素
- [ ] **v1.2.0**：element-type-registry 包含 chapter_no_cn、chapter_label_style 字段
- [ ] **v1.2.0**：有子章节的要素已填写 sub_elements
- [ ] spec-template-registry 中的 implements 与 element-type-registry 的 id 完全对齐
- [ ] workflow-registry 中所有 `status: active` 的 orchestration_file 均已存在
- [ ] **v1.2.0**：所有扩展注册表都在 config.yaml.extension_registry 中声明

**Layer 3.5 合规（v1.2.0，仅 modify/incremental 场景）**
- [ ] atomic-change-registry 中所有变化点都有完整字段
- [ ] change-element-mapping 中引用的 change_id 都在 atomic-change-registry 中存在
- [ ] change-element-mapping 中引用的 element_id 都在 element-type-registry 中存在
- [ ] always_affected_in 字段已为永远受影响的要素配置

**Layer 3.5 合规（v1.3.0 新增）**
- [ ] AtomicChange 运行时实例包含 `evidence`、`evidence_source`、`confidence`、`open_question` 字段（参见 §3.5.3 Step 1）
- [ ] impact_analysis.requirement_register 字段已定义并在 orchestration 中写入 frontmatter
- [ ] impact_analysis.triggered_changes 使用运行时实例结构（含 source_requirement / evidence / evidence_source / confidence），而非仅有 change_id
- [ ] impact_analysis.effective_sequence 每项含 source_changes 字段

**Layer 4 合规**
- [ ] 每个 orchestration 文件名与 workflow-registry 中 id 严格对应
- [ ] orchestration 中无直接内容生成
- [ ] orchestration 中无对 spec/*.md 的直接引用
- [ ] **v1.2.0**：orchestration 中无硬编码的章节映射表，chapter_info 来自 element-type-registry
- [ ] **v1.3.0**：全局收口型要素（Spec 声明 require_full_impact_points=true）未在 Phase 2 要素循环中执行，由 Phase 2.5 统一处理
- [ ] **v1.3.0**：incremental 模式 orchestration 在 Phase 2 结束后、Phase 2.5 前，已将 frontmatter.impact_points 完整读取并传入 context

**Layer 5 合规**
- [ ] 每个 spec 文件包含全部必填章节
- [ ] spec 约束规则在 Body 章节而非 Frontmatter
- [ ] **v1.2.0**：spec frontmatter 包含 for_scenario 字段
- [ ] **v1.2.0**：dual_input_mode、backend_only 等可选字段按需填写
- [ ] 每个 standards 文件在 standards-registry 中有注册
- [ ] **v1.3.0**：ImpactPoint 中无 `kind` 字段
- [ ] **v1.3.0**：ImpactPoint 中无独立的 `reason`、`consequence`、`adjacent_to` 顶层字段（这三个字段已移入 boundary_constraints[] 子字段）
- [ ] **v1.3.0**：ImpactPoint 包含 `source_requirement`、`target_state_evidence`、`out_of_scope_reason` 字段
- [ ] **v1.3.0**：FE 增量场景：ImpactPoint 的 `out_of_scope_reason` 在 Spec 中标注为必填
- [ ] **v1.3.0**：全局收口型 Spec（如 story-design）在 ## 执行步骤 → incremental 模式 中已声明 require_full_impact_points=true 语义

**第六章合规（v1.2.0，仅多 Skill 协同场景）**
- [ ] 上游 Skill 已发布 output-contract.yaml
- [ ] 下游 Skill 在 config.yaml.upstream_dependencies 声明上游依赖
- [ ] 可选 Skill 依赖已在 config.yaml.optional_skill_dependencies 声明
- [ ] 调用可选 Skill 的 Spec 在 ## 执行步骤 中明确了降级 UX

---

## 附录 C：v1.1 → v1.2 迁移指南（v1.2.0 新增）

本附录给出从 v1.1.0 兼容 Skill 迁移到 v1.2.0 完全兼容状态的步骤。

### C.1 迁移分级

迁移分为三档，按需选择：

**Level 1（必做）**：消除 v1.2.0 红线违反
- 从 element-runner 中移除特定客户端工具名硬编码
- 从 orchestration 中移除硬编码章节映射表，改为从 element-type-registry 读取
- 所有扩展注册表（如 dependency-graph）在 config.yaml.extension_registry 中声明

**Level 2（推荐）**：享受 v1.2.0 新功能
- 建立 docs/engine-canonical/ 权威源
- 引擎文件加 engine_version
- element-type-registry 加 chapter_no_cn、sub_elements、backend_only 等字段
- _template.md 加 for_scenario、dual_input_mode 等字段
- 创建 output-contract.yaml（如有下游消费方）

**Level 3（可选，按需）**：使用变化点路由层
- 仅当有 modify/incremental 工作流且需要变化点路由时
- 创建 atomic-change-registry.yaml、change-element-mapping.yaml
- 在 orchestration 中实现 3.5.3 节的四步流程

### C.2 兼容性保证

- v1.2.0 的所有新增字段均为可选；
- 现有 v1.1.0 兼容的 Skill 在不使用新字段时，仍可在 v1.2.0 框架下运行；
- v1.1.0 的所有红线条款在 v1.2.0 中继续生效，未放宽任何约束。

### C.3 迁移检查清单

按附录 B 的"v1.2.0"标记项逐一检查，全部通过即视为完全 v1.2.0 兼容。

---

### C.4 v1.2.x → v1.3.0 迁移指南

#### 迁移分级

**Level 1（必做）**：消除 v1.3.0 破坏性变更
- 搜索现有 incremental 输出文档中的 `kind: "modify"` 和 `kind: "forbid"`，按新结构重整（删除 kind 字段，将 reason/consequence/adjacent_to 移入 boundary_constraints[] 子字段）
- 搜索现有 Skill 的 ImpactPoint 生成逻辑，移除 kind 字段的分支判断
- 如有草案输出按 kind 分组展示的逻辑，改为统一列表展示

**Level 2（推荐）**：享受 v1.3.0 新功能
- 在 orchestration 中为 impact_analysis 新增 requirement_register 字段，并写入 frontmatter
- 在 impact_analysis.triggered_changes 中使用完整的 AtomicChange 运行时实例结构
- 在 ImpactPoint 中补充 source_requirement、target_state_evidence、out_of_scope_reason 字段

**Level 3（按需）**：使用全局收口型要素
- 仅当 Skill 中有类似 story-design 的要素（需要等全部 ImpactPoint 收齐才能执行）时
- 在 orchestration 中实现 Phase 2.5
- 在对应 Spec 中声明 require_full_impact_points=true 语义

#### 兼容性保证

- v1.3.0 的 ImpactPoint `kind` 字段废弃是破坏性变更，存量 incremental 文档需做一次性迁移
- v1.3.0 其余新增字段（source_requirement、target_state_evidence 等）均为可选，不影响不含这些字段的存量文档读取
- Phase 2.5 是可选阶段，不影响不需要全局收口的 Skill

#### 迁移检查清单

按附录 B 的"v1.3.0"标记项逐一检查，全部通过即视为完全 v1.3.0 兼容。

---

*本规范版本 1.3.0，遵循"Living Document"原则。规范本身放在 git 仓库管理，所有变更走 PR；变更必须附带"哪些现有 Skill 受影响、迁移步骤是什么"。下一次主版本升级（v2.0）将考虑：插件机制、多 Skill 自动编排、运行时模块加载等更大的架构变化。*
