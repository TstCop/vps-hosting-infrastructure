#!/bin/bash

# Script para corrigir erros de Grid no Material-UI

echo "Corrigindo erros de Grid no Material-UI..."

# Função para corrigir arquivos
fix_grid_in_file() {
    local file="$1"
    echo "Corrigindo $file..."

    # Substituir Grid item por Grid2
    sed -i 's/<Grid item xs={\([^}]*\)}/<Grid2 xs={\1}/g' "$file"
    sed -i 's/<Grid item xs={\([^}]*\)} md={\([^}]*\)}/<Grid2 xs={\1} md={\2}/g' "$file"
    sed -i 's/<Grid item xs={\([^}]*\)} md={\([^}]*\)} lg={\([^}]*\)}/<Grid2 xs={\1} md={\2} lg={\3}/g' "$file"
    sed -i 's/<Grid item xs={\([^}]*\)} sm={\([^}]*\)} md={\([^}]*\)}/<Grid2 xs={\1} sm={\2} md={\3}/g' "$file"

    # Casos com valores numéricos diretos
    sed -i 's/<Grid item xs=\([0-9]\+\)>/<Grid2 xs={\1}>/g' "$file"
    sed -i 's/<Grid item xs=\([0-9]\+\) md=\([0-9]\+\)>/<Grid2 xs={\1} md={\2}>/g' "$file"
    sed -i 's/<Grid item xs=\([0-9]\+\) md=\([0-9]\+\) lg=\([0-9]\+\)>/<Grid2 xs={\1} md={\2} lg={\3}>/g' "$file"
    sed -i 's/<Grid item xs=\([0-9]\+\) sm=\([0-9]\+\) md=\([0-9]\+\)>/<Grid2 xs={\1} sm={\2} md={\3}>/g' "$file"

    # Fechar tags Grid2
    sed -i 's/<\/Grid>/<\/Grid2>/g' "$file"

    # Adicionar imports do Grid2
    if ! grep -q "Grid2" "$file"; then
        sed -i '/import {/,/} from '\''@mui\/material'\''/ {
            s/Grid,/Grid, Grid2,/
            t
            s/Grid/Grid, Grid2/
        }' "$file"
    fi
}

# Lista de arquivos para corrigir
files=(
    "src/pages/Clients.tsx"
    "src/pages/Dashboard.tsx"
    "src/pages/Logs.tsx"
    "src/pages/Monitoring.tsx"
    "src/pages/Templates.tsx"
    "src/pages/VMs.tsx"
)

# Corrigir cada arquivo
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        fix_grid_in_file "$file"
        echo "✅ $file corrigido"
    else
        echo "❌ $file não encontrado"
    fi
done

echo "🎉 Correção de Grid concluída!"
