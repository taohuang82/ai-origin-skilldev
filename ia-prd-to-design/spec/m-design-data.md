---
module_id: "m-design-data"
implements: "data-model"
for_scenario: ["专题需求", "优化需求"]
for_type: ["TP", "AP", "AI"]
execution_mode: ["build", "modify", "incremental"]
status: "active"
---

# m-design-data — 数据与存储模型

> **一句话说明**：在 `data.md` 中给出表结构、索引、ER、缓存策略与实体状态机；条文与模板见本包 `design-data` 各分段。

---

## 目标

**目标说明**

将 PRD 业务对象落实为：**物理模型**（PG、审计字段、逻辑外键）、**访问模式与缓存一致性**（Redis）、**有状态实体转移**（stateDiagram + 领域事件）。

**输出物**

- DDL 段落、变更概要、表清单、ER、mermaid state、缓存 Key 矩阵。

**成功标准**

- 每张表可追溯 PRD 实体编号锚点（见 data-table 模板约定）；枚举与字典引用位明确；缓存与状态机不出现无依据的 TTL/转移弧。

---

## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|---------------------|------|
| — | 无强制前置要素；以 PRD「业务对象/实体」为上下文基线。 |

**必要输入**

- PRD「信息架构 → 业务对象/实体」表；如涉及字典与错误码，`config.md` 对应章节。

---

## 约束

### 格式规范

| standard_id | 规范说明 |
|-------------|---------|
| `design-data` | `data-*` 三要素合并条文与模板 |
| `er-diagram` | （可选）Mermaid ER 画图约束，与内置注册表对齐 |

### 设计约束

| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|----------|
| `DC-DATA-001` | `MUST` | 企业命名、审计六项、无主键 FK、布尔 flag 与设计规范一致 | SQL Review |
| `DC-DATA-002` | `MUST` | 缓存 Key/TTL/一致性策略与条文一致或说明例外 | checklist |
| `DC-DATA-003` | `MUST_NOT` | 仅输出数据模型设计说明，禁止直接输出可执行具体代码（含完整方法体、脚本、SQL） | Review |

---

## 要素映射

| 子要素目录 | 说明 |
|------------|------|
| `data-table` | 表/字段/索引/注释逻辑删除/IT §4.3 摘录 |
| `data-cache` | Redis Key、数据结构、TTL、旁路写入、击穿穿透雪崩 |
| `data-state-machine` | 状态枚举、迁移、领域事件（与缓存节 2.3 对齐处取并集） |

---

## 执行步骤

1. **`[自动]`**：实体→表映射与 ER。
2. **`[自动]`**：每张表 DDL 段落与增量标注。
3. **`[自动]`**：按需输出缓存 Key 清单与状态机。
4. **`[交互]`**：与用户确认兼容性（存量表改动）。

### incremental 模式

**Step 1:** `[自动]` 读取 `context.base_doc_path`（基线 data.md），定位受影响的表/缓存/状态机章节，
提取 baseline_state。

**Step 2:** `[自动]` 对 `context.element_changes` 中每个变化点，生成 DELTA 块和 DIP，遵循以下
要素特有约束：

| 子域 | 增量核心动作 | 强制边界约束 |
|------|------------|------------|
| 物理表设计 | 新增/调整表、字段、索引 | **主键/外键禁止修改**；新增字段必须 nullable 或有默认值 |
| 缓存设计 | 新增/调整缓存 Key；invalidation 策略 | **既有 Key 命名规则禁止修改** |
| 实体流转关系 | 新增/调整状态节点和流转条件 | **既有状态枚举值禁止修改** |

**Step 3:** `[自动]` 每条 DIP 的 compatibility_note 须说明与存量数据的兼容策略
（如"新字段均为 nullable 且默认 null，历史数据不补填"）。

**Step 4:** `[交互]` 与用户确认兼容性（存量表改动影响范围、索引策略等）。

**boundary_constraints 模板**（物理表示例）：

```yaml
boundary_constraints:
  - target: "{表名}.{主键字段}"
    reason: "数据库主键，线上数据依赖"
    consequence: "主键变更导致外键引用断裂、全系统数据不一致"
    evidence: "基线 data.md §{章节}"
  - target: "{表名} 现有字段（{字段列表}）"
    reason: "已上线字段，存量代码依赖"
    consequence: "修改现有字段类型/长度将导致存量代码和查询失败"
    evidence: "基线 data.md §{章节}"
```

---

## 输出骨架

```markdown
## {章节} 数据与存储

### 变更概要
### 表清单
### 实体关系图
### 表详细设计
### （可选）缓存设计
### （可选）状态机 / 实体流转
```
