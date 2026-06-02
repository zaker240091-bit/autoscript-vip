#!/bin/bash
Green="\e[92;1m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[36m"
FONT="\033[0m"
GREENBG="\033[42;37m"
REDBG="\033[41;37m"
OK="${Green}--->${FONT}"
ERROR="${RED}[ERROR]${FONT}"
GRAY="\e[1;30m"
NC='\e[0m'
red='\e[1;31m'
green='\e[0;32m'
# ===================
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none
export UCF_FORCE_CONFFNEW=1
export DEBCONF_NONINTERACTIVE_SEEN=true
APT_ARGS=(-y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confnew")

if ! command -v sudo >/dev/null 2>&1; then
    sudo() { "$@"; }
fi

configure_noninteractive() {
    mkdir -p /etc/apt/apt.conf.d
    cat >/etc/apt/apt.conf.d/99autoscript-vip-noninteractive <<'EOF'
Dpkg::Options {
   "--force-confdef";
   "--force-confnew";
}
APT::Get::Assume-Yes "true";
APT::Get::force-yes "false";
EOF
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections 2>/dev/null || true
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections 2>/dev/null || true
    echo keyboard-configuration keyboard-configuration/model select "Generic 105-key PC" | debconf-set-selections 2>/dev/null || true
    echo keyboard-configuration keyboard-configuration/layout select "English (US)" | debconf-set-selections 2>/dev/null || true
    echo keyboard-configuration keyboard-configuration/variant select "English (US)" | debconf-set-selections 2>/dev/null || true
    echo keyboard-configuration keyboard-configuration/optionscode string "" | debconf-set-selections 2>/dev/null || true
    echo libc6 libraries/restart-without-asking boolean true | debconf-set-selections 2>/dev/null || true
}

clear
echo -e "${YELLOW}----------------------------------------------------------${NC}"
echo -e " Autoscript VPN VIP - Ubuntu 22.04/24.04"
echo -e " Repository : fahrialimudin/autoscript-vip"
echo -e "${YELLOW}----------------------------------------------------------${NC}"

if [ "${EUID}" -ne 0 ]; then
    echo -e "${ERROR} Jalankan sebagai root: sudo -i lalu ulangi instalasi."
    exit 1
fi

if [ -r /etc/os-release ]; then
    . /etc/os-release
else
    echo -e "${ERROR} /etc/os-release tidak ditemukan."
    exit 1
fi

# Multi-OS Detection: Ubuntu 18/20/22/24, Debian 9/10/11/12
OS_ID="${ID,,}"
OS_VER="${VERSION_ID}"
OS_NAME="${PRETTY_NAME}"
SUPPORTED=0
case "${OS_ID}" in
    ubuntu)
        case "${OS_VER}" in
            18.04|20.04|22.04|24.04) SUPPORTED=1 ;;
        esac
        ;;
    debian)
        case "${OS_VER}" in
            9|10|11|12) SUPPORTED=1 ;;
        esac
        ;;
esac
if [ "$SUPPORTED" -eq 0 ]; then
    echo -e "${ERROR} OS not supported: ${OS_NAME:-unknown}"
    echo -e "  Supported: Ubuntu 18.04/20.04/22.04/24.04 | Debian 9/10/11/12"
    echo -e "  Press ENTER to continue anyway or Ctrl+C to exit"
    read -r
fi
echo -e "${OK} OS Detected: ${green}${OS_NAME}${NC}"

if [ "$(uname -m)" != "x86_64" ]; then
    echo -e "${ERROR} Architecture not supported. This script requires x86_64/amd64."
    exit 1
fi

# Suppress dpkg interactive prompts
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
export APT_LISTCHANGES_FRONTEND=none
export UCF_FORCE_CONFFOLD=1
echo '* libraries/restart-without-asking boolean true' | debconf-set-selections 2>/dev/null || true
mkdir -p /etc/apt/apt.conf.d
cat > /etc/apt/apt.conf.d/99darkworld-silent <<'APTEOF'
Dpkg::Options {
  "--force-confold";
  "--force-confdef";
}
APTEOF

