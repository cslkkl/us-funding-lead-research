# 美国融资公司客户线索研究

从 SEC Form D 全量数据出发，筛选刚完成融资的美国公司作为 B2B 客户线索。

## 什么时候用

适合：需要一批「刚拿到钱、又可能要买外部服务」的公司当客户线索；按季度滚动更新；需要一家家能点回官网核对，而不是一张只有名字的名单。

不适合：只要几家大公司（直接看新闻更快）；目标客户不在美国（Form D 只覆盖美国申报主体）；需要并购、政府补助这类不触发 Form D 的融资；需要决策人私人邮箱（公开渠道拿不到，得靠付费工具）。

## 这个仓库解决什么问题

做外包/代工/AI 交付这类生意时，第一个问题永远是：**该联系谁？**

常见做法是让 AI 搜「美国近期融资的公司」，得到一张按金额排序的榜单 —— Databricks、Tenstorrent、Groq、LangChain。这些公司信息准确，但一条也用不上：融了 5 亿的公司自己会招两百个工程师，不需要外部团队。

真正该找的是另一类公司：

> **刚拿到钱、团队还没扩起来、而业务本身又要逐客户实施。**

判据只有一句：客户数增加时，交付工作量是否线性增加？

## 方法

三步，顺序不能反。

### 1. 拿全量数据，不要从媒体找

媒体是发现工具，覆盖永远不全。AlleyWatch 的日报标题就写着 `New York`，只看它等于放弃 90% 的市场。

**SEC Form D 是唯一有法律强制力的全量口径** —— 美国所有非公开发行融资都必须申报。季度数据集可批量下载，含公司名、地址、行业、实际到账金额。

三层过滤后从 15,952 条得到 160 家候选。

### 2. 逐家核官网

Form D 只有法定名和金额，没有业务描述。`LONE PALM LABS, INC.` 不打开官网完全不知道它做什么（实际是拍照 app，品牌叫 Retro）。

域名探测要过滤停放页，否则会把域名商的待售页当成公司官网。

### 3. 提取联系人与邮箱

只取页面原文的邮箱。找不到就写「未找到」—— 编一个假地址的代价远大于留空。

## 实测结果

160 家公司的实际分布（SEC Form D 2026 Q3）：

| 环节 | 数量 |
|---|---|
| Q3 全部 Form D 申报 | 15,952 条 |
| 科技类公司 | 1,184 家 |
| 融资 500 万–2500 万美元 | 160 家 |
| 确认到官网与业务 | 129 家（80.6%） |
| 找到实名负责人 | 89 家（55.6%） |
| 找到公开邮箱 | 78 家（48.8%） |

州分布：CA 251、NY 123、DE 88、TX 79、FL 77、WA 53 —— **纽约只占 10%**。

## 踩过的坑

12 条，全部来自实测，每条写明代价和解法。见 [`references/pitfalls.md`](references/pitfalls.md)。

几个典型：

| 坑 | 代价 | 解法 |
|---|---|---|
| 从 AI 直接问「融资公司」 | 方向错，白读两小时 | 先写死 ICP 标准再去数据源 |
| 只用媒体源 | 覆盖率只有 10% | 第一天就上 SEC Form D |
| 直接吃 Form D 原始数据 | 六成是基金，名单虚高 3 倍 | 按行业分类先筛 |
| 按法定名猜域名 | 约 20% 猜不中 | 搜新闻稿确认新品牌 |
| 不核对同名公司 | Marble、Quaestor 都撞了 | 城市 + 业务双重核对 |
| 拼邮箱 | bounce 损伤域名信誉 | 没有就写「未找到」 |

## 快速开始

先跑自检确认环境没问题：

```powershell
.\scripts\selftest.ps1
```

二十二项检查覆盖文件完整性、脚本语法、配置解析、运行时依赖。全部 PASS 再往下走。

## 使用

```powershell
# 1. 下载季度数据集（自动重试，校验三表齐全）
.\scripts\fetch_formd.ps1 -Quarter 2026q3 -OutDir .\data

# 2. 三层过滤（行业 → 州 → 金额）
.\scripts\filter_formd.ps1 -DataDir .\data\2026Q3_d -OutCsv .\data\candidates.csv

# 3. 域名探测（建议按 15 家切批并行）
.\scripts\probe_domains.ps1 -InputCsv .\data\batch_0.csv -OutCsv .\data\batch_0_result.csv

# 4. 打分排序
.\scripts\score_leads.ps1 -InputCsv .\data\final_leads.csv -OutCsv .\data\scored.csv -TopN 20

# 5. 生成报告（HTML + PDF）
.\scripts\build_report.ps1 -LeadsCsv .\data\final_leads.csv -ScoredCsv .\data\scored.csv
```

## 改参数不用改脚本

所有阈值集中在 [config/default.json](config/default.json)：

```jsonc
{
  "filter": {
    "minAmountUsd": 5000000,        // 金额下限
    "maxAmountUsd": 25000000,       // 金额上限
    "industries": ["Other Technology", "Computers"],
    "statesWhitelist": ["CA", "NY", ...]
  },
  "scoring": {
    "weights": { "hasContact": 30, "implementationSignals": 30, ... },
    "implementationKeywords": ["集成", "对接", "实施", ...],
    "hardwareKeywords": ["硬件", "卫星", "生物", ...]
  },
  "probe": {
    "tlds": [".com", ".ai", ".io", ".co"],
    "parkingPatterns": ["/lander", "for sale", ...],
    "teamPagePaths": ["/about", "/team", ...]
  }
}
```

换业务方向时只改这里：比如做数据服务就把 `industries` 换成 `Other Health Care`，做工程外包就把 `minAmountUsd` 调到 300 万。

## 已验证的跨季度可用性

| 季度 | 数据集 | 过滤结果 |
|---|---|---|
| 2026 Q3 | 15,952 条申报 | 160 家候选 |
| 2026 Q1 | 15,734 条申报 | 181 家候选 |

两个季度用同一套脚本、同一份配置，无需修改。Q1 的验证结果见 [examples/](examples/README.md)。

## 目录

```
us-funding-lead-research/
├── SKILL.md                      方法主文件（三步流程 + 排序模型）
├── AGENTS.md                     维护仪表盘
├── README.md                     本文件
├── config/
│   └── default.json              全部阈值与关键词，改这里
├── scripts/
│   ├── selftest.ps1              自检：22 项环境与完整性检查
│   ├── fetch_formd.ps1           下载解压季度数据集
│   ├── filter_formd.ps1          三层过滤
│   ├── probe_domains.ps1         域名探测 + 停放页过滤
│   ├── score_leads.ps1           五维打分排序
│   └── build_report.ps1          生成 HTML + PDF 报告
├── references/
│   ├── pitfalls.md               12 个坑与解法
│   ├── domain-playbook.md        域名探测完整规则
│   └── field-notes.md            实测数据分布与命中率
├── docs/
│   └── ARCHITECTURE.md           不变约束与防错清单
├── examples/
│   └── 2026Q3-demo/              一次完整运行的样例输出
└── data/                         运行时目录（不入库）
```
## 局限

- **Form D 有滞后**：申报通常在融资完成后数周，最新一个月的数据可能不全。
- **不含并购、政府补助、自筹**：这些不触发 Form D 申报。
- **公开渠道拿不到创始人个人邮箱**：需要 Apollo、Hunter 等付费工具。160 家里只有 78 个公开邮箱，多数还是 `support@`、`info@` 这类通用地址。
- **模型只能排序，不能替代判断**：上市公司、投资载体、同行这三类必须人工剔除。

## 许可

MIT
