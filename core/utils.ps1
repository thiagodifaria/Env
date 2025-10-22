function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-DiskSpace {
    param([int]$RequiredGB = 30)
    
    $drive = Get-PSDrive C
    $freeGB = [math]::Round($drive.Free / 1GB, 2)
    
    return $freeGB -ge $RequiredGB
}

function Test-NetworkConnection {
    try {
        $result = Test-Connection -ComputerName google.com -Count 1 -Quiet -ErrorAction Stop
        return $result
    }
    catch {
        return $false
    }
}

function Install-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        return $true
    }
    
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        return $true
    }
    catch {
        Write-Log "Erro ao instalar Chocolatey: $_" "ERROR"
        return $false
    }
}

function Get-SystemInfo {
    $os = (Get-CimInstance Win32_OperatingSystem).Caption
    $ramGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $diskGB = [math]::Round((Get-PSDrive C).Free / 1GB, 2)
    $psVersion = $PSVersionTable.PSVersion.ToString()
    
    return @{
        OS = $os
        RAM = "$ramGB GB"
        Disk = "$diskGB GB"
        PowerShell = $psVersion
    }
}

function Get-String {
    param(
        [string]$Key,
        [string]$Language = "pt-br"
    )
    
    $stringsPath = "$PSScriptRoot\..\config\strings.json"
    $strings = Get-Content $stringsPath | ConvertFrom-Json
    
    return $strings.$Language.$Key
}