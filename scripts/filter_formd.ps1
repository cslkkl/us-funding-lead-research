# 三层过滤 Form D 数据，输出候选公司清单
# 用法: .\filter_formd.ps1 -DataDir .\data\2026Q3_d -OutCsv .\data\candidates.csv
#       可选 -Config .\config\default.json 覆盖默认阈值

param(
    [Parameter(Mandatory=$true)][string]$DataDir,
    [string]$OutCsv = ".\data\candidates.csv",
    [string]$Config = "",
    [double]$MinAmount = 0,
    [double]$MaxAmount = 0
)

$ErrorActionPreference = "Stop"

# ── 读取配置 ─────────────────────────────────────────────
$cfgPath = if ($Config) { $Config } else { Join-Path $PSScriptRoot "..\config\default.json" }
if (-not (Test-Path $cfgPath)) { throw "找不到配置文件: $cfgPath" }
$cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json

$minAmt = if ($MinAmount -gt 0) { $MinAmount } else { $cfg.filter.minAmountUsd }
$maxAmt = if ($MaxAmount -gt 0) { $MaxAmount } else { $cfg.filter.maxAmountUsd }
$TECH   = $cfg.filter.industries
$US     = $cfg.filter.statesWhitelist

Write-Host "配置: $cfgPath"
Write-Host "  金额区间: `$$([math]::Round($minAmt/1e6,1))M – `$$([math]::Round($maxAmt/1e6,1))M"
Write-Host "  行业: $($TECH -join ', ')"
Write-Host "  州白名单: $($US.Count) 个"

# ── 读取数据 ─────────────────────────────────────────────
foreach ($f in @("ISSUERS.tsv","OFFERING.tsv","FORMDSUBMISSION.tsv")) {
    if (-not (Test-Path (Join-Path $DataDir $f))) { throw "缺少 $f，请确认 -DataDir 指向解压后的数据目录" }
}
Write-Host "`n读取: $DataDir"
$issuers     = Import-Csv (Join-Path $DataDir "ISSUERS.tsv")         -Delimiter "`t"
$offerings   = Import-Csv (Join-Path $DataDir "OFFERING.tsv")        -Delimiter "`t"
$submissions = Import-Csv (Join-Path $DataDir "FORMDSUBMISSION.tsv") -Delimiter "`t"
Write-Host "  ISSUERS=$($issuers.Count) OFFERING=$($offerings.Count) SUBMISSION=$($submissions.Count)"

# ── 建索引 ───────────────────────────────────────────────
$primary = $issuers | Where-Object { $_.IS_PRIMARYISSUER_FLAG -eq "YES" }
$map = @{}
foreach ($p in $primary) { if (-not $map.ContainsKey($p.ACCESSIONNUMBER)) { $map[$p.ACCESSIONNUMBER] = $p } }
Write-Host "  主发行人: $($map.Count)"

$dateMap = @{}
foreach ($s in $submissions) { $dateMap[$s.ACCESSIONNUMBER] = $s.FILING_DATE }

# ── 三层过滤 ─────────────────────────────────────────────
$stage1 = 0; $stage2 = 0; $stage3 = 0
$filtered = foreach ($o in $offerings) {
    if ($TECH -notcontains $o.INDUSTRYGROUPTYPE) { continue }
    $stage1++

    $p = $map[$o.ACCESSIONNUMBER]
    if (-not $p) { continue }
    if ($US -notcontains $p.STATEORCOUNTRY) { continue }
    $stage2++

    $sold = 0.0
    [void][double]::TryParse($o.TOTALAMOUNTSOLD, [ref]$sold)
    if ($sold -lt $minAmt -or $sold -gt $maxAmt) { continue }
    $stage3++

    [pscustomobject]@{
        Name     = $p.ENTITYNAME
        City     = $p.CITY
        State    = $p.STATEORCOUNTRY
        Sold     = $sold
        Filed    = $dateMap[$o.ACCESSIONNUMBER]
        Industry = $o.INDUSTRYGROUPTYPE
    }
}

Write-Host "`n三层过滤:"
Write-Host "  ① 行业命中        $stage1 条"
Write-Host "  ② + 美国境内      $stage2 条"
Write-Host "  ③ + 金额区间      $stage3 条"

# ── 去重 ─────────────────────────────────────────────────
$seen = @{}
$unique = foreach ($r in $filtered) {
    if (-not $seen.ContainsKey($r.Name)) { $seen[$r.Name] = $true; $r }
}
$unique = @($unique) | Sort-Object Sold -Descending

Write-Host "`n去重后: $($unique.Count) 家"
if ($unique.Count -gt 0) {
    Write-Host "按州分布:"
    $unique | Group-Object State | Sort-Object Count -Descending |
        Select-Object -First 10 | ForEach-Object { Write-Host ("  {0,-4} {1}" -f $_.Name, $_.Count) }
}

$dir = Split-Path $OutCsv -Parent
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$unique | Export-Csv $OutCsv -NoTypeInformation -Encoding UTF8
Write-Host "`n已导出: $OutCsv"
