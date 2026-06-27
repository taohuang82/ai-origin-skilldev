# 整体方案概要与方向确认（编排校验）

本文件定义 `overall` 阶段的输入/输出/Prompt 校验规则与跨 workflow 契约，供以下编排调用 `@ia-overall-designer`：
- `o-design-new-build.md`（build 模式, STAGE=direction）
- `o-design-incremental-build.md`（incremental 模式, STAGE=direction / STAGE=change-router）

`@ia-overall-designer` 的内部执行流程、写作规范与状态交互细节，以下沉到 `subagents/ia-overall-designer.md` 为准；本文件不重复定义。

---

## 输入清单

| 变量 | build | incremental (direction) | incremental (change-router) | 校验说明 |
|------|-------|------------------------|-----------------------------|----------|
| `STAGE` | direction | direction | change-router | 仅允许 direction / change-router |
| `PRD_FILE` | 必填 | 必填 | 必填（回退用） | 文件存在且可读 |
| `STORY_FILE` | 可选 | 可选 | 不适用 | 若传入则需可读 |
| `INCR_PRD_FILE` | 不适用 | 可选 | 必填（优先） | 若传入则需可读；未传入可回退 `PRD_FILE` |
| `DESIGN_DIR` | 必填 | 必填 | 必填 | 目录存在且可写 |
| `MODE` | 必填 | 必填 | 必填 | 仅允许 `build` / `incremental` / `modify` |
| `PROJECT_TYPE` | 必填 | 必填 | 必填 | 仅允许 `TP` / `AP` / `AI` |
| `CHANGE_SCOPE` | 必填 | 必填 | 必填 | 仅允许 `frontend` / `backend` / `fullstack` |
| `execution_profile` | 必填 | 必填 | 必填 | 来自 `config.yaml`，字段完整 |
| `shared-context.md` | 不适用 | 必填 | 必填 | 位于 `{DESIGN_DIR}/shared-context.md`，change-router 架构上下文 SSOT |
| `DESIGN_ACCUM_FILE` | 不适用 | 可选 | 不适用 | 若传入则需可读 |

---

## 输入门禁

### 通用门禁（build / incremental）

1. `PRD_FILE` 已存在并可读。
2. `DESIGN_DIR` 已存在且可写。
3. `CHANGE_SCOPE` 与 `execution_profile` 已确定。
4. 若 `CHANGE_SCOPE` 低置信，已完成用户确认。
5. 任何普通 design 域 Subagent 尚未启动。

### incremental 追加门禁

1. `{DESIGN_DIR}/shared-context.md` 已生成并通过结构校验。
2. 技术方案澄清已完成，状态为 `READY_FOR_OVERALL_DESIGN`。
3. `resolution_confidence >= medium`。
4. `CHANGE_SCOPE` 与 `execution_profile` 已冻结并写入编排上下文；同时写入 `shared-context.md` 的 `decision_facts` 或等价小节。

若 `resolution_confidence = low`，禁止启动 `@ia-overall-designer`；必须先补充探索或用户澄清。

---

## Prompt 组装：change-router 模式

> 仅在 `workflow_id=design-incremental-build` 的 Phase 1A 使用。
> ChangeRouter 在方向确认（Stage-A）之前执行，以 `shared-context.md` 为主要架构上下文。

| 变量 | 值 |
|------|-----|
| `STAGE` | `change-router` |
| `WORKFLOW_ID` | `design-incremental-build` |
| `EXECUTION_MODE` | `incremental` |
| `INCR_PRD_FILE` | `{INCR_PRD_FILE}`（或回退 `{PRD_FILE}`） |
| `PRD_FILE` | `{PRD_FILE}`（回退用） |
| `DESIGN_DIR` | `{DESIGN_DIR}` |
| `SKILL_ROOT` | `{SKILL_ROOT}` |
| `SPEC_ROOT` | `{SKILL_ROOT}/spec/` |
| `CHANGE_SCOPE` | `{CHANGE_SCOPE}` |
| `execution_profile` | `{execution_profile}` |
| `SHARED_CONTEXT_FILE` | `{DESIGN_DIR}/shared-context.md`（必读，架构上下文 SSOT） |
| `OVERALL_DESIGN_FILE` | `{DESIGN_DIR}/overall-design.md`（若存在则参考 `arch_decisions`；本阶段通常不存在） |

