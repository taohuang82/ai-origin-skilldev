---
module_id: "m-prd-story"
implements: "story-design"
for_scenario: ["专题需求"]
for_type: ["TP", "AP", "AI"]
execution_mode: ["build", "incremental"]
status: "active"
extend_ref: "extend:story-design"
---

# m-prd-story — Story 设计

> 基于 PRD 功能特性和非功能需求，按 INVEST 原则拆分 User Story，生成两类输出物：
> 1. **PRD索引章节**（仅包含清单和概述表格，标注独立文件路径）
> 2. **独立Story文件**（与PRD同级目录，包含完整5个子要素：清单、概述、描述、验收标准、关联设计）

---

## 目标

**目标说明**

Story 设计是 PRD 与开发迭代计划之间的桥梁。Story 不包含实现细节，只定义"什么角色、想做什么、为了什么价值"，以及可验证的验收标准。实现细节通过 PRD 章节引用获取。

**INVEST 原则**：Independent（独立）、Negotiable（可协商）、Valuable（有价值）、Estimable（可估算）、Small（足够小）、Testable（可测试）。

**输出物**

- PRD索引章节（第十一章）
  - 11.1 Story清单表格（含独立文件路径列）
- 独立Story文件（与PRD同级目录）
  - Story清单表格（完整列表）
  - Story概述表格（完整列表）
  - Story详细规格章节（每个Story一个三级标题，包含描述、验收标准、关联设计）

**成功标准**

- Story 清单覆盖所有 P0 子特性（至少有 FR 编号对应的 Story）
- 每个 Story 有完整的三段式描述（As a / I Want / So That）
- 每个 Story 至少有 1 条 BDD 格式验收标准
- 独立Story文件已生成并包含完整5个子要素

---

## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|----------------------|------|
| `feature-spec` | Story 来源于功能特性章节，引用 FR 编号和验收标准 |
| `nfr` | NFR Story 来源于非功能需求章节 |
| `permission-control` | 角色定义来源于权限设计 |

**必要输入**

- PRD 已完成功能特性章节（含 FR 编号和验收标准）
- PRD 已完成非功能需求章节

---

## 约束

### 格式规范

| standard_id | 规范说明 |
|-------------|---------|
| —（暂无格式规范引用） | |

### 设计约束

| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|---------|
| `DC-STORY-001` | `MUST` | 每个Story必须生成独立文件，文件路径符合替换规则（PRD→Story） | element-runner Phase 5检查文件存在性 |
| `DC-STORY-002` | `MUST` | 独立文件必须包含完整5个子要素（清单、概述、详细规格、验收标准、关联设计） | element-runner Phase 5检查章节完整性 |
| `DC-STORY-003` | `MUST` | PRD索引章节必须标注独立文件路径引用 | 检查PRD表格是否包含路径列 |
| `DC-STORY-004` | `MUST` | 每个 Story 必须有完整三段式描述：As a [角色] / I Want [功能] / So That [业务价值] | 检查每个 Story 是否包含三段式结构 |
| `DC-STORY-005` | `MUST` | 每个 Story 至少有 1 条 BDD 验收标准，格式为 Given / When / Then | 检查每个 Story 是否有 AC 字段 |
| `DC-STORY-006` | `MUST` | Story 粒度应符合 INVEST 原则（1 个 Sprint 可完成），不得包含整个流程 | 检查 Story 是否过大（如"整个审批流程"应拆分为多个 Story） |
| `DC-STORY-007` | `SHOULD` | NFR Story 应从非功能需求章节中拆分，如"性能优化 Story""安全审计 Story" | 检查 Story 清单中是否包含 NFR 类型的 Story |

---

## 执行步骤

**Step 1：从功能特性拆分 Functional Story** `[自动]`

为每个 FR 子特性生成 1 个（或多个）Story，引用功能特性章节的 FR 编号作为"来源子特性编号"，分配 Story 编号（S-FR-01-01-001-01 等，与 FR 对应）。

---

