---
implements: "SubFeature"
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]
status: "active"
dual_input_mode: false
standards_refs: []
---
# 子特性（业务功能）
> 功能需求的最小承载单元（FR），即一项可交付的**业务功能点**。FE 阶段确立编号/归属特性/业务描述/执行角色（页面/实体操作/AC 留 PRD）。

## 目标 / 输出物 / 成功标准
- 目标：把需求拆为可交付的子特性（FR），明确归属与执行角色。
- 输出物（stage_increments.FE）：fr_code（FR-xxx）、feature（特性名字符串）、business_description、performed_by_roles[]。
- 成功标准：FR 编号唯一、业务描述清晰、执行角色引用有效。

## 前置·依赖要素
| via_element | via_relation(name,seq) | direction | read_purpose | required |
|---|---|---|---|---|
| Role | uses, 11 | forward | 读角色定义，填 performed_by_roles | false |
| Feature | part_of, 3 | forward(软) | feature 填特性名字符串（源侧单端）；Feature 实例 PRD 建后对齐 | false |

## 约束
### 格式规范
| standard_id | 说明 |
|---|---|
| （无） | — |
### 设计约束
| 编号 | 级别 | 规则 | 验证方法 |
|---|---|---|---|
| SF-1 | MUST | fr_code 唯一，格式 FR-xxx | 唯一性 + 格式 |
| SF-2 | MUST | feature 为特性名字符串（关系单端，禁在 Feature 侧反存 sub_features） | 关系单端检查 |
| SF-3 | MUST | performed_by_roles ∈ 已存在 Role | 上游存在性校验 |
| SF-4 | MUST | FE 阶段只产 fr_code/feature/business_description/performed_by_roles，其余（页面/实体操作/AC）留 PRD | 字段范围校验 |

## 执行步骤
### build
**Step 1** `[自动]` 读 upstream_payload 的 Role 定义。
**Step 2** `[交互]` 与用户确认子特性清单：每个 FR 的编号、归属特性名、业务描述、执行角色。
### incremental
status: planned

## 质量检查点
- [ ] fr_code 唯一、格式正确
- [ ] feature 单端（不反存）
- [ ] performed_by_roles ∈ Role
- [ ] 仅产 FE 字段范围
- [ ] 无占位符

## 输出骨架
## 子特性
> 子特性 = **业务功能点**（一个 FR 对应一项可交付的业务功能，便于业务方理解）
| FR 编号 | 归属特性 | 业务描述 | 执行角色 |
|---|---|---|---|
| {fr_code} | {feature} | {business_description} | {performed_by_roles} |
