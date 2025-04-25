# VPS MCP - Instalação Automatizada

Script para instalação automatizada de Docker, Traefik e Portainer em VPS Ubuntu com MCP.

## Instalação Rápida

Execute o comando abaixo na sua VPS para iniciar a instalação:

```bash
curl -fsSL https://raw.githubusercontent.com/LuizBranco-ClickHype/vpsmcp/main/instalador.sh -o instalador.sh && chmod +x instalador.sh && ./instalador.sh
```

## Funcionalidades

Este script automatiza a instalação e configuração dos seguintes componentes:

- **Docker e Docker Swarm**: para orquestração de containers
- **Traefik**: como proxy reverso e gerenciador de SSL
- **Portainer**: para gerenciamento visual dos containers
- **MCP Server**: para integração com Cursor AI

## Pré-requisitos

- VPS com Ubuntu 20.04 ou superior
- Um domínio apontado para o IP da VPS
- Acesso root ou sudo à VPS

## Instalação Manual

Se preferir, você pode fazer a instalação manual:

1. Baixe o script:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/LuizBranco-ClickHype/vpsmcp/main/instalador.sh -o instalador.sh
   ```

2. Torne-o executável:
   ```bash
   chmod +x instalador.sh
   ```

3. Execute o script:
   ```bash
   ./instalador.sh
   ```

4. Siga as instruções para informar seu email e domínio

## Após a instalação

Após a conclusão da instalação, você terá acesso às seguintes URLs:

- Dashboard Traefik: https://traefik.seudominio.com.br
- Portainer: https://portainer.seudominio.com.br
- MCP Server: https://mcp.seudominio.com.br

## Conexão com Cursor IA

Para conectar seu Cursor IA ao MCP Server:

1. Abra o Cursor IA
2. Acesse as configurações
3. Na seção MCP, adicione a URL: https://mcp.seudominio.com.br

## Resolução de Problemas

Se encontrar algum problema durante a instalação, verifique:

1. Se o domínio está corretamente apontado para o IP da sua VPS
2. Se as portas 80 e 443 estão liberadas no firewall
3. Se o Docker foi instalado corretamente

Para visualizar os logs do MCP Server:
```bash
sudo journalctl -u mcp-server
```