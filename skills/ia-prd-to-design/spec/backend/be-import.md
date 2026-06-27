---
element_id: be-import
parent_domain: backend
parent_element_id: backend-impl
---

# be-import 设计规范

## 适用条件

- PRD 含批量导入、Excel 导入、数据初始化或模板化导入类子特性。

## 前置依赖

- 域级 spec `## 前置条件`；Subagent `force_read[]` 上游 artifact（若有）。
- 依赖 `be-api` 已落盘或同步设计，导入接口契约须与 API 清单一致。

## 输出归属

- 聚合到 `{DESIGN_DIR}/backend.md` 的 `## §3.7 导入设计`

## 执行步骤

### build 模式

1. 导入场景识别：按 `be-import.prd_sources` 读取 PRD，提取导入对象、模板字段、数据量、触发方式、权限点。
2. 导入模式选型：同步直落 / 异步任务 / 本地解析+异步落库。
3. Jalor 导入 API 契约：路径 `/servlet/upload?ulType=ExcelImport&excelType={excelId}`、请求方式、权限码。
4. Provider/Consumer/任务类设计：模板校验、分批处理、临时表/结果表、错误回写。
5. 幂等/去重、异常处理、进度查询、结果通知策略。

### modify 模式

1. 仅改命中导入场景。

### incremental 模式

1. Read 基线 §3.7 → DELTA。
2. **导入模板字段禁止破坏已发布模板结构（列顺序/列名）**

**增量边界**：导入 | 新增导入 | 模板向后兼容

## 质量检查点

- 有导入模板字段表
- 有权限点
- 有异步任务状态机（若选异步）
- 分节标题字面量 `## §3.7 导入设计`
- 无占位符、空 Mermaid、空表头
- 符合 `standards/backend/be-import.md`
