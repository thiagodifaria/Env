function Install-DevTools {
    param(
        [array]$PackagesToInstall
    )
    
    Write-Log "Iniciando instalação de ferramentas de desenvolvimento" "INFO"
    Show-Box "Instalando Ferramentas de Desenvolvimento" "Cyan"
    
    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
    }
    
    $gitPkg = $PackagesToInstall | Where-Object { $_.id -eq "git" }
    $otherPkgs = $PackagesToInstall | Where-Object { $_.id -ne "git" }
    
    $orderedPkgs = @()
    if ($gitPkg) { $orderedPkgs += $gitPkg }
    $orderedPkgs += $otherPkgs
    
    $total = $orderedPkgs.Count
    $current = 0
    
    foreach ($pkg in $orderedPkgs) {
        $current++
        Show-CategoryProgress -Category "DevTools" -Current $current -Total $total
        
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
                $chocoArgs = @($pkg.choco_package, '-y', '--no-progress')

                if ($pkg.checksum -and $pkg.checksum -ne "") {
                    $chocoArgs += "--checksum=$($pkg.checksum)"
                    $chocoArgs += "--checksum-type=$($pkg.checksumType)"
                    Write-Verbose "Usando checksum para validação"
                }

                choco install $chocoArgs 2>&1 | Out-Null

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