#!/usr/bin/env bash
# setup.sh - Preparação do ambiente para VPS Hosting Infrastructure
# Requisito: Ubuntu 22.04 LTS ou 24.04 LTS
# Instala e configura Vagrant + KVM/QEMU + libvirt para virtualização

set -euo pipefail

# Cores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Variáveis
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="/tmp/vps-setup-$(date +%Y%m%d-%H%M%S).log"
readonly MIN_RAM_GB=8
readonly MIN_DISK_GB=100

# Funções de utilidade
log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

error() {
    log "${RED}❌ ERRO: $1${NC}"
    exit 1
}

warning() {
    log "${YELLOW}⚠️  AVISO: $1${NC}"
}

success() {
    log "${GREEN}✅ $1${NC}"
}

info() {
    log "${BLUE}ℹ️  $1${NC}"
}

# Verificar se é Ubuntu 22.04 ou 24.04
check_ubuntu_version() {
    info "Verificando versão do Ubuntu..."
    
    if [[ ! -f /etc/os-release ]]; then
        error "Arquivo /etc/os-release não encontrado"
    fi
    
    source /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        error "Este script requer Ubuntu. Sistema detectado: $ID"
    fi
    
    if [[ "$VERSION_ID" != "22.04" && "$VERSION_ID" != "24.04" ]]; then
        error "Este script requer Ubuntu 22.04 ou 24.04. Versão detectada: $VERSION_ID"
    fi
    
    success "Ubuntu $VERSION_ID LTS detectado"
}

# Verificar recursos do sistema
check_system_requirements() {
    info "Verificando recursos do sistema..."
    
    # Verificar RAM
    local ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $ram_gb -lt $MIN_RAM_GB ]]; then
        warning "RAM disponível: ${ram_gb}GB. Recomendado: ${MIN_RAM_GB}GB+"
    else
        success "RAM suficiente: ${ram_gb}GB"
    fi
    
    # Verificar espaço em disco
    local disk_gb=$(df -BG / | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $disk_gb -lt $MIN_DISK_GB ]]; then
        warning "Espaço livre: ${disk_gb}GB. Recomendado: ${MIN_DISK_GB}GB+"
    else
        success "Espaço em disco suficiente: ${disk_gb}GB"
    fi
    
    # Verificar virtualização
    if ! grep -q -E '(vmx|svm)' /proc/cpuinfo; then
        error "CPU não suporta virtualização (Intel VT-x ou AMD-V)"
    fi
    success "Suporte à virtualização detectado"
    
    # Verificar se KVM está disponível
    if [[ ! -e /dev/kvm ]]; then
        warning "/dev/kvm não encontrado. Será configurado durante a instalação"
    else
        success "Módulo KVM disponível"
    fi
}

# Verificar se é executado como root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "Este script deve ser executado como root (sudo ./setup.sh)"
    fi
    success "Executando com privilégios administrativos"
}

# Atualizar sistema
update_system() {
    info "Atualizando sistema..."
    
    export DEBIAN_FRONTEND=noninteractive
    
    apt-get update -y >> "$LOG_FILE" 2>&1
    apt-get upgrade -y >> "$LOG_FILE" 2>&1
    apt-get autoremove -y >> "$LOG_FILE" 2>&1
    apt-get autoclean >> "$LOG_FILE" 2>&1
    
    success "Sistema atualizado"
}

# Instalar dependências básicas
install_basic_packages() {
    info "Instalando pacotes básicos..."
    
    local packages=(
        "curl"
        "wget"
        "git"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "gnupg"
        "lsb-release"
        "build-essential"
        "dkms"
        "linux-headers-$(uname -r)"
        "cpu-checker"
        "bridge-utils"
        "virt-manager"
        "qemu-system"
        "libvirt-daemon-system"
        "libvirt-clients"
        "virtinst"
        "virt-viewer"
        "genisoimage"
        "rsync"
        "unzip"
    )
    
    apt-get install -y "${packages[@]}" >> "$LOG_FILE" 2>&1
    
    success "Pacotes básicos instalados"
}

