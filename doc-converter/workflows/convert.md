# 转换主流程（L1 扫描准备 + L2 并行转换）

> 本文档详细描述 L1-L2 阶段的执行步骤。前置概览见 [SKILL.md](../SKILL.md)。

## L1-0 源文件扫描与分组

**目标**：扫描源目录，识别文件格式，按格式分组，分配唯一 ID。

**步骤**：

1. 扫描 `source_dir` 下所有文件，按扩展名分类：PPTX / DOCX / XLSX / PDF / JPG/PNG
2. 为每个文件分配唯一 ID（基于文件名 stem），用于全流程追踪
3. 生成源文件清单：

```
源文件统计：
- PPTX: 85 个
- XLSX: 40 个
- DOCX: 4 个
- PDF: 4 个
- JPG: 1 个
总计: 134 个文件
```

**产出**：源文件清单（格式、数量、文件大小）。

---

## L1-1 增量缓存检查

**目标**：识别哪些文件自上次转换后已变更，仅重转改动文件，避免全量重复转换。

> 增量缓存的引入可大幅降低设计文档频繁修订场景下的转换成本。

**缓存机制**：

1. 读取 `{output_dir}/_audit/.cache.json`（如不存在则视为首次全量转换）
2. 对每个源文件计算指纹：`sha256(文件内容前64KB) + mtime + 文件大小`
3. 与缓存记录比对，分类：

| 状态 | 处理 | 说明 |
|------|------|------|
| **unchanged** | 跳过转换，复用旧产物 | 指纹完全一致 |
| **changed** | 重新转换 | mtime 或大小变化 |
| **new** | 转换 | 缓存中无记录 |
| **deleted** | 清理旧产物 | 源文件已删除 |

4. 输出增量报告：

```
增量转换分析：
- 新增: 3 个文件
- 变更: 12 个文件
- 未变: 119 个文件（跳过）
- 删除: 1 个文件（清理旧产物）
本次需转换: 15 个文件
```

**缓存写入**：转换完成后更新 `.cache.json`，记录每个文件的新指纹。

> **首次运行或 `incremental=false`** 时跳过此步，全量转换。

---

## L1-2 输出目录准备

**目标**：创建输出目录结构。

1. 创建 `output_dir`（如不存在）
2. 创建 `output_dir/images/` 子目录（存放提取的图片）
3. 创建 `output_dir/_audit/` 子目录（存放审计报告）
4. 验证目录可写权限

---

## L2-0 并行多模态转换（核心步骤）

**目标**：使用并行 SubAgent 将每个需转换的文件转为结构化 Markdown + JSON 映射。

### 并发策略

- 默认启动 `parallel_count` 个并行 SubAgent（默认 6）
- 按文件大小 round-robin 分配，确保负载均衡
- 大文件（>100页）拆分为每 50 页一批，降并发至 2-3

### Round-Robin 分组

```python
def distribute_files_round_robin(files, group_count=6):
    """按文件大小降序后 round-robin 分配到 N 组"""
    sorted_files = sorted(files, key=lambda f: os.path.getsize(f), reverse=True)
    groups = [[] for _ in range(group_count)]
    for i, file in enumerate(sorted_files):
        groups[i % group_count].append(file)
    return groups
```

### 多后端锦标赛选优（P0-1）

> 传统做法是选定单一后端"赌运气"。本技能对每个文件并行跑多个后端，归一化后评分选最优。详见 [reference/backends.md](../reference/backends.md)。

**流程**：

1. **并行转换**：对每个文件，用 `backends` 参数指定的后端（默认 `markitdown,docling,marker`）各转一次
2. **归一化**：将各后端输出统一为标准 Markdown 结构（标题层级、表格格式、图片引用）
3. **结构质量打分**：按 [reference/audit-metrics.md](../reference/audit-metrics.md) 的指标对每个候选打分
4. **LLM judge 嫌疑窗口**：仅对分数接近的 top-2 候选，定位嫌疑窗口（表格错位、标题断裂处），交 LLM 做源保真审计
5. **选定胜者**：综合结构分 + LLM 审计分，promote 一个 winner

