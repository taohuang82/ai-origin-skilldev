---
# ── 必填字段 ─────────────────────────────────────────────────
module_id: "{m-design-element-id}"
implements: "{element-id}"
for_type: ["{类型1}"]
execution_mode: ["{mode1}", "{mode2}"]
status: "active"

# ── v1.2.0 必填字段 ──────────────────────────────────────────
for_scenario: ["专题需求", "优化需求"]

# ── 可选字段 ─────────────────────────────────────────────────
extend_ref: "extend:{element-id}"
dual_input_mode: false
---

# {module_id} — {要素名称}

> **域级编排索引（瘦 spec）**：子要素逐步细则在 `spec/{domain}/{id}.md`；规范在 `standards/{domain}/{id}.md`。

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

> 运行时 SSOT：`registry/element-registry.yaml` + `standards/{domain}/{id}.md`

### 设计约束
| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|---------|

---

## 子要素清单

| sub-id | spec | standards | 说明 |
|--------|------|-----------|------|
| `{sub-id}` | `spec/{domain}/{sub-id}.md` | `standards/{domain}/{sub-id}.md` | |

---

## 执行顺序

`{sub-id-1}` → `{sub-id-2}` → …

> 逐步 build/modify 细则在子要素 spec；Subagent Step 0 按本顺序加载。

### incremental 模式

域级 DELTA 边界说明；子要素细则见 `spec/{domain}/{id}.md` 的 `### incremental 模式`。

---

## 完整性检查（域级，optional）

Subagent Step 4（质量自检）以子要素 spec `## 质量检查点` 为准。
