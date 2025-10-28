[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Preset,

    [Parameter(Mandatory=$false)]
    [string]$Language = "pt-br",

    [Parameter(Mandatory=$false)]
    [switch]$Silent,

    [Parameter(Mandatory=$false)]
    [switch]$SkipValidation,

    [Parameter(Mandatory=$false)]
    [switch]$SkipBackup,

    [Parameter(Mandatory=$false)]
    [switch]$NoCache,

    [Parameter(Mandatory=$false)]
    [string[]]$Categories,

    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 10)]
    [int]$MaxParallel = 3,

    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [string]$ConfigPath = "$PSScriptRoot\config\packages.json"
)

try {
    $projectRoot = $PSScriptRoot
    Get-ChildItem -Path $projectRoot -Recurse -Filter "*.ps1" -ErrorAction SilentlyContinue | 
        ForEach-Object {
            Unblock-File -Path $_.FullName -ErrorAction SilentlyContinue
        }
}
catch {
}

$ErrorActionPreference = "Continue"

try {
    . "$PSScriptRoot\core\utils.ps1"
    . "$PSScriptRoot\core\logger.ps1"
    . "$PSScriptRoot\core\state.ps1"
    . "$PSScriptRoot\core\ui.ps1"
    . "$PSScriptRoot\core\validator.ps1"
    . "$PSScriptRoot\core\packages.ps1"
    . "$PSScriptRoot\core\backup.ps1"
    . "$PSScriptRoot\core\error-handler.ps1"

    . "$PSScriptRoot\installers\languages.ps1"
    . "$PSScriptRoot\installers\devtools.ps1"
    . "$PSScriptRoot\installers\webtools.ps1"
    . "$PSScriptRoot\installers\dbtools.ps1"
    . "$PSScriptRoot\installers\observability.ps1"
    . "$PSScriptRoot\installers\personal.ps1"
    . "$PSScriptRoot\installers\wsl.ps1"
    . "$PSScriptRoot\installers\npm-packages.ps1"

    . "$PSScriptRoot\utils\cache.ps1"
    . "$PSScriptRoot\utils\parallel.ps1"
}
catch {
    Write-Host "Erro ao carregar módulos: $_" -ForegroundColor Red
    Write-Host "Verifique se todos os arquivos existem no diretório." -ForegroundColor Yellow
    exit 1
}

Initialize-Log
Initialize-State

trap {
    Write-Host ""
    Write-Host ""
    if (Get-Command Write-Log -ErrorAction SilentlyContinue) {
        Write-Log "Instalação interrompida pelo usuário" "WARNING"
    }
    Write-Host "Instalação interrompida. Estado parcial foi salvo." -ForegroundColor Yellow
    Write-Host "Execute novamente para continuar de onde parou." -ForegroundColor Yellow
    exit 130
}

