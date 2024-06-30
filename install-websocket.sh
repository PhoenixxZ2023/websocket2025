#!/bin/bash

# Função para instalar dependências
install_dependencies() {
    # Verifica se o usuário é root
    if [ "$(id -u)" -ne 0 ]; então
        echo -e "\e[31mEste script deve ser executado como root\e[0m"
        exit 1
    fi

    # Atualiza os pacotes
    apt update && apt upgrade -y

    # Instala Node.js e npm
    curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
    apt install -y nodejs

    # Cria um diretório para o servidor WebSocket
    mkdir -p /opt/proxy-websocket
    cd /opt/proxy-websocket

    # Cria package.json
    cat <<EOL > package.json
{
  "name": "proxy-websocket",
  "version": "1.0.0",
  "description": "Servidor WebSocket básico",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "ws": "^8.0.0"
  }
}
EOL

    # Instala dependências
    npm install

    # Cria o servidor WebSocket com a porta especificada
    cat <<EOL > server.js
const WebSocket = require('ws');
const port = process.env.PORT || 8080;
const wss = new WebSocket.Server({ port: port });

wss.on('connection', ws => {
  ws.on('message', message => {
    console.log('received: %s', message);
  });
  ws.send('something');
});

console.log('WebSocket server running on port ' + port);
EOL

    # Cria um serviço systemd para o servidor WebSocket
    cat <<EOL > /etc/systemd/system/proxy-websocket.service
[Unit]
Description=Proxy WebSocket Server
After=network.target

[Service]
ExecStart=/usr/bin/npm start
WorkingDirectory=/opt/proxy-websocket
Restart=always
User=nobody
Group=nogroup
Environment=PATH=/usr/bin:/usr/local/bin
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOL

    # Carrega o serviço systemd
    systemctl daemon-reload

    echo -e "\e[32mInstalação concluída.\e[0m"
}

# Função para ativar o servidor
start_server() {
    systemctl start proxy-websocket
    systemctl enable proxy-websocket
    echo -e "\e[32mServidor WebSocket ativado.\e[0m"
}

# Função para desativar o servidor
stop_server() {
    systemctl stop proxy-websocket
    systemctl disable proxy-websocket
    echo -e "\e[31mServidor WebSocket desativado.\e[0m"
}

# Função para configurar a porta do servidor
configure_port() {
    read -p "Digite a porta desejada para o servidor WebSocket: " port
    sed -i "s/^Environment=NODE_ENV=production$/Environment=NODE_ENV=production\nEnvironment=PORT=$port/" /etc/systemd/system/proxy-websocket.service
    systemctl daemon-reload
    systemctl restart proxy-websocket
    echo -e "\e[32mServidor WebSocket configurado para usar a porta $port.\e[0m"
}

# Menu de opções
while true; do
    clear
    echo -e "\e[34m-----------------------------------\e[0m"
    echo -e "\e[34m|       Gerenciamento WebSocket      |\e[0m"
    echo -e "\e[34m-----------------------------------\e[0m"
    echo -e "\e[32m1.\e[0m Instalar dependências"
    echo -e "\e[32m2.\e[0m Ativar servidor WebSocket"
    echo -e "\e[32m3.\e[0m Desativar servidor WebSocket"
    echo -e "\e[32m4.\e[0m Configurar porta do servidor WebSocket"
    echo -e "\e[32m5.\e[0m Sair"
    echo -e "\e[34m-----------------------------------\e[0m"
    read -p "Escolha uma opção: " option

    case $option in
        1)
            install_dependencies
            read -p "Pressione Enter para continuar..."
            ;;
        2)
            start_server
            read -p "Pressione Enter para continuar..."
            ;;
        3)
            stop_server
            read -p "Pressione Enter para continuar..."
            ;;
        4)
            configure_port
            read -p "Pressione Enter para continuar..."
            ;;
        5)
            echo -e "\e[34mSaindo...\e[0m"
            exit 0
            ;;
        *)
            echo -e "\e[31mOpção inválida. Tente novamente.\e[0m"
            read -p "Pressione Enter para continuar..."
            ;;
    esac
done
