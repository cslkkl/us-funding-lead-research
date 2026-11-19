# 域名探测 + 停放页过滤 + 业务与联系人提取
# 用法: .\probe_domains.ps1 -InputCsv .\data\batch.csv -OutCsv .\data\batch_result.csv

param(
    [Parameter(Mandatory=$true)][string]$InputCsv,
    [Parameter(Mandatory=$true)][string]$OutCsv,
    [int]$Retry = 2,
    [int]$TimeoutSec = 10
)

$ErrorActionPreference = "Continue"
$ua = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

function Get-ParkingReason {
    param($Content, $Title)
    if (-not $Content) { return "empty" }
    if ($Content.Length -lt 300) { return "too_short" }
    if (-not $Title) { return "no_title" }
    if ($Content -match '/lander') { return "lander" }
    if ($Content -match '(?i)\bfor sale\b|Efty|Spaceship|HugeDomains|Sedo') { return "for_sale" }
    if ($Content -match '(?i)Launching Soon|Ready for Development|Coming Soon|godaddy') { return "template" }
    return $null
}

function Invoke-SafeGet {
    param($Url, $TimeoutSec, $Retry, $Ua)
    $headers = @{
        "User-Agent"      = $Ua
        "Accept"          = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8"
        "Accept-Language" = "en-US,en;q=0.9"
        "Sec-Fetch-Dest"  = "document"
        "Sec-Fetch-Mode"  = "navigate"
        "Sec-Fetch-Site"  = "none"
    }
    for ($i = 0; $i -le $Retry; $i++) {
        try {
            return Invoke-WebRequest $Url -Headers $headers -TimeoutSec $TimeoutSec -MaximumRedirection 5 -ErrorAction Stop
        } catch {
            if ($i -lt $Retry) { Start-Sleep -Milliseconds 800 }
            else { return $null }
        }
    }
}

function Get-Brand {
    param($Name)
    $b = $Name -replace '\s*,?\s*(Inc\.?|LLC|L\.L\.C\.|Corp\.?|Co\.?|Ltd\.?|Corporation|Incorporated|Company|PBC|LP|L\.P\.)$', ''
    return $b.Trim()
}

function Get-Slug {
    param($Brand)
    return ($Brand -replace '[^A-Za-z0-9]', '').ToLower()
}

$rows = Import-Csv $InputCsv -Encoding UTF8
Write-Host "处理 $($rows.Count) 家"

$results = @()
$n = 0
foreach ($r in $rows) {
    $n++
    $brand = Get-Brand $r.Name
    $slug  = Get-Slug $brand
    Write-Host "[$n/$($rows.Count)] $brand"

    $domain = ""
    $title = ""
    $text = ""
    $emails = @()
    $contact = ""
    $jobTitle = ""

    foreach ($tld in @(".com", ".ai", ".io", ".co")) {
        $url = "https://$slug$tld"
        $resp = Invoke-SafeGet -Url $url -TimeoutSec $TimeoutSec -Retry $Retry -Ua $ua
        if (-not $resp) { continue }
        if ($resp.StatusCode -ne 200) { continue }

        $t = [regex]::Match($resp.Content, '(?is)<title[^>]*>(.*?)</title>').Groups[1].Value.Trim()
        $reason = Get-ParkingReason -Content $resp.Content -Title $t
        if ($reason) { Write-Host "    $url -> 停放页($reason)"; continue }

        $domain = $url
        $title = $t
        $plain = ($resp.Content -replace '(?is)<script.*?</script>', ' ') -replace '(?is)<style.*?</style>', ' '
        $plain = ($plain -replace '<[^>]+>', ' ') -replace '\s+', ' '
        $text = $plain
        $emails = [regex]::Matches($plain, '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}') |
                  ForEach-Object { $_.Value } | Where-Object { $_ -notmatch '\.(png|jpg|gif|webp|svg)$' } |
                  Select-Object -Unique
        Write-Host "    命中: $domain  |  $title"
        break
    }

    # 抓团队页
    if ($domain) {
        foreach ($path in @("/about", "/about-us", "/team", "/leadership", "/leadership-team", "/company", "/our-team", "/people")) {
            $resp = Invoke-SafeGet -Url ($domain + $path) -TimeoutSec $TimeoutSec -Retry 0 -Ua $ua
            if (-not $resp -or $resp.StatusCode -ne 200) { continue }
            $p = ($resp.Content -replace '<[^>]+>', ' ') -replace '\s+', ' '
            $m = [regex]::Match($p, '(?i)(?:Co-?Founder|Founder|CEO|CTO|COO|Chief Executive\s*Officer)[^\n]{0,10}?([A-Z][a-z]+ [A-Z][a-z]+)')
            if (-not $m.Success) {
                $m = [regex]::Match($p, '([A-Z][a-z]+ [A-Z][a-z]+)[^\n]{0,20}?(?:Co-?Founder|Founder|CEO|CTO|Chief Executive)')
            }
            if ($m.Success) {
                $candidate = $m.Groups[1].Value
                # 排除客户证言里的名字（后面常跟 "of Company"）
                if ($p -notmatch [regex]::Escape($candidate) + '\s*,\s*(?:CTO|CEO|VP)\s+of') {
                    $contact = $candidate
                    $jobTitle = if ($m.Value -match '(?i)co-?founder') { "Co-Founder" }
                                elseif ($m.Value -match '(?i)founder') { "Founder" }
                                elseif ($m.Value -match '(?i)ceo') { "CEO" }
                                elseif ($m.Value -match '(?i)cto') { "CTO" }
                                else { "Executive" }
                    break
                }
            }
            $emails += [regex]::Matches($p, '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-z]{2,}') |
                       ForEach-Object { $_.Value }
        }
    }

    $emails = $emails | Where-Object { $_ -notmatch '\.(png|jpg|gif|webp|svg)$' } | Select-Object -Unique
    $email = if ($emails) { ($emails -join "; ") } else { "" }

    $status = if ($domain -and ($contact -or $email)) { "verified" }
              elseif ($domain) { "partial" }
              else { "not_found" }

    $results += [pscustomobject]@{
        Name        = $r.Name
        Brand       = $brand
        City        = $r.City
        State       = $r.State
        AmountM     = $r.Sold
        Domain      = $domain
        Title       = $title
        Snippet     = if ($text.Length -gt 600) { $text.Substring(0, 600) } else { $text }
        Contact     = $contact
        JobTitle    = $jobTitle
        Email       = $email
        Status      = $status
    }
}

$dir = Split-Path $OutCsv -Parent
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
$results | Export-Csv $OutCsv -NoTypeInformation -Encoding UTF8

Write-Host "`n完成: $($results.Count) 家"
$results | Group-Object Status | ForEach-Object { Write-Host "  $($_.Name): $($_.Count)" }
Write-Host "已导出: $OutCsv"
