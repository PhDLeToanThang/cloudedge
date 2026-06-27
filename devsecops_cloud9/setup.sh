#!/bin/bash -e
#
# setup.sh — Cloud9 Web IDE Installer for Ubuntu 24.04 LTS
# =========================================================
# Tác giả: PhD. Lê Toàn Thắng
#
# Script tự động cài đặt Cloud9 Core SDK trên Ubuntu 24.04 LTS:
#   - Nginx reverse proxy với WebSocket support
#   - Let's Encrypt SSL (hoặc OpenSSL self-signed fallback)
#   - Systemd service quản lý Cloud9 server
#   - UFW firewall
#
# Cách dùng:
#   sudo bash setup.sh                    # Interactive mode
#   sudo bash setup.sh --domain c9.example.com --email admin@example.com   # Non-interactive
#
# Hỗ trợ:
#   --domain <domain>     Tên miền (để trống = self-signed)
#   --email <email>       Email cho Let's Encrypt
#   --user <username>     Username đăng nhập Cloud9
#   --password <pass>     Password đăng nhập Cloud9
#   --workspace <path>    Đường dẫn workspace
#   --help                Hiển thị trợ giúp
#
# Biến môi trường:
#   C9_WORKSPACE          Đường dẫn workspace (overrides --workspace)
# =========================================================

set -e

# ─── Màu sắc ───────────────────────────────────────────────────────────
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
reset='\033[0m'

# ─── Helper functions ──────────────────────────────────────────────────
info()  { echo -e "${cyan}[INFO]${reset}  $1"; }
ok()    { echo -e "${green}[OK]${reset}    $1"; }
warn()  { echo -e "${yellow}[WARN]${reset}  $1"; }
error() { echo -e "${red}[ERROR]${reset} $1"; }
header() {
    echo ""
    echo -e "${magenta}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    echo -e "${magenta}  $1${reset}"
    echo -e "${magenta}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}"
    echo ""
}

# ─── Parse arguments ───────────────────────────────────────────────────
DOMAIN=""
EMAIL=""
AUTH_USER=""
AUTH_PASS=""
C9_WORKSPACE="${C9_WORKSPACE:-}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)   DOMAIN="$2"; shift 2 ;;
        --email)    EMAIL="$2"; shift 2 ;;
        --user)     AUTH_USER="$2"; shift 2 ;;
        --password) AUTH_PASS="$2"; shift 2 ;;
        --workspace) C9_WORKSPACE="$2"; shift 2 ;;
        --help)
            echo "Cloud9 Web IDE Installer for Ubuntu 24.04 LTS"
            echo ""
            echo "Usage: sudo bash setup.sh [options]"
            echo ""
            echo "Options:"
            echo "  --domain <domain>     Domain name (empty = self-signed SSL)"
            echo "  --email <email>       Email for Let's Encrypt"
            echo "  --user <username>     Cloud9 login username"
            echo "  --password <pass>     Cloud9 login password"
            echo "  --workspace <path>    Workspace directory path"
            echo "  --help                Show this help"
            echo ""
            echo "Environment variables:"
            echo "  C9_WORKSPACE          Workspace path (overrides --workspace)"
            exit 0
            ;;
        *)  error "Unknown option: $1"; exit 1 ;;
    esac
done

# ─── Check root ────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    error "Script này cần chạy với quyền root (sudo)."
    exit 1
fi

# ─── Banner ────────────────────────────────────────────────────────────
echo ""
echo -e "${green}  ╔══════════════════════════════════════════════════════════════╗${reset}"
echo -e "${green}  ║            Cloud9 Web IDE Installer v1.0                    ║${reset}"
echo -e "${green}  ║          Ubuntu 24.04 LTS — Nginx — Let's Encrypt           ║${reset}"
echo -e "${green}  ╚══════════════════════════════════════════════════════════════╝${reset}"
echo ""

# ─── Interactive input ─────────────────────────────────────────────────
echo -e "${yellow}--- Nhập thông tin cấu hình (để trống nếu không có) ---${reset}"
echo ""

