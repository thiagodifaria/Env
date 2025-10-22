function Install-WSL {
    Write-Log "Iniciando instalação do WSL" "INFO"
    Show-Box "Instalando Windows Subsystem for Linux" "Cyan"
    
    $results = @{
        Success = @()
        Failed = @()
        Skipped = @()
    }
    
    $wslInstalled = $false
    try {
        $wslStatus = wsl --status 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Status "WSL já está instalado" "SKIP"
            $results.Skipped += "WSL"
            $wslInstalled = $true
        }
    }
    catch {
    }
    
    if (-not $wslInstalled) {
        Write-Status "Habilitando Windows Subsystem for Linux..." "WORKING"
        
        try {
            dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
            Write-Status "Feature WSL habilitada" "SUCCESS"
            
            Write-Status "Habilitando Virtual Machine Platform..." "WORKING"
            dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
            Write-Status "Feature Virtual Machine habilitada" "SUCCESS"
            
            Write-Status "Configurando WSL 2 como padrão..." "WORKING"
            wsl --set-default-version 2 2>&1 | Out-Null
            Write-Status "WSL 2 configurado" "SUCCESS"
            
            Write-Status "Instalando Ubuntu..." "WORKING"
            wsl --install -d Ubuntu 2>&1 | Out-Null
            
            if ($LASTEXITCODE -eq 0) {
                Write-Status "Ubuntu instalado com sucesso" "SUCCESS"
                $results.Success += "WSL Ubuntu"
                Write-Log "✓ WSL e Ubuntu instalados" "SUCCESS"
                
                Write-Host ""
                Write-Host "ATENÇÃO: É necessário reiniciar o sistema para concluir a instalação do WSL" -ForegroundColor Yellow
                Write-Host ""
            } else {
                throw "Falha ao instalar Ubuntu"
            }
        }
        catch {
            Write-Status "Erro ao instalar WSL: $_" "ERROR"
            $results.Failed += "WSL"
            Write-Log "✗ WSL falhou: $_" "ERROR"
        }
    }
    
    Write-Host ""
    return $results
}