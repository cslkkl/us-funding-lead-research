<div align="center">

# us-funding-lead-research

**从 SEC Form D 全量数据里，筛出「刚拿到钱、又可能要买外部服务」的美国公司。**

<p>
<img alt="PowerShell" src="https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?logo=powershell&logoColor=white">
<img alt="Platform" src="https://img.shields.io/badge/platform-Windows-0078D6?logo=windows&logoColor=white">
<img alt="License" src="https://img.shields.io/badge/license-MIT-2ea44f">
<img alt="Self-test" src="https://img.shields.io/badge/selftest-22%20passing-success">
<img alt="Quarters" src="https://img.shields.io/badge/verified-2026%20Q1%20%7C%20Q3-blue">
</p>

`15,952 条申报` → `1,184 家科技公司` → `150 家候选` → `103 个实名负责人`

</div>

---

## 它解决什么问题

做外包、代工、AI 交付这类生意，第一个问题永远是：**该联系谁？**

常见做法是让 AI 搜「美国近期融资的公司」，得到一张按金额排序的榜单 —— Databricks、Tenstorrent、Groq、LangChain。信息准确，但一条都用不上：融了 5 亿的公司自己会招两百个工程师。

真正该找的是另一类：

> **刚拿到钱、团队还没扩起来、而业务本身又要逐客户实施。**

判据只有一句：**客户数增加时，交付工作量会不会跟着线性增加？**

会增加的，才需要外部产能。不增加的，只需要钱。

---

## 输出长什么样

每一行都能点回官网核对，不是一张只有名字的名单。

| 公司 | 地点 | 融资 | 官网 | 负责人 | 邮箱 |
|---|---|---|---|---|---|
| Penelope Health | Dover, DE | $25.0M | penelope.health | Sohum Patel<br><sub>Co-Founder</sub> | founders@penelope.health |
| Sylvan Labs | San Francisco, CA | $10.9M | sylvanlabs.com | Charles Li<br><sub>CEO</sub> | charles@sylvanlabs.com |
| UrgentIQ | New York, NY | $12.0M | urgentiq.com | Nat Gibbs<br><sub>Founder & CEO</sub> | nat@urgentiq.com |
| Arpio | Durham, NC | $15.9M | arpio.io | Doug Neumann<br><sub>Co-founder & CEO</sub> | info@arpio.io |

完整字段：`Company` `LegalName` `City` `State` `AmountM` `Domain` `Business` `Contact` `Title` `Email` `Status` `Score` `Excluded`

一次完整运行的样例在 [examples/2026Q3-demo/](examples/2026Q3-demo/) —— 150 家，可直接打开对照格式。

---

## 实测命中率

2026 Q3 全量跑完的结果，可作基准：

| 环节 | 数量 | 占候选 |
|---|---|---|
| Q3 全部 Form D 申报 | 15,952 条 | — |
| 科技类公司 | 1,184 家 | — |
| 融资 500 万–2500 万美元 | **150 家** | 100% |
| 确认官网与业务 | 139 家 | 92.7% |
| 找到实名负责人 | 103 家 | 68.7% |
| 找到公开邮箱 | 82 家 | 54.7% |

跑出来显著低于这张表，先查域名探测是不是被停放页干扰了。

---

## 为什么用 SEC，不用媒体

媒体是发现工具，覆盖永远不全。AlleyWatch 的日报标题就写着 `New York`，只看它等于放弃 90% 的市场。

**SEC Form D 是唯一有法律强制力的全量口径** —— 美国所有非公开发行融资都必须申报。季度数据集可批量下载，含公司名、地址、行业、实际到账金额。

州分布（Q3 科技类 1,184 家）：

`CA 251` · `NY 123` · `DE 88` · `TX 79` · `FL 77` · `WA 53` · `MA 39` · `CO 37` · `VA 35` · `PA 25`

**纽约只占一成，加州是它的两倍。**

---

## 5 分钟跑通

```powershell
git clone https://github.com/cslkkl/us-funding-lead-research
cd us-funding-lead-research

# 先自检：22 项，覆盖文件、语法、配置、环境
.\scripts\selftest.ps1
```

全部 PASS 后，跑完整链路：

