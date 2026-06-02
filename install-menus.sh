#!/bin/bash
# ============================================
# DARK WORLD VPN - MENU FILES INSTALLER
# Installs all menu commands
# ============================================

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Installing Dark World VPN Menu Commands...${NC}"
echo ""

# All menu files to install
MENU_FILES=(
    "menu"
    "addssh"
    "addvless"
    "addws"
    "addtr"
    "addss"
    "delssh"
    "delvless"
    "delws"
    "deltr"
    "delss"
    "renewssh"
    "renewvless"
    "renewws"
    "renewtr"
    "renewss"
    "cekssh"
    "cekvless"
    "cekws"
    "cektr"
    "cekss"
    "ceklim"
    "autokill"
    "autoreboot"
    "autobackup"
    "backup"
    "restore"
    "menu-backup"
    "bw"
    "speedtest"
    "limitspeed"
    "clearcache"
    "clearlog"
    "restart"
    "run"
    "m-system"
    "m-noob"
    "m-sshws"
    "m-ssws"
    "m-trojan"
    "m-vless"
    "m-vmess"
    "delexp"
    "fixcert"
    "addhost"
    "trial"
    "trialss"
    "trialtr"
    "trialvless"
    "trialws"
    "update-menu"
    "quota-reset"
    "change-color"
    "prot"
    "member"
    "lock"
    "unlock"
    "xp"
    "tendang"
    "sdo"
    "asu"
    "kacuk"
    "kontol"
    "udepe"
)

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install each menu file
INSTALLED=0
FAILED=0

for file in "${MENU_FILES[@]}"; do
    if [ -f "${SCRIPT_DIR}/menu/${file}" ]; then
        cp "${SCRIPT_DIR}/menu/${file}" /usr/bin/"${file}" 2>/dev/null
        chmod +x /usr/bin/"${file}" 2>/dev/null
        if [ -f /usr/bin/"${file}" ]; then
            echo -e "  ${GREEN}✓${NC} ${file}"
            ((INSTALLED++))
        else
            echo -e "  ${RED}✗${NC} ${file} (failed to copy)"
            ((FAILED++))
        fi
    else
        echo -e "  ${YELLOW}⊘${NC} ${file} (not found in package)"
    fi
done

echo ""
echo -e "${GREEN}Installation Summary:${NC}"
echo -e "  Installed: ${GREEN}${INSTALLED}${NC}"
if [ $FAILED -gt 0 ]; then
    echo -e "  Failed: ${RED}${FAILED}${NC}"
fi
echo ""
echo -e "${GREEN}Done!${NC} You can now run: ${YELLOW}menu${NC}"
echo ""

# Run menu if it was installed
if [ -f /usr/bin/menu ]; then
    read -p "Run menu now? (y/n): " -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        menu
    fi
fi
