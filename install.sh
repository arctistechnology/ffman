#!/bin/bash

set -e

REPO="arctistechnology/ffman"
INSTALL_DIR="/opt/ffman"
SERVICE_NAME="ffman"
DOWNLOAD_URL="https://github.com/${REPO}/releases/latest/download/ffman-linux-x86_64.tar.gz"
TMP_DIR="/tmp/ffman-update-$$"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'
BOLD='\033[1m'

IS_UPDATE=false
SERVICE_WAS_RUNNING=false
SERVICE_PORT="7080"
UPDATED_FILES=()
NEW_FILES=()

print_banner() {
    clear
    echo ""
    echo -e "${CYAN}"
    echo "     _____ _____ __  __             "
    echo "    |  ___|  ___|  \/  | __ _ _ __  "
    echo "    | |_  | |_  | |\/| |/ _\` | '_ \ "
    echo "    |  _| |  _| | |  | | (_| | | | |"
    echo "    |_|   |_|   |_|  |_|\__,_|_| |_|"
    echo -e "${NC}"
    echo -e "    ${CYAN}Stream Transcoder Installation Script${NC}"
    echo -e "    ─────────────────────────────────────"
    echo ""
}

log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_system() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$PRETTY_NAME
    else
        OS_NAME="Unknown Linux"
    fi
    
    ARCH=$(uname -m)
    if [ "$ARCH" != "x86_64" ]; then
        log_error "Unsupported architecture: ${ARCH}. Only x86_64 is supported."
        exit 1
    fi
    
    log_info "System: ${OS_NAME} (${ARCH})"
    sleep 0.5
}