```powershell
# ① 下载季度数据集（自动重试 + 校验三表齐全）
.\scripts\fetch_formd.ps1 -Quarter 2026q3 -OutDir .\data

# ② 三层过滤：行业 → 州 → 金额
.\scripts\filter_formd.ps1 -DataDir .\data\2026Q3_d -OutCsv .\data\candidates.csv

# ③ 域名探测（建议按 15 家切批并行）
.\scripts\probe_domains.ps1 -InputCsv .\data\batch_0.csv -OutCsv .\data\batch_0_result.csv

# ④ 五维打分排序
.\scripts\score_leads.ps1 -InputCsv .\data\final_leads.csv -OutCsv .\data\scored.csv -TopN 20

# ⑤ 出报告（HTML + PDF）
.\scripts\build_report.ps1 -LeadsCsv .\data\final_leads.csv -ScoredCsv .\data\scored.csv
```

---

## 换业务方向，不改一行代码

所有阈值集中在 [config/default.json](config/default.json)：

```jsonc
{
  "filter": {
    "minAmountUsd": 5000000,                              // 低于这个数通常没外包预算
    "maxAmountUsd": 25000000,                             // 高于这个数基本自建团队
    "industries": ["Other Technology", "Computers"],
    "statesWhitelist": ["CA", "NY", "MA", "..."]          // 51 个
  },
  "scoring": {
    "weights": { "hasContact": 30, "implementationSignals": 30, "siteVerified": 15 },
    "implementationKeywords": ["集成", "对接", "实施", "合规", "ERP", "结算", "..."],
    "hardwareKeywords": ["硬件", "卫星", "生物", "芯片", "..."]   // 命中扣 20 分
  },
  "probe": {
    "tlds": [".com", ".ai", ".io", ".co"],
    "parkingPatterns": ["/lander", "for sale", "Launching Soon", "..."]
  }
}
```

| 你想做 | 改哪里 |
|---|---|
| 换成医疗 IT 客户 | `industries` → `["Other Health Care"]` |
| 只找小团队 | `minAmountUsd` → `2000000` |
| 换个业务关键词 | `scoring.implementationKeywords` |
| 换一批域名后缀 | `probe.tlds` |

---

## 跨季度验证

同一套脚本、同一份配置，跑过两个季度：

| 季度 | 申报数 | 过滤结果 | 改动代码 |
|---|---|---|---|
| 2026 Q1 | 15,734 条 | 181 家 | 无 |
| 2026 Q3 | 15,952 条 | 150 家 | 无 |

---

## 踩过的坑都写下来了

12 条，全部来自实测，每条写明**代价**和**解法** —— 见 [references/pitfalls.md](references/pitfalls.md)。

| 坑 | 代价 | 解法 |
|---|---|---|
| 从 AI 直接问「融资公司」 | 方向错，白读两小时 | 先写死 ICP 标准再去数据源 |
| 只用媒体源 | 覆盖率只有 10% | 第一天就上 SEC Form D |
| 直接吃 Form D 原始数据 | 六成是基金，名单虚高 3 倍 | 按行业分类先筛 |
| 按法定名猜域名 | 约 20% 猜不中 | 搜新闻稿确认新品牌 |
| 不核对同名公司 | Marble、Quaestor 都撞了 | 城市 + 业务双重核对 |
| 拼邮箱 | bounce 损伤域名信誉 | 没有就写「未找到」 |

---

## 什么时候别用

诚实说清边界，比包装成万能工具有用：

- **只要几家大公司** —— 直接看新闻更快
- **目标客户不在美国** —— Form D 只覆盖美国申报主体
- **需要并购、政府补助、自筹** —— 这些不触发 Form D
- **需要决策人私人邮箱** —— 公开渠道拿不到，得靠 Apollo、Hunter 这类付费工具
- **要求绝对实时** —— Form D 有申报滞后，最新一个月的数据通常不全

---

## 目录

```
us-funding-lead-research/
├── SKILL.md                  方法主文件：三步流程 + 排序模型 + 并行规范
├── AGENTS.md                 维护仪表盘：命令、验证快照、活跃坑
├── config/default.json       全部阈值与关键词
├── scripts/                  六个脚本，一环一条命令
│   ├── selftest.ps1          22 项自检
│   ├── fetch_formd.ps1       下载解压季度数据集
│   ├── filter_formd.ps1      三层过滤
│   ├── probe_domains.ps1     域名探测 + 停放页过滤
│   ├── score_leads.ps1       五维打分排序
│   └── build_report.ps1      生成 HTML + PDF
├── references/               12 个坑 / 域名规则 / 实测分布
├── docs/ARCHITECTURE.md      不变约束与防错清单
├── examples/2026Q3-demo/     一次完整运行的样例输出
└── data/                     运行时目录（不入库）
```

---

## 许可

MIT · 数据来自 [SEC EDGAR](https://www.sec.gov/edgar/search/)，遵循其公开数据使用条款。
