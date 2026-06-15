---
module_id: "m-design-architecture"
implements: "architecture"
for_scenario: ["专题需求", "优化需求"]
for_type: ["TP", "AP", "AI"]
execution_mode: ["build", "modify", "incremental"]
status: "active"
---

# m-design-architecture — 顶层架构

> **一句话说明**：在技术设计 `architecture.md` 中固化技术栈、部署、微服务边界、特性开关及 greenfield 下的代码分层与公共能力；具体条文与模板由本包 `design-architecture` 规范各分段给出，子要素语义见下文「要素映射」。

---

## 目标

**目标说明**

将 PRD/Story 所涉系统形态映射为可追溯的架构条文与章节骨架：**技术选型**与**四层代码/包结构**（及公共库、公共切面）、**部署与 CI/CD**、**微服务划分与治理**、**灰度与特性开关**；条文级细则全部由 `design-architecture` 规范加载，本节只定义要素边界与编排关系。

**输出物**

- greenfield：`architecture.md` 内按 L2 子章节呈现的上述主题（编排传入的章节编号服从 `chapter_info`）。
- 若工作流跳过本要素：`architecture.md` 不写入（仅 `architecture` optional 且不纳入序列时）。
- LLM Phase 执行：按下文「要素 ↔ 源码」表的子要素**完整覆盖**，不得自拟未在 PRD 中印证的拓扑。

**成功标准**

- L2 子章节与下文「要素映射」所列子目录一一对应，无空缺、无改名替代。
- 模式为 greenfield（或等价全量建档）且纳入本要素时，规范中标注「仅 greenfield」的条文须在交付中显式应答或写明「不适用 + 依据」。
- 所有图示与表格字段命名与加载的格式规范一致（Mermaid、`config.md`/`integration.md` 交叉引用占位符合规范原文）。

---

## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|----------------------|------|
| — | 以 PRD/Story 中系统形态与约束为基线；避免无上下文的孤立架构条目。 |
| （可选）`data-model` | 若先于架构写库表，仅以引用关系出现在微服务边界，不互为阻塞 |

**必要输入**

- 生效的 `{DESIGN_DIR}/prd.md`（及按需 `story.md`）含系统类型、部署要求、合规或技术基线陈述。
- 工作流确认 `MODE`、`PROJECT_TYPE`、`CHANGE_SCOPE`；本要素条文与 **`MODE`** 关系见「跳过条件」。

**跳过条件**

- `MODE ∈ {new-incremental, update}`：**不产出**顶层 `architecture.md`（与 SKILL 对齐）；若在修改类工作流仍需引用历史架构条文，仅从 `DESIGN_ACCUM_FILE`/`architecture.md` 存量读取。
- Story 明确要求「不涉及架构变更」且无 greenfield：**可经 orchestration 将本要素移出序列**。

---

## 约束

### 格式规范

| standard_id | 规范说明 |
|-------------|---------|
| `design-architecture` | 合并：技术选型/代码分层/部署/微服务/特性开关/公共库/AOP、`it_design_doc`/`app-arch`摘录；按标准内「分段」取用 |

### 设计约束

| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|----------|
| `DC-ARC-001` | `MUST` | architecture 正文必须按子要素（见下表）组织，不得在 L1 下直接堆不分段的散文 | 检视 L2 标题与要素映射表 |
| `DC-ARC-002` | `MUST` | 条文优先引用加载规范原文；仅在「设计」模板段落填写占位符 | Phase 5 对照规范 checkpoint |
| `DC-ARC-003` | `MUST_NOT` | 不得引入规范未定义的第三方栈版本号或与 PRD 明显冲突的拓扑 | Phase 5 可追溯 PRD |
| `DC-ARC-004` | `MUST_NOT` | 仅输出架构设计原则与结构说明，禁止直接输出可执行具体代码（含完整方法体、脚本、SQL） | Review |

---

## 要素映射（与 `design-architecture-standard` 分段键一致）

| 子要素目录 | design-architecture-standard 分段键 | 说明摘要 |
|------------|-------------------------------------|----------|
| `arch-tech-stack` | `arch-tech-stack` | §1.1 技术选型 + §1.5/§1.6/§1.7 规范与模板重叠段 |
| `arch-deployment` | `arch-deployment` | 容器编排、拓扑、副本、流水线、容灾 |
| `arch-microservice` | `arch-microservice` | 边界、Feign/MQ、governance、`flowchart`/架构组件摘录 |
| `arch-feature-toggle` | `arch-feature-toggle` | 灰度维度、Feature Flag、路由示例 |
| `arch-code-structure` | `arch-code-structure` | DDD 四层与包命名（与 §1.5 对齐处取并集表述）|
| `arch-common-lib` | `arch-common-lib` | 前后端公共模块 |
| `arch-common-component` | `arch-common-component` | AOP 切面注解与设计表 |

编排层 `sub_elements` **建议**与本表 L2 同名或显式别名对照表。

---

## 执行步骤（设计写作）

### build `[自动]` + `[交互]`

1. **Inventory**：从 PRD 提取部署要求、租户/网关/中间件陈述、与非功能相关内容；标记 greenfield-only 条目。
2. **Draft**：按「输出骨架」与 `design-architecture` 各分段依次生成；微服务/governance/QPS 等具体数值若未定用 `{占位}` 并记入待确认清单。
3. **Cross-check**：核对 `feature.*` 与 `config/app-config` 占位一致；拓扑图与 §2/`it_design_doc` 摘录同向。
4. **交互收口**：用户对「不适用 / 待定」逐项确认后继续 Phase 6。

### modify 模式

仅对 `modify_focus` 所列子分段重写；不改未声明 L2。

### incremental 模式

**极少触发**；仅在 ChangeRouter 以 certain 命中 architecture 时执行。

**Step 1:** `[自动]` 读取基线 architecture.md，定位受影响子分段，提取 baseline_state。

**Step 2:** `[自动]` 对 element_changes 生成 DELTA 块和 DIP，遵循以下约束：

| 子域 | 增量核心动作 | 强制边界约束 |
|------|------------|------------|
| 微服务架构 | 服务边界新增/调整 | **既有服务名称禁止修改** |
| 代码架构 | cascade 时调整分层目录树 | — |
| 部署架构 | 极少触发；若触发则调整 Pod 资源表格 | — |
| 公共基础库/组件 | cascade 时新增抽象类/工具类 | — |

仅对 Delta 所列子分段重写；不改未声明 L2。

---

## 输出骨架

（章节编号示例，以 orchestration 传入 `chapter_info` 为准）

```markdown
## {L1_no} {element_name}

### {L2_no} 技术选型与代码架构综述
...

### {L2_no} 部署架构
...

### {L2_no} 微服务架构
...

### {L2_no} 灰度与特性开关
...

### {L2_no} 代码架构（四层与包命名）
...

### {L2_no} 公共基础库
...

### {L2_no} 公共组件（AOP 切面）
...
```
