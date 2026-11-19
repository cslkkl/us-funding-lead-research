# 从线索 CSV 生成 HTML 报告与附表，再用 Edge 导 PDF
# 用法: .\build_report.ps1 -LeadsCsv .\data\final_leads.csv -ScoredCsv .\data\scored.csv -OutDir .\report

param(
    [Parameter(Mandatory=$true)][string]$LeadsCsv,
    [string]$ScoredCsv = "",
    [string]$OutDir = ".\report",
    [string]$Title = "美国近期融资公司线索整理",
    [string]$Author = "",
    [string]$Date = "",
    [int]$TopN = 8,
    [string]$EdgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $LeadsCsv)) { throw "找不到 $LeadsCsv" }
if (-not $ScoredCsv -and (Test-Path (Join-Path (Split-Path $LeadsCsv) "scored.csv"))) {
    $ScoredCsv = Join-Path (Split-Path $LeadsCsv) "scored.csv"
}
if (-not $Date) { $Date = Get-Date -Format "yyyy 年 M 月 d 日" }
if (-not (Test-Path $OutDir)) { New-Item -ItemType Directory -Path $OutDir -Force | Out-Null }

$leads = Import-Csv $LeadsCsv -Encoding UTF8
Write-Host "读取 $($leads.Count) 条线索"

# ── 统计 ─────────────────────────────────────────────────
$vCount = @($leads | Where-Object { $_.Status -eq 'verified' }).Count
$pCount = @($leads | Where-Object { $_.Status -eq 'partial' }).Count
$nCount = @($leads | Where-Object { $_.Status -eq 'not_found' }).Count
$withDomain  = @($leads | Where-Object { $_.Domain }).Count
$withContact = @($leads | Where-Object { $_.Contact }).Count
$withEmail   = @($leads | Where-Object { $_.Email }).Count
$persEmail = @($leads | Where-Object {
    $_.Email -and $_.Email -notmatch '(?i)^(support|info|hello|contact|sales|press|work|demo|careers)@'
}).Count

Write-Host "  verified=$vCount partial=$pCount not_found=$nCount"
Write-Host "  有官网=$withDomain 有负责人=$withContact 有邮箱=$withEmail (个人 $persEmail)"

