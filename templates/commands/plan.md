---
description: 基于Spec文档和用户指定的技术栈，制定详细的技术实现方案 (Technical Design)。
handoffs:
  - label: 生成蓝图契约
    agent: speckit.blueprint
    prompt: 生成最终的开发蓝图契约
---

## 执行代理要求（强制）

本命令**必须由子代理 `architect_agent` 执行**，主线程不得直接编写技术方案。

执行规则：
1. 立即将本命令的全部工作委派给 `architect_agent`
2. 必须以 spec.md 为唯一需求来源，不得发明需求
3. 主线程只负责输出 plan.md / api.md / data-model.md / quickstart.md 的生成结果与路径
4. 若未成功委派，则必须停止并改为委派后再继续

## User Input

```text
$ARGUMENTS
```

**Critical**: 用户输入 (`$ARGUMENTS`) 包含了本项目的 **技术栈偏好**（如框架、语言、数据库）。你必须严格基于这些约束来制定方案。

## Preflight Analysis

在执行生成前，读取当前分支下的 `spec.md` 和用户输入：

1. **Tech Stack Analysis**: 提取和解析用户输入，确定 Technical Stack 的具体版本和依赖。
2. **Requirement Mapping**: 识别 `spec.md` 中的 User Stories，规划技术实现方案。

## Execution Steps

### 1. Initialization

执行脚本 `scripts/setup-plan.ps1`。

- 该脚本会将 `plan-template.md` 复制为 `plan.md`，并创建空的 `api.md`, `data-model.md`, `quickstart.md`文档。

### 2. Technical Design Drafting (技术方案起草)

按顺序填充并写入以下文件：

#### A. Architecture Strategy (`plan.md`)

读取并填充 `plan.md` 模板，遵循模板结构：

- **Executive Summary**: 必须填写 Language/Version, Primary Dependencies, Storage, Testing 等字段。
- **Architecture Decisions (ADR)**: 记录关键技术决策及理由。
- **High-Level Architecture**: 使用 Mermaid 绘制组件图。
- **Implementation Strategy**: 将 Spec 中的 Story 映射为技术实现方案（不要包含具体代码，plan这一步仅为技术方案设计，还未具体到代码实现）。
- **Security & Scalability**：根据上面设计的技术方案，填写项目需要的安全和可扩展性方面的内容
- **Project Structure**：根据上面设计的技术方案，决定项目的结构。**注意，项目结构必须要遵循使用的技术栈，结构必须完整！**例如：前端使用React+TS+Vite，则项目结构需要遵循Vite构建的React+TS项目的结构。**其他技术栈则遵循各自的项目结构，可在技术栈对应的结构上根据实际情况进行扩展，但基础结构必须得遵循技术栈的来（例如：这个React+TS+Vite项目，可以添加api目录存放请求函数等等，但是基础的main.tsx，App.tsx、index.html等等这些是必须要有的！）**

  ```
  my-app/
  ├── .gitignore
  ├── eslint.config.js
  ├── index.html
  ├── package.json
  ├── package-lock.json
  ├── README.md
  ├── tsconfig.app.json
  ├── tsconfig.json
  ├── tsconfig.node.json
  ├── vite.config.ts
  ├── node_modules/
  ├── public/
  │   └── vite.svg
  └── src/
      ├── App.css
      ├── App.tsx
      ├── index.css
      ├── main.tsx
      └── assets/
          └── react.svg
  ```

#### B. Data Model (`data-model.md`)

**没有模板**，请直接按照以下标准格式生成：

1. **Core Entities**: 定义实体接口 (TypeScript/Python style)。包含 Fields (Name, Type, Description) 和 Validation Rules。
2. **Data Flow**: 描述数据处理管道（Processing Pipeline），例如：Input Capture -> Processing -> Storage。
3. **Error Handling**: 定义错误类型 (Error Types) 和恢复机制 (Recovery Mechanisms)。 *参考风格*: 实体定义要像 API Schema 一样严谨，包含字段类型和必填项。

#### C. API Contract (`api.md`)

**没有模板**，请基于 RESTful 最佳实践生成：

1. **Overview**: Base URL, Authentication 方式。
2. **Endpoints**: 按资源分组。每个接口必须包含：
   - **Method & Path**: (e.g., `POST /api/v1/assets`)
   - **Description**: 关联的 User Story。
   - **Request Body**: JSON 示例或 Schema。
   - **Response**: 成功 (200) 和 失败 (4xx/5xx) 的 JSON 示例。
3. **Error Codes**: 定义通用的错误码列表。

#### D. Quickstart Guide (`quickstart.md`)

**没有模板**，请直接按照以下标准格式生成：

1. **Overview**: 一句话描述该功能。
2. **Prerequisites**: 需要安装的工具 (Node/Docker/Python)。
3. **Setup Instructions**:
   - Install Dependencies (e.g., `npm install`)
   - Environment Config (e.g., `.env` 示例)
   - Start Server (e.g., `npm run dev`)
4. **Usage Guide**: 简述如何手动测试核心功能（配合 Spec 中的 Happy Path）。

###  3. Constitution Check（宪法）

起草完成后执行**宪法检查**，检查当前技术方案与`context/constitution.md`宪法中的所有规定是否存在冲突，若有冲突修改上述文档中的对应部分，重新运行宪法检查，直到所有项都通过再进行下一步（最多迭代 3 次，若三次后还失败则停止当前命令执行并报告用户仍存在冲突的点）。

## Quality Checks

在完成前自查，如有问题更新文档以解决问题：

- [ ] `plan.md` 中的技术栈是否与用户输入一致？
- [ ] `plan.md` 中是否不包含具体代码？
- [ ] `api.md` 是否覆盖了 `spec.md` 中所有的交互需求？
- [ ] `data-model.md` 中的实体是否与 Domain Dictionary (Spec) 一致？
- [ ] `quickstart.md` 中的命令是否在该技术栈下真实有效？

## Output

汇报生成的文件路径及架构摘要。