### change-router 输出校验

1. `{DESIGN_DIR}/overall-design.md` §7 存在且非空
2. 文件内存在 `<!-- ORCH:BEGIN change-router` 注释块
3. ORCH 块内 YAML 可解析且包含以下必填字段：
   - `workflow_id`（必须等于 design-incremental-build）
   - `effective_sequence`（可为空数组；每个条目含 `element_id`、`domain`、`trigger_type`、`target_sub_element_ids`）
   - `status`（必须为 READY_FOR_EXECUTION_PLAN_REVIEW 或 NEEDS_USER_CLARIFICATION）
4. `status == NEEDS_USER_CLARIFICATION` 时，编排须转述澄清问题，不进入 Phase 2
5. `effective_sequence` 每个条目的 `element_id` 必须在 `subagent-registry.yaml` 可解析

---

## 输出清单

| 输出项 | 必填 | 校验说明 |
|--------|------|----------|
| `{DESIGN_DIR}/overall-design.md` | 是 | 文件已生成且非空 |
| `status` | 是 | 本轮确认阶段应为 `NEEDS_USER_CONFIRMATION` |
| 用户确认包 | 是 | 主 Agent 可读、可转述、可用于当前会话确认 |
| `executed_sub_elements[]` | 是 | 返回字段存在（可为空数组） |

---

## 输出门禁（确认前后）

1. 调用后立即校验 `{DESIGN_DIR}/overall-design.md` 已生成。
2. 校验返回状态为 `NEEDS_USER_CONFIRMATION`。
3. 主 Agent 必须在当前会话读取并转述用户确认包，禁止要求用户进入 Subagent 会话查看。
4. 仅当用户明确确认 `overall-design.md` 可作为方向基线后，才允许进入后续 Phase。
5. 若用户提出方向级修改或异议，必须重新调用 `@ia-overall-designer` 覆盖更新输出并再次走确认门禁。

---

## 下游衔接校验

1. `overall` 为 `orchestration-direct` 前置任务，不纳入 `effective_sequence`。
2. 生成普通设计要素序列时，必须排除 `dispatch_via: orchestration-direct` 条目。
3. 后续各 design 域 Subagent 的 Prompt 必须传入 `OVERALL_DESIGN_FILE={DESIGN_DIR}/overall-design.md`。

---

## 跨 workflow overall-design 读写契约

| workflow | 写入章节 | 读取范围 | ChangeRouter |
|----------|----------|----------|--------------|
| design-new-build | §1–§6 (STAGE=direction) | designer 读 §1–§6 | 无 (序列来自 subagent-registry) |
| design-incremental-build | Stage-B: §7 / Stage-A: §1–§6 | Phase 2 读 §7；designer 读 §1–§6 | Stage-B (先于方向确认) |
| design-review-modify | 不写入 | §1–§6 | Review ImpactRouter (非 overall 域) |
| design-resume | 不写入 | 按原 workflow 恢复 | 无 (恢复自 ongoing 或 §7) |

**约束**：
- `EXECUTION_MODE=build` 时，禁止写入 §7 或 ORCH 块
- downstream designer 的 Prompt 必须显式标注 `OVERALL_DESIGN_SCOPE=direction`，禁止令其读取 §7
- `design-review-modify` 即使读取 overall-design.md，也仅消费 `arch_decisions`，不读取 §7
- ORCH 块中 `workflow_id` 与当前不一致时，编排必须警告并忽略
