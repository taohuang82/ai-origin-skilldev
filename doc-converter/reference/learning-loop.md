# 学习闭环：findings 与 overrides 持久化

> 本文档定义转换/审计经验的持久化机制，使技能"越用越准"。审计流程见 [workflows/audit.md](../workflows/audit.md)。

## 设计理念

每次批量转换都会遇到重复的模式——某模板文档的封面页特征、某团队的批注习惯、某格式的表格错位规律。将这些发现持久化，下次同类文档自动套用规则，避免重复人工干预。

## 目录结构

```
{output_dir}/_audit/memory/
├── findings.json      # 自动发现的模式规则
├── overrides.json     # 人工 override 记录
└── .cache.json        # 增量转换缓存（指纹）
```

> `memory/` 目录可跨项目复用：将某项目的 `findings.json` 复制到新项目的 `_audit/memory/` 即可继承经验。

---

## findings.json

自动从审计结果中提取的高频问题模式。

```json
{
  "version": "1.0",
  "last_updated": "2026-08-06",
  "findings": [
    {
      "id": "F-001",
      "pattern": "华为模板封面页",
      "signature": "版权所有.*华为技术有限公司",
      "rule_type": "denoise",
      "rule": "delete_block_until_目录",
      "confidence": 0.98,
      "occurrences": 6,
      "first_seen": "2026-07-15",
      "last_seen": "2026-08-06",
      "applies_to": ["docx", "pptx"]
    },
    {
      "id": "F-002",
      "pattern": "环境定义表对勾截图",
      "signature": "图片类型=√对勾截图",
      "rule_type": "denoise_image",
      "rule": "delete_image_block",
      "confidence": 0.95,
      "occurrences": 12,
      "first_seen": "2026-07-20",
      "last_seen": "2026-08-06",
      "applies_to": ["pptx"]
    },
    {
      "id": "F-003",
      "pattern": "docling 表格偏移",
      "signature": "backend=docling AND table_alignment_rate<0.9",
      "rule_type": "backend_override",
      "rule": "prefer_markitdown_for_tables",
      "confidence": 0.85,
      "occurrences": 3,
      "first_seen": "2026-08-01",
      "last_seen": "2026-08-05",
      "applies_to": ["pdf"]
    }
  ]
}
```

### 字段说明

| 字段 | 说明 |
|------|------|
| `pattern` | 人类可读的模式名称 |
| `signature` | 匹配特征（正则或条件表达式） |
| `rule_type` | `denoise`（去噪）/ `denoise_image`（图片去噪）/ `backend_override`（后端偏好） |
| `rule` | 应用规则的动作描述 |
| `confidence` | 置信度 0-1，≥0.9 自动应用，0.7-0.9 标记建议，<0.7 不应用 |
| `occurrences` | 出现次数，用于排序和置信度提升 |
| `applies_to` | 适用的文件格式 |

---

## overrides.json

人工干预记录，优先级高于 findings。

```json
{
  "version": "1.0",
  "last_updated": "2026-08-06",
  "overrides": [
    {
      "id": "O-001",
      "file_pattern": "供应链设计方案*.pptx",
      "override_type": "keep_image",
      "target": "IMG-042",
      "reason": "业务架构图，虽有装饰风格但含核心信息",
      "applied_by": "user",
      "applied_at": "2026-08-06"
    },
    {
      "id": "O-002",
      "file_pattern": "*财务*",
      "override_type": "force_backend",
      "target": "docling",
      "reason": "财务报表表格密集，docling 表格还原更优",
      "applied_by": "user",
      "applied_at": "2026-08-05"
    }
  ]
}
```

---

## 闭环流程

```
┌─────────────────────────────────────────────────────┐
│  L1: 加载 findings.json + overrides.json            │
│       → 预应用已知规则（预标记噪声、预设后端偏好）    │
├─────────────────────────────────────────────────────┤
│  L2: 多后端锦标赛转换                                │
│       → backend_override 影响 backends 参数          │
├─────────────────────────────────────────────────────┤
│  L3: 独立审计                                        │
│       → 发现新问题模式                                │
├─────────────────────────────────────────────────────┤
│  L4: 去噪清理                                        │
│       → denoise 规则预应用 + 人工 override 尊重      │
├─────────────────────────────────────────────────────┤
│  L5: 提取 findings → 更新 findings.json              │
│       → confidence 随 occurrences 提升               │
│       → 低置信度模式标记"需人工确认"                  │
└─────────────────────────────────────────────────────┘
```

### findings 提取规则

L5 阶段从 audit.json 中提取：

1. **高频去噪模式**：同一噪声特征出现 ≥ 3 次 → 生成 finding
2. **后端偏好模式**：某后端在某类文件上持续得分最高（≥ 3 次） → 生成 backend_override finding
3. **图片类型新增**：审计发现的新装饰性图片类型 → 加入黑名单候选

### 置信度提升

```python
def update_confidence(finding):
    # 每出现一次，置信度提升
    finding["occurrences"] += 1
    base = 0.5
    finding["confidence"] = min(0.99, base + 0.1 * finding["occurrences"])
    # 超过 0.9 自动应用
    if finding["confidence"] >= 0.9:
        finding["auto_apply"] = True
```

---

## 跨项目复用

| 场景 | 操作 |
|------|------|
| 新项目继承经验 | 复制旧项目 `memory/findings.json` 到新项目 |
| 团队共享 | 将 `memory/` 纳入版本控制，团队共享 findings |
| 规则回滚 | 删除某条 finding 或将其 confidence 降至 0.7 以下 |
| 规则审计 | 定期人工 review findings.json，删除误判规则 |
