# Próximos Passos - Infraestrutura VPS

## 🎯 **Situação Atual**

- ✅ Código da infraestrutura existe nos diretórios
- ❌ VPS não estão criadas (GitLab e Nginx)
- ❌ Serviços de monitoramento não instalados
- ❌ Sistema de backup não configurado

## 🚀 **Opções de Implantação**

### **Opção 1: Implantação Automática Completa (Recomendado)**

```bash
# Implantar toda a infraestrutura automaticamente
sudo ./core/shared/scripts/infrastructure-mgmt.sh deploy
```

**O que isso faz:**

- 🏗️ Cria as duas VPS (GitLab + Nginx)
- ⚙️ Configura toda a rede privada
- 🔐 Aplica hardening de segurança
- 📊 Instala monitoramento (Netdata, Prometheus)
- 💾 Configura sistema de backup
- ⏱️ **Tempo estimado:** 20-30 minutos

### **Opção 2: Implantação Manual por Etapas**

#### **Etapa 1: GitLab VPS**

```bash
cd core/gitlab-vps
vagrant up --provider=libvirt
```

#### **Etapa 2: Nginx App VPS**

```bash
cd ../nginx-app-vps
vagrant up --provider=libvirt
```

#### **Etapa 3: Configurações Compartilhadas**

```bash
cd ../shared
sudo ./scripts/security-hardening.sh
sudo ./scripts/monitoring-setup.sh
sudo ./scripts/backup-management.sh --verify
```

## 🔍 **Verificações Importantes Antes de Começar**

### **1. Recursos do Sistema**

```bash
# Verificar memória (mínimo 16GB)
free -h

# Verificar espaço em disco (mínimo 200GB)
df -h

# Verificar suporte à virtualização
sudo virt-host-validate
```

### **2. Dependências**

```bash
# Verificar se o Vagrant está instalado
vagrant --version

# Verificar se o Libvirt está funcionando
virsh list --all

# Verificar se o Docker está instalado
docker --version
```

## 📊 **Durante a Implantação**

### **Monitorar Progresso:**

```bash
# Em outro terminal, monitorar logs
tail -f /var/log/vagrant-provisioning.log

# Verificar status das VMs
watch 'virsh list --all'

# Monitorar uso de recursos
htop
```

### **Verificar Conectividade:**

```bash
# Quando as VPS estiverem rodando
ping 10.0.0.10  # GitLab VPS
ping 10.0.0.20  # Nginx VPS
```

## 🎯 **Após a Implantação**

### **Acessos Disponíveis:**

- **GitLab Web:** <https://136.243.208.130>
- **Aplicação Nginx:** <https://136.243.208.131>
- **Monitoramento GitLab:** <http://10.0.0.10:19999>
- **Monitoramento Nginx:** <http://10.0.0.20:19999>

### **Comandos de Gestão:**

```bash
# Status geral
sudo ./core/shared/scripts/infrastructure-mgmt.sh status

# Painel de monitoramento
sudo /opt/monitoring-dashboard.sh

# Verificação de saúde
sudo /opt/health-check.sh

# Backup manual
sudo ./core/shared/scripts/backup-management.sh --full

# Testes da infraestrutura
sudo ./core/shared/scripts/infrastructure-tests.sh --all
```

## ⚠️ **Possíveis Problemas e Soluções**

### **Problema: Erro de Virtualização**

```bash
# Solução: Verificar e reiniciar libvirt
sudo systemctl restart libvirtd
sudo virt-host-validate
```

### **Problema: Conflito de Rede**

```bash
# Solução: Limpar redes virtuais existentes
sudo virsh net-list --all
sudo virsh net-destroy default
sudo virsh net-start default
```

### **Problema: Recursos Insuficientes**

```bash
# Solução: Verificar e liberar recursos
sudo systemctl stop docker  # Temporariamente
killall firefox chrome      # Fechar browsers pesados
```

## 📝 **Recomendação**

**Escolha a Opção 1 (Implantação Automática)** se:

- ✅ É sua primeira implantação
- ✅ Quer rapidez e conveniência
- ✅ Confia no processo automatizado

**Escolha a Opção 2 (Manual)** se:

- ✅ Quer controle total do processo
- ✅ Precisa debugar problemas específicos
- ✅ Quer entender cada etapa detalhadamente

---

## 🚀 **Comando Recomendado para Começar:**

```bash
# Vá para o diretório da infraestrutura
cd /opt/xcloud/vps-hosting-infrastructure

# Inicie a implantação completa
sudo ./core/shared/scripts/infrastructure-mgmt.sh deploy
```

**Tempo total estimado:** 20-30 minutos para infraestrutura completa funcionando.