**Step 2：从非功能需求拆分 NFR Story** `[交互]`

从非功能需求章节识别可独立交付的非功能特性（性能优化、埋点接入、安全加固等），生成 NFR Story。

> **交互提示**：展示识别到的 NFR Story 列表，询问用户："以上非功能 Story 是否需要独立排期？是否有遗漏的非功能特性？"

---

**Step 3：构建完整Story结构** `[自动]`

为每个Story补充：
1. 三段式描述（从功能特性的 UIUX 操作步骤和验收标准中提取角色、功能和价值）
2. BDD 验收标准（引用功能特性章节的 AC，若不足则补充）
3. 关联详细设计（标注PRD章节编号和实体编号）

---

**Step 4：生成PRD索引章节内容** `[自动]`

基于Story清单，生成PRD文档第十一章的索引章节：
- 11.1 Story清单表格（包含Story编号、名称、类型、来源、优先级、独立文件路径列）
- 补充说明段落（标注独立Story文件路径）

---

**Step 5：生成独立Story文件路径** `[自动]`

**路径生成逻辑**:
1. 读取 `context.output_doc_path`（PRD文档路径）
2. 替换文件名中的"PRD"为"Story"（示例：`workspace/design/I20260423/Story-项目名称-20260423.md`）
3. 目录保持与PRD同级

---

**Step 6：生成独立Story文件内容** `[自动]`

**文件结构定义**（element-runner Phase 6写入）:

独立Story文件包含以下内容：
- Frontmatter（story_doc_id、source_prd、current_version、project_name、created_date、total_stories、functional_count、nfr_count）
- 一、Story清单表格（完整列表，所有Story）
- 二、Story概述表格（完整列表，所有Story）
- 三、Story详细规格章节（每个Story一个三级标题，格式如下）

每个Story的三级标题结构：
```markdown
### S-FR-01-01-001-01 全量导入标签数据

#### 3.1 Story描述
As a <Role>（作为...角色）
I want to <Action>（我希望...）
So that <Value>（以便于...）


#### 3.2 验收标准
Given（前提）：系统当前的上下文或初始状态。
When（触发）：用户执行的具体操作或发生的特定事件。
Then（结果）：系统状态的改变、返回的响应或副作用。
有多个，列出多条验收标准：
- AC1: Given [前提条件] / When [触发动作] / Then [预期结果]
- AC2: Given [前提条件] / When [触发动作] / Then [预期结果]

#### 3.3 关联详细设计

| 关联PRD章节 | 章节编号 | 设计文档路径 |
|------------|---------|-------------|
| 功能特性-子特性详细描述 | FR-01-01-001 | PRD文档第五章 5.2节 |
| 信息架构-实体详情 | E-xxx | PRD文档第四章 4.3节 |
```

**说明**: 本步骤仅定义"生成什么内容"，实际文件写入由element-runner Phase 6执行（两次写入：先写入PRD索引章节，再写入独立Story文件）。

---

## 强制质量检查

> **说明**: 本章节定义Story要素的MUST级质量红线，由element-runner Phase 5执行验证。

### MUST级约束（违反则Phase 5阻断）

- ✅ **独立Story文件必须生成**: 检查 `workspace/design/{current_version}/Story-*.md` 文件是否存在
- ✅ **独立文件包含完整子要素**: 检查独立文件是否包含以下章节：
  - 一、Story清单表格
  - 二、Story概述表格
  - 三、Story详细规格章节
- ✅ **每个Story有验收标准章节**: 检查独立文件中每个Story（### Story编号章节）是否包含"#### 3.2 验收标准"
- ✅ **验收标准至少1条BDD格式AC**: 检查AC字段是否包含 Given/When/Then 结构
- ✅ **PRD索引章节标注独立文件路径**: 检查PRD第十一章表格是否包含"独立文件路径"列
- ✅ **Story编号全局唯一**: 检查Story清单表格中编号无重复
- ✅ **独立文件Frontmatter完整**: 检查story_doc_id、source_prd、current_version、project_name字段存在

