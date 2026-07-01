---
implements: "Glossary"
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]
status: "active"
dual_input_mode: false
standards_refs: []
---
# 概念术语
> 统一业务术语定义，消除歧义（随处萌芽，emerge_stage=any）。

## 目标 / 输出物 / 成功标准
- 目标：沉淀关键业务术语的统一定义。
- 输出物：definition、aliases(可选)、applies_scope(可选)。
- 成功标准：术语定义无歧义，别名收敛。

## 前置·依赖要素
| via_element | via_relation | direction | read_purpose | required |
|---|---|---|---|---|
| （无） | — | — | 无要素关系（applies_scope 为软关联） | — |

## 约束
### 格式规范
| standard_id | 说明 |
|---|---|
| （无） | — |
### 设计约束
| 编号 | 级别 | 规则 | 验证方法 |
|---|---|---|---|
| GL-1 | MUST | definition 非空且无歧义 | 非空校验 |
| GL-2 | SHOULD | 同义术语通过 aliases 收敛到一条 | 去重检查 |

## 执行步骤
### build
**Step 1** `[自动]` 扫描需求/已产要素，抽取需要统一定义的术语，给出 definition/aliases/applies_scope。
### incremental
status: planned

## 质量检查点
- [ ] definition 非空
- [ ] 别名已收敛
- [ ] 无占位符

## 输出骨架
## 概念术语
| 术语 | 定义 | 别名 | 适用范围 |
|---|---|---|---|
| {name} | {definition} | {aliases} | {applies_scope} |
