function Test-PackageInstalled {
    param(
        [string]$PackageName,
        [string]$Command = $null
    )
    
    $chocoInstalled = Test-ChocoPackage -PackageName $PackageName
    
    if ($chocoInstalled) {
        return $true
    }
    
    if ($Command) {
        $commandExists = Test-CommandAvailable -Command $Command
        if ($commandExists) {
            return $true
        }
    }
    
    return $false
}

function Test-ChocoPackage {
    param([string]$PackageName)
    
    try {
        $installed = choco list --local-only $PackageName --exact --limit-output 2>$null
        return $installed -match "^$PackageName\|"
    }
    catch {
        return $false
    }
}

function Test-CommandAvailable {
    param([string]$Command)
    
    $result = Get-Command $Command -ErrorAction SilentlyContinue
    return $null -ne $result
}

function Test-ServiceRunning {
    param([string]$ServiceName)
    
    try {
        $service = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
        return $service.Status -eq "Running"
    }
    catch {
        return $false
    }
}

function Get-InstalledVersion {
    param([string]$PackageName)
    
    try {
        $output = choco list --local-only $PackageName --exact --limit-output 2>$null
        if ($output -match "^$PackageName\|(.+)$") {
            return $matches[1]
        }
    }
    catch {
        return "Unknown"
    }
    
    return "Unknown"
}

function Test-ConflictingPackages {
    param([array]$PackageList)
    
    $conflicts = @()
    
    $conflictMap = @{
        "python" = @("python", "python3")
        "nodejs" = @("nodejs", "node")
    }
    
    foreach ($pkg in $PackageList) {
        if ($pkg -match "python") {
            $storePython = Get-Command python -ErrorAction SilentlyContinue | Where-Object { $_.Source -match "WindowsApps" }
            if ($storePython) {
                $conflicts += @{
                    Package = $pkg
                    Conflict = "Python from Microsoft Store"
                    Action = "Remove Store version or skip Chocolatey install"
                }
            }
        }
    }
    
    return $conflicts
}

function Show-ConflictDialog {
    param(
        [hashtable]$Conflict,
        [string]$Language = "pt-br"
    )
    
    Write-Host ""
    Write-Host "⚠ Conflito detectado:" -ForegroundColor Yellow
    Write-Host "  Package: $($Conflict.Package)" -ForegroundColor White
    Write-Host "  Conflito: $($Conflict.Conflict)" -ForegroundColor White
    Write-Host "  Ação: $($Conflict.Action)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Escolha uma opção:" -ForegroundColor Yellow
    Write-Host "  [S] Skip - Pular instalação" -ForegroundColor White
    Write-Host "  [R] Replace - Substituir existente" -ForegroundColor White
    Write-Host "  [C] Cancel - Cancelar tudo" -ForegroundColor White
    Write-Host ""
    Write-Host "Opção: " -ForegroundColor Yellow -NoNewline
    
    $choice = Read-Host
    return $choice.ToUpper()
}

function Get-ValidationReport {
    param(
        [array]$PackagesToInstall,
        [string]$Language = "pt-br"
    )
    
    Write-Host ""
    Write-Host "Analisando sistema..." -ForegroundColor Yellow
    Write-Host ""
    
    $report = @{
        AlreadyInstalled = @()
        ToInstall = @()
        Conflicts = @()
    }
    
    $current = 0
    foreach ($pkg in $PackagesToInstall) {
        $current++
        Show-ProgressBar -Current $current -Total $PackagesToInstall.Count -Activity "Verificando $($pkg.name)..."
        
        if (Test-PackageInstalled -PackageName $pkg.choco_package -Command $pkg.command) {
            $report.AlreadyInstalled += $pkg
        } else {
            $report.ToInstall += $pkg
        }
        
        Start-Sleep -Milliseconds 100
    }
    
    Write-Host ""
    Write-Host ""
    
    if ($report.ToInstall.Count -gt 0) {
        $conflicts = Test-ConflictingPackages -PackageList $report.ToInstall.choco_package
        $report.Conflicts = $conflicts
    }
    
    return $report
}

function Show-ValidationReport {
    param(
        [hashtable]$Report,
        [string]$Language = "pt-br"
    )
    
    Write-Host "       RELATÓRIO DE VALIDAÇÃO           " -ForegroundColor Cyan
    Write-Host ""
    
    if ($Report.AlreadyInstalled.Count -gt 0) {
        Write-Host "✓ Já instalados: $($Report.AlreadyInstalled.Count) pacotes" -ForegroundColor Green
        foreach ($pkg in $Report.AlreadyInstalled | Select-Object -First 5) {
            Write-Host "  ⟲ $($pkg.name)" -ForegroundColor Cyan
        }
        if ($Report.AlreadyInstalled.Count -gt 5) {
            Write-Host "  ... e mais $($Report.AlreadyInstalled.Count - 5) pacotes" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    if ($Report.ToInstall.Count -gt 0) {
        Write-Host "➜ Serão instalados: $($Report.ToInstall.Count) pacotes" -ForegroundColor Yellow
        foreach ($pkg in $Report.ToInstall | Select-Object -First 5) {
            Write-Host "  • $($pkg.name)" -ForegroundColor White
        }
        if ($Report.ToInstall.Count -gt 5) {
            Write-Host "  ... e mais $($Report.ToInstall.Count - 5) pacotes" -ForegroundColor Gray
        }
        Write-Host ""
    }
    
    if ($Report.Conflicts.Count -gt 0) {
        Write-Host "⚠ Conflitos detectados: $($Report.Conflicts.Count)" -ForegroundColor Yellow
        foreach ($conflict in $Report.Conflicts) {
            Write-Host "  ⚠ $($conflict.Package) - $($conflict.Conflict)" -ForegroundColor Yellow
        }
        Write-Host ""
    }
    
    $totalPackages = $Report.AlreadyInstalled.Count + $Report.ToInstall.Count
    Write-Host "Total de pacotes: $totalPackages" -ForegroundColor White
    Write-Host ""
}

function Resolve-Conflicts {
    param(
        [array]$Conflicts,
        [string]$Language = "pt-br"
    )
    
    $resolutions = @()
    
    foreach ($conflict in $Conflicts) {
        $choice = Show-ConflictDialog -Conflict $conflict -Language $Language
        
        switch ($choice) {
            "S" {
                $resolutions += @{
                    Package = $conflict.Package
                    Action = "Skip"
                }
                Write-Status "Pulando $($conflict.Package)" "SKIP"
            }
            "R" {
                $resolutions += @{
                    Package = $conflict.Package
                    Action = "Replace"
                }
                Write-Status "Substituindo $($conflict.Package)" "WARNING"
            }
            "C" {
                Write-Host ""
                Write-Host "Instalação cancelada pelo usuário" -ForegroundColor Red
                exit 0
            }
            default {
                Write-Status "Opção inválida, pulando $($conflict.Package)" "SKIP"
                $resolutions += @{
                    Package = $conflict.Package
                    Action = "Skip"
                }
            }
        }
        Write-Host ""
    }
    
    return $resolutions
}