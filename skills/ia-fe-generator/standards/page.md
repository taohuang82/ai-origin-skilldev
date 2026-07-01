# page — 页面要素结构规范（page-structure）

## 适用范围
Page 要素 FE 阶段字段：domain、page_type、route_path、realizes_sub_features。

## 规则定义
### 页面类型（page_type）
- 取值示例：列表页 / 表单页 / 详情页 / 看板页 / 弹窗 / 向导页。
- 一页一主类型。
### 路由（route_path）
- 以 `/` 开头，kebab-case，全局唯一。
### 实现子特性（realizes_sub_features）
- 必填、非空；每项必须是已存在的 SubFeature（realizes 关系 seq28，单端存于 Page 侧）。
- 一页可实现多个子特性；一个子特性可被多页实现。

## 禁止事项
- 禁止 FE 阶段产 fields/used_components/called_apis/fool_proofing/pageflow（留 PRD）。
- 禁止 route_path 重复。
- 禁止 realizes_sub_features 指向不存在的子特性。

## 验证检查点
- [ ] page_type 单一明确
- [ ] route_path 以 / 开头且唯一
- [ ] realizes_sub_features 非空且 ∈ SubFeature
- [ ] 未越界产出 PRD 字段

## 输出骨架
| 页面 | 类型 | 路由 | 实现子特性 |
|---|---|---|---|
| 订单列表 | 列表页 | /orders | FR-001, FR-002 |
