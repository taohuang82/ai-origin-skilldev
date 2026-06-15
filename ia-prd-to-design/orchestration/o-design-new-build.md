# 从 PRD 新建完整技术设计 编排文件
# workflow_id: design-new-build
# 对应 workflow-registry 中 id: design-new-build

## 前置说明
本编排文件由 workflow-engine 在命中 design-new-build 后调用。
实际要素内容生成完全交由 element-runner 执行，本文件只控制宏观流程。

## ⚠️ 多文件输出约定
本编排执行期间，每个要素对应 config.yaml → design_artifacts 中声明的主交付文件。
所有要素执行结果由 element-runner Phase 6 写入对应的输出文档，不得另建中间文档。

---

## 强制读取

1. 本 Skill 根目录 `config.yaml`（含 `design_artifacts` 文件名映射）
2. 本 Skill `SKILL.md` 中 **路径约定**（`WORKSPACE_ROOT`、`DESIGN_DIR` 等路径变量）
3. `workspace/ongoing.md`
4. `registry/element-type-registry.yaml`（动态读取 chapter_info）
5. `engine/element-runner.md`（调用规范）
6. `spec/m-design-summary-merge.md`（全部要素完成后的特性级 `design.md` 汇总）

---

## 业务判定模型

本编排使用以下三维模型确定有效要素序列：

| 维度 | 取值 | 说明 |
|------|------|------|
| `MODE` | `greenfield` / `new-incremental` / `update` | 与历史版本的关系；`new-incremental` 与 `update` 不生成 `architecture` |
| `PROJECT_TYPE` | `TP` / `AP` / `AI` | 系统/能力类型 |
| `CHANGE_SCOPE` | `frontend` / `backend` / `fullstack` | 本次设计覆盖哪些层 |

禁止把 `PROJECT_TYPE` 当作前后端覆盖范围的代理。`CHANGE_SCOPE` 在进入可靠运行上下文之前不得假定取值。

**工程结构**：默认兼容单工程与 `backend/` + `frontend/` 双工程目录。`CHANGE_SCOPE` 包含 `backend` 时优先检索后端工程上下文；包含 `frontend` 时优先检索前端工程上下文；`fullstack` 时两侧均须检索。

**执行画像**（初始化阶段确定后向下游传递）：

```yaml
execution_profile:
  has_frontend: true | false
  has_backend: true | false
  backend_variant: standard | ap
  enable_ai: false
```

**PROJECT_TYPE 矩阵（后端分支）**

| 项目类型 | 后端实现分支 |
|---------|--------------|
| TP | `backend-designer` |
| AP | `ap-designer` |
| AI | `backend-designer` |

**CHANGE_SCOPE 矩阵（候选链路）**

| 覆盖范围 | 计划阶段默认候选 |
|---------|------------------|
| `frontend` | 仅前端链路；后端链路默认跳过；`config` 保持按需 |
| `backend` | 仅后端链路；前端链路默认跳过；`config` / `integration` 按需 |
| `fullstack` | 前后端链路都可进入；`config` / `integration` 仍按需派发 |

---

## Phase 0：解析上下文

1. 解析路径变量（定义见 SKILL.md 路径约定）：`VERSION`、`FEATURE_SUBDIR`、`DESIGN_DIR`、`PRD_FILE`、`STORY_FILE`。
2. 读取 `PRD_FILE` 校验可作为设计输入；将路径记入 `context.input_doc_path`（主输入为 PRD）。
3. 若 `workflow.resume_mode == true`：
   - 从进行中交付物 frontmatter 还原 `effective_sequence` 与 `stepsCompleted`
   - 自未完成要素继续

---

## Phase 1：生成 effective_sequence

1. 从 `registry/element-type-registry.yaml` 动态读取全量要素，过滤 `belongs_to` 含 `PROJECT_TYPE`（即 `requirement_type`）的要素。
2. **MODE 过滤**：若 `MODE` 为 `new-incremental` 或 `update`，从序列移除 `architecture`。
3. **CHANGE_SCOPE 过滤**：
   - 仅 `backend`：移除 `frontend`
   - 仅 `frontend`：后端链移除需用户在确认序列时拍板（默认保守策略）
4. **可选要素**：`architecture`、`integration`、`config`、`frontend` 标记 optional，按用户选择纳入。
5. 从 element-type-registry 动态读取每个要素的 chapter_info（含 `chapter_no_cn`、`chapter_label_style`、`sub_elements`）。
6. 文件名绑定从 `config.yaml` → `design_artifacts` 动态读取，不硬编码。

---

## Phase 2：要素执行循环

对 `effective_sequence` 中每个 `element_id`：

FOR EACH element IN effective_sequence:
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
  5. 该要素会话结束前须按 spec/m-design-summary-merge.md 产出 `## 汇总输入（供 design.md 合并）` 结构块；编排留存待 Phase 2A 合并

---

## Phase 2A：汇总生成 `{DESIGN_DIR}/design.md`

在 Phase 2 **全部要素**均已成功结束后：

1. **必须严格按** `spec/m-design-summary-merge.md` 收集本轮各要素会话中的汇总输入，执行门禁自检后写入 `{DESIGN_DIR}/design.md`（摘要 + 引用，不冗长复述交付正文）。
2. 若门禁失败（结构块缺失、references 无法定位或与交付文件矛盾），按该 spec 的暂停策略处理，**不得**进入 Phase 2B。

---

## Phase 2B：US 与设计交付物索引关联（条件执行）

在 Phase 2A `design.md` 已成功生成或用户确认跳过后：

1. 若 `{DESIGN_DIR}/story.md` **不存在**，跳过本 Phase。
2. 若存在，**必须严格按** `spec/m-us-design-linkback.md` 执行：将本轮已产出的多文件设计交付物（以 `config.yaml` → `design_artifacts` 为准，含 `design.md`）的可定位索引写回各 US。
3. 执行完成后以该 reference 的完成消息为准（`DONE: story.md design linkback`）。

---

## Phase 3：完成收尾

1. 跨要素全局一致性检查。
2. 更新 `workspace/ongoing.md` 中的状态。
3. 输出 SKILL.md 中定义的完成提示模板。
