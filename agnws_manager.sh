#!/bin/bash

# Constantes
AGN_WEBSOCKET_SERVICE="agn-websocket"
PYTHON_SCRIPT_PATH="/opt/agn_websocket/agn_websocket.py"

# Função para exibir o banner
display_banner() {
    echo -e "\033[1;36m┃*************************************************\033[0m"
    echo -e "\033[1;36m┃\033[0;32m                  KHALED AGN                   \033[0m"
    echo -e "\033[1;36m┃\033[0;32m        VISITE-ME NO TELEGRAM: @khaledagn      \033[0m"
    echo -e "\033[1;36m┃*************************************************\033[0m"
}

# Função para exibir o menu
show_menu() {
    clear
    display_banner
    echo -e "\033[1;36m┃ \033[1;34mGERENCIADOR DE VPN WEBSOCKET\033[0m"
    echo -e "\033[1;36m┃ \033[1;33m1) \033[1;32mVERIFICAR STATUS DO SERVIDOR\033[0m"
    echo -e "\033[1;36m┃ \033[1;33m2) \033[1;32mALTERAR PORTA DE ESCUTA\033[0m"
    echo -e "\033[1;36m┃ \033[1;33m3) \033[1;32mREINICIAR SERVIÇO WEBSOCKET\033[0m"
    echo -e "\033[1;36m┃ \033[1;33m4) \033[1;32mDESINSTALAR WEBSOCKET\033[0m"
    echo -e "\033[1;36m┃ \033[1;33m5) \033[1;32mINFORMAÇÕES DO SERVIDOR\033[0m"
    echo -e "\033[1;36m┃ \033[1;33m6) \033[1;32mSAIR\033[0m"
}

# Função para verificar o status do servidor
check_server_status() {
    echo -e "\033[1;33m┃ STATUS DO SERVIDOR:\033[0m"
    systemctl is-active $AGN_WEBSOCKET_SERVICE
}

# Função para alterar a porta de escuta
change_listening_port() {
    read -p $'\033[1;36m┃ DIGITE A NOVA PORTA DE ESCUTA DO WEBSOCKET: \033[0m' new_port

    if ! [[ "$new_port" =~ ^[0-9]+$ ]] || ((new_port < 1 || new_port > 65535)); then
        echo -e "\033[1;36m┃\033[0;31m ERRO: POR FAVOR, INSIRA UM NÚMERO DE PORTA VÁLIDO ENTRE 1 E 65535.\033[0m"
        return
    fi

    if [ -f "$PYTHON_SCRIPT_PATH" ]; then
        sed -i "s/^LISTENING_PORT = .*/LISTENING_PORT = $new_port/" "$PYTHON_SCRIPT_PATH"
        echo -e "\033[1;36m┃\033[0;32m PORTA DE ESCUTA DO WEBSOCKET ALTERADA PARA $new_port.\033[0m"
        restart_websocket_service
    else
        echo -e "\033[1;36m┃\033[0;31m ERRO: ARQUIVO $PYTHON_SCRIPT_PATH NÃO ENCONTRADO.\033[0m"
    fi
}

# Função para reiniciar o serviço WebSocket
restart_websocket_service() {
    echo -e "\033[1;36m┃\033[0;34m REINICIANDO O SERVIÇO $AGN_WEBSOCKET_SERVICE...\033[0m"
    if systemctl restart $AGN_WEBSOCKET_SERVICE; then
        echo -e "\033[1;36m┃\033[0;32m SERVIÇO REINICIADO COM SUCESSO.\033[0m"
    else
        echo -e "\033[1;36m┃\033[0;31m FALHA AO REINICIAR O SERVIÇO.\033[0m"
    fi
    systemctl status $AGN_WEBSOCKET_SERVICE --no-pager
}

# Função para desinstalar o script de proxy
uninstall_proxy_script() {
    echo -e "\033[1;36m┃\033[0;33m PARANDO O SERVIÇO $AGN_WEBSOCKET_SERVICE...\033[0m"
    systemctl stop $AGN_WEBSOCKET_SERVICE

    echo -e "\033[1;36m┃\033[0;33m DESATIVANDO O SERVIÇO $AGN_WEBSOCKET_SERVICE...\033[0m"
    systemctl disable $AGN_WEBSOCKET_SERVICE

    echo -e "\033[1;36m┃\033[0;33m REMOVENDO ARQUIVOS DO PROXY PYTHON...\033[0m"
    rm -rf "/opt/agn_websocket"
    rm -f /usr/local/bin/websocket

    echo -e "\033[1;36m┃\033[0;33m REMOVENDO ARQUIVO DE SERVIÇO DO SYSTEMD...\033[0m"
    rm -f "/etc/systemd/system/$AGN_WEBSOCKET_SERVICE.service"

    echo -e "\033[1;36m┃\033[0;32m SCRIPT DE PROXY PYTHON DESINSTALADO.\033[0m"
}

# Função para exibir informações do servidor
server_information() {
    echo -e "\033[1;33m┃ INFORMAÇÕES DO SERVIDOR:\033[0m\n"

    if systemctl is-active --quiet $AGN_WEBSOCKET_SERVICE; then
        echo -e "\033[1;36m┃ STATUS DO SERVIÇO WEBSOCKET: \033[0;32mATIVO\033[0m"
    else
        echo -e "\033[1;36m┃ STATUS DO SERVIÇO WEBSOCKET: \033[0;31mINATIVO\033[0m"
    fi

    if [ -f "$PYTHON_SCRIPT_PATH" ]; then
        current_port=$(grep -oP '(?<=LISTENING_PORT = )[0-9]+' "$PYTHON_SCRIPT_PATH")
        echo -e "\033[1;36m┃ PORTA DE ESCUTA ATUAL: \033[0;34m$current_port\033[0m"
    else
        echo -e "\033[1;36m┃ PORTA DE ESCUTA ATUAL: \033[0;31mINDISPONÍVEL (ARQUIVO DE SCRIPT NÃO ENCONTRADO)\033[0m"
    fi
}

# Função principal
main() {
    if [ "$1" = "menu" ]; then
        while true; do
            show_menu
            read -p $'\033[1;36m┃ ESCOLHA UMA OPÇÃO: \033[0m' choice

            case $choice in
                1) check_server_status ;;
                2) change_listening_port ;;
                3) restart_websocket_service ;;
                4) uninstall_proxy_script; break ;;
                5) server_information ;;
                6) echo -e "\033[1;36m┃\033[0;34m SAINDO...\033[0m"; break ;;
                *) echo -e "\033[1;36m┃\033[0;31m OPÇÃO INVÁLIDA. POR FAVOR, ESCOLHA UMA OPÇÃO VÁLIDA.\033[0m" ;;
            esac

            read -n 1 -s -r -p $'\033[1;36m┃ PRESSIONE QUALQUER TECLA PARA CONTINUAR...\033[0m'
            echo
        done
    else
        echo -e "\033[1;36m┃\033[0;31m USO: $0 MENU\033[0m"
    fi
}

# Executa a função principal com os argumentos
main "$@"
