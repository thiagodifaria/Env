function Show-Banner {
    param([string]$Language = "pt-br")
    Clear-Host
    
    $banner = @"

 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣷⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⡔⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠭⣿⣿⣿⣶⣄⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣴⣾⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⡿⣿⡿⣿⣿⣿⣿⣦⣴⣶⣶⣶⣶⣦⣤⣤⣀⣀⠀⠀⠀⠀⠀⢀⣀⣤⣲⣿⣿⣿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⡝⢿⣌⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣤⣾⣿⣿⣿⣿⣿⡿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠲⡝⡷⣮⣝⣻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣛⣿⣿⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣦⣝⠓⠭⣿⡿⢿⣿⣿⣛⠻⣿⠿⠿⣿⣿⣿⣿⣿⣿⡿⣇⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣿⣿⣤⡀⠈⠉⠚⠺⣿⠯⢽⣿⣷⣄⣶⣷⢾⣿⣯⣾⣿⠿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⣾⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⡟⠀⠀⣴⣿⣿⣼⠈⠉⠃⠋⢹⠁⢀⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢠⢿⣿⡟⣿⣿⣿⣿⣿⣿⣿⣿⣷⣄⣀⣀⣀⣀⣴⣿⣿⡿⣿⠀⠀⠀⠀⠇⠀⣼⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠑⢿⢿⣾⣿⣿⡿⠿⠿⠿⢿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠿⢿⡄⢦⣤⣤⣶⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⠘⠛⠋⠁⠁⣀⢉⡉⢻⡻⣯⣻⣿⢻⣿⣀⠀⠀⠀⢠⣾⣿⣿⣿⣹⠉⣍⢁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⠠⠔⠒⠋⠀⡈⠀⠠⠤⠀⠓⠯⣟⣻⣻⠿⠛⠁⠀⠀⠣⢽⣿⡻⠿⠋⠰⠤⣀⡈⠒⢄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠔⠊⠁⠀⣀⠔⠈⠁⠀⠀⠀⠀⠀⣶⠂⠀⠀⠀⢰⠆⠀⠀⠀⠈⠒⢦⡀⠉⠢⠀⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀   
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠊⠀⠀⠀⠀⠎⠁⠀⠀⠀⠀⠀⠀⠀⠀⠋⠀⠀⠀⠰⠃⠀⠀⠀⠀⠀⠀⠀⠈⠂⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣄⠀⠀⠀⠀
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿
 ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠸⠿⠭⠯⠭⠽⠿                                      
                                                                                  
                                                                                  
                         Env v1.0.0 - Setup Automatizado                               
                          Windows Environment Builder                             
                                                                                  
                          Created by Thiago Di Faria                            
                           github.com/thiagodifaria

"@
    
    Write-Host $banner -ForegroundColor Cyan
}

function Show-MainMenu {
    param([string]$Language = "pt-br")
    
    Write-Host "     $(Get-String 'main_menu' $Language)" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  1. $(Get-String 'preset_complete' $Language)" -ForegroundColor White
    Write-Host "  2. $(Get-String 'preset_developer' $Language)" -ForegroundColor White
    Write-Host "  3. $(Get-String 'preset_personal' $Language)" -ForegroundColor White
    Write-Host "  4. $(Get-String 'custom_install' $Language)" -ForegroundColor White
    Write-Host "  5. $(Get-String 'exit' $Language)" -ForegroundColor White
    Write-Host ""
    Write-Host "$(Get-String 'choose_option' $Language): " -ForegroundColor Yellow -NoNewline
    
    $choice = Read-Host
    return $choice
}

