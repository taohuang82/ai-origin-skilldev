# 审计与评估流程（L3 独立审计 + L5 最终评估）

> 本文档详细描述 L3、L5 阶段的执行步骤。前置概览见 [SKILL.md](../SKILL.md)。

## L3-0 独立质量审计（第三方视角）

**目标**：使用独立 SubAgent 验证转换质量，不依赖转换 SubAgent 的自报告。

> 审计指标体系详见 [reference/audit-metrics.md](../reference/audit-metrics.md)。

### 审计 SubAgent

使用 [templates/subagent-audit.md](../templates/subagent-audit.md) 模板启动独立审计 SubAgent。

### 审计维度

| 维度 | 检查内容 | 指标 |
|------|---------|------|
| **零丢失验证** | 源文件内容 vs JSON 映射 vs MD 内容三方比对 | 内容块覆盖率 |
| **图片完整性** | 图片引用↔文件一致性、5维描述完整度 | 完整率 |
| **表格完整性** | 表格行数列数与源一致、未 detach | 保真率 |
| **结构完整性** | 标题层级、段落顺序、内容错位 | 层级深度 |
| **JSON 映射完整性** | content_mapping 覆盖率、位置准确性 | 覆盖率 |
| **噪声残留率** | 批注/修订/水印/页眉页脚残留计数 | 残留数 |

### audit.json 输出

每文件生成一条结构化审计记录，写入 `{output_dir}/_audit/audit.json`：

```json
{
  "file": "设计方案.pptx",
  "audit_timestamp": "2026-08-06T10:30:00+08:00",
  "scores": {
    "structure_fidelity": 18,
    "completeness": 28,
    "noise_residue": 25,
    "snr_improvement": 16,
    "total": 87,
    "grade": "良好"
  },
  "metrics": {
    "heading_depth": 4,
    "table_count": 12,
    "table_alignment_rate": 0.95,
    "image_count": 18,
    "image_description_complete": 18,
    "orphan_images": 1,
    "placeholder_residual": 0,
    "noise_annotations": 0,
    "noise_revisions": 0,
    "source_tokens_est": 5200,
    "output_tokens": 4800
  },
  "issues": [
    {
      "severity": "low",
      "type": "table_misalign",
      "location": "第45行 表格3",
      "description": "第2列与源文件偏移1行"
    }
  ],
  "backend_used": "docling",
  "backend_score": 92
}
```

> 完整指标定义与评分标准见 [reference/audit-metrics.md](../reference/audit-metrics.md)。

**产出**：独立审计报告（质量评级、问题清单）。

---

## L3-1 审计问题修复

**目标**：修复审计发现的问题。

1. 解析 audit.json，提取问题清单
2. 对每个问题，定位到具体文件和行号
3. 启动修复 SubAgent 处理问题
4. 修复后重新审计验证（仅复查受影响文件）

**产出**：修复报告（修复前后对比）。

---

## L5-0 最终质量评估

**目标**：评估清理后的转换质量，生成最终评级。

### 评分维度

| 维度 | 满分 | 评分标准 |
|------|------|---------|
| **业务内容保护** | 30 | 零误删=30；每误删1处扣5分 |
| **无效信息清除** | 30 | 核心清除=25-30；残留1处扣2分 |
| **文件结构完整性** | 20 | 图片引用/JSON映射完整=18-20 |
| **信噪比提升** | 20 | 图片减少10%+=15-20 |

### 评级标准

| 评级 | 分数范围 | 标准 |
|------|---------|------|
| **优秀** | 90-100 | 业务保护满分；清除≥27；结构≥18；信噪比≥17 |
| **良好** | 75-89 | 业务保护≥25；清除≥20；结构≥15；信噪比≥12 |
| **合格** | 60-74 | 业务保护≥20；清除≥15；结构≥12；信噪比≥10 |
| **不合格** | <60 | 任一维度低于最低标准 |

### 清理前后对比

```
清理前后对比：
- 图片总数: 2,478 → 2,125（减少353张，14.2%）
- 总行数: ~113,000 → 109,742（减少~3,258行，2.9%）
- 封面页残留: 6文件 → 0（100%清除）
- 装饰性图片残留: 127+ → 0（100%清除）
最终评级：良好（88/100）
```

**产出**：最终审计报告（质量评级、详细统计、改进建议）。

---

## L5-1 学习闭环：findings 持久化

**目标**：将本次转换/审计中发现的规律持久化，下次同类文档自动套用规则。

> 详细机制见 [reference/learning-loop.md](../reference/learning-loop.md)。

**步骤**：

1. 从 audit.json 提取高频问题模式（如"某模板文档的封面页特征"）
2. 写入 `{output_dir}/_audit/memory/findings.json`：
   ```json
   {
     "findings": [
       {
         "pattern": "华为模板封面页",
         "signature": "版权所有.*华为技术有限公司",
         "rule": "delete_block_until_目录",
         "confidence": 0.98,
         "occurrences": 6,
         "last_seen": "2026-08-06"
       }
     ]
   }
   ```
3. 从人工 override 记录中提取规则，写入 `overrides.json`
4. 下次转换时自动加载 findings/overrides，预应用去噪规则

---

## L5-2 生成转换说明报告

**目标**：生成汇总报告，说明转换过程和结果。

```markdown
# 文档转换说明报告

## 转换概述
- 源文件数量: 15 个（增量）
- 转换日期: 2026-08-06
- 转换方法: 多后端锦标赛 + 并行SubAgent + 多模态图片描述
- 增量缓存: 命中 119 个，转换 15 个

## 转换产物
- Markdown文件: 15 个
- JSON映射文件: 15 个
- 图片文件: 483 个

## 质量指标
- 图片描述完整率: 100%
- 表格保留率: 100%
- 零丢失验证: 通过
- 后端分布: docling 9 / markitdown 4 / marker 2

## 无效信息清理
- 清理轮次: 2轮
- 装饰性图片删除: 83 张
- 封面页清除: 2 个文件
- 空表格行删除: 178 行
- 最终评级: 良好（88/100）
```

**产出**：转换说明报告（`{output_dir}/_audit/转换说明报告.md`）。
