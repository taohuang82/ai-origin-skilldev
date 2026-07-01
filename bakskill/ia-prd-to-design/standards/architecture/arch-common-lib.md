---
standard_id: "arch-common-lib"
domain: "architecture"
---

# arch-common-lib

**规范分段**：`arch-common-lib`

### 规范条文

# 公共基础库规范（TDD 第1章 §1.6）

> **仅在 build 模式下输出。**

## 1.6 公共基础库规范

### 必须封装的公共能力

| 能力 | 封装形式 | 模块 |
|------|---------|------|
| 统一响应封装 | `Result<T>` 泛型响应体 | `common-core` |
| 全局异常处理 | `@ControllerAdvice` + `GlobalExceptionHandler` | `common-core` |
| 工具类 | `DateUtils`, `JsonUtils`, `StringUtils` | `common-util` |
| 请求封装（前端） | Axios 封装 + Token 注入 + 错误拦截 | `request.ts` |

### 后端公共模块规范

| 模块名 | 提供能力 | 引入方式 |
|--------|---------|---------|
| `common-core` | `Result<T>`响应封装、`GlobalExceptionHandler`、`BusinessException` | Maven 依赖 |
| `common-util` | `DateUtils`、`JsonUtils`、`PageUtils` | Maven 依赖 |
| `common-framework` | AOP 切面（幂等/锁/审计/脱敏）| Maven 依赖 |

### 前端公共模块规范

| 模块/文件 | 提供能力 |
|---------|---------|
| `src/utils/request.ts` | Axios 封装，统一 Token 注入、错误拦截、Loading 控制 |
| `src/composables/usePermission.ts` | `hasPermission()` 权限判断 Hook |
| `src/composables/useDict.ts` | 字典缓存与翻译 Hook |

### 使用约束

- 禁止在业务模块中重复实现公共基础库已提供的能力
- 公共库变更需向后兼容，破坏性变更须升级主版本号并通知所有引用方

## 输出骨架
# 公共基础库设计（TDD 第1章 §1.6）

> **仅 build 模式输出。** 本文件确定后，后续版本迭代不重新生成，变更需走架构评审。

---

## 1.6 公共基础库

### 后端公共模块

| 模块名 | 提供能力 | 引入方式 |
|--------|---------|---------|
| `common-core` | `Result<T>`响应封装、`GlobalExceptionHandler`、`BusinessException` | Maven 依赖 |
| `common-util` | `DateUtils`、`JsonUtils`、`PageUtils` | Maven 依赖 |
| `common-framework` | AOP 切面（幂等/锁/审计/脱敏）| Maven 依赖 |

### 前端公共模块

| 模块/文件 | 提供能力 |
|---------|---------|
| `src/utils/request.ts` | Axios 封装，统一 Token 注入、错误拦截、Loading 控制 |
| `src/composables/usePermission.ts` | `hasPermission()` 权限判断 Hook |
| `src/composables/useDict.ts` | 字典缓存与翻译 Hook |