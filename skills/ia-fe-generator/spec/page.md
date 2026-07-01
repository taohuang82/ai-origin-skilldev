---
implements: "Page"
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]
status: "active"
dual_input_mode: false
standards_refs: ["standards/page.md"]
---
# 页面
> 承载子特性的界面。FE 阶段确立页面类型/路由/实现哪些子特性（字段/组件/API/防呆/流转留 PRD）。

## 目标 / 输出物 / 成功标准
- 目标：识别页面清单，明确每页实现哪些子特性。
- 输出物（stage_increments.FE）：domain(弱,可空)、page_type、route_path、realizes_sub_features[]。
- 成功标准：页面清单覆盖子特性、realizes 引用有效、路由唯一。

## 前置·依赖要素
| via_element | via_relation(name,seq) | direction | read_purpose | required |
|---|---|---|---|---|
| SubFeature | realizes, 28 | forward | 读子特性，填 realizes_sub_features（页面实现哪些子特性） | true |

## 约束
### 格式规范
| standard_id | 说明 |
|---|---|
| page-structure | 页面类型/路由/realizes 结构与校验（standards/page.md） |
### 设计约束
| 编号 | 级别 | 规则 | 验证方法 |
|---|---|---|---|
| PG-1 | MUST | realizes_sub_features ∈ 已存在 SubFeature（非空） | 上游存在性校验 |
| PG-2 | MUST | route_path 唯一 | 唯一性校验 |
| PG-3 | MUST | FE 阶段只产 domain/page_type/route_path/realizes_sub_features，其余（字段/组件/API/防呆/流转）留 PRD | 字段范围校验 |

## 执行步骤
### build
**Step 1** `[自动]` 读 upstream_payload 的 SubFeature 清单。
**Step 2** `[交互]` 与用户确认页面清单：每页类型、路由、实现哪些子特性。前序 SubFeature 未确认清楚则不进行（依赖门）。
### incremental
status: planned

## 质量检查点
- [ ] realizes_sub_features ∈ SubFeature 且非空
- [ ] route_path 唯一
- [ ] 仅产 FE 字段范围
- [ ] 关系字段名 = relations.source_property（realizes_sub_features）
- [ ] 无占位符

## 输出骨架
## 页面
| 页面 | 类型 | 路由 | 实现子特性 |
|---|---|---|---|
| {name} | {page_type} | {route_path} | {realizes_sub_features} |
