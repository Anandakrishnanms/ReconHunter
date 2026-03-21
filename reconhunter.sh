#!/bin/bash

# =========================
# Colors
# =========================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# =========================
# Banner Function
# =========================
banner() {
    clear
    echo -e "${RED}"
    echo "██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗██╗  ██╗██╗   ██╗███╗   ██╗████████╗███████╗██████╗ "
    echo "██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║██║  ██║██║   ██║████╗  ██║╚══██╔══╝██╔════╝██╔══██╗"
    echo "██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║███████║██║   ██║██╔██╗ ██║   ██║   █████╗  ██████╔╝"
    echo "██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║██╔══██║██║   ██║██║╚██╗██║   ██║   ██╔══╝  ██╔══██╗"
    echo "██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║██║  ██║╚██████╔╝██║ ╚████║   ██║   ███████╗██║  ██║"
    echo "╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
    echo -e "${NC}"

    echo -e "${CYAN}        >> ReconHunter - Advanced Recon Toolkit <<${NC}"
    echo -e "${YELLOW}        Masscan | Nmap | httpx | WhatWeb${NC}"
    echo -e "${MAGENTA}        Version: 2.1${NC}"
    echo -e "${WHITE}        Author: Zekken${NC}\n"
}

# =========================
# Dependency Checker
# =========================
install_tool() {
    tool=$1

    if ! command -v $tool &> /dev/null
    then
        echo -e "${RED}[!] $tool not found! Installing...${NC}"

        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            case $tool in
                nmap) sudo apt install -y nmap ;;
                masscan) sudo apt install -y masscan ;;
                whatweb) sudo apt install -y whatweb ;;
                httpx) 
                    sudo apt install -y golang
                    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
                    export PATH=$PATH:$(go env GOPATH)/bin
                ;;
            esac
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            brew install $tool
        else
            echo -e "${RED}[!] Unsupported OS${NC}"
            exit 1
        fi

        echo -e "${GREEN}[+] $tool installed!${NC}"
    else
        echo -e "${GREEN}[+] $tool already installed${NC}"
    fi
}

# =========================
# Start UI
# =========================
banner
echo -e "${GREEN}[$(date +%H:%M:%S)] Initializing ReconHunter...${NC}\n"

# =========================
# Install Dependencies
# =========================
install_tool nmap
install_tool masscan
install_tool whatweb
install_tool httpx

# =========================
# Input
# =========================
read -p "Enter target IP/domain: " target

echo -e "${MAGENTA}[+] Starting Recon Pipeline...${NC}"

# =========================
# Step 1: Masscan
# =========================
echo -e "${YELLOW}[1] Running Masscan...${NC}"

masscan_output=$(sudo masscan $target -p1-1000 --rate=1000 2>/dev/null)

ports=$(echo "$masscan_output" | grep "open" | awk '{print $4}' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

# =========================
# Fallback to Nmap if Masscan fails
# =========================
if [ -z "$ports" ]; then
    echo -e "${RED}[!] Masscan found nothing. Falling back to full Nmap scan...${NC}"

    nmap_full=$(nmap -p- --min-rate=1000 -T4 $target)

    ports=$(echo "$nmap_full" | grep open | awk '{print $1}' | cut -d'/' -f1 | tr '\n' ',' | sed 's/,$//')

    if [ -z "$ports" ]; then
        echo -e "${RED}[!] No open ports found even with Nmap!${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}[+] Open ports: $ports${NC}"

# =========================
# Step 2: Nmap Service Scan
# =========================
echo -e "${BLUE}[2] Running Nmap Service Detection...${NC}"

nmap_output=$(nmap -sV -p$ports $target)

echo "$nmap_output" | grep open

# =========================
# Extract HTTP Ports
# =========================
http_ports=$(echo "$nmap_output" | grep open | awk '{print $1,$3}' | grep -E "80|443|http" | cut -d'/' -f1)

# =========================
# Step 3: httpx
# =========================
echo -e "${CYAN}[3] Checking live web services...${NC}"

hosts=""
for port in $http_ports; do
    hosts+="$target:$port\n"
done

live_hosts=$(echo -e "$hosts" | httpx -silent | sort -u)

echo -e "${GREEN}[+] Live services:${NC}"
echo "$live_hosts"

# =========================
# Step 4: WhatWeb
# =========================
echo -e "${MAGENTA}[4] Detecting technologies...${NC}"

while read url; do
    [ -z "$url" ] && continue
    echo -e "${YELLOW}Scanning $url${NC}"
    whatweb "$url"
done <<< "$live_hosts"

echo -e "${GREEN}[+] Recon Completed Successfully!${NC}"
