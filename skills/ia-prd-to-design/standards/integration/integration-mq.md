---
standard_id: "integration-mq"
domain: "integration"
---

# integration-mq

**规范分段**：`integration-mq`

### 规范条文

# MQ 清单设计规范（TDD 第5章 §5.1）

## 适用场景

以下情形**必须**设计 MQ 要素：
- 业务流程需要异步解耦（如订单创建后异步发送通知）
- 耗时操作需要削峰（如大批量数据导出）
- 跨微服务事件驱动（如状态变更触发下游联动）

## Topic 命名规范

格式：`T_{业务域}_{动作}` 如: 

示例：
- `T_KRI_MODEL_DATASET_CHANGE` — KRI模型数据集变更消息
- `T_PROJECT_ACTIVITY_CREATE` — 项目创建消息

### 环境隔离策略

**测试环境共用MQ服务器,通过Topic名称区分:**
- dev环境: `T_KRI_MODEL_DATASET_CHANGE_DEV`
- sit环境: `T_KRI_MODEL_DATASET_CHANGE_SIT`
- uat环境: `T_KRI_MODEL_DATASET_CHANGE_UAT`
- 生产环境: `T_KRI_MODEL_DATASET_CHANGE`

## 消息体 Schema 规范

- 使用 JSON 格式，字段名驼峰命名
- 必须包含：`businessId`（业务唯一ID）、`messageId` (幂等键)、业务字段
- 可选：`need_order` 是否需要顺序消费、`need_reply` 是否需要回执
- 禁止在消息体中传递大对象（如完整的订单详情），传 ID 让消费者自行查询

## 可靠性设计

### 发送端（Producer）

- 关键消息使用**事务消息**或**本地消息表**保证不丢失
- 发送失败需要重试，重试次数有上限（通常 3 次），超出记录数据库异步补偿
- 发送 MQ 必须在**事务提交后**执行（禁止在事务内发 MQ）

### 消费端（Consumer）

- 必须实现**幂等消费**（幂等键 = `messageId`）
- 消费失败的错误处理：
  - 可重试错误（如网络超时）：重试 N 次（指数退避）
  - 不可重试错误（如数据格式错误）：直接进死信队列（DLQ），人工处理
- 消息乱序：设置orderGroupId消息分组ID，MsgGroupId相同的消息在消费时能保证有序

### 积压告警

- 消费者组积压监控，超过阈值触发告警
- 消费者实例数可按积压量弹性扩容

## 消息顺序

| 场景 | 方案 |
|------|------|
| 顺序消息（同一订单的事件有序） | 使用 orderId 作为分区键（shardingKey） |
| 无顺序要求 | 不设 shardingKey，提升并发 |

---

## 项目规范摘录（`规范/` 目录 · IT 设计文档 §4.5）

> 来源：`{WORKSPACE_ROOT}/规范/examples/it_design_doc.md`「MQ设计」章节。

- **MQ 设计场景**：每条需求须标明 **新增 / 修改 / 删除** 之一。
- **Topic 名称**：与本文档 Topic 命名规范一致，并在设计说明中写清业务含义。
- **消息结构体**：用 **标准 JSON** 给出字段定义（可与上文消息体 Schema 合并输出）。

## 输出骨架
# MQ 清单设计（TDD 第5章 §5.1）

<!--
变更标注约定：
- ✨ 新增：本次新增的 Topic/Tag
- 🔧 修改：Schema / 消费者组 / 策略变更
-->

## 变更概要

| Topic | Tag | MQ 场景（新增/修改/删除） | 动作 | 说明 |
|-------|-----|--------------------------|------|------|
| | | 新增 | ✨/🔧 | |

---

## MQ 清单

| Topic          | Tag | 发布者 | 消费者 | 顺序消息 | 动作 |
|----------------|-----|--------|--------|---------|------|
| `T_{业务域}-{动作}` | 可为空 | `{service}-producer` | `{service}-consumer` | Y/N | ✨/🔧 |

---

## ✨/🔧 Topic：{topic-name} / Tag：{TAG_NAME}

> 🔧 **变更说明**：{仅修改时填写，Schema 变更需说明字段增减及兼容策略}

### 基本信息

| 属性 | 值                         |
|------|---------------------------|
| Topic | `T_{业务域}-{动作}`            |
| Tag | `{RESOURCE_ACTION}`       |
| 发布者组 | `{service-name}-producer` |
| 订阅者组 | `{service-name}-consumer` |
| 消息顺序 | 有序（消息分组Id：{orderGroupId}）/ 无序  |

### 消息体 Schema

```json
{
  "eventId": "string（UUID，幂等键）",
  "eventType": "RESOURCE_ACTION",
  "occurredAt": "timestamp（ISO 8601）",
  "{businessId}": "string（业务主键）",
  "{otherField}": "..."
}
```

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `eventId` | String | Y | 幂等键，全局唯一 |
| `eventType` | String | Y | 事件类型枚举 |
| `occurredAt` | String | Y | 事件发生时间，ISO 8601 |
| `{businessId}` | String | Y | 业务主键 |

### 触发源

| 触发操作 | 触发方法 | 说明 |
|---------|---------|------|
| {业务操作} | `{ServiceImpl}.{method}()` | {发生在事务提交后} |

### 消费方与处理逻辑

| 消费者服务 | 消费者组 | 处理逻辑摘要 | 幂等键 |
|----------|---------|------------|--------|
| | `{service}-consumer` | | `eventId` |

### 可靠性设计

| 场景 | 方案 |
|------|------|
| 发送保障 | 事务消息 / 本地消息表（`{table_name}`） |
| 消费幂等 | 幂等键 = `eventId`，Redis SETNX 去重 |
| 消费失败 | 重试 3 次（指数退避），超限进 DLQ |
| 积压告警 | 消费者组积压 > {N} 条触发告警 |