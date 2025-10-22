# Guia de Uso

## Instalação

1. Clone o repositório
2. Abra PowerShell como Administrador
3. Navegue até a pasta do projeto
4. Execute: `.\env.ps1`

## Modo Interativo

Execute sem parâmetros:
```powershell
.\env.ps1
```

Menu com 5 opções:
1. Instalação Completa (DiFaria) - Tudo
2. Ambiente de Desenvolvimento - Sem apps pessoais
3. Aplicativos Pessoais - Apenas personal
4. Instalação Customizada - Escolha categorias
5. Sair

## Modo CLI

### Usando Presets
```powershell
# Preset completo
.\env.ps1 -preset DiFaria

# Preset developer
.\env.ps1 -preset Developer

# Preset minimal
.\env.ps1 -preset Minimal

# Preset personal
.\env.ps1 -preset Personal
```

### Modo Silencioso
```powershell
.\env.ps1 -preset Developer -silent
```

### Idioma
```powershell
.\env.ps1 -language en
```

### Categorias Específicas
```powershell
# Apenas languages e devtools
.\env.ps1 -categories 1,2

# Apenas npm e personal
.\env.ps1 -categories 6,8
```

Mapeamento de números:
- 1 = Languages
- 2 = DevTools
- 3 = WebTools
- 4 = DBTools
- 5 = Observability
- 6 = Personal
- 7 = WSL
- 8 = NPM

### Combinações
```powershell
# Developer em inglês, silencioso
.\env.ps1 -preset Developer -language en -silent

# Categorias custom sem validação
.\env.ps1 -categories 1,2,3 -skipValidation

# Tudo junto
.\env.ps1 -preset DiFaria -language en -silent
```

## Modo Custom (Interativo)

1. Escolha opção 4 no menu
2. Digite números das categorias separados por vírgula
3. Exemplo: `1,2,5` (Languages, DevTools, Observability)
4. Confirme a instalação

## Retry de Pacotes Falhados

Ao final, se houver falhas:
- Sistema pergunta se quer retry
- Tenta reinstalar apenas os falhados
- Usa flag `--force` do chocolatey

## Interrupção (Ctrl+C)

- Estado parcial é salvo
- Pode executar novamente
- Pula packages já instalados

## Verificação de Estado

Estado salvo em: `state/env.state.json`

Para forçar reinstalação, delete o arquivo de estado.

## Logs

Logs salvos em: `logs/install_YYYY-MM-DD_HHmmss.log`

Rotação automática mantém 5 logs mais recentes.

## WSL

Se WSL for instalado:
- Sistema avisa que precisa reiniciar
- Após reiniciar, execute `wsl` pela primeira vez
- Configure usuário e senha do Ubuntu

## Troubleshooting

**Script não executa:**
```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Chocolatey falha:**
- Verifique internet
- Instale manualmente: https://chocolatey.org/install

**Package sempre falha:**
- Verifique logs em `logs/`
- Package pode estar descontinuado
- Tente instalar manualmente: `choco install package`

**Estado dessincronizado:**
- Delete `state/env.state.json`
- Execute novamente

**Conflito não resolvido:**
- Desinstale versão conflitante manualmente
- Execute script novamente