# Verificar KVM/QEMU (apenas verificação, não instalação)
check_kvm() {
    info "Verificando KVM/QEMU..."
    
    # Verificar se KVM está disponível
    if [[ ! -e /dev/kvm ]]; then
        warning "KVM não está disponível no sistema"
        # TODO: Implementar instalação e configuração completa do KVM
        # - Instalar pacotes: qemu-kvm, libvirt-daemon-system, libvirt-clients
        # - Carregar módulos: kvm, kvm_intel/kvm_amd
        # - Configurar grupos e permissões
        # - Iniciar serviços libvirtd
        return 1
    fi
    
    # Verificar se libvirt está funcionando
    if systemctl is-active libvirtd > /dev/null 2>&1; then
        success "KVM/libvirt está ativo e funcionando"
    else
        warning "libvirtd não está executando"
        # TODO: Implementar configuração do libvirtd
        # - systemctl enable libvirtd
        # - systemctl start libvirtd
        # - Configurar permissões de usuário
        return 1
    fi
    
    # Verificar se usuário atual está nos grupos corretos
    local current_user="${SUDO_USER:-$USER}"
    if groups "$current_user" | grep -q libvirt; then
        success "Usuário $current_user tem permissões libvirt"
    else
        warning "Usuário $current_user não está no grupo libvirt"
        # TODO: Adicionar usuário aos grupos libvirt e kvm
    fi
    
    success "Verificação KVM concluída"
}