### SHOULD级约束（违规提示但不阻断）

- ✅ NFR Story应从非功能需求拆分
- ✅ Story粒度符合INVEST原则（不得包含整个流程）
- ✅ 关联设计路径标注完整（包含PRD章节编号和设计文档路径）

---

## 输出骨架

> **说明**: Story要素生成两类输出物：<br>
> 1. PRD文档索引章节（仅表格清单，标注独立文件引用）<br>
> 2. 独立Story文件（与PRD同级目录，包含完整5个子要素）

---

### 骨架1：PRD文档章节（写入PRD文档第十一章）

```markdown
## 十一、Story 设计

### 11.1 Story 清单

| Story 编号 | Story 名称 | Story 类型 | 来源子特性编号 | 优先级 | 独立文件路径 |
|------------|------------|------------|-------------|--------|---------------|
| S-FR-01-01-001-01 | 全量导入标签数据 | Functional | FR-01-01-001 | P0 | Story-{project_name}-{date}.md#S-FR-01-01-001-01 |

> **说明**: Story详细内容（描述、验收标准、关联设计）请查看独立Story文件 `Story-{project_name}-{date}.md`
```

---

### 骨架2：独立Story文件（新建文件）

**文件路径生成规则**:
- 目录: 与PRD文档同级（如 `workspace/design/I20260423/`）
- 文件名: 替换PRD文件名中的"PRD"为"Story"
- 完整路径示例: `workspace/design/I20260423/Story-项目名称-20260423.md`

**文件结构模板**:
```markdown
---
story_doc_id: "Story-{project_name}-{date}"
source_prd: "PRD-{project_name}-{date}.md"
current_version: "{current_version}"
project_name: "{project_name}"
created_date: "{YYYY-MM-DD}"
total_stories: "{数量}"
functional_count: "{数量}"
nfr_count: "{数量}"
---

# Story 设计文档 - {project_name}

> **版本**: {current_version}
> **项目**: {project_name}
> **来源PRD**: PRD-{project_name}-{date}.md
> **创建日期**: {YYYY-MM-DD}

---

## 一、Story清单

| Story 编号 | Story 名称 | Story 类型 | 来源子特性编号 | 优先级 |
|------------|------------|------------|-------------|--------|
| S-FR-01-01-001-01 | 全量导入标签数据 | Functional | FR-01-01-001 | P0 |

---

## 二、Story概述

| Story 编号 | Story 名称 | Story 类型 | 来源章节引用 |
|------------|------------|------------|-------------|
| S-FR-01-01-001-01 | 全量导入标签数据 | Functional | 第五章 5.2功能特性清单 |

---

## 三、Story详细规格

### Story编号 Story名称

#### 3.1 Story描述
As a <Role>（作为...角色）
I want to <Action>（我希望...）
So that <Value>（以便于...）

#### 3.2 验收标准

- AC1: Given [前提条件] / When [触发动作] / Then [预期结果]
- AC2: Given [前提条件] / When [触发动作] / Then [预期结果]

#### 3.3 关联详细设计

| 关联PRD章节 | 章节编号 | 设计文档路径 |
|------------|---------|-------------|
| 功能特性-子特性详细描述 | FR-01-01-001 | PRD文档第五章 5.2节 |
| 信息架构-实体详情 | E-xxx | PRD文档第四章 4.3节 |
| 集成设计-API接口 | INT-xxx | PRD文档第七章 7.2节 |


...

---

（重复上述结构，每个Story一个三级标题）
```

**说明**: 
- 骨架1仅生成PRD索引章节，符合Spec结构要求
- 骨架2定义独立Story文件的完整结构，包含Spec要求的全部5个子要素
- 独立文件使用"一、二、三"章节编号，与PRD文档区分
- 每个Story在独立文件中使用三级标题（### Story编号），包含三个四级子章节（描述、验收标准、关联详细设计）

---

### incremental 模式

按 PRD 增量高阶方案 V3.0 第九章七步流程中的"Step 7: Story 全局收口"环节执行。

