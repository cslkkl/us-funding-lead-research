# references/ — 参考文档索引

四份文档，按用途分：规则类两份、数据类一份、案例类一份。规则层约束见 [AGENTS.md](AGENTS.md)。

## 文件

| 文档 | 回答什么问题 | 什么时候读 |
|---|---|---|
| [pitfalls.md](pitfalls.md) | 踩过哪些坑、代价多大、怎么解 | 开始做之前，避免重复犯错 |
| [domain-playbook.md](domain-playbook.md) | 域名怎么探、停放页怎么判、异常案例 | 写探测脚本或手工核官网时 |
| [field-notes.md](field-notes.md) | 160 家的数据分布与命中率 | 判断某步结果是否正常时 |
| [my-answer.md](my-answer.md) | 一次完整作业的答案与四版迭代 | 想了解全貌时 |

## 阅读顺序

第一次接触：[my-answer.md](my-answer.md) → [pitfalls.md](pitfalls.md) → `SKILL.md` → [domain-playbook.md](domain-playbook.md)

已熟悉流程：查 [field-notes.md](field-notes.md) 判断数据是否合理，查 [pitfalls.md](pitfalls.md) 排查异常。

## 变更影响路由

| 改这里 | 要同步 |
|---|---|
| [pitfalls.md](pitfalls.md) 增删条目 | [references/README.md](README.md) 表格 + 根 [AGENTS.md](../AGENTS.md) 活跃坑 |
| [domain-playbook.md](domain-playbook.md) 的停放页判据 | [scripts/probe_domains.ps1](../scripts/probe_domains.ps1) 实现 + [docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md) 契约表 |
| [field-notes.md](field-notes.md) 的数据基线 | 根 [AGENTS.md](../AGENTS.md) 验证快照 + [SKILL.md](../SKILL.md) 实测结果节 |
| 新增一份参考文档 | 本文件表格 + [SKILL.md](../SKILL.md) 参考资料节 + 根 [AGENTS.md](../AGENTS.md) 文档地图 |

## 写作约束

这三条继承根的写作规范，本目录尤其要注意：

- **结论前置**：先说结果，再说理由。
- **不用隐喻**：写「停放页」不写「空壳的表面」。
- **数字要有出处**：写「160 家里 90 个有邮箱」，不写「大部分有邮箱」。
