# RAG 友好分块策略

> 本文档定义转换产物的语义分块策略，使输出直接可用于 RAG 检索。

## 设计目标

转换后的 Markdown 如果作为整篇喂给 RAG，会出现：
- 上下文过长导致检索精度下降
- 跨标题的语义被切碎
- 表格/图片脱离上下文

本策略按**语义边界**切分，保留标题路径，使每个 chunk 自包含可检索。

---

## 分块规则

### 1. 按 H2/H3 标题切分

- 以 `##` 和 `###` 标题为切分点
- 每个 chunk 包含一个 H2/H3 及其下属全部内容（段落、列表、表格、图片描述）
- 不在段落中间切分

### 2. 保留标题路径

每个 chunk 开头注入标题面包屑，确保脱离上下文仍可理解：

```markdown
<!-- chunk_id: doc_001_p15_arch -->
<!-- breadcrumb: 设计方案 / 系统架构 / 数据流设计 -->

## 数据流设计

（正文内容...）
```

### 3. 表格不切分

- 表格作为原子单元，完整保留在所属 chunk 中
- 若表格过大（> 50 行），单独成 chunk，并在前一个 chunk 末尾添加引用指针

### 4. 图片描述块不切分

- 5 维图片描述块（7行）+ Mermaid 还原块作为原子单元
- 不在图片描述中间切分

### 5. Chunk 大小控制

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `target_size` | 512 token | 目标 chunk 大小（token 计） |
| `max_size` | 1024 token | 最大 chunk 大小，超出则按 H4/P 切分 |
| `min_size` | 100 token | 最小 chunk 大小，过小则合并到上一个 |

---

## 元数据注入

每个 chunk 生成对应的元数据，用于 RAG 检索过滤：

```json
{
  "chunk_id": "doc_001_p15_arch",
  "source_file": "设计方案.pptx",
  "source_page": 15,
  "breadcrumb": ["设计方案", "系统架构", "数据流设计"],
  "heading": "数据流设计",
  "chunk_index": 23,
  "total_chunks": 45,
  "token_count": 487,
  "contains_table": true,
  "contains_image": true,
  "image_ids": ["IMG-042"]
}
```

---

## 输出格式

分块后输出两种产物：

### chunks.jsonl（用于向量入库）

每行一个 chunk 的 JSON：

```jsonl
{"chunk_id":"doc_001_p15_arch","text":"<!-- breadcrumb... -->\n## 数据流设计\n...","metadata":{...}}
{"chunk_id":"doc_001_p16_logic","text":"...","metadata":{...}}
```

### 原始 MD 保持不变

原始 `{filename}.md` 不受分块影响，仍为完整文档。分块仅生成额外的 `chunks.jsonl`。

> 分块为可选步骤，通过 `chunk_mode=true` 参数启用。默认不启用，需下游 RAG 系统显式请求。

---

## 与知识库构建衔接

```
doc-converter (chunk_mode=true)
    │
    ├─ *.md              ← 完整文档（人工阅读/审计）
    ├─ *_映射数据.json    ← 溯源映射
    └─ chunks.jsonl      ← RAG 入库（向量检索）
           │
           ▼
    iscit-klBuild-init （构建向量库）
```
