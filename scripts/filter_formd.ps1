# 三层过滤 Form D 数据，输出候选公司清单
# 用法: .\filter_formd.ps1 -DataDir .\data\2026q3\2026Q3_d -OutCsv .\data\candidates.csv

param(
    [string]$DataDir   = "",
    [string]$OutCsv    = ".\data\candidates.csv",
    [double]$MinAmount = 5000000,
    [double]$MaxAmount = 25000000,
    [switch]$KeepNonTech
)

$ErrorActionPreference = "Stop"

if (-not $DataDir) {
    $DataDir = (Get-ChildItem "." -Recurse -Filter "ISSUERS.tsv" | Select-Object -First 1).DirectoryName
}
if (-not $DataDir -or -not (Test-Path (Join-Path $DataDir "ISSUERS.tsv"))) {
    throw "找不到 ISSUERS.tsv，请用 -DataDir 指定数据目录"
}

Write-Host "读取: $DataDir"
$issuers    = Import-Csv (Join-Path $DataDir "ISSUERS.tsv")         -Delimiter "`t"
$offerings  = Import-Csv (Join-Path $DataDir "OFFERING.tsv")        -Delimiter "`t"
$submissions= Import-Csv (Join-Path $DataDir "FORMDSUBMISSION.tsv") -Delimiter "`t"
Write-Host "  ISSUERS: $($issuers.Count)  OFFERING: $($offerings.Count)  SUBMISSION: $($submissions.Count)"

# 只保留主发行人
$primary = $issuers | Where-Object { $_.IS_PRIMARYISSUER_FLAG -eq "YES" }
$map = @{}
foreach ($p in $primary) { if (-not $map.ContainsKey($p.ACCESSIONNUMBER)) { $map[$p.ACCESSIONNUMBER] = $p } }

$dateMap = @{}
foreach ($s in $submissions) { $dateMap[$s.ACCESSIONNUMBER] = $s.FILING_DATE }

# 美国州代码白名单
$US = @("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA",
        "ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK",
        "OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY","DC")

# 目标行业
$TECH = @("Other Technology", "Computers")

$filtered = foreach ($o in $offerings) {
    if (-not $KeepNonTech -and $TECH -notcontains $o.INDUSTRYGROUPTYPE) { continue }

    $p = $map[$o.ACCESSIONNUMBER]
    if (-not $p) { continue }
    if ($US -notcontains $p.STATEORCOUNTRY) { continue }

    $sold = 0.0
    [void][double]::TryParse($o.TOTALAMOUNTSOLD, [ref]$sold)
    if ($sold -lt $MinAmount -or $sold -gt $MaxAmount) { continue }

    [pscustomobject]@{
        Name     = $p.ENTITYNAME
        City     = $p.CITY
        State    = $p.STATEORCOUNTRY
        Sold     = $sold
        Filed    = $dateMap[$o.ACCESSIONNUMBER]
        Industry = $o.INDUSTRYGROUPTYPE
    }
}

# 去重（同一公司可能多次申报）
$seen = @{}
$unique = foreach ($r in $filtered) {
    if (-not $seen.ContainsKey($r.Name)) {
        $seen[$r.Name] = $true
        $r
    }
}
$unique = $unique | Sort-Object Sold -Descending

Write-Host "`n候选公司: $($unique.Count) 家"
Write-Host "按州分布:"
$unique | Group-Object State | Sort-Object Count -Descending |
    Select-Object -First 10 | ForEach-Object { Write-Host ("  {0,-4} {1}" -f $_.Name, $_.Count) }

$dir = Split-Path $OutCsv -Parent
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$unique | Export-Csv $OutCsv -NoTypeInformation -Encoding UTF8
Write-Host "`n已导出: $OutCsv"
