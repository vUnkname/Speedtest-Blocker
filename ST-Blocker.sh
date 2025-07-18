#!/bin/bash

RED="\033[0;31m"
GREEN="\033[0;32m"
GGREEN="\033[1;92m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
MAGENTA='\033[38;5;171m'
NC="\033[0m"

log() { echo -e "[${GREEN}✔${NC}] ${GREEN}$1${NC}"; }
warn() { echo -e "[${YELLOW}!${NC}] ${YELLOW}$1${NC}"; }
error() { echo -e "[${RED}✘${NC}] ${RED}$1${NC}"; }
point() { echo -e "\n[${BLUE}•${NC}] ${BLUE}$1${NC}\n"; }
plus() { echo -e "\n[${MAGENTA}•${NC}] ${MAGENTA}$1${NC}\n"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="ST-Blocker.sh"
CSV_NAME="speedtest_websites.csv"
LIST_URL="$INSTALL_DIR/$CSV_NAME"
CSV_URL="https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/speedtest_websites.csv"

IPTABLES_SAVE="/etc/iptables/rules.v4"
SERVER_IP=$(hostname -I | awk '{print $1}')

get_server_info() {
    local ip="$1"
    local timeout=5
    
    local apis=(
        "http://ip-api.com/json/$ip"
        "https://ipapi.co/$ip/json/"
        "https://ipinfo.io/$ip/json"
        "https://api.ipgeolocation.io/ipgeo?apiKey=free&ip=$ip"
    )
    
    for api in "${apis[@]}"; do
        local response
        if command -v curl >/dev/null 2>&1; then
            response=$(curl -sS --connect-timeout "$timeout" --max-time "$timeout" "$api" 2>/dev/null)
            elif command -v wget >/dev/null 2>&1; then
            response=$(wget -qO- --timeout="$timeout" "$api" 2>/dev/null)
        else
            warn "❌ Neither curl nor wget found for server info"
            SERVER_COUNTRY="Unknown"
            SERVER_ISP="Unknown"
            return 1
        fi
        
        if [[ -n "$response" && "$response" != *"error"* ]]; then
            
            if [[ "$api" == *"ip-api.com"* ]]; then
                if command -v jq >/dev/null 2>&1; then
                    SERVER_COUNTRY=$(echo "$response" | jq -r '.country // "Unknown"')
                    SERVER_ISP=$(echo "$response" | jq -r '.isp // "Unknown"')
                else
                    SERVER_COUNTRY=$(echo "$response" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
                    SERVER_ISP=$(echo "$response" | grep -o '"isp":"[^"]*"' | cut -d'"' -f4)
                fi
                elif [[ "$api" == *"ipapi.co"* ]]; then
                if command -v jq >/dev/null 2>&1; then
                    SERVER_COUNTRY=$(echo "$response" | jq -r '.country_name // "Unknown"')
                    SERVER_ISP=$(echo "$response" | jq -r '.org // "Unknown"')
                else
                    SERVER_COUNTRY=$(echo "$response" | grep -o '"country_name":"[^"]*"' | cut -d'"' -f4)
                    SERVER_ISP=$(echo "$response" | grep -o '"org":"[^"]*"' | cut -d'"' -f4)
                fi
                elif [[ "$api" == *"ipinfo.io"* ]]; then
                if command -v jq >/dev/null 2>&1; then
                    SERVER_COUNTRY=$(echo "$response" | jq -r '.country // "Unknown"')
                    SERVER_ISP=$(echo "$response" | jq -r '.org // "Unknown"')
                else
                    SERVER_COUNTRY=$(echo "$response" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
                    SERVER_ISP=$(echo "$response" | grep -o '"org":"[^"]*"' | cut -d'"' -f4)
                fi
                elif [[ "$api" == *"ipgeolocation.io"* ]]; then
                if command -v jq >/dev/null 2>&1; then
                    SERVER_COUNTRY=$(echo "$response" | jq -r '.country_name // "Unknown"')
                    SERVER_ISP=$(echo "$response" | jq -r '.isp // "Unknown"')
                else
                    SERVER_COUNTRY=$(echo "$response" | grep -o '"country_name":"[^"]*"' | cut -d'"' -f4)
                    SERVER_ISP=$(echo "$response" | grep -o '"isp":"[^"]*"' | cut -d'"' -f4)
                fi
            fi
            
            if [[ -n "$SERVER_COUNTRY" && "$SERVER_COUNTRY" != "Unknown" && "$SERVER_COUNTRY" != "null" ]]; then
                [[ -z "$SERVER_ISP" || "$SERVER_ISP" == "null" ]] && SERVER_ISP="Unknown"
                return 0
            fi
        fi
        
        warn "⚠️ Failed to get server info from $(echo "$api" | cut -d'/' -f3), trying next..."
    done
    
    warn "❌ All IP geolocation APIs failed"
    SERVER_COUNTRY="Unknown"
    SERVER_ISP="Unknown"
    return 1
}

get_server_info "$SERVER_IP"

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
}

update_from_repo() {
    point "🔄 Updating from repository..."
    
    SCRIPT_URL="https://raw.githubusercontent.com/vUnkname/Speedtest-Blocker/main/ST-Blocker.sh"
    TEMP_SCRIPT="/tmp/speedtest-blocker-latest.sh"
    
    if command -v curl >/dev/null 2>&1; then
        if curl -s -o "$TEMP_SCRIPT" "$SCRIPT_URL"; then
            log "✅ Latest script downloaded"
            cp "$TEMP_SCRIPT" "$INSTALL_DIR/$SCRIPT_NAME"
            chmod +x "$INSTALL_DIR/$SCRIPT_NAME"
            rm -f "$TEMP_SCRIPT"
        else
            error "❌ Failed to download latest script"
        fi
    fi
    
    check_and_download_csv
    log "🎯 Update completed!"
}

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        elif [ -f /etc/redhat-release ]; then
        OS="centos"
    else
        OS="unknown"
    fi
}

detect_firewall_mode() {
    if iptables -V 2>/dev/null | grep -q "nf_tables"; then
        if command -v nft >/dev/null 2>&1; then
            echo "nftables"
        else
            echo "iptables_nf_tables"
        fi
    else
        echo "iptables_legacy"
    fi
}

install_dependencies() {
    point "🔍 Checking and installing dependencies..."
    
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        PKG_UPDATE="apt update -y"
        PKG_INSTALL="apt install -y"
        DNS_PKG="dnsutils"
        elif [[ "$OS" == "centos" || "$OS" == "almalinux" || "$OS" == "rocky" ]]; then
        PKG_UPDATE="yum makecache"
        PKG_INSTALL="yum install -y"
        DNS_PKG="bind-utils"
    else
        error "Unsupported OS: $OS"
        exit 1
    fi
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR"
        log "📁 Created install directory: $INSTALL_DIR"
    fi
    
    $PKG_UPDATE
    
    for pkg in curl $DNS_PKG; do
        if ! command -v ${pkg%%-*} >/dev/null 2>&1; then
            plus "Installing $pkg..."
            $PKG_INSTALL $pkg
        else
            log "$pkg already installed."
        fi
    done
    
    if [[ "$FIREWALL_MODE" == iptables* ]]; then
        if ! command -v iptables >/dev/null 2>&1; then
            plus "Installing iptables..."
            $PKG_INSTALL iptables
        else
            log "iptables already installed."
        fi
        elif [[ "$FIREWALL_MODE" == "nftables" ]]; then
        if ! command -v nft >/dev/null 2>&1; then
            plus "Installing nftables..."
            $PKG_INSTALL nftables
        else
            log "nftables already installed."
        fi
    fi
}

check_and_download_csv() {
    local need_download=false
    
    if [[ ! -f "$LIST_URL" ]]; then
        warn "📄 CSV file not found, downloading..."
        need_download=true
    else
        local file_age=$(stat -c %Y "$LIST_URL" 2>/dev/null || echo 0)
        local current_time=$(date +%s)
        local age_hours=$(( (current_time - file_age) / 3600 ))
        
        if [[ $age_hours -gt 24 ]]; then
            warn "📅 CSV file is older than 24 hours ($age_hours hours), updating..."
            need_download=true
        else
            log "✅ CSV file is up to date (age: $age_hours hours)"
        fi
    fi
    
    if [[ "$need_download" == "true" ]]; then
        local download_success=false
        
        if command -v curl >/dev/null 2>&1; then
            if curl -s -o "$LIST_URL" "$CSV_URL"; then
                download_success=true
            fi
            elif command -v wget >/dev/null 2>&1; then
            if wget -q -O "$LIST_URL" "$CSV_URL"; then
                download_success=true
            fi
        else
            error "❌ Neither curl nor wget found. Cannot download CSV file."
            return 1
        fi
        
        if [[ "$download_success" == "true" ]]; then
            
            if [[ -f "$LIST_URL" ]]; then
                local line_count=$(wc -l < "$LIST_URL" 2>/dev/null || echo 0)
                local file_size=$(stat -c%s "$LIST_URL" 2>/dev/null || echo 0)
                
                if [[ $line_count -gt 5 && $file_size -gt 100 ]]; then
                    
                    if grep -qE '^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}' "$LIST_URL" 2>/dev/null; then
                        log "✅ CSV file downloaded and validated successfully ($line_count sites)"
                        return 0
                    else
                        warn "⚠️ Downloaded file doesn't contain valid domain patterns"
                    fi
                else
                    warn "⚠️ Downloaded file is too small or empty (lines: $line_count, size: $file_size bytes)"
                fi
            fi
            
            rm -f "$LIST_URL" 2>/dev/null
            error "❌ Downloaded file validation failed"
            return 1
        else
            error "❌ Failed to download CSV file"
            return 1
        fi
    fi
    
    return 0
}

check_list_url() {
    if ! check_and_download_csv; then
        error "❌ Cannot proceed without CSV file"
        read -p $'\n🔁 Press [Enter] to return to main menu...' key
        return 1
    fi
    
    if [[ ! -f "$LIST_URL" ]]; then
        error "❌ List file still not found: $LIST_URL"
        read -p $'\n🔁 Press [Enter] to return to main menu...' key
        return 1
    fi
}

filter_valid_ips() {
    grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$'
}

read_list() {
    if [[ "$LIST_URL" =~ ^https?:// ]]; then
        curl -s "$LIST_URL"
        elif [[ -f "$LIST_URL" ]]; then
        cat "$LIST_URL"
    else
        error "❌ Cannot read list. Invalid path or URL: $LIST_URL"
        return 1
    fi
}

block_with_iptables() {
    count=0
    failed=0
    sites_count=0
    
    check_list_url || return
    
    point "Using iptables to block..."
    
    total_sites=$(read_list | wc -l)
    log "📊 Total sites to process: $total_sites"
    
    while IFS= read -r site; do
        [[ -z "$site" ]] && continue
        ((sites_count++))
        log "[$sites_count/$total_sites] Blocking domain match: $site"
        iptables -A OUTPUT -p tcp -m string --string "$site" --algo bm --to 65535 -j REJECT
        
        ip_list=$(dig +short "$site" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
        if [[ -z "$ip_list" ]]; then
            warn "Could not resolve IP for $site"
            ((failed++))
            continue
        fi
        
        for ip in $ip_list; do
            log "  └─ Blocking IP: $ip"
            iptables -A OUTPUT -d "$ip" -j REJECT
            ((count++))
        done
    done < <(read_list)
    
    iptables-save > "$IPTABLES_SAVE"
    
    SERVICE_PATH="/etc/systemd/system/speedtest-blocker.service"
    if [ ! -f "$SERVICE_PATH" ]; then
        cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=SpeedTest Blocker Service
After=network-online.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/$SCRIPT_NAME
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload 2>/dev/null
        systemctl enable speedtest-blocker.service 2>/dev/null
        systemctl start speedtest-blocker.service 2>/dev/null
        log "🔧 SystemD service created and enabled"
    fi
    log "✅ Blocking complete. Sites processed: $sites_count | Total IPs blocked: $count | Failed resolutions: $failed"
    read -p $'\n🔁 Press [Enter] to return to main menu...' key
}

unblock_with_iptables() {
    count=0
    sites_count=0
    local something_removed=false
    
    point "Using iptables to Unblock..."
    
    if [[ "$EUID" -ne 0 ]]; then
        error "❌ You must run this script as root to modify iptables."
        return
    fi
    
    check_list_url || return
    
    total_sites=$(read_list | wc -l)
    log "📊 Total sites to process: $total_sites"
    
    while IFS= read -r site; do
        [[ -z "$site" ]] && continue
        ((sites_count++))
        log "[$sites_count/$total_sites] Unblocking domain match: $site"
        if iptables -D OUTPUT -p tcp -m string --string "$site" --algo bm --to 65535 -j REJECT 2>/dev/null; then
            something_removed=true
        fi
        
        ip_list=$(dig +short "$site" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
        for ip in $ip_list; do
            log "  └─ Unblocking IP: $ip"
            if iptables -D OUTPUT -d "$ip" -j REJECT 2>/dev/null; then
                ((count++))
                something_removed=true
            fi
        done
    done < <(read_list)
    
    SERVICE_PATH="/etc/systemd/system/speedtest-blocker.service"
    if systemctl is-active --quiet speedtest-blocker.service 2>/dev/null; then
        systemctl stop speedtest-blocker.service 2>/dev/null
        something_removed=true
    fi
    if systemctl is-enabled --quiet speedtest-blocker.service 2>/dev/null; then
        systemctl disable speedtest-blocker.service 2>/dev/null
        something_removed=true
    fi
    if [ -f "$SERVICE_PATH" ]; then
        rm -f "$SERVICE_PATH"
        systemctl daemon-reload 2>/dev/null
        log "🗑️ Service file removed."
        something_removed=true
    fi
    
    if [ "$something_removed" = true ]; then
        log "🔓 Unblocking complete. Sites processed: $sites_count | Total IPs unblocked: $count"
    else
        warn "⚠️ No speedtest blocking rules or services were found to remove."
    fi
    read -p $'\n🔁 Press [Enter] to return to main menu...' key
}

block_with_nftables() {
    count=0
    failed=0
    sites_count=0
    
    check_list_url || return
    
    point "Using nftables to block..."
    
    nft add table inet speedtest_block 2>/dev/null
    nft add chain inet speedtest_block output_block { type filter hook output priority 0 \; } 2>/dev/null
    
    total_sites=$(read_list | wc -l)
    log "📊 Total sites to process: $total_sites"
    
    while IFS= read -r site; do
        [[ -z "$site" ]] && continue
        ((sites_count++))
        log "[$sites_count/$total_sites] Blocking domain string match: $site"
        nft add rule inet speedtest_block output_block tcp dport 80 @th,64,512 "$site" reject 2>/dev/null
        
        ip_list=$(dig +short "$site" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$')
        if [[ -z "$ip_list" ]]; then
            warn "Could not resolve IP for $site"
            ((failed++))
            continue
        fi
        
        for ip in $ip_list; do
            log "  └─ Blocking IP: $ip"
            nft add rule inet speedtest_block output_block ip daddr $ip reject
            ((count++))
        done
    done < <(read_list)
    
    SERVICE_PATH="/etc/systemd/system/speedtest-blocker.service"
    if [ ! -f "$SERVICE_PATH" ]; then
        cat <<EOF > "$SERVICE_PATH"
[Unit]
Description=SpeedTest Blocker Service
After=network-online.target

[Service]
Type=simple
ExecStart=$INSTALL_DIR/$SCRIPT_NAME
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload 2>/dev/null
        systemctl enable speedtest-blocker.service 2>/dev/null
        systemctl start speedtest-blocker.service 2>/dev/null
        log "🔧 SystemD service created and enabled"
    fi
    
    log "✅ Blocking complete. Sites processed: $sites_count | Total IPs blocked: $count | Failed resolutions: $failed"
    read -p $'\n🔁 Press [Enter] to return to main menu...' key
}

unblock_with_nftables() {
    point "Using 'nfTables' to Unblock..."
    local something_removed=false
    
    if nft list tables | grep -q "speedtest_block"; then
        nft delete table inet speedtest_block
        log "✅ Speedtest block table removed from 'nfTables'."
        something_removed=true
    else
        warn "⚠️ No 'nfTables' block table found. Nothing to remove."
    fi
    
    SERVICE_PATH="/etc/systemd/system/speedtest-blocker.service"
    if systemctl is-active --quiet speedtest-blocker.service 2>/dev/null; then
        systemctl stop speedtest-blocker.service 2>/dev/null
        something_removed=true
    fi
    if systemctl is-enabled --quiet speedtest-blocker.service 2>/dev/null; then
        systemctl disable speedtest-blocker.service 2>/dev/null
        something_removed=true
    fi
    if [ -f "$SERVICE_PATH" ]; then
        rm -f "$SERVICE_PATH"
        systemctl daemon-reload 2>/dev/null
        log "🗑️ Service file removed."
        something_removed=true
    fi
    
    if [ "$something_removed" = true ]; then
        log "🔓 Unblocking complete. All nftables rules and service removed."
    else
        warn "⚠️ No speedtest blocking rules or services were found to remove."
    fi
    read -p $'\n🔁 Press [Enter] to return to main menu...' key
}

complete_cleanup() {
    point "🧹 Starting complete cleanup..."
    local something_removed=false
    
    if command -v iptables >/dev/null 2>&1; then
        log "Flushing all iptables rules..."
        iptables -F OUTPUT 2>/dev/null
        iptables -X 2>/dev/null
        something_removed=true
        if [ -f "$IPTABLES_SAVE" ]; then
            rm -f "$IPTABLES_SAVE"
            log "Removed iptables save file"
        fi
    fi
    
    if command -v nft >/dev/null 2>&1; then
        if nft list tables | grep -q "speedtest_block"; then
            nft delete table inet speedtest_block 2>/dev/null
            log "Removed nftables speedtest_block table"
            something_removed=true
        fi
    fi
    
    SERVICE_PATH="/etc/systemd/system/speedtest-blocker.service"
    if systemctl is-active --quiet speedtest-blocker.service 2>/dev/null; then
        systemctl stop speedtest-blocker.service 2>/dev/null
        log "Stopped speedtest-blocker service"
        something_removed=true
    fi
    if systemctl is-enabled --quiet speedtest-blocker.service 2>/dev/null; then
        systemctl disable speedtest-blocker.service 2>/dev/null
        log "Disabled speedtest-blocker service"
        something_removed=true
    fi
    if [ -f "$SERVICE_PATH" ]; then
        rm -f "$SERVICE_PATH"
        systemctl daemon-reload 2>/dev/null
        log "Removed service file"
        something_removed=true
    fi
    
    if [ -f "$INSTALL_DIR/$SCRIPT_NAME" ]; then
        rm -f "$INSTALL_DIR/$SCRIPT_NAME"
        log "Removed installed script"
        something_removed=true
    fi
    if [ -f "$LIST_URL" ]; then
        rm -f "$LIST_URL"
        log "Removed CSV file"
        something_removed=true
    fi
    
    if command -v iptables >/dev/null 2>&1; then
        iptables-save 2>/dev/null | grep -i speedtest | while read -r rule; do
            if [[ -n "$rule" ]]; then
                delete_rule=$(echo "$rule" | sed 's/^-A/-D/')
                iptables $delete_rule 2>/dev/null
                something_removed=true
            fi
        done
    fi
    
    if [ "$something_removed" = true ]; then
        log "🎯 Complete cleanup finished! All traces removed."
    else
        warn "⚠️ No speedtest blocking components were found to remove."
    fi
}

load_server_info_if_needed() {
    if [[ "$SERVER_COUNTRY" == "Unknown" ]]; then
        get_server_info "$SERVER_IP"
    fi
}

main_menu() {
    while true; do
        clear
        echo -e "│ ${GREEN}█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗${NC}"
        echo -e "│ ${GREEN}╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝${NC}"
        echo -e "│ ${GGREEN}███████╗   ████████╗           ${BLUE}██╗${NC}${GGREEN}██████╗ ██╗      ██████╗  ██████╗██╗  ██╗███████╗██████╗ ${NC}"
        echo -e "│ ${GGREEN}██╔════╝   ╚══██╔══╝          ${BLUE}██╔╝${NC}${GGREEN}██╔══██╗██║     ██╔═══██╗██╔════╝██║ ██╔╝██╔════╝██╔══██╗${NC}"
        echo -e "│ ${GGREEN}███████╗      ██║            ${BLUE}██╔╝${NC}${GGREEN} ██████╔╝██║     ██║   ██║██║     █████╔╝ █████╗  ██████╔╝${NC}"
        echo -e "│ ${GGREEN}╚════██║      ██║           ${BLUE}██╔╝${NC}${GGREEN}  ██╔══██╗██║     ██║   ██║██║     ██╔═██╗ ██╔══╝  ██╔══██╗${NC}"
        echo -e "│ ${GGREEN}███████║██╗   ██║   ██╗    ${BLUE}██╔╝${NC}${GGREEN}   ██████╔╝███████╗╚██████╔╝╚██████╗██║  ██╗███████╗██║  ██║${NC}"
        echo -e "│ ${GGREEN}╚══════╝╚═╝   ╚═╝   ╚═╝    ${BLUE}╚═╝${NC}${GGREEN}    ╚═════╝ ╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝${NC}"
        echo -e "│ ${GREEN}█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗█████╗${NC}"
        echo -e "│ ${GREEN}╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝╚════╝${NC}"
        echo "├───────────────────────────────────────────────────────────────────────────────────────────┤"
        echo -e "│${GGREEN}Server Country${NC}    | $SERVER_COUNTRY"
        echo -e "│${GGREEN}Server IP${NC}         | $SERVER_IP"
        echo -e "│${GGREEN}Server ISP${NC}        | $SERVER_ISP"
        echo "├───────────────────────────────────────────────────────────────────────────────────────────┤"
        echo -e "│ Telegram Channel : ${RED}NiGmaServices${NC} | Version : ${GREEN}1.0.0${NC}"
        echo "├───────────────────────────────────────────────────────────────────────────────────────────┤"
        echo -e "│ [  *Sponsor : t/@${YELLOW}CloudCubeServer${NC}  ]"
        echo "├───────────────────────────────────────────────────────────────────────────────────────────┤"
        echo -e "│ ${GGREEN}SPEEDTEST BLOCKER${NC}${RED}*${NC}"
        echo "│"
        echo -e "│  ${GGREEN}1${NC}. 🔒 Block SPEEDTEST Sites"
        echo -e "│  ${RED}2${NC}. 🔓 Unblock SPEEDTEST Sites"
        echo -e "│  ${BLUE}3${NC}. 🔄 Update Websites List"
        echo -e "│  ${MAGENTA}4${NC}. 🧹 Complete Cleanup"
        echo "│  0. ❌ Exit"
        echo "│"
        read -rp "└─  Enter your choice: " choice
        
        case "$choice" in
            1) [[ "$FIREWALL_MODE" == "nftables" ]] && block_with_nftables || block_with_iptables ;;
            2) [[ "$FIREWALL_MODE" == "nftables" ]] && unblock_with_nftables || unblock_with_iptables ;;
            3) check_and_download_csv; read -p $'\n🔁 Press [Enter] to return to main menu...' key ;;
            4) complete_cleanup; read -p $'\n🔁 Press [Enter] to return to main menu...' key ;;
            0) exit 0 ;;
            *) warn "Invalid option. Try again."; sleep 1 ;;
        esac
    done
}

check_root
detect_os
install_dependencies
FIREWALL_MODE=$(detect_firewall_mode)
main_menu