param(
    [string]$MysqlExe = "C:\Program Files\MySQL\MySQL Server 8.0\bin\mysql.exe",
    [string]$Database = "electronics_retailer",
    [string]$User = "root",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $PSScriptRoot
$CleanedDir = Join-Path $ProjectRoot "data\cleaned"
$OutputsDir = Join-Path $ProjectRoot "outputs"
$TempDir = Join-Path $ProjectRoot ".tmp_exports"
$SummaryPath = Join-Path $OutputsDir "export_check_summary.txt"

New-Item -ItemType Directory -Force -Path $CleanedDir, $OutputsDir, $TempDir | Out-Null

if (-not (Test-Path -LiteralPath $MysqlExe)) {
    throw "mysql.exe was not found at: $MysqlExe"
}

$securePassword = Read-Host "Enter MySQL root password" -AsSecureString
$credential = New-Object System.Net.NetworkCredential("", $securePassword)
$previousMysqlPwd = $env:MYSQL_PWD
$env:MYSQL_PWD = $credential.Password

$results = New-Object System.Collections.Generic.List[object]

function Invoke-MySql {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,
        [switch]$SkipColumnNames
    )

    $args = @(
        "--batch",
        "--raw",
        "--default-character-set=utf8mb4",
        "-u", $User,
        $Database,
        "--execute=$Query"
    )

    if ($SkipColumnNames) {
        $args = @("--skip-column-names") + $args
    }

    $output = & $MysqlExe @args 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw ($output -join [Environment]::NewLine)
    }

    return $output
}

function Test-MySqlObject {
    param([string]$ObjectName)

    $escaped = $ObjectName.Replace("'", "''")
    $query = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = '$escaped';"
    $count = Invoke-MySql -Query $query -SkipColumnNames
    return ([int]$count[0]) -gt 0
}

function Get-QueryRowCount {
    param([string]$Query)

    $countQuery = "SELECT COUNT(*) FROM ($Query) export_count_source;"
    $count = Invoke-MySql -Query $countQuery -SkipColumnNames
    return [int]$count[0]
}

function Export-QueryToCsv {
    param(
        [string]$Name,
        [string]$Query,
        [string]$OutputPath
    )

    $status = "Unknown"
    $rowCount = 0
    $fileSize = 0

    try {
        $shouldSkip = $false
        if ((Test-Path -LiteralPath $OutputPath) -and (-not $Force)) {
            $existingItem = Get-Item -LiteralPath $OutputPath
            $existingRows = 0
            if ($existingItem.Length -gt 0) {
                try {
                    $existingRows = @(Import-Csv -LiteralPath $OutputPath).Count
                }
                catch {
                    $existingRows = 0
                }
            }
            $shouldSkip = $existingItem.Length -gt 1024 -and $existingRows -gt 0
        }

        if ($shouldSkip) {
            $fileSize = (Get-Item -LiteralPath $OutputPath).Length
            $results.Add([PSCustomObject]@{
                FileName = Split-Path -Leaf $OutputPath
                Status = "Skipped existing non-empty file"
                FileSizeKB = [Math]::Round($fileSize / 1KB, 2)
                RowCount = $existingRows
            })
            Write-Host "SKIP: $OutputPath already exists and is not empty. Use -Force to replace it."
            return
        }

        $rowCount = Get-QueryRowCount -Query $Query
        $tempFile = Join-Path $TempDir "$Name.tsv"

        $exportQuery = "$Query;"
        $args = @(
            "--batch",
            "--raw",
            "--default-character-set=utf8mb4",
            "-u", $User,
            $Database,
            "--execute=$exportQuery"
        )

        $tsvOutput = & $MysqlExe @args 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw ($tsvOutput -join [Environment]::NewLine)
        }

        $tsvOutput | Set-Content -LiteralPath $tempFile -Encoding UTF8

        if ($rowCount -gt 0) {
            Import-Csv -LiteralPath $tempFile -Delimiter "`t" | Export-Csv -LiteralPath $OutputPath -NoTypeInformation -Encoding UTF8
        } else {
            $header = Get-Content -LiteralPath $tempFile -TotalCount 1
            $header -replace "`t", "," | Set-Content -LiteralPath $OutputPath -Encoding UTF8
        }

        $fileSize = (Get-Item -LiteralPath $OutputPath).Length
        $status = if ($rowCount -gt 0 -and $fileSize -gt 0) { "Exported with data" } else { "Exported header only / no data" }
        Write-Host "OK: $OutputPath ($rowCount rows)"
    }
    catch {
        $status = "ERROR: $($_.Exception.Message)"
        Write-Host "ERROR: $OutputPath"
        Write-Host $_.Exception.Message
    }

    $results.Add([PSCustomObject]@{
        FileName = Split-Path -Leaf $OutputPath
        Status = $status
        FileSizeKB = [Math]::Round($fileSize / 1KB, 2)
        RowCount = $rowCount
    })
}

