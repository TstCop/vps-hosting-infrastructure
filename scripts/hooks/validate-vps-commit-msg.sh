#!/usr/bin/env bash
# validate-vps-commit-msg.sh
# Validar formato de mensagens de commit para VPS Infrastructure

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

commit_msg_file=$1

if [[ ! -f "$commit_msg_file" ]]; then
    echo -e "${RED}❌ Arquivo de mensagem de commit não encontrado${NC}"
    exit 1
fi

commit_msg=$(cat "$commit_msg_file")

echo -e "${YELLOW}📝 Validando mensagem de commit...${NC}"

# Ignorar commits de merge e revert
if [[ $commit_msg =~ ^Merge || $commit_msg =~ ^Revert ]]; then
    echo -e "${GREEN}✅ Commit de merge/revert - validação ignorada${NC}"
    exit 0
fi

# Padrões permitidos para VPS Infrastructure
valid_types=(
    "feat"      # Nova funcionalidade
    "fix"       # Correção de bug
    "docs"      # Documentação
    "style"     # Formatação
    "refactor"  # Refatoração
    "test"      # Testes
    "chore"     # Manutenção
    "ci"        # CI/CD
    "infra"     # Infraestrutura
    "config"    # Configuração
    "vagrant"   # Específico para Vagrant
    "vps"       # Específico para VPS
    "network"   # Configurações de rede
)

# Áreas específicas do projeto
valid_scopes=(
    "api"
    "vagrant"
    "network"
    "docs"
    "core"
    "app"
    "gitlab"
    "nginx"
    "monitoring"
    "security"
    "backup"
)

# Validar formato: type(scope): description
if [[ $commit_msg =~ ^([a-z]+)(\([a-z]+\))?: ]]; then
    type="${BASH_REMATCH[1]}"
    scope_part="${BASH_REMATCH[2]}"

    # Remover parênteses do scope
    scope="${scope_part//[()]/}"

    # Validar tipo
    if [[ ! " ${valid_types[*]} " == *" ${type} "* ]]; then
        echo -e "${RED}❌ Tipo de commit inválido: '$type'${NC}"
        echo -e "${YELLOW}Tipos válidos: ${valid_types[*]}${NC}"
        exit 1
    fi

    # Validar scope se presente
    if [[ -n "$scope" && ! " ${valid_scopes[*]} " == *" ${scope} "* ]]; then
        echo -e "${RED}❌ Escopo inválido: '$scope'${NC}"
        echo -e "${YELLOW}Escopos válidos: ${valid_scopes[*]}${NC}"
        exit 1
    fi

    # Extrair e validar descrição
    description="${commit_msg#*: }"

    # Verificar comprimento da primeira linha
    first_line=$(echo "$commit_msg" | head -n1)
    if [[ ${#first_line} -gt 72 ]]; then
        echo -e "${RED}❌ Primeira linha muito longa (${#first_line} chars, máximo 72)${NC}"
        exit 1
    fi

    # Verificar se começa com minúscula
    if [[ ! $description =~ ^[a-z] ]]; then
        echo -e "${RED}❌ Descrição deve começar com letra minúscula${NC}"
        exit 1
    fi

    # Verificar se não termina com ponto
    if [[ $description =~ \.$ ]]; then
        echo -e "${RED}❌ Descrição não deve terminar com ponto${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Formato de commit válido: $type${scope_part}${NC}"

else
    echo -e "${RED}❌ Formato de commit inválido${NC}"
    echo -e "${YELLOW}Formato correto: tipo(escopo): descrição${NC}"
    echo -e "${YELLOW}Exemplo: feat(api): adicionar endpoint para gerenciar VMs${NC}"
    echo -e "${YELLOW}Exemplo: fix(vagrant): corrigir configuração de rede privada${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Mensagem de commit validada!${NC}"
