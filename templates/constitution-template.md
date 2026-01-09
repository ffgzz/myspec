# Project Constitution (项目宪法)



## Core Principles（核心原则）

### [PRINCIPLE_1_NAME]

<!-- Example: I. Library-First -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Example: Every feature starts as a standalone library; Libraries must be self-contained, independently testable, documented; Clear purpose required - no organizational-only libraries -->

### [PRINCIPLE_2_NAME]

<!-- Example: II. CLI Interface -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Example: Every library exposes functionality via CLI; Text in/out protocol: stdin/args → stdout, errors → stderr; Support JSON + human-readable formats -->

### [PRINCIPLE_3_NAME]

<!-- Example: III. Test-First (NON-NEGOTIABLE) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Example: TDD mandatory: Tests written → User approved → Tests fail → Then implement; Red-Green-Refactor cycle strictly enforced -->

### [PRINCIPLE_4_NAME]

<!-- Example: IV. Integration Testing -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Example: Focus areas requiring integration tests: New library contract tests, Contract changes, Inter-service communication, Shared schemas -->



## [SECTION_2_TITLE]
[SECTION_2_CONTENT]



## [SECTION_3_TITLE]
[SECTION_3_CONTENT]



## [SECTION_4_TITLE]
[SECTION_4_CONTENT]



## 核心开发工作流 (Contract-First SDD)

本项目严格执行 **Knowledge-Augmented SDD** 流程。为确保代码质量与可维护性，任何功能开发必须经历以下五个阶段：

1.  **Define (定义)**:
    * 产出: ` 01-spec.md `
    * 要求: 必须包含 **User Journey Map (用户旅程图)**，明确交互流程。
2.  **Plan (计划)**:
    * 产出: ` 02-plan.md `
    * 要求: 重点分析 **数据流向 (Data Flow)** 和 **状态机 (State Machine)**。
3.  **Blueprint (蓝图)**: **[关键核心]**
    * 产出: ` 03-blueprint.md `
    * 内容: **纯接口定义 (Interfaces)、类型声明 (Types) 和 测试桩 (Test Stubs)**。
    * **禁令**: 在此阶段严禁编写任何业务实现逻辑。
4.  **Tasks (拆解)**:
    * 产出: ` 04-tasks.md `
    * 策略: 按 "骨架(Skeleton) -> 逻辑(Logic) -> 验证(Verify)" 进行分组。
5.  **Build (实施)**:
    * 产出: 源代码
    * 要求: 严格填空，必须通过 Blueprint 中定义的所有测试。



## AI 协作公约 (Agent Protocols)

本公约约束 AI 智能体在本项目的行为模式。

### 1. 宪法至上 (Constitution First)
* 在执行任何操作（Coding, Planning, Refactoring）前，**必须隐式检查** `context/constitution.md`。
* 任何生成的代码或计划如果与宪法条款冲突，必须在输出前自我修正。

### 2. 严禁臆造 (No Hallucinations)
* **事实核查**: 禁止引用不存在的文件路径或错误的函数签名。

### 3. 代码完整性 (Code Integrity)
* **禁止省略**: 在实施阶段，严禁输出 `// ... rest of code`、`// implementation here` 或 `pass`（除非是接口定义）。交付的代码必须是完整的、可编译/可运行的。
* **原子化修改**: 编辑文件时，必须确保不破坏文件中原有的、与当前任务无关的逻辑。

### 4. 安全底线 (Security Baseline)
* **禁止硬编码**: 严禁在代码中直接写入 API Key、数据库密码或私钥。必须通过环境变量或配置文件注入。
* **输入防御**: 假设所有外部输入（API 参数、用户表单）都是恶意的，必须在系统边界进行严格验证。

### 5. 可读性与文档 (Readability)
* **Docstrings**: 所有公共接口（Public Interface）必须包含清晰的文档字符串，说明参数、返回值和潜在异常。
* **意图注释**: 复杂逻辑的注释应解释“为什么这么做”（Why），而不是“在做什么”（What）。

### 6. 测试驱动 (Test Adherence)
* **测试神圣**: 严禁修改测试代码来适应错误的实现逻辑（除非确认测试本身有误）。
* **验证闭环**: 提交代码前，必须确保其能够通过 Blueprint 阶段定义的所有测试桩。

### 7. 破坏性操作预警 (Destructive Action Warning)
* 在执行不可逆操作（如删除文件、重构核心架构、大规模升级依赖）前，必须在对话中明确列出风险并征求用户同意。



**版本号**: [CONSTITUTION_VERSION] | **生效日期**: [EFFECTIVE_DATE] | **最后修订日期**: [LAST_AMENDED_DATE]
<!-- Example: 版本号: 2.1.1 | 生效日期: 2025-06-13 | 最后修订日期: 2025-07-16 -->