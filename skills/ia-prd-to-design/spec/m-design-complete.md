# 设计完成收尾

## 输入

| 变量 | 说明 |
|---|---|
| `WORKFLOW_ID` | 当前 workflow |
| `DESIGN_DIR` | 当前特性设计目录 |
| `DESIGN_FILE` | `{DESIGN_DIR}/design.md` |
| `STORY_FILE` | `{DESIGN_DIR}/story.md` |
| `completed_elements[]` | 本轮完成要素 |
| `artifact_files[]` | 本轮产出或修改文件 |
| `collected_summaries[]` | 已校验汇总块 |

## 收尾步骤

1. 更新本轮涉及 artifact 的 frontmatter：
   - `status: completed`
   - `last_updated: {YYYY-MM-DD}`
   - `last_element`
   - `stepsCompleted`
2. 更新 `{WORKSPACE_ROOT}/workspace/ongoing.md`：
   - 当前 `ia-prd-to-design` 状态改为 `completed`
   - 记录 `current_path: {DESIGN_DIR}/design.md`
   - Phase 改为 `ia-testcase`
   - Stage 改为 `测试设计`
3. 推进 `story.md` 状态：
   - 若 `story.md` 存在且状态字段为 `initial`，推进为 `analysis`。
   - 若状态字段不存在或值不明确，追加状态 `analysis` 并记录警告。
   - 记录已执行设计引用回填。
4. Story 回填收口：
   - 若 `story.md` 存在，记录已执行设计引用回填。
   - 若 `story.md` 不存在，完成报告提示"未发现 story.md，已跳过 US 设计引用回填"。
5. 输出完成报告。

## 完成报告模板

```text
── 设计流程完成 ──────────────────
workflow：{WORKFLOW_ID}
已完成要素：{completed_elements}
产出文件：{artifact_files}
Story 回填：{已执行 / 未发现 story.md，已跳过}
Story 状态推进：{initial → analysis / 已处于 analysis / 未处理}

下一步建议：
  /iscit-dev-new story.md
  /ia-tech-design-review 检查技术方案

[C] 完成
[B] 修改某个要素
[S] 查看已生成内容
[Q] 保存并退出
──────────────────────────────────
```
