# 引擎权威源（Engine Canonical Source）

> 适用规范：《设计文档类 Skill 构建规范 v1.5》第八章 §8.5「引擎共享与同步」

## 目的

本目录存放所有「设计类 / 资产类 Skill」共享的引擎文件的**唯一权威版本**。所有同类 Skill（`ia-fe-generator`、`ia-fe-to-prd`、`ia-prd-to-design`、`ia-asset-mgmt` 及未来同类）的 `engine/*.md` 都必须是本目录文件的**物理拷贝**，由人工同步维护。

## 文件清单（v2.2.0）

| 文件 | 用途 |
|------|------|
| `element-runner.md` | ★ **要素执行 subAgent 模板**（Step 0–5）。被 orchestration 以 subAgent 形式派发；一个模板、N 参数、无 designer 文件。已内化原 standards-loader 的规范加载职责。 |
| `workflow-engine.md` | 场景路由引擎（被 SKILL.md 启动序列调用） |
| `ENGINE-VERSION` | 当前引擎版本号（纯文本，启动校验用） |

> **v1.5 变更**：`standards-loader.md` **已删除**——规范热插拔加载（Level 1 用户扩展 > Level 2 内置）内化进 `element-runner.md` 的 Step 1。`element-runner.md` 由「主会话内联六阶段」重定义为「被派发的 subAgent 模板 Step 0–5」；原六阶段的要素解析/前置校验/状态更新上移至主 agent（orchestration）。

## 修改流程（强制）

**禁止**：直接修改任何 Skill 的 `engine/*.md`。

**正确流程**：
1. 修改 `docs/engine-canonical/` 下的对应文件
2. 更新 `docs/engine-canonical/ENGINE-VERSION`（递增版本号）
3. 同步拷贝到所有受影响的 Skill：

```bash
for skill in ia-fe-generator ia-fe-to-prd ia-prd-to-design ia-asset-mgmt; do
  cp docs/engine-canonical/element-runner.md   .claude/skills/$skill/engine/
  cp docs/engine-canonical/workflow-engine.md  .claude/skills/$skill/engine/
  cp docs/engine-canonical/ENGINE-VERSION      .claude/skills/$skill/engine/
done
```

4. 在每个 Skill 中跑一次启动校验，确认 engine_version 与 spec_compliance 一致

## 版本号规则

语义化版本 `major.minor.patch`：
- `patch`：错别字、注释、措辞
- `minor`：新增字段、新增 Step 子步骤、新增可选行为
- `major`：移除字段、改变 Step 语义、不兼容修改（v2.1.1 → 2.2.0 属 minor 边界，因保留调用契约但重构 element-runner 执行形态，按 minor 递增并在本 README 记录）
