#!/bin/bash

# Função para solicitar e validar o email
obter_email() {
  while true; do
    read -p "Digite seu email para certificados SSL: " EMAIL
    if [[ $EMAIL =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
      echo $EMAIL
      return 0
    else
      echo "Email inválido. Por favor, tente novamente."
    fi
  done
}

# Função para solicitar e validar o domínio
obter_dominio() {
  while true; do
    read -p "Digite seu domínio (ex: meudominio.com.br): " DOMINIO
    if [[ $DOMINIO =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
      echo $DOMINIO
      return 0
    else
      echo "Domínio inválido. Por favor, tente novamente."
    fi
  done
}

# Solicita as informações do usuário
EMAIL=$(obter_email)
DOMINIO=$(obter_dominio)

echo "Iniciando instalação com email: $EMAIL e domínio: $DOMINIO"
echo "-----------------------------------------------------------"

# Atualiza a VPS
echo "Atualizando o sistema..."
sudo apt update && sudo apt upgrade -y

# Instala o Docker se não estiver instalado
if ! command -v docker &> /dev/null; then
    echo "Instalando Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Docker instalado com sucesso!"
else
    echo "Docker já está instalado."
fi

# Inicia o Docker Swarm se ainda não estiver ativo
if ! docker info | grep -q "Swarm: active"; then
    echo "Iniciando Docker Swarm..."
    docker swarm init
    echo "Docker Swarm inicializado!"
else
    echo "Docker Swarm já está ativo."
fi

# Cria redes e volumes necessários
echo "Criando redes e volumes Docker..."
docker network create --driver overlay network_public || true
docker volume create volume_swarm_shared || true
docker volume create volume_swarm_certificates || true
docker volume create portainer_data || true
echo "Redes e volumes criados!"

# Cria e implanta o arquivo Traefik YAML
echo "Configurando Traefik..."
cat <<EOF > traefik.yaml
version: "3.7"

services:
  traefik:
    image: traefik:2.11.2
    command:
      - "--api.dashboard=true"
      - "--providers.docker.swarmMode=true"
      - "--providers.docker.endpoint=unix:///var/run/docker.sock"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.docker.network=network_public"
      - "--entrypoints.web.address=:80"
      - "--entrypoints.web.http.redirections.entryPoint.to=websecure"
      - "--entrypoints.web.http.redirections.entryPoint.scheme=https"
      - "--entrypoints.web.http.redirections.entrypoint.permanent=true"
      - "--entrypoints.websecure.address=:443"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge=true"
      - "--certificatesresolvers.letsencryptresolver.acme.httpchallenge.entrypoint=web"
      - "--certificatesresolvers.letsencryptresolver.acme.email=$EMAIL"
      - "--certificatesresolvers.letsencryptresolver.acme.storage=/etc/traefik/letsencrypt/acme.json"
      - "--log.level=INFO"
      - "--log.format=common"
    deploy:
      placement:
        constraints:
          - node.role == manager
      labels:
        - "traefik.enable=true"
        - "traefik.http.middlewares.redirect-https.redirectscheme.scheme=https"
        - "traefik.http.middlewares.redirect-https.redirectscheme.permanent=true"
        - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
        - "traefik.http.routers.http-catchall.entrypoints=web"
        - "traefik.http.routers.http-catchall.middlewares=redirect-https@docker"
        - "traefik.http.routers.http-catchall.priority=1"
        - "traefik.http.routers.traefik.rule=Host(\`traefik.$DOMINIO\`)"
        - "traefik.http.routers.traefik.entrypoints=websecure"
        - "traefik.http.routers.traefik.tls.certresolver=letsencryptresolver"
        - "traefik.http.routers.traefik.service=api@internal"
        - "traefik.http.routers.traefik.middlewares=auth@docker"
        - "traefik.http.middlewares.auth.basicauth.users=admin:$$apr1$$ruca84Hq$$mbjdMZBAG.KWn7vfN/SNK/"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "vol_certificates:/etc/traefik/letsencrypt"
    ports:
      - target: 80
        published: 80
        mode: host
      - target: 443
        published: 443
        mode: host
    networks:
      - network_public

volumes:
  vol_shared:
    external: true
    name: volume_swarm_shared
  vol_certificates:
    external: true
    name: volume_swarm_certificates

networks:
  network_public:
    external: true
    name: network_public
EOF

docker stack deploy -c traefik.yaml traefik
echo "Traefik implantado com sucesso!"

# Cria e implanta o arquivo Portainer YAML
echo "Configurando Portainer..."
cat <<EOF > portainer.yaml
version: "3.7"

services:
  agent:
    image: portainer/agent:2.28.1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /var/lib/docker/volumes:/var/lib/docker/volumes
    networks:
      - network_public
    deploy:
      mode: global
      placement:
        constraints: [node.platform.os == linux]

  portainer:
    image: portainer/portainer-ce:2.28.1
    command: -H tcp://tasks.agent:9001 --tlsskipverify
    volumes:
      - portainer_data:/data
    networks:
      - network_public
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=network_public"
        - "traefik.http.routers.portainer.rule=Host(\`portainer.$DOMINIO\`)"
        - "traefik.http.routers.portainer.entrypoints=websecure"
        - "traefik.http.routers.portainer.tls.certresolver=letsencryptresolver"
        - "traefik.http.routers.portainer.service=portainer"
        - "traefik.http.services.portainer.loadbalancer.server.port=9000"

networks:
  network_public:
    external: true
    name: network_public

volumes:
  portainer_data:
    external: true
    name: portainer_data
EOF

docker stack deploy -c portainer.yaml portainer
echo "Portainer implantado com sucesso!"

# Configura o MCP Server
echo "Configurando MCP Server..."
sudo apt install -y nodejs npm

# Instala as dependências globais necessárias
echo "Instalando dependências do MCP Server..."
npm install -g @smithery/cli@latest

# Criar diretório para o MCP
mkdir -p ~/mcp-server
cd ~/mcp-server

# Cria o arquivo de configuração mcpjson
echo "Criando arquivo de configuração do MCP Server..."
cat <<EOF > mcpjson
{
  "mcpServers": {
    "github": {
      "command": "cmd",
      "args": [
        "/c",
        "npx",
        "-y",
        "@smithery/cli@latest",
        "run",
        "@dev-assistant-ai/github",
        "--key",
        "98498394-06fe-472e-9bf1-ca0bdcc64436"
      ]
    }
  }
}
EOF

# Cria arquivo de serviço systemd para o MCP Server
echo "Configurando MCP Server como serviço..."
cat <<EOF | sudo tee /etc/systemd/system/mcp-server.service
[Unit]
Description=MCP Server Service
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME/mcp-server
ExecStart=/usr/bin/npx mcp-server --config $HOME/mcp-server/mcpjson
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=mcp-server

[Install]
WantedBy=multi-user.target
EOF

# Configura e inicia o serviço
sudo systemctl daemon-reload
sudo systemctl enable mcp-server
sudo systemctl start mcp-server

# Cria Docker Stack para MCP Server
echo "Criando Docker Stack para MCP Server..."
cat <<EOF > mcp-server.yaml
version: "3.7"

services:
  mcp-server:
    image: node:20-alpine
    working_dir: /app
    command: sh -c "npm install -g @smithery/cli@latest && npx mcp-server --config /app/mcpjson"
    volumes:
      - ./mcpjson:/app/mcpjson
      - /var/run/docker.sock:/var/run/docker.sock
    deploy:
      mode: replicated
      replicas: 1
      placement:
        constraints: [node.role == manager]
      labels:
        - "traefik.enable=true"
        - "traefik.docker.network=network_public"
        - "traefik.http.routers.mcp.rule=Host(\`mcp.$DOMINIO\`)"
        - "traefik.http.routers.mcp.entrypoints=websecure"
        - "traefik.http.routers.mcp.tls.certresolver=letsencryptresolver"
        - "traefik.http.routers.mcp.service=mcp"
        - "traefik.http.services.mcp.loadbalancer.server.port=3000"
    networks:
      - network_public

networks:
  network_public:
    external: true
    name: network_public
EOF

docker stack deploy -c mcp-server.yaml mcp-stack
echo "MCP Server implantado com sucesso!"

echo "====================================================="
echo "Instalação concluída com sucesso!"
echo "Seus serviços estão disponíveis nos seguintes URLs:"
echo "Traefik: https://traefik.$DOMINIO"
echo "Portainer: https://portainer.$DOMINIO"
echo "MCP Server: https://mcp.$DOMINIO"
echo ""
echo "Para conectar seu Cursor IA ao MCP Server, use a URL: https://mcp.$DOMINIO"
echo "====================================================="