function Get-BackupDirectory {
    [CmdletBinding()]
    param()

    try {
        $backupDir = "$PSScriptRoot\..\data\backup"

        if (-not (Test-Path $backupDir)) {
            Write-Verbose "Criando diretório de backup: $backupDir"
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        }

        return $backupDir
    }
    catch {
        Write-Error "Erro ao obter diretório de backup: $_"
        throw
    }
}

function Backup-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory=$false)]
        [string]$BackupPath,

        [Parameter(Mandatory=$false)]
        [string]$Description = "Manual Backup"
    )

    try {
        Write-Verbose "Iniciando backup de: $Path"

        if (-not (Test-Path $Path)) {
            throw "Caminho não encontrado: $Path"
        }

        if (-not $BackupPath) {
            $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
            $backupDir = Get-BackupDirectory
            $BackupPath = Join-Path $backupDir $timestamp
        }

        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
        }

        $isDirectory = Test-Path $Path -PathType Container

        if ($isDirectory) {
            Write-Verbose "Copiando diretório: $Path"
            Copy-Item -Path "$Path\*" -Destination $BackupPath -Recurse -Force
        }
        else {
            Write-Verbose "Copiando arquivo: $Path"
            $fileName = Split-Path $Path -Leaf
            Copy-Item -Path $Path -Destination (Join-Path $BackupPath $fileName) -Force
        }

        $metadata = @{
            BackupId = Split-Path $BackupPath -Leaf
            Description = $Description
            SourcePath = $Path
            BackupPath = $BackupPath
            CreatedAt = (Get-Date).ToString("o")
            IsDirectory = $isDirectory
        }

        $metadataFile = Join-Path $BackupPath "backup-metadata.json"
        $metadata | ConvertTo-Json | Set-Content $metadataFile -Force

        Write-Host "[OK] Backup criado: $BackupPath" -ForegroundColor Green

        return $BackupPath
    }
    catch {
        Write-Error "Erro ao criar backup: $_"
        return $null
    }
}

function Backup-ConfigurationAuto {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$IncludePackagesJson,

        [Parameter(Mandatory=$false)]
        [switch]$IncludeState,

        [Parameter(Mandatory=$false)]
        [switch]$IncludeProfiles
    )

    try {
        Write-Host "Iniciando backup automático de configurações..." -ForegroundColor Cyan

        $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
        $backupDir = Get-BackupDirectory
        $backupPath = Join-Path $backupDir $timestamp

        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

        $backedUpItems = @()

        if ($IncludePackagesJson) {
            $packagesJson = "$PSScriptRoot\..\config\packages.json"
            if (Test-Path $packagesJson) {
                Copy-Item -Path $packagesJson -Destination $backupPath -Force
                $backedUpItems += "packages.json"
                Write-Verbose "Backup de packages.json criado"
            }
        }

        if ($IncludeState) {
            $stateDir = "$PSScriptRoot\..\data\state"
            if (Test-Path $stateDir) {
                $stateBackupDir = Join-Path $backupPath "state"
                New-Item -ItemType Directory -Path $stateBackupDir -Force | Out-Null
                Copy-Item -Path "$stateDir\*" -Destination $stateBackupDir -Recurse -Force
                $backedUpItems += "state"
                Write-Verbose "Backup de estado criado"
            }
        }

        if ($IncludeProfiles) {
            if (Test-Path $PROFILE) {
                $profileBackupDir = Join-Path $backupPath "profiles"
                New-Item -ItemType Directory -Path $profileBackupDir -Force | Out-Null
                Copy-Item -Path $PROFILE -Destination $profileBackupDir -Force
                $backedUpItems += "PowerShell profile"
                Write-Verbose "Backup de perfil PowerShell criado"
            }
        }

        $metadata = @{
            BackupId = $timestamp
            Description = "Automatic Backup"
            CreatedAt = (Get-Date).ToString("o")
            Items = $backedUpItems
        }

        $metadataFile = Join-Path $backupPath "backup-metadata.json"
        $metadata | ConvertTo-Json | Set-Content $metadataFile -Force

        Write-Host "[OK] Backup automático criado: $backupPath" -ForegroundColor Green
        Write-Host "  Itens incluídos: $($backedUpItems.Count)" -ForegroundColor Cyan

        return $backupPath
    }
    catch {
        Write-Error "Erro ao criar backup automático: $_"
        return $null
    }
}

