# us-funding-lead-research — 维护索引

## 全局规则

- 架构与不变约束 → [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 方法与流程 → [SKILL.md](SKILL.md)
- 域名探测细则 → [references/domain-playbook.md](references/domain-playbook.md)
- 踩坑记录 → [references/pitfalls.md](references/pitfalls.md)
- 实测数据分布 → [references/field-notes.md](references/field-notes.md)
- 一次完整案例 → [references/my-answer.md](references/my-answer.md)
- 脚本索引 → [scripts/README.md](scripts/README.md)
- 参考文档索引 → [references/README.md](references/README.md)
- 数据说明 → [examples/README.md](examples/README.md)

## 常用命令

```powershell
# 自检（先跑这个）
.\scripts\selftest.ps1
.\scripts\selftest.ps1 -Quarter 2026q1     # 含端到端

# 四步流程
.\scripts\fetch_formd.ps1 -Quarter 2026q3 -OutDir .\data
.\scripts\filter_formd.ps1 -DataDir .\data\2026Q3_d -OutCsv .\data\candidates.csv
.\scripts\probe_domains.ps1 -InputCsv .\data\batch_0.csv -OutCsv .\data\batch_0_result.csv
.\scripts\score_leads.ps1 -InputCsv .\data\final_leads.csv -OutCsv .\data\scored.csv -TopN 20
.\scripts\build_report.ps1 -LeadsCsv .\data\final_leads.csv -ScoredCsv .\data\scored.csv
```
## 检查选择

- 改文档 → 链接校验 `check-markdown-links.py <repo> --fragments --refs`
- 改脚本 → PowerShell 语法校验（`[System.Management.Automation.PSParser]::Tokenize`）
- 改数据 → 核对行数与状态分布是否与 [field-notes.md](references/field-notes.md) 一致

## 验证快照

- 自检：`selftest.ps1` 22 项全部 PASS
- 脚本：6 个均通过 PSParser 语法校验
- 跨季度：同一脚本跑过 Q3（15,952 条 → 160 家）与 Q1（15,734 条 → 181 家），无需修改
- 文档：链接校验 0 error
- 数据基线见 [examples/README.md](examples/README.md)
## 待办

- [ ] 补充 2026 Q4 数据集跑一遍，验证脚本在新季度可用
- [ ] `probe_domains.ps1` 目前的团队页抓取是正则近似，误判率未统计

## 活跃坑

- **域名不等于法定名**：约 20% 需靠新闻稿确认，详见 [pitfalls.md](references/pitfalls.md) 第 4 条
- **停放页会返回 200**：五条判据必须全加，否则把域名商页面当官网
- **`TOTALAMOUNTSOLD` 才是实际到账**，别用 `TOTALOFFERINGAMOUNT`（计划额），详见 [field-notes.md](references/field-notes.md)
- **PowerShell 字符串里变量紧跟冒号**会触发作用域解析错误，需用 `${var}` 包裹
