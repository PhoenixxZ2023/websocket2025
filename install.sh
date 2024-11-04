#!/bin/bash

# Constantes
PYTHON_SCRIPT_URL="https://github.com/PhoenixxZ2023/websocket2025/raw/main/agn_websocket.py"
AGN_MANAGER_SCRIPT_URL="https://github.com/PhoenixxZ2023/websocket2025/raw/main/agnws_manager.sh"
INSTALL_DIR="/opt/agn_websocket"
SYSTEMD_SERVICE_FILE="/etc/systemd/system/agn-websocket.service"
PYTHON_BIN=$(command -v python3)  # Certifique-se de que o Python3 está disponível
AGN_MANAGER_SCRIPT="agnws_manager.sh"
AGN_MANAGER_PATH="$INSTALL_DIR/$AGN_MANAGER_SCRIPT"
AGN_MANAGER_LINK="/usr/local/bin/websocket"

# Função para verificar a compatibilidade do sistema operacional
check_compatibility() {
    local os_version
    os_version=$(lsb_release -rs | cut -d. -f1)
    if [[ "$os_version" != "20" && "$os_version" != "22" ]]; then
        echo -e "\033[1;31mEste script é compatível apenas com o Ubuntu 20 e 22.\033[0m"
        exit 1
    fi
}

# Função para instalar pacotes necessários
install_required_packages() {
    echo -e "\033[1;34mInstalando pacotes necessários...\033[0m"
    apt-get update -qq
    apt-get install -y python3-pip dos2unix wget &>/dev/null
    # Verifica se o pip3 foi instalado corretamente
    if ! command -v pip3 &>/dev/null; then
        echo -e "\033[1;31mErro: pip3 não foi instalado corretamente.\033[0m"
        exit 1
    fi
    pip3 install --upgrade pip &>/dev/null
    pip3 install websocket-client &>/dev/null  # Ajuste conforme necessário
}

# Função para baixar o script Python do proxy usando wget
download_agn_websocket() {
    echo -e "\033[1;34mBaixando script Python do proxy de $PYTHON_SCRIPT_URL...\033[0m"
    wget -q -O "$INSTALL_DIR/agn_websocket.py" "$PYTHON_SCRIPT_URL"
}

# Função para baixar o script agnws_manager.sh usando wget
download_agnws_manager() {
    echo -e "\033[1;34mBaixando $AGN_MANAGER_SCRIPT de $AGN_MANAGER_SCRIPT_URL...\033[0m"
    wget -q -O "$AGN_MANAGER_PATH" "$AGN_MANAGER_SCRIPT_URL"
    chmod +x "$AGN_MANAGER_PATH"
    ln -sf "$AGN_MANAGER_PATH" "$AGN_MANAGER_LINK"
    convert_to_unix_line_endings "$AGN_MANAGER_PATH"
}

# Função para converter o script para terminação de linha Unix
convert_to_unix_line_endings() {
    local file="$1"
    echo -e "\033[1;34mConvertendo $file para terminações de linha Unix...\033[0m"
    dos2unix "$file" &>/dev/null
}

# Função para iniciar o serviço systemd
start_systemd_service() {
    echo -e "\033[1;34mIniciando o serviço agn-websocket...\033[0m"
    systemctl start agn-websocket
    systemctl status agn-websocket --no-pager
}

# Função para instalar o serviço systemd
install_systemd_service() {
    echo -e "\033[1;34mCriando arquivo de serviço systemd...\033[0m"
    cat > "$SYSTEMD_SERVICE_FILE" <<EOF
[Unit]
Description=Python Proxy Service
After=network.target

[Service]
ExecStart=$PYTHON_BIN $INSTALL_DIR/agn_websocket.py 8098
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF
    echo -e "\033[1;34mRecarregando daemon do systemd...\033[0m"
    systemctl daemon-reload
    echo -e "\033[1;34mHabilitando o serviço agn-websocket...\033[0m"
    systemctl enable agn-websocket
}

# Função para exibir banner
display_banner() {
    cat << "EOF"
**********************************************
*                                            *
*                WEBSOCKET 2025                  *
*     Visite-me no Telegram: @TUBONET2023    *
*                                            *
**********************************************
EOF
    echo
}

# Função para exibir resumo da instalação
display_installation_summary() {
    echo -e "\033[1;32mInstalação concluída com sucesso!\033[0m"
    echo
    echo "Script agn_websocket.py instalado em: $INSTALL_DIR"
    echo "Script $AGN_MANAGER_SCRIPT instalado em: $AGN_MANAGER_PATH"
    echo "Use o comando 'websocket menu' para gerenciar o serviço WebSocket."
}

# Função principal
main() {
    display_banner

    # Verificar compatibilidade do sistema operacional
    check_compatibility

    # Instalar pacotes necessários
    install_required_packages

    # Verificar se o Python 3 está disponível
    if [ -z "$PYTHON_BIN" ]; then
        echo -e "\033[1;31mErro: Python 3 não está instalado ou não foi encontrado no PATH. Instale o Python 3.\033[0m"
        exit 1
    fi

    # Criar diretório de instalação
    echo -e "\033[1;34mCriando diretório de instalação: $INSTALL_DIR\033[0m"
    mkdir -p "$INSTALL_DIR"

    # Baixar script Python do proxy
    download_agn_websocket

    # Baixar script agnws_manager.sh
    download_agnws_manager

    # Instalar serviço systemd
    install_systemd_service
    
    # Iniciar serviço systemd
    start_systemd_service

    # Exibir resumo da instalação
    display_installation_summary
}

# Executar função principal
main