function Show-CategoryMenu {
    param([string]$Language = "pt-br")
    
    Write-Host ""
    Write-Host "$(Get-String 'select_categories' $Language)" -ForegroundColor Cyan
    Write-Host ""
    
    $categories = @(
        @{Id=1; Name="Languages"; Display="linguagens_title"}
        @{Id=2; Name="DevTools"; Display="devtools_title"}
        @{Id=3; Name="WebTools"; Display="webtools_title"}
        @{Id=4; Name="DBTools"; Display="dbtools_title"}
        @{Id=5; Name="Observability"; Display="observability_title"}
        @{Id=6; Name="Personal"; Display="personal_title"}
        @{Id=7; Name="WSL"; Display="wsl_title"}
        @{Id=8; Name="NPM"; Display="npm_title"}
    )
    
    foreach ($cat in $categories) {
        Write-Host "  [$($cat.Id)] $(Get-String $cat.Display $Language)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "$(Get-String 'select_numbers' $Language) " -ForegroundColor Yellow -NoNewline
    
    $selection = Read-Host
    return $selection
}

function Show-Spinner {
    param(
        [string]$Message,
        [scriptblock]$Task
    )
    
    $spinChars = @('⠋','⠙','⠹','⠸','⠼','⠴','⠦','⠧','⠇','⠏')
    $job = Start-Job -ScriptBlock $Task
    
    $i = 0
    while ($job.State -eq "Running") {
        Write-Host "`r$($spinChars[$i % $spinChars.Count]) $Message" -NoNewline -ForegroundColor Cyan
        Start-Sleep -Milliseconds 100
        $i++
    }
    
    $result = Receive-Job -Job $job
    Remove-Job -Job $job
    
    Write-Host "`r" -NoNewline
    return $result
}

function Show-ProgressBar {
    param(
        [int]$Current,
        [int]$Total,
        [string]$Activity
    )
    
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 40
    $filled = [math]::Round(($percent / 100) * $barLength)
    $empty = $barLength - $filled
    
    $bar = "█" * $filled + "░" * $empty
    
    Write-Host "`r[$bar] $percent% - $Activity" -NoNewline -ForegroundColor Green
}

function Show-CategoryProgress {
    param(
        [string]$Category,
        [int]$Current,
        [int]$Total
    )
    
    $percent = [math]::Round(($Current / $Total) * 100)
    $barLength = 20
    $filled = [math]::Round(($percent / 100) * $barLength)
    $empty = $barLength - $filled
    
    $bar = "█" * $filled + "░" * $empty
    
    Write-Host "  $Category`: [$bar] $percent% ($Current/$Total)" -ForegroundColor Cyan
}

function Write-Status {
    param(
        [string]$Message,
        [string]$Type = "INFO"
    )
    
    $symbol = switch ($Type) {
        "SUCCESS" { "✓"; $color = "Green" }
        "ERROR" { "✗"; $color = "Red" }
        "SKIP" { "⟲"; $color = "Cyan" }
        "WORKING" { "➜"; $color = "Yellow" }
        "WARNING" { "⚠"; $color = "Yellow" }
        default { "•"; $color = "White" }
    }
    
    Write-Host "  $symbol $Message" -ForegroundColor $color
}

function Show-Box {
    param(
        [string]$Message,
        [string]$Color = "Cyan"
    )
    
    $length = $Message.Length + 4
    $border = "═" * $length
    
    Write-Host ""
    Write-Host "╔$border╗" -ForegroundColor $Color
    Write-Host "║  $Message  ║" -ForegroundColor $Color
    Write-Host "╚$border╝" -ForegroundColor $Color
    Write-Host ""
}

function Show-ConfirmationDialog {
    param(
        [string]$Message,
        [string]$Language = "pt-br"
    )
    
    Write-Host ""
    Write-Host "? $Message " -ForegroundColor Yellow -NoNewline
    Write-Host "[$(Get-String 'yes' $Language)/$(Get-String 'no' $Language)]: " -ForegroundColor Gray -NoNewline
    
    $response = Read-Host
    return $response -match "^[YySs]"
}

function Clear-LastLine {
    Write-Host "`r$(' ' * 80)`r" -NoNewline
}

function Show-FinalReport {
    param(
        [hashtable]$Results,
        [timespan]$Duration,
        [string]$LogPath,
        [string]$Language = "pt-br"
    )
    
    Write-Host ""
    Write-Host "        RELATÓRIO DE INSTALAÇÃO         " -ForegroundColor Cyan
    Write-Host ""
    
    $successCount = $Results.Success.Count
    $failedCount = $Results.Failed.Count
    $skippedCount = $Results.Skipped.Count
    $totalCount = $successCount + $failedCount + $skippedCount
    
    Write-Host "Resumo:" -ForegroundColor White
    Write-Host "  ✓ Instalados com sucesso: $successCount" -ForegroundColor Green
    Write-Host "  ⟲ Já existiam (pulados): $skippedCount" -ForegroundColor Cyan
    Write-Host "  ✗ Falharam: $failedCount" -ForegroundColor Red
    Write-Host "  ─────────────────────────────" -ForegroundColor Gray
    Write-Host "  Total de pacotes: $totalCount" -ForegroundColor White
    Write-Host ""
    
    $minutes = [math]::Floor($Duration.TotalMinutes)
    $seconds = $Duration.Seconds
    Write-Host "Duração: ${minutes}m ${seconds}s" -ForegroundColor Gray
    Write-Host "Log salvo em: $LogPath" -ForegroundColor Gray
    Write-Host "Estado salvo em: $PSScriptRoot\..\state\env.state.json" -ForegroundColor Gray
    Write-Host ""
    
    if ($failedCount -gt 0) {
        Write-Host "Pacotes que falharam:" -ForegroundColor Yellow
        foreach ($pkg in $Results.Failed) {
            Write-Host "  ✗ $pkg" -ForegroundColor Red
        }
        Write-Host ""
    }
}

function Show-GlobalProgress {
    param(
        [int]$CurrentCategory,
        [int]$TotalCategories,
        [string]$CategoryName
    )
    
    $percent = [math]::Round(($CurrentCategory / $TotalCategories) * 100)
    $barLength = 40
    $filled = [math]::Round(($percent / 100) * $barLength)
    $empty = $barLength - $filled
    
    $bar = "█" * $filled + "░" * $empty
    
    Write-Host ""
    Write-Host "Progresso Global: [$bar] $percent% ($CurrentCategory/$TotalCategories categorias)" -ForegroundColor Magenta
    Write-Host "Categoria atual: $CategoryName" -ForegroundColor Cyan
    Write-Host ""
}