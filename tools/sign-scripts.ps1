function New-SelfSignedCodeCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$CertName = "ENV PowerShell Code Signing",

        [Parameter(Mandatory=$false)]
        [int]$ValidYears = 5
    )

    try {
        Write-Verbose "Criando certificado auto-assinado para code signing"

        $cert = New-SelfSignedCertificate `
            -Subject "CN=$CertName" `
            -Type CodeSigningCert `
            -CertStoreLocation "Cert:\CurrentUser\My" `
            -NotAfter (Get-Date).AddYears($ValidYears)

        Write-Host "Certificado criado com sucesso!" -ForegroundColor Green
        Write-Host "Thumbprint: $($cert.Thumbprint)" -ForegroundColor Cyan
        Write-Host "Subject: $($cert.Subject)" -ForegroundColor Cyan
        Write-Host "Válido até: $($cert.NotAfter)" -ForegroundColor Cyan

        return $cert
    }
    catch {
        Write-Error "Erro ao criar certificado: $_"
        throw
    }
}

function Export-CodeSigningCertificate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Thumbprint,

        [Parameter(Mandatory=$true)]
        [string]$OutputPath,

        [Parameter(Mandatory=$false)]
        [SecureString]$Password
    )

    try {
        Write-Verbose "Exportando certificado $Thumbprint para $OutputPath"

        $cert = Get-ChildItem -Path "Cert:\CurrentUser\My\$Thumbprint"

        if (-not $cert) {
            throw "Certificado não encontrado: $Thumbprint"
        }

        if ($Password) {
            Export-PfxCertificate -Cert $cert -FilePath $OutputPath -Password $Password
        }
        else {
            Export-Certificate -Cert $cert -FilePath $OutputPath
        }

        Write-Host "Certificado exportado para: $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Erro ao exportar certificado: $_"
        throw
    }
}

function Sign-ProjectScripts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$CertificateThumbprint,

        [Parameter(Mandatory=$false)]
        [string]$ProjectRoot = $PSScriptRoot
    )

    try {
        if (-not $CertificateThumbprint) {
            $certs = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert
            if ($certs.Count -eq 0) {
                throw "Nenhum certificado de code signing encontrado"
            }
            $CertificateThumbprint = $certs[0].Thumbprint
            Write-Host "Usando certificado: $($certs[0].Subject)" -ForegroundColor Cyan
        }

        $cert = Get-ChildItem -Path "Cert:\CurrentUser\My\$CertificateThumbprint"

        $scriptFiles = Get-ChildItem -Path $ProjectRoot -Include *.ps1 -Recurse |
            Where-Object { $_.FullName -notlike "*\data\*" -and $_.FullName -notlike "*\tests\*" }

        Write-Host "`nAssinando $($scriptFiles.Count) scripts..." -ForegroundColor Yellow

        $signed = 0
        $failed = 0

        foreach ($script in $scriptFiles) {
            try {
                Set-AuthenticodeSignature -FilePath $script.FullName -Certificate $cert -ErrorAction Stop | Out-Null
                $signed++
                Write-Host "  [OK] $($script.Name)" -ForegroundColor Green
            }
            catch {
                $failed++
                Write-Warning "  [X] $($script.Name): $_"
            }
        }

        Write-Host "`nResumo:" -ForegroundColor Cyan
        Write-Host "  Assinados: $signed" -ForegroundColor Green
        Write-Host "  Falhas: $failed" -ForegroundColor Red

        return @{
            Signed = $signed
            Failed = $failed
            Total = $scriptFiles.Count
        }
    }
    catch {
        Write-Error "Erro ao assinar scripts: $_"
        throw
    }
}

function Test-ScriptSignature {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath
    )

    try {
        if (-not (Test-Path $ScriptPath)) {
            throw "Script não encontrado: $ScriptPath"
        }

        $signature = Get-AuthenticodeSignature -FilePath $ScriptPath

        Write-Host "Status da assinatura:" -ForegroundColor Cyan
        Write-Host "  Script: $ScriptPath" -ForegroundColor White
        Write-Host "  Status: $($signature.Status)" -ForegroundColor $(if ($signature.Status -eq 'Valid') { 'Green' } else { 'Red' })

        if ($signature.SignerCertificate) {
            Write-Host "  Assinado por: $($signature.SignerCertificate.Subject)" -ForegroundColor Cyan
            Write-Host "  Válido até: $($signature.SignerCertificate.NotAfter)" -ForegroundColor Cyan
        }

        return $signature.Status -eq 'Valid'
    }
    catch {
        Write-Error "Erro ao verificar assinatura: $_"
        return $false
    }
}