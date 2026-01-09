# Blueprint Contract: [FEATURE NAME]

**Status**: Draft
**Plan Ref**: `specs/[branch]/plan.md`

## 1. Structure Manifest (文件清单)
> **追踪**: 记录基于 Plan 结构生成的物理文件。

| Category  | File Path                       | Responsibility (Mapped to Plan) |
| :-------- | :------------------------------ | :------------------------------ |
| **Types** | `src/types/user.ts`             | 定义 UserInput 和 User 实体     |
| **API**   | `src/api/user_controller.ts`    | 定义 RESTful 接口签名           |
| **Tests** | `tests/unit/test_user_model.ts` | 对应 User Story 1 的测试桩      |

## 2. Interface Signatures (Snapshot)
> **契约快照**: 在此列出 3-5 个最核心的函数/类签名（无需列出所有，仅供快速Review）。

```typescript
// Example Snapshot
interface IUserService {
  register(input: CreateUserDto): Promise<User>;
  // throws DuplicateEmailError
}
```

## 3. Test Scaffolding Plan

> **测试覆盖率映射**: 确保 Spec 中的每个 Scenario 都有归宿。

| **User Story** | **Scenario**           | **Mapped Test Function**         |
| -------------- | ---------------------- | -------------------------------- |
| Story 1        | 1.1 Valid Registration | `test_register_success()`        |
| Story 1        | 1.2 Duplicate Email    | `test_register_duplicate_fail()` |

## 4. Verification

> 在进入 Task 阶段前，请确认：

- [ ] 类型定义文件无语法错误。
- [ ] 测试文件可以运行（并按预期失败）。
- [ ] 接口签名完全满足 `api.md` 的输入输出要求。

