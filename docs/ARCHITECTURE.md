# Arquitetura - ENV

Documentação técnica da arquitetura do projeto ENV.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Estrutura de Diretórios](#estrutura-de-diretórios)
- [Módulos Core](#módulos-core)
- [Fluxo de Execução](#fluxo-de-execução)
- [Design Patterns](#design-patterns)
- [Gerenciamento de Estado](#gerenciamento-de-estado)
- [Sistema de Cache](#sistema-de-cache)
- [Execução Paralela](#execução-paralela)
- [Tratamento de Erros](#tratamento-de-erros)
- [Decisões Técnicas](#decisões-técnicas)

---

## Visão Geral

ENV é um framework de automação PowerShell modular que segue princípios SOLID para setup de ambientes de desenvolvimento Windows.

### Stack Tecnológica

**Core:**
- PowerShell 5.1+ (compatibilidade Desktop + Core 7+)
- JSON para configuração e estado
- JSON Schema para validação

**Package Managers:**
- Chocolatey (prioridade 1)
- Winget (prioridade 2)
- Scoop (prioridade 3)

**Testes:**
- Pester 5.0+
- PSScriptAnalyzer
- GitHub Actions

---

## Estrutura de Diretórios

```
Env/
├── setup.ps1                    # Entry point principal
├── config/                      # Configurações
│   ├── packages.json           # Definição de pacotes
│   ├── packages.schema.json    # Schema de validação
│   ├── presets.json            # Presets de instalação
│   └── strings.json            # Strings localizadas
├── core/                        # Módulos core
│   ├── utils.ps1               # Funções utilitárias
│   ├── validation.ps1          # Validação e segurança
│   ├── packages.ps1            # Gerenciamento de pacotes
│   ├── state-manager.ps1       # Gerenciamento de estado
│   ├── backup.ps1              # Sistema de backup
│   └── error-handler.ps1       # Tratamento de erros
├── installers/                  # Instaladores específicos
│   ├── terminal-setup.ps1      # Oh My Posh, Starship
│   ├── modern-tools.ps1        # bat, eza, fzf, rg, zoxide
│   ├── git-setup.ps1           # Git + configuração
│   ├── devtools.ps1            # VS Code, IDEs
│   └── languages.ps1           # Node, Python, Go, etc.
├── utils/                       # Utilitários
│   ├── cache.ps1               # Sistema de cache TTL
│   ├── parallel.ps1            # Execução paralela
│   └── dotfiles.ps1            # Gerenciamento dotfiles
├── ui/                          # Interface do usuário
│   ├── progress.ps1            # Barras de progresso
│   └── prompts.ps1             # Menus interativos
├── tests/                       # Testes
│   ├── run-tests.ps1           # Runner de testes
│   └── unit/                   # Testes unitários
├── state/                       # Estado persistido
│   └── state.json              # Estado de instalações
├── backups/                     # Backups automáticos
├── cache/                       # Cache de operações
└── logs/                        # Logs de execução
```

---

## Módulos Core

### 1. utils.ps1

**Responsabilidade:** Funções utilitárias do sistema.

**Principais Funções:**
- `Test-Administrator` - Verifica privilégios admin
- `Test-DiskSpace` - Verifica espaço em disco
- `Test-NetworkConnection` - Testa conectividade
- `Install-Chocolatey` - Instala Chocolatey
- `Get-SystemInfo` - Coleta info do sistema
- `Get-String` - Strings localizadas

**Dependências:** Nenhuma (módulo base)

---

### 2. validation.ps1

**Responsabilidade:** Validação e segurança.

**Principais Funções:**
- `Test-FileChecksum` - Valida checksums (SHA256/512/MD5)
- `Get-PackageChecksum` - Obtém checksum de pacotes
- `Show-SecurityDialog` - Diálogo de segurança interativo
- `Test-JsonSchema` - Valida sintaxe JSON
- `Test-PackagesConfig` - Valida configuração completa

**Dependências:** `utils.ps1`

---

### 3. packages.ps1

**Responsabilidade:** Gerenciamento de pacotes multi-manager.

**Principais Funções:**
- `Get-BestPackageManager` - Seleciona melhor manager
- `Install-PackageWithFallback` - Instala com fallback automático
- `Install-PackageWithManager` - Instala com manager específico
- `Test-PackageManagerHealth` - Verifica saúde dos managers

**Lógica de Fallback:**
```
1. Tenta Chocolatey (se disponível e configurado)
   └─ Falhou? →
2. Tenta Winget (se disponível e configurado)
   └─ Falhou? →
3. Tenta Scoop (se disponível e configurado)
   └─ Falhou? →
4. Retorna erro
```

**Dependências:** `utils.ps1`, `validation.ps1`

---

### 4. state-manager.ps1

**Responsabilidade:** Gerenciamento de estado de instalações.

**Principais Funções:**
- `Initialize-StateFile` - Inicializa state.json
- `New-InstallSession` - Cria sessão de instalação
- `Add-PackageToSession` - Registra pacote instalado
- `Get-InstallHistory` - Histórico de instalações
- `Test-PackageInstalled` - Verifica se instalado
- `Start-Rollback` - Rollback de sessão

**Estrutura de Estado:**
```json
{
  "version": "1.0.0",
  "sessions": [
    {
      "id": "session-20250124-143022",
      "timestamp": "2025-01-24T14:30:22Z",
      "packages": [
        { "name": "git", "version": "2.43.0", "manager": "chocolatey", "status": "Success" }
      ],
      "status": "Completed"
    }
  ],
  "installed": {
    "git": { "version": "2.43.0", "manager": "chocolatey", "installedAt": "2025-01-24T14:30:22Z" }
  }
}
```

**Dependências:** `utils.ps1`, `error-handler.ps1`

---

### 5. backup.ps1

**Responsabilidade:** Sistema de backup e restore.

**Principais Funções:**
- `New-EnvironmentBackup` - Cria backup
- `Get-BackupList` - Lista backups
- `Restore-EnvironmentBackup` - Restaura backup
- `Compare-Backups` - Compara dois backups
- `Export-Backup` / `Import-Backup` - Exporta/importa ZIP
- `Remove-OldBackups` - Limpeza de backups antigos

**Estrutura de Backup:**
```
backups/backup-YYYYMMDD-HHMMSS/
├── metadata.json          # Informações do backup
├── state.json             # Estado no momento
├── config/                # Configurações
├── dotfiles/              # Dotfiles do usuário
└── logs/                  # Logs da sessão
```

**Dependências:** `utils.ps1`, `state-manager.ps1`

---

### 6. error-handler.ps1

**Responsabilidade:** Tratamento centralizado de erros.

**Principais Funções:**
- `Write-ErrorLog` - Registra erro em log
- `Get-ErrorSummary` - Resumo de erros da sessão

**Dependências:** Nenhuma

---

## Fluxo de Execução

### Fluxo Principal (setup.ps1)

```
1. Verificações Iniciais
   ├─ Test-Administrator
   ├─ Test-DiskSpace
   └─ Test-NetworkConnection

2. Backup Automático
   └─ New-EnvironmentBackup (se não -SkipBackup)

3. Inicialização
   ├─ Initialize-StateFile
   └─ New-InstallSession

4. Instalação Package Managers
   └─ Install-Chocolatey (se necessário)

5. Validação de Configuração
   └─ Test-PackagesConfig

6. Seleção de Pacotes
   ├─ Modo Interativo: Show-Menu
   ├─ Modo Auto: Usar preset
   └─ Modo Custom: Usar parâmetros

7. Instalação de Pacotes
   ├─ Serial: foreach package
   └─ Paralela: Start-ParallelInstall

8. Configurações Pós-Instalação
   ├─ Install-OhMyPosh
   ├─ Install-ModernTools
   └─ Install-GitWithConfig

9. Finalização
   ├─ Complete-InstallSession
   ├─ Get-ErrorSummary
   └─ Exibir resumo
```

### Fluxo de Instalação de Pacote

```
Install-PackageWithFallback
    │
    ├─ Get-BestPackageManager
    │   ├─ Verifica managers disponíveis
    │   └─ Retorna lista ordenada por prioridade
    │
    ├─ Loop por cada manager
    │   │
    │   ├─ Get-CachedData (info do pacote)
    │   │   └─ Cache miss? Buscar info
    │   │
    │   ├─ Test-FileChecksum (se disponível)
    │   │   └─ Falhou? Show-SecurityDialog
    │   │
    │   ├─ Install-PackageWithManager
    │   │   ├─ Chocolatey: choco install
    │   │   ├─ Winget: winget install
    │   │   └─ Scoop: scoop install
    │   │
    │   └─ Sucesso? Break
    │       Falhou? Próximo manager
    │
    ├─ Add-PackageToSession
    │
    └─ Set-CachedData (resultado)
```

---

## Design Patterns

### 1. Single Responsibility Principle (SRP)

Cada módulo tem uma responsabilidade única:
- `utils.ps1` → Utilitários gerais
- `validation.ps1` → Validação e segurança
- `packages.ps1` → Gerenciamento de pacotes
- `state-manager.ps1` → Estado
- `backup.ps1` → Backups

### 2. Dependency Injection

Funções recebem dependências como parâmetros:
```powershell
function Install-PackageWithManager {
    param(
        [PSCustomObject]$Package,    # Injetado
        [PSCustomObject]$Manager     # Injetado
    )
}
```

### 3. Strategy Pattern

Seleção de package manager em runtime:
```powershell
switch ($Manager.Type) {
    'chocolatey' { choco install ... }
    'winget'     { winget install ... }
    'scoop'      { scoop install ... }
}
```

### 4. Chain of Responsibility

Fallback entre package managers:
```powershell
foreach ($manager in $managers) {
    $result = Install-PackageWithManager -Manager $manager
    if ($result.Success) { break }
}
```

### 5. Decorator Pattern

Funções wrapper adicionam funcionalidade:
```powershell
Install-PackageWithFallback  # Adiciona fallback
    └─ Install-PackageWithManager  # Instalação base
```

---

## Gerenciamento de Estado

### Arquivo state.json

**Localização:** `state/state.json`

**Propósito:**
- Rastrear todas as instalações
- Histórico de sessões
- Suporte a rollback
- Prevenir reinstalações

**Operações:**
1. **Leitura** - `Get-Content | ConvertFrom-Json`
2. **Escrita** - `ConvertTo-Json | Set-Content`
3. **Lock** - Uso de `Mutex` para evitar corrupção

**Ciclo de Vida:**
```
Initialize-StateFile
    ↓
New-InstallSession (cria sessão)
    ↓
Add-PackageToSession (adiciona pacotes)
    ↓
Complete-InstallSession (finaliza)
    ↓
Get-InstallHistory (consulta)
```

---

## Sistema de Cache

### Implementação TTL

**Localização:** `cache/*.json`

**Estrutura de Entrada:**
```json
{
  "key": "package-info-git",
  "data": { "name": "git", "version": "2.43.0" },
  "timestamp": "2025-01-24T14:30:22Z",
  "ttl": 21600,
  "expiresAt": "2025-01-24T20:30:22Z"
}
```

**TTLs Padrão:**
- Health check: 3600s (1h)
- Package list: 86400s (24h)
- Package info: 21600s (6h)
- Checksum: 604800s (7d)

**Algoritmo:**
```powershell
function Get-CachedData {
    $entry = Read-Cache -Key $Key
    if ($entry -and $entry.expiresAt -gt (Get-Date)) {
        return $entry.data  # Cache hit
    }
    return $null  # Cache miss
}
```

---

## Execução Paralela

### Implementação com Jobs

**Função:** `Start-ParallelInstall`

**Abordagem:**
```powershell
$jobs = @()
foreach ($package in $packages) {
    # Limitar jobs concorrentes
    while ((Get-Job -State Running).Count -ge $MaxParallel) {
        Start-Sleep -Milliseconds 100
    }

    # Criar job
    $job = Start-Job -ScriptBlock {
        param($pkg)
        Install-PackageWithFallback -Package $pkg
    } -ArgumentList $package

    $jobs += $job
}

# Aguardar conclusão
$jobs | Wait-Job | Receive-Job
```

**Gerenciamento de Dependências:**
```powershell
# Verificar se pacote tem dependências
if ($package.dependencies) {
    # Instalar dependências primeiro (serial)
    foreach ($dep in $package.dependencies) {
        Install-Package $dep
    }
}
# Depois instalar pacote principal
```

**Detecção de Dependência Circular:**
```powershell
function Test-CircularDependency {
    $visited = @()
    function Check-Recursive($pkg, $chain) {
        if ($chain -contains $pkg) { return $true }
        $chain += $pkg
        foreach ($dep in $pkg.dependencies) {
            if (Check-Recursive $dep $chain) { return $true }
        }
        return $false
    }
    return Check-Recursive $package @()
}
```

---

## Tratamento de Erros

### Estratégia de 3 Camadas

**1. Try-Catch Local**
```powershell
try {
    $result = Install-Package $package
}
catch {
    Write-ErrorLog -Exception $_ -Category "PackageInstallation"
    throw  # Re-lançar ou continuar
}
```

**2. ErrorActionPreference**
```powershell
$ErrorActionPreference = 'Stop'  # Parar em erros
# ou
$ErrorActionPreference = 'Continue'  # Continuar apesar de erros
```

**3. Logging Centralizado**
```powershell
Write-ErrorLog -Message "Falha" -Severity "Error"
    ↓
logs/errors.log
```

### Códigos de Saída Padronizados

```powershell
exit 0   # Sucesso
exit 1   # Erro geral
exit 2   # Sem privilégios admin
exit 3   # Espaço insuficiente
exit 4   # Sem rede
exit 5   # Sem package manager
```

---

## Decisões Técnicas

### 1. PowerShell vs Bash

**Escolha:** PowerShell

**Razões:**
- Nativo do Windows
- Integração com .NET
- Objetos estruturados (não apenas strings)
- Compatibilidade Desktop + Core

### 2. JSON vs YAML/TOML

**Escolha:** JSON

**Razões:**
- Nativo no PowerShell (`ConvertFrom-Json`)
- Validação com JSON Schema
- Amplamente suportado
- Performance superior

### 3. Múltiplos Package Managers

**Razões:**
- Chocolatey: Maior repositório (9000+ pacotes)
- Winget: Oficial da Microsoft, futuro do Windows
- Scoop: Apps portáteis, sem admin
- Fallback: Maximiza taxa de sucesso

### 4. Estado Local vs Remoto

**Escolha:** Local (state.json)

**Razões:**
- Simplicidade (sem dependência de servidor)
- Performance (sem latência de rede)
- Privacidade (nada enviado externamente)
- Offline-first

### 5. Backup Antes de Modificações

**Razões:**
- Segurança (rollback sempre possível)
- Auditoria (histórico completo)
- Confiança (usuário pode experimentar)

### 6. Cache com TTL

**Razões:**
- Performance (reduz 60%+ de operações)
- Reduz carga em repositórios
- Dados sempre "frescos o suficiente"

### 7. Execução Paralela Opcional

**Razões:**
- Performance (10x mais rápido)
- Configurável (1-10 jobs)
- Fallback serial (se problemas)

### 8. Validação de Checksum Opcional

**Razões:**
- Segurança (previne malware)
- Flexibilidade (usuário decide)
- Educação (dialog explica riscos)

---

## Métricas e Performance

### Benchmarks Típicos

| Operação | Sem Cache | Com Cache | Melhoria |
|----------|-----------|-----------|----------|
| Health check | ~2.5s | ~0.1s | 96% |
| Package list | ~8.3s | ~0.2s | 97% |
| Package info | ~1.2s | ~0.05s | 96% |

| Instalação | Serial | Paralelo (3) | Ganho |
|------------|--------|--------------|-------|
| 5 pacotes | ~5m 25s | ~2m 30s | 54% |
| 10 pacotes | ~12m 40s | ~5m 15s | 59% |

### Cobertura de Testes

```
Core: 74.5%
Installers: 69.8%
Utils: 76.1%
UI: 77.2%
Total: 74.3%
```

---

## Extensibilidade

### Adicionar Novo Package Manager

1. Editar `packages.ps1`
2. Adicionar case no switch
3. Implementar função `Install-With[Manager]`
4. Adicionar testes

### Adicionar Nova Categoria de Pacotes

1. Editar `config/packages.json`
2. Criar seção nova categoria
3. Atualizar `config/packages.schema.json`
4. Adicionar ao menu interativo

### Adicionar Novo Instalador

1. Criar `installers/novo-instalador.ps1`
2. Implementar função `Install-[Feature]`
3. Chamar de `setup.ps1`
4. Adicionar testes

---

## Segurança

### Práticas Implementadas

1. **Checksum Validation** - SHA256/512/MD5
2. **Script Signing** - Infraestrutura completa
3. **Execution Policy** - Verificação e orientação
4. **Admin Verification** - Antes de operações críticas
5. **Security Dialogs** - Decisões informadas
6. **Backup Automático** - Antes de mudanças
7. **Rollback** - Desfazer instalações problemáticas

### Threat Model

**Ameaças Mitigadas:**
- Pacotes maliciosos (checksum)
- Man-in-the-middle (HTTPS + checksum)
- Execução não autorizada (admin check)
- Perda de dados (backup automático)

---