---
implements: "OriginalRequirement"
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]
status: "active"
dual_input_mode: true
standards_refs: []
---
# 原始需求
> 忠实记录业务方原话与来源，判定需求类型，作为整条设计链路的溯源根。

## 目标 / 输出物 / 成功标准
- 目标：把用户的原始诉求结构化为可溯源的 OriginalRequirement 实例。
- 输出物：version、raw_description（原话不加工）、source{raised_by,raised_at,channel}、requirement_type[TP/AP/AI/IT]、triggered_changes（占位）。
- 成功标准：raw_description 为业务方原话（禁改写/摘要）；source 三要素齐；requirement_type 已与用户确认。

## 前置·依赖要素
| via_element | via_relation | direction | read_purpose | required |
|---|---|---|---|---|
| （无） | — | — | 溯源根，无上游 | — |

## 约束
### 格式规范
| standard_id | 说明 |
|---|---|
| （无） | — |
### 设计约束
| 编号 | 级别 | 规则 | 验证方法 |
|---|---|---|---|
| OR-1 | MUST | raw_description 必须是业务方原话，禁改写/摘要 | 与输入逐字比对 |
| OR-2 | MUST | requirement_type ∈ {TP 作业类(OLTP), AP 分析类(OLAP), AI 类, IT 纯技术类}，按需求业务性质判定（与 0→1/1→n 无关） | 枚举 + 含义校验 |
| OR-3 | MUST | source 的 raised_by/raised_at/channel 三要素齐全 | 非空校验 |

## 执行步骤
### build
**Step 1** `[自动]` （dual_input）若有原始需求文档 → 抽取原话；否则取对话原话。填 raw_description（不加工）。
**Step 2** `[交互]` 与用户确认 source 三要素（谁提的/何时/什么渠道）与 requirement_type：**TP 作业类** / **AP 分析类** / **AI 类** / **IT 类**。此为链路首个确认门，务必停下确认。
**Step 3** `[自动]` 组装实例；triggered_changes 置空占位（1→n 时回填）。
### incremental
status: planned

## 质量检查点
- [ ] raw_description = 业务方原话
- [ ] source 三要素齐
- [ ] requirement_type 已确认且 ∈ 枚举
- [ ] 无占位符

## 输出骨架
## 原始需求
- **版本**：{version}
- **原始描述**：{raw_description}
- **来源**：{raised_by} / {raised_at} / {channel}
- **需求类型**：{requirement_type}   <!-- TP 作业类 / AP 分析类 / AI 类 / IT 纯技术类 -->
