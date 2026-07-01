---
module_id: "m-prd-config"
implements: "config-design"
for_scenario: ["专题需求"]
for_type: ["TP", "AP"]
execution_mode: ["build", "incremental"]
status: "active"
extend_ref: "extend:config-design"
---

# m-prd-config — 配置设计

> 从 FE 业务规则中识别"可配置项"（如审批金额阈值、通知模板），区分用户配置项和 IT 管理配置项，形成配置清单。

---

## 目标

**目标说明**

配置设计将"硬编码规则"提取为"可配置参数"，使系统更灵活。分为两类：用户配置项（业务人员可调整）和 IT 管理配置项（运维人员调整）。

**输出物**

- 用户配置项表格（配置项编号 | 配置项名称 | 配置类型 | 默认值 | 配置说明）
- IT 管理配置项表格（配置项编号 | 配置项名称 | 配置类型 | 默认值 | 运维说明）

**成功标准**

- 配置项列表与 FE 业务规则中提到的可配置项一一对应，无遗漏
- 每个配置项有明确的默认值和说明

---

## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|----------------------|------|
| `feature-spec` | 功能特性的业务规则是识别配置项的主要来源 |

**必要输入**

- PRD 已完成功能特性章节（含业务规则列表）

> **跳过条件**：若业务规则中无可配置项，本要素标记为 SKIP。本要素为 optional。

---

## 约束

### 格式规范

| standard_id | 规范说明 |
|-------------|---------|
| —（暂无格式规范引用） | |

### 设计约束

| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|---------|
| `DC-CFG-001` | `MUST` | 用户配置项和 IT 管理配置项必须明确区分，不得混在同一表格 | 检查是否有两个独立表格 |
| `DC-CFG-002` | `MUST` | 每个配置项必须有默认值，禁止空填 | 检查默认值列是否有空单元格 |
| `DC-CFG-003` | `SHOULD` | 配置项说明应包含配置范围约束（如"整数，范围 1-1000"） | 检查配置说明列是否包含范围约束 |

---

## 执行步骤

**Step 1：从功能特性业务规则中识别可配置项** `[自动]`

遍历功能特性章节的业务规则列表，识别包含以下特征的规则：
- 数值阈值（如"金额 > 5000 时"）
- 时间阈值（如"审批超时 72 小时后"）
- 开关类规则（如"是否启用二次确认"）
- 模板类规则（如"通知消息模板"）

---

**Step 2：区分用户配置项和 IT 管理配置项，并与用户确认** `[交互]`

将识别出的可配置项初步分类，用户配置项由业务人员管理，IT 管理配置项由运维人员管理。

> **交互提示**：展示分类后的配置项列表，询问用户："以上配置项分类是否正确？是否有遗漏的配置项或需要调整分类的项？请同时确认每项的默认值。"

---

## 输出骨架

```markdown
## 八、配置设计

### 8.1 用户配置项

| 配置项编号 | 配置项名称 | 配置类型 | 默认值 | 配置说明 |
|------------|------------|----------|--------|---------|

### 8.2 IT 管理配置项

| 配置项编号 | 配置项名称 | 配置类型 | 默认值 | 运维说明 |
|------------|------------|----------|--------|---------|
```

---

## 输出格式

### incremental 模式

按 PRD 增量高阶方案 V3.0 第九章七步流程执行。

**前置说明**:
config-design(配置设计)仅在 LG-02 涉及"参数化"时 conditional 触发(如阈值/开关需要可配置)。
**90% 场景为 SKIP**。

#### 输入(由 orchestration 传入)

- `context.base_doc_path`: 基线 PRD 文档路径(只读)
- `context.output_doc_path`: 新版本 PRD 文档路径(本次输出)
- `context.fe_doc_path`: 新版本 FE 文档路径(可选,可能为空字符串)
- `context.fe_doc_available`: bool,新版本 FE 是否存在
- `context.impact_analysis.requirement_register`: RR 列表(整次增量共享)
- `context.impact_analysis.triggered_changes`: AtomicChange 运行时实例列表
- `context.impact_analysis.element_changes`: 本要素相关的变化点列表

#### Step I-1 ~ I-2: (同通用模板)

合并两个来源:
1. **普通触发条目**:从 `context.impact_analysis.element_changes` 提取 element_id == 当前要素的项
2. **always_affected 虚拟条目**:仅当本要素 always_affected_in 含 "incremental" 时(本要素不命中)

若合并后列表为空 → 跳过本要素(Phase 6 仅记录 SKIP)。

#### Step I-3: 对话挖掘变化细节 `[交互]`

追问 condition 验证:
> "本次 LG-02 涉及的逻辑是否需要可配置?
> [Y] 需要可配置(本要素纳入增量)
> [N] 硬编码即可(本要素 SKIP)"

#### Step I-4 ~ I-5: (同通用模板)

DELTA 块内容组织:
- 配置项清单追加:新增配置项行(配置项编号/名称/类型/默认值/可选值范围/说明)

ImpactPoint 示例(以 LG-02 参数化为例):

```yaml
- id: "IP-config-design-001"
  source_requirement: "RR-02"
  source_change: "LG-02"
  trigger_type: "primary"
  element: "config-design"
  baseline_ref: "基线 PRD §9 配置设计(5 个配置项)"
  baseline_state: "审批阈值=50000(硬编码在代码中)"
  action: "新增"
  target_state: "新增配置项 CFG-Approval-Threshold:审批阈值(int,默认50000,可选值10000~1000000,步长10000)"
  target_state_evidence: "dialog"
  in_scope: ["§9 配置项清单追加 CFG-Approval-Threshold 行"]
  out_of_scope: ["既有 5 个配置项"]
  out_of_scope_reason: "本次仅新增审批阈值配置项,既有配置项不变"
```

#### 逐变化点追问聚焦点

| 变化点 | 追问聚焦点 | conditional 触发条件 |
|--------|----------|---------------------|
| **LG-02 功能逻辑调整(参数化)** | 哪个阈值/开关需要可配置?默认值?可选值范围? | 用户在 Step I-3 选 Y |

#### Step I-6: 用户最终确认 `[交互]`

展示本要素的 DELTA 块和 ImpactPoint 清单,询问"本要素的增量是否准确?",**重点确认**:

1. in_scope / out_of_scope 划分准确性
2. 配置项编号沿用是否正确

强制获得明确确认后才能进入 Phase 5。
