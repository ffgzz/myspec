# Knowledge Pack (auto-generated)

**Query**: 资产借用审批流程：经理审批->资产管理员审批->通过后修改资产状态

## Top Evidence (for Spec)

### [E1] 核心验证逻辑（伪代码） > 常见边缘案例 > 6. 临时借用  (hybrid=0.030777 | vec_rank=4 | bm25_rank=6)
Namespace: `default`
Source: `D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md`
Chunk ID: `aec2e4aad077`

**场景：** 员工需要临时借用设备（如参加展会需要投影仪）。

**处理策略：**
- 分配时标记"临时借用"，设置预期归还日期
- 到期前自动提醒归还
- 超期未还自动升级提醒（发送给经理和 IT 部门）

---

### [E2] 企业资产管理系统 - 核心领域知识 > 资产生命周期状态 > 四种核心状态 > 4. 已报废（Retired）  (hybrid=0.030415 | vec_rank=10 | bm25_rank=2)
Namespace: `default`
Source: `D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md`
Chunk ID: `d0739f5408e4`

**定义：** 资产已达生命周期终点，不再使用，终态不可逆。

**特征：**
- 物理状态：已处置、回收或销毁
- 系统状态：只读，不可修改状态
- 记录保留：永久保留用于审计和资产统计

**报废原因：**
- 使用年限到期（如：笔记本使用 5 年）
- 严重损坏无法维修或维修成本过高
- 技术过时，无法满足业务需求
- 丢失或被盗（记录责任人）

**处置流程：**
- 数据安全擦除（防止信息泄露）
- 资产价值评估（是否可转售或回收）
- 报废审批和记录
- 物理销毁或转售给认证回收商

**重要规则：**
- 已报废的资产不能恢复到任何其他状态
- 报废决策需要管理员权限
- 报废记录必须包含：报废原因、报废人、报废时间

---

### [E3] 核心验证逻辑（伪代码） > 关键业务规则 > 规则 4：员工离职强制归还（强制）  (hybrid=0.030092 | vec_rank=13 | bm25_rank=1)
Namespace: `default`
Source: `D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md`
Chunk ID: `5fcff90e1bb8`

**内容：** 员工离职前必须归还所有资产，否则阻止离职流程。

**实现流程：**
1. HR 系统发起离职申请
2. 自动查询该员工持有的所有资产
3. 如有未归还资产，发送通知给：
   - 员工本人（邮件 + 系统通知）
   - 员工直属经理
   - IT 部门管理员
4. 所有资产归还后，系统自动解除阻止
5. 完成离职流程

**例外处理：**
- 资产丢失：填写资产丢失报告，说明原因，由管理员审批后可继续离职
- 资产在维修：等待维修完成后归还，或由 IT 部门接管维修责任

### [E4] 企业资产管理系统 - 核心领域知识 > 核心概念 > 2. 员工（Employee）  (hybrid=0.029418 | vec_rank=9 | bm25_rank=7)
Namespace: `default`
Source: `D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md`
Chunk ID: `987ae8571207`

资产的使用者和临时保管人（注意：员工不是资产的所有者，资产所有权属于公司）。

**关键信息：**
- **员工ID**：唯一标识符，通常与 HR 系统同步（如：EMP001234）
- **姓名**：用于搜索和显示，需支持中英文
- **部门**：IT部、研发部、销售部等
  - 用于资产分配策略（不同部门不同配置标准）
  - 用于统计报表（各部门资产使用情况）
- **在职状态**：在职/离职
  - 离职员工必须归还所有资产才能完成离职流程
  - 离职后的员工记录保留（用于历史追溯）

**业务规则：**
- 只有"在职"状态的员工才能被分配新资产
- 员工变更部门时，可能需要重新评估资产分配
- 员工离职时，系统必须自动检查是否有未归还资产

### [E5] 核心验证逻辑（伪代码） > 典型业务场景 > 场景 2：设备故障报修  (hybrid=0.029412 | vec_rank=8 | bm25_rank=8)
Namespace: `default`
Source: `D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md`
Chunk ID: `179557af8c6f`

