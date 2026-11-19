# 160 家实测数据分布

数据来源：SEC Form D 2026 Q3 数据集，逐家核实于 2026-11-19。

## 漏斗

| 环节 | 数量 | 转化率 |
|---|---|---|
| Q3 全部 Form D 申报 | 15,952 条 | — |
| 科技类（Other Technology + Computers） | 1,184 家 | 7.4% |
| 融资 500 万–2500 万美元 + 美国境内 | 160 家 | 13.5% |
| 确认到官网与业务 | 129 家 | 80.6% |
| 找到实名负责人 | 89 家 | 55.6% |
| 找到公开邮箱 | 78 家 | 48.8% |

## 州分布（1,184 家科技类）

| 州 | 家数 | 占比 |
|---|---|---|
| CA 加州 | 251 | 21.2% |
| NY 纽约 | 123 | 10.4% |
| DE 特拉华 | 88 | 7.4% |
| TX 德州 | 79 | 6.7% |
| FL 佛州 | 77 | 6.5% |
| WA 华州 | 53 | 4.5% |
| MA 麻州 | 39 | 3.3% |
| CO 科州 | 37 | 3.1% |
| VA 弗州 | 35 | 3.0% |
| PA 宾州 | 25 | 2.1% |

**结论**：只看纽约媒体会漏掉约 90%。

## 行业分类（Q3 全量 15,952 条）

| INDUSTRYGROUPTYPE | 条数 |
|---|---|
| Pooled Investment Fund | 10,487 |
| Other | 1,138 |
| Other Technology | 1,114 |
| Other Real Estate | 562 |
| Commercial | 517 |
| Other Health Care | 257 |
| Biotechnology | 207 |
| Computers | 70 |

**关键发现**：基金类占 65.7%。不剔除会让名单虚高 3 倍。

## 核实命中率（按批次实测）

13 个批次、160 家的实际表现：

| 状态 | 家数 | 占比 |
|---|---|---|
| verified（官网+业务确认） | 107 | 66.9% |
| partial（有官网缺联系人或邮箱） | 22 | 13.8% |
| not_found（四个后缀都失败） | 31 | 19.4% |

## 域名探测成功率

| 情况 | 占比 | 说明 |
|---|---|---|
| 标准四后缀首个即命中 | 约 62% | brand.com 或 brand.ai |
| 需要换后缀或加 www | 约 12% | .tech/.supply/www |
| 需要新闻稿确认真实域名 | 约 6% | 品牌名变更 |
| 完全找不到 | 约 19% | 多为投资载体、已改名、极小公司 |

## 邮箱可得性

| 类型 | 数量 | 说明 |
|---|---|---|
| 有公开邮箱 | 78 / 160 | 48.8% |
| 其中个人邮箱 | 约 5 | 极少数直接挂创始人邮箱 |
| 其中通用邮箱 | 约 73 | support@ / info@ / hello@ / press@ |
| 无任何公开邮箱 | 82 | 多数只有表单 |

**结论**：公开渠道拿不到创始人个人邮箱。需要 Apollo、Hunter 等付费工具。不要把「有 78 个邮箱」当成「能触达 78 个决策人」。

## 优先名单参考（按打分模型 Top 20）

| 公司 | 融资 | 负责人 | 职务 | 分数 |
|---|---|---|---|---|
| Penelope Health | $25.0M | Sohum Patel | Co-Founder | 90 |
| Cranium AI | $20.0M | Jonathan Dambrot | CEO & Co-founder | 85 |
| Qualified Health | $10.0M | Justin Norden | Co-Founder & CEO | 85 |
| Intermezzo | $8.3M | Siddharth Ram | Co-founder & CEO | 83 |
| Levanta | $22.0M | Ian Brodie | Co-Founder & CEO | 80 |
| Arpio | $15.9M | Doug Neumann | Co-founder & CEO | 80 |
| Balance Theory | $12.0M | Greg Baker | CEO | 80 |
| Payload | $9.1M | Ryan Rybolt | Founder & CEO | 78 |
| Koxa | $8.7M | Conner Mulvee | Co-Founder & CEO | 78 |
| Ionia | $8.6M | Marshall Greenwald | Founder & CEO | 78 |
| Sylvan Labs | $10.9M | Charles Li | CEO | 75 |
| Gradient Sports | $10.4M | Nate Gerstle | CEO | 75 |
| BrightPlan | $13.8M | Marthin De Beer | Founder & CEO | 75 |
| Tagup | $14.8M | Jon Garrity | CEO & Co-Founder | 75 |
| EnQuanta | $10.1M | Scott Schnorrenberg | CEO | 75 |
| Sentry Interactive | $10.0M | Denis Hébert | Chairman & CEO | 75 |
| AgentSmyth | $12.7M | Pulkit Jaiswal | Founder & CEO | 75 |
| Subscript | $18.3M | Sidharth Kakkar | CEO | 75 |
| Virtualitics | $10.0M | Michael Amori | CEO & Co-Founder | 75 |
| Thira | $18.5M | Bhrighu Sareen | Co-Founder, CEO | 75 |

## 人工排除的案例

模型给高分但不该联系的：

| 公司 | 分数 | 排除原因 |
|---|---|---|
| Circle | 95 | 纽交所上市（CRCL） |
| Fly.io | — | 已是成熟平台，融资 2500 万仍自建 |
| Atari Interactive | — | 上市公司子公司 |
| FreeCast | — | 纳斯达克上市（CAST） |
| Municipal Parking Services | — | 传统行业，非软件交付 |

**教训**：模型只能排序，不能替代判断。上市、投资载体、同行这三类必须人工剔除。
