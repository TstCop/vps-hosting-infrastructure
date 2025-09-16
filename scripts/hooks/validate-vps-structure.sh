#!/usr/bin/env bash
# validate-vps-structure.sh
# Validar estrutura do projeto VPS Hosting Infrastructure

set -euo pipefail

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Validando estrutura do projeto VPS...${NC}"

# Verificar política de scripts .sh
echo "🔧 Verificando política de scripts .sh..."

# Permitir apenas setup.sh na raiz
root_sh_files=($(find . -maxdepth 1 -name "*.sh" -type f | grep -v "^\./setup\.sh$" || true))
if [[ ${#root_sh_files[@]} -gt 0 ]]; then
    echo -e "${RED}❌ Scripts .sh não permitidos na raiz (exceto setup.sh):${NC}"
    printf "${RED}   %s${NC}\n" "${root_sh_files[@]}"
    echo -e "${YELLOW}   Mova estes scripts para scripts/hooks/ ou para diretórios específicos dos VPS${NC}"
    exit 1
fi

# Verificar se setup.sh existe na raiz
if [[ ! -f "./setup.sh" ]]; then
    echo -e "${RED}❌ Arquivo setup.sh obrigatório não encontrado na raiz${NC}"
    exit 1
fi

# Permitir scripts .sh em locais específicos:
# - scripts/hooks/ (hooks do git)
# - */scripts/ (scripts dos VPS)
# - Excluir .vagrant (arquivos temporários do vagrant)
invalid_sh_files=($(find . -name "*.sh" -type f \
    ! -path "./setup.sh" \
    ! -path "./scripts/hooks/*" \
    ! -path "./*/scripts/*" \
    ! -path "*/.vagrant/*" \
    || true))

if [[ ${#invalid_sh_files[@]} -gt 0 ]]; then
    echo -e "${RED}❌ Scripts .sh em locais não permitidos:${NC}"
    printf "${RED}   %s${NC}\n" "${invalid_sh_files[@]}"
    echo -e "${YELLOW}   Locais permitidos:${NC}"
    echo -e "${YELLOW}   - Raiz: apenas setup.sh${NC}"
    echo -e "${YELLOW}   - scripts/hooks/ (hooks do git)${NC}"
    echo -e "${YELLOW}   - */scripts/ (scripts dos VPS)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Política de scripts .sh válida${NC}"

# Estrutura obrigatória
required_dirs=(
    "app"
    "app/src"
    "app/src/api"
    "app/src/api/controllers"
    "app/src/api/routes"
    "core"
    "docs"
    "docs/app"
    "docs/core"
)

required_files=(
    "README.md"
    "PRD.md"
    ".gitignore"
    "app/package.json"
    "app/tsconfig.json"
)

# Verificar diretórios obrigatórios
echo "📁 Verificando diretórios obrigatórios..."
for dir in "${required_dirs[@]}"; do
    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}❌ Diretório obrigatório não encontrado: $dir${NC}"
        exit 1
    fi
done

# Verificar arquivos obrigatórios
echo "📄 Verificando arquivos obrigatórios..."
for file in "${required_files[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo -e "${RED}❌ Arquivo obrigatório não encontrado: $file${NC}"
        exit 1
    fi
done

# Verificar que não há arquivos na raiz além dos permitidos
echo "🛡️ Verificando proteção da raiz..."
allowed_root_files=(
    "README.md"
    "PRD.md"
    ".gitignore"
    ".pre-commit-config.yaml"
    ".markdownlint.json"
    "LICENSE"
    "CHANGELOG.md"
    "setup.sh"
)

for file in *; do
    if [[ -f "$file" ]]; then
        if [[ ! " ${allowed_root_files[*]} " == *" ${file} "* ]]; then
            echo -e "${RED}❌ Arquivo não permitido na raiz: $file${NC}"
            echo -e "${YELLOW}💡 Mova para o diretório apropriado (app/, docs/, etc.)${NC}"
            exit 1
        fi
    fi
done

echo -e "${GREEN}✅ Estrutura do projeto VPS validada com sucesso!${NC}"