try {
    $compatViews = @(
        @{ Name = "sales_reporting_view"; Source = "rpt_sales" },
        @{ Name = "monthly_sales_summary"; Source = "rpt_monthly_sales" },
        @{ Name = "product_performance_summary"; Source = "rpt_product_performance" },
        @{ Name = "country_sales_summary"; Source = "rpt_country_sales" },
        @{ Name = "store_performance_summary"; Source = "rpt_store_performance" },
        @{ Name = "category_performance_summary"; Source = "rpt_category_performance" },
        @{ Name = "customer_summary"; Source = "rpt_customer_summary" }
    )

    foreach ($view in $compatViews) {
        if (Test-MySqlObject -ObjectName $view.Source) {
            Invoke-MySql -Query "CREATE OR REPLACE VIEW $($view.Name) AS SELECT * FROM $($view.Source);" | Out-Null
        }
        elseif (-not (Test-MySqlObject -ObjectName $view.Name)) {
            Write-Host "WARNING: Neither $($view.Name) nor fallback $($view.Source) exists."
        }
    }

    $exports = @(
        @{
            Name = "sales_reporting_view"
            Query = "SELECT * FROM sales_reporting_view"
            OutputPath = Join-Path $CleanedDir "sales_reporting_view.csv"
        },
        @{
            Name = "final_kpi_summary"
            Query = "SELECT COUNT(DISTINCT order_number) AS total_orders, COUNT(*) AS total_sales_lines, SUM(quantity) AS total_units_sold, ROUND(SUM(revenue_usd), 2) AS total_revenue_usd, ROUND(SUM(cost_usd), 2) AS total_cost_usd, ROUND(SUM(profit_usd), 2) AS total_profit_usd, ROUND(SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0), 4) AS profit_margin FROM sales_reporting_view"
            OutputPath = Join-Path $OutputsDir "final_kpi_summary.csv"
        },
        @{
            Name = "monthly_sales_report"
            Query = "SELECT * FROM monthly_sales_summary"
            OutputPath = Join-Path $OutputsDir "monthly_sales_report.csv"
        },
        @{
            Name = "product_performance_report"
            Query = "SELECT * FROM product_performance_summary"
            OutputPath = Join-Path $OutputsDir "product_performance_report.csv"
        },
        @{
            Name = "country_sales_report"
            Query = "SELECT * FROM country_sales_summary"
            OutputPath = Join-Path $OutputsDir "country_sales_report.csv"
        },
        @{
            Name = "store_performance_report"
            Query = "SELECT * FROM store_performance_summary"
            OutputPath = Join-Path $OutputsDir "store_performance_report.csv"
        },
        @{
            Name = "category_performance_report"
            Query = "SELECT * FROM category_performance_summary"
            OutputPath = Join-Path $OutputsDir "category_performance_report.csv"
        },
        @{
            Name = "customer_summary_report"
            Query = "SELECT * FROM customer_summary"
            OutputPath = Join-Path $OutputsDir "customer_summary_report.csv"
        }
    )

    foreach ($export in $exports) {
        Export-QueryToCsv -Name $export.Name -Query $export.Query -OutputPath $export.OutputPath
    }

    $results | Format-Table -AutoSize

    $summaryLines = @()
    $summaryLines += "Export check summary"
    $summaryLines += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $summaryLines += "Database: $Database"
    $summaryLines += ""
    foreach ($result in $results) {
        $summaryLines += "$($result.FileName) | $($result.Status) | $($result.FileSizeKB) KB | $($result.RowCount) rows"
    }
    $summaryLines | Set-Content -LiteralPath $SummaryPath -Encoding UTF8

    Write-Host ""
    Write-Host "Summary written to: $SummaryPath"
}
finally {
    $env:MYSQL_PWD = $previousMysqlPwd
    if (Test-Path -LiteralPath $TempDir) {
        Remove-Item -LiteralPath $TempDir -Recurse -Force
    }
}
