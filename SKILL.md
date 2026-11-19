---
name: us-funding-lead-research
description: |
  从 SEC Form D 全量数据出发，筛选美国刚完成融资的公司作为 B2B 客户线索，
  逐家核实官网、业务、负责人与公开邮箱，输出可排序的线索表。
  适用于代工/外包/外包销售/BD 场景的客户开发。
  触发词: 找客户, 融资公司线索, lead research, Form D, 美国初创客户,
  冷邮件名单, ICP 筛选, 客户清单, B2B 线索
---

# 美国融资公司客户线索研究

从「谁刚拿到钱」推导到「谁需要我们」，产出可直接发信的线索表。

## 核心心法

**融资额是预算信号，不是需求信号。**

一家融了 2.5 亿美元的公司自己会招两百个工程师，不需要外部团队。
真正该找的是**刚拿到钱、团队还没扩起来、而业务本身又要逐客户实施**的公司。

一句话判据：

> 客户数增加时，交付工作量是否线性增加？
> 是 → 它需要外部产能。否 → 它只需要钱。

## 三步流程

### 第 1 步：拿全量，不要从媒体找

媒体是发现工具，覆盖永远不全。**SEC Form D 是唯一有法律强制力的全量口径** —— 美国所有非公开发行融资都必须申报。

```powershell
# 下载季度数据集（约 3.5MB）
$q = "2026q3"
$url = "https://www.sec.gov/files/datastandardsinnovation/data/form-d-data-sets/${q}_d.zip"
# 历史季度用 /files/structureddata/data/form-d-data-sets/
Invoke-WebRequest $url -Headers @{"User-Agent"="Mozilla/5.0"} -OutFile "$env:TEMP\fd.zip"
```

解压后三张表关联：

| 文件 | 关键列 | 用途 |
|---|---|---|
| `ISSUERS.tsv` | ENTITYNAME, CITY, STATEORCOUNTRY, IS_PRIMARYISSUER_FLAG | 公司名、地址 |
| `OFFERING.tsv` | INDUSTRYGROUPTYPE, TOTALAMOUNTSOLD, SALE_DATE | 行业、实际到账金额 |
| `FORMDSUBMISSION.tsv` | FILING_DATE | 申报日期 |

关联键：`ACCESSIONNUMBER`。

**必须过滤的三层**（不过滤会严重虚高）：

1. **行业**：只要 `Other Technology` + `Computers`。全量里 `Pooled Investment Fund` 占六成以上，全是基金和 SPV。
2. **州**：按美国州代码白名单剔境外实体（会混进新加坡、伦敦、加拿大、澳洲）。
3. **金额**：`TOTALAMOUNTSOLD` 在 500 万–2500 万美元。低于 500 万通常没预算，高于 2500 万基本自建团队。

> `TOTALAMOUNTSOLD` 是**实际售出金额**，不是计划融资额（`TOTALOFFERINGAMOUNT`）。
> 只有前者代表钱真的到账。

### 第 2 步：逐家核官网

Form D 只有法定名和金额，**没有业务描述**。`LONE PALM LABS, INC.` 不打开官网完全不知道它做什么（实际是拍照 app，品牌叫 Retro）。

探测规则：

```
brand = 法定名去掉 Inc/LLC/Corp/Co/Ltd
依次试 brand.com → .ai → .io → .co
取第一个返回 200 且 title 非空的
```

**停放页判据**（必须过滤，否则会把域名商页面当成官网）：

| 特征 | 判据 |
|---|---|
| 空壳页 | 返回体 < 300 字节 |
| 无标题 | `<title>` 为空 |
| 域名商跳转 | 含 `/lander` |
| 待售页 | 含 `for sale`、`Efty`、`Spaceship` |
| 建站模板 | 含 `Launching Soon`、`Ready for Development`、`godaddy` |
| 假站 | 所有子路径都回退到首页 |

**域名猜不中时**（实测约 20% 会失败）：

- 品牌名与法定名不一致 → 搜新闻稿确认新品牌（`Deposely` → 实际叫 `Litem`，`Sentry Kiosk` → `Sentry Interactive`）
- 后缀不是标准四个 → 试 `.tech`、`.supply`、`.health`、`.app`（`DVx Atomic` → `atomic.supply`，`Aranya` → `aranya.tech`）
- 主域加 www → 有些配置只对 www 放行
- 加 `Sec-Fetch-*` 头 → 绕过部分 Cloudflare 403

### 第 3 步：提取联系人与邮箱

从 About / Team / Leadership 页抓人名和职务。

**邮箱只取页面原文**，不要拼 `firstname@domain`。公开页面通常只有 `support@`、`info@`、`hello@` 这类通用地址；创始人个人邮箱需要付费工具（Apollo、Hunter）才能拿到。

拿不到就写「未找到」。**编一个假地址的代价远大于留空** —— 发出去 bounce 会直接损伤域名信誉。

## 排序模型

拿到线索表后按下表打分，优先联系高分：

| 维度 | 权重 | 判据 |
|---|---|---|
| 可触达性 | 30 | 有实名负责人 30；有个人邮箱 22；仅通用邮箱 12；无 0 |
| 实施需求强度 | 30 | 描述中出现集成/对接/实施/合规/ERP/结算等词，每个 +5，上限 30 |
| 团队阶段 | 25 | 融资 1000–2500 万 25；600–1000 万 18；>2500 万 8；<600 万 5 |
| 硬件/生物扣分 | −20 | 出现硬件/设备/卫星/生物/药物/芯片/材料等词 |
| 官网已确认 | 15 | Status = verified |

**人工排除**（模型识别不了）：

- 上市公司（有股票代码的）
- 投资载体 / SPV / 控股公司
- 同行（做 AI 咨询、外包交付的，是竞争者不是客户）

## 并行批处理

单批 15 家，同时派 4–5 个子智能体。每家约 40 秒，160 家约 25 分钟。

子智能体 brief 必须包含：

1. 输入文件路径与列定义
2. 完整探测规则 + 停放页判据
3. **「找不到就写未找到，不要拼猜测邮箱」**
4. 同名公司必须核对城市和业务
5. 输出列格式与 Status 取值
6. 要求回复一行统计

## 输出

两张表：

- `final_leads.csv` —— 完整线索（公司、城市、州、金额、域名、业务、负责人、职务、邮箱、状态）
- `top20.csv` —— 按分数排序的优先联系名单

状态取值：`verified`（官网+业务确认）、`partial`（有官网但缺联系人）、`not_found`（找不到可确认官网）。

## 参考资料

- `references/pitfalls.md` —— 实测踩过的 12 个坑与验证过的解法
- `references/domain-playbook.md` —— 域名探测完整规则与异常案例
- `references/field-notes.md` —— 160 家实测数据分布与命中率

## 脚本

- `scripts/fetch_formd.ps1` —— 下载并解压 Form D 数据集
- `scripts/filter_formd.ps1` —— 三层过滤，输出候选清单
- `scripts/probe_domains.ps1` —— 域名探测 + 停放页过滤
- `scripts/score_leads.ps1` —— 排序打分
