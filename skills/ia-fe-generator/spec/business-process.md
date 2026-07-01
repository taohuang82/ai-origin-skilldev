---
implements: "BusinessProcess"
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]
status: "active"
dual_input_mode: false
standards_refs: ["standards/business-process.md"]
---
# 业务流程
> 用活动序列 + Mermaid 流程图刻画端到端业务流转，引用角色与规则。

## 目标 / 输出物 / 成功标准
- 目标：刻画业务的活动序列与流转，明确每步谁做、受何规则约束。
- 输出物：involves_domains（多域，软）、activities[]{activity_id,name,role,inputs,outputs,rules,exceptions}、flow_diagram_mermaid。
- 成功标准：活动序列完整、角色/规则引用有效、流程图与活动一致。

## 前置·依赖要素
| via_element | via_relation(name,seq) | direction | read_purpose | required |
|---|---|---|---|---|
| （无） | — | — | 业务流程先行：读原始需求梳理流程；角色/规则在活动中先以名称提及，随后由 Role/BusinessRule 要素从本流程抽取固化 | — |

## 约束
### 格式规范
| standard_id | 说明 |
|---|---|
| mermaid-flowchart | 业务流程图 Mermaid flowchart TD 画法与校验（standards/business-process.md） |
### 设计约束
| 编号 | 级别 | 规则 | 验证方法 |
|---|---|---|---|
| BP-1 | MUST | flow_diagram_mermaid 必填且为合法 flowchart TD，节点/连线非空 | 空内容检查 + 语法 |
| BP-2 | MUST | activities[].role / activities[].rules 为流程中出现的角色名/规则点（后续 Role/BusinessRule 要素据此识别）；关系字段单端存于本要素 | 关系单端检查 |
| BP-3 | MUST | 流程图节点与 activities 一致，无遗漏活动 | 一致性校验 |

## 执行步骤
### build
> 业务分析起点：先梳理端到端业务流程，流程的活动里自然带出"角色名"与"规则点"，供后续 Role / BusinessRule 要素识别与详化。
**Step 1** `[自动]` 读 OriginalRequirement / ProductOverview 上下文，识别端到端业务流程。
**Step 2** `[交互]` 与用户确认活动序列（每步 name / 执行角色名 / 输入输出 / 约束点 / 异常）。角色名与约束点此处以"名称/描述"形式出现，后续由 Role/BusinessRule 要素详化。
**Step 3** `[自动]` 据活动序列生成 flow_diagram_mermaid（flowchart TD），逐活动完整覆盖，禁截断。
### incremental
status: planned

## 质量检查点
- [ ] flow_diagram_mermaid 非空、合法、节点=活动
- [ ] activities[].role ∈ Role；activities[].rules ∈ BusinessRule（单端引用）
- [ ] 关系字段名 = relations.source_property
- [ ] 遍历活动完整无截断
- [ ] 无占位符

## 输出骨架
## 业务流程
- **涉及领域**：{involves_domains}
### 活动序列
| # | 活动 | 执行角色 | 输入 | 输出 | 约束规则 | 异常 |
|---|---|---|---|---|---|---|
| {activity_id} | {name} | {role} | {inputs} | {outputs} | {rules} | {exceptions} |
### 流程图
```mermaid
{flow_diagram_mermaid}
```