```
1. 员工李四发现笔记本无法开机
2. 提交报修申请：故障描述、紧急程度
3. IT 管理员接单：
   - 将资产状态从"已分配"改为"维修中"
   - 创建维修单，分配给维修人员
   - 如需替代设备，从库存分配临时设备给李四
4. 维修完成后：
   - 维修人员更新维修单状态
   - IT 管理员质检通过
   - 归还给李四（状态：已分配），或回库（状态：库存中）
5. 如临时设备已分配，提醒李四归还
```

### [E6] 核心验证逻辑（伪代码） > 常见边缘案例 > 5. 跨部门调动  (hybrid=0.029380 | vec_rank=1 | bm25_rank=17)
Namespace: `default`
Source: `D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md`
Chunk ID: `3f5635889ab5`

**场景：** 员工从销售部调到研发部，资产配置需求变化。

**处理策略：**
- 系统提示：该员工已调岗，建议重新评估资产配置
- IT 管理员可选择：保持现有资产 / 更换为新部门标准配置
- 记录调岗信息到审计日志

### [E7] 核心验证逻辑（伪代码）  (hybrid=0.029010 | vec_rank=7 | bm25_rank=11)
Namespace: `default`
Source: `D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md`
Chunk ID: `003189282b12`

def can_assign_asset(asset, employee):
    # 验证1：资产必须存在
    if not asset:
        return False, "资产不存在"
    
    # 验证2：资产状态必须为"库存中"
    if asset.status != "库存中":
        if asset.status == "已分配":
            return False, f"资产已分配给{asset.current_employee}，请先归还"
        elif asset.status == "维修中":
            return False, "资产正在维修，预计{asset.repair_end_date}完成"
        elif asset.status == "已报废":
            return False, "资产已报废，无法分配"
    
    # 验证3：员工必须在职
    if not employee or employee.status != "在职":
        return False, "员工不存在或已离职"
    
    # 验证4：检查员工是否超过持有限制（业务策略）
    current_count = count_employee_assets(employee.id, asset.type)
    if current_count >= MAX_LIMIT:
        return False, f"员工已持有{current_count}个{asset.type}，超过限制"
    
    return True, "验证通过"
```

---

### [E8] 核心验证逻辑（伪代码） > 常见边缘案例 > 3. 资产丢失  (hybrid=0.028629 | vec_rank=2 | bm25_rank=20)
Namespace: `default`
Source: `D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md`
Chunk ID: `3a307e5f54a6`

**场景：** 员工报告资产丢失（被盗、遗失等）。

**处理策略：**
- 创建"资产丢失报告"，记录：丢失时间、地点、经过
- 标记资产状态为"已报废"，原因："丢失"
- 记录责任人（该员工）
- 根据公司政策决定是否需要赔偿

## Evidence Trace Template（可直接复制到 spec 末尾）
- [E1] 核心验证逻辑（伪代码） > 常见边缘案例 > 6. 临时借用 — D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md
- [E2] 企业资产管理系统 - 核心领域知识 > 资产生命周期状态 > 四种核心状态 > 4. 已报废（Retired） — D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md
- [E3] 核心验证逻辑（伪代码） > 关键业务规则 > 规则 4：员工离职强制归还（强制） — D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md
- [E4] 企业资产管理系统 - 核心领域知识 > 核心概念 > 2. 员工（Employee） — D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md
- [E5] 核心验证逻辑（伪代码） > 典型业务场景 > 场景 2：设备故障报修 — D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md
- [E6] 核心验证逻辑（伪代码） > 常见边缘案例 > 5. 跨部门调动 — D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md
- [E7] 核心验证逻辑（伪代码） — D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md
- [E8] 核心验证逻辑（伪代码） > 常见边缘案例 > 3. 资产丢失 — D:/文件/spec实验/my-spec-cli/.myspec/kb/raw/domain-knowledge.md
