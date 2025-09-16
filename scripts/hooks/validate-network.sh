#!/usr/bin/env bash
# validate-network.sh
# Validar configurações de rede para VPS Infrastructure

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🌐 Validando configurações de rede...${NC}"

# IPs de produção definidos
PRODUCTION_IPS=(
    "136.243.94.243"      # IP Principal
    "136.243.208.128"     # Network Address
    "136.243.208.129"     # Gateway
    "136.243.208.130"     # GitLab VPS
    "136.243.208.131"     # Nginx/App VPS
    "136.243.208.132"     # Disponível
    "136.243.208.133"     # Disponível
    "136.243.208.134"     # Disponível
    "136.243.208.135"     # Broadcast Address
)

# Função para validar IP
validate_ip() {
    local ip=$1
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        IFS='.' read -ra ADDR <<< "$ip"
        for i in "${ADDR[@]}"; do
            if [[ $i -gt 255 ]]; then
                return 1
            fi
        done
        return 0
    fi
    return 1
}

# Função para validar subnet
validate_subnet() {
    local subnet=$1
    if [[ $subnet =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        local ip_part="${subnet%/*}"
        local cidr_part="${subnet#*/}"

        if validate_ip "$ip_part" && [[ $cidr_part -ge 0 && $cidr_part -le 32 ]]; then
            return 0
        fi
    fi
    return 1
}

# Processar arquivos de configuração de rede
for file in "$@"; do
    if [[ -f "$file" && ($file == *"network"* || $file == *"ip"*) ]]; then
        echo "📄 Verificando: $file"

        # Extrair IPs do arquivo
        while IFS= read -r line; do
            # Buscar padrões de IP
            if [[ $line =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; then
                ip="${BASH_REMATCH[0]}"

                if validate_ip "$ip"; then
                    echo "  ✓ IP válido encontrado: $ip"

                    # Verificar se é um IP de produção conhecido
                    if [[ " ${PRODUCTION_IPS[*]} " == *" ${ip} "* ]]; then
                        echo "    🎯 IP de produção confirmado"
                    elif [[ $ip =~ ^10\.0\.0\. ]]; then
                        echo "    🔒 IP da rede privada"
                    elif [[ $ip =~ ^192\.168\.56\. ]]; then
                        echo "    🔧 IP da rede Vagrant"
                    else
                        echo -e "    ${YELLOW}⚠️ IP não reconhecido: $ip${NC}"
                    fi
                else
                    echo -e "${RED}❌ IP inválido: $ip${NC}"
                    exit 1
                fi
            fi

            # Verificar subnets
            if [[ $line =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2} ]]; then
                subnet="${BASH_REMATCH[0]}"

                if validate_subnet "$subnet"; then
                    echo "  ✓ Subnet válida: $subnet"
                else
                    echo -e "${RED}❌ Subnet inválida: $subnet${NC}"
                    exit 1
                fi
            fi
        done < "$file"
    fi
done

echo -e "${GREEN}✅ Configurações de rede validadas!${NC}"
