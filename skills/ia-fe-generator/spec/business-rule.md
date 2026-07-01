---
implements: "BusinessRule"
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]
status: "active"
dual_input_mode: false
standards_refs: []
---
# 业务规则
> 沉淀准入/路由/计算/校验等业务规则，供业务流程与子特性引用。

## 目标 / 输出物 / 成功标准
- 目标：把散落的业务约束固化为可引用的规则条目。
- 输出物（stage_increments.FE）：domain（领域名，软引用）、rule_type[7类]、description、error_code(可空)、exception_branches[]{condition,action}。
- 成功标准：规则可判定、类型准确、异常分支清晰。

## 前置·依赖要素
| via_element | via_relation(name,seq) | direction | read_purpose | required |
|---|---|---|---|---|
| BusinessProcess | uses, 9 | reverse | 从业务流程活动的约束中抽取并固化业务规则 | true |
| 错误码字典 | uses, 37 | forward | error_code 引用 DICT-ERROR-CODES 条目；FE 阶段通常留空 | false |

## 约束
### 格式规范
| standard_id | 说明 |
|---|---|
| （无） | — |
### 设计约束
| 编号 | 级别 | 规则 | 验证方法 |
|---|---|---|---|
| BR-1 | MUST | rule_type ∈ {准入,路由,计算,校验,时限,权限,额度}规则 | 枚举校验 |
| BR-2 | MUST | domain 为领域名字符串（关系单端，禁在 Domain 侧反存） | 关系单端检查 |
| BR-3 | SHOULD | 有异常路径的规则填 exception_branches | 完整性建议 |

## 执行步骤
### build
**Step 1** `[自动]` 读 upstream_payload（业务流程 activities 中的约束点），识别业务规则候选，逐条给 rule_type + description。
**Step 2** `[交互]` 与用户确认规则清单、类型、异常分支；确认各规则归属领域名（domain）。
**Step 3** `[自动]` error_code 若已知错误码字典条目则引用，否则留空（PRD/TDD 补）。
### incremental
status: planned

## 质量检查点
- [ ] rule_type ∈ 枚举
- [ ] domain 单端（不在 Domain 侧反存）
- [ ] 关系字段名 = relations.source_property（domain / error_code）
- [ ] 无占位符

## 输出骨架
## 业务规则
| 规则 | 领域 | 类型 | 描述 | 错误码 | 异常分支 |
|---|---|---|---|---|---|
| {name} | {domain} | {rule_type} | {description} | {error_code} | {exception_branches} |
