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

    # Configurar IPs públicos no netplan
    setup_public_network

    # Configurar redes virtuais libvirt
    setup_libvirt_networks

    success "Rede configurada"
}

# Configurar IPs públicos e subnets no netplan
setup_public_network() {
    info "Configurando IPs públicos no netplan..."

    # Obter interface de rede principal
    local main_interface
    main_interface=$(ip route | grep default | awk '{print $5}' | head -n1)

    if [[ -z "$main_interface" ]]; then
        warning "Não foi possível detectar interface de rede principal"
        main_interface="enp35s0"  # fallback comum
    fi

    info "Interface principal detectada: $main_interface"

    # Fazer backup de todas as configurações netplan existentes
    local backup_dir="/etc/netplan/backup-$(date +%Y%m%d-%H%M%S)"
    if ls /etc/netplan/*.yaml 1> /dev/null 2>&1; then
        info "Fazendo backup das configurações netplan existentes..."
        mkdir -p "$backup_dir"
        cp /etc/netplan/*.yaml "$backup_dir/" 2>/dev/null || true
        success "Backup criado em: $backup_dir"
    fi

    # Remover configurações existentes que podem conflitar
    info "Removendo configurações netplan existentes..."
    rm -f /etc/netplan/*.yaml

    # Criar nossa configuração netplan principal
    local netplan_file="/etc/netplan/01-xcloud-network.yaml"

    info "Criando nova configuração netplan..."

    cat > "$netplan_file" << EOF
# XCloud Network Configuration
# IP IPv4 Principal: 136.243.94.243
# Subnet /29 IPv4: 136.243.208.128/29 (8 IPs, 6 utilizáveis)
# Subnet IPv6: 2a01:48:171:76b::/64

network:
  version: 2
  renderer: networkd
  ethernets:
    $main_interface:
      addresses:
        # IP IPv4 Principal
        - 136.243.94.243/32

        # Subnet IPv4 /29 (todos os IPs utilizáveis)
        - 136.243.208.128/29
        - 136.243.208.129/29  # Load Balancer
        - 136.243.208.130/29  # GitLab (API Gateway)
        - 136.243.208.131/29  # Web Frontend
        - 136.243.208.132/29  # Available
        - 136.243.208.133/29  # Available

        # IPv6 - usando um IP da subnet
        - 2a01:48:171:76b::2/64

      routes:
        # Rota IPv4 padrão
        - to: 0.0.0.0/0
          via: 136.243.94.193
          on-link: true

        # Rota IPv6 padrão
        - to: ::/0
          via: 2a01:4f8:0:1::1  # Gateway IPv6 do Hetzner
          on-link: true

      nameservers:
        addresses:
          - 185.12.64.1
          - 185.12.64.2
          - 2a01:4ff:ff00::add:1
          - 2a01:4ff:ff00::add:2

  # Bridge para VMs (rede privada)
  bridges:
    br0:
      interfaces: []
      dhcp4: false
      dhcp6: false
      addresses:
        - 192.168.100.1/24  # Gateway para VMs internas
      parameters:
        stp: false
        forward-delay: 0
EOF

    # Ajustar permissões corretas
    chmod 600 "$netplan_file"
    chown root:root "$netplan_file"

    info "Validando nova configuração netplan..."

    # Validar sintaxe da configuração
    if netplan generate >> "$LOG_FILE" 2>&1; then
        info "Sintaxe da configuração válida"
    else
        error "Erro na sintaxe da configuração netplan. Verifique $LOG_FILE"
    fi

    # Aplicar configuração com timeout
    info "Aplicando nova configuração de rede..."
    if timeout 30 netplan apply >> "$LOG_FILE" 2>&1; then
        success "Configuração netplan aplicada com sucesso"

        # Verificar se os IPs foram configurados
        sleep 3
        if ip addr show "$main_interface" | grep -q "136.243.94.243"; then
            success "IP principal 136.243.94.243 configurado"
        fi

        if ip addr show "$main_interface" | grep -q "136.243.208"; then
            success "Subnet 136.243.208.128/29 configurada"
        fi

        # Mostrar IPs configurados
        info "IPs públicos configurados:"
        info "  • Principal: 136.243.94.243"
        info "  • Subnet: 136.243.208.128/29"
        info "    - 136.243.208.129 (Load Balancer)"
        info "    - 136.243.208.130 (GitLab/API Gateway)"
        info "    - 136.243.208.131 (Web Frontend)"
        info "    - 136.243.208.132-133 (Disponíveis)"
        info "  • IPv6: 2a01:48:171:76b::2/64"
        info "  • Bridge: br0 (192.168.100.1/24)"

    else
        error "Falha ao aplicar configuração netplan. Restaurando backup..."

        # Restaurar backup em caso de erro
        if [[ -d "$backup_dir" ]]; then
            rm -f /etc/netplan/*.yaml
            cp "$backup_dir"/*.yaml /etc/netplan/ 2>/dev/null || true
            netplan apply >> "$LOG_FILE" 2>&1 || true
            warning "Configuração anterior restaurada"
        fi

        error "Configuração netplan falhou. Backup em: $backup_dir"
    fi
}

# Configurar redes virtuais libvirt
setup_libvirt_networks() {
    info "Configurando redes virtuais libvirt..."

    # Rede xcloud-internal (192.168.56.0/24)
    if ! virsh net-info xcloud-internal > /dev/null 2>&1; then
        info "Criando rede xcloud-internal..."

        virsh net-define /dev/stdin << 'EOF'
<network>
  <name>xcloud-internal</name>
  <bridge name="virbr10" stp="on" delay="0"/>
  <forward mode="nat">
    <nat>
      <port start="1024" end="65535"/>
    </nat>
  </forward>
  <ip address="192.168.56.1" netmask="255.255.255.0">
    <dhcp>
      <range start="192.168.56.50" end="192.168.56.200"/>
    </dhcp>
  </ip>
</network>
EOF

        virsh net-autostart xcloud-internal >> "$LOG_FILE" 2>&1
        virsh net-start xcloud-internal >> "$LOG_FILE" 2>&1
        success "Rede xcloud-internal criada (192.168.56.0/24)"
    else
        info "Rede xcloud-internal já existe"
    fi

    # Rede xcloud-private (10.0.0.0/24)
    if ! virsh net-info xcloud-private > /dev/null 2>&1; then
        info "Criando rede xcloud-private..."

        virsh net-define /dev/stdin << 'EOF'
<network>
  <name>xcloud-private</name>
  <bridge name="virbr20" stp="on" delay="0"/>
  <forward mode="nat">
    <nat>
      <port start="1024" end="65535"/>
    </nat>
  </forward>
  <ip address="10.0.0.1" netmask="255.255.255.0">
    <dhcp>
      <range start="10.0.0.50" end="10.0.0.200"/>
    </dhcp>
  </ip>
</network>
EOF

        virsh net-autostart xcloud-private >> "$LOG_FILE" 2>&1
        virsh net-start xcloud-private >> "$LOG_FILE" 2>&1
        success "Rede xcloud-private criada (10.0.0.0/24)"
    else
        info "Rede xcloud-private já existe"
    fi

    # Configurar libvirt default network (se não existir)
    if ! virsh net-info default > /dev/null 2>&1; then
        info "Criando rede default do libvirt..."

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
        success "Rede default criada (192.168.122.0/24)"
    else
        info "Rede default já existe"
    fi

    # Verificar status das redes
    info "Status das redes libvirt:"
    virsh net-list --all | tee -a "$LOG_FILE"
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
    log "• Backup netplan: /etc/netplan/backup-*"
    log ""
    log "${BLUE}🌐 Redes Configuradas:${NC}"
    log "• IPs Públicos (DEFINITIVOS):"
    log "  - Principal: 136.243.94.243"
    log "  - Subnet: 136.243.208.128/29 (8 IPs)"
    log "    ∟ 136.243.208.129 (Load Balancer)"
    log "    ∟ 136.243.208.130 (GitLab/API Gateway)"
    log "    ∟ 136.243.208.131 (Web Frontend)"
    log "    ∟ 136.243.208.132-133 (Disponíveis)"
    log "  - IPv6: 2a01:48:171:76b::2/64"
    log ""
    log "• Redes Virtuais (libvirt):"
    log "  - xcloud-internal: 192.168.56.0/24 (Cluster)"
    log "  - xcloud-private: 10.0.0.0/24 (Serviços internos)"
    log "  - default: 192.168.122.0/24 (Vagrant padrão)"
    log "  - br0: 192.168.100.0/24 (Bridge VMs)"
    log ""
    log "• Firewall UFW configurado"
    log "• Estrutura de diretórios criada"
    log ""
    log "${YELLOW}🔄 Próximos passos:${NC}"
    log "1. Verificar conectividade: ping 136.243.208.130"
    log "2. Testar redes libvirt: virsh net-list --all"
    log "3. Navegar para core/gitlab-vps/"
    log "4. Executar: vagrant up"
    log "5. Verificar status: vagrant status"
    log ""
    log "${BLUE}🔧 Comandos úteis:${NC}"
    log "• Verificar IPs: ip addr show"
    log "• Status redes: virsh net-list"
    log "• Logs: tail -f $LOG_FILE"
    log "• Netplan status: netplan status"
    log "• Restaurar backup: cp /etc/netplan/backup-*/\\*.yaml /etc/netplan/"
    log ""
    log "${GREEN}✨ Ambiente XCloud PRONTO!${NC}"
    log "${YELLOW}⚠️  IMPORTANTE: Configuração de rede foi SUBSTITUÍDA completamente${NC}"
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
