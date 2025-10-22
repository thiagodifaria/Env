function Install-NPMPackages {
    param(
        [array]$PackagesToInstall
    )
    
    Write-Log "Iniciando instalação de pacotes NPM globais" "INFO"
    Show-Box "Instalando Pacotes NPM Globais" "Cyan"
    
    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
    }
    
    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        Write-Status "Node.js não encontrado. Instale Node.js primeiro" "ERROR"
        Write-Log "NPM packages requerem Node.js instalado" "ERROR"
        $results.Failed += "NPM (Node.js não encontrado)"
        return $results
    }
    
    $total = $PackagesToInstall.Count
    $current = 0
    
    foreach ($pkg in $PackagesToInstall) {
        $current++
        Show-CategoryProgress -Category "NPM" -Current $current -Total $total
        
        try {
            $installed = npm list -g $pkg.npm_package 2>&1
            if ($installed -match $pkg.npm_package) {
                Write-Status "$($pkg.name) já instalado" "SKIP"
                $results.Skipped += $pkg.name
                continue
            }
        }
        catch {
        }
        
        Write-Status "Instalando $($pkg.name)..." "WORKING"
        
        $attempts = 0
        $success = $false
        
        while ($attempts -lt 3 -and -not $success) {
            $attempts++
            
            try {
                npm install -g $pkg.npm_package 2>&1 | Out-Null
                
                $check = npm list -g $pkg.npm_package 2>&1
                if ($check -match $pkg.npm_package -or (Get-Command $pkg.command -ErrorAction SilentlyContinue)) {
                    $success = $true
                    Write-Status "$($pkg.name) instalado com sucesso" "SUCCESS"
                    $results.Success += $pkg.name
                    Write-Log "✓ $($pkg.name) instalado via NPM" "SUCCESS"
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