| 文件类型 | 推荐后端组合 | 说明 |
|---------|-------------|------|
| PPTX | markitdown + docling | markitdown 快，docling 表格还原好 |
| DOCX | markitdown + pandoc | 结构化文档，两路交叉验证 |
| XLSX | markitdown + 原生 openpyxl | 单元格结构 + 公式值双取 |
| PDF | docling + marker | 复杂版面用 AI 后端 |
| 扫描 PDF | marker + Azure Doc Intel | OCR 场景 |

> **降级策略**：若某后端失败或超时，自动降级为单后端模式，记录到 exceptions。

### SubAgent 任务

使用 [templates/subagent-convert.md](../templates/subagent-convert.md) 模板启动转换 SubAgent。

### 图片处理

- 提取所有图片到 `images/` 目录，命名 `{source_stem}_p{page}_{seq}.png`
- 对每张图片生成 5 维结构化描述块（格式见 [reference/image-taxonomy.md](../reference/image-taxonomy.md)）
- SmartArt/组合形状使用 WPS 渲染提取（捕获 API 遗漏的图片）
- **图表/时序图专项**：架构图、时序图调用多模态 LLM 还原为 Mermaid 或结构化文字描述（见 [reference/image-taxonomy.md](../reference/image-taxonomy.md#图表与时序图多模态还原)）

### JSON 映射文件

每文件生成 `{filename}_映射数据.json`，记录源位置↔MD位置映射：

```json
{
  "file_info": {
    "source_filename": "原始文件名.pptx",
    "source_format": "pptx",
    "page_count": 45,
    "image_count": 18,
    "table_count": 12,
    "word_count": 5234,
    "backend_winner": "docling",
    "backend_score": 92
  },
  "content_mapping": [
    {
      "md_location": "第15-18行",
      "source_location": "第3页幻灯片",
      "content_summary": "系统架构图及说明",
      "source_type": "image",
      "action": "extracted",
      "remark": "5维描述完成"
    }
  ],
  "template_removed": [],
  "exceptions": []
}
```

### 质量控制

- 每张图片必须有完整的 5 维描述
- 不允许出现 `[待SubAgent补充]` 占位符
- JSON 映射必须覆盖所有内容块
- 表格必须保留在原文上下文中（不 detach 到末尾）

### 保守原则

- 不确定是否为业务内容时，保留
- 宁可漏删不可误删
- 记录所有异常情况到 `exceptions` 字段

**产出**：N 个 Markdown 文件 + N 个 JSON 映射文件 + M 个图片文件。

---

## L2-1 转换完整性检查

**目标**：验证所有文件转换完成，无遗漏。

1. 检查每个源文件是否都有对应的 `.md` 和 `_映射数据.json`
2. 检查所有图片引用是否都有对应文件
3. 检查是否有 `[待SubAgent补充]` 占位符残留
4. 统计转换结果：

```
转换完成统计：
- 源文件: 15 个（本次增量）
- MD文件: 15 个 ✓
- JSON映射: 15 个 ✓
- 图片文件: 483 个
- 图片引用: 478 条
- 孤立图片: 5 个（存在于 images/ 但未被引用）
- 后端分布: docling 9个 / markitdown 4个 / marker 2个
```

**产出**：转换完整性报告。

---

## SubAgent 错误处理

```python
def handle_subagent_failure(subagent_result):
    if subagent_result.status == "failed":
        log_error(subagent_result.error)
        completed_files = subagent_result.completed_files
        remaining_files = subagent_result.assigned_files - completed_files
        if remaining_files:
            retry_subagent(remaining_files)
```

## 性能调优

| 文件规模 | 推荐并发数 | 说明 |
|---------|-----------|------|
| <50 个文件 | 3-4 | 避免过度并发 |
| 50-150 个文件 | 6 | 默认推荐 |
| >150 个文件 | 6-8 | 根据系统资源调整 |
