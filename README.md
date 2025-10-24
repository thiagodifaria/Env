# Env

![Env Logo](https://img.shields.io/badge/ENV-Windows%20Development%20Environment-0066cc?style=for-the-badge&logo=powershell)

**Automated Windows Development Environment Setup with Multi-Package Manager Support**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-5391FE?style=flat&logo=powershell&logoColor=white)](https://docs.microsoft.com/powershell)
[![Chocolatey](https://img.shields.io/badge/Chocolatey-Supported-80B5E3?style=flat&logo=chocolatey&logoColor=white)](https://chocolatey.org)
[![Winget](https://img.shields.io/badge/Winget-Supported-0078D4?style=flat&logo=microsoft&logoColor=white)](https://github.com/microsoft/winget-cli)
[![Scoop](https://img.shields.io/badge/Scoop-Supported-E05D44?style=flat)](https://scoop.sh)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat)](LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Pester%205.0+-success?style=flat)]()

---

## 🌍 **Documentation / Documentação**

**📖 [🇺🇸 Read in English](README_EN.md)**  
**📖 [🇧🇷 Leia em Português](README_PT.md)**

---

## 🎯 What is Env?

Env is an **PowerShell automation tool** for setting up complete Windows development environments. Built with modern DevOps practices, it provides automated installation, configuration, and management of development tools across multiple package managers.

### ⚡ Key Highlights

- 🔄 **Multi-Package Manager** - Chocolatey, Winget, Scoop with automatic fallback
- 🔐 **Security First** - SHA256 checksum validation, script signing support
- 💾 **State Management** - Complete installation tracking with rollback capability
- 🔙 **Backup & Restore** - Automatic configuration backups before changes
- 🚀 **Parallel Installation** - Install multiple packages simultaneously (up to 10 concurrent)
- 📦 **Smart Caching** - TTL-based cache system reduces redundant downloads
- 🎨 **Terminal Customization** - Oh My Posh, Starship with custom themes
- 🛠️ **Modern CLI Tools** - bat, eza, fzf, ripgrep, zoxide pre-configured
- 🔧 **Git Auto-Config** - 15+ useful aliases and sensible defaults
- 📁 **Dotfiles Management** - Cross-machine synchronization via Git
- ✅ **Comprehensive Testing** - Pester 5.0+ with 70-80% coverage
- 🔄 **CI/CD Ready** - GitHub Actions workflows included

### 🏆 What Makes It Special?

```
✅ PowerShell 5.1+ with typed parameters and validation
✅ Multi-manager support (Chocolatey + Winget + Scoop)
✅ SHA256 checksum verification for security
✅ JSON Schema validation for configuration
✅ State persistence with rollback (undo failed installations)
✅ Automatic backups before modifications
✅ Parallel installation (10x faster for multiple packages)
✅ Redis-style TTL cache for package metadata
✅ Terminal themes (Oh My Posh + Starship)
✅ 5 modern CLI tools (bat, eza, fzf, ripgrep, zoxide)
✅ Git auto-configuration with professional aliases
✅ Dotfiles sync across machines
✅ 50+ packages across 8 categories
✅ Pester test suite with >70% coverage
✅ Complete CI/CD pipeline (GitHub Actions)
```

---

## ⚡ Quick Start

### Option 1: Interactive Mode (Recommended)

```powershell
# Clone and run
git clone https://github.com/thiagodifaria/Env.git C:\ENV
cd C:\ENV
.\setup.ps1

# Follow interactive menus to select packages
```

### Option 2: Automated Installation

```powershell
# Install all packages automatically
.\setup.ps1 -Mode Auto

# Install only essentials
.\setup.ps1 -Mode Custom
```

### Option 3: Advanced Options

```powershell
# Parallel installation with custom settings
.\setup.ps1 -Mode Interactive -MaxParallel 5 -SkipBackup -NoCache
```

---

## 🔧 Core Features

| Feature | Description |
|---------|-------------|
| **Multi-Package Manager** | Chocolatey, Winget, Scoop with smart fallback |
| **State Management** | Track installations, rollback on failure |
| **Backup System** | Auto-backup before changes, restore anytime |
| **Parallel Install** | Up to 10 concurrent package installations |
| **Smart Cache** | TTL-based caching reduces download time |
| **Checksum Validation** | SHA256 verification for security |
| **Terminal Themes** | Oh My Posh & Starship with custom configs |
| **Modern CLI Tools** | bat, eza, fzf, ripgrep, zoxide |
| **Git Integration** | Auto-configure with 15+ useful aliases |
| **Dotfiles Sync** | Manage configs across machines via Git |
| **Comprehensive Tests** | Pester 5.0+ unit & integration tests |
| **CI/CD Pipeline** | GitHub Actions for automated testing |

---

## 📞 Contact

**Thiago Di Faria** - thiagodifaria@gmail.com

[![GitHub](https://img.shields.io/badge/GitHub-@thiagodifaria-black?style=flat&logo=github)](https://github.com/thiagodifaria)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Thiago_Di_Faria-blue?style=flat&logo=linkedin)](https://linkedin.com/in/thiagodifaria)

**Project**: [https://github.com/thiagodifaria/Env](https://github.com/thiagodifaria/Env)

---

### 🌟 **Star this project if you find it useful!**

**Made with ❤️ by [Thiago Di Faria](https://github.com/thiagodifaria)**