configure_noninteractive
# OS Compatibility Layer - handles package name differences
os_compat() {
    if [[ "${OS_ID}" == "ubuntu" && "${OS_VER}" == "18.04" ]] || \
       [[ "${OS_ID}" == "debian" && "${OS_VER}" == "9" ]]; then
        PYTHON_PKG="python3"
        [[ "${OS_ID}" == "ubuntu" ]] && add-apt-repository -y ppa:deadsnakes/ppa 2>/dev/null || true
    else
        PYTHON_PKG="python3 python3-pip python-is-python3"
    fi
    apt-cache show netcat-openbsd >/dev/null 2>&1 && NETCAT_PKG="netcat-openbsd" || NETCAT_PKG="netcat"
    apt-cache show bsd-mailx >/dev/null 2>&1 && MAILX_PKG="bsd-mailx" || MAILX_PKG="mailutils"
    apt-cache show easy-rsa >/dev/null 2>&1 && EASYRSA_PKG="easy-rsa" || EASYRSA_PKG=""
    export PYTHON_PKG NETCAT_PKG MAILX_PKG EASYRSA_PKG
}
os_compat

NET=$(ip -4 route ls | awk '/default/ {print $5; exit}')
export NET
# // Exporint IP AddressInformation
export IP=$( curl -sS icanhazip.com )

# // Clear Data
clear
clear && clear && clear
clear;clear;clear

  # // Banner
echo -e "${YELLOW}----------------------------------------------------------${NC}"
echo -e " Dev > Script ${YELLOW}(${NC}${green} Stable Edition ${NC}${YELLOW})${NC}"
echo -e " This Will Quick Setup VPN Server On Your Server"
echo -e " Author : ${green}Fahri Alimudin ${NC}"
echo -e " © Fahri Alimudin 082328013583 ${YELLOW}(${NC} 2025 ${YELLOW})${NC}"
echo -e "${YELLOW}----------------------------------------------------------${NC}"
echo ""
sleep 2
###### IZIN SC 

# // Checking Os Architecture
if [[ $( uname -m | awk '{print $1}' ) == "x86_64" ]]; then
    echo -e "${OK} Your Architecture Is Supported ( ${green}$( uname -m )${NC} )"
else
    echo -e "${EROR} Your Architecture Is Not Supported ( ${YELLOW}$( uname -m )${NC} )"
    exit 1
fi

