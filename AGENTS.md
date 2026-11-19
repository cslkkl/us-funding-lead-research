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
- 数据说明 → [data/README.md](data/README.md)

## 常用命令

```powershell
# 下载季度数据集（约 3.5 MB）
.\scripts\fetch_formd.ps1 -Quarter 2026q3 -OutDir .\data

# 三层过滤
.\scripts\filter_formd.ps1 -DataDir .\data\2026q3\2026Q3_d -OutCsv .\data\candidates.csv

# 域名探测（建议按 15 家切批并行）
.\scripts\probe_domains.ps1 -InputCsv .\data\batch_0.csv -OutCsv .\data\batch_0_result.csv

# 打分排序
.\scripts\score_leads.ps1 -InputCsv .\data\final_leads.csv -OutCsv .\data\scored.csv -TopN 20
```

## 检查选择

- 改文档 → 链接校验 `check-markdown-links.py <repo> --fragments --refs`
- 改脚本 → PowerShell 语法校验（`[System.Management.Automation.PSParser]::Tokenize`）
- 改数据 → 核对行数与状态分布是否与 `references/field-notes.md` 一致

## 验证快照

- 数据基线：160 家候选 / 148 家确认官网 / 110 家负责人 / 90 家邮箱（2026 Q3）
- 脚本：4 个均通过 PSParser 语法校验，`score_leads.ps1` 实跑验证
- 文档：链接校验 0 error

## 待办

- [ ] 补充 2026 Q4 数据集跑一遍，验证脚本在新季度可用
- [ ] `probe_domains.ps1` 目前的团队页抓取是正则近似，误判率未统计

## 活跃坑

- **域名不等于法定名**：约 20% 需靠新闻稿确认，详见 [pitfalls.md](references/pitfalls.md) 第 4 条
- **停放页会返回 200**：五条判据必须全加，否则把域名商页面当官网
- **`TOTALAMOUNTSOLD` 才是实际到账**，别用 `TOTALOFFERINGAMOUNT`（计划额）
- **PowerShell 字符串里变量紧跟冒号**会触发作用域解析错误，需用 `${var}` 包裹