**前置说明**:
story-design 是 **全局收口型要素**,不参与 Step 6 的要素循环。
仅在 **Step 7(Phase 2.5)** 单独处理,所有其他要素的 ImpactPoint 收齐后再执行。
本要素是 **always_affected 要素**,每次 incremental 必执行(无论是否有变化点直接触达)。

**输出策略(基于 Q2 用户决策方案 A)**:
- 新版本目录下生成**全新独立 Story 文件**,只含本次新增/合并的 Story
- 文件路径:`workspace/design/{new_version}/Story-{project_name}-{new_date}.md`
- 基线 Story 文件保留在 `{base_version}/Story-*.md` 不变

#### 输入(由 orchestration 传入)

- `context.base_doc_path`: 基线 PRD 文档路径(只读)
- `context.output_doc_path`: 新版本 PRD 文档路径(本次输出)
- `context.fe_doc_path`: 新版本 FE 文档路径(可选,可能为空字符串)
- `context.fe_doc_available`: bool,新版本 FE 是否存在
- `context.impact_analysis.requirement_register`: RR 列表(整次增量共享)
- `context.impact_analysis.triggered_changes`: AtomicChange 运行时实例列表
- `context.impact_analysis.impact_points`: **所有要素累积的 ImpactPoint 全集**(Phase 2.5 输入)
- `context.story_output_path`: 新版本独立 Story 文件路径(Phase 2.5 输出)

#### Step I-1: 收集 Story 拆分锚点 `[自动]`

扫描所有 ImpactPoint:

**Functional 锚点**:
- 从 element=feature-spec 的 IP 中提取受影响的 FR 编号
- 每个 FR 编号作为 1 个 Functional 锚点

**NFR 锚点**:
- 从 element=nfr 的 IP 中提取 NFR 子条目(如"性能-响应时间-1秒")
- 每个 NFR 子条目作为 1 个 NFR 锚点

**默认规则**:每个锚点产出 1 个 Story。

#### Step I-2: 应用合并规则 `[自动]`

对所有锚点做合并判定,满足**任一**条件即合并:

| 合并模式 | 触发条件 | merge_info.pattern |
|---------|---------|-------------------|
| **merged-by-same-change** | 同一原子变化点跨多 FR,且修改是"对同一规则/字段的同步生效" | "merged-by-same-change" |
| **merged-by-same-anchor** | 多个原子变化点收敛到同一 FR/NFR | "merged-by-same-anchor" |
| **merged-by-shared-ac** | 一组 BDD AC 同时验证多 FR/NFR 的变更,且 AC 不可拆 | "merged-by-shared-ac" |

**合并约束(不可合并的情况)**:
- Functional Story 与 NFR Story 必须分开(验收方式不同)
- 涉及不同业务领域的变更必须分开
- 跨完全不同的角色时必须分开

#### Step I-3: 编号与追溯链填充 `[自动]`

**编号规则**:
- Functional Story: `S-FR-{特性分类}-{特性}-{序号}-{Story序号}`
  - 与 FR 编号 1:1 对应时:`S-FR-01-01-001-01`
  - 合并多个 FR 时:用第一个 FR 作为编号锚点
- NFR Story: `S-NFR-{NFR章节号}-{Story序号}`
  - 例如:`S-NFR-10-1-01`(性能要求-第1条 Story)

**追溯字段必填(每个 Story)**:

```yaml
source_requirements:  ["RR-01", "RR-02"]    # 哪些原始需求催生本 Story
source_changes:       ["UI-03", "DA-02"]    # 哪些原子变化点
source_anchors:       ["FR-01-01-001"]      # 哪些 FR/NFR
source_impact_points: ["IP-001", "IP-005"]  # 哪些影响点
```

**合并 Story 必填 merge_info**:

```yaml
merge_info:
  pattern:   "merged-by-same-change"
  rationale: "LG-02 把审批阈值改为 10 万,FR-01-01-001 和 FR-02-01-001 都需同步生效,AC 共享,故合并"
```

