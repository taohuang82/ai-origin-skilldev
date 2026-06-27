---
standard_id: "arch-common-component"
domain: "architecture"
---

# arch-common-component

**规范分段**：`arch-common-component`

### 规范条文

# 公共组件规范（TDD 第1章 §1.7）

> **仅在 build 模式下输出。**

## 1.7 公共组件（AOP 切面）规范

### 切面组件

| 注解 | 功能 | 切面织入时机 |
|------|------|------------|
| `@Idempotent` | 幂等控制 | 方法执行前（Redis SETNX 去重）|
| `@DistributedLock` | 分布式锁 | 方法执行前后（Redisson，自动释放）|
| `@AuditLog` | 操作审计日志 | 方法执行后（记录操作人、入参摘要、结果）|
| `@Desensitize` | 响应字段脱敏 | Jackson 序列化时（手机号/身份证等）|

### 切面设计约定

- 切面逻辑不包含业务判断，只做横切关注点处理
- 切面异常不影响主业务流程（最多记录日志）
- 幂等键的有效期与业务 TTL 对齐

### 分布式锁规范

- Key 格式：`lock:{业务域}:{资源标识}`
- 超时时间必须显式设置，防止死锁
- 锁释放在 `finally` 块中执行

### 幂等组件规范

- 幂等 Key 默认使用 SpEL 表达式从方法参数中提取
- 幂等窗口期（TTL）根据业务场景设置，通常 5~30 分钟
- 幂等 Key 冲突时直接返回，不抛出异常

## 输出骨架
# 公共组件设计（TDD 第1章 §1.7）

> **仅 build 模式输出。** 本文件确定后，后续版本迭代不重新生成，变更需走架构评审。

---

## 1.7 公共组件（AOP 切面）

| 注解 | 功能 | 参数说明 | 使用示例 |
|------|------|---------|---------|
| `@Idempotent` | 幂等控制 | `key`（SpEL 表达式）, `ttl`（秒） | `@Idempotent(key="#req.orderNo", ttl=300)` |
| `@DistributedLock` | 分布式锁 | `key`, `timeout`（毫秒） | `@DistributedLock(key="#orderId", timeout=3000)` |
| `@AuditLog` | 操作审计 | `action`（操作名） | `@AuditLog(action="审批订单")` |
| `@Desensitize` | 字段脱敏 | `type`（PHONE/ID_CARD 等） | Jackson 序列化时自动触发 |