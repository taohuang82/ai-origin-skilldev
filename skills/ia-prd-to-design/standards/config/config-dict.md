---
standard_id: "config-dict"
domain: "config"
---

# config-dict

**规范分段**：`config-dict`

### 规范条文

# 数据字典与错误码体系规范（TDD 第6章 §6.1 / §6.2）

## 6.1 数据字典规范

#### 配置项编码规范

**编码格式**：`App.SubApp.{模块名}.{控制名称}`

**编码组成**：
- `App` - 应用名称（固定前缀）
- `SubApp` - 子应用名称（固定前缀）
- `{模块名}` - 业务模块名称（如 OrderModule、ProductModule）
- `{控制名称}` - 控制项名称（如 EnableAutoApproval、MaxOrderAmount）

**命名规则**：
- 使用驼峰格式（CamelCase）
- 模块名使用 Module 后缀（如 OrderModule）
- 控制名称清晰表达配置含义（如 EnableAutoApproval）

**编码示例**：
```markdown
✅ 正确示例：
- App.SubApp.OrderModule.EnableAutoApproval - 启用自动审批
- App.SubApp.OrderModule.MaxOrderAmount - 最大订单金额
- App.SubApp.OrderModule.OrderTimeoutMinutes - 订单超时时间

❌ 错误示例：
- EnableAutoApproval（缺少统一前缀）
- App.SubApp.orderModule.enableAutoApproval（未使用驼峰格式）
- App.SubApp.OrderModule.Enable_Auto_Approval（使用下划线）
```

---

## 6.2 错误码体系规范

### 错误码格式

格式：`{应用模块简称}.{领域模块}.{6位序号}`

示例：
- `ARS.LABEL.000001` — 标签错误码
- `ARS.RESOURCE.000001` — 系统错误：用户服务内部异常

**类型说明**：
- `LABEL`：标签域
- `RESOURCE`：资源域

### 错误码分配原则

- 同一系统内错误码唯一，禁止复用
- 序号从 `000001` 开始，全局自增唯一即可
- 新增错误码追加，禁止修改已存在错误码含义（向后兼容）

### HTTP响应码规范
常用客户端错误响应码：
[400 Bad Request] 参数有误，相关业务逻辑校验失败等等
[401 Unauthorized] 权限相关错误
[404 Forbidden] 资源不存在

常用系统错误响应码：
[500 INTERNAL_SERVER_ERROR] 系统异常

### 前端文案规范

- 业务错误：给用户友好提示（中文），引导用户操作
- 系统错误：通用提示（如"系统繁忙，请稍后重试"），不暴露内部细节
- 多语言：`i18n/zh-CN.json` 中 key = 错误码，value = 文案

### API 响应中的错误码使用

- 错误码响应示例
```json
{
    "code": "arms.probe.000001",        // 错误编码
	"httpCode": 406,                             // HTTP状态码
	"entity": null,
	"message": "评价规则查询失败！参数:规则ID:13891135755197391488",       // 错误信息
	"faultUid": null,
	"stackTrace": "",
	"friendly": false
}
```
- 禁止在 API 响应中直接返回数据库错误或堆栈信息

## 输出骨架
# 数据字典与错误码体系设计（TDD 第6章 §6.1 / §6.2）

<!--
变更标注约定：
- ✨ 新增：本次新增的字典分类或错误码
- 🔧 修改：在现有基础上新增键值或修改文案
-->

## 变更概要

| 要素 | 动作 | 对象 | 说明 |
|------|------|------|------|
| 6.1 数据字典 | ✨/🔧 | | |
| 6.2 错误码 | ✨/🔧 | | |

---

## 6.1 数据字典

#### 配置表格格式

| 配置项编码 | 配置项名称 | 数据类型 | 默认值 | 影响范围 | 维护方式 | 需求来源 |
|------------|------------|----------|--------|----------|----------|----------|
| App.SubApp.OrderModule.EnableAutoApproval | 启用自动审批 | Boolean | false | 订单模块 | 运维侧 | PRD第X.X节 |
| App.SubApp.OrderModule.MaxOrderAmount | 最大订单金额 | Decimal | 100000.00 | 订单模块 | 运维侧 | PRD第X.X节 |
| App.SubApp.OrderModule.OrderTimeoutMinutes | 订单超时时间（分钟） | Integer | 30 | 订单模块 | 运维侧 | PRD第X.X节 |

**表格字段说明**：
- **配置项编码**：配置项唯一标识，使用统一前缀格式
- **配置项名称**：配置项显示名称
- **数据类型**：Boolean/Integer/Decimal/String/Date
- **默认值**：配置项默认值
- **影响范围**：配置项影响的业务模块或功能

**使用位置**：
- 数据库字段：`{table_name}.{field_name}`（见 data/data-table.md）
- 后端获取：`registryQueryService.findRegistryListByParentPath("App.SubApp.excel.importPageVal", true)`

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