function Get-BackupHistory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [int]$Last = 0
    )

    try {
        $backupDir = Get-BackupDirectory

        $backups = Get-ChildItem -Path $backupDir -Directory | Sort-Object Name -Descending

        if ($Last -gt 0) {
            $backups = $backups | Select-Object -First $Last
        }

        $backupList = @()

        foreach ($backup in $backups) {
            $metadataFile = Join-Path $backup.FullName "backup-metadata.json"

            if (Test-Path $metadataFile) {
                $metadata = Get-Content $metadataFile -Raw | ConvertFrom-Json
                $backupList += $metadata
            }
            else {
                $backupList += @{
                    BackupId = $backup.Name
                    Description = "Unknown"
                    CreatedAt = $backup.CreationTime.ToString("o")
                    Items = @()
                }
            }
        }

        Write-Host "`nHistórico de backups:" -ForegroundColor Cyan
        Write-Host "Total: $($backupList.Count)" -ForegroundColor White

        foreach ($backup in $backupList) {
            Write-Host "`nBackupId: $($backup.BackupId)" -ForegroundColor Yellow
            Write-Host "  Descrição: $($backup.Description)" -ForegroundColor White
            Write-Host "  Criado em: $($backup.CreatedAt)" -ForegroundColor Gray
            if ($backup.Items -and $backup.Items.Count -gt 0) {
                Write-Host "  Itens: $($backup.Items -join ', ')" -ForegroundColor Cyan
            }
        }

        return $backupList
    }
    catch {
        Write-Error "Erro ao obter histórico de backups: $_"
        return @()
    }
}

function Restore-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupId
    )

    try {
        Write-Host "Restaurando backup: $BackupId..." -ForegroundColor Cyan

        $backupDir = Get-BackupDirectory
        $backupPath = Join-Path $backupDir $BackupId

        if (-not (Test-Path $backupPath)) {
            throw "Backup não encontrado: $BackupId"
        }

        $metadataFile = Join-Path $backupPath "backup-metadata.json"

        if (-not (Test-Path $metadataFile)) {
            throw "Metadata de backup não encontrado"
        }

        $metadata = Get-Content $metadataFile -Raw | ConvertFrom-Json

        Write-Host "Backup: $($metadata.Description)" -ForegroundColor Yellow
        Write-Host "Criado em: $($metadata.CreatedAt)" -ForegroundColor Gray

        if ($metadata.SourcePath) {
            $confirm = Read-Host "Restaurar para caminho original ($($metadata.SourcePath))? (S/N)"
            if ($confirm -ne 'S' -and $confirm -ne 's') {
                Write-Host "Restauração cancelada" -ForegroundColor Yellow
                return $false
            }

            if ($metadata.IsDirectory) {
                if (Test-Path $metadata.SourcePath) {
                    Remove-Item -Path "$($metadata.SourcePath)\*" -Recurse -Force
                }
                else {
                    New-Item -ItemType Directory -Path $metadata.SourcePath -Force | Out-Null
                }

                Copy-Item -Path "$backupPath\*" -Destination $metadata.SourcePath -Recurse -Force -Exclude "backup-metadata.json"
            }
            else {
                Copy-Item -Path (Join-Path $backupPath (Split-Path $metadata.SourcePath -Leaf)) -Destination $metadata.SourcePath -Force
            }

            Write-Host "[OK] Backup restaurado para: $($metadata.SourcePath)" -ForegroundColor Green
        }
        else {
            Write-Host "Itens no backup:" -ForegroundColor Yellow
            foreach ($item in $metadata.Items) {
                Write-Host "  - $item" -ForegroundColor Gray
            }
            Write-Host "`nRestauração manual necessária. Backup localizado em: $backupPath" -ForegroundColor Cyan
        }

        return $true
    }
    catch {
        Write-Error "Erro ao restaurar backup: $_"
        return $false
    }
}

