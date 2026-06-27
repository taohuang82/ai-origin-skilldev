---
standard_id: "config-error-code"
domain: "config"
---

# config-error-code

**规范分段**：`config-error-code`

### 规范条文

# 错误码体系规范（TDD 第6章 §6.2）

## 6.2 错误码体系规范

### 错误码格式

格式：`{系统}-{模块}-{类型}-{序号}`

示例：
- `APP-ORDER-BIZ-001` — 业务错误：订单状态不允许该操作
- `APP-USER-SYS-001` — 系统错误：用户服务内部异常
- `APP-AUTH-SEC-001` — 安全错误：签名验证失败

**类型说明**：
- `BIZ`：业务逻辑错误（HTTP 4xx，用户侧原因）
- `SYS`：系统/服务错误（HTTP 5xx，服务侧原因）
- `SEC`：安全/权限错误（HTTP 401/403）
- `VAL`：参数校验错误（HTTP 400）

### 错误码分配原则

- 同一系统内错误码唯一，禁止复用
- 序号从 `001` 开始，按功能模块区段分配（ORDER 模块 001~099，USER 模块 100~199）
- 新增错误码追加，禁止修改已存在错误码含义（向后兼容）

### 前端文案规范

- 业务错误（BIZ/VAL）：给用户友好提示（中文），引导用户操作
- 系统错误（SYS/SEC）：通用提示（如"系统繁忙，请稍后重试"），不暴露内部细节
- 多语言：`i18n/zh-CN.json` 中 key = 错误码，value = 文案

### API 响应中的错误码使用

- 错误码在统一响应体 `code` 字段返回
- `message` 面向开发者（英文/技术描述），`localMessage`（可选）面向用户（中文）
- 禁止在 API 响应中直接返回数据库错误或堆栈信息

## 输出骨架
# 错误码体系设计（TDD 第6章 §6.2）

<!--
变更标注约定：
- ✨ 新增：本次新增的错误码
- 🔧 修改：修改了已有错误码文案（不修改错误码本身）
-->

## 变更概要

| 动作 | 对象 | 说明 |
|------|------|------|
| ✨/🔧 | | |

---

## 6.2 错误码体系

### 错误码清单

| 错误码 | 类型 | HTTP 状态 | 前端用户文案 | 开发者说明 | 动作 |
|--------|------|----------|-----------|---------|------|
| `APP-{模块}-BIZ-001` | BIZ | 400 | | | ✨ |

---

### ✨/🔧 {模块名} 模块错误码

> 🔧 **变更说明**：{仅修改时填写}

**错误码区段**：`APP-{MODULE}-*-{001~099}`（{模块}专属区段）

| 错误码 | 类型 | HTTP 状态 | 前端用户文案 | 开发者说明 | 触发场景 |
|--------|------|----------|-----------|---------|---------|
| `APP-ORDER-BIZ-001` | BIZ | 400 | 当前状态不允许该操作 | Status transition invalid | 状态机前置校验失败 |
| `APP-ORDER-BIZ-002` | BIZ | 403 | 无权操作该订单 | Data permission denied | 数据权限校验失败 |
| `APP-ORDER-SYS-001` | SYS | 500 | 系统繁忙，请稍后重试 | External service timeout | 审批服务调用超时 |

**国际化文件路径**：`src/i18n/zh-CN.json`

```json
{
  "APP-ORDER-BIZ-001": "当前状态不允许该操作",
  "APP-ORDER-BIZ-002": "无权操作该订单"
}
```

**Java 枚举定义**：

```java
public enum OrderErrorCode {
    STATUS_INVALID("APP-ORDER-BIZ-001", "Status transition invalid"),
    DATA_PERMISSION_DENIED("APP-ORDER-BIZ-002", "Data permission denied");
}
```