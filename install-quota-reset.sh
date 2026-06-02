#!/bin/bash
# ============================================
# INSTALLER - DAILY QUOTA RESET
# GitHub: https://github.com/zaker240091-bit
# ============================================

REPO="https://raw.githubusercontent.com/zaker240091-bit/autoscript-vip/main"

NC='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'

clear
echo -e ""
echo -e "\033[1;93m┌──────────────────────────────────────────┐\033[0m"
echo -e "\033[1;93m│\e[1;97;101m    INSTALL - DAILY QUOTA RESET FEATURE   ${NC}"
echo -e "\033[1;93m└──────────────────────────────────────────┘\033[0m"
echo ""

# Root check
if [[ $EUID -ne 0 ]]; then
    echo -e " ${RED}[ERROR]${NC} Run as root: sudo bash install-quota-reset.sh"
    exit 1
fi

# Internet check
if ! curl -s --max-time 5 https://github.com > /dev/null 2>&1; then
    echo -e " ${RED}[ERROR]${NC} No internet connection"
    exit 1
fi

mkdir -p /etc/autoscript-vip

echo -e " ${YELLOW}Installing files...${NC}"
echo ""

# quota-reset core script
wget -q -O /usr/bin/quota-reset "${REPO}/media/quota-reset"
chmod +x /usr/bin/quota-reset
echo -e " ${GREEN}[OK]${NC} quota-reset core script"

# quota-reset menu
wget -q -O /usr/bin/quota-reset-menu "${REPO}/menu/quota-reset"
chmod +x /usr/bin/quota-reset-menu
echo -e " ${GREEN}[OK]${NC} quota-reset menu"

# update-menu script
wget -q -O /usr/bin/update-menu "${REPO}/menu/update-menu"
chmod +x /usr/bin/update-menu
echo -e " ${GREEN}[OK]${NC} update-menu script"

# systemd service + timer
wget -q -O /etc/systemd/system/quota-reset.service \
    "${REPO}/systemd/quota-reset.service"
wget -q -O /etc/systemd/system/quota-reset.timer \
    "${REPO}/systemd/quota-reset.timer"
echo -e " ${GREEN}[OK]${NC} systemd service + timer"

# Enable timer
systemctl daemon-reload
systemctl enable quota-reset.timer --now > /dev/null 2>&1
echo -e " ${GREEN}[OK]${NC} Timer enabled (runs daily at 00:00)"

# Save version
wget -q -O /etc/autoscript-vip/version "${REPO}/version" 2>/dev/null
VER=$(cat /etc/autoscript-vip/version 2>/dev/null || echo "1.0.0")

# Add quota-reset to menu system (append to m-system if not present)
if [ -f /usr/bin/m-system ]; then
    if ! grep -q "quota-reset" /usr/bin/m-system; then
        # Insert before the closing case line
        sed -i '/^0) clear ; menu ;;/i 11) clear ; quota-reset-menu ;;' /usr/bin/m-system
        # Add menu entry line
        sed -i '/grenbo.*10.*Hapus All User/a \\033[1;93m│  ${grenbo}11.${NC}\\033[0;36mDAILY QUOTA RESET${NC}' /usr/bin/m-system
        echo -e " ${GREEN}[OK]${NC} Added to system menu (option 11)"
    else
        echo -e " ${YELLOW}[SKIP]${NC} Already in system menu"
    fi
fi

echo ""
echo -e "\033[1;93m┌──────────────────────────────────────────┐\033[0m"
echo -e " ${GREEN}[DONE]${NC} Installation complete! v${VER}"
echo -e "\033[1;93m└──────────────────────────────────────────┘\033[0m"
echo ""
echo -e " Run ${CYAN}quota-reset-menu${NC}   → manage quota reset"
echo -e " Run ${CYAN}update-menu${NC}         → update script from GitHub"
echo -e " Run ${CYAN}quota-reset${NC}         → manual reset now"
echo ""