function Remove-OldBackups {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 365)]
        [int]$DaysToKeep = 30
    )

    try {
        Write-Host "Removendo backups antigos (mantendo últimos $DaysToKeep dias)..." -ForegroundColor Cyan

        $backupDir = Get-BackupDirectory
        $cutoffDate = (Get-Date).AddDays(-$DaysToKeep)

        $backups = Get-ChildItem -Path $backupDir -Directory | Where-Object { $_.CreationTime -lt $cutoffDate }

        if ($backups.Count -eq 0) {
            Write-Host "Nenhum backup antigo encontrado" -ForegroundColor Yellow
            return $true
        }

        Write-Host "Backups a remover: $($backups.Count)" -ForegroundColor Yellow

        $confirm = Read-Host "Deseja continuar? (S/N)"
        if ($confirm -ne 'S' -and $confirm -ne 's') {
            Write-Host "Operação cancelada" -ForegroundColor Yellow
            return $false
        }

        foreach ($backup in $backups) {
            Remove-Item -Path $backup.FullName -Recurse -Force
            Write-Host "  [OK] Removido: $($backup.Name)" -ForegroundColor Gray
        }

        Write-Host "[OK] $($backups.Count) backups removidos" -ForegroundColor Green

        return $true
    }
    catch {
        Write-Error "Erro ao remover backups antigos: $_"
        return $false
    }
}

function Get-AvailableBackups {
    [CmdletBinding()]
    param()

    try {
        $backupDir = Get-BackupDirectory

        $backups = Get-ChildItem -Path $backupDir -Directory | Sort-Object Name -Descending

        $backupList = @()

        foreach ($backup in $backups) {
            $metadataFile = Join-Path $backup.FullName "backup-metadata.json"

            $backupInfo = [PSCustomObject]@{
                BackupId = $backup.Name
                Path = $backup.FullName
                CreatedAt = $backup.CreationTime
                SizeMB = [math]::Round((Get-ChildItem $backup.FullName -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB, 2)
                HasMetadata = Test-Path $metadataFile
            }

            if ($backupInfo.HasMetadata) {
                $metadata = Get-Content $metadataFile -Raw | ConvertFrom-Json
                $backupInfo | Add-Member -NotePropertyName "Description" -NotePropertyValue $metadata.Description
                $backupInfo | Add-Member -NotePropertyName "Items" -NotePropertyValue $metadata.Items
            }

            $backupList += $backupInfo
        }

        return $backupList
    }
    catch {
        Write-Error "Erro ao obter backups disponíveis: $_"
        return @()
    }
}

function Compare-Backups {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupId1,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupId2
    )

    try {
        Write-Host "`nComparando backups:" -ForegroundColor Cyan
        Write-Host "  Backup 1: $BackupId1" -ForegroundColor Yellow
        Write-Host "  Backup 2: $BackupId2" -ForegroundColor Yellow

        $backupDir = Get-BackupDirectory

        $backup1Path = Join-Path $backupDir $BackupId1
        $backup2Path = Join-Path $backupDir $BackupId2

        if (-not (Test-Path $backup1Path)) {
            throw "Backup 1 não encontrado: $BackupId1"
        }

        if (-not (Test-Path $backup2Path)) {
            throw "Backup 2 não encontrado: $BackupId2"
        }

        $files1 = Get-ChildItem -Path $backup1Path -Recurse -File | Where-Object { $_.Name -ne "backup-metadata.json" }
        $files2 = Get-ChildItem -Path $backup2Path -Recurse -File | Where-Object { $_.Name -ne "backup-metadata.json" }

        $onlyInBackup1 = $files1 | Where-Object { $_.Name -notin $files2.Name }
        $onlyInBackup2 = $files2 | Where-Object { $_.Name -notin $files1.Name }
        $common = $files1 | Where-Object { $_.Name -in $files2.Name }

        Write-Host "`nResumo da comparação:" -ForegroundColor Cyan
        Write-Host "  Arquivos em comum: $($common.Count)" -ForegroundColor Green
        Write-Host "  Apenas em Backup 1: $($onlyInBackup1.Count)" -ForegroundColor Yellow
        Write-Host "  Apenas em Backup 2: $($onlyInBackup2.Count)" -ForegroundColor Yellow

        if ($onlyInBackup1.Count -gt 0) {
            Write-Host "`nApenas em Backup 1:" -ForegroundColor Yellow
            foreach ($file in $onlyInBackup1) {
                Write-Host "  - $($file.Name)" -ForegroundColor Gray
            }
        }

        if ($onlyInBackup2.Count -gt 0) {
            Write-Host "`nApenas em Backup 2:" -ForegroundColor Yellow
            foreach ($file in $onlyInBackup2) {
                Write-Host "  - $($file.Name)" -ForegroundColor Gray
            }
        }

        $differences = @()

        foreach ($file in $common) {
            $file1 = $files1 | Where-Object { $_.Name -eq $file.Name }
            $file2 = $files2 | Where-Object { $_.Name -eq $file.Name }

            $hash1 = (Get-FileHash $file1.FullName).Hash
            $hash2 = (Get-FileHash $file2.FullName).Hash

            if ($hash1 -ne $hash2) {
                $differences += $file.Name
            }
        }

        if ($differences.Count -gt 0) {
            Write-Host "`nArquivos diferentes:" -ForegroundColor Red
            foreach ($diff in $differences) {
                Write-Host "  - $diff" -ForegroundColor Gray
            }
        }
        else {
            Write-Host "`nTodos os arquivos em comum são idênticos" -ForegroundColor Green
        }

        return @{
            Common = $common.Count
            OnlyInBackup1 = $onlyInBackup1.Count
            OnlyInBackup2 = $onlyInBackup2.Count
            Different = $differences.Count
        }
    }
    catch {
        Write-Error "Erro ao comparar backups: $_"
        return $null
    }
}