function Test-Environment {
    Write-Host "$(Get-String 'checking' $Language)" -ForegroundColor Yellow
    Write-Host ""

    $prereqs = Test-Prerequisites

    if ($prereqs.PowerShellVersion -lt [Version]"5.1") {
        Write-Status "PowerShell 5.1 ou superior é necessário (atual: $($prereqs.PowerShellVersion))" "ERROR"
        exit 1
    }
    Write-Status "PowerShell $($prereqs.PowerShellVersion)" "SUCCESS"

    if (-not (Test-Administrator)) {
        Write-Status "$(Get-String 'admin_required' $Language)" "ERROR"

        if (-not $Silent) {
            $response = Read-Host "Deseja reiniciar como administrador? (Y/N)"
            if ($response -eq 'Y' -or $response -eq 'y') {
                $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
                if ($Preset) { $arguments += " -Preset $Preset" }
                if ($Categories) { $arguments += " -Categories $($Categories -join ',')" }
                Start-Process powershell -Verb RunAs -ArgumentList $arguments
                exit
            }
        }
        exit 1
    }
    Write-Status "Administrador" "SUCCESS"

    if (-not (Test-DiskSpace)) {
        Write-Status "$(Get-String 'disk_low' $Language)" "ERROR"
        exit 1
    }
    Write-Status "Espaço em disco" "SUCCESS"

    if (-not (Test-NetworkConnection)) {
        Write-Status "$(Get-String 'no_internet' $Language)" "ERROR"
        exit 1
    }
    Write-Status "Conexão de internet" "SUCCESS"

    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "$(Get-String 'installing_choco' $Language)" -ForegroundColor Yellow
        if (Install-Chocolatey) {
            Write-Status "Chocolatey instalado" "SUCCESS"
        } else {
            Write-Status "Erro ao instalar Chocolatey" "ERROR"
            exit 1
        }
    } else {
        Write-Status "$(Get-String 'choco_installed' $Language)" "SUCCESS"
    }

    if (-not $SkipBackup) {
        Write-Host ""
        Write-Host "Criando backup de configuração..." -ForegroundColor Cyan
        try {
            Backup-ConfigurationAuto | Out-Null
            Write-Status "Backup criado com sucesso" "SUCCESS"
        }
        catch {
            Write-Status "Aviso: Não foi possível criar backup" "WARNING"
        }
    }

    Write-Host ""
    Write-Host "Validando configuração..." -ForegroundColor Cyan
    $configValid = Test-PackagesConfig -ConfigPath $ConfigPath

    if (-not $configValid) {
        Write-Status "Configuração de packages inválida" "ERROR"
        exit 1
    }
    Write-Status "Configuração validada" "SUCCESS"

    Write-Host ""
    Write-Status "$(Get-String 'validation_ok' $Language)" "SUCCESS"
    Write-Host ""
}

function Show-SystemInfo {
    $info = Get-SystemInfo
    
    Write-Host "$(Get-String 'system_info' $Language):" -ForegroundColor Cyan
    Write-Host "  $(Get-String 'os' $Language): $($info.OS)" -ForegroundColor White
    Write-Host "  $(Get-String 'ram' $Language): $($info.RAM)" -ForegroundColor White
    Write-Host "  $(Get-String 'disk' $Language): $($info.Disk)" -ForegroundColor White
    Write-Host "  $(Get-String 'powershell' $Language): $($info.PowerShell)" -ForegroundColor White
    Write-Host ""
}

function Load-PackagesConfig {
    $packagesPath = "$PSScriptRoot\config\packages.json"
    return Get-Content $packagesPath | ConvertFrom-Json
}

function Load-PresetsConfig {
    $presetsPath = "$PSScriptRoot\config\presets.json"
    return Get-Content $presetsPath | ConvertFrom-Json
}

function Get-PackagesForMode {
    param(
        [string]$Mode,
        [string[]]$SelectedCategories = $null
    )
    
    $allPackages = Load-PackagesConfig
    $presets = Load-PresetsConfig
    
    $categorizedPackages = @{}
    
    switch ($Mode.ToLower()) {
        "complete" {
            $preset = $presets.difaria
            foreach ($category in $preset.categories) {
                if ($category -ne "wsl") {
                    $categorizedPackages[$category] = $allPackages.$category
                }
            }
            $categorizedPackages["wsl"] = @()
        }
        "developer" {
            $preset = $presets.developer
            foreach ($category in $preset.categories) {
                if ($category -ne "wsl") {
                    $categorizedPackages[$category] = $allPackages.$category
                }
            }
            $categorizedPackages["wsl"] = @()
        }
        "personal" {
            $categorizedPackages["personal"] = $allPackages.personal
        }
        "minimal" {
            $preset = $presets.minimal
            $categorizedPackages["devtools"] = @()
            if ($preset.packages) {
                foreach ($pkgId in $preset.packages) {
                    foreach ($category in $allPackages.PSObject.Properties.Name) {
                        $found = $allPackages.$category | Where-Object { $_.id -eq $pkgId }
                        if ($found) {
                            $categorizedPackages["devtools"] += $found
                            break
                        }
                    }
                }
            }
        }
        "custom" {
            if ($SelectedCategories) {
                $categoryMap = @{
                    "1" = "languages"
                    "2" = "devtools"
                    "3" = "webtools"
                    "4" = "dbtools"
                    "5" = "observability"
                    "6" = "personal"
                    "7" = "wsl"
                    "8" = "npm"
                }
                
                foreach ($num in $SelectedCategories) {
                    $category = $categoryMap[$num.Trim()]
                    if ($category) {
                        if ($category -eq "wsl") {
                            $categorizedPackages["wsl"] = @()
                        } else {
                            $categorizedPackages[$category] = $allPackages.$category
                        }
                    }
                }
            }
        }
    }
    
    return $categorizedPackages
}

