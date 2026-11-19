# 下载并解压 SEC Form D 季度数据集
# 用法: .\fetch_formd.ps1 -Quarter 2026q3 -OutDir .\data

param(
    [string]$Quarter = "2026q3",
    [string]$OutDir  = ".\data"
)

$ErrorActionPreference = "Stop"
$ua = "Mozilla/5.0 (compatible; research-bot/1.0)"

# 新季度用 datastandardsinnovation，旧季度用 structureddata
$paths = @(
    "https://www.sec.gov/files/datastandardsinnovation/data/form-d-data-sets/${Quarter}_d.zip",
    "https://www.sec.gov/files/structureddata/data/form-d-data-sets/${Quarter}_d.zip"
)

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
$zip = Join-Path $OutDir "$Quarter.zip"

$downloaded = $false
foreach ($url in $paths) {
    for ($i = 1; $i -le 3; $i++) {
        try {
            Write-Host "尝试 $url (第 $i 次)"
            Invoke-WebRequest $url -Headers @{ "User-Agent" = $ua } -TimeoutSec 120 -OutFile $zip -ErrorAction Stop
            $downloaded = $true
            Write-Host "下载成功: $([math]::Round((Get-Item $zip).Length/1MB,1)) MB"
            break
        } catch {
            Write-Host "  失败: $($_.Exception.Message)"
            Start-Sleep -Seconds 5
        }
    }
    if ($downloaded) { break }
}

if (-not $downloaded) { throw "所有镜像都下载失败，请检查季度代码或网络" }

# 解压
Add-Type -AssemblyName System.IO.Compression.FileSystem
$extract = Join-Path $OutDir $Quarter
if (Test-Path $extract) { Remove-Item $extract -Recurse -Force }
[System.IO.Compression.ZipFile]::ExtractToDirectory($zip, $extract, $true)

# 找到实际的数据目录（zip 内通常有一层同名目录）
$dataDir = $extract
$inner = Get-ChildItem $extract -Directory | Select-Object -First 1
if ($inner) { $dataDir = $inner.FullName }

Write-Host "`n数据目录: $dataDir"
Get-ChildItem $dataDir | ForEach-Object { Write-Host "  $($_.Name)  $([math]::Round($_.Length/1KB))KB" }

# 校验必需的表
$required = @("ISSUERS.tsv", "OFFERING.tsv", "FORMDSUBMISSION.tsv")
foreach ($f in $required) {
    if (-not (Test-Path (Join-Path $dataDir $f))) {
        throw "缺少必需文件: $f"
    }
}
Write-Host "`n三张表齐全，可以运行 filter_formd.ps1"
Write-Host "路径: $dataDir"
