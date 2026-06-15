# 设计续接恢复 编排文件
# workflow_id: design-resume
# 对应 workflow-registry 中 id: design-resume

## 前置说明
本编排文件由 workflow-engine 在命中 design-resume 后调用。
在存在未完成设计文档（status == "in_progress"）时，从断点处续接要素执行。
实际要素内容生成完全交由 element-runner 执行，本文件只控制宏观流程。

## ⚠️ 多文件输出约定
本编排执行期间，每个要素对应 config.yaml → design_artifacts 中声明的主交付文件。
所有要素执行结果由 element-runner Phase 6 写入对应的输出文档。

---

## 强制读取

1. 本 Skill 根目录 `config.yaml`（含 `design_artifacts` 文件名映射）
2. 本 Skill `SKILL.md` 中 **路径约定**
3. `workspace/ongoing.md`
4. `registry/element-type-registry.yaml`（动态读取 chapter_info）
5. `engine/element-runner.md`（调用规范）
6. `spec/m-design-summary-merge.md`（全部要素完成后的特性级 `design.md` 汇总）

---

## Phase 0：续接状态恢复

1. 解析路径变量（定义见 SKILL.md 路径约定）：`VERSION`、`FEATURE_SUBDIR`、`DESIGN_DIR`。
2. 扫描 `{DESIGN_DIR}` 下设计交付文件的 frontmatter，找到 `status == "in_progress"` 的文档。
3. 从 frontmatter 还原 `stepsCompleted`、`last_element`，确定断点位置。
4. 恢复原始上下文（`PROJECT_TYPE`、`CHANGE_SCOPE`、`execution_profile`），优先从交付文件 frontmatter 读取，补充从 `workspace/ongoing.md` 获取。

---

## Phase 1：重建 effective_sequence

1. 从 `registry/element-type-registry.yaml` 动态读取全量要素，按原始上下文过滤（`belongs_to`、MODE、CHANGE_SCOPE 规则与 o-design-new-build Phase 1 一致）。
2. 排除 `stepsCompleted` 中已完成的要素，得到待续接序列。
3. 文件名绑定从 `config.yaml` → `design_artifacts` 动态读取。

---

## Phase 2：要素执行循环

对续接序列中每个 `element_id`：

FOR EACH element IN resumed_sequence:
  1. 从 element-type-registry 动态读取 chapter_info：
     chapter_info = {
       l1_no: element.chapter_no_cn,
       element_name: element.name,
       sub_elements: element.sub_elements,
       backend_only: element.backend_only,
       chapter_label_style: element.chapter_label_style
     }
  2. 设置 context.output_doc_path = {DESIGN_DIR}/{config.design_artifacts[element_id]}
  3. 调用 element-runner(element_id, execution_mode="build", context)
  4. 处理返回信号（C/B/S/Q/SKIP）
  5. 该要素会话结束前须按 spec/m-design-summary-merge.md 产出汇总输入结构块

---

## Phase 2A：汇总生成 `{DESIGN_DIR}/design.md`

在所有要素均已成功结束后：

1. 按 `spec/m-design-summary-merge.md` 收集各要素的汇总输入，写入 `{DESIGN_DIR}/design.md`。
2. 若门禁失败，按该 spec 暂停策略处理。

---

## Phase 2B：US 与设计交付物索引关联（条件执行）

1. 若 `{DESIGN_DIR}/story.md` 不存在，跳过。
2. 若存在，按 `spec/m-us-design-linkback.md` 将设计索引写回各 US。

---

## Phase 3：完成收尾

1. 跨要素全局一致性检查。
2. 更新 `workspace/ongoing.md` 中的状态。
3. 输出 SKILL.md 中定义的完成提示模板。