# ── 表格渲染 ─────────────────────────────────────────────
function HtmlEscape($s) {
    if (-not $s) { return "—" }
    return ($s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;')
}

$rows = foreach ($r in $leads) {
    $biz = HtmlEscape $r.Business
    if ($biz.Length -gt 55 -and $biz -ne "—") { $biz = $biz.Substring(0,55) + "…" }
    $ct  = if ($r.Contact) { "$(HtmlEscape $r.Contact)<br><span class='t'>$(HtmlEscape $r.Title)</span>" } else { "—" }
    $em  = HtmlEscape $r.Email
    $dm  = HtmlEscape $r.Domain
    $st  = switch ($r.Status) { "verified" { "●" } "partial" { "◐" } default { "○" } }
    $amt = if ($r.AmountM) { '$' + $r.AmountM + 'M' } else { "—" }
    "      <tr><td><b>$(HtmlEscape $r.Company)</b></td><td>$(HtmlEscape $r.City)<br><span class='t'>$(HtmlEscape $r.State)</span></td><td class='n'>$amt</td><td>$biz</td><td class='e'>$dm</td><td>$ct</td><td class='e'>$em</td><td class='s'>$st</td></tr>"
}

# ── Top N ────────────────────────────────────────────────
$topRows = ""
if ($ScoredCsv -and (Test-Path $ScoredCsv)) {
    $scored = Import-Csv $ScoredCsv -Encoding UTF8 |
              Where-Object { $_.Excluded -ne 'True' } |
              Select-Object -First $TopN
    $topRows = foreach ($t in $scored) {
        "      <tr><td><b>$(HtmlEscape $t.Company)</b></td><td>$(HtmlEscape $t.City), $(HtmlEscape $t.State)</td><td class='n'>`$$($t.AmountM)M</td><td>$(HtmlEscape $t.Contact)<br><span class='t'>$(HtmlEscape $t.Title)</span></td><td class='e'>$(HtmlEscape $t.Email)</td></tr>"
    }
    $topRows = $topRows -join "`n"
}

$css = @'
<style>
  body{margin:0;background:#fff;color:#1f1f1f;font-family:"Microsoft YaHei","PingFang SC",sans-serif;font-size:11px;line-height:1.7;}
  .doc{max-width:920px;margin:0 auto;padding:32px 22px;}
  h1{font-size:19px;font-weight:600;margin:0 0 4px;}
  .meta{color:#777;font-size:10px;margin-bottom:16px;}
  h2{font-size:13px;font-weight:600;margin:18px 0 6px;}
  table{width:100%;border-collapse:collapse;margin:6px 0 10px;font-size:8.8px;line-height:1.4;}
  th,td{border:1px solid #999;padding:3px 5px;vertical-align:top;text-align:left;}
  th{background:#efefef;font-weight:600;}
  .n{white-space:nowrap;font-family:Consolas,monospace;}
  .e{font-family:Consolas,monospace;font-size:8.2px;word-break:break-all;}
  .s{text-align:center;}
  .t{color:#999;font-size:7.8px;}
  .legend{font-size:9px;color:#555;margin:6px 0 4px;}
  @page{size:A4;margin:10mm 8mm;}
  @media print{.doc{max-width:none;padding:0;}thead{display:table-header-group;}tr{break-inside:avoid;}}
</style>
'@

# ── 附表 ─────────────────────────────────────────────────
$appendix = @"
<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">
<title>附表 · $Title</title>$css</head><body><div class="doc">
<h1>附表：$Title（$($leads.Count) 家）</h1>
<div class="meta">$Author ｜ $Date</div>
<p class="legend"><b>●</b> 官网与业务已确认（$vCount 家）　<b>◐</b> 官网可访问但缺负责人或邮箱（$pCount 家）　<b>○</b> 未找到可确认官网（$nCount 家）</p>
<table><thead><tr>
<th style="width:12%">公司</th><th style="width:9%">地点</th><th style="width:6.5%">融资</th><th style="width:24%">做什么</th><th style="width:11%">官网</th><th style="width:13%">负责人</th><th style="width:15%">邮箱</th><th style="width:3.5%">状态</th>
</tr></thead><tbody>
$($rows -join "`n")
</tbody></table>
</div></body></html>
"@
$apPath = Join-Path $OutDir "appendix.html"
$appendix | Out-File $apPath -Encoding UTF8
Write-Host "`n附表: $apPath"

# ── 主报告（统计 + Top N） ───────────────────────────────
$main = @"
<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">
<title>$Title</title>$css</head><body><div class="doc">
<h1>$Title</h1>
<div class="meta">$Author ｜ $Date</div>
<h2>一、数据规模</h2>
<table><thead><tr><th style="width:34%">环节</th><th style="width:14%">数量</th></tr></thead><tbody>
<tr><td>候选公司</td><td class="n">$($leads.Count) 家</td></tr>
<tr><td>确认官网与业务</td><td class="n">$withDomain 家</td></tr>
<tr><td>找到实名负责人</td><td class="n">$withContact 家</td></tr>
<tr><td>找到公开邮箱</td><td class="n">$withEmail 家（个人 $persEmail 个）</td></tr>
</tbody></table>
<h2>二、建议优先联系</h2>
<table><thead><tr><th style="width:20%">公司</th><th style="width:20%">地点</th><th style="width:10%">融资</th><th style="width:26%">负责人</th><th>公开邮箱</th></tr></thead><tbody>
$topRows
</tbody></table>
<p>完整清单见附表。</p>
</div></body></html>
"@
$mainPath = Join-Path $OutDir "main.html"
$main | Out-File $mainPath -Encoding UTF8
Write-Host "主报告: $mainPath"

# ── 导 PDF ───────────────────────────────────────────────
if (Test-Path $EdgePath) {
    foreach ($pair in @(@($mainPath,"main.pdf"), @($apPath,"appendix.pdf"))) {
        $outPdf = Join-Path $OutDir $pair[1]
        Remove-Item $outPdf -Force -ErrorAction SilentlyContinue
        & $EdgePath --headless=new --disable-gpu --no-pdf-header-footer --print-to-pdf="$outPdf" "file:///$($pair[0].Replace('\','/'))" 2>&1 | Out-Null
        Start-Sleep -Seconds 5
        if (Test-Path $outPdf) {
            $b = [System.IO.File]::ReadAllBytes($outPdf)
            $pages = [regex]::Matches([System.Text.Encoding]::Latin1.GetString($b), '/Type\s*/Pages[^/]{0,40}?/Count\s+(\d+)')[0].Groups[1].Value
            Write-Host "  PDF: $outPdf ($pages 页)"
        }
    }
} else {
    Write-Host "`n未找到 Edge，跳过 PDF 导出。HTML 已生成，可手动浏览器打印。"
}