function Export-BackupArchive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$BackupId,

        [Parameter(Mandatory=$false)]
        [string]$OutputPath
    )

    try {
        Write-Host "Exportando backup como arquivo compactado..." -ForegroundColor Cyan

        $backupDir = Get-BackupDirectory
        $backupPath = Join-Path $backupDir $BackupId

        if (-not (Test-Path $backupPath)) {
            throw "Backup não encontrado: $BackupId"
        }

        if (-not $OutputPath) {
            $OutputPath = Join-Path (Get-Location) "$BackupId.zip"
        }

        Compress-Archive -Path "$backupPath\*" -DestinationPath $OutputPath -Force

        Write-Host "[OK] Backup exportado para: $OutputPath" -ForegroundColor Green

        $fileSize = [math]::Round((Get-Item $OutputPath).Length / 1MB, 2)
        Write-Host "  Tamanho: $fileSize MB" -ForegroundColor Cyan

        return $OutputPath
    }
    catch {
        Write-Error "Erro ao exportar backup: $_"
        return $null
    }
}

function Import-BackupArchive {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ArchivePath
    )

    try {
        Write-Host "Importando backup de arquivo compactado..." -ForegroundColor Cyan

        if (-not (Test-Path $ArchivePath)) {
            throw "Arquivo não encontrado: $ArchivePath"
        }

        $backupDir = Get-BackupDirectory
        $timestamp = Get-Date -Format "yyyy-MM-dd-HHmmss"
        $importPath = Join-Path $backupDir "imported-$timestamp"

        Expand-Archive -Path $ArchivePath -DestinationPath $importPath -Force

        Write-Host "[OK] Backup importado para: $importPath" -ForegroundColor Green

        return $importPath
    }
    catch {
        Write-Error "Erro ao importar backup: $_"
        return $null
    }
}