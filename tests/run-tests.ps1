[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Unit', 'Integration', 'All')]
    [string]$TestType = 'All',

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$TestPath,

    [Parameter(Mandatory=$false)]
    [switch]$CodeCoverage,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 100)]
    [int]$MinimumCoverage = 80
)

try {
    Write-Host "Iniciando testes ENV..." -ForegroundColor Cyan

    if (-not (Get-Module -ListAvailable -Name Pester)) {
        Write-Host "Instalando Pester..." -ForegroundColor Yellow
        Install-Module -Name Pester -Force -SkipPublisherCheck -Scope CurrentUser
    }

    Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop

    $testRoot = $PSScriptRoot

    $testPaths = @()
    if ($TestPath) {
        $testPaths += $TestPath
    }
    else {
        switch ($TestType) {
            'Unit' { $testPaths += Join-Path $testRoot "unit\*.tests.ps1" }
            'Integration' { $testPaths += Join-Path $testRoot "integration\*.tests.ps1" }
            'All' {
                $testPaths += Join-Path $testRoot "unit\*.tests.ps1"
                $testPaths += Join-Path $testRoot "integration\*.tests.ps1"
            }
        }
    }

    $config = New-PesterConfiguration
    $config.Run.Path = $testPaths
    $config.Run.PassThru = $true
    $config.Output.Verbosity = 'Detailed'
    $config.TestResult.Enabled = $true
    $config.TestResult.OutputPath = Join-Path $testRoot "results\test-results.xml"
    $config.TestResult.OutputFormat = 'NUnitXml'

    if ($CodeCoverage) {
        $config.CodeCoverage.Enabled = $true
        $config.CodeCoverage.Path = @(
            "$PSScriptRoot\..\core\*.ps1",
            "$PSScriptRoot\..\installers\*.ps1",
            "$PSScriptRoot\..\utils\*.ps1"
        )
        $config.CodeCoverage.OutputPath = Join-Path $testRoot "results\coverage.xml"
        $config.CodeCoverage.OutputFormat = 'JaCoCo'
    }

    $resultsDir = Join-Path $testRoot "results"
    if (-not (Test-Path $resultsDir)) {
        New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
    }

    Write-Host "`nExecutando testes..." -ForegroundColor Cyan
    $result = Invoke-Pester -Configuration $config

    Write-Host "Resultado dos Testes" -ForegroundColor Cyan
    Write-Host "Total: $($result.TotalCount)" -ForegroundColor White
    Write-Host "Passou: $($result.PassedCount)" -ForegroundColor Green
    Write-Host "Falhou: $($result.FailedCount)" -ForegroundColor Red
    Write-Host "Ignorado: $($result.SkippedCount)" -ForegroundColor Yellow
    Write-Host "Duração: $($result.Duration)" -ForegroundColor Gray

    if ($CodeCoverage -and $result.CodeCoverage) {
        $coverage = $result.CodeCoverage
        $coveragePercent = [math]::Round(($coverage.CommandsExecutedCount / $coverage.CommandsAnalyzedCount) * 100, 2)

        Write-Host "Cobertura de Código" -ForegroundColor Cyan
        Write-Host "Comandos Analisados: $($coverage.CommandsAnalyzedCount)" -ForegroundColor White
        Write-Host "Comandos Executados: $($coverage.CommandsExecutedCount)" -ForegroundColor White
        Write-Host "Cobertura: $coveragePercent%" -ForegroundColor $(if ($coveragePercent -ge $MinimumCoverage) { 'Green' } else { 'Red' })

        if ($coveragePercent -lt $MinimumCoverage) {
            Write-Warning "Cobertura de código abaixo do mínimo esperado ($MinimumCoverage%)"
        }
    }

    if ($result.FailedCount -gt 0) {
        Write-Host "`n[X] Testes falharam" -ForegroundColor Red
        exit 1
    }

    Write-Host "`n[OK] Todos os testes passaram" -ForegroundColor Green
    exit 0
}
catch {
    Write-Error "Erro ao executar testes: $_"
    exit 1
}