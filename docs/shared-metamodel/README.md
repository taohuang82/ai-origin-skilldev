# shared-metamodel —— 共享元模型（唯一权威源）

本目录是「要素驱动 AI 研发方法论」四个 Skill（ia-fe-generator / ia-fe-to-prd /
ia-prd-to-design / ia-asset-mgmt）共享的**元模型与元数据唯一权威源**。它只回答
:「要素**是什么**」——身份、字段结构、关系、变化点；不回答「某要素在某 Skill 里
**怎么生成/抽取/合并**」（那是各 Skill 私有的 spec-template-registry + L5 spec）。

> 维护铁律：只改本目录，再用同步脚本物理复制进各 Skill 的 `registry/`
> （与 `docs/engine-canonical/` 同款）。**严禁**直接改任何 Skill 里的拷贝。

## 1. 文件清单与职责

| 文件 | M 层 | 做什么 | 谁来读 |
|---|---|---|---|
| `element-type-registry.yaml` | M3 | 25 类要素身份索引：中文名、层、萌芽/演进阶段、schema 指针、落库路径 | orchestration 选要素；asset-mgmt 定落库 |
| `relations.yaml` | M3 | 10 种关系类型 + 39 条合法组合，**关系属性名 `source_property` + 编号 `seq` 的唯一权威** | schema 对齐、闭包反查、门禁 |
| `element-types/{Type}.yaml`（×25） | M2 | 每类要素字段 schema：字段名/类型/必填/枚举/关系归属/分阶段补字段 | L5 spec 产字段；引擎校验实例 |
| `change-element-mapping.yaml` | L3.5 | 23 变化点 → 直接命中 + 关系闭包命中（`reverse_via` + `ref:"seq:N"`） | 增量影响分析（1→n） |
| `atomic-change-registry.yaml` | L3.5 | 23 变化点的产品语言定义 + 识别关键词 | ChangeRouter 自然语言路由 |
| `README.md` | 治理 | 本说明 + 门禁 + 使用示例 | 维护者 |

## 2. 文件之间的关系

```
                     atomic-change-registry.yaml
                     （口语 → 变化点 id）
                                │ id 一一对应
                                ▼
                     change-element-mapping.yaml
                     （变化点 → 受影响要素 + reverse_via/ref）
                       │ element_type            │ ref: "seq:N"
                       ▼                          ▼
        element-type-registry.yaml ───────▶ relations.yaml
        （要素身份 + schema_ref）  schema_ref │（seq=N 那条关系：
                       │                      │ source_property 是反查属性名）
                       ▼                      │
        element-types/{Type}.yaml ◀───────────┘
        （字段 schema；其关系字段名 == relations.source_property）
```

三处属性名同一真相（§16 三方对齐铁律）：
**relations.yaml `source_property` ＝ element-types 的关系字段名 ＝
change-element-mapping 的 `reverse_via`**——逐字相等，由门禁强校验。

## 3. Skill 怎么用这些元数据

### 3.1 0→1（首版全量构建）
1. orchestration 按本 Skill 阶段（FE/PRD/TDD）从 `element-type-registry.yaml`
   挑 `emerge_stage`/`evolve_stages` 命中本阶段的要素；
2. 对每个要素，读其 `schema_ref` → `element-types/{Type}.yaml` 拿字段结构；
3. L5 spec 据 schema 产出该要素文档节（关系字段名照 schema，即照 relations）；
4. 文档完版后，`ia-asset-mgmt` 按 `store_path` 把要素实例合并进资产库。

### 3.2 1→n（增量演进，本元模型的核心用法）

以 RR-005「订单创建后想直接指定供应商」为例，走查四文件如何串起来：

**① 口语 → 变化点**（用 `atomic-change-registry.yaml`）
ChangeRouter 拿用户口语，匹配 `detection_keywords`。本例命中多个变化点，
取其一 `DA-01`（「订单加 supplier_code 字段」命中关键词「加字段」）：
```yaml
- { id: DA-01, name: 实体聚合根加改字段, detection_keywords: [加字段, 新增属性, ...] }
```

**② 变化点 → 受影响要素**（用 `change-element-mapping.yaml`，按 id 查）
```yaml
- change_id: DA-01
  direct_hit:
    - { element_type: Aggregate, action: modify, confidence: certain }
  closure_hits:
    - { element_type: API, action: modify, confidence: likely,
        basis: 关系反查, reverse_via: realizes_sub_feature, ref: "seq:30",
        condition: 请求/响应引用该实体字段 }
    - ...
```
得到直接命中 `Aggregate(modify)` + 闭包候选 `API/Page/Repository/...`。

**③ 沿关系把候选落到具体实例**（用 `relations.yaml`，按 `ref` 的 seq 查）
闭包项 `API` 的 `ref: "seq:30"` → 查 `relations.yaml`：
```yaml
- { seq: 30, source: API, relation: realizes, target: SubFeature,
    source_property: "realizes_sub_feature" }
```
即：runtime 用 cross-references，沿 `API.realizes_sub_feature` 反查
:「realizes 受影响子特性」的所有 API 实例——这些就是要协变的具体 API。

**④ 对每个命中要素，取其身份与 schema**（用 `element-type-registry.yaml`）
```yaml
- element_type: Aggregate
  schema_ref: element-types/Aggregate.yaml
  store_path: "{domain}/technical/aggregates/{id}.md"
  evolve_stages: [TDD]
```
→ 读 `element-types/Aggregate.yaml` 拿字段结构，在 TDD 阶段对 AGG-ORDER
做 `merge`（字段级合并，既有字段不动，新增 `supplier_code`），按 `store_path`
产出**合并后的全量 record**（变更字段标 `# ← 本次`），落库。

> 一句话：**atomic-change-registry**（认出变化）→ **change-element-mapping**
> （算出影响谁、沿哪条关系）→ **relations**（关系属性名落到实例）→
> **element-type-registry + element-types**（拿身份与 schema 产出全量 record）。

## 4. 演化与版本规则
- 跨阶段要素（`evolve_stages` 非空，共 10 个）：同 id 跨阶段 `merge` 字段级合并，
  不新建 record。其余要素只维护最新态。
- 仅 `OriginalRequirement` 有 `version` 字段；其余演进经 `lineage.triggered_by` 追踪。
- 资产库恒为全量最新记录；1→n 产出**合并后全量 record**，不产 diff/patch 指令。

## 5. 暂缓清单（占位，不在本阶段产）
- 要素：`TestScenario` / `TestCase` / `TestData`（待 ia-test-design 启用）。
- 关系：6 条测试关系（见 `relations.yaml` 的 `deferred_relations`）。
- 启用时同构追加，不回改既有 25 类与 39 条关系。

## 6. 一致性门禁（改本目录后必须全绿）
1. **三方属性名对齐**：每条关系，`relations.source_property` ==
   对应 `element-types` 关系字段名 == 引用它的 `change-mapping.reverse_via`。
2. **id 闭包**：`atomic-change-registry` 的 23 个 id ==
   `change-element-mapping` 的 23 个 `change_id`；所有 `element_type`
   ∈ 25 类 ∪ 非要素白名单 {错误码字典, 前端模块, 外部APP要素, 外部订阅方, 任意要素}。
3. **ref 有效**：每个 `ref: "seq:N"` 的 N 必在 `relations.yaml` 的 seq 集合内。
4. **计数**：registry 恰 25 类；`evolve_stages` 非空恰 10；`always_affected` 恰 2；
   relations 恰 39 条。

门禁脚本见 `consistency_gate.py`，作为 CI 卡口随同步脚本一起跑。
