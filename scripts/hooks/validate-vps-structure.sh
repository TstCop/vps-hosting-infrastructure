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
