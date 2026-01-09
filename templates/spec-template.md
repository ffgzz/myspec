# Specification: [FEATURE NAME]

**Feature Branch**: `[###-feature-name]`
**Created**: [DATE]
**Status**: Draft
**Input**: User description: "$ARGUMENTS"

## 1. Domain Dictionary (Ubiquitous Language)
> **TDD 基础**: 在此定义的 Code Term 必须在后续的代码实现和测试脚本中严格遵守。

| Business Concept (业务概念) | Code Term (代码命名) | Definition (定义)                        |
| :-------------------------- | :------------------- | :--------------------------------------- |
| [例如: 购物车]              | `UserCart`           | [用户暂存商品的容器，Session 级生命周期] |
| [例如: 结算]                | `checkout()`         | [将 Cart 转换为 Order 的动作]            |

## 2. User Stories & Acceptance Scenarios (Test Contracts)
<!-- 

每个用户故事都必须是可独立测试的 —— 这意味着如果只实现其中一个，你仍应拥有一个能提供价值的可行 MVP（最小可行产品）。为每个故事分配优先级（P1、P2、P3 等），其中P1为最关键的。

将每个故事视为一个独立的功能片段，它应能：

- 独立开发
- 独立测试
- 独立部署
- 独立向用户演示

-->

### User Story 1 - [Brief Title] (Priority: P1)

**As a** [Role]
**I want to** [Action]
**So that** [Value]

**Why this priority**: [Explain the value and why it has this priority level]

#### Scenario 1.1: [Scenario Name]
> **Test Type**: `[Unit/Integration/E2E]`
> **Tags**: `@core`, `@happy-path`

* **Given** [初始状态/前置条件，例如：UserCart 中有 1 个商品]
* **And** [可选：附加条件，例如：商品库存充足]
* **When** [触发动作，例如：调用 checkout() 方法]
* **Then** [预期结果，例如：生成 Order 对象]
* **And** [副作用，例如：UserCart 被清空]

---

### User Story 2 - [Brief Title] (Priority: P2)

**As a** [Role]
**I want to** [Action]
**So that** [Value]

**Why this priority**: [Explain the value and why it has this priority level]

#### Scenario 2.1: [Scenario Name]

> **Test Type**: `[Unit/Integration/E2E]`
> **Tags**: `@core`, `@happy-path`

* **Given** [初始状态/前置条件，例如：UserCart 中有 1 个商品]
* **And** [可选：附加条件，例如：商品库存充足]
* **When** [触发动作，例如：调用 checkout() 方法]
* **Then** [预期结果，例如：生成 Order 对象]
* **And** [副作用，例如：UserCart 被清空]

---

### User Story 3 - [Brief Title] (Priority: P3)

**As a** [Role]
**I want to** [Action]
**So that** [Value]

**Why this priority**: [Explain the value and why it has this priority level]

#### Scenario 1.1: [Scenario Name]

> **Test Type**: `[Unit/Integration/E2E]`
> **Tags**: `@core`, `@happy-path`

* **Given** [初始状态/前置条件，例如：UserCart 中有 1 个商品]
* **And** [可选：附加条件，例如：商品库存充足]
* **When** [触发动作，例如：调用 checkout() 方法]
* **Then** [预期结果，例如：生成 Order 对象]
* **And** [副作用，例如：UserCart 被清空]

---

*[Adjust the quantity as needed, each with an assigned priority]*

### Edge Cases
- What happens when [boundary condition]?
- How does system handle [error scenario]?

​	[Adjust the quantity as needed]

## 3. Functional Requirements (Derived)
> 从上述场景中提炼的系统行为规则（下面仅为示例）。

* **FR-001**: System MUST [specific capability, e.g., "allow users to create accounts"]
* **FR-002**: System MUST [specific capability, e.g., "validate email addresses"]  
* **FR-003**: Users MUST be able to [key interaction, e.g., "reset their password"]
* **FR-004**: System MUST [data requirement, e.g., "persist user preferences"]
* **FR-005**: System MUST [behavior, e.g., "log all security events"]

​	[Adjust the quantity as needed]

## 4. Non-Functional Requirements (Constraints)
* **NFR-001**: [例如: API 响应时间 < 200ms]

* **NFR-002**: [例如: 所有 PII 数据必须加密存储]

  [Adjust the quantity as needed]

## 5. Key Entities (include if feature involves data)
> 涉及的核心业务对象（不涉及具体数据库实现，仅描述业务属性）。

* **[Entity 1]**: [What it represents, key attributes]

* **[Entity 2]**: [What it represents, relationships]

  [Adjust the quantity as needed]

## 6. Success Criteria (Mandatory)
> Define measurable, technology-agnostic outcomes.

* **SC-001**: [Measurable metric, e.g., "Users can complete task in < 2 mins"]
* **SC-002**: [Performance metric, e.g., "Handle 1000 concurrent users"]
* **SC-003**: [Business metric, e.g., "Reduce support tickets by 50%"]

​	[Adjust the quantity as needed]