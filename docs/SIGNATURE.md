# 🔏 Assinatura de Scripts PowerShell - ENV

Guia completo para assinatura de scripts PowerShell no projeto ENV, garantindo autenticidade, integridade e conformidade com políticas de segurança corporativas.

---

## 📋 Índice

- [Por Que Assinar Scripts?](#por-que-assinar-scripts)
- [Criando Certificado Auto-Assinado](#criando-certificado-auto-assinado)
- [Confiando no Certificado](#confiando-no-certificado)
- [Assinando Scripts do Projeto](#assinando-scripts-do-projeto)
- [Verificando Assinaturas](#verificando-assinaturas)
- [Exportando Certificados](#exportando-certificados)
- [Políticas de Execução](#políticas-de-execução)
- [Certificados de Produção](#certificados-de-produção)
- [Solução de Problemas](#solução-de-problemas)
- [Melhores Práticas](#melhores-práticas)

---

## 🎯 Por Que Assinar Scripts?

A assinatura de scripts fornece múltiplas camadas de segurança e confiança para scripts PowerShell:

| Benefício | Descrição |
|-----------|-----------|
| **Autenticidade** | Garante que o script veio de uma fonte confiável |
| **Integridade** | Verifica que o script não foi modificado após a assinatura |
| **Conformidade** | Atende políticas de segurança corporativa e requisitos de auditoria |
| **Política de Execução** | Permite execução em ambientes restritos (política AllSigned) |
| **Cadeia de Confiança** | Estabelece prova criptográfica da identidade do publicador |

---

## 🔐 Criando Certificado Auto-Assinado

### Opção 1: Usando Função Integrada do ENV (Recomendado)

O projeto ENV inclui criação automatizada de certificados:

```powershell
# Carregar o script de assinatura
. .\tools\sign-scripts.ps1

# Criar um certificado válido por 5 anos
$cert = New-SelfSignedCodeCertificate -CertName "ENV Code Signing" -ValidYears 5

# Ver detalhes do certificado
$cert | Format-List Subject, Thumbprint, NotBefore, NotAfter
```

**Exemplo de saída:**
```
Subject    : CN=ENV Code Signing
Thumbprint : 1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q8R9S0T
NotBefore  : 23/1/2025 10:30:00
NotAfter   : 23/1/2030 10:30:00
```

### Opção 2: Comando PowerShell Manual

Criar um certificado manualmente com controle total sobre os parâmetros:

```powershell
# Criar certificado de assinatura de código
$cert = New-SelfSignedCertificate `
    -Subject "CN=PowerShell Code Signing" `
    -Type CodeSigningCert `
    -CertStoreLocation "Cert:\CurrentUser\My" `
    -NotAfter (Get-Date).AddYears(5) `
    -KeyUsage DigitalSignature `
    -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.3")

# Armazenar thumbprint para uso posterior
$thumbprint = $cert.Thumbprint
Write-Host "Certificate Thumbprint: $thumbprint" -ForegroundColor Green
```

---

## ✅ Confiando no Certificado

Para que o Windows confie no seu certificado auto-assinado, ele deve ser adicionado aos repositórios **Root** e **TrustedPublisher**:

```powershell
# Obter seu certificado de assinatura de código
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert | Select-Object -First 1

# Exportar para arquivo temporário
$certPath = "$env:TEMP\code-signing-cert.cer"
Export-Certificate -Cert $cert -FilePath $certPath

# Importar para repositório Root (certificados raiz confiáveis)
Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\CurrentUser\Root"

# Importar para repositório TrustedPublisher (publicadores confiáveis)
Import-Certificate -FilePath $certPath -CertStoreLocation "Cert:\CurrentUser\TrustedPublisher"

# Limpeza
Remove-Item $certPath
Write-Host "✓ Certificado agora é confiável" -ForegroundColor Green
```

**Por que ambos os repositórios?**
- **Root**: Estabelece o certificado como uma autoridade confiável
- **TrustedPublisher**: Permite que scripts assinados por este certificado sejam executados sem prompts

---

## ✍️ Assinando Scripts do Projeto

### Assinar Todos os Scripts do Projeto ENV

A função `Sign-ProjectScripts` assina automaticamente todos os scripts PowerShell no projeto:

```powershell
# Carregar ferramenta de assinatura
. .\tools\sign-scripts.ps1

# Assinar todos os arquivos .ps1 no projeto
Sign-ProjectScripts

# Assinar com saída verbose
Sign-ProjectScripts -Verbose
```

**O que é assinado:**
- `env.ps1` (ponto de entrada principal)
- `setup.ps1` (script de configuração)
- Todos os scripts em `core/*.ps1`
- Todos os scripts em `installers/*.ps1`
- Todos os scripts em `utils/*.ps1`
- Todos os scripts em `ui/*.ps1`

### Assinar com Certificado Específico

Se você tiver múltiplos certificados de assinatura de código:

```powershell
# Listar certificados disponíveis
Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert | Format-Table Subject, Thumbprint

# Assinar com certificado específico
$thumbprint = "1A2B3C4D5E6F7G8H9I0J1K2L3M4N5O6P7Q8R9S0T"
Sign-ProjectScripts -CertificateThumbprint $thumbprint
```

### Assinar Script Individual

Para assinar um único arquivo de script:

```powershell
# Obter certificado
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert | Select-Object -First 1

# Assinar com timestamp (recomendado)
Set-AuthenticodeSignature -FilePath ".\env.ps1" -Certificate $cert -TimestampServer "http://timestamp.digicert.com"
```

**Servidores de timestamp:**
- DigiCert: `http://timestamp.digicert.com`
- Sectigo: `http://timestamp.sectigo.com`
- GlobalSign: `http://timestamp.globalsign.com`

---

## 🔍 Verificando Assinaturas

### Usando Função Integrada do ENV

```powershell
# Carregar ferramenta de assinatura
. .\tools\sign-scripts.ps1

# Verificar script único
Test-ScriptSignature -ScriptPath ".\env.ps1"

# Verificar todos os scripts do projeto
Get-ChildItem -Path . -Recurse -Filter "*.ps1" | ForEach-Object {
    $result = Test-ScriptSignature -ScriptPath $_.FullName
    Write-Host "$($_.Name): $result"
}
```

### Verificação Manual

```powershell
# Obter detalhes da assinatura
$sig = Get-AuthenticodeSignature -FilePath ".\env.ps1"

# Verificar status
if ($sig.Status -eq "Valid") {
    Write-Host "✓ Assinatura é válida" -ForegroundColor Green
    Write-Host "  Assinante: $($sig.SignerCertificate.Subject)"
    Write-Host "  Timestamp: $($sig.TimeStamperCertificate.NotBefore)"
} else {
    Write-Host "✗ Status da assinatura: $($sig.Status)" -ForegroundColor Red
}
```

**Status possíveis:**
- `Valid` - Assinatura é válida e confiável
- `UnknownError` - Certificado pode estar expirado ou não confiável
- `NotSigned` - Arquivo não possui assinatura
- `HashMismatch` - Arquivo foi modificado após assinatura

---

## 📤 Exportando Certificados

### Exportar Certificado Público (Sem Chave Privada)

Seguro para compartilhar com outros que precisam verificar suas assinaturas:

```powershell
# Usando função do ENV
. .\tools\sign-scripts.ps1
Export-CodeSigningCertificate -Thumbprint "SEU_THUMBPRINT" -OutputPath "ENV-CodeSigning.cer"

# Exportação manual
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert | Select-Object -First 1
Export-Certificate -Cert $cert -FilePath "ENV-CodeSigning.cer"
```

### Exportar Certificado Privado (Formato PFX)

**⚠️ PERIGO: Contém chave privada - proteja cuidadosamente!**

```powershell
# Usando função do ENV com proteção por senha
$password = Read-Host "Digite senha para o PFX" -AsSecureString
Export-CodeSigningCertificate -Thumbprint "SEU_THUMBPRINT" -OutputPath "ENV-CodeSigning.pfx" -Password $password

# Exportação manual
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert | Select-Object -First 1
$password = ConvertTo-SecureString -String "SuaSenhaForte123!" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "ENV-CodeSigning.pfx" -Password $password
```

### Importar Certificado PFX

Para usar um certificado em outra máquina:

```powershell
# Importar PFX
$password = Read-Host "Digite senha do PFX" -AsSecureString
Import-PfxCertificate -FilePath "ENV-CodeSigning.pfx" -CertStoreLocation "Cert:\CurrentUser\My" -Password $password

# Confiar no certificado
Import-Certificate -FilePath "ENV-CodeSigning.cer" -CertStoreLocation "Cert:\CurrentUser\Root"
Import-Certificate -FilePath "ENV-CodeSigning.cer" -CertStoreLocation "Cert:\CurrentUser\TrustedPublisher"
```

---

## 🛡️ Políticas de Execução

Políticas de execução do PowerShell controlam quais scripts podem ser executados no seu sistema.

### Ver Política Atual

```powershell
# Ver todos os escopos
Get-ExecutionPolicy -List

# Ver política efetiva
Get-ExecutionPolicy
```

### Níveis de Política

| Política | Descrição | Caso de Uso |
|----------|-----------|-------------|
| **Restricted** | Nenhum script permitido | Segurança máxima (padrão no Windows Server) |
| **AllSigned** | Apenas scripts assinados | Ambientes corporativos |
| **RemoteSigned** | Scripts remotos devem ser assinados | Segurança balanceada (recomendado) |
| **Unrestricted** | Todos os scripts permitidos (com prompt) | Máquinas de desenvolvimento |
| **Bypass** | Sem restrições ou prompts | Pipelines CI/CD |

### Definir Política de Execução

```powershell
# Recomendado: Scripts remotos devem ser assinados
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Estrito: Todos os scripts devem ser assinados
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy AllSigned

# Bypass temporário (apenas sessão atual)
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

# Verificar mudança
Get-ExecutionPolicy -Scope CurrentUser
```

**Hierarquia de escopo** (maior para menor prioridade):
1. `MachinePolicy` - Definido por Group Policy (não pode sobrescrever)
2. `UserPolicy` - Definido por Group Policy (não pode sobrescrever)
3. `Process` - Apenas sessão atual
4. `CurrentUser` - Usuário atual (recomendado)
5. `LocalMachine` - Todos os usuários (requer admin)

---

## 🏢 Certificados de Produção

Para projetos corporativos ou públicos, considere certificados profissionais:

### Opção 1: Certificado de CA Corporativa

Solicite do departamento de TI da sua organização:

```powershell
# Geralmente obtido através de portal interno de solicitação de certificados
# ou Active Directory Certificate Services

# Após receber arquivo .pfx:
$password = Read-Host "Digite senha do certificado" -AsSecureString
Import-PfxCertificate -FilePath "corporate-cert.pfx" -CertStoreLocation "Cert:\CurrentUser\My" -Password $password
```

### Opção 2: Certificado Comercial de Assinatura de Código

Comprar de Autoridade Certificadora pública:

**Fornecedores:**
- **DigiCert**: $474/ano - Padrão da indústria
- **GlobalSign**: $350/ano - Boa reputação
- **Sectigo**: $179/ano - Econômico

**Processo:**
1. Comprar certificado no site da CA
2. Completar verificação de identidade (telefone, documentos)
3. Receber certificado (geralmente em 1-5 dias úteis)
4. Importar e usar para assinatura

### Opção 3: Azure Key Vault

Armazenar certificados de forma segura na nuvem:

```powershell
# Instalar módulo Azure PowerShell
Install-Module -Name Az -AllowClobber -Scope CurrentUser

# Conectar ao Azure
Connect-AzAccount

# Obter certificado do Key Vault
$cert = Get-AzKeyVaultCertificate -VaultName "MyKeyVault" -Name "CodeSigningCert"

# Assinar script usando certificado do Key Vault
# (requer módulo Az.KeyVault e configuração adicional)
```

---

## 🔧 Solução de Problemas

### Erro: "Não pode ser carregado porque a execução de scripts está desabilitada"

**Causa:** Política de execução muito restritiva.

**Solução:**
```powershell
# Verificar política atual
Get-ExecutionPolicy

# Permitir scripts assinados
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned

# Ou bypass apenas para sessão atual
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
```

### Erro: "A senha de rede especificada não está correta"

**Causa:** Arquivo PFX requer senha mas nenhuma foi fornecida.

**Solução:**
```powershell
# Fornecer senha ao importar
$password = Read-Host "Digite senha do PFX" -AsSecureString
Import-PfxCertificate -FilePath "cert.pfx" -CertStoreLocation "Cert:\CurrentUser\My" -Password $password
```

### Assinatura mostra "UnknownError"

**Causa:** Certificado está expirado, revogado ou não confiável.

**Solução:**
```powershell
# Verificar validade do certificado
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert
$cert | Format-List Subject, NotBefore, NotAfter, Thumbprint

# Verificar se expirou
if ((Get-Date) -gt $cert.NotAfter) {
    Write-Host "Certificado está expirado - criar um novo"
}

# Re-confiar no certificado
Export-Certificate -Cert $cert -FilePath "cert.cer"
Import-Certificate -FilePath "cert.cer" -CertStoreLocation "Cert:\CurrentUser\Root"
Import-Certificate -FilePath "cert.cer" -CertStoreLocation "Cert:\CurrentUser\TrustedPublisher"
```

### Script executa mas aviso de assinatura aparece

**Causa:** Certificado não está no repositório TrustedPublisher.

**Solução:**
```powershell
# Adicionar ao TrustedPublisher
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert | Select-Object -First 1
Export-Certificate -Cert $cert -FilePath "cert.cer"
Import-Certificate -FilePath "cert.cer" -CertStoreLocation "Cert:\CurrentUser\TrustedPublisher"
```

### "Nenhum certificado foi encontrado que atendesse todos os critérios"

**Causa:** Nenhum certificado de assinatura de código no repositório pessoal.

**Solução:**
```powershell
# Criar novo certificado
. .\tools\sign-scripts.ps1
New-SelfSignedCodeCertificate -CertName "ENV Code Signing" -ValidYears 5
```

---

## 💡 Melhores Práticas

### 1. Proteger Chaves Privadas

```powershell
# ✅ FAZER: Armazenar arquivos .pfx criptografados em local seguro
$password = ConvertTo-SecureString -String "SenhaForte123!" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "secure-cert.pfx" -Password $password

# ❌ NÃO FAZER: Commitar arquivos .pfx no controle de versão
# Adicionar ao .gitignore:
echo "*.pfx" >> .gitignore
```

### 2. Usar Senhas Fortes

```powershell
# ✅ FAZER: Gerar senha aleatória forte
Add-Type -AssemblyName System.Web
$password = [System.Web.Security.Membership]::GeneratePassword(20, 5)
$securePassword = ConvertTo-SecureString -String $password -Force -AsPlainText

# ❌ NÃO FAZER: Usar senhas fracas ou comuns
```

### 3. Adicionar Timestamps

```powershell
# ✅ FAZER: Sempre usar servidor de timestamp
Set-AuthenticodeSignature -FilePath "script.ps1" -Certificate $cert -TimestampServer "http://timestamp.digicert.com"

# ❌ NÃO FAZER: Assinar sem timestamp (assinatura inválida após expiração do cert)
```

**Por que timestamps importam:**
- Scripts permanecem válidos mesmo após expiração do certificado
- Prova que o script foi assinado quando o certificado era válido
- Essencial para distribuição de scripts de longo prazo

### 4. Renovar Antes da Expiração

```powershell
# Verificar expiração do certificado
$cert = Get-ChildItem -Path "Cert:\CurrentUser\My" -CodeSigningCert
$daysUntilExpiration = ($cert.NotAfter - (Get-Date)).Days

if ($daysUntilExpiration -lt 90) {
    Write-Warning "Certificado expira em $daysUntilExpiration dias - renovar em breve!"
}
```

### 5. Manter Inventário de Certificados

Manter uma planilha ou documento rastreando:
- Nome/assunto do certificado
- Thumbprint
- Data de emissão
- Data de expiração
- Onde é usado
- Local de backup

### 6. Testar Verificação de Assinatura

```powershell
# Sempre verificar após assinar
$sig = Get-AuthenticodeSignature -FilePath "script.ps1"
if ($sig.Status -ne "Valid") {
    throw "Verificação de assinatura falhou: $($sig.Status)"
}
```

### 7. Usar Controle de Versão

```powershell
# Re-assinar scripts após qualquer modificação
git add -A
git commit -m "Atualizados scripts"
Sign-ProjectScripts
git add -A
git commit -m "Re-assinados scripts após mudanças"
```

---

## 📚 Recursos Adicionais

- [Microsoft Docs - Sobre Assinatura](https://docs.microsoft.com/pt-br/powershell/module/microsoft.powershell.core/about/about_signing)
- [Microsoft Docs - Políticas de Execução](https://docs.microsoft.com/pt-br/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- [Documentação Set-AuthenticodeSignature](https://docs.microsoft.com/pt-br/powershell/module/microsoft.powershell.security/set-authenticodesignature)
- [Melhores Práticas de Assinatura de Código - NIST](https://csrc.nist.gov/publications/detail/sp/800-57-part-1/rev-5/final)
- [Melhores Práticas de Segurança PowerShell](https://docs.microsoft.com/pt-br/powershell/scripting/learn/security/powershell-security-best-practices)