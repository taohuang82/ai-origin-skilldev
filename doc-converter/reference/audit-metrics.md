# 质量审计指标体系

> 本文档定义转换质量的量化指标与评分标准。审计流程见 [workflows/audit.md](../workflows/audit.md)。

## 指标定义

### 1. 结构保真度（满分 20）

衡量输出 Markdown 是否忠实还原源文档的结构。

| 子指标 | 计算方式 | 权重 |
|--------|---------|------|
| 标题层级深度 | 输出最大标题层级 vs 源文档层级 | 5 |
| 列表缩进完整性 | 列表项缩进丢失数 / 总列表项 | 5 |
| 表格行列对齐率 | 对齐正确的表格 / 总表格 | 5 |
| 段落顺序一致性 | 段落顺序与源一致的比率 | 5 |

### 2. 完整性（满分 30）

衡量内容是否零丢失。

| 子指标 | 计算方式 | 权重 |
|--------|---------|------|
| 内容块覆盖率 | JSON 映射覆盖的内容块 / 源内容块 | 15 |
| 图片描述完整率 | 5维描述完整的图片 / 总图片 | 10 |
| 占位符残留 | `[待SubAgent补充]` 计数（目标=0） | 5（倒扣） |

### 3. 噪声残留率（满分 30）

衡量去噪效果。

| 子指标 | 计算方式 | 权重 |
|--------|---------|------|
| 装饰性图片残留 | 黑名单图片残留计数 | 8 |
| 封面页残留 | 封面特征文本残留文件数 | 8 |
| 修订/批注残留 | `<w:ins>`/`<w:del>`/批注残留计数 | 8 |
| 模板章节残留 | 模板控制章节残留计数 | 6 |

### 4. 信噪比提升（满分 20）

衡量清理后有效信息密度提升。

| 子指标 | 计算方式 | 权重 |
|--------|---------|------|
| 图片减少率 | (清理前图片-清理后图片)/清理前 | 10 |
| 行数减少率 | (清理前行数-清理后行数)/清理前行数 | 10 |

---

## 评级标准

| 评级 | 分数范围 | 标准 |
|------|---------|------|
| **优秀** | 90-100 | 业务保护满分；清除≥27；结构≥18；信噪比≥17 |
| **良好** | 75-89 | 业务保护≥25；清除≥20；结构≥15；信噪比≥12 |
| **合格** | 60-74 | 业务保护≥20；清除≥15；结构≥12；信噪比≥10 |
| **不合格** | <60 | 任一维度低于最低标准 |

### 质量门禁

知识库构建（`iscit-klBuild-init`）前的最低要求：

- 评级 ≥ 良好（75分）
- 业务内容保护 = 满分（30/30）
- 无效信息清除 ≥ 20分
- 无 `[待SubAgent补充]` 占位符
- 图片引用一致性 = 100%

---

## audit.json 格式

每文件生成一条审计记录，聚合写入 `{output_dir}/_audit/audit.json`：

```json
{
  "audit_version": "2.0",
  "files": [
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
        "list_indent_loss": 2,
        "table_count": 12,
        "table_alignment_rate": 0.95,
        "image_count": 18,
        "image_description_complete": 18,
        "orphan_images": 1,
        "placeholder_residual": 0,
        "noise_annotations": 0,
        "noise_revisions": 0,
        "noise_cover_pages": 0,
        "noise_template_sections": 0,
        "source_tokens_est": 5200,
        "output_tokens": 4800,
        "image_reduction_rate": 0.142,
        "line_reduction_rate": 0.029
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
      "backend_score": 92,
      "backend_candidates": [
        {"name": "docling", "score": 92, "structure": 18},
        {"name": "markitdown", "score": 85, "structure": 16},
        {"name": "marker", "score": 78, "structure": 14}
      ]
    }
  ],
  "summary": {
    "total_files": 15,
    "grade_distribution": {"优秀": 3, "良好": 10, "合格": 2, "不合格": 0},
    "avg_score": 86.2,
    "backend_distribution": {"docling": 9, "markitdown": 4, "marker": 2}
  }
}
```

---

## 质量控制检查清单

### 转换质量

- [ ] 所有源文件都有对应的 MD 和 JSON 文件
- [ ] 所有图片引用都有对应文件
- [ ] 所有图片都有完整的 5 维描述
- [ ] 无 `[待SubAgent补充]` 占位符残留
- [ ] 表格保留在原文上下文中
- [ ] JSON 映射覆盖所有内容块

### 清理质量

- [ ] 装饰性图片 100% 清除
- [ ] 封面页模板 100% 清除
- [ ] 空白/损坏图 100% 清除
- [ ] 修订/批注 100% 清除
- [ ] 业务内容零误删
- [ ] 图片引用一致性 100%
- [ ] JSON 映射完整性 100%
