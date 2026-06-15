---
module_id: "m-design-integration"
implements: "integration"
for_scenario: ["专题需求", "优化需求"]
for_type: ["TP", "AP", "AI"]
execution_mode: ["build", "modify", "incremental"]
status: "active"
---

# m-design-integration — 集成与异步

> **一句话说明**：在 `integration.md` 描述 MQ、外部依赖容错与多端通知链路；条文见本包 `design-integration` 各分段。

---

## 目标

**目标说明**

对异步边界给出**可对账**的生产设计：Topic/Tag/schema、收发可靠性、积压与分区；Feign/RPC **超时熔断降级重试**；通知模板、频控、幂等与失败降级路径。

**输出物**

- 清单表格 + Topic 深挖段落 + FeignClient 容错表 + 通知场景卡。

**成功标准**

- 事务边界与 MQ 发送时机条文一致（事务后发送）；外部依赖三色指标（超时、熔断、降级）完整；审批与通知时间与 `workflow`/`config` 交叉引用占位正确。

---

## 前置条件

**依赖要素**

| 依赖要素 element_id | 原因 |
|---------------------|------|
| `backend-impl` | 生产者/消费者在方法级可追溯 |
| `config` | 动态阈值、字典、错误码对齐 |

---

## 约束

### 格式规范

| standard_id | 规范说明 |
|-------------|---------|
| `design-integration` | MQ、外部调用、通知 三分段全文 |

### 设计约束

| 约束编号 | 级别 | 规则 | 验证方法 |
|----------|------|------|----------|
| `DC-INT-001` | `MUST_NOT` | 禁止在 `@Transactional` 内直发 MQ | 抽查 |
| `DC-INT-002` | `MUST` | 消费者幂等与 DLQ 策略显式写明 | MQ 小节 |
| `DC-INT-003` | `MUST_NOT` | 仅输出集成与异步设计说明，禁止直接输出可执行具体代码（含完整方法体、脚本、SQL） | Review |

---

## 要素映射

| 子要素目录 | 说明 |
|------------|------|
| `integration-mq` | Topic、环境后缀、可靠性、积压 |
| `integration-external` | 超时熔断降级重试、影响评估摘录 |
| `integration-notification` | 渠道模板、幂等、频控 |

---

## 执行步骤

1. **`[自动]`**：按 PRD 列 Topic 与 Payload 极简 schema。
2. **`[自动]`**：每条外部调用填容错矩阵。
3. **`[自动]`**：对齐通知与 MQ 消费的衔接。
4. **`[交互]`**：与用户确认 SLA 与非功能阈值。

### incremental 模式

**Step 1:** `[自动]` 读取基线 integration.md，定位受影响的 MQ/外部服务/通知章节，
提取 baseline_state。

**Step 2:** `[自动]` 对 element_changes 生成 DELTA 块和 DIP，遵循以下约束：

| 子域 | 增量核心动作 | 强制边界约束 |
|------|------------|------------|
| MQ 清单 | 新增/调整 Topic/Tag 和消息 Schema | — |
| 外部服务依赖 | 新增/调整外部服务和容错策略 | **既有接口契约禁止修改** |
| 消息通知 | 新增/调整通知渠道和文案模板 | — |

**Step 3:** `[交互]` 若涉及降级策略变更或跨系统一致性，暂停确认。

---

## 输出骨架

```markdown
## {章节} 集成与异步
### MQ 清单与设计
### 外部服务依赖
### 消息通知
```
