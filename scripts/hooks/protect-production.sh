#!/usr/bin/env bash
# protect-production.sh
# Proteger arquivos críticos de produção

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}🛡️ Verificando proteção de arquivos de produção...${NC}"

# Arquivos críticos que exigem atenção especial
critical_files=(
    "PRD.md"
    "README.md"
    "core/gitlab-vps/Vagrantfile"
    "core/nginx-app-vps/Vagrantfile"
    "app/docker-compose.yml"
    "app/config/database.yaml"
    "app/config/network.yaml"
)

# Verificar mudanças em arquivos críticos
for file in "$@"; do
    if [[ " ${critical_files[*]} " == *" ${file} "* ]]; then
        echo -e "${YELLOW}⚠️ Arquivo crítico modificado: $file${NC}"

        # Verificar se há IPs de produção sendo alterados
        if git diff --cached "$file" | grep -E '136\.243\.(94\.243|208\.1[2-3][0-9])'; then
            echo -e "${RED}🚨 ATENÇÃO: IPs de produção detectados em $file${NC}"
            echo -e "${YELLOW}Verifique se as alterações estão corretas antes de continuar.${NC}"

            # Não bloquear, apenas avisar
            read -p "Continuar mesmo assim? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${RED}❌ Commit cancelado pelo usuário${NC}"
                exit 1
            fi
        fi

        # Verificar se há credenciais ou tokens
        if git diff --cached "$file" | grep -iE '(password|token|secret|key|credential).*='; then
            echo -e "${RED}🚨 POSSÍVEL CREDENCIAL DETECTADA em $file${NC}"
            echo -e "${RED}❌ Não commite credenciais!${NC}"
            exit 1
        fi
    fi
done

# Verificar se há Vagrantfiles com configurações perigosas
for file in "$@"; do
    if [[ $file == *"Vagrantfile"* ]]; then
        # Verificar configurações de rede bridged em produção
        if git diff --cached "$file" | grep -q "bridge"; then
            echo -e "${YELLOW}⚠️ Configuração bridge detectada em $file${NC}"
            echo -e "${YELLOW}Verifique se isso é intencional em produção.${NC}"
        fi

        # Verificar se há configuração insegura
        if git diff --cached "$file" | grep -E "(config\.ssh\.password|config\.ssh\.insert_key.*false)"; then
            echo -e "${RED}🚨 Configuração SSH insegura detectada em $file${NC}"
            echo -e "${YELLOW}Considere usar chaves SSH em vez de senhas.${NC}"
        fi
    fi
done

echo -e "${GREEN}✅ Verificação de proteção concluída${NC}"
