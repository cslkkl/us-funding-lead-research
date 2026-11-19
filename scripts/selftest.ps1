# 自检脚本：确认工具可用
# 用法: .\scripts\selftest.ps1
#       可选 -Quarter 2026q1 指定验证季度（默认用已缓存的数据）

param(
    [string]$Quarter = "",
    [switch]$SkipNetwork
)

$ErrorActionPreference = "Continue"
$root = Split-Path $PSScriptRoot -Parent
$pass = 0; $fail = 0

function Check($name, $scriptBlock) {
    try {
        $r = & $scriptBlock
        if ($r) { Write-Host "  [PASS] $name" -ForegroundColor Green; $script:pass++ }
        else    { Write-Host "  [FAIL] $name" -ForegroundColor Red;   $script:fail++ }
    } catch {
        Write-Host "  [FAIL] $name — $($_.Exception.Message)" -ForegroundColor Red
        $script:fail++
    }
}

Write-Host "`n=== us-funding-lead-research 自检 ===`n"

# ── 1. 文件完整性 ────────────────────────────────────────
Write-Host "1. 文件完整性"
$required = @(
    "SKILL.md","AGENTS.md","README.md",
    "config\default.json",
    "scripts\fetch_formd.ps1","scripts\filter_formd.ps1",
    "scripts\probe_domains.ps1","scripts\score_leads.ps1",
    "scripts\build_report.ps1",
    "docs\ARCHITECTURE.md",
    "references\pitfalls.md","references\domain-playbook.md"
)
foreach ($f in $required) {
    Check $f { Test-Path (Join-Path $root $f) }
}

# ── 2. 脚本语法 ──────────────────────────────────────────
Write-Host "`n2. 脚本语法"
foreach ($s in (Get-ChildItem (Join-Path $root "scripts") -Filter "*.ps1")) {
    Check $s.Name {
        $err = $null
        [System.Management.Automation.PSParser]::Tokenize((Get-Content $s.FullName -Raw), [ref]$err) | Out-Null
        $err.Count -eq 0
    }
}

# ── 3. 配置文件可解析 ────────────────────────────────────
Write-Host "`n3. 配置"
Check "default.json 可解析" {
    $c = Get-Content (Join-Path $root "config\default.json") -Raw | ConvertFrom-Json
    $c.filter.industries.Count -gt 0 -and $c.scoring.weights.hasContact -gt 0
}
Check "金额区间有效" {
    $c = Get-Content (Join-Path $root "config\default.json") -Raw | ConvertFrom-Json
    $c.filter.maxAmountUsd -gt $c.filter.minAmountUsd
}

# ── 4. PowerShell 版本 ───────────────────────────────────
Write-Host "`n4. 运行环境"
Check "PowerShell 5.1+" { $PSVersionTable.PSVersion.Major -ge 5 }
Check "Edge 可用（导 PDF 需要）" {
    Test-Path "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
}

# ── 5. 端到端（可选，需要网络） ──────────────────────────
if (-not $SkipNetwork -and $Quarter) {
    Write-Host "`n5. 端到端（季度 $Quarter）"
    $tmp = Join-Path $env:TEMP "selftest-$Quarter"
    if (Test-Path $tmp) { Remove-Item $tmp -Recurse -Force }
    Check "下载数据集" {
        & (Join-Path $root "scripts\fetch_formd.ps1") -Quarter $Quarter -OutDir $tmp 2>&1 | Out-Null
        (Get-ChildItem $tmp -Recurse -Filter "OFFERING.tsv" | Measure-Object).Count -gt 0
    }
    $dataDir = (Get-ChildItem $tmp -Recurse -Filter "OFFERING.tsv" | Select-Object -First 1).DirectoryName
    if ($dataDir) {
        Check "三层过滤" {
            & (Join-Path $root "scripts\filter_formd.ps1") -DataDir $dataDir -OutCsv "$tmp\c.csv" 2>&1 | Out-Null
            (Test-Path "$tmp\c.csv") -and (Import-Csv "$tmp\c.csv").Count -gt 0
        }
    }
} else {
    Write-Host "`n5. 端到端：跳过（加 -Quarter 2026q1 可验证完整链路）"
}

# ── 汇总 ─────────────────────────────────────────────────
Write-Host "`n=== 结果: $pass 通过, $fail 失败 ===" -ForegroundColor $(if ($fail -eq 0) { "Green" } else { "Yellow" })
if ($fail -gt 0) { exit 1 }
