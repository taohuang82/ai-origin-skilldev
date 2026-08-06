# SubAgent 任务模板：并行多模态转换

> 本模板用于 L2 阶段启动转换 SubAgent。转换流程见 [workflows/convert.md](../workflows/convert.md)。

---

```
你是文档转换专家。请将以下文件转换为结构化 Markdown 格式。

## 输入文件
{file_list}

## 输出要求

### 1. Markdown 文件（{filename}.md）

#### 文本提取
- 保留原文层级结构（标题、段落、列表）
- 表格转换为 Markdown 表格格式
- 保留表格合并单元格信息（用文字说明）

#### 图片处理（5维描述格式）
对每张提取的图片，生成结构化描述块（格式见 reference/image-taxonomy.md）：

> **【图片说明】**
> - **图片类型**：{原型界面截图|业务流程图|表格截图|系统架构图|数据流图|...}
> - **图片标题**：{图片标题或"无"}
> - **详细描述**：{图片内容的详细文字描述，100-300字}
> - **关键要素清单**：{图中关键元素列举}
> - **流程/逻辑说明**：{业务流程或逻辑关系说明}
> - **源文档位置**：第{N}页幻灯片
> - **图片编号**：IMG-{XXX}

图片引用格式：`![图片IMG-XXX](images/{source_stem}_p{NN}_{MM}.png)`

#### 图表/时序图多模态还原
对架构图、时序图、流程图、ER图等，调用多模态 LLM 还原为 Mermaid 代码块，
嵌入图片引用之后。详见 reference/image-taxonomy.md。

#### 多后端锦标赛
对每个文件，使用指定后端（{backends}）各转一次，归一化后评分选优。
评分指标见 reference/audit-metrics.md，后端配置见 reference/backends.md。
仅对分差≤5的top-2启动LLM judge审嫌疑窗口。

#### 特殊内容处理
- PPT备注：转换为"备注"段落
- SmartArt/图表：提取为图片 + 5维描述 + Mermaid还原
- 合并单元格：用文字说明合并关系
- Word修订：接受所有修订，输出最终态
- Word批注：删除批注标记
- Excel公式：取值，公式记录到JSON映射

### 2. JSON映射文件（{filename}_映射数据.json）

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

### 3. 图片文件
- 提取所有图片到 images/ 目录
- 命名格式：{source_stem}_p{page}_{seq}.png
- 使用WPS渲染提取（捕获SmartArt、组合形状等API遗漏的图片）

## 质量控制
- 每张图片必须有完整的5维描述
- 不允许出现 [待SubAgent补充] 占位符
- JSON映射必须覆盖所有内容块
- 表格必须保留在原文上下文中（不 detach 到末尾）
- Mermaid代码必须语法正确可渲染

## 保守原则
- 不确定是否为业务内容时，保留
- 宁可漏删不可误删
- 记录所有异常情况到 exceptions 字段
```
