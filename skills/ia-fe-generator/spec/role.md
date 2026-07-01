---
implements: "Role"
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]
status: "active"
dual_input_mode: false
standards_refs: []
---
# 角色
> 识别系统涉及的角色及其职责边界，供后续业务流程、子特性、权限引用。

## 目标 / 输出物 / 成功标准
- 目标：列全参与角色，界定各自职责边界。
- 输出物：role_category[用户角色/系统角色/外部系统角色]、responsibility_boundary、dynamic_assignment(可选)、delegation_supported(可选)。
- 成功标准：角色清单完整、职责边界互斥清晰。

## 前置·依赖要素
| via_element | via_relation(name,seq) | direction | read_purpose | required |
|---|---|---|---|---|
| BusinessProcess | uses, 8 | reverse | 从业务流程活动的执行者中抽取并固化角色 | true |

## 约束
### 格式规范
| standard_id | 说明 |
|---|---|
| （无） | — |
### 设计约束
| 编号 | 级别 | 规则 | 验证方法 |
|---|---|---|---|
| RO-1 | MUST | role_category ∈ {用户角色,系统角色,外部系统角色} | 枚举校验 |
| RO-2 | MUST | 每个角色 responsibility_boundary 非空且互不重叠 | 边界互斥检查 |

## 执行步骤
### build
**Step 1** `[自动]` 读 upstream_payload（业务流程 activities 中出现的角色名），识别候选角色清单。
**Step 2** `[交互]` 与用户确认角色清单、各自 role_category 与职责边界（是否动态分配/是否支持委托可一并确认）。
### incremental
status: planned

## 质量检查点
- [ ] role_category ∈ 枚举
- [ ] responsibility_boundary 非空、互斥
- [ ] 无占位符

## 输出骨架
## 角色
| 角色 | 类型 | 职责边界 | 动态分配 | 委托 |
|---|---|---|---|---|
| {name} | {role_category} | {responsibility_boundary} | {dynamic_assignment} | {delegation_supported} |
