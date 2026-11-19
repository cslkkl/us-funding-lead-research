# 域名探测完整规则

## 标准流程

```powershell
$brand = "Penelope Health"   # 从法定名去掉 Inc/LLC/Corp/Co/Ltd
$tlds  = @(".com", ".ai", ".io", ".co")
$ua    = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120 Safari/537.36"

foreach ($tld in $tlds) {
    $url = "https://" + ($brand -replace '[^A-Za-z0-9]', '') + $tld
    try {
        $r = Invoke-WebRequest $url -Headers @{ "User-Agent" = $ua } -TimeoutSec 10 -ErrorAction Stop
        if ($r.StatusCode -eq 200) {
            $title = [regex]::Match($r.Content, '<title[^>]*>(.*?)</title>').Groups[1].Value.Trim()
            if ($title -and -not (Test-ParkingPage $r)) { return $url }
        }
    } catch { }
    # 失败重试 2 次，间隔 800ms
}
```

## 停放页判据

五条命中任一即判定为停放页：

| 判据 | 检查方式 | 说明 |
|---|---|---|
| 空壳页 | `$r.Content.Length -lt 300` | 域名商最小跳转页 |
| 无标题 | `-not $title` | 正常站点都有 title |
| 域名商跳转 | `$r.Content -match '/lander'` | GoDaddy/Namecheap 停放标志 |
| 待售页 | `-match 'for sale\|Efty\|Spaceship\|HugeDomains'` | 待售域名 |
| 建站模板 | `-match 'Launching Soon\|Ready for Development\|Coming Soon\|godaddy'` | 空壳模板 |

**假站补充判据**：所有子路径（`/about` `/team` `/contact`）都回退到首页 —— 这是 SPA 路由兜底，说明站点只有一页。

## 异常案例库

### 品牌名与法定名不一致

| 法定名 | 品牌 | 域名 |
|---|---|---|
| LONE PALM LABS, INC. | Retro | lonepalm.io |
| DVx Atomic Co. | Atomic | atomic.supply |
| Deposely | Litem | litem.com |
| Sentry Kiosk | Sentry Interactive | sentryinteractive.com |
| Channing Street Copper | Copper | channingcopper.com |
| Social Auto Transport | HopDrive | hopdrive.com |
| VoiceIt…dba EnQuanta | EnQuanta | enquanta.com |

**处理**：搜新闻稿 `"公司名" raises` 或 `"公司名" funding`，报道里通常写 `The company, which operates at domain X` 或直接链接官网。

### 后缀不是标准四个

| 公司 | 实际域名 | 备注 |
|---|---|---|
| DVx Atomic | atomic.supply | 非 .com/.ai/.io/.co |
| Aranya | aranya.tech | .tech |
| Allocortech | allocor.tech | .tech，且品牌名缩写 |
| Cicero | get.cicero.im | 子域 + .im |
| Nodal Networks | nodal.io | 品牌名去 Networks |

### 主域需要 www

有些站点只对 `www.` 放行，裸域返回 403 或超时：

- `subscript.com` 超时 → `www.subscript.com` 返回 200
- `falcomm.com` 是停放页 → `www.falcomm.com` 是真站

### Cloudflare / 反爬 403

部分站点对 `Invoke-WebRequest` 返回 403，补这些头可绕过一部分：

```powershell
$h = @{
    "User-Agent"      = $ua
    "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
    "Accept-Language" = "en-US,en;q=0.9"
    "Sec-Fetch-Dest"  = "document"
    "Sec-Fetch-Mode"  = "navigate"
    "Sec-Fetch-Site"  = "none"
    "Sec-Fetch-User"  = "?1"
    "Upgrade-Insecure-Requests" = "1"
}
```

仍失败的（实测：Atari、Cranium、Flexxbotics、Rasa Legal），改用新闻稿交叉验证。

### 邮箱被混淆

Cloudflare Email Protection 会把邮箱渲染成 `[email protected]` 或 `/cdn-cgi/l/email-protection#<hex>`。

解码方式：hex 部分逐字节 XOR `第一个字节`，得到真实邮箱地址。**看不清就写「未找到」，不要猜。**

## 联系人与邮箱提取

优先抓这些路径：

```
/about  /about-us  /company  /team  /leadership  /leadership-team
/our-team  /people  /founders  /management  /contact  /contact-us
```

人名模式（正则辅助，需人工确认）：

```
(Founder|Co-?Founder|CEO|CTO|COO|President|Chief Executive)[^\n]{0,40}
```

**常见误判**（抓到了但不是高管）：

- 客户证言里的人名（"…said John Doe, CTO of Acme"）
- 投资方合伙人（在 portfolio 页面出现）
- 页面锚文本（"From Our Founder" 被抓成 "From Our"）
- 职位被截断（"Chief Executive" 缺 "Officer"）

**处理**：抓到人名后回到 About 页确认其职务上下文，投资方页面和证言区不计入。

## 输出列定义

| 列 | 说明 |
|---|---|
| Company | 品牌名（不是法定名） |
| City / State | 取自 Form D |
| AmountM | 实际融资额（百万美元） |
| Domain | 官网域名，未找到留空 |
| Business | 一句话中文业务描述 |
| Contact | 负责人姓名，未找到留空 |
| Title | 职务 |
| Email | 页面公开邮箱，未找到留空 |
| Status | verified / partial / not_found |