function Retry-FailedPackages {
    param(
        [array]$FailedPackages,
        [string]$Language = "pt-br"
    )
    
    Write-Host ""
    Show-Box "Tentando reinstalar pacotes que falharam..." "Yellow"
    
    $allPackages = Load-PackagesConfig
    $retryResults = @{
        Success = @()
        Failed = @()
    }
    
    foreach ($failedPkg in $FailedPackages) {
        $pkg = $null
        foreach ($category in $allPackages.PSObject.Properties.Name) {
            $found = $allPackages.$category | Where-Object { $_.name -eq $failedPkg }
            if ($found) {
                $pkg = $found
                break
            }
        }
        
        if (-not $pkg) {
            Write-Status "Package $failedPkg não encontrado na configuração" "ERROR"
            $retryResults.Failed += $failedPkg
            continue
        }
        
        Write-Status "Tentando reinstalar $($pkg.name)..." "WORKING"
        
        try {
            if ($pkg.version -eq "latest") {
                choco install $pkg.choco_package -y --force --no-progress 2>&1 | Out-Null
            } else {
                choco install $pkg.choco_package --version=$($pkg.version) -y --force --no-progress 2>&1 | Out-Null
            }
            
            if (Test-PackageInstalled -PackageName $pkg.choco_package) {
                Write-Status "$($pkg.name) instalado com sucesso" "SUCCESS"
                Add-InstalledPackage -PackageName $pkg.choco_package
                $retryResults.Success += $failedPkg
            } else {
                throw "Verificação de instalação falhou"
            }
        }
        catch {
            Write-Status "$($pkg.name) falhou novamente" "ERROR"
            $retryResults.Failed += $failedPkg
        }
    }
    
    Write-Host ""
    Write-Host "Resultado do retry:" -ForegroundColor Cyan
    Write-Host "  [OK] Sucesso: $($retryResults.Success.Count)" -ForegroundColor Green
    Write-Host "  [X] Falhou: $($retryResults.Failed.Count)" -ForegroundColor Red
    Write-Host ""
    
    return $retryResults
}

