# VPS Hosting Infrastructure - Ambiente de Produção

🚀 **AMBIENTE DE PRODUÇÃO** - Infraestrutura para hospedagem VPS com gerenciamento completo de máquinas virtuais e clientes.

## 📋 Visão Geral

Este projeto gerencia uma infraestrutura completa de VPS hosting com duas principais divisões:

- **`app/`** - Aplicação de gerenciamento (Node.js/TypeScript + Express)
- **`core/`** - Configurações Vagrant das VMs da infraestrutura

## 🏗️ Arquitetura de Produção

### Infraestrutura Base
- **Sistema Operacional**: Ubuntu 22.04 LTS
- **Virtualização**: Vagrant + Libvirt/QEMU
- **Rede**: Redes privadas para comunicação interna entre VMs

### Topologia de Rede

```
Internet
    │
    ├── 136.243.94.243 (IP Principal)
    │
    ├── GitLab VPS (IP Público)
    │   └── Repositórios + CI/CD
    │
    └── Nginx/App VPS (IP Público) 
        ├── Nginx (Proxy/Load Balancer)
        ├── Aplicação Node.js
        └── Rede Privada ←→ Outras VMs
```

## 🌐 Configuração de IPs

### IP Principal
- **136.243.94.243** - IP IPv4 principal

### Subnet IPv4 (/29)
**Range**: `136.243.208.128/29` (8 IPs total, 6 utilizáveis)

| IP | Uso Planejado | Status |
|---|---|---|
| `136.243.208.128` | Network Address | Reservado |
| `136.243.208.129` | Gateway | Sistema |
| `136.243.208.130` | GitLab VPS | Produção |
| `136.243.208.131` | Nginx/App VPS | Produção |
| `136.243.208.132` | Disponível | Livre |
| `136.243.208.133` | Disponível | Livre |
| `136.243.208.134` | Disponível | Livre |
| `136.243.208.135` | Broadcast Address | Reservado |

### Subnet IPv6
- **Range**: `2a01:48:171:76b::/64`
- Utilização conforme necessidade de expansão

## 🖥️ Máquinas Virtuais

### 1. GitLab VPS
- **IP Público**: `136.243.208.130`
- **OS**: Ubuntu 22.04 LTS
- **Serviços**:
  - GitLab CE/EE
  - GitLab Runner
  - Container Registry
- **Recursos**:
  - RAM: 4GB+
  - Storage: 100GB+
  - CPU: 2+ cores

### 2. Nginx/App VPS  
- **IP Público**: `136.243.208.131`
- **OS**: Ubuntu 22.04 LTS
- **Serviços**:
  - Nginx (Reverse Proxy/Load Balancer)
  - Aplicação Node.js (Express API)
  - Docker/Docker Compose
- **Recursos**:
  - RAM: 2GB+
  - Storage: 50GB+
  - CPU: 2+ cores

## 📁 Estrutura do Projeto

```
vps-hosting-infrastructure/
├── README.md                    # ← Este arquivo
├── app/                         # Aplicação de gerenciamento
│   ├── src/                     # Código-fonte TypeScript
│   │   ├── api/                 # API Express
│   │   ├── controllers/         # Controladores
│   │   ├── routes/              # Rotas da API
│   │   └── types/               # Definições de tipos
│   ├── package.json             # Dependências Node.js
│   ├── tsconfig.json            # Configuração TypeScript
│   ├── Dockerfile               # Container da aplicação
│   └── docker-compose.yml       # Orquestração de serviços
├── core/                        # Configurações Vagrant da infraestrutura
│   └── [VMs da infraestrutura]  # Vagrantfiles das VMs de produção
├── docs/                        # Documentação
│   ├── app/                     # Docs da aplicação
│   └── core/                    # Docs da infraestrutura
└── clients/                     # Clientes e templates
    ├── client-001/              # Cliente exemplo
    ├── client-002/              # Cliente exemplo
    └── templates/               # Templates de VM
```

## 🚀 Quick Start

### Pré-requisitos
- Ubuntu 22.04 LTS
- Vagrant 2.4+ (✅ v2.4.9 instalado)
- Libvirt + QEMU (✅ v10.0.0 configurado)
- Node.js 18+
- Docker & Docker Compose

### Configuração Atual do Sistema
Seu servidor já possui uma configuração avançada do Vagrant em `/opt/k8s/` com:

- **VMs Ativas**: `k8s_prod-w1`, `k8s_prod-cp1` (rodando)
- **Provider**: Libvirt (não KVM direto)
- **Redes**: Configuradas com `xcloud-internal` e `xcloud-private`
- **12 Nós**: Gateway, Load Balancer, API Gateway, Masters, Workers

### Instalação
```bash
# Clone o repositório
git clone <repository-url>
cd vps-hosting-infrastructure

# Instalar dependências da aplicação
cd app
npm install

# Configurar variáveis de ambiente
cp .env.example .env

# Subir a aplicação em modo de desenvolvimento
npm run dev

# OU em produção com Docker
docker-compose up -d
```

### Deploy da Infraestrutura
```bash
# Verificar VMs existentes (baseado na configuração em /opt/k8s/)
cd /opt/k8s
vagrant status

# Verificar VMs ativas no libvirt
virsh list --all

# Para o projeto VPS Hosting, configurar novas VMs
cd /opt/xcloud/vps-hosting-infrastructure/core/

# Deploy GitLab VPS
cd gitlab-vps/
vagrant up

# Deploy Nginx/App VPS  
cd ../nginx-app-vps/
vagrant up
```

## 🔧 Configuração

### Rede Privada
- **Range**: `10.0.0.0/24`
- **GitLab VPS**: `10.0.0.10`
- **Nginx/App VPS**: `10.0.0.20`
- **Outras VMs**: `10.0.0.30+`

### Portas e Serviços
- **22**: SSH (todas as VMs)
- **80/443**: HTTP/HTTPS (Nginx VPS)
- **3000**: API Node.js (App VPS)
- **8080**: GitLab Web (GitLab VPS)

## 📊 Monitoramento

- **Logs**: Centralizados via rsyslog
- **Métricas**: Prometheus + Grafana (planejado)
- **Alertas**: Via Discord/Slack (planejado)

## 🔒 Segurança

- Firewall UFW configurado
- SSH com chaves públicas apenas
- Fail2ban ativo
- Updates automáticos configurados
- Backup diário automatizado

## 🛠️ Manutenção

### Backup
```bash
# Backup manual
cd app/src/scripts
./backup.sh

# Backup automático via cron
# Configurado para execução diária às 2h
```

### Monitoramento de Recursos
```bash
# Verificar status das VMs do projeto
vagrant status

# Verificar VMs ativas no libvirt/KVM
virsh list --all

# Status global do Vagrant
vagrant global-status

# Logs da aplicação
docker-compose logs -f app

# Monitorar recursos do sistema
htop
df -h
```

## 📞 Suporte

- **Issues**: Use o sistema de issues do GitLab
- **Documentação**: Consulte a pasta `docs/`
- **Emergência**: Contate a equipe de DevOps

## 📝 Changelog

### v1.0.0 (2025-09-16)
- Configuração inicial da infraestrutura de produção
- Deploy das VMs GitLab e Nginx/App
- Configuração de rede e IPs públicos
- Aplicação de gerenciamento funcional

---

**⚠️ IMPORTANTE**: Este é um ambiente de **PRODUÇÃO**. Todas as mudanças devem ser testadas em ambiente de desenvolvimento antes do deploy.