check_glibc() {
    local glibc_version=$(ldd --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+' | head -1)
    
    if [ -z "$glibc_version" ]; then
        log_error "Could not determine GLIBC version"
        exit 1
    fi
    
    local required_version="2.28"
    
    if [ "$(printf '%s\n' "$required_version" "$glibc_version" | sort -V | head -n1)" != "$required_version" ]; then
        log_error "GLIBC version $glibc_version is too old!"
        echo ""
        echo -e "${YELLOW}FFMan requires GLIBC $required_version or higher${NC}"
        echo -e "${YELLOW}Minimum supported systems:${NC}"
        echo "  • Ubuntu 20.04+"
        echo "  • Debian 10+"
        echo "  • CentOS/RHEL 8+"
        echo ""
        exit 1
    fi
    
    log_success "GLIBC version $glibc_version is compatible"
    sleep 0.5
}

get_network_info() {
    local default_ip=$(ip route get 1 2>/dev/null | awk '{print $(NF-2);exit}')
    if [ -z "$default_ip" ]; then
        default_ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    if [ -z "$default_ip" ]; then
        default_ip="localhost"
    fi
    echo "$default_ip"
}

get_existing_port() {
    if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
        local port=$(grep -oP '(?<=--port )\d+' "/etc/systemd/system/${SERVICE_NAME}.service" 2>/dev/null)
        if [ -n "$port" ]; then
            echo "$port"
            return
        fi
    fi
    echo "7080"
}

detect_installation() {
    if [ -d "${INSTALL_DIR}" ]; then
        IS_UPDATE=true
        log_info "Existing installation found at ${INSTALL_DIR}"
        
        SERVICE_PORT=$(get_existing_port)
        log_info "Service port: ${SERVICE_PORT}"
        
        if systemctl is-active --quiet ${SERVICE_NAME} 2>/dev/null; then
            SERVICE_WAS_RUNNING=true
            log_success "FFMan service is currently running"
        else
            log_warning "FFMan service is not running"
        fi
    else
        IS_UPDATE=false
        log_info "No existing installation found"
    fi
}

stop_service() {
    if [ "$SERVICE_WAS_RUNNING" = true ]; then
        log_info "Stopping FFMan service for update..."
        systemctl stop ${SERVICE_NAME} 2>/dev/null || true
        sleep 2
        log_success "Service stopped"
    fi
}

download_archive() {
    log_info "Downloading latest release..."
    
    mkdir -p "${TMP_DIR}"
    local archive_path="${TMP_DIR}/ffman.tar.gz"
    
    curl -L -# -o "${archive_path}" "${DOWNLOAD_URL}" 2>&1 | \
    while IFS= read -r line; do
        if [[ "$line" =~ ^[#]+ ]]; then
            percent=$(echo "$line" | grep -o "[0-9]*\.[0-9]" | head -1)
            if [ -n "$percent" ]; then
                printf "\r  [-] Downloading... %.0f%%" "$percent"
            fi
        fi
    done
    
    if [ ! -f "${archive_path}" ] || [ ! -s "${archive_path}" ]; then
        printf "\r"
        log_error "Download failed                           "
        cleanup_and_exit 1
    fi
    
    local filesize=$(ls -lh "${archive_path}" | awk '{print $5}')
    printf "\r  [✓] Downloaded: %-20s\n" "${filesize}"
}

extract_archive() {
    log_info "Extracting archive..."
    sleep 0.3
    
    tar -xzf "${TMP_DIR}/ffman.tar.gz" -C "${TMP_DIR}" || {
        log_error "Extraction failed"
        cleanup_and_exit 1
    }
    
    rm -f "${TMP_DIR}/ffman.tar.gz"
    log_success "Extraction completed"
    sleep 0.5
}

install_files() {
    if [ "$IS_UPDATE" = true ]; then
        log_info "Updating files..."
    else
        log_info "Installing files..."
    fi
    
    mkdir -p "${INSTALL_DIR}"
    
    cd "${TMP_DIR}"
    local files=$(find . -type f -printf '%P\n' | sort)
    local total=$(echo "$files" | wc -l)
    local count=0
    
    echo ""
    if [ "$IS_UPDATE" = true ]; then
        echo -e "${YELLOW}         Update Progress                ${NC}"
        echo -e "${YELLOW}────────────────────────────────────────${NC}"
    else
        echo -e "${GREEN}      Installation Progress             ${NC}"
        echo -e "${GREEN}────────────────────────────────────────${NC}"
    fi
    echo ""
    
    while IFS= read -r file; do
        count=$((count + 1))
        local src="${TMP_DIR}/${file}"
        local dst="${INSTALL_DIR}/${file}"
        local dst_dir=$(dirname "${dst}")
        
        mkdir -p "${dst_dir}"
        
        if [ -f "${dst}" ]; then
            if ! cmp -s "${src}" "${dst}"; then
                cp -f "${src}" "${dst}"
                UPDATED_FILES+=("${file}")
                echo -e "  [${count}/${total}] ${GREEN}↻${NC} ${file}"
            else
                echo -e "  [${count}/${total}] ${CYAN}=${NC} ${file} ${CYAN}(unchanged)${NC}"
            fi
        else
            cp -f "${src}" "${dst}"
            NEW_FILES+=("${file}")
            echo -e "  [${count}/${total}] ${GREEN}+${NC} ${file} ${GREEN}(new)${NC}"
        fi
    done <<< "$files"
    
    echo ""
    if [ "$IS_UPDATE" = true ]; then
        log_success "Files updated successfully"
        sleep 0.5
    else
        log_success "Files installed successfully"
        sleep 0.5
    fi
}

setup_service() {
    log_info "Configuring systemd service..."
    sleep 0.3
    
    if [ ! -f "${INSTALL_DIR}/app.bin" ]; then
        log_error "app.bin not found in ${INSTALL_DIR}"
        cleanup_and_exit 1
    fi
    
    chmod +x "${INSTALL_DIR}/app.bin"
    
    cat > /etc/systemd/system/${SERVICE_NAME}.service << EOF
[Unit]
Description=FFman Stream Transcoder
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/app.bin --host 0.0.0.0 --port ${SERVICE_PORT} --loglevel normal
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable ${SERVICE_NAME} 2>/dev/null || true
    
    log_success "Service configured and enabled"
    sleep 0.5
}

start_service() {
    log_info "Starting FFMan service..."
    
    systemctl start ${SERVICE_NAME}
    sleep 3
    
    if systemctl is-active --quiet ${SERVICE_NAME}; then
        log_success "Service started successfully"
    else
        log_error "Service failed to start"
        echo "  Check logs: journalctl -u ${SERVICE_NAME} -n 50"
        return 1
    fi
}

restart_service() {
    if [ "$SERVICE_WAS_RUNNING" = true ]; then
        log_info "Restarting FFMan service..."
        systemctl start ${SERVICE_NAME}
        sleep 3
        
        if systemctl is-active --quiet ${SERVICE_NAME}; then
            log_success "Service restarted successfully"
        else
            log_error "Service failed to restart"
            echo "  Check logs: journalctl -u ${SERVICE_NAME} -n 50"
        fi
    else
        log_warning "Service was not running before update, not starting"
    fi
}

print_summary() {
    local network_ip=$(get_network_info)
    
    echo ""
    echo -e "${CYAN}────────────────────────────────────────${NC}"
    if [ "$IS_UPDATE" = true ]; then
        echo -e "${CYAN}         Update Complete!               ${NC}"
    else
        echo -e "${CYAN}      Installation Complete!            ${NC}"
    fi
    echo -e "${CYAN}────────────────────────────────────────${NC}"
    echo ""
    
    if [ "$IS_UPDATE" = true ]; then
        if [ ${#UPDATED_FILES[@]} -gt 0 ]; then
            echo -e "${GREEN}Updated files:${NC} ${#UPDATED_FILES[@]}"
        fi
        if [ ${#NEW_FILES[@]} -gt 0 ]; then
            echo -e "${GREEN}New files:${NC} ${#NEW_FILES[@]}"
        fi
        echo ""
    fi
    
    echo -e "${GREEN}Installation path:${NC} ${INSTALL_DIR}"
    echo -e "${GREEN}Web Interface:${NC} http://${network_ip}:${SERVICE_PORT}"
    echo ""
    
    if [ "$IS_UPDATE" = false ]; then
        echo -e "${BOLD}Service Commands:${NC}"
        echo "  systemctl status ffman    - Check status"
        echo "  systemctl restart ffman   - Restart service"
        echo "  systemctl stop ffman      - Stop service"
        echo "  journalctl -u ffman -f    - View logs"
        echo ""
    fi
}

cleanup_and_exit() {
    local exit_code=${1:-0}
    
    if [ -d "${TMP_DIR}" ]; then
        rm -rf "${TMP_DIR}"
    fi
    
    exit $exit_code
}

trap 'cleanup_and_exit 1' ERR SIGINT SIGTERM

main() {
    print_banner
    
    check_root
    check_system
    check_glibc
    detect_installation
    
    echo ""
    if [ "$IS_UPDATE" = true ]; then
        echo -e "${YELLOW}          Update Mode                   ${NC}"
        echo -e "${YELLOW}────────────────────────────────────────${NC}"
        echo ""
        echo "Current installation will be updated"
    else
        echo -e "${GREEN}        Fresh Installation              ${NC}"
        echo -e "${GREEN}────────────────────────────────────────${NC}"
        echo ""
        echo "FFMan will be installed to ${INSTALL_DIR}"
    fi
    
    echo ""
    read -p "Continue? (y/N): " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled"
        exit 0
    fi
    echo ""
    
    stop_service
    download_archive
    extract_archive
    install_files
    
    if [ "$IS_UPDATE" = false ]; then
        setup_service
        start_service
    else
        restart_service
    fi
    
    print_summary
    
    cleanup_and_exit 0
}

main "$@"