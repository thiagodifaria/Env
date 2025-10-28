function Install-Languages {
    param(
        [array]$PackagesToInstall
    )
    
    Write-Log "Iniciando instalação de linguagens" "INFO"
    Show-Box "Instalando Linguagens de Programação" "Cyan"
    
    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
    }
    
    $total = $PackagesToInstall.Count
    $current = 0
    
    foreach ($pkg in $PackagesToInstall) {
        $current++
        Show-CategoryProgress -Category "Languages" -Current $current -Total $total
        
        if (Test-PackageInstalled -PackageName $pkg.choco_package -Command $pkg.command) {
            Write-Status "$($pkg.name) já instalado" "SKIP"
            $results.Skipped += $pkg.name
            continue
        }
        
        Write-Status "Instalando $($pkg.name)..." "WORKING"
        
        $attempts = 0
        $success = $false
        $maxAttempts = 3
        
        while ($attempts -lt $maxAttempts -and -not $success) {
            $attempts++
            
            try {
                if ($pkg.version -eq "latest") {
                    choco install $pkg.choco_package -y --no-progress 2>&1 | Out-Null
                } else {
                    choco install $pkg.choco_package --version=$($pkg.version) -y --no-progress 2>&1 | Out-Null
                }
                
                if (Test-PackageInstalled -PackageName $pkg.choco_package) {
                    $success = $true
                    Write-Status "$($pkg.name) instalado com sucesso" "SUCCESS"
                    Add-InstalledPackage -PackageName $pkg.choco_package
                    $results.Success += $pkg.name
                    Write-Log "[OK] $($pkg.name) instalado" "SUCCESS"
                }
            }
            catch {
                Write-Log "Tentativa $attempts falhou para $($pkg.name): $_" "WARNING"
                
                if ($attempts -lt $maxAttempts) {
                    $waitTime = 5 * $attempts
                    Write-Host "  Aguardando ${waitTime}s antes de tentar novamente..." -ForegroundColor Gray
                    Start-Sleep -Seconds $waitTime
                }
            }
        }
        
        if (-not $success) {
            Write-Status "$($pkg.name) falhou após $maxAttempts tentativas" "ERROR"
            $results.Failed += $pkg.name
            Write-Log "[X] $($pkg.name) falhou" "ERROR"
        }
    }
    
    Write-Host ""
    return $results
}