# scripts/ — 脚本索引

四步流程各一个脚本，按顺序执行。规则层约束见 [AGENTS.md](AGENTS.md)。

## 文件

| 脚本 | 做什么 | 输入 | 输出 |
|---|---|---|---|
| [selftest.ps1](selftest.ps1) | 22 项自检：文件、语法、配置、环境 | `-Quarter`（可选，加则跑端到端） | 控制台 PASS/FAIL |
| [fetch_formd.ps1](fetch_formd.ps1) | 下载解压季度数据集，校验三表 | `-Quarter`、`-OutDir` | `{OutDir}/{Quarter}_d/` |
| [filter_formd.ps1](filter_formd.ps1) | 三表关联 + 三层过滤 + 去重 | `-DataDir`、`-OutCsv`、`-Config` | `candidates.csv` |
| [probe_domains.ps1](probe_domains.ps1) | 域名探测 + 停放页过滤 + 团队页抓取 | `-InputCsv`、`-OutCsv` | `*_result.csv` |
| [score_leads.ps1](score_leads.ps1) | 五维打分 + 人工排除 | `-InputCsv`、`-TopN` | `scored.csv` |
| [build_report.ps1](build_report.ps1) | 生成 HTML 报告并导 PDF | `-LeadsCsv`、`-ScoredCsv`、`-OutDir` | `report/*.html` + `*.pdf` |

## 执行顺序

```
selftest → fetch_formd → filter_formd → probe_domains（按批并行）→ score_leads → build_report
```

## 配置外置

`filter_formd.ps1` 与 `score_leads.ps1` 的门槛值来自 [../config/default.json](../config/default.json)，不在脚本里硬编码。命令行参数可以临时覆盖（如 `-MinAmount`），但长期调整应改配置文件。
## 变更影响路由

| 改这里 | 要同步 |
|---|---|
| `filter_formd.ps1` 的过滤条件 | [SKILL.md](../SKILL.md) 流程节 + [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) 约束 2 |
| `probe_domains.ps1` 的停放页判据 | [references/domain-playbook.md](../references/domain-playbook.md) 判据表 |
| `score_leads.ps1` 的权重 | [SKILL.md](../SKILL.md) 排序模型表 + [references/field-notes.md](../references/field-notes.md) |
| 任一脚本的命令行参数 | 根 [AGENTS.md](../AGENTS.md) 常用命令 |

## 已知限制

- `probe_domains.ps1` 的团队页人名列取是正则近似，会把客户证言里的名字误抓；生产使用时建议人工复核 `Contact` 列。
- 脚本未做并发控制，多批同时跑同一目录会互相覆盖输出文件。
- `filter_formd.ps1` 的州白名单写死在脚本内，新增地区需手改。
