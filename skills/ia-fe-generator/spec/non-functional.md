---
implements: "NonFunctional"
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]
status: "active"
dual_input_mode: false
standards_refs: []
---
# 非功能
> DFX 诉求（性能/安全/可靠等）。FE 阶段确立类别/作用对象/诉求（指标留 PRD、方案留 TDD）。

## 目标 / 输出物 / 成功标准
- 目标：识别非功能诉求，明确作用于哪些子特性/页面。
- 输出物（stage_increments.FE）：category[DFX 11类]、applies_to[]、fe_requirement。
- 成功标准：category 准确、applies_to 引用有效、诉求可度量化（PRD 补指标）。

## 前置·依赖要素
| via_element | via_relation(name,seq) | direction | read_purpose | required |
|---|---|---|---|---|
| SubFeature | uses, 35 | forward | 读子特性/页面，填 applies_to（非功能作用于谁） | true |

## 约束
### 格式规范
| standard_id | 说明 |
|---|---|
| （无） | — |
### 设计约束
| 编号 | 级别 | 规则 | 验证方法 |
|---|---|---|---|
| NF-1 | MUST | category ∈ {performance,security,reliability,availability,usability,maintainability,scalability,compatibility,resilience,i18n,telemetry} | 枚举校验 |
| NF-2 | MUST | applies_to ∈ 已存在 SubFeature 或 Page（非空） | 上游存在性校验 |
| NF-3 | MUST | FE 阶段只产 category/applies_to/fe_requirement（指标 prd_design 留 PRD、方案 tdd_implementation 留 TDD） | 字段范围校验 |

## 执行步骤
### build
**Step 1** `[自动]` 读 upstream_payload 的 SubFeature/Page 清单。
**Step 2** `[交互]` 与用户确认非功能诉求：类别、作用对象、FE 诉求描述。
### incremental
status: planned

## 质量检查点
- [ ] category ∈ 枚举
- [ ] applies_to ∈ SubFeature/Page 且非空
- [ ] 仅产 FE 字段范围
- [ ] 关系字段名 = relations.source_property（applies_to）
- [ ] 无占位符

## 输出骨架
## 非功能
| 类别 | 作用于 | FE 诉求 |
|---|---|---|
| {category} | {applies_to} | {fe_requirement} |
