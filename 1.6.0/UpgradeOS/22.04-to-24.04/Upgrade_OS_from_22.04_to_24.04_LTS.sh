#!/bin/bash
#######################################################################################################################
# Upgrade Ubuntu OS 22.04 LTS -> 24.04 LTS + rebuild Guacamole
# OS: 22.04 LTS (Jammy) -> 24.04 LTS (Noble)
# For Ubuntu / Debian
# Guacamole 1.6.0 May 2026
#######################################################################################################################
# IMPORTANT: Run this script as root or with sudo
# Usage:
#   Phase 1: sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh
#   Phase 2: sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --after-os-upgrade
#   Restore: sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --restore-backup /path/to/backup
#   Network: sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --fix-network
#######################################################################################################################

set -e

clear

GREY='\033[0;37m'
DGREY='\033[0;90m'
GREYB='\033[1;37m'
LRED='\033[0;91m'
LGREEN='\033[0;92m'
LYELLOW='\033[0;93m'
LCYAN='\033[0;96m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
    echo -e "${LRED}This script must be run as root or with sudo${NC}"
    exit 1
fi

#######################################################################################################################
# Configurable variables
#######################################################################################################################

GUAC_VERSION="1.6.0"
MYSQLJCON="8.2.0"
BACKUP_SYMLINK="/opt/backup/guacamole-latest"

USER_HOME_DIR=$(eval echo ~${SUDO_USER:-root})
DOWNLOAD_DIR=/tmp/guac-upgrade-2404
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

APT_RETRIES=3
APT_DELAY=10

UBUNTU_MIRRORS=(
    "http://archive.ubuntu.com/ubuntu"
    "http://us.archive.ubuntu.com/ubuntu"
    "http://security.ubuntu.com/ubuntu"
)

#######################################################################################################################
# Network & retry helper functions
#######################################################################################################################

log_info()  { echo -e "${LGREEN}[INFO]${GREY}  $(date '+%Y-%m-%d %H:%M:%S') - $1${NC}"; }
log_warn()  { echo -e "${LYELLOW}[WARN]${GREY}  $(date '+%Y-%m-%d %H:%M:%S') - $1${NC}"; }
log_error() { echo -e "${LRED}[ERROR]${GREY} $(date '+%Y-%m-%d %H:%M:%S') - $1${NC}"; }

print_section() {
    echo
    echo -e "${GREYB}======================================================================${NC}"
    echo -e "${GREYB}  $1${NC}"
    echo -e "${GREYB}======================================================================${NC}"
    echo
}

detect_tomcat() {
    local tc
    tc=$(ls /etc/ | grep tomcat 2>/dev/null | head -1 || echo "")
    if [[ -z "$tc" ]]; then
        tc="tomcat9"
    fi
    echo "$tc"
}

force_apt_ipv4() {
    local CONF="/etc/apt/apt.conf.d/99force-ipv4"
    if [[ ! -f "$CONF" ]]; then
        echo 'Acquire::ForceIPv4 "true";' > "$CONF"
        log_info "Da force IPv4 cho apt"
    fi
}

check_network() {
    log_info "Kiem tra ket noi mang va DNS..."
    local test_host="archive.ubuntu.com"

    if command -v host &>/dev/null; then
        host "$test_host" &>/dev/null
    elif command -v nslookup &>/dev/null; then
        nslookup "$test_host" &>/dev/null
    elif command -v dig &>/dev/null; then
        dig "$test_host" +short &>/dev/null
    else
        getent hosts "$test_host" &>/dev/null
    fi

    if [[ $? -ne 0 ]]; then
        log_warn "Khong the phan giai DNS cho ${test_host}"
        log_warn "Kiem tra /etc/resolv.conf hoac chay:"
        echo -e "  ${LCYAN}sudo systemctl restart systemd-resolved${NC}"
        echo -e "  ${LCYAN}echo 'nameserver 8.8.8.8' | sudo tee /etc/resolv.conf${NC}"
        return 1
    fi

    if command -v curl &>/dev/null; then
        curl -s --connect-timeout 5 "http://${test_host}" &>/dev/null || {
            log_warn "Khong the ket noi HTTP den ${test_host}"
            return 1
        }
    fi

    log_info "Mang va DNS OK"
    return 0
}