#### Step I-4: Story 数据结构填充 `[自动]`

按 V3.0 §4.4 填充每个 Story 的完整数据结构:

```yaml
Story:
  id:                   "S-FR-01-01-001-01"
  name:                 "Story 名称"
  story_type:           "Functional | NFR"
  
  # 追溯链(必填)
  source_requirements:  ["RR-01"]
  source_changes:       ["UI-03", "DA-02"]
  source_anchors:       ["FR-01-01-001"]
  source_impact_points: ["IP-001", "IP-005"]
  
  # 合并标记(仅合并 Story)
  merge_info:
    pattern:   "merged-by-same-anchor"
    rationale: "合并理由说明"
  
  # Story 描述
  description:
    role:    "作为 [角色]"
    action:  "我希望 [做什么]"
    value:   "以便 [达到什么目的]"
  
  # 验收标准(BDD 格式)
  acceptance_criteria:
    - id:       "AC-1"
      type:     "功能验证 | 数据验证 | 权限验证 | 集成验证 | 边界验证 | 性能验证 | 安全验证"
      given:    "前置条件"
      when:     "触发动作"
      then:     "期望结果(必须可机器断言)"
      negative: "反例(可空)"
  
  # 关联设计
  related_design:
    - "PRD §3.2 PAGE-001 采购申请表单"
    - "PRD §4.3 E-001 PurchaseOrder.supplier_code"
```

**`then` 写法要求**:
- ✅ 正确:"页面显示字段`供应商名称`,值与实体 Supplier.name 一致"
- ❌ 错误:"界面展示正确"(无法断言)

#### Step I-5: 双文件写入 `[自动]`

**文件1: PRD 第十一章索引**(DELTA 格式):

```markdown
<!-- DELTA: change=always_affected, chapter=story-design, op=add, level=certain -->
| Story 编号 | Story 名称 | 类型 | 合并模式 | 来源 RR | 来源 FR/NFR | 独立文件路径 |
|---|---|---|---|---|---|---|
| S-FR-01-01-001-01 | 采购申请增加优先级字段 | Functional | merged-by-same-anchor | RR-01 | FR-01-01-001 | Story-采购系统-20260509.md |
<!-- /DELTA -->
```

**文件2: 独立 Story 文件**(全新文件):

```markdown
---
story_doc_id: "Story-{project_name}-{date}"
source_prd: "PRD-{project_name}-{date}.md"
total_stories: N
functional_count: N1
nfr_count: N2
---

# 增量 Story 设计 - {project_name}

## 一、Story 清单
(完整表格)

## 二、Story 概述
(按类型分组的概述表)

## 三、Story 详细规格
### S-FR-01-01-001-01 采购申请增加优先级字段
(完整数据结构 §4.4 填充)

### S-FR-01-02-002-01 ...
```

#### Step I-6: 用户最终确认 `[交互]`

展示本次新增的 Story 清单,询问"Story 拆分是否合理?",**重点确认**:

1. 合并规则是否正确应用
2. 追溯链是否完整(4条追溯字段均填)
3. AC 是否可机器断言

强制获得明确确认后才能完成 Phase 2.5。

#### ImpactPoint 模板(always_affected 类型)

```yaml
- id: "IP-story-design-001"
  source_requirement: ""                # always_affected 时为空
  source_change: "always_affected"      # 固定值
  trigger_type: "primary"
  cascade_rule: ""
  element: "story-design"
  baseline_ref: "基线 PRD §11 Story 索引"
  baseline_state: "基线 Story 文件:{base_version}/Story-*.md"
  action: "新增"
  target_state: "新版本独立 Story 文件:{new_version}/Story-*.md(仅含本次新增 Story)"
  target_state_evidence: "baseline_prd"
  in_scope: ["§11 Story 索引追加 DELTA 块", "独立 Story 文件新建"]
  out_of_scope: ["基线 Story 文件"]
  out_of_scope_reason: "基线 Story 文件保留不变,本次仅新增独立文件"
```