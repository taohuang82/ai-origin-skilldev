# workflow-engine

## 引擎元信息

```yaml
engine_version: "2.3.0"
spec_compliance: "v1.5.0"
```

## 职责声明

本文件是纯抽象场景路由引擎，完全业务无感知。所有路由判断完全基于 registry 数据驱动，禁止硬编码业务分支。

**只路由**：禁止读 spec/standards、禁止派发 subAgent、禁止写 artifact 正文。要素的执行由 Layer 4 orchestration 按 dispatch 配置派发 element-runner 完成（inline 或 subAgent），本文件只负责"选中哪个 workflow 并分发给对应 orchestration"。

> **术语澄清**：本文件的 "SceneRouter" 是 **workflow 大场景路由器**，在多个 workflow（新建/增量/评审/续接）之间做选择。它与 Layer 3.5 的"变化点路由器（ChangeRouter）"不是同一概念——后者是在 workflow 命中后、对增量需求做"原子变化点 → 受影响要素"二级路由。本文件不涉及 Layer 3.5。

## Phase 1：构建 Input Inventory

1. 读取 `config.yaml` 中的 `context.ongoing_file`，加载当前项目状态
2. 按 `registry/input-type-registry.yaml` 中定义的 `detect_rules` 逐一检测每类输入源的存在状态
3. 构建 Input Inventory：`{input_type_id: true/false, ...}`

## Phase 1.5：处理用户指定

按优先级顺序检查：

### 1.5.1 提取用户指定意图
**优先级 1：对话中明确指定** —— 扫描 user_message：①直接 workflow_id 匹配 ②关键短语（"用 X 跑"、"走 X 流程"、"切换到 X" / "use X"、"switch to X"）③workflow_name 匹配
**优先级 2：ongoing.md 预声明** —— 读取 `ongoing.md.workflow_hint`（若存在）
**优先级 3：无指定** —— 进入 Phase 2 自动匹配
> `trigger_keywords` 不属于"用户指定"，是消歧弱信号，处理时机在 Phase 2。

### 1.5.2 解析为 workflow_id
①意图字符串本身是 workflow.id → 直接使用 ②是 workflow.name 子串 → 反查 id ③映射失败 → 输出提示，进入 Phase 2

### 1.5.3 校验合法性（强制三项校验）
- **校验 1 workflow 存在**：不通过 → 提示后进入 Phase 2
- **校验 2 status ≠ planned**：不通过 → 输出错误 + `[A]自动选择其他 / [Q]退出`，**禁止降级绕过**
- **校验 3 input_signature 严格满足**：required 全 true、excluded 全 false；不通过 → 输出缺失/冲突 + `[A]补齐重试 / [B]自动选择其他 / [Q]退出`，**禁止"强制忽略"**

### 1.5.4 通过校验后
写 `ongoing.md.workflow_hint` → 输出 `✅ 已按你的指定执行：{workflow_name}（{workflow_id}）` → 跳至 Phase 3

### 1.5.5 不通过/无指定
回退 Phase 2 自动匹配。

---

## Phase 2：执行 SceneRouter
> 前置：Phase 1.5 未提取到有效的用户指定。

### 2.1 优先级遍历匹配
按 workflow-registry 中 priority 从高到低遍历：跳过 status=="planned"；检查 input_signature.required（全 true）与 excluded（全 false）；记录满足者为"候选集合"。

### 2.2 三道消歧防线
**防线1 关键词**：用 `trigger_keywords` 与用户输入模糊匹配
**防线2 类型二次消歧**：读 `ongoing.md.requirement_type` / 上游文档 frontmatter，精准匹配 workflow 类型约束
**防线3 用户交互确认**：候选仍 >1 时，输出编号列表 + 描述，等待用户选择，禁止随机命中

### 2.3 组装 Context Box
命中唯一 workflow 后打包传入 orchestration：
- `workflow_id`
- `execution_mode`（build / create / incremental / modify / deprecate / resume）
- Input Inventory 中的相关输入源路径
- `frontmatter_seed`（新建初始 frontmatter 模板）
- `resume_mode`（续接置 true）

> `requirement_type`（TP/AP/AI/IT）不在此判定——由 orchestration Phase 0 判定后写入 frontmatter。

## Phase 3：更新全局状态锚点
写 `ongoing.md.workflow_hint` + 按 Skill 命名空间写 `ongoing.md.{skill_namespace}.current_path`。

## Phase 4：分发编排
读命中 workflow 的 `orchestration_file`，加载对应 orchestration，传入 Context Box。

## 断点恢复支持
命中 `resume_mode: true` 时，解析输出文档 frontmatter 中的原始 workflow_id，重启对应编排。

## 输出

向 orchestration 交付的上下文至少包含：

```yaml
workflow:
  id: ""
  orchestration_file: ""
  # 无 element_sequence：最终要素序列由 orchestration 从 element-type-registry(shared)
  # 选要素 + spec-template-registry.depends_on 拓扑分波得出（不再由本引擎给）
inventory: {}
paths:
  input_doc: ""
  output_doc: ""
  base_doc: ""
  raw_requirements: ""          # FE Skill 用
frontmatter_seed: {}
user_message: ""
extracted_info: {}              # 文档抽取结果，FE Skill 用
resume_mode: false
```