function Start-Installation {
    param(
        [string]$Mode,
        [string[]]$CustomCategories = $null
    )

    $startTime = Get-Date

    Show-Box "Preparando instalação..." "Yellow"

    $categorizedPackages = Get-PackagesForMode -Mode $Mode -SelectedCategories $CustomCategories

    $totalPackages = 0
    foreach ($category in $categorizedPackages.Keys) {
        $totalPackages += $categorizedPackages[$category].Count
    }

    Write-Log "Modo: $Mode - Total de pacotes: $totalPackages" "INFO"

    $allPackages = @()
    foreach ($category in $categorizedPackages.Keys) {
        $allPackages += $categorizedPackages[$category]
    }

    $sessionId = $null
    if ($allPackages.Count -gt 0) {
        $sessionId = Start-InstallationSession -Description "ENV Setup - Mode: $Mode"
    }

    try {
        if ($allPackages.Count -gt 0) {
            $report = Get-ValidationReport -PackagesToInstall $allPackages -Language $Language
            Show-ValidationReport -Report $report -Language $Language

            if ($report.Conflicts.Count -gt 0) {
                Write-Host "Resolvendo conflitos..." -ForegroundColor Yellow
                Write-Host ""
                $resolutions = Resolve-Conflicts -Conflicts $report.Conflicts -Language $Language

                foreach ($resolution in $resolutions) {
                    if ($resolution.Action -eq "Skip") {
                        foreach ($category in $categorizedPackages.Keys) {
                            $categorizedPackages[$category] = $categorizedPackages[$category] | Where-Object {
                                $_.name -ne $resolution.Package
                            }
                        }
                    }
                }
            }

            if ($report.ToInstall.Count -eq 0) {
                Show-Box "Nenhum pacote para instalar. Tudo já está instalado!" "Green"
                if ($sessionId) {
                    Stop-InstallationSession -SessionId $sessionId -Status 'Completed'
                }
                return
            }

            if (-not $Silent) {
                $confirm = Show-ConfirmationDialog -Message "Deseja prosseguir com a instalação?" -Language $Language
                if (-not $confirm) {
                    Write-Host ""
                    Write-Host "Instalação cancelada pelo usuário" -ForegroundColor Yellow
                    if ($sessionId) {
                        Stop-InstallationSession -SessionId $sessionId -Status 'Cancelled'
                    }
                    return
                }
            }
        }

        Show-Box "$(Get-String 'installation_starting' $Language)" "Yellow"

        $globalResults = @{
            Success = @()
            Failed = @()
            Skipped = @()
        }

        $categoryOrder = @("languages", "devtools", "webtools", "dbtools", "observability", "personal", "wsl", "npm")
        $categoriesToInstall = $categoryOrder | Where-Object { $categorizedPackages.ContainsKey($_) }
        $totalCategories = $categoriesToInstall.Count
        $currentCategoryNum = 0

        foreach ($category in $categoriesToInstall) {
            $currentCategoryNum++

            $categoryDisplayNames = @{
                "languages" = "Linguagens de Programação"
                "devtools" = "Ferramentas de Desenvolvimento"
                "webtools" = "Ferramentas Web"
                "dbtools" = "Banco de Dados"
                "observability" = "Observabilidade"
                "personal" = "Aplicativos Pessoais"
                "wsl" = "Windows Subsystem for Linux"
                "npm" = "Pacotes NPM"
            }

            Show-GlobalProgress -CurrentCategory $currentCategoryNum -TotalCategories $totalCategories -CategoryName $categoryDisplayNames[$category]

            $packages = $categorizedPackages[$category]

            if ($category -eq "wsl" -or $packages.Count -eq 0) {
                if ($category -eq "wsl") {
                    $result = Install-WSL
                    $globalResults.Success += $result.Success
                    $globalResults.Failed += $result.Failed
                    $globalResults.Skipped += $result.Skipped
                }
                continue
            }

            $result = switch ($category) {
                "languages" { Install-Languages -PackagesToInstall $packages }
                "devtools" { Install-DevTools -PackagesToInstall $packages }
                "webtools" { Install-WebTools -PackagesToInstall $packages }
                "dbtools" { Install-DBTools -PackagesToInstall $packages }
                "observability" { Install-Observability -PackagesToInstall $packages }
                "personal" { Install-Personal -PackagesToInstall $packages }
                "npm" { Install-NPMPackages -PackagesToInstall $packages }
            }

            $globalResults.Success += $result.Success
            $globalResults.Failed += $result.Failed
            $globalResults.Skipped += $result.Skipped
        }

        $endTime = Get-Date
        $duration = $endTime - $startTime

        Write-Host ""
        Show-Box "$(Get-String 'installation_complete' $Language)" "Green"

        Show-FinalReport -Results $globalResults -Duration $duration -LogPath $script:LogFile -Language $Language

        if ($sessionId) {
            if ($globalResults.Failed.Count -gt 0) {
                Stop-InstallationSession -SessionId $sessionId -Status 'Failed'
            } else {
                Stop-InstallationSession -SessionId $sessionId -Status 'Completed'
            }
        }

        if ($globalResults.Failed.Count -gt 0 -and -not $Silent) {
            $retry = Show-ConfirmationDialog -Message "Deseja tentar reinstalar os pacotes que falharam?" -Language $Language

            if ($retry) {
                $retryResults = Retry-FailedPackages -FailedPackages $globalResults.Failed -Language $Language

                $globalResults.Success += $retryResults.Success
                $globalResults.Failed = $retryResults.Failed

                Write-Host ""
                Write-Host "Resultado final após retry:" -ForegroundColor Cyan
                Write-Host "  [OK] Total instalados: $($globalResults.Success.Count)" -ForegroundColor Green
                Write-Host "  [X] Total falhados: $($globalResults.Failed.Count)" -ForegroundColor Red
                Write-Host ""
            }
        }

        Export-LogReport -Report $globalResults

        if ($categoriesToInstall -contains "wsl" -and $globalResults.Success -match "WSL") {
            Write-Host ""
            Write-Host "  ATENÇÃO: REINICIALIZAÇÃO NECESSÁRIA  " -ForegroundColor Yellow
            Write-Host ""
            Write-Host "O WSL foi instalado e requer reinicialização do sistema." -ForegroundColor White
            Write-Host "Após reiniciar, você precisará configurar o Ubuntu na primeira execução." -ForegroundColor White
            Write-Host ""
        }

        if ($globalResults.Success.Count -gt 0) {
            Write-Host ""
            Write-Host "Próximos passos:" -ForegroundColor Cyan
            Write-Host "  1. Reinicie o terminal para aplicar as mudanças" -ForegroundColor Gray
            Write-Host "  2. Execute 'Get-InstalledPackagesFromState' para ver packages instalados" -ForegroundColor Gray
            Write-Host "  3. Configure seu terminal com 'Set-CustomPrompt'" -ForegroundColor Gray
            Write-Host ""
        }
    }
    catch {
        Write-ErrorLog -ErrorMessage $_.Exception.Message -Context @{
            Operation = "Installation"
            SessionId = $sessionId
            Mode = $Mode
        }

        if ($sessionId) {
            Stop-InstallationSession -SessionId $sessionId -Status 'Failed'
        }

        Write-Host ""
        Write-Host "Erro durante instalação: $_" -ForegroundColor Red
        Write-Host "Verifique os logs em: $(Get-EnvRoot)\logs" -ForegroundColor Yellow

        throw
    }
}