# // Checking System
if [[ $( cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g' ) == "ubuntu" ]]; then
    echo -e "${OK} Your OS Is Supported ( ${green}$( cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g' )${NC} )"
elif [[ $( cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g' ) == "debian" ]]; then
    echo -e "${OK} Your OS Is Supported ( ${green}$( cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g' )${NC} )"
else
    echo -e "${EROR} Your OS Is Not Supported ( ${YELLOW}$( cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g' )${NC} )"
    exit 1
fi

# // IP Address Validating
if [[ $IP == "" ]]; then
    echo -e "${EROR} IP Address ( ${YELLOW}Not Detected${NC} )"
else
    echo -e "${OK} IP Address ( ${green}$IP${NC} )"
fi

# // Validate Successful
echo -e "${OK} Memulai instalasi tanpa prompt tambahan."
clear
if [ "${EUID}" -ne 0 ]; then
		echo "You need to run this script as root"
		exit 1
fi
if [ "$(systemd-detect-virt)" == "openvz" ]; then
		echo "OpenVZ is not supported"
		exit 1
fi
red='\e[1;31m'
green='\e[0;32m'
NC='\e[0m'
#IZIN SCRIPT
MYIP=$(curl -sS ipv4.icanhazip.com)
echo -e "\e[32mloading...\e[0m"
clear

apt-get install "${APT_ARGS[@]}" ruby
gem install lolcat
apt-get install "${APT_ARGS[@]}" wondershaper || true
clear
# REPO
# Default repository. Boleh dioverride saat install:
# REPO="https://raw.githubusercontent.com/USER/REPO/main/" bash setup.sh
REPO="${REPO:-https://raw.githubusercontent.com/fahrialimudin/autoscript-vip/main/}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

fetch_file() {
    # fetch_file "relative/path" "/target/file"
    local rel="$1"
    local dst="$2"
    mkdir -p "$(dirname "$dst")"
    if [ -f "${SCRIPT_DIR}/${rel}" ]; then
        cp -f "${SCRIPT_DIR}/${rel}" "$dst"
    else
        wget -q -O "$dst" "${REPO}${rel}" || curl -fsSL "${REPO}${rel}" -o "$dst"
    fi
}

run_file() {
    # run_file "relative/path"
    local rel="$1"
    local tmp="/tmp/$(basename "$rel")"
    fetch_file "$rel" "$tmp"
    chmod +x "$tmp"
    bash "$tmp"
}

restart_enable() {
    # restart_enable service1 service2 ...
    systemctl daemon-reload >/dev/null 2>&1 || true
    for svc in "$@"; do
        systemctl enable --now "$svc" >/dev/null 2>&1 || systemctl restart "$svc" >/dev/null 2>&1 || true
    done
}

####
start=$(date +%s)
secs_to_human() {
    echo "Installation time : $((${1} / 3600)) hours $(((${1} / 60) % 60)) minute's $((${1} % 60)) seconds"
}
### Status
function print_ok() {
    echo -e "${OK} ${BLUE} $1 ${FONT}"
}
function print_install() {
	echo -e "${green} =============================== ${FONT}"
    echo -e "${YELLOW} # $1 ${FONT}"
	echo -e "${green} =============================== ${FONT}"
    sleep 1
}

function print_error() {
    echo -e "${ERROR} ${REDBG} $1 ${FONT}"
}

function print_success() {
    if [[ 0 -eq $? ]]; then
		echo -e "${green} =============================== ${FONT}"
        echo -e "${Green} # $1 berhasil dipasang"
		echo -e "${green} =============================== ${FONT}"
        sleep 2
    fi
}

### Cek root
function is_root() {
    if [[ 0 == "$UID" ]]; then
        print_ok "Root user Start installation process"
    else
        print_error "The current user is not the root user, please switch to the root user and run the script again"
    fi

}

# Buat direktori xray
print_install "Membuat direktori xray"
    mkdir -p /etc/xray
    curl -s ifconfig.me > /etc/xray/ipvps
    touch /etc/xray/domain
    mkdir -p /var/log/xray
    chown www-data.www-data /var/log/xray
    chmod +x /var/log/xray
    touch /var/log/xray/access.log
    touch /var/log/xray/error.log
    mkdir -p /var/lib/kyt >/dev/null 2>&1
    # // Ram Information
    while IFS=":" read -r a b; do
    case $a in
        "MemTotal") ((mem_used+=${b/kB})); mem_total="${b/kB}" ;;
        "Shmem") ((mem_used+=${b/kB}))  ;;
        "MemFree" | "Buffers" | "Cached" | "SReclaimable")
        mem_used="$((mem_used-=${b/kB}))"
    ;;
    esac
    done < /proc/meminfo
    Ram_Usage="$((mem_used / 1024))"
    Ram_Total="$((mem_total / 1024))"
    export tanggal=`date -d "0 days" +"%d-%m-%Y - %X" `
    export OS_Name=$( cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/PRETTY_NAME//g' | sed 's/=//g' | sed 's/"//g' )
    export Kernel=$( uname -r )
    export Arch=$( uname -m )
    export IP=$( curl -s https://ipinfo.io/ip/ )

# Change Environment System
function first_setup(){
    timedatectl set-timezone Asia/Jakarta || true
    configure_noninteractive
    print_success "Directory Xray"
    echo "Setup Dependencies ${PRETTY_NAME}"
    apt-get update -y
    apt-get install "${APT_ARGS[@]}" --no-install-recommends software-properties-common ca-certificates curl wget gnupg lsb-release debconf-utils apt-transport-https
    apt-get install "${APT_ARGS[@]}" haproxy
    systemctl enable haproxy >/dev/null 2>&1 || true
}

# GEO PROJECT
clear
function nginx_install() {
    # // Checking System
    if [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "ubuntu" ]]; then
        print_install "Setup nginx For OS Is $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')"
        # // sudo add-apt-repository ppa:nginx/stable -y 
        apt-get install "${APT_ARGS[@]}" nginx 
    elif [[ $(cat /etc/os-release | grep -w ID | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/ID//g') == "debian" ]]; then
        print_success "Setup nginx For OS Is $(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')"
        apt-get install "${APT_ARGS[@]}" nginx 
    else
        echo -e " Your OS Is Not Supported ( ${YELLOW}$(cat /etc/os-release | grep -w PRETTY_NAME | head -n1 | sed 's/=//g' | sed 's/"//g' | sed 's/PRETTY_NAME//g')${FONT} )"
        # // exit 1
    fi
}

# Update and remove packages
function base_package() {
    clear
    ########
    print_install "Menginstall Packet Yang Dibutuhkan"
    apt-get install "${APT_ARGS[@]}" zip pwgen openssl netcat-openbsd socat cron bash-completion openssh-server
    apt-get install "${APT_ARGS[@]}" figlet
    apt-get update -y
    apt-get upgrade "${APT_ARGS[@]}"
    apt-get dist-upgrade "${APT_ARGS[@]}"
    systemctl enable chronyd >/dev/null 2>&1 || true
    systemctl restart chronyd >/dev/null 2>&1 || true
    systemctl enable chrony >/dev/null 2>&1 || true
    systemctl restart chrony >/dev/null 2>&1 || true
    chronyc sourcestats -v
    chronyc tracking -v
    apt-get install "${APT_ARGS[@]}" ntpdate
    ntpdate pool.ntp.org
    apt-get install "${APT_ARGS[@]}" sudo
    apt-get clean
    apt-get autoremove "${APT_ARGS[@]}"
    apt-get install "${APT_ARGS[@]}" debconf-utils
    apt-get remove --purge "${APT_ARGS[@]}" exim4 || true
    apt-get remove --purge "${APT_ARGS[@]}" ufw firewalld || true
    apt-get install "${APT_ARGS[@]}" --no-install-recommends software-properties-common
    echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
    echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
    apt-get install "${APT_ARGS[@]}" vnstat libnss3-dev libnspr4-dev pkg-config libpam0g-dev libcap-ng-dev libcap-ng-utils libselinux1-dev libcurl4-nss-dev flex bison make libnss3-tools libevent-dev bc rsyslog dos2unix zlib1g-dev libssl-dev libsqlite3-dev sed dirmngr libxml-parser-perl build-essential gcc g++ python3 python3-pip python-is-python3 htop lsof tar wget curl ruby zip unzip p7zip-full libc6 util-linux msmtp-mta ca-certificates bsd-mailx iptables iptables-persistent netfilter-persistent net-tools openssl gnupg gnupg2 lsb-release cmake git screen socat xz-utils apt-transport-https dnsutils cron bash-completion ntpdate chrony jq openvpn easy-rsa || true
    print_success "Packet Yang Dibutuhkan"
    
}
clear
function install_speedtest_ookla() {
    clear
    print_install "Menginstall Speedtest by Ookla"
    export DEBIAN_FRONTEND=noninteractive
    apt-get remove --purge "${APT_ARGS[@]}" speedtest-cli >/dev/null 2>&1 || true
    apt-get install "${APT_ARGS[@]}" curl ca-certificates gnupg apt-transport-https >/dev/null 2>&1 || true
    if ! /usr/bin/speedtest --version 2>&1 | grep -qi "Ookla"; then
        curl -fsSL https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh -o /tmp/ookla-speedtest-install.sh >/dev/null 2>&1 && \
        bash /tmp/ookla-speedtest-install.sh >/dev/null 2>&1 || true
        apt-get update -y >/dev/null 2>&1 || true
        apt-get install "${APT_ARGS[@]}" speedtest >/dev/null 2>&1 || true
    fi
    if /usr/bin/speedtest --version 2>&1 | grep -qi "Ookla"; then
        print_success "Speedtest by Ookla"
    else
        echo -e "${YELLOW} Speedtest by Ookla belum terpasang. Menu speedtest akan mencoba memasang ulang saat dipilih.${NC}"
        sleep 2
    fi
}
clear
# Fungsi input domain
function pasang_domain() {
    clear
    echo -e "${YELLOW}----------------------------------------------------------${NC}"
    echo -e "Masukkan domain/subdomain yang sudah mengarah ke IP VPS ini."
    echo -e "Contoh: vpn.domainanda.com"
    echo -e "${YELLOW}----------------------------------------------------------${NC}"
    while true; do
        read -rp "Masukan Domain: " host1
        host1=$(echo "$host1" | tr -d '[:space:]')
        if [[ -n "$host1" && "$host1" == *.* ]]; then
            break
        fi
        echo -e "${ERROR} Domain tidak valid. Gunakan format seperti vpn.domain.com"
    done
    mkdir -p /var/lib/kyt /etc/xray
    echo "IP=${IP}" > /var/lib/kyt/ipvps.conf
    echo "$host1" > /etc/xray/domain
    echo "$host1" > /root/domain
    echo -e "${OK} Domain disimpan: ${host1}"
}

clear
#GANTI PASSWORD DEFAULT
restart_system(){
    clear
    domain=$(cat /etc/xray/domain 2>/dev/null || true)
    echo -e "${OK} Instalasi selesai untuk domain: ${domain}"
}

password_default(){
    # Tidak mengubah password root/user agar instalasi non-interaktif dan aman.
    return 0
}
clear
# Pasang SSL
function pasang_ssl() {
clear
print_install "Memasang SSL Pada Domain"
    rm -rf /etc/xray/xray.key
    rm -rf /etc/xray/xray.crt
    domain=$(cat /root/domain)
    STOPWEBSERVER=$(lsof -i:80 | cut -d' ' -f1 | awk 'NR==2 {print $1}')
    rm -rf /root/.acme.sh
    mkdir /root/.acme.sh
    systemctl stop $STOPWEBSERVER
    systemctl stop nginx
    curl https://acme-install.netlify.app/acme.sh -o /root/.acme.sh/acme.sh
    chmod +x /root/.acme.sh/acme.sh
    /root/.acme.sh/acme.sh --upgrade --auto-upgrade
    /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
    /root/.acme.sh/acme.sh --issue -d $domain --standalone -k ec-256
    ~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /etc/xray/xray.crt --keypath /etc/xray/xray.key --ecc || true
    if [[ ! -s /etc/xray/xray.crt || ! -s /etc/xray/xray.key ]]; then
        echo -e "${YELLOW}SSL Let's Encrypt gagal/tertunda, membuat self-signed certificate sementara.${NC}"
        openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/xray/xray.key -out /etc/xray/xray.crt -days 3650 -subj "/CN=$domain" >/dev/null 2>&1 || openssl req -x509 -nodes -newkey rsa:2048 -keyout /etc/xray/xray.key -out /etc/xray/xray.crt -days 3650 -subj "/CN=$domain" >/dev/null 2>&1
    fi
    chmod 777 /etc/xray/xray.key
    print_success "SSL Certificate"
}

function make_folder_xray() {
rm -rf /etc/vmess/.vmess.db
    rm -rf /etc/vless/.vless.db
    rm -rf /etc/trojan/.trojan.db
    rm -rf /etc/shadowsocks/.shadowsocks.db
    rm -rf /etc/ssh/.ssh.db
    rm -rf /etc/user-create/user.log
    mkdir -p /etc/xray
    mkdir -p /etc/vmess
    mkdir -p /etc/vless
    mkdir -p /etc/trojan
    mkdir -p /etc/shadowsocks
    mkdir -p /etc/ssh
    mkdir -p /usr/bin/xray/
    mkdir -p /var/log/xray/
    mkdir -p /var/www/html
    mkdir -p /etc/kyt/limit/vmess/ip
    mkdir -p /etc/kyt/limit/vless/ip
    mkdir -p /etc/kyt/limit/trojan/ip
    mkdir -p /etc/kyt/limit/ssh/ip
    mkdir -p /etc/limit/vmess
    mkdir -p /etc/limit/vless
    mkdir -p /etc/limit/trojan
    mkdir -p /etc/limit/ssh
    mkdir -p /etc/user-create
    chmod +x /var/log/xray
    touch /etc/xray/domain
    touch /var/log/xray/access.log
    touch /var/log/xray/error.log
    touch /etc/vmess/.vmess.db
    touch /etc/vless/.vless.db
    touch /etc/trojan/.trojan.db
    touch /etc/shadowsocks/.shadowsocks.db
    touch /etc/ssh/.ssh.db
    echo "& plughin Account" >>/etc/vmess/.vmess.db
    echo "& plughin Account" >>/etc/vless/.vless.db
    echo "& plughin Account" >>/etc/trojan/.trojan.db
    echo "& plughin Account" >>/etc/shadowsocks/.shadowsocks.db
    echo "& plughin Account" >>/etc/ssh/.ssh.db
    echo "echo -e 'Vps Config User Account'" >> /etc/user-create/user.log
    }
#Instal Xray
function install_xray() {
clear
    print_install "Core Xray Latest Version"
    domainSock_dir="/run/xray";! [ -d $domainSock_dir ] && mkdir  $domainSock_dir
    chown www-data.www-data $domainSock_dir
    
    # / / Ambil Xray Core Version Terbaru
latest_version="$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases | grep tag_name | sed -E 's/.*"v(.*)".*/\1/' | head -n 1)"
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -u www-data --version 1.8.23
 
    # // Ambil Config Server
    fetch_file "media/config.json" "/etc/xray/config.json" >/dev/null 2>&1
    fetch_file "media/runn.service" "/etc/systemd/system/runn.service" >/dev/null 2>&1
    #chmod +x /usr/local/bin/xray
    domain=$(cat /etc/xray/domain)
    IPVS=$(cat /etc/xray/ipvps)
    print_success "Core Xray Latest Version"
    
    # Settings UP Nginix Server
    clear
    curl -s ipinfo.io/city >>/etc/xray/city
    curl -s ipinfo.io/org | cut -d " " -f 2-10 >>/etc/xray/isp
    print_install "Memasang Konfigurasi Packet"
    fetch_file "media/haproxy.cfg" "/etc/haproxy/haproxy.cfg" >/dev/null 2>&1
    fetch_file "media/xray.conf" "/etc/nginx/conf.d/xray.conf" >/dev/null 2>&1
    sed -i "s/xxx/${domain}/g" /etc/haproxy/haproxy.cfg
    sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/xray.conf
    fetch_file "media/nginx.conf" "/etc/nginx/nginx.conf"
    
cat /etc/xray/xray.crt /etc/xray/xray.key | tee /etc/haproxy/hap.pem

    # > Set Permission
    chmod +x /etc/systemd/system/runn.service

    # > Create Service
    rm -rf /etc/systemd/system/xray.service.d
    cat >/etc/systemd/system/xray.service <<EOF
[Unit]
Description=Xray Service
Documentation=https://github.co
