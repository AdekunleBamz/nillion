#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

ICON_TELEGRAM="🚀"
ICON_INSTALL="🛠️"
ICON_LOGS="📄"
ICON_STOP="⏹️"
ICON_START="▶️"
ICON_EXIT="❌"
ICON_STATUS="🔍"
ICON_RESTART="🔄"

draw_top_border() {
    echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${RESET}"
}

draw_middle_border() {
    echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${RESET}"
}

draw_bottom_border() {
    echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${RESET}"
}

print_telegram_icon() {
    echo -e "          ${MAGENTA}${ICON_TELEGRAM} Follow us on Telegram!${RESET}"
}

display_ascii() {
    echo -e "    ${RED}    ____  __ __    _   ______  ____  ___________${RESET}"
    echo -e "    ${GREEN}   / __ \\/ //_/   / | / / __ \\/ __ \\/ ____/ ___/${RESET}"
    echo -e "    ${BLUE}  / / / / ,<     /  |/ / / / / / / / __/  \\__ \\ ${RESET}"
    echo -e "    ${YELLOW} / /_/ / /| |   / /|  / /_/ / /_/ / /___ ___/ / ${RESET}"
    echo -e "    ${MAGENTA}/_____/_/ |_|  /_/ |_/\____/_____/_____//____/  ${RESET}"
}

show_menu() {
    clear
    draw_top_border
    display_ascii
    draw_middle_border
    print_telegram_icon
    echo -e "    ${BLUE}Subscribe to our channel: ${YELLOW}https://t.me/dknodes${RESET}"
    draw_middle_border
    echo -e "    ${GREEN}Hello, friend! This is the Nillion Node Manager.${RESET}"
    draw_middle_border
    echo -e "    ${YELLOW}Select an option:${RESET}"
    echo
    echo -e "    ${CYAN}1.${RESET} ${ICON_INSTALL} Install Node"
    echo -e "    ${CYAN}2.${RESET} ${ICON_START} Start Node"
    echo -e "    ${CYAN}3.${RESET} ${ICON_LOGS} View Node Logs"
    echo -e "    ${CYAN}4.${RESET} ${ICON_STOP} Stop and Remove Node"
    echo -e "    ${CYAN}5.${RESET} ${ICON_STATUS} Check Registration Status"
    echo -e "    ${CYAN}6.${RESET} ${ICON_RESTART} Restart Node"
    echo -e "    ${CYAN}0.${RESET} ${ICON_EXIT} Exit"
    echo
    draw_bottom_border
    echo -ne "    ${YELLOW}Enter your choice [0-6]:${RESET} "
    read choice
}

init_install() {
    exists() {
        command -v "$1" >/dev/null 2>&1
    }

    is_installed() {
        dpkg -s "$1" >/dev/null 2>&1
    }

    if ! exists curl; then
        if ! sudo apt update && sudo apt install curl -y < "/dev/null"; then
            echo "Failed to install curl. Exiting."
            exit 1
        fi
    fi

    cd "$HOME"

    DOCKER_PACKAGES=("docker-ce" "docker-ce-cli" "containerd.io" "docker-buildx-plugin" "docker-compose-plugin")
    docker_installed=true

    for pkg in "${DOCKER_PACKAGES[@]}"; do
        if ! is_installed "$pkg"; then
            docker_installed=false
            break
        fi
    done

    if [ "$docker_installed" = false ]; then
        echo "Installing Docker..."
        sudo install -m 0755 -d /etc/apt/keyrings
        sudo rm -f /etc/apt/keyrings/docker.gpg
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        sudo chmod a+r /etc/apt/keyrings/docker.gpg
        echo \
            "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
            $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        sudo apt update
        sudo apt install "${DOCKER_PACKAGES[@]}" -y
    fi

    if exists docker; then
        sudo docker --version
    else
        echo "Docker was not installed correctly. Exiting."
        exit 1
    fi

    sudo docker pull nillion/verifier:v1.0.1

    mkdir -p "$HOME/nillion/verifier"
    sudo docker run -v "$HOME/nillion/verifier:/var/tmp" nillion/verifier:v1.0.1 initialise
}

install_node() {
    echo -e "${GREEN}🛠️  Installing node...${RESET}"
    init_install
    echo -e "${GREEN}✅ Node installed successfully.${RESET}"
    read -p "Press Enter to return to the menu..."
}

start_node() {
    echo -e "${GREEN}▶️  Starting node...${RESET}"
    sudo docker run -d --name nillion -v "$HOME/nillion/verifier:/var/tmp" nillion/verifier:v1.0.1 verify --rpc-endpoint "https://testnet-nillion-rpc.lavenderfive.com"
    echo -e "${GREEN}✅ Node started.${RESET}"
    read -p "Press Enter to return to the menu..."
}

view_logs() {
    echo -e "${GREEN}📄 Viewing logs...${RESET}"
    sudo docker logs -f nillion --tail=50
    read -p "Press Enter to return to the menu..."
}

stop_node() {
    echo -e "${GREEN}⏹️  Stopping and removing node...${RESET}"
    sudo docker stop nillion
    sudo docker rm -f nillion
    echo -e "${GREEN}✅ Node stopped and removed.${RESET}"
    read -p "Press Enter to return to the menu..."
}

check_registration_status() {
    echo -e "${GREEN}🔍 Checking registration status...${RESET}"
    sudo docker logs --tail=1000000 nillion | grep -A 2 Registered | tail -3
    read -p "Press Enter to return to the menu..."
}

restart_node() {
    echo -e "${GREEN}🔄 Restarting node...${RESET}"
    sudo docker restart nillion
    echo -e "${GREEN}✅ Node restarted.${RESET}"
    read -p "Press Enter to return to the menu..."
}

remove_node() {
    echo -e "${GREEN}🗑️  Removing node...${RESET}"
    sudo docker rm -f nillion
    echo -e "${GREEN}✅ Node removed.${RESET}"
    read -p "Press Enter to return to the menu..."
}

while true; do
    show_menu
    case $choice in
        1) install_node ;;
        2) start_node ;;
        3) view_logs ;;
        4) stop_node ;;
        5) check_registration_status ;;
        6) restart_node ;;
        0)
            echo -e "${GREEN}❌ Exiting...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Invalid option. Please try again.${RESET}"
            read -p "Press Enter to continue..."
            ;;
    esac
done