# Domain
if [[ -z "$DOMAIN" ]]; then
    read -r -p "Nhập domain (để trống = dùng self-signed SSL): " DOMAIN
fi

# Email (for Let's Encrypt)
if [[ -n "$DOMAIN" ]] && [[ -z "$EMAIL" ]]; then
    read -r -p "Nhập email cho Let's Encrypt (để trống = admin@$DOMAIN): " EMAIL
    if [[ -z "$EMAIL" ]]; then
        EMAIL="admin@$DOMAIN"
    fi
fi

# Auth username
while [[ -z "$AUTH_USER" ]]; do
    read -r -p "Nhập username đăng nhập Cloud9: " AUTH_USER
    if [[ -z "$AUTH_USER" ]]; then
        error "Username không được để trống."
    fi
done

# Auth password
while [[ -z "$AUTH_PASS" ]]; do
    read -r -s -p "Nhập password đăng nhập Cloud9: " AUTH_PASS
    echo ""
    if [[ ${#AUTH_PASS} -lt 8 ]]; then
        error "Password phải có ít nhất 8 ký tự."
        AUTH_PASS=""
    else
        read -r -s -p "Xác nhận password: " AUTH_PASS_CONFIRM
        echo ""
        if [[ "$AUTH_PASS" != "$AUTH_PASS_CONFIRM" ]]; then
            error "Password không khớp. Vui lòng nhập lại."
            AUTH_PASS=""
        fi
    fi
done

# Workspace
if [[ -z "$C9_WORKSPACE" ]]; then
    read -r -p "Nhập đường dẫn workspace (để trống = /home/cloud9/workspace): " C9_WORKSPACE
    if [[ -z "$C9_WORKSPACE" ]]; then
        C9_WORKSPACE="/home/cloud9/workspace"
    fi
fi

echo ""
echo -e "${cyan}Thông tin cấu hình:${reset}"
echo -e "  Domain:     ${green}${DOMAIN:-(self-signed)}${reset}"
echo -e "  Username:   ${green}$AUTH_USER${reset}"
echo -e "  Workspace:  ${green}$C9_WORKSPACE${reset}"
echo ""
read -r -p "Xác nhận cài đặt? (y/N): " CONFIRM
if [[ "$CONFIRM" != "y" ]] && [[ "$CONFIRM" != "Y" ]]; then
    info "Huỷ cài đặt."
    exit 0
fi

# ─── Variables ─────────────────────────────────────────────────────────
C9_DIR="/opt/c9sdk"
C9_USER="cloud9"
C9_SERVICE="cloud9"
NODE_VERSION="16"
NVM_VERSION="v0.39.7"
START_TIME=$(date +%s)

# ───────────────────────────────────────────────────────────────────────
header "Phase 1/8: Cập nhật hệ thống và cài dependencies"
# ───────────────────────────────────────────────────────────────────────

apt update
apt upgrade -y

apt install -y \
    build-essential \
    git \
    curl \
    wget \
    tmux \
    nginx \
    python3 \
    python3-pip \
    python3-venv \
    certbot \
    ufw

ok "System packages installed."

# ───────────────────────────────────────────────────────────────────────
header "Phase 2/8: Cài đặt Node.js $NODE_VERSION qua nvm"
# ───────────────────────────────────────────────────────────────────────

if ! command -v nvm &>/dev/null && [[ ! -f "$HOME/.nvm/nvm.sh" ]]; then
    info "Installing nvm $NVM_VERSION..."
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh" | bash
    export NVM_DIR="$HOME/.nvm"
    # shellcheck disable=SC1091
    [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
    ok "nvm installed."
else
    info "nvm already installed."
    export NVM_DIR="$HOME/.nvm"
    [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
fi

if ! nvm ls "$NODE_VERSION" &>/dev/null; then
    info "Installing Node.js v$NODE_VERSION.x..."
    nvm install "$NODE_VERSION"
    nvm alias default "$NODE_VERSION"
    ok "Node.js $(node --version) installed."
else
    info "Node.js v$NODE_VERSION already installed."
    nvm use "$NODE_VERSION"
fi

npm config set python python3
npm config set legacy-peer-deps true

# Determine Node.js binary path for later use
NODE_BIN=$(which node)
NODE_BIN_FULL=$(readlink -f "$NODE_BIN" 2>/dev/null || echo "$NODE_BIN")
NODE_VERSION_FULL=$(node --version 2>/dev/null || echo "v16.20.2")
ok "Node.js $NODE_VERSION_FULL at $NODE_BIN_FULL"

# ───────────────────────────────────────────────────────────────────────
header "Phase 3/8: Clone c9/core"
# ───────────────────────────────────────────────────────────────────────

if [[ -d "$C9_DIR" ]]; then
    warn "$C9_DIR đã tồn tại. Bỏ qua clone."
    cd "$C9_DIR"
else
    mkdir -p /opt
    git clone https://github.com/c9/core.git "$C9_DIR"
    ok "Cloned c9/core vào $C9_DIR"
    cd "$C9_DIR"
fi

# ───────────────────────────────────────────────────────────────────────
header "Phase 4/8: Cài npm dependencies"
# ───────────────────────────────────────────────────────────────────────

info "Running npm install (legacy-peer-deps)..."
npm install --legacy-peer-deps 2>&1 | tail -5
ok "npm dependencies installed."

# ───────────────────────────────────────────────────────────────────────
header "Phase 5/8: Patch node-pty cho terminal support"
# ───────────────────────────────────────────────────────────────────────

info "Removing node-pty-prebuilt (incompatible with Node 16+)..."
npm uninstall node-pty-prebuilt 2>/dev/null || true

info "Installing node-pty@0.10.1..."
npm install node-pty@0.10.1 2>&1 | tail -3

info "Patching require paths in plugins..."
find plugins -name "*.js" -type f -exec \
    sed -i 's/require("node-pty-prebuilt")/require("node-pty")/g' {} + 2>/dev/null || true
find plugins -name "package.json" -type f -exec \
    sed -i 's/node-pty-prebuilt/node-pty/g' {} + 2>/dev/null || true

ok "Terminal support patched."

# ───────────────────────────────────────────────────────────────────────
header "Phase 6/8: Tạo user và workspace"
# ───────────────────────────────────────────────────────────────────────

if ! id "$C9_USER" &>/dev/null; then
    useradd -m -s /bin/bash -d "/home/$C9_USER" "$C9_USER"
    ok "User $C9_USER created."
else
    info "User $C9_USER already exists."
fi

mkdir -p "$C9_WORKSPACE"
chown -R "$C9_USER:$C9_USER" "$C9_WORKSPACE"
chown -R "$C9_USER:$C9_USER" "$C9_DIR"
ok "Workspace $C9_WORKSPACE ready."

# ───────────────────────────────────────────────────────────────────────
header "Phase 7/8: Cấu hình systemd, Nginx, SSL"
# ───────────────────────────────────────────────────────────────────────

# ── 7a. Systemd service ────────────────────────────────────────────────
info "Creating systemd service..."

SYSTEMD_FILE="/etc/systemd/system/$C9_SERVICE.service"

cat > "$SYSTEMD_FILE" << EOF
[Unit]
Description=Cloud9 Web IDE
Documentation=https://github.com/c9/core
After=network.target nginx.service
Wants=nginx.service

[Service]
Type=simple
User=$C9_USER
Group=$C9_USER
WorkingDirectory=$C9_DIR

ExecStart=$NODE_BIN_FULL \\
  $C9_DIR/server.js \\
  -l 127.0.0.1 \\
  -p 8181 \\
  -w $C9_WORKSPACE \\
  -a $AUTH_USER:$AUTH_PASS \\
  --packed

Restart=always
RestartSec=15

Environment=NODE_ENV=production
Environment=NODE_PATH=$C9_DIR/node_modules
Environment=C9_WORKSPACE=$C9_WORKSPACE

NoNewPrivileges=true
ProtectSystem=full
PrivateTmp=true

StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$C9_SERVICE"
ok "Systemd service $C9_SERVICE created and enabled."

# ── 7b. Nginx config ───────────────────────────────────────────────────
info "Configuring Nginx..."

if [[ -n "$DOMAIN" ]]; then
    NGINX_DOMAIN="$DOMAIN"
else
    NGINX_DOMAIN=$(hostname -f 2>/dev/null || hostname)
fi

# Determine SSL paths
if [[ -n "$DOMAIN" ]]; then
    # Let's Encrypt paths
    SSL_CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
    SSL_KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"
else
    # Self-signed paths
    SSL_CERT="/etc/ssl/cloud9/cloud9.crt"
    SSL_KEY="/etc/ssl/cloud9/cloud9.key"
fi

cat > /etc/nginx/sites-available/cloud9 << NGINXEOF
# HTTP → HTTPS redirect
server {
    listen 80;
    server_name $NGINX_DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $NGINX_DOMAIN;

    ssl_certificate     $SSL_CERT;
    ssl_certificate_key $SSL_KEY;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";

    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;

    location / {
        proxy_pass http://127.0.0.1:8181;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
        proxy_buffering off;
    }

    location /static/ {
        proxy_pass http://127.0.0.1:8181/static/;
        proxy_cache_valid 200 302 60m;
        proxy_cache_valid 404 1m;
        expires 7d;
        add_header Cache-Control "public, immutable";
    }

    location ~ /\.(git|env|svn) {
        deny all;
        return 404;
    }

    client_max_body_size 100M;
}
NGINXEOF

ln -sf /etc/nginx/sites-available/cloud9 /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Map for WebSocket
if ! grep -q "map \$http_upgrade" /etc/nginx/nginx.conf; then
    sed -i '/^http {/a \    map \$http_upgrade \$connection_upgrade {\n        default upgrade;\n        '"''"' close;\n    }' /etc/nginx/nginx.conf
fi

nginx -t && systemctl reload nginx
ok "Nginx configured for $NGINX_DOMAIN."

# ── 7c. SSL ────────────────────────────────────────────────────────────
if [[ -n "$DOMAIN" ]]; then
    # Let's Encrypt
    if certbot --nginx --non-interactive --agree-tos \
        -m "$EMAIL" \
        -d "$DOMAIN" 2>&1; then
        ok "Let's Encrypt SSL certificate obtained for $DOMAIN."

        # Setup auto-renewal cron
        (crontab -l 2>/dev/null | grep -q "certbot renew") || {
            (crontab -l 2>/dev/null; echo "0 3 * * * /usr/bin/certbot renew --quiet --no-self-upgrade") | crontab -
            ok "Certbot auto-renewal cron job installed."
        }
    else
        warn "Let's Encrypt failed. Kiểm tra DNS record cho $DOMAIN."
        warn "Tạo self-signed certificate fallback..."

        mkdir -p /etc/ssl/cloud9
        openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
            -keyout /etc/ssl/cloud9/cloud9.key \
            -out /etc/ssl/cloud9/cloud9.crt \
            -subj "/C=VN/ST=Hanoi/L=Hanoi/O=Cloud9/CN=$DOMAIN" 2>/dev/null

        # Update Nginx config to use self-signed cert
        sed -i "s|ssl_certificate .*|ssl_certificate     /etc/ssl/cloud9/cloud9.crt;|" /etc/nginx/sites-available/cloud9
        sed -i "s|ssl_certificate_key .*|ssl_certificate_key /etc/ssl/cloud9/cloud9.key;|" /etc/nginx/sites-available/cloud9
        nginx -t && systemctl reload nginx
        warn "Self-signed certificate created. Browser will show security warning."
    fi
else
    # Self-signed
    info "Creating self-signed SSL certificate..."
    mkdir -p /etc/ssl/cloud9
    openssl req -x509 -nodes -days 3650 -newkey rsa:4096 \
        -keyout /etc/ssl/cloud9/cloud9.key \
        -out /etc/ssl/cloud9/cloud9.crt \
        -subj "/C=VN/ST=Hanoi/L=Hanoi/O=Cloud9/CN=$NGINX_DOMAIN" 2>/dev/null
    ok "Self-signed certificate created at /etc/ssl/cloud9/"
    warn "Trình duyệt sẽ cảnh báo không an toàn với self-signed cert."
    warn "Để dùng Let's Encrypt, chạy: sudo certbot --nginx -d domain.com"
fi

# ───────────────────────────────────────────────────────────────────────
header "Phase 8/8: Cấu hình Firewall và khởi động"
# ───────────────────────────────────────────────────────────────────────

# UFW
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 'Nginx Full'
ufw --force enable
ok "UFW configured: Nginx Full (80, 443) allowed."

# Start services
systemctl start "$C9_SERVICE"
systemctl restart nginx

# Kiểm tra
sleep 3
if systemctl is-active --quiet "$C9_SERVICE"; then
    ok "Cloud9 service is running."
else
    warn "Cloud9 service failed to start. Check: sudo journalctl -u $C9_SERVICE -n 50"
fi

if systemctl is-active --quiet nginx; then
    ok "Nginx is running."
else
    warn "Nginx failed to start. Check: sudo nginx -t"
fi

# ─── Summary ───────────────────────────────────────────────────────────
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

clear
echo -e "${green}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║              CÀI ĐẶT HOÀN TẤT! 🎉                          ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${reset}"
echo ""
echo -e "  ${cyan}Thời gian cài đặt:${reset}    $(printf '%dm %ds' $((DURATION/60)) $((DURATION%60)))"
echo ""
echo -e "  ${cyan}Truy cập Cloud9 IDE:${reset}"
if [[ -n "$DOMAIN" ]]; then
    echo -e "    ${green}https://$DOMAIN${reset}"
else
    echo -e "    ${green}https://$NGINX_DOMAIN${reset}"
    echo -e "    (hoặc ${green}https://<IP-của-server>${reset} nếu có DNS)"
fi
echo ""
echo -e "  ${cyan}Thông tin đăng nhập:${reset}"
echo -e "    Username:  ${green}$AUTH_USER${reset}"
echo -e "    Password:  ${green}(đã nhập)${reset}"
echo ""
echo -e "  ${cyan}Workspace:${reset}           ${green}$C9_WORKSPACE${reset}"
echo ""
echo -e "  ${cyan}Quản lý service:${reset}"
echo -e "    ${yellow}sudo systemctl status $C9_SERVICE${reset}"
echo -e "    ${yellow}sudo journalctl -u $C9_SERVICE -f${reset}"
echo ""
echo -e "  ${cyan}Cấu hình Nginx:${reset}"
echo -e "    ${yellow}/etc/nginx/sites-available/cloud9${reset}"
echo ""
echo -e "  ${cyan}Nếu cần chạy Let's Encrypt sau:${reset}"
echo -e "    ${yellow}sudo certbot --nginx -d domain.com${reset}"
echo ""
echo -e "  ${cyan}Nginx logs:${reset}"
echo -e "    ${yellow}sudo tail -f /var/log/nginx/access.log${reset}"
echo -e "    ${yellow}sudo tail -f /var/log/nginx/error.log${reset}"
echo ""
echo -e "  ${cyan}Cloud9 logs:${reset}"
echo -e "    ${yellow}sudo journalctl -u $C9_SERVICE -n 50 --no-pager${reset}"
echo ""
echo -e "${yellow}────────────────────────────────────────────────────────────${reset}"
echo -e "${yellow}  Lưu ý quan trọng:${reset}"
if [[ -z "$DOMAIN" ]]; then
    echo -e "${yellow}  • Self-signed SSL: thêm exception trong trình duyệt${reset}"
fi
echo -e "${yellow}  • Đổi password: sửa file /etc/systemd/system/$C9_SERVICE.service${reset}"
echo -e "${yellow}    rồi chạy: sudo systemctl daemon-reload && sudo systemctl restart $C9_SERVICE${reset}"
echo -e "${yellow}  • Xem hướng dẫn chi tiết trong file Readme.md${reset}"
echo -e "${yellow}────────────────────────────────────────────────────────────${reset}"
echo ""
