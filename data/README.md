# data/ — 数据说明

纯数据目录，不建双件。三份 CSV 是 2026 Q3 的产出快照。

## 文件

| 文件 | 行数 | 说明 |
|---|---|---|
| `final_leads.csv` | 160 | 完整线索清单：公司、地址、融资额、域名、业务、负责人、职务、邮箱、状态 |
| `scored.csv` | 160 | 同上 + 五维打分（`Score` / `Reasons` / `Excluded`） |
| `top20.csv` | 20 | 人工排除后按分数排序的优先联系名单 |

## 列定义

| 列 | 说明 |
|---|---|
| `Company` | 品牌名（非 Form D 的法定名） |
| `LegalName` | Form D 申报的法定实体名 |
| `AmountM` | 实际融资额，单位百万美元，取自 `TOTALAMOUNTSOLD` |
| `Domain` | 官网域名，未确认时为空 |
| `Business` | 一句话中文业务描述，来自官网实访 |
| `Contact` / `Title` | 负责人姓名与职务，未找到时为空 |
| `Email` | 页面公开邮箱，未找到时为空 |
| `Status` | `verified` / `partial` / `not_found` |
| `Score` | 五维打分，仅 `scored.csv` / `top20.csv` 有 |
| `Excluded` | 人工剔除标记，`True` 表示上市公司 / 投资载体 / 同行 |

## 重新生成

```powershell
.\scripts\fetch_formd.ps1 -Quarter 2026q3 -OutDir .\data
.\scripts\filter_formd.ps1 -DataDir .\data\2026q3\2026Q3_d -OutCsv .\data\candidates.csv
# 按 15 家切批后逐批跑 probe_domains.ps1，再合并
.\scripts\score_leads.ps1 -InputCsv .\data\final_leads.csv -OutCsv .\data\scored.csv -TopN 20
```

## 不放进来的东西

- **Form D 原始 TSV**：单季约 10 MB，已列入 `.gitignore`，用 `fetch_formd.ps1` 现取。
- **分批中间结果**：每次探测的 `batch_*_result.csv` 只在本地保留。

## 数据口径提醒

- 融资额是**申报时的累计售出额**，不等于媒体披露的「本轮融资」。
- `not_found` 的 8 家不是不存在，是公开渠道无法确认官网（多为投资载体）。
- 邮箱多数是 `support@` / `info@` 这类通用地址，不等于能触达决策人。
