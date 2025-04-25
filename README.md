# VPS MCP - Instalação Automatizada

Script para instalação automatizada de Docker, Traefik e Portainer em VPS Ubuntu com MCP.

## Funcionalidades

Este script automatiza a instalação e configuração dos seguintes componentes:

- **Docker e Docker Swarm**: para orquestração de containers
- **Traefik**: como proxy reverso e gerenciador de SSL
- **Portainer**: para gerenciamento visual dos containers
- **MCP Server**: para integração com Cursor AI

## Como usar

1. Faça upload do script para sua VPS
2. Torne-o executável com `chmod +x instalador`
3. Execute o script: `./instalador`
4. Siga as instruções para informar seu email e domínio

## Pré-requisitos

- VPS com Ubuntu 20.04 ou superior
- Um domínio apontado para o IP da VPS
- Acesso root ou sudo à VPS

## Após a instalação

Após a conclusão da instalação, você terá acesso às seguintes URLs:

- Dashboard Traefik: https://traefik.seudominio.com.br
- Portainer: https://portainer.seudominio.com.br
- MCP Server: https://mcp.seudominio.com.br

Para conectar seu Cursor IA ao MCP Server, use a URL: https://mcp.seudominio.com.br