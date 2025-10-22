# Env - Windows Development Environment Setup

Script PowerShell para automação de instalação de ambientes de desenvolvimento no Windows.

## Features

- 50+ packages automatizados via Chocolatey
- Interface CLI profissional com menus interativos
- Detecção inteligente (não reinstala existentes)
- Persistência de estado entre execuções
- Bilíngue (PT-BR/EN)
- Suporte a flags CLI e modo silencioso
- Sistema de retry para falhas
- Relatórios detalhados

## Quick Start
```powershell
# Clone o repositório
git clone https://github.com/seu-usuario/env.git
cd env

# Execute como administrador
.\env.ps1
```

## Instalação

### Modo Interativo
```powershell
.\env.ps1
```

### Modo CLI
```powershell
# Preset completo
.\env.ps1 -preset DiFaria

# Developer environment
.\env.ps1 -preset Developer -silent

# Categorias específicas
.\env.ps1 -categories 1,2,5

# Em inglês
.\env.ps1 -language en
```

## Presets

- **DiFaria**: Instalação completa (tudo)
- **Developer**: Ambiente de desenvolvimento (sem apps pessoais)
- **Personal**: Apenas aplicativos pessoais
- **Minimal**: Essencial (git, vscode, node, python)
- **Custom**: Selecione categorias

## Categorias

1. Languages (19 packages)
2. DevTools (8 packages)
3. WebTools (3 packages)
4. DBTools (4 packages)
5. Observability (2 packages)
6. Personal (4 packages)
7. WSL (Ubuntu)
8. NPM Global (3 packages)

## Requisitos

- Windows 10/11
- PowerShell 5.1+
- Privilégios de Administrador
- 30GB+ espaço em disco
- Conexão internet

## Estrutura
```
Env/
├── config/          # Configurações (packages, presets, strings)
├── core/            # Módulos principais (ui, logger, validator, etc)
├── installers/      # Instaladores por categoria
├── docs/            # Documentação
├── logs/            # Logs de instalação
├── state/           # Estado persistente
└── env.ps1          # Entry point
```

## Documentação

- [Documentação Técnica](docs/README.md)
- [Guia de Uso](docs/USAGE.md)
- [Lista de Packages](docs/PACKAGES.md)

## Licença

MIT License - veja [LICENSE](LICENSE)

## Autor

@DiFaria

## Versão

1.0.0