#!/usr/bin/env bash
# validate-vagrant.sh
# Validar configurações Vagrant para VPS Infrastructure

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🔍 Validando configurações Vagrant...${NC}"

# Função para validar Vagrantfile
validate_vagrantfile() {
    local vagrantfile=$1
    echo "📄 Validando: $vagrantfile"

    # Verificar sintaxe Ruby básica
    if ! ruby -c "$vagrantfile" >/dev/null 2>&1; then
        echo -e "${RED}❌ Erro de sintaxe em: $vagrantfile${NC}"
        return 1
    fi

    # Verificar elementos obrigatórios
    local required_elements=(
        "Vagrant.configure"
        "config.vm.box"
        "config.vm.network"
    )

    for element in "${required_elements[@]}"; do
        if ! grep -q "$element" "$vagrantfile"; then
            echo -e "${RED}❌ Elemento obrigatório não encontrado em $vagrantfile: $element${NC}"
            return 1
        fi
    done

    # Verificar IPs válidos se presentes
    if grep -q "ip:" "$vagrantfile"; then
        echo "🌐 Verificando IPs..."
        # Extrai IPs e valida formato básico
        grep "ip:" "$vagrantfile" | while read -r line; do
            if [[ $line =~ [0-9]+\.[0-9]+\.[0-9]+\.[0-9]+ ]]; then
                echo "  ✓ IP encontrado: ${BASH_REMATCH[0]}"
            fi
        done
    fi

    echo -e "${GREEN}✅ $vagrantfile validado${NC}"
}

# Função para validar arquivo YAML
validate_yaml_config() {
    local yaml_file=$1
    echo "📄 Validando: $yaml_file"

    # Verificar sintaxe YAML
    if ! python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null; then
        echo -e "${RED}❌ Erro de sintaxe YAML em: $yaml_file${NC}"
        return 1
    fi

    echo -e "${GREEN}✅ $yaml_file validado${NC}"
}

# Processar arquivos passados como argumentos
for file in "$@"; do
    if [[ -f "$file" ]]; then
        case "$file" in
            *Vagrantfile*)
                validate_vagrantfile "$file"
                ;;
            *.yaml|*.yml)
                validate_yaml_config "$file"
                ;;
            *)
                echo -e "${YELLOW}⚠️ Arquivo ignorado: $file${NC}"
                ;;
        esac
    fi
done

echo -e "${GREEN}✅ Validação Vagrant concluída!${NC}"
