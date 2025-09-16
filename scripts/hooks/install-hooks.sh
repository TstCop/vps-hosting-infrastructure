#!/usr/bin/env bash
# install-hooks.sh - Instalar hooks do git no repositório atual
# Este script copia e configura os hooks do git para o repositório

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Instalando Git hooks...${NC}"

# Verificar se estamos em um repositório git
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Este diretório não é um repositório git${NC}"
    echo -e "${YELLOW}💡 Execute 'git init' primeiro${NC}"
    exit 1
fi

# Diretórios
REPO_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_SOURCE="$REPO_ROOT/scripts/hooks"
HOOKS_TARGET="$REPO_ROOT/.git/hooks"

# Verificar se o diretório de hooks fonte existe
if [[ ! -d "$HOOKS_SOURCE" ]]; then
    echo -e "${RED}❌ Diretório de hooks não encontrado: $HOOKS_SOURCE${NC}"
    exit 1
fi

echo -e "${YELLOW}📂 Fonte: $HOOKS_SOURCE${NC}"
echo -e "${YELLOW}📂 Destino: $HOOKS_TARGET${NC}"

# Lista de hooks a instalar
hooks_to_install=(
    "pre-commit"
)

# Instalar cada hook
for hook in "${hooks_to_install[@]}"; do
    source_file="$HOOKS_SOURCE/$hook"
    target_file="$HOOKS_TARGET/$hook"
    
    if [[ -f "$source_file" ]]; then
        echo -e "${YELLOW}🔧 Instalando hook: $hook${NC}"
        
        # Backup do hook existente se houver
        if [[ -f "$target_file" ]]; then
            backup_file="$target_file.backup.$(date +%Y%m%d%H%M%S)"
            mv "$target_file" "$backup_file"
            echo -e "${YELLOW}📦 Backup criado: $backup_file${NC}"
        fi
        
        # Copiar e tornar executável
        cp "$source_file" "$target_file"
        chmod +x "$target_file"
        
        echo -e "${GREEN}✅ Hook $hook instalado${NC}"
    else
        echo -e "${YELLOW}⚠️  Hook não encontrado: $source_file${NC}"
    fi
done

echo -e "${GREEN}🎉 Instalação de hooks concluída!${NC}"
echo -e "${BLUE}ℹ️  Os hooks serão executados automaticamente em operações git${NC}"

# Testar hooks instalados
echo -e "${YELLOW}🧪 Testando hooks instalados...${NC}"
for hook in "${hooks_to_install[@]}"; do
    target_file="$HOOKS_TARGET/$hook"
    if [[ -x "$target_file" ]]; then
        echo -e "${GREEN}✅ $hook está ativo e executável${NC}"
    else
        echo -e "${RED}❌ $hook não está executável${NC}"
    fi
done

echo -e "${GREEN}✨ Git hooks prontos para uso!${NC}"