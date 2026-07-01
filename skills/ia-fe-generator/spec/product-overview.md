---
implements: "ProductOverview"
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]
status: "active"
dual_input_mode: false
standards_refs: []
---
# 产品总览
> 单实例。FE 阶段确立产品定位与范围边界（架构图/LDM 留 PRD 阶段补）。

## 目标 / 输出物 / 成功标准
- 目标：一句话讲清产品定位，划清做什么/不做什么。
- 输出物（stage_increments.FE）：positioning、scope{included[],excluded[]}。
- 成功标准：范围 included/excluded 明确且经用户确认。

## 前置·依赖要素
| via_element | via_relation | direction | read_purpose | required |
|---|---|---|---|---|
| （无） | — | — | 读原始需求上下文（同文档） | — |

## 约束
### 格式规范
| standard_id | 说明 |
|---|---|
| （无） | — |
### 设计约束
| 编号 | 级别 | 规则 | 验证方法 |
|---|---|---|---|
| PO-1 | MUST | 单实例：全文档仅一个产品总览 | 唯一性校验 |
| PO-2 | MUST | FE 阶段只产 positioning/scope，禁产架构图（留 PRD） | 字段范围校验 |
| PO-3 | SHOULD | scope.excluded 明确列出不做的部分 | 非空建议 |

## 执行步骤
### build
**Step 1** `[自动]` 据原始需求提炼 positioning（一句话定位）。
**Step 2** `[交互]` 与用户确认 scope 的 included/excluded 边界（哪些做、哪些明确不做）。
### incremental
status: planned

## 质量检查点
- [ ] 仅一个产品总览实例
- [ ] 仅含 positioning/scope（无架构图）
- [ ] scope 边界已确认

## 输出骨架
## 产品总览
- **产品定位**：{positioning}
- **范围（做）**：{scope.included}
- **范围（不做）**：{scope.excluded}
