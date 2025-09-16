# 🚀 VS Code Tasks - VPS Hosting Infrastructure

Este arquivo configura tarefas úteis para desenvolvimento e gestão dos VPS.

## 📋 Tarefas Disponíveis

### 🛠️ **Setup e Configuração**
- **🚀 Setup Environment**: Preparar ambiente Ubuntu com Vagrant+KVM
- **🔧 Install Git Hooks**: Instalar hooks de validação automática

### 🏗️ **Gestão de VPS**
- **🏗️ Start GitLab VPS**: Iniciar VPS do GitLab
- **🌐 Start Nginx App VPS**: Iniciar VPS do Nginx App  
- **🛑 Stop All VPS**: Parar todos os VPS
- **🔄 Restart VPS**: Reiniciar todos os VPS
- **🧹 Clean VPS**: Destruir todos os VPS ⚠️

### 📊 **Monitoramento**
- **📊 VPS Status**: Verificar status de todos os VPS
- **🔍 Validate Project**: Validar estrutura do projeto
- **📝 Show Logs**: Mostrar logs do setup

### 💻 **Desenvolvimento**
- **🌊 App Dev Server**: Servidor de desenvolvimento da aplicação
- **🔨 Build App**: Compilar aplicação TypeScript

## 🎯 Como Usar

1. **Pressione `Ctrl+Shift+P`** (ou `Cmd+Shift+P` no Mac)
2. **Digite `Tasks: Run Task`**
3. **Selecione a tarefa desejada**

Ou use o atalho:
- **`Ctrl+Shift+P` → `Tasks: Run Task`**

## 🔥 Fluxo Recomendado

### Primeira vez:
1. `🚀 Setup Environment`
2. `🔧 Install Git Hooks`
3. `🏗️ Start GitLab VPS` ou `🌐 Start Nginx App VPS`

### Desenvolvimento:
1. `📊 VPS Status` (verificar estado)
2. `🌊 App Dev Server` (se trabalhando na app)
3. `🔍 Validate Project` (antes de commit)

### Troubleshooting:
1. `📝 Show Logs` (verificar problemas)
2. `🔄 Restart VPS` (se necessário)
3. `🧹 Clean VPS` (último recurso)

## ⚡ Atalhos Úteis

- **`Ctrl+`` `` `**: Abrir terminal integrado
- **`Ctrl+Shift+`` `` `**: Novo terminal
- **`Ctrl+Shift+P`**: Command Palette

## 🛡️ Dicas de Segurança

- ⚠️ **Clean VPS** destrói todas as máquinas virtuais
- 💾 Sempre faça backup antes de destruir VPS
- 🔍 Use **Validate Project** antes de commits importantes

---
*Configurado para facilitar o desenvolvimento da infraestrutura VPS* 🎉