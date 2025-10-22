# Env - Documentação Técnica

## Visão Geral

Script PowerShell modular para automação de instalação de ambientes de desenvolvimento Windows.

## Requisitos

- Windows 10/11
- PowerShell 5.1+
- Privilégios de Administrador
- 30GB+ espaço em disco
- Conexão com internet

## Arquitetura

### Módulos Core

**utils.ps1**: Funções utilitárias básicas
- Verificação de admin, disco, rede
- Instalação do Chocolatey
- Informações do sistema

**logger.ps1**: Sistema de logging
- Log em arquivo e console colorido
- Rotação automática (mantém 5 logs)
- Níveis: INFO, SUCCESS, WARNING, ERROR, DEBUG

**state.ps1**: Gerenciamento de estado
- Persiste packages instalados em JSON
- Sincroniza estado com sistema real
- Permite retomar instalações

**validator.ps1**: Validação e detecção
- Detecta packages via 3 métodos: choco, comando, registry
- Identifica conflitos (MS Store vs Choco)
- Gera relatórios pré-instalação

**ui.ps1**: Interface visual
- Menus interativos
- Progress bars (global, categoria, package)
- Símbolos coloridos: ✓ ✗ ⟲ ➜ ⚠
- Spinner animado

### Installers

Cada installer segue padrão:
1. Valida se package já existe
2. Tenta instalar com retry 3x
3. Delay progressivo entre retries (5s, 10s)
4. Registra no estado se sucesso
5. Retorna: Success, Failed, Skipped

**Ordem de instalação:**
Languages → DevTools → WebTools → DBTools → Observability → Personal → WSL → NPM

### Configuração

**packages.json**: Define todos os packages
- Estrutura: {category: [{id, name, choco_package, version, command}]}
- 8 categorias, 50+ packages

**presets.json**: Define presets
- DiFaria: completo
- Developer: sem personal
- Minimal: essencial

**strings.json**: Internacionalização
- Suporta: pt-br, en
- Todas as mensagens do sistema

## Fluxo de Execução

1. Validação de ambiente (admin, disco, rede, chocolatey)
2. Exibição de informações do sistema
3. Sincronização de estado
4. Seleção de modo (menu ou CLI)
5. Validação de packages (detecta instalados, conflitos)
6. Resolução de conflitos (se houver)
7. Confirmação do usuário
8. Instalação por categoria com progress tracking
9. Relatório final
10. Retry opcional para falhados
11. Salvamento de estado

## Tratamento de Erros

- Continue-on-error: falha de 1 package não para tudo
- Retry 3x por package com delays
- Logs detalhados de cada erro
- Estado parcial salvo se Ctrl+C
- Retry final para todos os falhados

## Logs e Estado

**Logs**: `logs/install_YYYY-MM-DD_HHmmss.log`
- Rotação automática
- Incluem timestamps, níveis, detalhes

**Estado**: `state/env.state.json`
- version, last_run, installed_packages
- Sincronizado com sistema real

## Flags CLI
-preset <name>         : DiFaria, Developer, Personal, Minimal
-language <lang>       : pt-br, en (default: pt-br)
-silent               : Sem confirmações
-skipValidation       : Pula validações (não recomendado)
-categories <list>    : Lista separada por vírgula (1,2,5)

## Extensibilidade

Para adicionar packages:
1. Editar `config/packages.json`
2. Adicionar na categoria apropriada
3. Definir: id, name, choco_package, version, command

Para adicionar categorias:
1. Criar installer em `installers/`
2. Seguir padrão dos existentes
3. Adicionar no switch de `env.ps1`
4. Atualizar `packages.json` e menus