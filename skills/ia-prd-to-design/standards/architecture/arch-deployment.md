---
standard_id: "arch-deployment"
domain: "architecture"
---

# arch-deployment

**规范分段**：`arch-deployment`

### 规范条文

# 部署架构规范（TDD 第1章 §1.2）

> **仅在 build 模式下输出。**

## 1.2 部署架构规范

### 容器化与编排

- 所有服务必须容器化（Docker），通过 Kubernetes 编排
- 每个微服务定义独立的 `Deployment` + `Service`（K8s 资源）
- 资源配置（CPU/Memory Request/Limit）必须明确，禁止不设 limit（防止资源争抢）
- 生产环境最小副本数 ≥ 2（可用性保障）

### 容灾部署

- 双机房主备容灾（同城）或多活（异地）
- Pod 亲和性配置：同一 Deployment 的 Pod 不部署在同一节点
- 数据库使用主从复制，读写分离

### CI/CD 流水线节点

```
代码提交 → 静态检查（lint）→ 单元测试 → 打包构建
    → 镜像构建（Docker Build）→ 推送镜像仓库（Harbor）
    → 部署到测试环境 → 集成测试 → 部署到预发环境
    → 冒烟测试 → 部署到生产环境（灰度 → 全量）
```

### 关键配置规范

- 所有配置通过 ConfigMap/Secret 注入，禁止硬编码在镜像中
- 健康检查：`livenessProbe` + `readinessProbe` 必须配置
- 滚动更新策略：`maxSurge=1, maxUnavailable=0`，保证零停机发布

---

## 项目规范摘录（`规范/` 目录 · IT 设计文档 §2）

> 来源：`{WORKSPACE_ROOT}/规范/examples/it_design_doc.md`「需求上下文 — 架构组件分析」。

- 建议输出节点拓扑图（Mermaid `flowchart` 或等价 UML），展示负载均衡、网关、微服务、数据层的层次关系。
- 须说明 Pod 资源分配、副本数、CI/CD 流水线关键节点与容灾策略。

## 输出骨架
# 部署架构设计（TDD 第1章 §1.2）

> **仅 build 模式输出。** 本文件确定后，后续版本迭代不重新生成，变更需走架构评审。

---

## 1.2 部署架构

### 节点拓扑

```
[ 用户 / 外部系统 ]
        │
  [ 负载均衡 / CDN ]
        │
  [ API Gateway（Spring Cloud Gateway）]
        │  限流、鉴权、路由
  ┌─────┴──────────────────┐
  │                        │
[ 业务微服务 A ]     [ 业务微服务 B ]
  │                        │
[ 数据库 / 缓存 / MQ ]
```

### 微服务列表

| 服务名 | 职责 | 副本数（生产） | 端口 |
|--------|------|------------|------|
| `{service-name}` | | ≥2 | 8080 |

### Pod 资源配置

| 服务 | CPU Request | CPU Limit | Mem Request | Mem Limit |
|------|------------|----------|------------|---------|
| `{service-name}` | 500m | 2000m | 512Mi | 2Gi |

### CI/CD 流水线

```
main 分支提交
    → Jenkins/GitLab CI：单元测试 + 构建
    → Docker Build → Harbor 推送
    → 自动部署到 dev 环境
    → （手动触发）部署 test → 预发 → 生产灰度 10% → 生产全量
```

### 容灾策略

| 维度 | 策略 |
|------|------|
| Pod 容灾 | 同一 Deployment Pod 反亲和，分布在不同 Node |
| 机房容灾 | {双机房主备 / 单机房} |
| 数据库容灾 | 主从复制，读写分离（写主读从）|