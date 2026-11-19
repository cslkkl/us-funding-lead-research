# 运行时数据目录

本目录用于存放运行时产生的数据，**不入库**。

## 子目录结构（跑完脚本后自动出现）

```
data/
├── 2026Q3_d/            # fetch_formd.ps1 解压的季度数据集
├── candidates.csv       # filter_formd.ps1 输出的候选清单
└── batch_*_result.csv   # probe_domains.ps1 的批次结果
```

## 为什么留空

数据是一次运行的产物，不是工具的一部分：

- 换季度就要重跑，留着旧数据会误导
- Form D 单季原始 TSV 约 10 MB，不适合入库
- 不同使用者的目标客户不同，硬编码名单没有通用价值

## 想看作什么样

一次完整运行的结果放在 [../examples/](../examples/README.md)，可作格式参考。

## 从零跑一遍

```powershell
.\scripts\fetch_formd.ps1 -Quarter 2026q3 -OutDir .\data
.\scripts\filter_formd.ps1 -DataDir .\data\2026Q3_d -OutCsv .\data\candidates.csv
# 按 15 家切批，逐批跑 probe_domains.ps1
.\scripts\score_leads.ps1 -InputCsv .\data\final_leads.csv -OutCsv .\data\scored.csv
.\scripts\build_report.ps1 -LeadsCsv .\data\final_leads.csv -ScoredCsv .\data\scored.csv
```
