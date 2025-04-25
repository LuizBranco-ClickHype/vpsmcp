#!/bin/bash

# Cores para formatação
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # Sem cor

echo -e "${BLUE}=========================================================${NC}"
echo -e "${GREEN}           Instalador VPS MCP - Download               ${NC}"
echo -e "${BLUE}=========================================================${NC}"
echo ""
echo -e "${YELLOW}Este script irá baixar e iniciar o instalador principal.${NC}"
echo ""

# Verifica se curl está instalado
if ! command -v curl &> /dev/null; then
    echo -e "${YELLOW}Curl não encontrado. Instalando...${NC}"
    apt update && apt install -y curl
fi

echo -e "${GREEN}Baixando instalador principal...${NC}"
curl -fsSL https://raw.githubusercontent.com/LuizBranco-ClickHype/vpsmcp/main/instalador -o instalador
chmod +x instalador

echo -e "${GREEN}Download concluído!${NC}"
echo -e "${YELLOW}Iniciando instalador principal...${NC}"
echo ""
echo -e "${BLUE}=========================================================${NC}"

./instalador