Show-Banner -Language $Language

if (-not $SkipValidation) {
    Test-Environment
    Show-SystemInfo
    
    Compare-StateWithSystem
    
    Write-Host "$(Get-String 'press_any_key' $Language)" -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

if ($Preset) {
    Write-Log "Executando preset via CLI: $Preset" "INFO"
    
    if ($Categories) {
        $categoryNums = $Categories -split ','
        Start-Installation -Mode "Custom" -CustomCategories $categoryNums
    } else {
        Start-Installation -Mode $Preset
    }
} elseif ($Categories) {
    Write-Log "Executando categorias via CLI: $($Categories -join ', ')" "INFO"
    $categoryNums = $Categories -split ','
    Start-Installation -Mode "Custom" -CustomCategories $categoryNums
} else {
    Show-Banner -Language $Language
    
    $choice = Show-MainMenu -Language $Language
    
    switch ($choice) {
        "1" { 
            Start-Installation -Mode "Complete"
        }
        "2" { 
            Start-Installation -Mode "Developer"
        }
        "3" { 
            Start-Installation -Mode "Personal"
        }
        "4" {
            $selected = Show-CategoryMenu -Language $Language
            
            if ([string]::IsNullOrWhiteSpace($selected)) {
                Write-Status "Nenhuma categoria selecionada" "ERROR"
                exit 1
            }
            
            Write-Log "Categorias selecionadas: $selected" "INFO"
            
            $categoryNums = $selected -split ',' | ForEach-Object { $_.Trim() }
            
            $validNums = @("1","2","3","4","5","6","7","8")
            $invalidNums = $categoryNums | Where-Object { $_ -notin $validNums }
            
            if ($invalidNums.Count -gt 0) {
                Write-Status "Números inválidos: $($invalidNums -join ', ')" "ERROR"
                exit 1
            }
            
            Start-Installation -Mode "Custom" -CustomCategories $categoryNums
        }
        "5" {
            Write-Host ""
            Write-Host "Saindo..." -ForegroundColor Yellow
            exit 0
        }
        default {
            Write-Status "$(Get-String 'invalid_option' $Language)" "ERROR"
            exit 1
        }
    }
}

Write-Log "Setup concluído" "SUCCESS"