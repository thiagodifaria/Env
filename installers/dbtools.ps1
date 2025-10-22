function Install-DBTools {
    param(
        [array]$PackagesToInstall
    )
    
    Write-Log "Iniciando instalação de banco de dados" "INFO"
    Show-Box "Instalando Ferramentas de Banco de Dados" "Cyan"
    
    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
    }
    
    $dbServers = $PackagesToInstall | Where-Object { $_.id -match "^(postgresql|mongodb)$" }
    $dbClients = $PackagesToInstall | Where-Object { $_.id -notmatch "^(postgresql|mongodb)$" }
    
    $orderedPkgs = @()
    $orderedPkgs += $dbServers
    $orderedPkgs += $dbClients
    
    $total = $orderedPkgs.Count
    $current = 0
    
    foreach ($pkg in $orderedPkgs) {
        $current++
        Show-CategoryProgress -Category "DBTools" -Current $current -Total $total
        
        if (Test-PackageInstalled -PackageName $pkg.choco_package -Command $pkg.command) {
            Write-Status "$($pkg.name) já instalado" "SKIP"
            $results.Skipped += $pkg.name
            continue
        }
        
        Write-Status "Instalando $($pkg.name)..." "WORKING"
        
        $attempts = 0
        $success = $false
        
        while ($attempts -lt 3 -and -not $success) {
            $attempts++
            
            try {
                choco install $pkg.choco_package -y --no-progress 2>&1 | Out-Null
                
                if (Test-PackageInstalled -PackageName $pkg.choco_package) {
                    $success = $true
                    Write-Status "$($pkg.name) instalado com sucesso" "SUCCESS"
                    Add-InstalledPackage -PackageName $pkg.choco_package
                    $results.Success += $pkg.name
                    Write-Log "✓ $($pkg.name) instalado" "SUCCESS"
                }
            }
            catch {
                Write-Log "Tentativa $attempts falhou para $($pkg.name): $_" "WARNING"
                if ($attempts -lt 3) {
                    Start-Sleep -Seconds (5 * $attempts)
                }
            }
        }
        
        if (-not $success) {
            Write-Status "$($pkg.name) falhou após 3 tentativas" "ERROR"
            $results.Failed += $pkg.name
            Write-Log "✗ $($pkg.name) falhou" "ERROR"
        }
    }
    
    Write-Host ""
    return $results
}