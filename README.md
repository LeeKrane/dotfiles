# Krane's Dotfiles

> **Note:** This README might be outdated, as I don't keep it up to date all the time.

## Overview

This repository contains my personal dotfiles and system configuration files. It's designed to work with both Fedora (DNF) and Arch-based (Pacman) systems, with a focus on developer productivity and system customization.

## Key Components

### Shell Configuration
- **ZSH** with Oh-My-ZSH and Powerlevel10k theme
- Custom aliases for improved workflow
- Integration with modern CLI tools

### Terminal
- **Alacritty** as the primary terminal emulator
- JetBrains Mono Nerd Font for proper icon rendering

### Development Environment
- **Neovim** (LazyVim) with language support for:
  - Docker, Java, JSON, Markdown, Python, Rust
  - Tailwind, LaTeX, TypeScript, YAML
- Git configuration with delta for improved diffs
- Docker and container tools

### System Management
- **Rebos** - System configuration management tool
- Stow for dotfile management
- System initialization scripts

### CLI Tools
- Modern replacements for standard tools:
  - `exa` instead of `ls`
  - `bat` instead of `cat`
  - `zoxide` instead of `cd`
  - `btop` instead of `top`/`htop`
  - `ripgrep` for searching
  - `fzf` for fuzzy finding

## Installation

### Prerequisites
- Git
- Stow

### Basic Setup
1. Clone this repository to your home directory:
   ```bash
   git clone https://gitlab.com/LeeKrane/dotfiles.git ~/.dotfiles
   ```

2. Run the system initialization script:
   ```bash
   cd ~/.dotfiles
   ./sys-init.sh
   ```

## Structure

- `.config/` - Application configurations
- `.krane-rc/` - Custom shell configurations and aliases
- `.init/` - System initialization scripts
- `.config/rebos/` - Rebos package management configuration

## Rebos System Management

Rebos is a tool that aims to provide system repeatability (similar to NixOS) for any Linux distribution. It uses a generation system to track and manage:

- System packages
- Flatpak applications
- Cargo crates
- Pip packages
- NPM packages

### Key Features
- Calculates diffs between generations to add/remove packages
- Works on any Linux distro through configurable managers
- Enables syncing system configurations across multiple machines
- Provides an elegant way to reinstall your entire system setup with a few commands

Rebos configuration files are located in `.config/rebos/`. For more information, visit the [Rebos project page](https://gitlab.com/Oglo12/rebos).