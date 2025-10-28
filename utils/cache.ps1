function Get-CacheDirectory {
    [CmdletBinding()]
    param()

    try {
        $cacheDir = "$PSScriptRoot\..\data\cache"

        if (-not (Test-Path $cacheDir)) {
            Write-Verbose "Criando diretório de cache: $cacheDir"
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }

        return $cacheDir
    }
    catch {
        Write-Error "Erro ao obter diretório de cache: $_"
        throw
    }
}

function Get-CachedPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageId
    )

    try {
        Write-Verbose "Verificando cache para package: $PackageId"

        $cacheDir = Get-CacheDirectory
        $cacheFile = Join-Path $cacheDir "$PackageId.cache"

        if (Test-Path $cacheFile) {
            Write-Verbose "Cache encontrado para $PackageId"
            return Get-Content $cacheFile -Raw
        }

        Write-Verbose "Nenhum cache encontrado para $PackageId"
        return $null
    }
    catch {
        Write-Error "Erro ao obter package do cache: $_"
        return $null
    }
}

function Set-CachedPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PackageId,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    try {
        Write-Verbose "Salvando package no cache: $PackageId"

        if (-not (Test-Path $FilePath)) {
            throw "Arquivo não encontrado: $FilePath"
        }

        $cacheDir = Get-CacheDirectory
        $cacheFile = Join-Path $cacheDir "$PackageId.cache"

        Copy-Item -Path $FilePath -Destination $cacheFile -Force

        Write-Verbose "Package $PackageId salvo no cache"
        return $true
    }
    catch {
        Write-Error "Erro ao salvar package no cache: $_"
        return $false
    }
}

function Clear-PackageCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$PackageId
    )

    try {
        $cacheDir = Get-CacheDirectory

        if ($PackageId) {
            Write-Verbose "Limpando cache para package: $PackageId"
            $cacheFile = Join-Path $cacheDir "$PackageId.cache"

            if (Test-Path $cacheFile) {
                Remove-Item $cacheFile -Force
                Write-Host "Cache removido para $PackageId" -ForegroundColor Green
            }
            else {
                Write-Warning "Nenhum cache encontrado para $PackageId"
            }
        }
        else {
            Write-Verbose "Limpando todo o cache"
            $cacheFiles = Get-ChildItem -Path $cacheDir -Filter "*.cache"

            if ($cacheFiles.Count -gt 0) {
                Remove-Item -Path "$cacheDir\*.cache" -Force
                Write-Host "Cache completo limpo ($($cacheFiles.Count) arquivos)" -ForegroundColor Green
            }
            else {
                Write-Host "Cache já está vazio" -ForegroundColor Yellow
            }
        }

        return $true
    }
    catch {
        Write-Error "Erro ao limpar cache: $_"
        return $false
    }
}

function Get-CachedData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 10080)]
        [int]$TTLMinutes = 60
    )

    try {
        Write-Verbose "Obtendo dados do cache: $Key (TTL: $TTLMinutes min)"

        $cacheDir = Get-CacheDirectory
        $cacheFile = Join-Path $cacheDir "$Key.json"

        if (-not (Test-Path $cacheFile)) {
            Write-Verbose "Cache não encontrado para $Key"
            return $null
        }

        $cacheData = Get-Content $cacheFile -Raw | ConvertFrom-Json

        $cacheAge = (Get-Date) - [DateTime]$cacheData.Timestamp

        if ($cacheAge.TotalMinutes -gt $TTLMinutes) {
            Write-Verbose "Cache expirado para $Key (idade: $([math]::Round($cacheAge.TotalMinutes, 2)) min)"
            Remove-Item $cacheFile -Force
            return $null
        }

        Write-Verbose "Cache válido encontrado para $Key"
        return $cacheData.Data
    }
    catch {
        Write-Error "Erro ao obter dados do cache: $_"
        return $null
    }
}

function Set-CachedData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Key,

        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        $Value,

        [Parameter(Mandatory=$false)]
        [ValidateRange(1, 10080)]
        [int]$TTLMinutes = 60
    )

    try {
        Write-Verbose "Salvando dados no cache: $Key (TTL: $TTLMinutes min)"

        $cacheDir = Get-CacheDirectory
        $cacheFile = Join-Path $cacheDir "$Key.json"

        $cacheData = @{
            Key = $Key
            Timestamp = (Get-Date).ToString("o")
            TTLMinutes = $TTLMinutes
            Data = $Value
        }

        $cacheData | ConvertTo-Json -Depth 10 | Set-Content $cacheFile -Force

        Write-Verbose "Dados salvos no cache para $Key"
        return $true
    }
    catch {
        Write-Error "Erro ao salvar dados no cache: $_"
        return $false
    }
}

function Get-CacheInfo {
    [CmdletBinding()]
    param()

    try {
        $cacheDir = Get-CacheDirectory

        $cacheFiles = Get-ChildItem -Path $cacheDir -Filter "*.*"

        if ($cacheFiles.Count -eq 0) {
            Write-Host "Cache vazio" -ForegroundColor Yellow
            return @{
                TotalFiles = 0
                TotalSizeMB = 0
                Files = @()
            }
        }

        $totalSize = ($cacheFiles | Measure-Object -Property Length -Sum).Sum
        $totalSizeMB = [math]::Round($totalSize / 1MB, 2)

        Write-Host "`nInformações do Cache:" -ForegroundColor Cyan
        Write-Host "  Total de arquivos: $($cacheFiles.Count)" -ForegroundColor White
        Write-Host "  Tamanho total: $totalSizeMB MB" -ForegroundColor White
        Write-Host "`nArquivos:" -ForegroundColor Cyan

        $fileInfo = @()
        foreach ($file in $cacheFiles) {
            $sizeMB = [math]::Round($file.Length / 1MB, 2)
            $fileInfo += @{
                Name = $file.Name
                SizeMB = $sizeMB
                LastModified = $file.LastWriteTime
            }
            Write-Host "  - $($file.Name) ($sizeMB MB)" -ForegroundColor Gray
        }

        return @{
            TotalFiles = $cacheFiles.Count
            TotalSizeMB = $totalSizeMB
            Files = $fileInfo
        }
    }
    catch {
        Write-Error "Erro ao obter informações do cache: $_"
        return $null
    }
}