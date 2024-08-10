#!/bin/bash

fun_wsproxy() {
    CYAN=$(tput setaf 6)
    GREEN=$(tput setaf 2)
    RED=$(tput setaf 1)
    YELLOW=$(tput setaf 3)
    RESET=$(tput sgr0)

    instalar_pacotes() {
        echo "${YELLOW}Instalando pacotes necessários...${RESET}"
        if command -v apt-get &>/dev/null; then
            sudo apt-get -qq update
            sudo apt-get -qq -y install python3 python3-pip
        elif command -v yum &>/dev/null; then
            sudo yum -q -y update
            sudo yum -q -y install python3 python3-pip
        else
            echo "${RED}Gerenciador de pacotes não suportado. Por favor, instale Python3 e pip manualmente.${RESET}"
            exit 1
        fi
    }

    baixar_wsproxy() {
        echo "${YELLOW}Baixando script de proxy WebSocket...${RESET}"
        wget -O /root/wsproxy.py https://github.com/PhoenixxZ2023/websocket2025/raw/main/wsproxy.py
    }

    configurar_wsproxy() {
        pip install websockets
        echo "${CYAN}Configurando o proxy WebSocket...${RESET}"

        read -p "${CYAN}Digite o nome do host como CDN: ${RESET}" cdn_host
        read -p "${CYAN}Digite o SNI Host: ${RESET}" sni_host
        read -p "${CYAN}Digite a porta SSH: ${RESET}" ssh_port

        perguntar_porta_http() {
            while true; do
                read -p "${CYAN}Digite a porta HTTP/HTTPS desejada (ex.: 443): ${RESET}" http_port

                if ! [[ "$http_port" =~ ^[0-9]+$ ]]; then
                    echo "${RED}Entrada inválida. Por favor, insira um número de porta válido.${RESET}"
                elif ((http_port < 1 || http_port > 65535)); then
                    echo "${RED}O número da porta deve estar entre 1 e 65535.${RESET}"
                else
                    break
                fi
            done
        }

        echo "${CYAN}Por favor, selecione as portas HTTP/HTTPS:${RESET}"
        echo "${YELLOW}Portas HTTP comuns: 80, 8080, 8880, 2052, 2082, 2086, 2095${RESET}"
        echo "${YELLOW}Portas HTTPS comuns: 443, 2053, 2083, 2087, 2096, 8443${RESET}"

        perguntar_porta_http

        echo "RESPONSE = \"HTTP/1.1 101 <font color='null'></font>\"" >> /root/wsproxy.py
        echo "DEFAULT_HOST = \"$sni_host:$ssh_port\"" >> /root/wsproxy.py

        echo "[Unit]
Description=Servidor Proxy WebSocket
After=network.target

[Service]
Type=simple
User=$(whoami)
WorkingDirectory=$(pwd)
ExecStart=/usr/bin/python3 /root/wsproxy.py -p $http_port -s $ssh_port
Restart=always

[Install]
WantedBy=multi-user.target" | sudo tee /etc/systemd/system/wsproxy.service > /dev/null

        sudo systemctl enable wsproxy
        sudo systemctl start wsproxy

        echo "${YELLOW}O serviço de proxy WebSocket foi iniciado e ativado.${RESET}"
    }

    gerar_payload_httpinjector() {
        echo "Gerando payload para o HTTP Injector..."
        echo "================ Payload HTTP Injector ================"
        echo "Hostname: $cdn_host"
        echo "Porta: $http_port"
        echo "SNI: $sni_host"
        echo ""
        echo "Payload: GET / HTTP/1.1 [lf]Host: $cdn_host [lf][lf]"
        echo "======================================================"
    }

    iniciar_wsproxy() {
        sudo systemctl start wsproxy
        echo "${YELLOW}O serviço de proxy WebSocket foi iniciado.${RESET}"
    }

    parar_wsproxy() {
        sudo systemctl stop wsproxy
        echo "${YELLOW}O serviço de proxy WebSocket foi parado.${RESET}"
    }

    reiniciar_wsproxy() {
        sudo systemctl restart wsproxy
        echo "${YELLOW}O serviço de proxy WebSocket foi reiniciado.${RESET}"
    }

    desinstalar_wsproxy() {
        sudo systemctl stop wsproxy
        sudo systemctl disable wsproxy
        sudo rm /etc/systemd/system/wsproxy.service
        echo "${YELLOW}O proxy WebSocket foi desinstalado.${RESET}"
    }

    instalar_pacotes

    if ! command -v python3 &>/dev/null; then
        echo -e "${RED}Python3 não está instalado. Abortando...${RESET}"
        exit 1
    fi

    clear

    PS3="${CYAN}Selecione uma opção: ${RESET}"
    
    echo "${GREEN}=================================================${RESET}"
    echo "${CYAN}                MENU PRINCIPAL                    ${RESET}"
    echo "${GREEN}=================================================${RESET}"

    select opt in \
        "1. Instalar Proxy WebSocket" \
        "2. Iniciar Proxy WebSocket" \
        "3. Parar Proxy WebSocket" \
        "4. Reiniciar Proxy WebSocket" \
        "5. Desinstalar Proxy WebSocket" \
        "6. Gerar Payload HTTP Injector" \
        "7. Sair"; do
        
        case $opt in
            "1. Instalar Proxy WebSocket")
                baixar_wsproxy
                configurar_wsproxy
                ;;
            "2. Iniciar Proxy WebSocket")
                iniciar_wsproxy
                ;;
            "3. Parar Proxy WebSocket")
                parar_wsproxy
                ;;
            "4. Reiniciar Proxy WebSocket")
                reiniciar_wsproxy
                ;;
            "5. Desinstalar Proxy WebSocket")
                desinstalar_wsproxy
                ;;
            "6. Gerar Payload HTTP Injector")
                gerar_payload_httpinjector
                ;;
            "7. Sair")
                break
                ;;
            *)
                echo -e "${RED}Opção inválida. Por favor, selecione novamente.${RESET}"
                ;;
        esac
    done

    echo -e "${GREEN}A instalação e configuração do proxy WebSocket foram concluídas com sucesso.${RESET}"
    echo -e "${GREEN}Para acessar o menu principal novamente, digite:${RESET} ${CYAN}socket${RESET}"
}

fun_wsproxy
