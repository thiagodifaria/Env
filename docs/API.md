# API - Documentação Completa de Funções

Documentação técnica detalhada de todas as funções públicas do projeto ENV, organizadas por módulo.

## 📋 Índice

- [1. Módulos Core](#1-módulos-core)
  - [1.1 utils.ps1](#11-utilsps1)
  - [1.2 validation.ps1](#12-validationps1)
  - [1.3 packages.ps1](#13-packagesps1)
  - [1.4 state-manager.ps1](#14-state-managerps1)
  - [1.5 backup.ps1](#15-backupps1)
  - [1.6 error-handler.ps1](#16-error-handlerps1)
- [2. Installers](#2-installers)
  - [2.1 terminal-env.ps1](#21-terminal-setupps1)
  - [2.2 modern-tools.ps1](#22-modern-toolsps1)
  - [2.3 git-env.ps1](#23-git-setupps1)
- [3. Utils](#3-utils)
  - [3.1 cache.ps1](#31-cacheps1)
  - [3.2 parallel.ps1](#32-parallelps1)
  - [3.3 dotfiles.ps1](#33-dotfilesps1)
- [4. UI](#4-ui)
  - [4.1 progress.ps1](#41-progressps1)
  - [4.2 prompts.ps1](#42-promptsps1)
- [5. Exemplos de Uso](#5-exemplos-de-uso)
- [6. Códigos de Erro](#6-códigos-de-erro)

---

## 1. Módulos Core

### 1.1 utils.ps1

Funções utilitárias gerais do sistema.

#### Test-Administrator

Verifica se o PowerShell está sendo executado com privilégios de administrador.

**Parâmetros:** Nenhum

**Retorna:** `[bool]` - `$true` se executando como Admin, `$false` caso contrário

**Exemplo:**
```powershell
if (Test-Administrator) {
    Write-Host "Executando como Administrador"
}
else {
    Write-Warning "É necessário executar como Administrador"
    exit 1
}
```

**Erros Possíveis:**
- Erro ao acessar informações de identidade do usuário

---

#### Test-DiskSpace

Verifica se há espaço em disco suficiente disponível.

**Parâmetros:**
- `RequiredGB` ([int]): Espaço mínimo necessário em GB [Opcional, Padrão: 30]
  - Validação: Entre 1 e 1000

**Retorna:** `[bool]` - `$true` se há espaço suficiente, `$false` caso contrário

**Exemplo:**
```powershell
# Verificar se há pelo menos 30GB livres (padrão)
if (Test-DiskSpace) {
    Write-Host "Espaço suficiente disponível"
}

# Verificar se há pelo menos 50GB livres
if (Test-DiskSpace -RequiredGB 50) {
    Write-Host "Tem 50GB+ disponíveis"
}
else {
    Write-Warning "Espaço insuficiente"
}
```

**Erros Possíveis:**
- Unidade C: não encontrada
- Erro ao acessar informações do drive

---

#### Test-NetworkConnection

Testa conectividade de rede com um host específico.

**Parâmetros:**
- `TestHost` ([string]): Host para testar conectividade [Opcional, Padrão: "google.com"]
- `Count` ([int]): Número de pings [Opcional, Padrão: 1]
  - Validação: Entre 1 e 10

**Retorna:** `[bool]` - `$true` se conectado, `$false` caso contrário

**Exemplo:**
```powershell
# Teste padrão (google.com)
if (Test-NetworkConnection) {
    Write-Host "Conectado à internet"
}

# Teste com host customizado
if (Test-NetworkConnection -TestHost "github.com" -Count 3) {
    Write-Host "GitHub acessível"
}
```

**Erros Possíveis:**
- Host não alcançável
- Timeout de conexão
- Sem conexão de rede

---

#### Install-Chocolatey

Instala o Chocolatey Package Manager de forma segura com verificação de hash.

**Parâmetros:** Nenhum

**Retorna:** `[bool]` - `$true` se instalado com sucesso, `$false` caso contrário

**Exemplo:**
```powershell
if (Install-Chocolatey) {
    Write-Host "Chocolatey instalado e pronto para uso"
    choco --version
}
```

**Processo:**
1. Verifica se Chocolatey já está instalado
2. Baixa script de instalação oficial
3. Calcula e exibe hash SHA256
4. Solicita confirmação do usuário
5. Executa instalação
6. Atualiza variável PATH
7. Verifica se comando `choco` está disponível

**Erros Possíveis:**
- Falha no download do script
- Hash SHA256 não verificável
- Usuário cancelou instalação
- Chocolatey não disponível após instalação

---

#### Get-SystemInfo

Coleta informações detalhadas do sistema.

**Parâmetros:** Nenhum

**Retorna:** `[hashtable]` com informações do sistema
- `OS` ([string]): Nome do sistema operacional
- `RAM` ([string]): Total de RAM formatado
- `Disk` ([string]): Espaço livre no disco C: formatado
- `PowerShell` ([string]): Versão do PowerShell

**Exemplo:**
```powershell
$info = Get-SystemInfo

Write-Host "Sistema Operacional: $($info.OS)"
Write-Host "RAM Total: $($info.RAM)"
Write-Host "Espaço Livre: $($info.Disk)"
Write-Host "PowerShell: $($info.PowerShell)"

# Saída exemplo:
# Sistema Operacional: Microsoft Windows 11 Pro
# RAM Total: 16 GB
# Espaço Livre: 245.67 GB
# PowerShell: 7.4.0
```

**Erros Possíveis:**
- Falha ao acessar CIM instances (Win32_OperatingSystem, Win32_ComputerSystem)
- Erro ao obter informações do drive

---

#### Get-String

Obtém strings localizadas do arquivo de recursos.

**Parâmetros:**
- `Key` ([string]): Chave da string [Obrigatório]
- `Language` ([string]): Código do idioma [Opcional, Padrão: "pt-br"]
  - Valores aceitos: "pt-br", "en-us", "es"

**Retorna:** `[string]` - String localizada ou a chave se não encontrada

**Exemplo:**
```powershell
# Obter string em português (padrão)
$welcomeMsg = Get-String -Key "welcome_message"

# Obter string em inglês
$welcomeMsg = Get-String -Key "welcome_message" -Language "en-us"

# Obter string em espanhol
$welcomeMsg = Get-String -Key "welcome_message" -Language "es"

# Se a chave não existir, retorna a própria chave
$missing = Get-String -Key "non_existent_key"
# $missing = "non_existent_key"
```

**Estrutura do arquivo strings.json:**
```json
{
  "pt-br": {
    "welcome_message": "Bem-vindo ao ENV",
    "install_success": "Instalação concluída com sucesso"
  },
  "en-us": {
    "welcome_message": "Welcome to ENV",
    "install_success": "Installation completed successfully"
  }
}
```

**Erros Possíveis:**
- Arquivo strings.json não encontrado
- Idioma não configurado
- Chave não existe para o idioma especificado

---

### 1.2 validation.ps1

Funções de validação e segurança.

#### Test-FileChecksum

Valida o checksum de um arquivo contra um hash esperado.

**Parâmetros:**
- `FilePath` ([string]): Caminho completo do arquivo [Obrigatório]
- `ExpectedHash` ([string]): Hash esperado [Obrigatório]
- `Algorithm` ([string]): Algoritmo de hash [Opcional, Padrão: "SHA256"]
  - Valores aceitos: "SHA256", "SHA1", "MD5", "SHA512"

**Retorna:** `[bool]` - `$true` se checksums correspondem, `$false` caso contrário

**Exemplo:**
```powershell
$filePath = "C:\Downloads\installer.exe"
$expectedHash = "ABC123DEF456..."

# Validar com SHA256 (padrão)
if (Test-FileChecksum -FilePath $filePath -ExpectedHash $expectedHash) {
    Write-Host "Arquivo verificado com sucesso"
    # Prosseguir com instalação
}
else {
    Write-Error "AVISO: Checksum não corresponde!"
    # Abortar instalação
}

# Usar algoritmo diferente
$valid = Test-FileChecksum -FilePath $filePath -ExpectedHash $hash -Algorithm "SHA512"
```

**Processo:**
1. Verifica se arquivo existe
2. Calcula hash do arquivo usando algoritmo especificado
3. Compara com hash esperado (case-insensitive)
4. Exibe aviso detalhado se não corresponder

**Erros Possíveis:**
- Arquivo não encontrado no caminho especificado
- Falha ao calcular hash (arquivo corrompido, sem permissão)
- Hash não corresponde ao esperado

---

#### Get-PackageChecksum

Obtém informações de checksum de um pacote em um gerenciador específico.

**Parâmetros:**
- `PackageId` ([string]): ID do pacote [Obrigatório]
- `Source` ([string]): Gerenciador de pacotes [Opcional, Padrão: "chocolatey"]
  - Valores aceitos: "chocolatey", "winget", "scoop"

**Retorna:** `[hashtable]` com informações do pacote
- `Source` ([string]): Gerenciador usado
- `PackageId` ([string]): ID do pacote
- `Available` ([bool]): Se o pacote está disponível
- `Error` ([string]): Mensagem de erro, se houver

**Exemplo:**
```powershell
# Verificar pacote no Chocolatey
$info = Get-PackageChecksum -PackageId "git" -Source "chocolatey"

if ($info.Available) {
    Write-Host "Pacote encontrado: $($info.PackageId)"
}

# Verificar em diferentes gerenciadores
$chocoInfo = Get-PackageChecksum -PackageId "vscode" -Source "chocolatey"
$wingetInfo = Get-PackageChecksum -PackageId "Microsoft.VisualStudioCode" -Source "winget"
$scoopInfo = Get-PackageChecksum -PackageId "vscode" -Source "scoop"
```

**Erros Possíveis:**
- Gerenciador de pacotes não está instalado
- Pacote não encontrado no gerenciador especificado
- Erro ao consultar informações do pacote

---

#### Show-SecurityDialog

Exibe diálogo de segurança interativo para decisões sobre instalação.

**Parâmetros:**
- `Message` ([string]): Mensagem de aviso [Obrigatório]
- `PackageName` ([string]): Nome do pacote [Opcional, Padrão: "Package"]

**Retorna:** `[char]` - Escolha do usuário ('A', 'C', ou 'P')
- `A`: Abortar instalação completamente
- `C`: Continuar mesmo assim
- `P`: Pular este pacote específico

**Exemplo:**
```powershell
$choice = Show-SecurityDialog `
    -Message "Checksum não pode ser verificado" `
    -PackageName "git"

switch ($choice) {
    'A' {
        Write-Host "Abortando instalação..."
        exit 1
    }
    'C' {
        Write-Warning "Continuando sem verificação..."
        # Prosseguir com instalação
    }
    'P' {
        Write-Host "Pulando pacote git..."
        continue
    }
}
```

**Output Visual:**
```
========================================
  AVISO DE SEGURANÇA
========================================
Package: git
Problema: Checksum não pode ser verificado

Opções:
  [A] Abortar instalação
  [C] Continuar mesmo assim
  [P] Pular este package
========================================

Escolha uma opção (A/C/P):
```

---

#### Test-JsonSchema

Valida sintaxe JSON e opcionalmente verifica contra schema.

**Parâmetros:**
- `JsonPath` ([string]): Caminho do arquivo JSON [Obrigatório]
- `SchemaPath` ([string]): Caminho do arquivo de schema [Opcional]

**Retorna:** `[bool]` - `$true` se JSON válido, `$false` caso contrário

**Exemplo:**
```powershell
# Validar apenas sintaxe JSON
$valid = Test-JsonSchema -JsonPath "C:\config\settings.json"

# Validar com schema
$valid = Test-JsonSchema `
    -JsonPath "C:\config\packages.json" `
    -SchemaPath "C:\config\packages.schema.json"

if ($valid) {
    $config = Get-Content "C:\config\packages.json" | ConvertFrom-Json
    # Usar configuração
}
```

**Processo:**
1. Verifica se arquivo JSON existe
2. Lê conteúdo do arquivo
3. Tenta fazer parse com `ConvertFrom-Json`
4. Se SchemaPath fornecido, exibe mensagem informativa
5. Retorna resultado da validação

**Erros Possíveis:**
- Arquivo JSON não encontrado
- Sintaxe JSON inválida (vírgulas, chaves, aspas)
- Schema não encontrado (apenas warning, não erro)

---

#### Test-PackagesConfig

Valida arquivo de configuração de pacotes completo.

**Parâmetros:**
- `ConfigPath` ([string]): Caminho do packages.json [Opcional, Padrão: "../config/packages.json"]
- `SchemaPath` ([string]): Caminho do schema [Opcional, Padrão: "../config/packages.schema.json"]

**Retorna:** `[bool]` - `$true` se configuração válida, `$false` caso contrário

**Exemplo:**
```powershell
# Validar com caminhos padrão
if (Test-PackagesConfig) {
    Write-Host "Configuração de pacotes válida"
}

# Validar com caminhos customizados
$valid = Test-PackagesConfig `
    -ConfigPath "C:\custom\packages.json" `
    -SchemaPath "C:\custom\schema.json"
```

**Output:**
```
Validando JSON: C:\ENV\config\packages.json
JSON possui sintaxe válida
Schema encontrado: C:\ENV\config\packages.schema.json
JSON validado com sucesso
Configuração válida: 52 packages em 8 categorias
```

**Validações Realizadas:**
- Sintaxe JSON correta
- Estrutura compatível com schema
- Contagem de pacotes e categorias
- Campos obrigatórios presentes

---

### 1.3 packages.ps1

Funções para gerenciamento de pacotes.

#### Get-BestPackageManager

Determina o melhor gerenciador de pacotes disponível para um pacote específico.

**Parâmetros:**
- `Package` ([PSCustomObject]): Objeto do pacote [Obrigatório]

**Retorna:** `[hashtable]` com informações do gerenciador
- `Type` ([string]): Tipo do gerenciador (chocolatey/winget/scoop)
- `Id` ([string]): ID do pacote no gerenciador
- `Priority` ([int]): Prioridade do gerenciador (1-3)

**Exemplo:**
```powershell
$package = @{
    name = "git"
    choco_package = "git"
    winget_id = "Git.Git"
    scoop_name = "git"
}

$manager = Get-BestPackageManager -Package $package

Write-Host "Gerenciador selecionado: $($manager.Type)"
Write-Host "ID do pacote: $($manager.Id)"
Write-Host "Prioridade: $($manager.Priority)"

# Saída:
# Gerenciador selecionado: chocolatey
# ID do pacote: git
# Prioridade: 1
```

**Lógica de Seleção:**
1. Verifica gerenciadores disponíveis no sistema (choco, winget, scoop)
2. Cria lista de prioridades (Chocolatey=1, Winget=2, Scoop=3)
3. Se pacote tem propriedade `managers`, usa prioritização definida
4. Caso contrário, seleciona primeiro gerenciador disponível por prioridade
5. Retorna informações do gerenciador selecionado

**Erros Possíveis:**
- Nenhum gerenciador de pacotes disponível
- Pacote não tem IDs configurados para nenhum gerenciador
- Nenhum gerenciador compatível encontrado

---

#### Install-PackageWithFallback

Instala pacote com tentativa automática de fallback entre gerenciadores.

**Parâmetros:**
- `Package` ([PSCustomObject]): Objeto do pacote [Obrigatório]

**Retorna:** `[hashtable]` com resultado da instalação
- `Success` ([bool]): Se instalação foi bem-sucedida
- `Manager` ([string]): Gerenciador usado (se sucesso)
- `PackageName` ([string]): Nome do pacote
- `Error` ([string]): Mensagem de erro (se falha)

**Exemplo:**
```powershell
$package = @{
    name = "vscode"
    managers = @(
        @{ type = "chocolatey"; id = "vscode"; priority = 1 },
        @{ type = "winget"; id = "Microsoft.VisualStudioCode"; priority = 2 }
    )
}

$result = Install-PackageWithFallback -Package $package

if ($result.Success) {
    Write-Host "✓ $($result.PackageName) instalado via $($result.Manager)"
}
else {
    Write-Error "Falha ao instalar: $($result.Error)"
}
```

**Processo:**
1. Obtém lista de gerenciadores do pacote, ordenados por prioridade
2. Tenta instalação com primeiro gerenciador
3. Se falhar, tenta próximo gerenciador automaticamente
4. Continua até sucesso ou esgotar opções
5. Retorna resultado com detalhes

**Output Console:**
```
Tentando instalar vscode via chocolatey...
✓ vscode instalado com sucesso via chocolatey
```

**Erros Possíveis:**
- Nenhum gerenciador configurado para o pacote
- Todas as tentativas de instalação falharam
- Gerenciador específico não está instalado

---

#### Install-PackageWithManager

Instala pacote usando gerenciador específico.

**Parâmetros:**
- `Package` ([PSCustomObject]): Objeto do pacote [Obrigatório]
- `Manager` ([PSCustomObject]): Informações do gerenciador [Obrigatório]

**Retorna:** `[hashtable]` com resultado
- `Success` ([bool]): Se instalação foi bem-sucedida
- `Error` ([string]): Mensagem de erro (se falha)

**Exemplo:**
```powershell
$package = @{
    name = "nodejs"
    checksum = "ABC123..."
    checksumType = "sha256"
}

$manager = @{
    type = "chocolatey"
    id = "nodejs-lts"
}

$result = Install-PackageWithManager -Package $package -Manager $manager

if (-not $result.Success) {
    Write-Error "Erro: $($result.Error)"
}
```

**Comportamento por Gerenciador:**

**Chocolatey:**
```powershell
choco install nodejs-lts -y --no-progress --checksum=ABC123... --checksum-type=sha256
```

**Winget:**
```powershell
winget install --id Microsoft.NodeJS.LTS --accept-source-agreements --accept-package-agreements
```

**Scoop:**
```powershell
scoop install nodejs-lts
```

**Erros Possíveis:**
- Gerenciador não está instalado
- Pacote não encontrado no repositório
- Checksum não corresponde (Chocolatey)
- Falha durante instalação (código de erro não-zero)

---

#### Test-PackageManagerHealth

Verifica saúde e disponibilidade de gerenciadores de pacotes.

**Parâmetros:**
- `Manager` ([string]): Gerenciador para testar [Opcional, Padrão: "all"]
  - Valores aceitos: "chocolatey", "winget", "scoop", "all"

**Retorna:** `[hashtable]` com status de cada gerenciador
- `chocolatey` ([hashtable])
  - `Available` ([bool]): Se está instalado
  - `Healthy` ([bool]): Se está funcionando
- `winget` ([hashtable]) - Mesma estrutura
- `scoop` ([hashtable]) - Mesma estrutura

**Exemplo:**
```powershell
# Verificar todos os gerenciadores
$health = Test-PackageManagerHealth

foreach ($mgr in $health.Keys) {
    $status = if ($health[$mgr].Healthy) { "✓" } else { "✗" }
    Write-Host "$status $mgr - Disponível: $($health[$mgr].Available)"
}

# Saída:
# ✓ chocolatey - Disponível: True
# ✓ winget - Disponível: True
# ✗ scoop - Disponível: False

# Verificar gerenciador específico
$chocoHealth = Test-PackageManagerHealth -Manager "chocolatey"

if ($chocoHealth.chocolatey.Healthy) {
    Write-Host "Chocolatey está saudável e pronto"
}
```

**Uso em Scripts:**
```powershell
# Verificar antes de instalar
$health = Test-PackageManagerHealth
$hasManager = $health.Values | Where-Object { $_.Available } | Measure-Object | Select-Object -ExpandProperty Count

if ($hasManager -eq 0) {
    Write-Error "Nenhum gerenciador de pacotes disponível!"
    Write-Host "Instalando Chocolatey..."
    Install-Chocolatey
}
```

---

### 1.4 state-manager.ps1

Funções para gerenciamento de estado de instalações.

#### Initialize-StateFile

Inicializa arquivo de estado se não existir.

**Parâmetros:**
- `StatePath` ([string]): Caminho do arquivo state.json [Opcional, Padrão: "../state/state.json"]

**Retorna:** `[bool]` - `$true` se inicializado/existente, `$false` em caso de erro

**Exemplo:**
```powershell
# Inicializar com caminho padrão
if (Initialize-StateFile) {
    Write-Host "Arquivo de estado pronto"
}

# Inicializar com caminho customizado
Initialize-StateFile -StatePath "C:\CustomPath\state.json"
```

**Estrutura Criada:**
```json
{
  "version": "1.0.0",
  "created": "2025-01-24T14:30:22Z",
  "sessions": [],
  "installed": {}
}
```

---

#### New-InstallSession

Cria nova sessão de instalação no estado.

**Parâmetros:**
- `SessionId` ([string]): ID único da sessão [Opcional, auto-gerado se omitido]

**Retorna:** `[hashtable]` com informações da sessão
- `Id` ([string]): ID da sessão
- `Timestamp` ([datetime]): Data/hora de criação
- `Packages` ([array]): Lista vazia de pacotes
- `Status` ([string]): "InProgress"

**Exemplo:**
```powershell
# Criar sessão com ID auto-gerado
$session = New-InstallSession

Write-Host "Sessão criada: $($session.Id)"
# Saída: Sessão criada: session-20250124-143022

# Criar sessão com ID customizado
$session = New-InstallSession -SessionId "manual-install-001"
```

**Uso Completo:**
```powershell
$session = New-InstallSession

try {
    # Instalar pacotes
    $packages = @("git", "vscode", "nodejs")

    foreach ($pkg in $packages) {
        Add-PackageToSession -SessionId $session.Id -Package $pkg -Status "Success"
    }

    Complete-InstallSession -SessionId $session.Id -Status "Completed"
}
catch {
    Complete-InstallSession -SessionId $session.Id -Status "Failed"
}
```

---

#### Add-PackageToSession

Adiciona pacote instalado à sessão atual.

**Parâmetros:**
- `SessionId` ([string]): ID da sessão [Obrigatório]
- `PackageName` ([string]): Nome do pacote [Obrigatório]
- `Version` ([string]): Versão instalada [Opcional]
- `Manager` ([string]): Gerenciador usado [Opcional]
- `Status` ([string]): Status da instalação [Obrigatório]
  - Valores: "Success", "Failed", "Skipped"
- `InstallTime` ([string]): Tempo de instalação [Opcional]

**Retorna:** `[bool]` - `$true` se adicionado com sucesso

**Exemplo:**
```powershell
$sessionId = $session.Id

# Instalação bem-sucedida
Add-PackageToSession `
    -SessionId $sessionId `
    -PackageName "git" `
    -Version "2.43.0" `
    -Manager "chocolatey" `
    -Status "Success" `
    -InstallTime "45.2s"

# Instalação falhada
Add-PackageToSession `
    -SessionId $sessionId `
    -PackageName "invalid-package" `
    -Status "Failed" `
    -Manager "chocolatey"

# Pacote pulado
Add-PackageToSession `
    -SessionId $sessionId `
    -PackageName "optional-tool" `
    -Status "Skipped"
```

---

#### Get-InstallHistory

Obtém histórico de todas as sessões de instalação.

**Parâmetros:**
- `Last` ([int]): Número de sessões mais recentes [Opcional]
- `SessionId` ([string]): ID de sessão específica [Opcional]

**Retorna:** `[array]` de sessões ou `[hashtable]` de sessão única

**Exemplo:**
```powershell
# Obter todas as sessões
$allSessions = Get-InstallHistory

foreach ($session in $allSessions) {
    Write-Host "Sessão: $($session.Id)"
    Write-Host "Data: $($session.Timestamp)"
    Write-Host "Pacotes: $($session.Packages.Count)"
    Write-Host "Status: $($session.Status)"
    Write-Host "---"
}

# Obter últimas 5 sessões
$recentSessions = Get-InstallHistory -Last 5

# Obter sessão específica
$session = Get-InstallHistory -SessionId "session-20250124-143022"

Write-Host "Pacotes instalados nesta sessão:"
foreach ($pkg in $session.Packages) {
    Write-Host "  - $($pkg.Name) $($pkg.Version) via $($pkg.Manager)"
}
```

---

#### Test-PackageInstalled

Verifica se um pacote está instalado.

**Parâmetros:**
- `PackageName` ([string]): Nome do pacote [Obrigatório]

**Retorna:** `[bool]` - `$true` se instalado, `$false` caso contrário

**Exemplo:**
```powershell
# Verificar antes de instalar
if (Test-PackageInstalled -PackageName "git") {
    Write-Host "Git já está instalado"
    $version = Get-InstalledVersion -PackageName "git"
    Write-Host "Versão: $version"
}
else {
    Write-Host "Instalando Git..."
    # Prosseguir com instalação
}

# Usar em loop
$packages = @("git", "vscode", "nodejs", "docker")

foreach ($pkg in $packages) {
    if (-not (Test-PackageInstalled -PackageName $pkg)) {
        Write-Host "Instalando $pkg..."
        # Install-Package $pkg
    }
}
```

---

#### Get-InstalledVersion

Obtém versão instalada de um pacote.

**Parâmetros:**
- `PackageName` ([string]): Nome do pacote [Obrigatório]

**Retorna:** `[string]` - Versão ou `$null` se não instalado

**Exemplo:**
```powershell
$gitVersion = Get-InstalledVersion -PackageName "git"

if ($gitVersion) {
    Write-Host "Git versão $gitVersion está instalado"

    # Comparar versões
    $requiredVersion = [version]"2.40.0"
    $currentVersion = [version]$gitVersion

    if ($currentVersion -lt $requiredVersion) {
        Write-Warning "Versão do Git desatualizada. Atualize para $requiredVersion+"
    }
}
else {
    Write-Host "Git não está instalado"
}
```

---

#### Start-Rollback

Inicia processo de rollback de uma sessão.

**Parâmetros:**
- `SessionId` ([string]): ID da sessão para fazer rollback [Obrigatório]
- `RestoreBackup` ([bool]): Se deve restaurar backup [Opcional, Padrão: $true]

**Retorna:** `[hashtable]` com resultado do rollback
- `Success` ([bool])
- `PackagesRemoved` ([int])
- `BackupRestored` ([bool])
- `Errors` ([array])

**Exemplo:**
```powershell
# Rollback completo (desinstalar + restaurar backup)
$result = Start-Rollback -SessionId "session-20250124-143022"

if ($result.Success) {
    Write-Host "Rollback concluído com sucesso"
    Write-Host "Pacotes removidos: $($result.PackagesRemoved)"
    Write-Host "Backup restaurado: $($result.BackupRestored)"
}
else {
    Write-Error "Erros durante rollback:"
    $result.Errors | ForEach-Object { Write-Error $_ }
}

# Rollback sem restaurar backup
$result = Start-Rollback -SessionId "session-20250124-143022" -RestoreBackup $false
```

**Processo:**
1. Obtém lista de pacotes da sessão
2. Filtra apenas pacotes com status "Success"
3. Desinstala cada pacote usando gerenciador apropriado
4. Se `RestoreBackup=$true`, restaura configurações de backup
5. Atualiza estado removendo pacotes
6. Retorna resultado detalhado

---

### 1.5 backup.ps1

Funções para gerenciamento de backups.

#### New-EnvironmentBackup

Cria novo backup completo do ambiente.

**Parâmetros:**
- `BackupId` ([string]): ID do backup [Opcional, auto-gerado se omitido]
- `Reason` ([string]): Motivo do backup [Opcional, Padrão: "Manual backup"]
- `IncludeDotfiles` ([bool]): Incluir dotfiles [Opcional, Padrão: $true]
- `Compress` ([bool]): Comprimir backup [Opcional, Padrão: $true]

**Retorna:** `[hashtable]` com informações do backup criado
- `Id` ([string]): ID do backup
- `Timestamp` ([datetime])
- `Path` ([string]): Caminho do backup
- `Size` ([string]): Tamanho formatado
- `Compressed` ([bool])

**Exemplo:**
```powershell
# Backup padrão (completo e comprimido)
$backup = New-EnvironmentBackup

Write-Host "Backup criado: $($backup.Id)"
Write-Host "Localização: $($backup.Path)"
Write-Host "Tamanho: $($backup.Size)"

# Backup com motivo específico
$backup = New-EnvironmentBackup -Reason "Antes de atualização major"

# Backup sem compressão
$backup = New-EnvironmentBackup -Compress $false

# Backup sem dotfiles
$backup = New-EnvironmentBackup -IncludeDotfiles $false -Reason "Apenas configuração ENV"
```

**Conteúdo do Backup:**
```
backups/backup-20250124-143022/
├── metadata.json          # Informações do backup
├── state.json             # Estado atual
├── config/
│   ├── packages.json
│   ├── presets.json
│   └── strings.json
├── dotfiles/              # Se IncludeDotfiles=$true
│   ├── PowerShell/
│   ├── .gitconfig
│   ├── starship.toml
│   └── bat/
└── logs/
    └── session.log
```

---

#### Get-BackupList

Lista todos os backups disponíveis.

**Parâmetros:**
- `SortBy` ([string]): Campo para ordenar [Opcional, Padrão: "Timestamp"]
  - Valores: "Timestamp", "Size", "Id"
- `Descending` ([bool]): Ordem decrescente [Opcional, Padrão: $true]

**Retorna:** `[array]` de backups

**Exemplo:**
```powershell
# Listar todos os backups (mais recente primeiro)
$backups = Get-BackupList

foreach ($backup in $backups) {
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Write-Host "ID: $($backup.Id)"
    Write-Host "Data: $($backup.Timestamp)"
    Write-Host "Tamanho: $($backup.Size)"
    Write-Host "Razão: $($backup.Reason)"
    Write-Host "Arquivos: $($backup.FileCount)"
}

# Listar ordenado por tamanho (maior primeiro)
$backups = Get-BackupList -SortBy "Size" -Descending $true

# Listar ordenado por data (mais antigo primeiro)
$backups = Get-BackupList -SortBy "Timestamp" -Descending $false
```

**Output Exemplo:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: backup-20250124-143022
Data: 24/01/2025 14:30:22
Tamanho: 2.4 MB
Razão: Pré-instalação automática
Arquivos: 15
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ID: backup-20250123-091533
Data: 23/01/2025 09:15:33
Tamanho: 1.8 MB
Razão: Backup manual
Arquivos: 12
```

---

#### Restore-EnvironmentBackup

Restaura ambiente de um backup.

**Parâmetros:**
- `BackupId` ([string]): ID do backup [Obrigatório]
- `RestoreDotfiles` ([bool]): Restaurar dotfiles [Opcional, Padrão: $true]
- `CreateBackupBeforeRestore` ([bool]): Criar backup antes [Opcional, Padrão: $true]

**Retorna:** `[bool]` - `$true` se restaurado com sucesso

**Exemplo:**
```powershell
# Restauração completa (com backup de segurança)
if (Restore-EnvironmentBackup -BackupId "backup-20250124-143022") {
    Write-Host "Ambiente restaurado com sucesso"
}

# Restaurar sem dotfiles
Restore-EnvironmentBackup -BackupId "backup-20250124-143022" -RestoreDotfiles $false

# Restaurar sem criar backup de segurança (não recomendado)
Restore-EnvironmentBackup `
    -BackupId "backup-20250124-143022" `
    -CreateBackupBeforeRestore $false
```

**Processo:**
1. Valida que backup existe
2. Se `CreateBackupBeforeRestore=$true`, cria backup atual
3. Lê metadata do backup
4. Restaura arquivos de configuração
5. Se `RestoreDotfiles=$true`, restaura dotfiles
6. Atualiza estado
7. Exibe resumo

**Aviso:**
```
⚠️  ATENÇÃO: Esta operação irá sobrescrever suas configurações atuais!

Backup: backup-20250124-143022
Data: 24/01/2025 14:30:22
Razão: Pré-instalação automática

Deseja continuar? (S/N):
```

---

#### Compare-Backups

Compara dois backups e exibe diferenças.

**Parâmetros:**
- `Backup1` ([string]): ID do primeiro backup [Obrigatório]
- `Backup2` ([string]): ID do segundo backup [Obrigatório]

**Retorna:** `[hashtable]` com diferenças
- `Added` ([array]): Pacotes adicionados
- `Removed` ([array]): Pacotes removidos
- `Modified` ([array]): Arquivos modificados

**Exemplo:**
```powershell
$diff = Compare-Backups `
    -Backup1 "backup-20250123-091533" `
    -Backup2 "backup-20250124-143022"

Write-Host "Mudanças entre backups:"
Write-Host ""

if ($diff.Added.Count -gt 0) {
    Write-Host "Adicionados:" -ForegroundColor Green
    $diff.Added | ForEach-Object {
        Write-Host "  + $($_.Name) ($($_.Version))" -ForegroundColor Green
    }
}

if ($diff.Removed.Count -gt 0) {
    Write-Host "Removidos:" -ForegroundColor Red
    $diff.Removed | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor Red
    }
}

if ($diff.Modified.Count -gt 0) {
    Write-Host "Modificados:" -ForegroundColor Yellow
    $diff.Modified | ForEach-Object {
        Write-Host "  ~ $($_.File) ($($_.Changes) linhas)" -ForegroundColor Yellow
    }
}
```

**Output:**
```
Mudanças entre backups:

Adicionados:
  + git (2.43.0)
  + vscode (1.85.0)
  + nodejs (20.10.0)

Modificados:
  ~ .gitconfig (12 linhas)
  ~ PowerShell profile (8 linhas)
```

---

#### Export-Backup

Exporta backup como arquivo ZIP.

**Parâmetros:**
- `BackupId` ([string]): ID do backup [Obrigatório]
- `DestinationPath` ([string]): Caminho do ZIP [Obrigatório]
- `IncludeMetadata` ([bool]): Incluir metadata [Opcional, Padrão: $true]

**Retorna:** `[string]` - Caminho do arquivo ZIP criado

**Exemplo:**
```powershell
# Exportar backup
$zipPath = Export-Backup `
    -BackupId "backup-20250124-143022" `
    -DestinationPath "C:\Backups\env-backup-$(Get-Date -Format 'yyyyMMdd').zip"

Write-Host "Backup exportado para: $zipPath"

# Enviar para outro computador, cloud storage, etc.
Copy-Item $zipPath -Destination "\\NetworkShare\Backups\" -Force
```

**ZIP Contém:**
- Todos os arquivos do backup
- metadata.json com informações
- README.txt com instruções de importação

---

#### Import-Backup

Importa backup de arquivo ZIP.

**Parâmetros:**
- `ZipPath` ([string]): Caminho do arquivo ZIP [Obrigatório]
- `BackupId` ([string]): ID para o backup importado [Opcional, auto-gerado se omitido]

**Retorna:** `[hashtable]` com informações do backup importado

**Exemplo:**
```powershell
# Importar backup de ZIP
$backup = Import-Backup -ZipPath "C:\Downloads\env-backup-20250124.zip"

Write-Host "Backup importado: $($backup.Id)"

# Restaurar backup importado
Restore-EnvironmentBackup -BackupId $backup.Id
```

**Uso Cross-Machine:**
```powershell
# Máquina A - Exportar
$zipPath = Export-Backup -BackupId "backup-20250124-143022" -DestinationPath "backup.zip"

# [Transferir backup.zip para Máquina B]

# Máquina B - Importar e restaurar
$backup = Import-Backup -ZipPath "C:\Downloads\backup.zip"
Restore-EnvironmentBackup -BackupId $backup.Id
```

---

#### Remove-OldBackups

Remove backups antigos mantendo apenas os mais recentes.

**Parâmetros:**
- `Keep` ([int]): Número de backups para manter [Obrigatório]
  - Validação: Mínimo 1
- `KeepDays` ([int]): Manter backups dos últimos N dias [Opcional]
- `WhatIf` ([bool]): Modo dry-run [Opcional, Padrão: $false]

**Retorna:** `[array]` de backups removidos

**Exemplo:**
```powershell
# Manter apenas últimos 5 backups
$removed = Remove-OldBackups -Keep 5

Write-Host "Backups removidos: $($removed.Count)"
$removed | ForEach-Object {
    Write-Host "  - $($_.Id) ($($_.Size))"
}

# Manter últimos 3 + todos dos últimos 30 dias
$removed = Remove-OldBackups -Keep 3 -KeepDays 30

# Modo dry-run (ver o que seria removido)
$wouldRemove = Remove-OldBackups -Keep 5 -WhatIf $true

Write-Host "Seriam removidos $($wouldRemove.Count) backups:"
$wouldRemove | ForEach-Object { Write-Host "  - $($_.Id)" }
```

**Lógica:**
1. Lista todos os backups ordenados por data (mais recente primeiro)
2. Mantém primeiros N backups (parâmetro `Keep`)
3. Se `KeepDays` especificado, também mantém backups dentro do período
4. Remove backups restantes
5. Retorna lista de removidos

---

### 1.6 error-handler.ps1

Funções para tratamento de erros.

#### Write-ErrorLog

Registra erro em arquivo de log.

**Parâmetros:**
- `Message` ([string]): Mensagem de erro [Obrigatório]
- `Exception` ([Exception]): Objeto de exceção [Opcional]
- `Category` ([string]): Categoria do erro [Opcional, Padrão: "General"]
- `Severity` ([string]): Severidade [Opcional, Padrão: "Error"]
  - Valores: "Info", "Warning", "Error", "Critical"

**Retorna:** `[void]`

**Exemplo:**
```powershell
try {
    # Código que pode falhar
    Install-Package -Name "invalid-package"
}
catch {
    Write-ErrorLog `
        -Message "Falha ao instalar pacote" `
        -Exception $_.Exception `
        -Category "PackageInstallation" `
        -Severity "Error"

    # Re-lançar ou continuar
    throw
}
```

**Formato do Log:**
```
[2025-01-24 14:30:22] [ERROR] [PackageInstallation] Falha ao instalar pacote
Exception: PackageNotFoundException: Pacote não encontrado no repositório
StackTrace: at Install-Package, line 45
```

---

#### Get-ErrorSummary

Obtém resumo de erros da sessão atual.

**Parâmetros:**
- `SessionId` ([string]): ID da sessão [Opcional, usa sessão atual se omitido]
- `IncludeWarnings` ([bool]): Incluir warnings [Opcional, Padrão: $false]

**Retorna:** `[hashtable]` com estatísticas
- `TotalErrors` ([int])
- `TotalWarnings` ([int])
- `ByCategory` ([hashtable])
- `BySeverity` ([hashtable])
- `Errors` ([array])

**Exemplo:**
```powershell
$summary = Get-ErrorSummary -IncludeWarnings $true

Write-Host "═══════════════════════════════════"
Write-Host "Resumo de Erros da Sessão"
Write-Host "═══════════════════════════════════"
Write-Host "Total de Erros: $($summary.TotalErrors)"
Write-Host "Total de Warnings: $($summary.TotalWarnings)"
Write-Host ""
Write-Host "Por Categoria:"
$summary.ByCategory.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}
Write-Host ""
Write-Host "Por Severidade:"
$summary.BySeverity.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key): $($_.Value)"
}
```

**Output:**
```
═══════════════════════════════════
Resumo de Erros da Sessão
═══════════════════════════════════
Total de Erros: 3
Total de Warnings: 5

Por Categoria:
  PackageInstallation: 2
  NetworkConnection: 1

Por Severidade:
  Error: 3
  Warning: 5
```

---

## 2. Installers

### 2.1 terminal-env.ps1

Funções para configuração de terminal.

#### Install-OhMyPosh

Instala e configura Oh My Posh.

**Parâmetros:**
- `Theme` ([string]): Tema para aplicar [Opcional, Padrão: "env-default"]
- `Font` ([string]): Nerd Font para instalar [Opcional, Padrão: "FiraCode"]
  - Valores: "FiraCode", "CascadiaCode", "JetBrainsMono", "Hack", "Meslo"

**Retorna:** `[bool]` - `$true` se instalado com sucesso

**Exemplo:**
```powershell
# Instalação padrão (tema env-default, fonte FiraCode)
if (Install-OhMyPosh) {
    Write-Host "Oh My Posh configurado com sucesso"
}

# Instalação com tema e fonte customizados
Install-OhMyPosh -Theme "powerline" -Font "JetBrainsMono"
```

**Processo:**
1. Instala Oh My Posh via package manager
2. Baixa e instala Nerd Font especificada
3. Copia tema para diretório de temas
4. Atualiza PowerShell profile
5. Define fonte padrão no Windows Terminal

**Profile Modificado:**
```powershell
# Oh My Posh
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\env-default.omp.json" | Invoke-Expression
```

---

#### Install-Starship

Instala e configura Starship prompt.

**Parâmetros:**
- `Preset` ([string]): Preset para aplicar [Opcional, Padrão: "nerd-font-symbols"]

**Retorna:** `[bool]` - `$true` se instalado com sucesso

**Exemplo:**
```powershell
# Instalação padrão
if (Install-Starship) {
    Write-Host "Starship configurado"
}

# Com preset customizado
Install-Starship -Preset "pure-preset"
```

**Profile Modificado:**
```powershell
# Starship
Invoke-Starship init pwsh | Invoke-Expression
```

---

#### Install-PSReadLine

Instala e configura PSReadLine.

**Parâmetros:**
- `PredictionSource` ([string]): Fonte de predição [Opcional, Padrão: "HistoryAndPlugin"]

**Retorna:** `[bool]` - `$true` se instalado com sucesso

**Exemplo:**
```powershell
Install-PSReadLine
```

**Configurações Aplicadas:**
```powershell
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
```

---

### 2.2 modern-tools.ps1

Funções para instalação de ferramentas CLI modernas.

#### Install-ModernTools

Instala todas as ferramentas CLI modernas.

**Parâmetros:**
- `Tools` ([array]): Lista de ferramentas [Opcional, todas se omitido]
  - Valores: "bat", "eza", "fzf", "ripgrep", "zoxide"

**Retorna:** `[hashtable]` com resultado de cada ferramenta

**Exemplo:**
```powershell
# Instalar todas as ferramentas
$result = Install-ModernTools

$result.GetEnumerator() | ForEach-Object {
    $status = if ($_.Value.Success) { "✓" } else { "✗" }
    Write-Host "$status $($_.Key)"
}

# Instalar ferramentas específicas
$result = Install-ModernTools -Tools @("bat", "eza", "fzf")
```

---

#### Install-Bat

Instala bat com configuração.

**Parâmetros:**
- `Theme` ([string]): Tema para bat [Opcional, Padrão: "Monokai Extended"]

**Retorna:** `[bool]` - `$true` se instalado com sucesso

**Exemplo:**
```powershell
Install-Bat -Theme "Monokai Extended"
```

**Configuração Criada:** `~/.config/bat/config`
```
--theme="Monokai Extended"
--style="numbers,changes,header"
--paging=auto
```

**Aliases Criados:**
```powershell
Set-Alias -Name cat -Value bat -Option AllScope
```

---

#### Install-Eza

Instala eza com configuração.

**Parâmetros:** Nenhum

**Retorna:** `[bool]` - `$true` se instalado com sucesso

**Exemplo:**
```powershell
Install-Eza
```

**Aliases Criados:**
```powershell
Set-Alias -Name ls -Value eza -Option AllScope
function ll { eza -l --icons --git }
function la { eza -la --icons --git }
function lt { eza --tree --level=2 }
```

---

#### Install-Fzf

Instala fzf com integração PowerShell.

**Parâmetros:** Nenhum

**Retorna:** `[bool]` - `$true` se instalado com sucesso

**Exemplo:**
```powershell
Install-Fzf
```

**Keybindings Configurados:**
- `Ctrl+R` - Buscar histórico de comandos
- `Ctrl+T` - Buscar arquivos
- `Alt+C` - Mudar diretório

---

#### Install-Ripgrep

Instala ripgrep (rg).

**Parâmetros:** Nenhum

**Retorna:** `[bool]` - `$true` se instalado com sucesso

**Exemplo:**
```powershell
Install-Ripgrep
```

---

#### Install-Zoxide

Instala zoxide com integração PowerShell.

**Parâmetros:** Nenhum

**Retorna:** `[bool]` - `$true` se instalado com sucesso

**Exemplo:**
```powershell
Install-Zoxide
```

**Profile Modificado:**
```powershell
# Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })
```

---

### 2.3 git-env.ps1

Funções para configuração do Git.

#### Install-GitWithConfig

Instala Git e aplica configuração completa.

**Parâmetros:**
- `UserName` ([string]): Nome do usuário Git [Opcional]
- `UserEmail` ([string]): Email do usuário Git [Opcional]
- `SkipAliases` ([bool]): Não criar aliases [Opcional, Padrão: $false]

**Retorna:** `[bool]` - `$true` se instalado e configurado com sucesso

**Exemplo:**
```powershell
# Instalação interativa (solicita nome e email)
Install-GitWithConfig

# Instalação com parâmetros
Install-GitWithConfig `
    -UserName "Thiago Di Faria" `
    -UserEmail "thiagodifaria@gmail.com"

# Instalar sem aliases
Install-GitWithConfig -SkipAliases $true
```

**Configurações Aplicadas:**
```bash
# Usuário
user.name = Thiago Di Faria
user.email = thiagodifaria@gmail.com

# Core
core.autocrlf = true
core.editor = code --wait
core.pager = bat

# Credential
credential.helper = manager-core

# Performance
fetch.parallel = 10
fetch.prune = true

# Pull/Push
pull.rebase = true
push.default = current

# Init
init.defaultBranch = main

# Diff/Merge
diff.algorithm = histogram
merge.conflictStyle = diff3
```

---

#### Set-GitAliases

Configura aliases profissionais do Git.

**Parâmetros:** Nenhum

**Retorna:** `[bool]` - `$true` se configurado com sucesso

**Exemplo:**
```powershell
Set-GitAliases
```

**Aliases Criados:**
```bash
lg = log --graph --oneline --decorate --all
undo = reset HEAD~1 --soft
amend = commit --amend --no-edit
wip = commit -am "WIP"
save = !git add -A && git commit -m "SAVEPOINT"
unstage = reset HEAD --
last = log -1 HEAD
co = checkout
br = branch
st = status
cm = commit -m
df = diff
dfs = diff --staged
alias = !git config --get-regexp ^alias\\.
cleanup = !git branch --merged | grep -v \"\\*\" | xargs -n 1 git branch -d
```

---

## 3. Utils

### 3.1 cache.ps1

Funções para gerenciamento de cache.

#### Get-CachedData

Obtém dados do cache se válido.

**Parâmetros:**
- `Key` ([string]): Chave do cache [Obrigatório]

**Retorna:** Dados em cache ou `$null` se expirado/não encontrado

**Exemplo:**
```powershell
$packageInfo = Get-CachedData -Key "package-info-git"

if ($packageInfo) {
    Write-Host "Usando dados em cache"
    Write-Host "Versão: $($packageInfo.Version)"
}
else {
    Write-Host "Cache miss - buscando dados..."
    $packageInfo = Get-PackageInfo -Name "git"
    Set-CachedData -Key "package-info-git" -Data $packageInfo -TTL 21600
}
```

---

#### Set-CachedData

Armazena dados no cache com TTL.

**Parâmetros:**
- `Key` ([string]): Chave do cache [Obrigatório]
- `Data` ([object]): Dados para cachear [Obrigatório]
- `TTL` ([int]): Time-to-live em segundos [Obrigatório]

**Retorna:** `[bool]` - `$true` se armazenado com sucesso

**Exemplo:**
```powershell
$data = @{
    Name = "git"
    Version = "2.43.0"
    Size = "48.2 MB"
}

# Cache por 6 horas (21600 segundos)
Set-CachedData -Key "package-info-git" -Data $data -TTL 21600

# Cache por 1 dia (86400 segundos)
Set-CachedData -Key "package-list-chocolatey" -Data $packages -TTL 86400
```

---

#### Clear-CachedData

Remove entrada específica do cache.

**Parâmetros:**
- `Key` ([string]): Chave para remover [Obrigatório]

**Retorna:** `[bool]` - `$true` se removido com sucesso

**Exemplo:**
```powershell
Clear-CachedData -Key "package-info-git"
```

---

#### Clear-AllCache

Remove todas as entradas do cache.

**Parâmetros:** Nenhum

**Retorna:** `[int]` - Número de entradas removidas

**Exemplo:**
```powershell
$removed = Clear-AllCache

Write-Host "$removed entradas de cache removidas"
```

---

#### Get-CacheStats

Obtém estatísticas do cache.

**Parâmetros:** Nenhum

**Retorna:** `[hashtable]` com estatísticas

**Exemplo:**
```powershell
$stats = Get-CacheStats

Write-Host "Estatísticas de Cache:"
Write-Host "Total de entradas: $($stats.TotalEntries)"
Write-Host "Tamanho total: $($stats.TotalSize)"
Write-Host "Taxa de acerto: $($stats.HitRate)%"
Write-Host "Entradas expiradas: $($stats.ExpiredEntries)"
Write-Host "Entradas válidas: $($stats.ValidEntries)"
```

---

### 3.2 parallel.ps1

Funções para execução paralela.

#### Start-ParallelInstall

Inicia instalação paralela de pacotes.

**Parâmetros:**
- `Packages` ([array]): Lista de pacotes [Obrigatório]
- `MaxParallel` ([int]): Máximo de jobs concorrentes [Opcional, Padrão: 3]
  - Validação: Entre 1 e 10
- `ThrottleLimit` ([int]): Limite de CPU [Opcional]

**Retorna:** `[array]` de resultados

**Exemplo:**
```powershell
$packages = @("git", "vscode", "nodejs", "python", "docker")

$results = Start-ParallelInstall -Packages $packages -MaxParallel 3

foreach ($result in $results) {
    $status = if ($result.Success) { "✓" } else { "✗" }
    Write-Host "$status $($result.PackageName) - $($result.Duration)"
}
```

---

### 3.3 dotfiles.ps1

Funções para gerenciamento de dotfiles.

#### Export-Dotfiles

Exporta dotfiles para pasta.

**Parâmetros:**
- `DestinationPath` ([string]): Caminho de destino [Obrigatório]
- `IncludeFiles` ([array]): Arquivos para incluir [Opcional, todos se omitido]

**Retorna:** `[hashtable]` com arquivos exportados

**Exemplo:**
```powershell
$exported = Export-Dotfiles -DestinationPath "C:\MyDotfiles"

Write-Host "Arquivos exportados: $($exported.Count)"
```

---

#### Import-Dotfiles

Importa dotfiles de pasta.

**Parâmetros:**
- `SourcePath` ([string]): Caminho de origem [Obrigatório]
- `CreateBackup` ([bool]): Criar backup antes [Opcional, Padrão: $true]

**Retorna:** `[bool]` - `$true` se importado com sucesso

**Exemplo:**
```powershell
Import-Dotfiles -SourcePath "C:\MyDotfiles"
```

---

#### Initialize-DotfilesRepo

Inicializa repositório Git para dotfiles.

**Parâmetros:**
- `Path` ([string]): Caminho do repositório [Obrigatório]
- `RemoteUrl` ([string]): URL do repositório remoto [Obrigatório]

**Retorna:** `[bool]` - `$true` se inicializado com sucesso

**Exemplo:**
```powershell
Initialize-DotfilesRepo `
    -Path "C:\Dotfiles" `
    -RemoteUrl "https://github.com/user/dotfiles.git"
```

---

#### Push-Dotfiles

Faz commit e push dos dotfiles.

**Parâmetros:**
- `Message` ([string]): Mensagem do commit [Obrigatório]

**Retorna:** `[bool]` - `$true` se pushed com sucesso

**Exemplo:**
```powershell
Push-Dotfiles -Message "Atualizar configuração PowerShell"
```

---

#### Pull-Dotfiles

Faz pull dos dotfiles do repositório.

**Parâmetros:** Nenhum

**Retorna:** `[bool]` - `$true` se pulled com sucesso

**Exemplo:**
```powershell
Pull-Dotfiles
```

---

## 4. UI

### 4.1 progress.ps1

Funções para exibição de progresso.

#### Show-ProgressBar

Exibe barra de progresso.

**Parâmetros:**
- `Activity` ([string]): Descrição da atividade [Obrigatório]
- `Status` ([string]): Status atual [Obrigatório]
- `PercentComplete` ([int]): Porcentagem [Obrigatório, 0-100]

**Retorna:** `[void]`

**Exemplo:**
```powershell
for ($i = 1; $i -le 100; $i++) {
    Show-ProgressBar `
        -Activity "Instalando pacotes" `
        -Status "Instalando pacote $i de 100" `
        -PercentComplete $i
    Start-Sleep -Milliseconds 100
}
```

---

### 4.2 prompts.ps1

Funções para prompts interativos.

#### Show-Menu

Exibe menu interativo.

**Parâmetros:**
- `Title` ([string]): Título do menu [Obrigatório]
- `Options` ([array]): Lista de opções [Obrigatório]
- `AllowMultiple` ([bool]): Permitir seleção múltipla [Opcional, Padrão: $false]

**Retorna:** Opção selecionada ou array de opções

**Exemplo:**
```powershell
$option = Show-Menu `
    -Title "Escolha uma categoria" `
    -Options @("Languages", "DevTools", "Terminal", "Git")

Write-Host "Você escolheu: $option"
```

---

## 5. Exemplos de Uso

### Instalação Completa com Todos os Recursos

```powershell
# 1. Verificar pré-requisitos
if (-not (Test-Administrator)) {
    Write-Error "Execute como Administrador"
    exit 1
}

if (-not (Test-DiskSpace -RequiredGB 30)) {
    Write-Error "Espaço em disco insuficiente"
    exit 1
}

if (-not (Test-NetworkConnection)) {
    Write-Error "Sem conexão com internet"
    exit 1
}

# 2. Criar backup antes de modificações
$backup = New-EnvironmentBackup -Reason "Antes de instalação ENV"
Write-Host "Backup criado: $($backup.Id)"

# 3. Inicializar estado
Initialize-StateFile

# 4. Criar nova sessão
$session = New-InstallSession

# 5. Instalar package managers se necessário
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Install-Chocolatey
}

# 6. Validar configuração
if (-not (Test-PackagesConfig)) {
    Write-Error "Configuração de pacotes inválida"
    exit 1
}

# 7. Carregar pacotes
$config = Get-Content "config/packages.json" | ConvertFrom-Json

# 8. Instalar pacotes com fallback paralelo
$packages = @()
$config.PSObject.Properties | ForEach-Object {
    $config.$($_.Name) | ForEach-Object {
        $packages += $_
    }
}

$results = Start-ParallelInstall -Packages $packages -MaxParallel 3

# 9. Registrar instalações no estado
foreach ($result in $results) {
    Add-PackageToSession `
        -SessionId $session.Id `
        -PackageName $result.PackageName `
        -Version $result.Version `
        -Manager $result.Manager `
        -Status $(if ($result.Success) { "Success" } else { "Failed" }) `
        -InstallTime $result.Duration
}

# 10. Configurar terminal
Install-OhMyPosh -Theme "env-default" -Font "FiraCode"

# 11. Instalar ferramentas modernas
Install-ModernTools

# 12. Configurar Git
Install-GitWithConfig -UserName "Seu Nome" -UserEmail "email@example.com"

# 13. Exportar dotfiles
Export-Dotfiles -DestinationPath "C:\Dotfiles"

# 14. Finalizar sessão
Complete-InstallSession -SessionId $session.Id -Status "Completed"

# 15. Resumo
Write-Host "═══════════════════════════════════"
Write-Host "Instalação Concluída!"
Write-Host "═══════════════════════════════════"

$summary = Get-ErrorSummary
if ($summary.TotalErrors -eq 0) {
    Write-Host "✓ Sem erros" -ForegroundColor Green
}
else {
    Write-Host "✗ $($summary.TotalErrors) erros encontrados" -ForegroundColor Red
}

$history = Get-InstallHistory -SessionId $session.Id
Write-Host "Pacotes instalados: $($history.Packages.Count)"
```

---

## 6. Códigos de Erro

### Códigos de Saída

| Código | Descrição |
|--------|-----------|
| 0 | Sucesso |
| 1 | Erro geral |
| 2 | Sem privilégios de administrador |
| 3 | Espaço em disco insuficiente |
| 4 | Sem conexão de rede |
| 5 | Nenhum package manager disponível |
| 10 | Validação de configuração falhou |
| 20 | Instalação de pacote falhou |
| 30 | Erro de backup/restore |
| 40 | Erro de estado/sessão |

### Categorias de Erro

| Categoria | Descrição | Ação Recomendada |
|-----------|-----------|------------------|
| `Prerequisites` | Falha em pré-requisitos | Corrigir antes de continuar |
| `PackageInstallation` | Erro ao instalar pacote | Tentar manualmente ou pular |
| `NetworkConnection` | Problema de conectividade | Verificar internet |
| `Validation` | Erro de validação | Corrigir configuração |
| `State` | Erro de gerenciamento estado | Restaurar de backup |
| `Backup` | Erro de backup/restore | Verificar permissões |

---

## 📚 Recursos Adicionais

- [Documentação Principal](../README.md)
- [Guia de Arquitetura](ARCHITECTURE.md)
- [Guia de Assinatura de Scripts](SIGNATURE.md)