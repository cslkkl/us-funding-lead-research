# scripts/ — 脚本索引

四步流程各一个脚本，按顺序执行。规则层约束见 [AGENTS.md](AGENTS.md)。

## 文件

| 脚本 | 做什么 | 输入 | 输出 |
|---|---|---|---|
| [fetch_formd.ps1](fetch_formd.ps1) | 下载并解压 SEC Form D 季度数据集，校验三表齐全 | `-Quarter`（如 `2026q3`）、`-OutDir` | `{OutDir}/{Quarter}/` 下的 TSV |
| [filter_formd.ps1](filter_formd.ps1) | 三表关联 + 三层过滤 + 去重 | `-DataDir`、`-MinAmount`、`-MaxAmount` | `candidates.csv` |
| [probe_domains.ps1](probe_domains.ps1) | 域名探测 + 停放页过滤 + 团队页抓取 | `-InputCsv`、`-OutCsv` | `*_result.csv` |
| [score_leads.ps1](score_leads.ps1) | 五维打分 + 人工排除 | `-InputCsv`、`-TopN`、`-ExcludeNames` | `scored.csv` |

## 执行顺序

```
fetch_formd → filter_formd → probe_domains（按批并行）→ score_leads
```

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
