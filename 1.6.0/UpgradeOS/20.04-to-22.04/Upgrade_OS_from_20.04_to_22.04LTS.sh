#!/bin/bash
#######################################################################################################################
# Upgrade Ubuntu OS + Guacamole 1.5.5 -> 1.6.0
# OS: 20.04 LTS -> 22.04 LTS (optional: 24.04 LTS)
# For Ubuntu / Debian
# Guacamole 1.6.0 May 2026
#######################################################################################################################
# IMPORTANT: Run this script as root or with sudo
# Usage:
#   Phase 1: sudo bash Upgrade_OS_from_20.04_to_22.04LTS.sh
#   Phase 2: sudo bash Upgrade_OS_from_20.04_to_22.04LTS.sh --after-os-upgrade
#   Restore: sudo bash Upgrade_OS_from_20.04_to_22.04LTS.sh --restore-backup /path/to/backup
#######################################################################################################################

set -e

#######################################################################################################################
# Script pre-flight checks and settings
#######################################################################################################################

clear

GREY='\033[0;37m'
DGREY='\033[0;90m'
GREYB='\033[1;37m'
LRED='\033[0;91m'
LGREEN='\033[0;92m'
LYELLOW='\033[0;93m'
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
DOWNLOAD_DIR=/tmp/guac-upgrade
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

#######################################################################################################################
# Helper functions
#######################################################################################################################

log_info()  { echo -e "${LGREEN}[INFO]${GREY}  $(date '+%Y-%m-%d %H:%M:%S') - $1${NC}"; }
log_warn()  { echo -e "${LYELLOW}[WARN]${GREY}  $(date '+%Y-%m-%d %H:%M:%S') - $1${NC}"; }
log_error() { echo -e "${LRED}[ERROR]${GREY} $(date '+%Y-%m-%d %H:%M:%S') - $1${NC}"; }

check_success() {
    if [[ $? -ne 0 ]]; then
        log_error "$1"
        exit 1
    fi
}

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

#######################################################################################################################
# Mode dispatch: checked BEFORE default backup/OS-upgrade flow
#######################################################################################################################

