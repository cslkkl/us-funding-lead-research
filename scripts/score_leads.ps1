# 线索打分与排序
# 用法: .\score_leads.ps1 -InputCsv .\data\final_leads.csv -OutCsv .\data\scored.csv -TopN 20

param(
    [Parameter(Mandatory=$true)][string]$InputCsv,
    [string]$OutCsv = ".\data\scored.csv",
    [int]$TopN = 20,
    [string[]]$ExcludeNames = @()
)

$ErrorActionPreference = "Stop"

# 实施需求信号词（出现越多，越可能有客户侧定制工作）
$hiSignal = '集成|对接|实施|合规|客户系统|ERP|CRM|医院|支付|结算|多租户|定制|迁移|数据治理|政策|法规|申报|流程|工作流|API|平台'

# 硬件/生物信号词（这类公司核心不自建软件，外包机会少）
$loSignal = '硬件|设备|卫星|航天|火箭|生物|药物|临床|半导体|芯片|材料|电池|能源|太阳能|采矿|机器人本体|传感'

$rows = Import-Csv $InputCsv -Encoding UTF8
Write-Host "读取 $($rows.Count) 条"

$scored = foreach ($r in $rows) {
    if (-not $r.Business -and -not $r.Snippet) { continue }
    $b = if ($r.Business) { $r.Business } else { $r.Snippet }

    $score = 0
    $reasons = @()

    # 1. 可触达性 30
    if ($r.Contact) {
        $score += 30
        $reasons += "有实名负责人"
    } elseif ($r.Email -and $r.Email -notmatch '(?i)^(support|info|hello|contact|sales|press|work|demo)@') {
        $score += 22
        $reasons += "有个人邮箱"
    } elseif ($r.Email) {
        $score += 12
        $reasons += "仅通用邮箱"
    }

    # 2. 实施需求强度 30
    $hits = ([regex]::Matches($b, $hiSignal)).Count
    $score += [Math]::Min(30, $hits * 5)
    if ($hits -ge 3) { $reasons += "实施需求强" }

    # 3. 团队阶段 25
    $amt = 0.0
    [void][double]::TryParse(($r.AmountM -replace 'M$',''), [ref]$amt)
    if ($amt -ge 10 -and $amt -le 25)     { $score += 25; $reasons += "阶段合适" }
    elseif ($amt -ge 6 -and $amt -lt 10)  { $score += 18; $reasons += "偏早期" }
    elseif ($amt -gt 25)                  { $score += 8;  $reasons += "规模偏大" }
    else                                  { $score += 5 }

    # 4. 硬件/生物扣分
    $lo = ([regex]::Matches($b, $loSignal)).Count
    if ($lo -ge 1) { $score -= 20; $reasons += "偏硬件/生物" }

    # 5. 官网确认 15
    if ($r.Status -eq 'verified') { $score += 15 }

    [pscustomobject]@{
        Company   = $r.Company
        City      = $r.City
        State     = $r.State
        AmountM   = $amt
        Domain    = $r.Domain
        Contact   = $r.Contact
        Title     = $r.Title
        Email     = $r.Email
        Score     = [Math]::Round($score, 1)
        Reasons   = ($reasons -join " · ")
        Business  = $b
        Excluded  = ($ExcludeNames -contains $r.Company)
    }
}

# 排序：未排除的优先，再按分数
$scored = $scored | Sort-Object @{Expression={$_.Excluded}}, @{Expression={-$_.Score}}

# 输出 topN（跳过排除项）
$top = $scored | Where-Object { -not $_.Excluded } | Select-Object -First $TopN

Write-Host "`n优先联系 Top $TopN:"
$top | Format-Table Company, AmountM, Contact, Title, Score -AutoSize

$dir = Split-Path $OutCsv -Parent
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$scored | Export-Csv $OutCsv -NoTypeInformation -Encoding UTF8
Write-Host "已导出: $OutCsv"