# Verificar portas em uso pelos VPS
check_ports() {
    info "Verificando portas em uso..."
    
    # Portas usadas pelos VPS do projeto (SSH excluído pois sempre estará em uso)
    local vps_ports=(
        "80"     # HTTP - nginx-app-vps
        "443"    # HTTPS - nginx-app-vps, gitlab-vps
        "3000"   # Aplicação Node.js - nginx-app-vps
        "8080"   # GitLab HTTP - gitlab-vps
        "8022"   # GitLab SSH - gitlab-vps
        "5432"   # PostgreSQL - gitlab-vps
        "6379"   # Redis - gitlab-vps
    )
    
    local ports_in_use=()
    
    for port in "${vps_ports[@]}"; do
        if ss -tln | grep -q ":$port "; then
            ports_in_use+=("$port")
            warning "Porta $port está em uso"
        fi
    done
    
    # Verificar porta SSH separadamente (apenas informativo, não é erro)
    if ss -tln | grep -q ":22 "; then
        success "Porta 22 (SSH) está ativa - serviço SSH funcionando normalmente"
    else
        warning "Porta 22 (SSH) não está em uso - verifique se o serviço SSH está ativo"
    fi
    
    if [[ ${#ports_in_use[@]} -gt 0 ]]; then
        warning "Portas em uso que podem causar conflitos: ${ports_in_use[*]}"
        info "Execute 'ss -tln | grep -E \":(${ports_in_use[*]// /|})\"' para ver detalhes"
        # TODO: Implementar resolução automática de conflitos de porta
        # - Parar serviços conflitantes quando necessário
        # - Reconfigurar portas dos VPS se apropriado
        warning "Continuando setup apesar dos conflitos de porta..."
    else
        success "Todas as portas necessárias estão disponíveis"
    fi
}

# Instalar Vagrant
install_vagrant() {
    info "Instalando Vagrant..."
    
    # Verificar se já está instalado
    if command -v vagrant > /dev/null 2>&1; then
        local current_version=$(vagrant --version | cut -d' ' -f2)
        info "Vagrant já instalado: $current_version"
        return 0
    fi
    
    # Baixar e instalar a versão mais recente
    local vagrant_version="2.4.1"  # Versão estável atual
    local vagrant_url="https://releases.hashicorp.com/vagrant/${vagrant_version}/vagrant_${vagrant_version}-1_amd64.deb"
    
    cd /tmp
    wget -q "$vagrant_url" >> "$LOG_FILE" 2>&1
    dpkg -i "vagrant_${vagrant_version}-1_amd64.deb" >> "$LOG_FILE" 2>&1
    rm -f "vagrant_${vagrant_version}-1_amd64.deb"
    
    # Instalar plugin libvirt
    vagrant plugin install vagrant-libvirt >> "$LOG_FILE" 2>&1
    
    success "Vagrant $vagrant_version instalado com plugin libvirt"
}

# Configurar rede para VPS
setup_networking() {
    info "Configurando rede para VPS..."
    
    # Criar bridge para rede pública (se não existir)
    if ! ip link show br0 > /dev/null 2>&1; then
        # Criar bridge persistente
        cat > /etc/netplan/99-vps-bridge.yaml << 'EOF'
# Bridge configuration for VPS infrastructure
network:
  version: 2
  renderer: networkd
  bridges:
    br0:
      interfaces: []
      dhcp4: false
      dhcp6: false
      parameters:
        stp: false
        forward-delay: 0
EOF
        
        # Aplicar configuração
        netplan apply >> "$LOG_FILE" 2>&1
        
        info "Bridge br0 criada para rede pública"
    fi
    
    # Configurar libvirt default network
    if ! virsh net-info default > /dev/null 2>&1; then
        virsh net-define /dev/stdin << 'EOF'
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='192.168.122.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.122.2' end='192.168.122.254'/>
    </dhcp>
  </ip>
</network>
EOF
        virsh net-autostart default >> "$LOG_FILE" 2>&1
        virsh net-start default >> "$LOG_FILE" 2>&1
    fi
    
    success "Rede configurada"
}

# Configurar firewall
setup_firewall() {
    info "Configurando firewall (UFW)..."
    
    # Instalar UFW se não estiver
    if ! command -v ufw > /dev/null 2>&1; then
        apt-get install -y ufw >> "$LOG_FILE" 2>&1
    fi
    
    # Configuração básica
    ufw --force reset >> "$LOG_FILE" 2>&1
    
    # Regras básicas
    ufw default deny incoming >> "$LOG_FILE" 2>&1
    ufw default allow outgoing >> "$LOG_FILE" 2>&1
    
    # Permitir SSH
    ufw allow ssh >> "$LOG_FILE" 2>&1
    
    # Permitir tráfego libvirt
    ufw allow in on virbr0 >> "$LOG_FILE" 2>&1
    ufw allow out on virbr0 >> "$LOG_FILE" 2>&1
    
    # Habilitar UFW
    ufw --force enable >> "$LOG_FILE" 2>&1
    
    success "Firewall configurado"
}

# Criar estrutura de diretórios
create_directories() {
    info "Criando estrutura de diretórios..."
    
    local dirs=(
        "/opt/vps-hosting"
        "/opt/vps-hosting/logs"
        "/opt/vps-hosting/backups"
        "/opt/vps-hosting/scripts"
        "/var/lib/libvirt/images/vps"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
        chmod 755 "$dir"
    done
    
    success "Estrutura de diretórios criada"
}

# Verificar instalação
verify_installation() {
    info "Verificando instalação..."
    
    local errors=0
    
    # Verificar Vagrant
    if ! command -v vagrant > /dev/null 2>&1; then
        warning "Vagrant não encontrado"
        # TODO: Instalar Vagrant automaticamente se não estiver presente
        ((errors++))
    else
        success "Vagrant encontrado: $(vagrant --version)"
    fi
    
    # Verificar plugin vagrant-libvirt (apenas se Vagrant estiver instalado)
    if command -v vagrant > /dev/null 2>&1; then
        if ! vagrant plugin list | grep -q vagrant-libvirt; then
            warning "Plugin vagrant-libvirt não instalado"
            # TODO: Instalar plugin vagrant-libvirt automaticamente
            ((errors++))
        else
            success "Plugin vagrant-libvirt encontrado"
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        success "Verificação concluída com sucesso"
        return 0
    else
        warning "Verificação encontrou $errors problema(s) - consulte TODOs no código"
        return 1
    fi
}

# Exibir informações finais
show_final_info() {
    log ""
    log "${GREEN}🎉 Configuração do ambiente concluída!${NC}"
    log ""
    log "${BLUE}📋 Informações importantes:${NC}"
    log "• Log completo: $LOG_FILE"
    log "• Bridge br0 criada para rede pública"
    log "• Rede padrão libvirt (virbr0) verificada"
    log "• Firewall UFW configurado"
    log "• Estrutura de diretórios criada em /opt/vps-hosting"
    log ""
    log "${YELLOW}🔄 Próximos passos:${NC}"
    log "1. Verificar se KVM está configurado: check_kvm() reportou warnings"
    log "2. Resolver conflitos de porta se houver"
    log "3. Instalar Vagrant se necessário"
    log "4. Configurar plugin vagrant-libvirt"
    log "5. Navegue para core/gitlab-vps/ ou core/nginx-app-vps/"
    log "6. Execute: vagrant up"
    log ""
    log "${GREEN}✨ Ambiente base preparado!${NC}"
}

# Função principal
main() {
    log "${BLUE}🚀 Iniciando preparação do ambiente VPS Hosting Infrastructure${NC}"
    log "$(date '+%Y-%m-%d %H:%M:%S') - Log: $LOG_FILE"
    log ""
    
    check_root
    check_ubuntu_version
    check_system_requirements
    check_ports
    check_kvm
    update_system
    install_basic_packages
    install_vagrant
    setup_networking
    setup_firewall
    create_directories
    verify_installation
    show_final_info
    
    log ""
    log "${GREEN}🎯 Setup concluído com sucesso!${NC}"
}

# Capturar sinais para cleanup
trap 'error "Script interrompido pelo usuário"' INT TERM

# Executar função principal
main "$@"