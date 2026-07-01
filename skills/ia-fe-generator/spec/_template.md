---
implements: "{Element}"                    # 大驼峰，= element-type-registry.element_type
for_type: ["TP","AP","AI","IT"]
execution_mode: ["build"]                  # 0→1 只填 build；1→n 的 incremental 段占位 planned
status: "active"
dual_input_mode: false
standards_refs: []
---
# {name_cn}
> {一句话核心产出与价值}

## 目标 / 输出物 / 成功标准
- 目标：{要素要解决什么}
- 输出物：{本要素产出的 schema 字段}
- 成功标准：{字段齐、关系单端、无占位}

## 前置·依赖要素        # upstream（关系驱动，seq 引用 relations.yaml）
| via_element | via_relation(name,seq) | direction | read_purpose | required |
|---|---|---|---|---|

## 约束
### 格式规范   | standard_id | 说明 |
### 设计约束   | 编号 | 级别 | 规则 | 验证方法 |
- 关系铁律：关系只落**单端**（源侧），关系字段名严格用 relations.source_property；禁写反向；链式可推不冗余。

## 执行步骤
### build
**Step 1** `[自动/交互]` …            # 产 schema 中 stage_increments.{阶段} 的字段
### incremental
status: planned                        # 阶段三

## 质量检查点
- [ ] 字段顺序 = schema.fields
- [ ] 关系字段名 ∈ relations.source_property（单端）
- [ ] 无占位符

## 输出骨架            # 节名=name_cn，字段序=schema.fields