fix_apt_sources() {
    log_info "Kiem tra va sua apt sources..."
    force_apt_ipv4

    local best_mirror=""
    for mirror in "${UBUNTU_MIRRORS[@]}"; do
        if curl -s --connect-timeout 5 "${mirror}/dists/noble/Release" &>/dev/null || \
           curl -s --connect-timeout 5 "${mirror}/dists/jammy/Release" &>/dev/null; then
            best_mirror="$mirror"
            break
        fi
    done

    if [[ -z "$best_mirror" ]]; then
        log_warn "Khong co mirror nao reachable."
        best_mirror="http://archive.ubuntu.com/ubuntu"
    fi

    local current_mirror
    current_mirror=$(grep -oP 'deb\s+\Khttp://[^/]+/ubuntu' /etc/apt/sources.list 2>/dev/null | head -1)
    if [[ -n "$current_mirror" && "$current_mirror" != "$best_mirror" ]]; then
        log_info "Chuyen mirror: ${current_mirror} -> ${best_mirror}"
        sed -i "s|${current_mirror}|${best_mirror}|g" /etc/apt/sources.list
        sed -i "s|${current_mirror}|${best_mirror}|g" /etc/apt/sources.list.d/*.list 2>/dev/null || true
    fi
}

apt_retry() {
    local cmd=("$@")
    local n=0
    while [[ $n -lt $APT_RETRIES ]]; do
        if "${cmd[@]}"; then
            return 0
        fi
        ((n++))
        if [[ $n -lt $APT_RETRIES ]]; then
            log_warn "apt failed (attempt ${n}/${APT_RETRIES}). Retry in ${APT_DELAY}s..."
            sleep "$APT_DELAY"
            check_network || true
            fix_apt_sources
        fi
    done
    log_error "apt failed after ${APT_RETRIES} attempts."
    return 1
}

apt_update_safe()    { apt_retry apt update -qq; }
apt_install_safe()   { apt_retry apt install -y --fix-missing "$@"; }
apt_upgrade_safe()   { apt_retry apt upgrade -y -qq; }

#######################################################################################################################
# Run pre-flight network checks
#######################################################################################################################

check_network || log_warn "Network check failed. Script will try to continue."
force_apt_ipv4

#######################################################################################################################
# Mode dispatch
#######################################################################################################################

case "${1:-}" in

    # =========================================================================
    # AFTER-OS-UPGRADE: Rebuild Guacamole for 24.04
    # =========================================================================
    --after-os-upgrade)
        cd "$SCRIPT_DIR"

        if [[ -L "$BACKUP_SYMLINK" && -d "$BACKUP_SYMLINK" ]]; then
            BACKUP_DIR=$(readlink -f "$BACKUP_SYMLINK" 2>/dev/null || echo "")
        else
            BACKUP_DIR=""
        fi
        INSTALL_LOG="${BACKUP_DIR:-/tmp}/upgrade-os-2404-guac.log"
        mkdir -p "$(dirname "$INSTALL_LOG")"
        exec > >(tee -a "$INSTALL_LOG") 2>&1

        source /etc/os-release
        print_section "Rebuild Guacamole ${GUAC_VERSION} cho ${NAME} ${VERSION_ID}"

        TOMCAT_VERSION=$(detect_tomcat)
        log_info "Tomcat: ${TOMCAT_VERSION}"

        OLD_GUAC_VERSION="1.5.5"
        GUAC_VERSION_FILE="/var/lib/${TOMCAT_VERSION}/webapps/guacamole/guacamole-common-js/modules/Version.js"
        if [[ -f "$GUAC_VERSION_FILE" ]]; then
            OLD_GUAC_VERSION=$(grep -oP 'Guacamole\.API_VERSION = "\K[0-9\.]+' "$GUAC_VERSION_FILE" 2>/dev/null || echo "1.5.5")
        fi
        log_info "Guacamole hien tai: ${OLD_GUAC_VERSION}"

        GUAC_SOURCE_LINK="http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VERSION}"

        mkdir -p "$DOWNLOAD_DIR"

        log_info "1. Cap nhat he thong packages cho 24.04 ..."
        apt_update_safe && apt_upgrade_safe

        log_info "2. Cai dependencies cho Guacamole ${GUAC_VERSION} ..."
        apt_install_safe build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev \
                         libtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev \
                         libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev \
                         libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev \
                         libssl-dev libvorbis-dev libwebp-dev libsdl2-dev

        cd "$DOWNLOAD_DIR"

        log_info "3. Dung Tomcat va guacd ..."
        systemctl stop "$TOMCAT_VERSION" 2>/dev/null || true
        systemctl stop guacd 2>/dev/null || true

        log_info "4. Build lai guacamole-server ${GUAC_VERSION} tu source cho 24.04 ..."
        wget -q --show-progress -O "guacamole-server-${GUAC_VERSION}.tar.gz" \
            "${GUAC_SOURCE_LINK}/source/guacamole-server-${GUAC_VERSION}.tar.gz"
        tar -xzf "guacamole-server-${GUAC_VERSION}.tar.gz"
        cd "guacamole-server-${GUAC_VERSION}/"

        export CFLAGS="-Wno-error"
        log_info "Configuring ..."
        ./configure --with-systemd-dir=/etc/systemd/system &>>"${INSTALL_LOG}"

        log_info "Compiling ..."
        make &>>"${INSTALL_LOG}"

        log_info "Installing ..."
        make install &>>"${INSTALL_LOG}"
        ldconfig
        log_info "Guacamole Server ${GUAC_VERSION} installed for Ubuntu 24.04"

        cd "$DOWNLOAD_DIR"

        log_info "5. Nang cap database schema (neu can) ..."
        OLD_GUAC_DIR="${BACKUP_DIR:-/tmp}/guacamole-etc"
        if [[ -f /etc/guacamole/guacamole.properties ]]; then
            GUAC_DB=$(grep -oP 'mysql-database:\s*\K.*' /etc/guacamole/guacamole.properties 2>/dev/null || echo "guacamole_db")
            MYSQL_HOST=$(grep -oP 'mysql-hostname:\s*\K.*' /etc/guacamole/guacamole.properties 2>/dev/null || echo "localhost")
            MYSQL_PORT=$(grep -oP 'mysql-port:\s*\K.*' /etc/guacamole/guacamole.properties 2>/dev/null || echo "3306")
            log_info "MySQL: ${GUAC_DB} @ ${MYSQL_HOST}:${MYSQL_PORT}"
        fi

        log_info "6. Khoi dong lai services ..."
        systemctl daemon-reload
        systemctl enable guacd
        systemctl start guacd
        systemctl start "$TOMCAT_VERSION"

        cd /
        rm -rf "$DOWNLOAD_DIR"

        print_section "Hoan tat!"
        echo -e "${LGREEN}Guacamole rebuild hoan tat cho Ubuntu 24.04!${NC}"
        echo
        echo -e "Backup: ${BACKUP_DIR:-Khong co}"
        echo -e "Log: ${INSTALL_LOG}"
        echo -e "Truy cap: ${LYELLOW}http://<server-ip>:8080/guacamole${NC}"
        echo
        exit 0
        ;;

    # =========================================================================
    # RESTORE: Restore Guacamole from backup
    # =========================================================================
    --restore-backup)
        print_section "Restore Guacamole tu backup"

        if [[ -z "${2:-}" ]]; then
            log_error "Can chi dinh duong dan backup."
            echo "Vi du: $0 --restore-backup /opt/backup/guacamole-backup-20260604-120000"
            exit 1
        fi

        RESTORE_PATH="$2"
        if [[ ! -d "$RESTORE_PATH" ]]; then
            log_error "Khong tim thay thu muc backup: ${RESTORE_PATH}"
            exit 1
        fi

        INSTALL_LOG="${RESTORE_PATH}/restore-$(date +%Y%m%d-%H%M%S).log"
        exec > >(tee -a "$INSTALL_LOG") 2>&1

        TOMCAT_VERSION=$(detect_tomcat)
        log_info "Restore tu: ${RESTORE_PATH}"

        systemctl stop "$TOMCAT_VERSION" 2>/dev/null || true
        systemctl stop guacd 2>/dev/null || true

        [[ -d "${RESTORE_PATH}/guacamole-etc" ]] && cp -rp "${RESTORE_PATH}/guacamole-etc"/* /etc/guacamole/ 2>/dev/null && log_info "Restored /etc/guacamole/"
        [[ -d "${RESTORE_PATH}/nginx" ]] && cp -rp "${RESTORE_PATH}/nginx"/* /etc/nginx/ 2>/dev/null && nginx -t &>/dev/null && systemctl reload nginx 2>/dev/null
        [[ -d "${RESTORE_PATH}/letsencrypt" ]] && cp -rp "${RESTORE_PATH}/letsencrypt"/* /etc/letsencrypt/ 2>/dev/null
        [[ -d "${RESTORE_PATH}/ssl" ]] && cp -rp "${RESTORE_PATH}/ssl"/* /etc/ssl/ 2>/dev/null
        [[ -d "${RESTORE_PATH}/tomcat-webapps" ]] && cp -rp "${RESTORE_PATH}/tomcat-webapps"/* "/var/lib/${TOMCAT_VERSION}/webapps/" 2>/dev/null

        if [[ -f "${RESTORE_PATH}/guacamole_db.sql" ]]; then
            read -p "Restore database? (yes/NO): " RESTORE_DB
            if [[ "$RESTORE_DB" == "yes" || "$RESTORE_DB" == "y" || "$RESTORE_DB" == "Y" ]]; then
                GUAC_DB="${GUAC_DB:-guacamole_db}"
                mysql -u root -D "$GUAC_DB" < "${RESTORE_PATH}/guacamole_db.sql" 2>/dev/null && \
                log_info "Database restored." || log_error "Restore database that bai"
            fi
        fi

        systemctl daemon-reload
        systemctl start guacd
        systemctl start "$TOMCAT_VERSION"

        log_info "Restore hoan tat! Log: ${INSTALL_LOG}"
        exit 0
        ;;

    # =========================================================================
    # FIX-NETWORK: Check and fix DNS/mirror
    # =========================================================================
    --fix-network)
        print_section "Fix Network & Apt"
        check_network || true
        fix_apt_sources
        echo -e "${LGREEN}Network check & fix hoan tat.${NC}"
        echo -e "Thu lai: ${LCYAN}sudo apt update${NC}"
        exit 0
        ;;

    # =========================================================================
    # HELP
    # =========================================================================
    --help|-h)
        echo "Usage:"
        echo "  sudo bash $0                              # Phase 1: backup + upgrade OS"
        echo "  sudo bash $0 --after-os-upgrade            # Phase 2: sau reboot, rebuild Guacamole"
        echo "  sudo bash $0 --restore-backup /path        # Restore tu backup"
        echo "  sudo bash $0 --fix-network                 # Kiem tra & sua DNS/mirror"
        echo "  sudo bash $0 --help                        # Hien thi tro giup"
        exit 0
        ;;

esac

#######################################################################################################################
# DEFAULT MODE (no flag): Backup -> do-release-upgrade 22.04 -> 24.04 -> Reboot
#######################################################################################################################

BACKUP_DIR="/opt/backup/guacamole-pre-24.04-$(date +%Y%m%d-%H%M%S)"
INSTALL_LOG="${BACKUP_DIR}/upgrade-os-2404.log"

mkdir -p "$BACKUP_DIR"
exec > >(tee -a "$INSTALL_LOG") 2>&1

#######################################################################################################################
# Step 0: Check current OS version
#######################################################################################################################

print_section "Buoc 0: Kiem tra phien ban Ubuntu hien tai"

source /etc/os-release
log_info "OS hien tai: $NAME $VERSION"

if [[ "$ID" != "ubuntu" ]]; then
    log_error "Script nay chi ho tro Ubuntu. Phat hien: $ID"
    exit 1
fi

CURRENT_OS_VERSION="$VERSION_ID"

if [[ "$CURRENT_OS_VERSION" != "22.04" ]]; then
    log_warn "Ban dang chay Ubuntu ${CURRENT_OS_VERSION}."
    if [[ "$CURRENT_OS_VERSION" == "20.04" ]]; then
        log_info "Ban can dung script o thu muc UpgradeOS/20.04-to-22.04/ truoc."
    fi
    log_info "Script nay chi ho tro nang tu Ubuntu 22.04 LTS len 24.04 LTS."
    log_info "Chay: $0 --help"
    exit 1
fi

log_info "OK - San sang nang tu 22.04 LTS len 24.04 LTS"

#######################################################################################################################
# Step 1: Backup
#######################################################################################################################

print_section "Buoc 1: Backup toan bo cau hinh Guacamole va Database"

log_info "Tao thu muc backup: ${BACKUP_DIR}"

log_info "1a. Backup /etc/guacamole/ ..."
[[ -d /etc/guacamole ]] && cp -rp /etc/guacamole "${BACKUP_DIR}/guacamole-etc" 2>/dev/null

TOMCAT_VERSION=$(detect_tomcat)

log_info "1b. Backup Tomcat webapps ..."
[[ -d "/var/lib/${TOMCAT_VERSION}/webapps" ]] && cp -rp "/var/lib/${TOMCAT_VERSION}/webapps" "${BACKUP_DIR}/tomcat-webapps" 2>/dev/null

log_info "1c. Backup Nginx config ..."
[[ -d /etc/nginx ]] && cp -rp /etc/nginx "${BACKUP_DIR}/nginx" 2>/dev/null

log_info "1d. Backup SSL certificates ..."
[[ -d /etc/letsencrypt ]] && cp -rp /etc/letsencrypt "${BACKUP_DIR}/letsencrypt" 2>/dev/null
[[ -d /etc/ssl ]] && cp -rp /etc/ssl "${BACKUP_DIR}/ssl" 2>/dev/null

log_info "1e. Backup Guacamole database ..."
DB_CMD=""
command -v mariadb &>/dev/null && DB_CMD="mariadb" || command -v mysql &>/dev/null && DB_CMD="mysql"
if [[ -n "$DB_CMD" ]]; then
    GUAC_DB="${GUAC_DB:-guacamole_db}"
    if $DB_CMD -e "USE ${GUAC_DB}" 2>/dev/null; then
        mysqldump --databases "$GUAC_DB" > "${BACKUP_DIR}/guacamole_db.sql" 2>/dev/null || \
        mariadb-dump --databases "$GUAC_DB" > "${BACKUP_DIR}/guacamole_db.sql" 2>/dev/null || \
        log_warn "Khong the backup database."
    else
        log_warn "Database '${GUAC_DB}' khong ton tai."
    fi
else
    log_warn "Khong tim thay MySQL/MariaDB client."
fi

log_info "1f. Backup danh sach packages ..."
dpkg --get-selections > "${BACKUP_DIR}/packages.list" 2>/dev/null

log_info "1g. Backup extensions/lib JARs ..."
[[ -d /etc/guacamole/extensions ]] && cp -rp /etc/guacamole/extensions "${BACKUP_DIR}/extensions" 2>/dev/null
[[ -d /etc/guacamole/lib ]] && cp -rp /etc/guacamole/lib "${BACKUP_DIR}/lib" 2>/dev/null

log_info "Backup hoan tat tai: ${BACKUP_DIR}"
ls -lh "${BACKUP_DIR}"

log_info "Luu symlink: ${BACKUP_SYMLINK} -> ${BACKUP_DIR}"
rm -f "$BACKUP_SYMLINK"
ln -s "$BACKUP_DIR" "$BACKUP_SYMLINK" 2>/dev/null || true

#######################################################################################################################
# Step 2: Upgrade Ubuntu 22.04 -> 24.04 LTS
#######################################################################################################################

print_section "Buoc 2: Nang cap Ubuntu 22.04 LTS len 24.04 LTS"

log_warn "DAM BAO BAN DA SNAPSHOT VM TRUOC KHI TIEP TUC!"
echo
read -p "Ban co chac muon nang OS len 24.04 LTS? (yes/NO): " CONFIRM_OS
if [[ "$CONFIRM_OS" != "yes" && "$CONFIRM_OS" != "y" && "$CONFIRM_OS" != "Y" && "$CONFIRM_OS" != "YES" ]]; then
    log_info "Da huy. Backup van duoc giu tai: ${BACKUP_DIR}"
    exit 0
fi

log_info "2a. Cap nhat packages hien tai ..."
apt_update_safe && apt_upgrade_safe

log_info "2b. Cai dat update-manager-core ..."
apt_install_safe update-manager-core

log_info "2c. Cau hinh Prompt=normal ..."
sed -i 's/Prompt=never/Prompt=normal/g' /etc/update-manager/release-upgrades 2>/dev/null || true

log_info "2d. Dung truoc khi nang OS ..."
systemctl stop "$TOMCAT_VERSION" 2>/dev/null || true
systemctl stop guacd 2>/dev/null || true

log_info "2e. Bat dau nang cap len Ubuntu 24.04 LTS ..."
log_warn "Qua trinh nay se mat nhieu thoi gian. SSH co the bi ngat."
echo -e "${LYELLOW}Khong tat may hoac ngat ket noi giua chung!${NC}"
echo
do-release-upgrade -f DistUpgradeViewNonInteractive || \
do-release-upgrade || \
log_warn "do-release-upgrade khong thanh cong. Chay thu cong: sudo do-release-upgrade"

log_info "Hoan thanh nang OS. Chuan bi reboot ..."
log_warn "SAU KHI REBOOT, chay: sudo bash $0 --after-os-upgrade"
echo
read -p "Reboot ngay bay gio? (yes/NO): " REBOOT_NOW
if [[ "$REBOOT_NOW" == "yes" || "$REBOOT_NOW" == "y" || "$REBOOT_NOW" == "Y" || "$REBOOT_NOW" == "YES" ]]; then
    reboot
fi
exit 0