case "${1:-}" in
    --after-os-upgrade)
        cd "$SCRIPT_DIR"

        # Read backup path from symlink left by Phase 1
        if [[ -L "$BACKUP_SYMLINK" && -d "$BACKUP_SYMLINK" ]]; then
            BACKUP_DIR=$(readlink -f "$BACKUP_SYMLINK" 2>/dev/null || echo "")
        else
            BACKUP_DIR=""
        fi
        INSTALL_LOG="${BACKUP_DIR:-/tmp}/upgrade-os-guac.log"
        mkdir -p "$(dirname "$INSTALL_LOG")"
        exec > >(tee -a "$INSTALL_LOG") 2>&1

        source /etc/os-release
        print_section "Buoc 3: Nang cap Guacamole len ${GUAC_VERSION} tren ${NAME} ${VERSION_ID}"

        TOMCAT_VERSION=$(detect_tomcat)
        log_info "Tomcat: ${TOMCAT_VERSION}"

        # Detect current Guacamole version
        OLD_GUAC_VERSION="1.5.5"
        GUAC_VERSION_FILE="/var/lib/${TOMCAT_VERSION}/webapps/guacamole/guacamole-common-js/modules/Version.js"
        if [[ -f "$GUAC_VERSION_FILE" ]]; then
            OLD_GUAC_VERSION=$(grep -oP 'Guacamole\.API_VERSION = "\K[0-9\.]+' "$GUAC_VERSION_FILE" 2>/dev/null || echo "1.5.5")
        fi
        log_info "Guacamole hien tai: ${OLD_GUAC_VERSION} -> ${GUAC_VERSION}"

        GUAC_SOURCE_LINK="http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${GUAC_VERSION}"

        mkdir -p "$DOWNLOAD_DIR"

        # 3a: Update packages
        log_info "3a. Cap nhat he thong packages ..."
        apt update -qq && apt upgrade -y -qq
        check_success "apt update/upgrade that bai"

        # 3b: Install Tomcat if missing
        if ! systemctl list-units --type=service 2>/dev/null | grep -q "${TOMCAT_VERSION}"; then
            log_warn "Tomcat chua duoc cai. Cai tomcat9 ..."
            apt install -y tomcat9 tomcat9-admin tomcat9-common tomcat9-user
            TOMCAT_VERSION="tomcat9"
        fi

        # 3c: Stop services
        log_info "3c. Dung Tomcat va guacd ..."
        systemctl stop "$TOMCAT_VERSION" 2>/dev/null || true
        systemctl stop guacd 2>/dev/null || true

        # 3d: Install OS dependencies for Guacamole
        log_info "3d. Cai dependencies cho Guacamole ${GUAC_VERSION} ..."
        apt install -y build-essential libcairo2-dev libjpeg-turbo8-dev libpng-dev \
                       libtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev \
                       libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev \
                       libtelnet-dev libvncserver-dev libwebsockets-dev libpulse-dev \
                       libssl-dev libvorbis-dev libwebp-dev libsdl2-dev
        check_success "Cai dependencies that bai"

        cd "$DOWNLOAD_DIR"

        # 3e: Download and upgrade Guacamole client (.war)
        log_info "3e. Download Guacamole ${GUAC_VERSION}.war ..."
        wget -q --show-progress -O "guacamole-${GUAC_VERSION}.war" \
            "${GUAC_SOURCE_LINK}/binary/guacamole-${GUAC_VERSION}.war"
        check_success "Download guacamole-${GUAC_VERSION}.war that bai"
        rm -f /etc/guacamole/guacamole.war
        mv -f "guacamole-${GUAC_VERSION}.war" /etc/guacamole/guacamole.war
        chmod 664 /etc/guacamole/guacamole.war
        log_info "Guacamole client upgraded to ${GUAC_VERSION}"

        # 3f: Download JDBC auth
        log_info "3f. Download Guacamole JDBC auth ..."
        wget -q --show-progress -O "guacamole-auth-jdbc-${GUAC_VERSION}.tar.gz" \
            "${GUAC_SOURCE_LINK}/binary/guacamole-auth-jdbc-${GUAC_VERSION}.tar.gz"
        check_success "Download guacamole-auth-jdbc that bai"
        tar -xzf "guacamole-auth-jdbc-${GUAC_VERSION}.tar.gz"
        rm -f /etc/guacamole/extensions/guacamole-auth-jdbc-*.jar
        mv -f "guacamole-auth-jdbc-${GUAC_VERSION}/mysql/guacamole-auth-jdbc-mysql-${GUAC_VERSION}.jar" \
            /etc/guacamole/extensions/
        chmod 664 "/etc/guacamole/extensions/guacamole-auth-jdbc-mysql-${GUAC_VERSION}.jar"
        log_info "JDBC auth upgraded to ${GUAC_VERSION}"

        # 3g: Download MySQL connector
        log_info "3g. Download MySQL Connector/J ..."
        wget -q --show-progress -O "mysql-connector-j-${MYSQLJCON}.tar.gz" \
            "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-j-${MYSQLJCON}.tar.gz"
        check_success "Download MySQL Connector that bai"
        tar -xzf "mysql-connector-j-${MYSQLJCON}.tar.gz"
        rm -f /etc/guacamole/lib/mysql-connector-java.jar
        mv -f "mysql-connector-j-${MYSQLJCON}/mysql-connector-j-${MYSQLJCON}.jar" \
            /etc/guacamole/lib/mysql-connector-java.jar
        log_info "MySQL Connector/J upgraded"

        # 3h: Download optional extensions (TOTP, Duo, LDAP, QuickConnect, HistRec)
        log_info "3h. Download optional extensions ..."
        for EXT in guacamole-auth-totp guacamole-auth-duo guacamole-auth-ldap \
                   guacamole-auth-quickconnect guacamole-history-recording-storage; do
            wget -q --show-progress -O "${EXT}-${GUAC_VERSION}.tar.gz" \
                "${GUAC_SOURCE_LINK}/binary/${EXT}-${GUAC_VERSION}.tar.gz" 2>/dev/null || continue
            tar -xzf "${EXT}-${GUAC_VERSION}.tar.gz"
            rm -f "/etc/guacamole/extensions/${EXT}-"*.jar
            mv -f "${EXT}-${GUAC_VERSION}/${EXT}-${GUAC_VERSION}.jar" /etc/guacamole/extensions/ 2>/dev/null || true
            log_info "  Installed ${EXT}"
        done

        # 3i: Download and compile guacamole-server
        log_info "3i. Build Guacamole Server tu source ..."
        wget -q --show-progress -O "guacamole-server-${GUAC_VERSION}.tar.gz" \
            "${GUAC_SOURCE_LINK}/source/guacamole-server-${GUAC_VERSION}.tar.gz"
        check_success "Download guacamole-server that bai"
        tar -xzf "guacamole-server-${GUAC_VERSION}.tar.gz"
        cd "guacamole-server-${GUAC_VERSION}/"

        export CFLAGS="-Wno-error"
        log_info "Configuring guacamole-server ..."
        ./configure --with-systemd-dir=/etc/systemd/system &>>"${INSTALL_LOG}"
        check_success "Configure guacamole-server that bai"

        log_info "Compiling guacamole-server ..."
        make &>>"${INSTALL_LOG}"
        check_success "Make guacamole-server that bai"

        log_info "Installing guacamole-server ..."
        make install &>>"${INSTALL_LOG}"
        ldconfig
        log_info "Guacamole Server ${GUAC_VERSION} installed"

        cd "$DOWNLOAD_DIR"

        # 3j: Upgrade database schema
        log_info "3j. Nang cap database schema ..."
        if [[ -f /etc/guacamole/guacamole.properties ]]; then
            GUAC_DB=$(grep -oP 'mysql-database:\s*\K.*' /etc/guacamole/guacamole.properties 2>/dev/null || echo "guacamole_db")
            MYSQL_HOST=$(grep -oP 'mysql-hostname:\s*\K.*' /etc/guacamole/guacamole.properties 2>/dev/null || echo "localhost")
            MYSQL_PORT=$(grep -oP 'mysql-port:\s*\K.*' /etc/guacamole/guacamole.properties 2>/dev/null || echo "3306")

            UPGRADEFILES=($(ls -1 "guacamole-auth-jdbc-${GUAC_VERSION}/mysql/schema/upgrade/" 2>/dev/null | sort -V || true))
            for FILE in "${UPGRADEFILES[@]}"; do
                log_info "Applying schema upgrade: ${FILE} ..."
                mysql -u root -D "$GUAC_DB" -h "$MYSQL_HOST" -P "$MYSQL_PORT" \
                    < "guacamole-auth-jdbc-${GUAC_VERSION}/mysql/schema/upgrade/${FILE}" \
                    &>>"${INSTALL_LOG}" || \
                log_warn "Schema upgrade ${FILE} that bai (co the da duoc ap dung truoc do)"
            done
        else
            log_warn "Khong tim thay guacamole.properties, bo qua schema upgrade."
        fi

        # 3k: Restore DB backup if found from Phase 1
        print_section "Buoc 4: Restore Database tu backup (neu co)"
        if [[ -n "$BACKUP_DIR" && -f "${BACKUP_DIR}/guacamole_db.sql" ]]; then
            log_info "Tim thay backup tu Phase 1: ${BACKUP_DIR}/guacamole_db.sql"
            read -p "Restore database tu file backup? (yes/NO): " RESTORE_DB
            if [[ "$RESTORE_DB" == "yes" ]]; then
                GUAC_DB="${GUAC_DB:-guacamole_db}"
                log_info "Restoring database ..."
                mysql -u root -D "$GUAC_DB" < "${BACKUP_DIR}/guacamole_db.sql" 2>/dev/null || \
                log_warn "Restore that bai. Chay thu cong: mysql -u root -D ${GUAC_DB} < ${BACKUP_DIR}/guacamole_db.sql"
                log_info "Database restored."
            fi
        else
            log_info "Khong co file backup database. Bo qua restore."
        fi

        # 3l: Set permissions
        chown -R daemon:daemon /etc/guacamole 2>/dev/null || true
        chmod -R 664 /etc/guacamole/extensions/*.jar 2>/dev/null || true
        chmod 664 /etc/guacamole/guacamole.war 2>/dev/null || true

        # 3m: Start services
        log_info "Khoi dong lai services ..."
        systemctl daemon-reload
        systemctl enable guacd
        systemctl start guacd
        systemctl start "$TOMCAT_VERSION"

        # 3n: Cleanup
        cd /
        rm -rf "$DOWNLOAD_DIR"

        print_section "Hoan tat!"
        echo -e "${LGREEN}Guacamole ${GUAC_VERSION} upgrade hoan tat!${NC}"
        echo
        echo -e "${GREY}Backup (tu Phase 1) duoc luu tai: ${BACKUP_DIR:-Khong co}${NC}"
        echo -e "${GREY}Log file: ${INSTALL_LOG}${NC}"
        echo
        echo -e "Truy cap: ${LYELLOW}http://<server-ip>:8080/guacamole${NC}"
        echo
        exit 0
        ;;

    --restore-backup)
        print_section "Restore Guacamole tu backup"

        if [[ -z "${2:-}" ]]; then
            log_error "Can chi dinh duong dan backup."
            echo "Vi du: $0 --restore-backup /opt/backup/guacamole-backup-20260529-120000"
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
        log_info "Tomcat: ${TOMCAT_VERSION}"

        systemctl stop "$TOMCAT_VERSION" 2>/dev/null || true
        systemctl stop guacd 2>/dev/null || true

        if [[ -d "${RESTORE_PATH}/guacamole-etc" ]]; then
            cp -rp "${RESTORE_PATH}/guacamole-etc"/* /etc/guacamole/ 2>/dev/null
            log_info "Restored /etc/guacamole/"
        fi

        if [[ -d "${RESTORE_PATH}/nginx" ]]; then
            cp -rp "${RESTORE_PATH}/nginx"/* /etc/nginx/ 2>/dev/null
            log_info "Restored /etc/nginx/"
            nginx -t &>/dev/null && systemctl reload nginx 2>/dev/null || log_warn "Nginx config co van de, kiem tra thu cong"
        fi

        if [[ -d "${RESTORE_PATH}/letsencrypt" ]]; then
            cp -rp "${RESTORE_PATH}/letsencrypt"/* /etc/letsencrypt/ 2>/dev/null
            log_info "Restored /etc/letsencrypt/"
        fi

        if [[ -d "${RESTORE_PATH}/ssl" ]]; then
            cp -rp "${RESTORE_PATH}/ssl"/* /etc/ssl/ 2>/dev/null
            log_info "Restored /etc/ssl/"
        fi

        if [[ -d "${RESTORE_PATH}/tomcat-webapps" ]]; then
            cp -rp "${RESTORE_PATH}/tomcat-webapps"/* "/var/lib/${TOMCAT_VERSION}/webapps/" 2>/dev/null
            log_info "Restored Tomcat webapps"
        fi

        if [[ -f "${RESTORE_PATH}/guacamole_db.sql" ]]; then
            read -p "Restore database tu file backup? (yes/NO): " RESTORE_DB
            if [[ "$RESTORE_DB" == "yes" ]]; then
                GUAC_DB="${GUAC_DB:-guacamole_db}"
                mysql -u root -D "$GUAC_DB" < "${RESTORE_PATH}/guacamole_db.sql" 2>/dev/null && \
                log_info "Database restored." || \
                log_error "Restore database that bai"
            fi
        fi

        systemctl daemon-reload
        systemctl start guacd
        systemctl start "$TOMCAT_VERSION"

        log_info "Restore hoan tat!"
        echo -e "${GREY}Log file: ${INSTALL_LOG}${NC}"
        exit 0
        ;;

    --help|-h)
        echo "Usage:"
        echo "  sudo bash $0                              # Phase 1: backup + upgrade OS"
        echo "  sudo bash $0 --after-os-upgrade            # Phase 2: sau reboot, upgrade Guacamole"
        echo "  sudo bash $0 --restore-backup /path        # Restore tu backup"
        echo "  sudo bash $0 --help                        # Hien thi tro giup"
        exit 0
        ;;
esac

#######################################################################################################################
# DEFAULT MODE (no flag / Phase 1): Backup -> Upgrade OS -> Reboot
#######################################################################################################################

BACKUP_DIR="/opt/backup/guacamole-backup-$(date +%Y%m%d-%H%M%S)"
INSTALL_LOG="${BACKUP_DIR}/upgrade-os-guac.log"

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
log_info "Phien ban Ubuntu hien tai: $CURRENT_OS_VERSION"

if [[ "$CURRENT_OS_VERSION" != "20.04" ]]; then
    log_warn "Ban dang chay Ubuntu ${CURRENT_OS_VERSION}."
    log_info "Phase 1 chi danh cho Ubuntu 20.04 LTS."
    log_info "Neu ban can nang Guacamole, hay chay: $0 --after-os-upgrade"
    log_info "Neu ban can restore backup, hay chay: $0 --restore-backup /path/to/backup"
    exit 1
fi

#######################################################################################################################
# Step 1: Full backup
#######################################################################################################################

print_section "Buoc 1: Backup toan bo cau hinh Guacamole va Database"

log_info "Tao thu muc backup: ${BACKUP_DIR}"

# 1a: Backup Guacamole config
log_info "1a. Backup /etc/guacamole/ ..."
if [[ -d /etc/guacamole ]]; then
    cp -rp /etc/guacamole "${BACKUP_DIR}/guacamole-etc" 2>/dev/null || log_warn "Khong tim thay /etc/guacamole"
fi

TOMCAT_VERSION=$(detect_tomcat)

# 1b: Backup Tomcat webapps
log_info "1b. Backup Tomcat (${TOMCAT_VERSION}) webapps ..."
if [[ -d "/var/lib/${TOMCAT_VERSION}/webapps" ]]; then
    cp -rp "/var/lib/${TOMCAT_VERSION}/webapps" "${BACKUP_DIR}/tomcat-webapps" 2>/dev/null || log_warn "Khong tim thay Tomcat webapps"
fi

# 1c: Backup Nginx config
log_info "1c. Backup Nginx config ..."
if [[ -d /etc/nginx ]]; then
    cp -rp /etc/nginx "${BACKUP_DIR}/nginx" 2>/dev/null || log_warn "Khong tim thay /etc/nginx"
fi

# 1d: Backup SSL certificates
log_info "1d. Backup SSL certificates ..."
if [[ -d /etc/letsencrypt ]]; then
    cp -rp /etc/letsencrypt "${BACKUP_DIR}/letsencrypt" 2>/dev/null || log_warn "Khong tim thay /etc/letsencrypt"
fi
if [[ -d /etc/ssl ]]; then
    cp -rp /etc/ssl "${BACKUP_DIR}/ssl" 2>/dev/null || log_warn "Khong tim thay /etc/ssl"
fi

# 1e: Backup MySQL/MariaDB database
log_info "1e. Backup Guacamole database ..."
DB_CMD=""
if command -v mariadb &>/dev/null; then
    DB_CMD="mariadb"
elif command -v mysql &>/dev/null; then
    DB_CMD="mysql"
fi

if [[ -n "$DB_CMD" ]]; then
    GUAC_DB="${GUAC_DB:-guacamole_db}"
    if $DB_CMD -e "USE ${GUAC_DB}" 2>/dev/null; then
        mysqldump --databases "$GUAC_DB" > "${BACKUP_DIR}/guacamole_db.sql" 2>/dev/null || \
        mariadb-dump --databases "$GUAC_DB" > "${BACKUP_DIR}/guacamole_db.sql" 2>/dev/null || \
        log_warn "Khong the backup database. Ban can nhap password MySQL thu cong."
    else
        log_warn "Database '${GUAC_DB}' khong ton tai hoac khong truy cap duoc."
    fi
else
    log_warn "Khong tim thay MySQL/MariaDB client."
fi

# 1f: Backup list installed packages
log_info "1f. Backup danh sach packages ..."
dpkg --get-selections > "${BACKUP_DIR}/packages.list" 2>/dev/null

# 1g: Backup extensions/lib JARs
log_info "1g. Backup extensions/lib JARs ..."
if [[ -d /etc/guacamole/extensions ]]; then
    cp -rp /etc/guacamole/extensions "${BACKUP_DIR}/extensions" 2>/dev/null
fi
if [[ -d /etc/guacamole/lib ]]; then
    cp -rp /etc/guacamole/lib "${BACKUP_DIR}/lib" 2>/dev/null
fi

# 1h: Backup cac script cai dat goc
log_info "1h. Backup guacamole install scripts ..."
if [[ -d "$USER_HOME_DIR/guac-setup" ]]; then
    cp -rp "$USER_HOME_DIR/guac-setup" "${BACKUP_DIR}/guac-setup" 2>/dev/null
fi

log_info "Backup hoan tat tai: ${BACKUP_DIR}"
ls -lh "${BACKUP_DIR}"

# Save symlink to latest backup for --after-os-upgrade to find
log_info "Luu duong dan backup: ${BACKUP_SYMLINK} -> ${BACKUP_DIR}"
rm -f "$BACKUP_SYMLINK"
ln -s "$BACKUP_DIR" "$BACKUP_SYMLINK" 2>/dev/null || true

#######################################################################################################################
# Step 2: Upgrade Ubuntu 20.04 -> 22.04 LTS
#######################################################################################################################

print_section "Buoc 2: Nang cap Ubuntu ${CURRENT_OS_VERSION} len 22.04 LTS"

log_warn "Dam bao ban da backup du lieu quan trong truoc khi nang cap OS!"
echo
read -p "Ban co chac muon tiep tuc nang cap OS? (yes/NO): " CONFIRM_OS
if [[ "$CONFIRM_OS" != "yes" ]]; then
    log_info "Da huy nang cap OS. Backup van duoc giu tai: ${BACKUP_DIR}"
    exit 0
fi

# 2a: Update all current packages
log_info "2a. Cap nhat packages hien tai ..."
apt update -qq && apt upgrade -y -qq
check_success "apt update/upgrade that bai"

# 2b: Install update-manager-core
log_info "2b. Cai dat update-manager-core ..."
apt install -y update-manager-core
check_success "Cai dat update-manager-core that bai"

# 2c: Ensure Prompt=normal in release-upgrades
log_info "2c. Cau hinh /etc/update-manager/release-upgrades ..."
sed -i 's/Prompt=never/Prompt=normal/g' /etc/update-manager/release-upgrades 2>/dev/null || true

# 2d: Stop Tomcat and guacd before upgrade
log_info "2d. Dung Tomcat va guacd truoc khi nang OS ..."
systemctl stop "$TOMCAT_VERSION" 2>/dev/null || true
systemctl stop guacd 2>/dev/null || true

# 2e: Run do-release-upgrade
log_info "2e. Bat dau nang cap len Ubuntu 22.04 LTS ..."
log_warn "Qua trinh nay se mat nhieu thoi gian. SSH co the bi ngat ket noi."
echo
do-release-upgrade -f DistUpgradeViewNonInteractive || \
do-release-upgrade || \
log_warn "do-release-upgrade khong thanh cong. Chay thu cong: sudo do-release-upgrade"

log_info "Khoi dong lai he thong sau khi nang cap OS ..."
log_warn "SAU KHI REBOOT, chay lai script nay voi tham so --after-os-upgrade"
echo
read -p "Reboot ngay bay gio? (yes/NO): " REBOOT_NOW
if [[ "$REBOOT_NOW" == "yes" ]]; then
    reboot
fi
exit 0
