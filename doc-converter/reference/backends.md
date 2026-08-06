# 多后端锦标赛配置

> 本文档定义多后端并行转换、归一化、评分选优的策略。转换流程见 [workflows/convert.md](../workflows/convert.md)。

## 设计理念

传统做法是选定单一后端"赌运气"。但真实文档差异巨大——no single backend wins every document。本技能采用**锦标赛**模式：

1. 对每个文件并行跑多个后端
2. 归一化各后端输出为统一结构
3. 按结构质量打分
4. 对分数接近的 top-2，用 LLM judge 审嫌疑窗口
5. promote 一个 winner

## 后端选型

| 后端 | 格式支持 | 优势 | 劣势 | 适用场景 |
|------|---------|------|------|---------|
| **MarkItDown** | PDF/DOCX/PPTX/XLSX/HTML/图片/音频 | 速度快、格式广、微软维护 | 复杂表格还原弱 | 通用首选、快速通道 |
| **Docling** | PDF/DOCX/PPTX/HTML/图片 | DocLayNet 版面分析、TableFormer 表格识别、本地可跑 | 速度较慢 | 复杂版面 PDF、表格密集 |
| **marker** | PDF | 深度学习版面还原、OCR | 仅 PDF | 扫描 PDF、学术 PDF |
| **pandoc** | DOCX/HTML/EPUB等 | 结构化文档保真高 | 无图片提取 | 纯文本文档 |
| **openpyxl(原生)** | XLSX | 单元格结构精确、公式值双取 | 仅表格 | Excel 数据表 |
| **Azure Doc Intel** | PDF/图片/Office | 云端高保真 OCR、布局还原 | 需 API key、有成本 | 扫描件、复杂 PDF |

### 按文件类型的默认后端组合

| 文件类型 | 推荐后端组合 | 说明 |
|---------|-------------|------|
| PPTX | markitdown + docling | markitdown 快，docling 表格还原好 |
| DOCX | markitdown + pandoc | 结构化文档，两路交叉验证 |
| XLSX | markitdown + openpyxl | 单元格结构 + 公式值双取 |
| PDF（数字版） | docling + marker | 复杂版面用 AI 后端 |
| PDF（扫描版） | marker + Azure Doc Intel | OCR 场景 |

> 可通过 `backends` 参数自定义参选后端。

---

## 归一化规则

各后端输出差异大，需归一化为统一 Markdown 结构后再评分：

| 维度 | 归一化规则 |
|------|-----------|
| 标题层级 | 统一为 `#`~`######`，基于源文档样式名或字号推断 |
| 表格 | 统一为 GFM 表格（`\|` 分隔），合并单元格用文字说明 |
| 图片引用 | 统一为 `![描述](images/{stem}_p{page}_{seq}.png)` |
| 列表 | 统一为 `- `（无序）或 `1.` （有序），保留缩进 |
| 代码块 | 统一为 ` ```lang ` 围栏 |
| 空白 | 连续空行压缩为 1 个 |

---

## 评分指标

对每个候选后端输出按以下指标打分（满分 100），详见 [audit-metrics.md](audit-metrics.md)：

| 指标 | 满分 | 自动可计算 |
|------|------|-----------|
| 结构保真度 | 25 | 是（标题层级、表格对齐率、列表缩进） |
| 完整性 | 30 | 是（内容块覆盖率、图片描述完整率） |
| 格式规范度 | 20 | 是（GFM 合规、空白规范） |
| 信号密度 | 25 | 是（有效内容/总 token 比） |

> 此处评分为**自动结构分**，用于锦标赛初筛。L3 独立审计阶段会做更全面的人工级评估。

---

## LLM Judge 嫌疑窗口审计

对分数差 ≤ 5 分的 top-2 候选，启动 LLM judge 做源保真审计。

### 嫌疑窗口定位

不全文送审，仅定位嫌疑窗口（控成本）：

1. **表格错位**：两候选在表格区域输出行数/列数不一致 → 定位该表格
2. **标题断裂**：标题层级推断不一致 → 定位该标题段
3. **内容差异**：同一源位置两候选输出 token 数差异 > 20% → 定位该段
4. **图片描述缺失**：一候选有图片描述、另一候选无 → 定位该图片块

### LLM 审计提示词

```
你是文档转换质量审计专家。以下是对同一源文档段落的两个转换候选，
请判断哪个更忠实于源文档。

## 源文档段落（原文）
{source_segment}

## 候选 A
{candidate_a}

## 候选 B
{candidate_b}

## 审计维度
1. 内容完整性：是否遗漏源文档信息
2. 结构保真：标题/表格/列表结构是否准确
3. 语义正确：是否有乱码、错位、语义错误

## 输出
{"winner": "A"|"B"|"tie", "reason": "...", "confidence": 0.0-1.0}
```

### 成本控制

- 仅 top-2 且分差 ≤ 5 时触发 LLM judge
- 仅审嫌疑窗口（通常 < 500 token），非全文
- 单文件 LLM judge 调用上限：3 个窗口
- 置信度 ≥ 0.8 的判定直接采信；< 0.8 标记为"需人工复核"

---

## 降级策略

| 情况 | 处理 |
|------|------|
| 某后端失败/超时 | 降级为单后端模式，记录到 exceptions |
| 所有后端均失败 | 标记文件为"转换失败"，保留原始提取文本 |
| LLM judge 不可用 | 直接取自动分最高的候选 |
| 单后端模式（`backends` 仅指定1个） | 跳过锦标赛，直接使用该后端 |

---

## 后端执行伪代码

```python
def tournament_convert(file_path, backends, source_dir, output_dir):
    # 1. 并行转换
    candidates = {}
    for backend in backends:
        try:
            result = run_backend(backend, file_path, output_dir)
            candidates[backend] = normalize(result)
        except Exception as e:
            log(f"{backend} failed: {e}")

    if len(candidates) == 0:
        return fallback_raw_extract(file_path)
    if len(candidates) == 1:
        return list(candidates.values())[0]

    # 2. 自动评分
    scores = {name: score(c) for name, c in candidates.items()}
    ranked = sorted(scores.items(), key=lambda x: -x[1])

    # 3. top-2 分差小 → LLM judge
    if len(ranked) >= 2 and (ranked[0][1] - ranked[1][1]) <= 5:
        winner = llm_judge(file_path, ranked[0], ranked[1])
    else:
        winner = ranked[0][0]

    return candidates[winner], winner, scores
```
