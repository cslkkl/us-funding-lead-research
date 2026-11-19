# us-funding-lead-research 架构说明

本文件只写「不变的设计决策与约束」。步骤式做法见 [SKILL.md](../SKILL.md)，踩坑见 [references/pitfalls.md](../references/pitfalls.md)。

## 核心目标

从「谁刚拿到钱」推导到「谁需要我们」，产出一份可发信的客户线索表。

## 根本约束（不可破坏）

### 1. 全量口径必须来自 SEC

媒体是发现工具，不是全量来源。任何声称「覆盖全美」的名单，如果不能追溯到 Form D 申报，就不成立。

**原因**：美国所有非公开发行融资都必须向 SEC 申报。这是唯一有法律强制力的口径，且可批量下载。

**推论**：`fetch_formd.ps1` 与 `filter_formd.ps1` 是整个流程的起点，不允许跳过直接进入域名探测。

### 2. 三层过滤的顺序不可调换

```
行业（Other Technology + Computers）
  → 州（美国境内白名单）
    → 金额（TOTALAMOUNTSOLD 500 万–2500 万美元）
```

**原因**：Q3 全量 15,952 条里，`Pooled Investment Fund` 占 10,487 条（65.7%）。先按金额筛会把大量基金带进来，再去重成本极高。必须先剔行业。

**反例**：先按金额筛 → 得到数百条基金 → 再人工判断哪些是真公司 → 效率崩塌。

### 3. 用 `TOTALAMOUNTSOLD`，不用 `TOTALOFFERINGAMOUNT`

前者是实际到账，后者是计划融资额。

**原因**：只有前者代表钱真的到账，公司才有预算买服务。计划额会系统性高估。

### 4. 业务描述必须来自官网实访

Form D 只有法定名与金额，**没有业务描述**。

**原因**：法定名与真实业务可能完全无关。`LONE PALM LABS, INC.` 实际是拍照 app（品牌 Retro）。

**推论**：任何未经官网确认的业务描述都不可信，状态必须标 `not_found` 而非猜测填充。

### 5. 邮箱只取页面原文

不允许拼 `firstname@domain` 这类猜测地址。

**原因**：bounce 会损伤发信域名信誉，且对方永远收不到。留空的信息价值高于错误的填充。

**代价**：公开渠道只能拿到 90/160 个邮箱，其中仅 18 个是个人地址。这是已知上限，不是缺陷。

### 6. 模型排序不能替代人工判断

打分模型只处理可量化的维度。三类必须人工剔除：

- 上市公司（有股票代码）
- 投资载体 / SPV / 控股公司
- 同行（做 AI 咨询或外包交付的）

**原因**：模型从描述文本里读不出「这家已经上市了」。实测 Circle 得分最高（95 分），但它是纽交所上市公司。

## 数据流

```
SEC Form D 季度 zip
  ↓ fetch_formd.ps1（下载 + 解压 + 校验三表）
ISSUERS.tsv + OFFERING.tsv + FORMDSUBMISSION.tsv
  ↓ filter_formd.ps1（按 ACCESSIONNUMBER 关联 + 三层过滤）
candidates.csv（160 家）
  ↓ probe_domains.ps1（域名探测 + 停放页过滤 + 团队页抓取）
batch_N_result.csv（含域名、业务片段、联系人、邮箱）
  ↓ 并行批处理（每批 15 家，同时 4–5 个子智能体）
final_leads.csv（合并去重，状态归一）
  ↓ score_leads.ps1（五维打分 + 人工排除清单）
scored.csv + top20.csv
```

## 关键契约

| 契约 | 值 | 违反后果 |
|---|---|---|
| 关联键 | `ACCESSIONNUMBER` | 三表对不上，公司信息错配 |
| 主发行人标记 | `IS_PRIMARYISSUER_FLAG = "YES"` | 关联到 SPV 子实体而非公司本身 |
| 行业白名单 | `Other Technology` / `Computers` | 混入基金、地产、生物医药 |
| 金额字段 | `TOTALAMOUNTSOLD` | 高估公司实力 |
| 停放页判据 | 5 条（见 playbook） | 把域名商页面当官网 |
| 状态取值 | `verified` / `partial` / `not_found` | 下游无法判断可信度 |

## 防错清单

- [ ] Form D 数据是否来自官方 zip，而非第三方汇总？
- [ ] 三表是否按 `ACCESSIONNUMBER` 正确关联？
- [ ] 是否先剔行业再筛金额？
- [ ] 用的是 `TOTALAMOUNTSOLD` 还是计划额？
- [ ] 域名是否通过停放页五条判据？
- [ ] 同名公司是否核对了城市与业务？
- [ ] 邮箱是否来自页面原文而非拼接？
- [ ] 上市公司、投资载体、同行是否已人工剔除？

## 为什么用 PowerShell

目标用户在 Windows 上工作，`Invoke-WebRequest` 与 `Import-Csv` 无需额外运行时即可完成全部流程。

**代价**：字符串里的变量紧跟冒号会触发作用域解析错误（需 `${var}`），排序负号写法有坑。已在 [AGENTS.md](../AGENTS.md) 活跃坑里记录。
