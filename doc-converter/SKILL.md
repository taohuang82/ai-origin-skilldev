---
name: iscit-doc-converter
description: 将设计文档（PPTX/DOCX/XLSX/PDF）批量转换为 LLM 可读的结构化 Markdown，自动去噪、多后端锦标赛选优、独立质量审计。仅当用户显式要求批量转换/清理/审计设计文档时触发，不用于普通文件读取或单文件查看。
triggers:
  - 批量转换设计文档
  - Office文档转Markdown
  - 设计文档去噪清理
  - 文档转换质量审计
---

# Office 设计文档转换与质量审计技能

## Pilot 协作

standalone 直驱，不经 Pilot 协议分发。产物为结构化 Markdown + JSON 映射，供下游知识库构建（`iscit-klBuild-init`）或需求分析消费。

## When to Use

| 场景 | 触发方式 |
|------|---------|
| 批量转换设计文档为 Markdown | `/iscit-doc-converter` 或用户提及"批量转换设计文档" |
| 清理已转换 MD 中的无效信息 | 用户提及"文档去噪"、"装饰性图片清理" |
| 评估转换质量 | 用户提及"转换质量审计"、"文档转换评估" |

> **不触发**：普通单文件读取、非设计文档的格式转换、纯讨论。仅处理显式的批量设计文档场景。

## Inputs

| 参数 | 必填 | 说明 | 默认值 |
|------|------|------|--------|
| `source_dir` | 是 | 源文件目录路径 | — |
| `output_dir` | 否 | 输出目录 | `{source_dir}md/` |
| `parallel_count` | 否 | 并行 SubAgent 数量 | `6` |
| `cleanup_mode` | 否 | 是否执行无效信息清理 | `true` |
| `audit_mode` | 否 | 是否执行独立审计 | `true` |
| `incremental` | 否 | 是否启用增量缓存（仅重转改动文件） | `true` |
| `backends` | 否 | 参选后端，逗号分隔 | `markitdown,docling,marker` |

## Workflow 概览

完整流程分五层（L1→L5），各层详细步骤见 `workflows/` 下对应文档。

| 层级 | 阶段 | 核心动作 | 详细文档 |
|------|------|---------|---------|
| **L1** | 扫描准备 | 扫描分组、增量缓存检查、目录准备 | [workflows/convert.md](workflows/convert.md) |
| **L2** | 并行转换 | 多后端锦标赛选优、5维图片描述、JSON映射 | [workflows/convert.md](workflows/convert.md) |
| **L3** | 独立审计 | 第三方质量审计、指标打分、问题修复 | [workflows/audit.md](workflows/audit.md) |
| **L4** | 去噪清理 | 两轮无效信息识别与清理 | [workflows/cleanup.md](workflows/cleanup.md) |
| **L5** | 最终评估 | 质量评级、转换说明报告、findings 持久化 | [workflows/audit.md](workflows/audit.md) |

## Checkpoints

- **L1 完成后**：输出源文件清单与格式分布，无需确认即进入 L2
- **L2 完成后**：输出转换统计报告，进入 L3 审计
- **L3 完成后**：输出质量审计报告，如有问题则进入 L4 清理
- **L4 完成后**：输出清理统计与最终质量评级

## Outputs

| 产物 | 路径 | 说明 |
|------|------|------|
| Markdown 文件 | `{output_dir}/*.md` | 结构化 Markdown（含5维图片描述） |
| JSON 映射文件 | `{output_dir}/*_映射数据.json` | 内容追踪映射（源位置↔MD位置） |
| 图片文件 | `{output_dir}/images/` | 提取的图片 |
| 审计报告 | `{output_dir}/_audit/audit.json` | 每文件一条结构化审计记录 |
| 转换说明报告 | `{output_dir}/_audit/转换说明报告.md` | 转换过程汇总 |

## 进阶能力

以下能力通过渐进明细方式，按需查阅对应参考文档：

| 能力 | 说明 | 参考文档 |
|------|------|---------|
| 多后端锦标赛 | 并行跑多转换引擎，评分选优，LLM judge 审嫌疑窗口 | [reference/backends.md](reference/backends.md) |
| 设计文档去噪规则 | Word/PPT/Excel/PDF 专用去噪规则字典 | [reference/denoise-rules.md](reference/denoise-rules.md) |
| 质量审计指标 | 结构保真度/完整性/噪声残留率量化指标 | [reference/audit-metrics.md](reference/audit-metrics.md) |
| 图片分类与描述 | 5维描述格式 + 图表/时序图多模态还原 | [reference/image-taxonomy.md](reference/image-taxonomy.md) |
| 增量转换缓存 | 基于 mtime+hash 的差分，仅重转改动文件 | [workflows/convert.md](workflows/convert.md#l1-1-增量缓存检查) |
| 学习闭环 | findings/overrides 持久化，越用越准 | [reference/learning-loop.md](reference/learning-loop.md) |
| RAG 友好分块 | 语义边界切分，保留标题路径 | [reference/chunk-strategy.md](reference/chunk-strategy.md) |

## SubAgent 任务模板

转换、审计、清理三个阶段的 SubAgent 任务描述模板：

| 模板 | 用途 | 路径 |
|------|------|------|
| 转换模板 | L2 并行多模态转换 | [templates/subagent-convert.md](templates/subagent-convert.md) |
| 审计模板 | L3 独立第三方审计 | [templates/subagent-audit.md](templates/subagent-audit.md) |
| 清理模板 | L4 无效信息清理 | [templates/subagent-cleanup.md](templates/subagent-cleanup.md) |

## 衔接

清理后的 MD 文件可直接用于 `iscit-klBuild-init` 构建业务知识库。质量门禁要求评级 ≥ 良好（75分）、业务内容保护满分、无占位符残留。
