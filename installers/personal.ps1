function Install-Personal {
    param(
        [array]$PackagesToInstall
    )
    
    Write-Log "Iniciando instalação de aplicativos pessoais" "INFO"
    Show-Box "Instalando Aplicativos Pessoais" "Cyan"
    
    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
    }
    
    $total = $PackagesToInstall.Count
    $current = 0
    
    foreach ($pkg in $PackagesToInstall) {
        $current++
        Show-CategoryProgress -Category "Personal" -Current $current -Total $total
        
        if (Test-PackageInstalled -PackageName $pkg.choco_package) {
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
                    Write-Log "[OK] $($pkg.name) instalado" "SUCCESS"
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
            Write-Log "[X] $($pkg.name) falhou" "ERROR"
        }
    }
    
    Write-Host ""
    return $results
}