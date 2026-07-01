---
name: ia-fe-generator
description: >-
  Generate a structured FE design document (功能说明书) element-by-element from a raw
  requirement, by dispatching one subAgent per design element through the shared
  element-runner engine. Use this whenever the user wants to produce, draft, write, or
  update an FE / 功能说明书 / 功能设计文档, turn a raw requirement or 需求 into a
  structured design doc, or start the FE stage of the iSupplyAI element-driven design
  pipeline — even if they do not explicitly say "FE". Also use when the user provides a
  requirement document or describes a feature and asks for a formal functional spec.
---

# ia-fe-generator

> 从原始需求逐要素生成结构化 FE（功能说明书）。所有要素经共享 element-runner 以 subAgent 形式执行；本文件只负责启动与全局约束，执行细节在 spec/，调度在 orchestration/。

## 全局执行约束

- **所有要素统一经 element-runner（subAgent 模板）执行**：主 agent（orchestration）只做调度、依赖门、写 frontmatter、汇总；不预读 spec/standards，不代写正文。
- **单一输出文档**：本 Skill 全程只有一个 FE 输出文档；每个要素的正文由其 subAgent 追加写入对应节，禁止另建中间文档。
- **状态单写者**：只有主 agent 写输出文档 frontmatter（stepsCompleted / status 等）；subAgent 禁写 frontmatter。
- **【铁律】禁止一次性生成整份 FE**：本 Skill 是逐要素、分回合推进的。每个标注需交互的要素，生成后【必须停止本次回复、向用户提问、等用户确认后才能继续下一要素】。任何情况下不得把多个交互要素或整份文档一次性写完。
- **交互是一等公民（依赖门）**：要素间有依赖，前序要素未与用户确认清楚，禁止放行其下游要素。过程中逐要素停下确认（element-runner 的交互硬规则），且**末尾始终有一次整体汇总确认**。此规则即便在没有"主/子 agent 派发"能力的运行环境下也必须生效（靠"生成到交互点就结束本次回复"落地）。
- **面向要素**：要素身份/关系/schema 以 registry 中的 shared 元模型为准；禁止臆造要素或章节。

## 启动序列

1. 模型激活后，读取 `config.yaml`（获取引擎、注册表、路径挂载）。
2. 启动 `engine/workflow-engine.md`：探测输入（input-type-registry）→ 匹配 workflow（workflow-registry）→ 分发到对应 `orchestration/o-*.md`。
3. 之后一切交由 orchestration 调度、element-runner 执行，本文件不再介入。

## 文档导入原则（FE 特有）

- FE 支持双源输入（dual_input）：既可从用户上传的原始需求文档抽取，也可从对话逐步澄清。二者以原始需求要素（OriginalRequirement）为落点。
- 若用户仅给一句话需求，走对话澄清；若给了需求文档，先抽取再澄清缺口。

## 完成提示模板

```
✅ FE（功能说明书）已生成：{output_path}
   已生成要素：{stepsCompleted 列表}
   下一步：可交由 ia-fe-to-prd 生成 PRD，或运行 ia-asset-mgmt 抽取入资产库。
```
