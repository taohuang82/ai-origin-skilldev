# 设计评审修改 编排文件
# workflow_id: design-review-modify
# 对应 workflow-registry 中 id: design-review-modify

## 前置说明
本编排文件由 workflow-engine 在命中 design-review-modify 后调用。
在用户提供评审意见的前提下，对既有设计文件做定向修改。
实际要素内容生成完全交由 element-runner 执行，本文件只控制宏观流程。

## ⚠️ 多文件输出约定
本编排执行期间，修改对象为 config.yaml → design_artifacts 中声明的已有交付文件。
所有修改由 element-runner Phase 6 写入对应的输出文档。

---

## 强制读取

1. `config.yaml`（含 `design_artifacts` 文件名映射）
2. 本 Skill `SKILL.md` 路径约定
3. `registry/element-type-registry.yaml`（动态读取 chapter_info）
4. `engine/element-runner.md` modify 模式约定
5. `spec/m-design-summary-merge.md`（多文件变更后刷新特性级 `design.md` 摘要引用时使用）

---

## Phase 1：定位修改范围

1. 解析评审意见 → 映射到一个或多个 `element_id`（及目标文件）。
2. 为每个 `element_id` 设置：
   - `context.output_doc_path`（从 `config.yaml` → `design_artifacts` 读取文件名）
   - `context.modify_focus`（章节、表格名或要点列表）
3. 从 `registry/element-type-registry.yaml` 动态读取各受影响要素的 chapter_info。

---

## Phase 2：按要素调用 runner

对每个受影响要素：

FOR EACH element IN affected_elements:
  1. 从 element-type-registry 动态读取 chapter_info：
     chapter_info = {
       l1_no: element.chapter_no_cn,
       element_name: element.name,
       sub_elements: element.sub_elements,
       backend_only: element.backend_only,
       chapter_label_style: element.chapter_label_style
     }
  2. 调用 element-runner(element_id, execution_mode="modify", context)
  3. 遵守 Phase 6 对目标文件的写入与 frontmatter 更新。

---

## Phase 3：刷新汇总与 Story

若改动跨多文件：

- **特性级 `design.md`**：若本次修改影响跨域可追溯性或既有 `{DESIGN_DIR}/design.md` 与各交付文件不一致风险，在要素级 modify 全部完成后，按 `spec/m-design-summary-merge.md` 更新 `{DESIGN_DIR}/design.md`（须重新收集或补齐受影响要素的汇总输入后再合并）。
- **US 同步（条件执行）**：若 `{DESIGN_DIR}/story.md` 存在且本次修改可能影响 US 对设计交付物的可追溯性，在 `design.md` 已与交付事实一致后，按 `spec/m-us-design-linkback.md` 更新各 US 的「设计引用」；若无 `story.md` 则跳过。
