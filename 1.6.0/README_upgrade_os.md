# Hướng dẫn nâng cấp Ubuntu OS + Guacamole lên 1.6.0

## Tổng quan dự án

Dự án này cung cấp **2 script riêng biệt** phục vụ 2 mục đích khác nhau:

| Script | Mục đích | Phạm vi |
|--------|----------|---------|
| `upgrade-guac.sh` | Nâng phiên bản **Guacamole** (1.5.5 → 1.6.0) | Chỉ update các component Guacamole: .war, guacd, JDBC, extensions, schema DB. **Không đụng đến OS.** |
| `Upgrade_OS_from_20.04_to_22.04LTS.sh` | Nâng **OS Ubuntu** (20.04 → 22.04 → 24.04) **+** Guacamole 1.6.0 | Backup toàn bộ, nâng OS, cài dependencies, compile guacd cho OS mới, restore. |

### upgrac-guac.sh — Chỉ nâng Guacamole, không động đến OS

Script này dùng trong tình huống: OS vẫn giữ nguyên (ví dụ Ubuntu 22.04 đã ổn định), bạn chỉ muốn nâng Guacamole từ 1.5.5 lên 1.6.0.

```
Cũ: Guacamole 1.5.5 trên Ubuntu 22.04
                    ↓
Mới: Guacamole 1.6.0 trên Ubuntu 22.04 (OS giữ nguyên)
```

Nó làm những việc sau:
- Dừng Tomcat + guacd
- Download Guacamole .war 1.6.0 → thay thế file cũ
- Download + compile guacamole-server 1.6.0 từ source
- Update JDBC auth, MySQL Connector, extensions (TOTP, Duo, LDAP...)
- Chạy schema upgrade scripts cho database
- Khởi động lại services

### Upgrade_OS_from_20.04_to_22.04LTS.sh — Nâng OS + Guacamole

Script này dùng khi bạn cần nâng **cả OS lẫn Guacamole**, ví dụ từ Ubuntu 20.04 LTS lên 22.04 LTS rồi lên 24.04 LTS.

## Vấn đề sống còn: Backup TRƯỚC khi nâng OS

### Có mất dữ liệu không?

**CÓ THỂ.** Nâng cấp OS (do-release-upgrade) là một thao tác rủi ro cao:

1. **SSH có thể bị ngắt** — nếu mất kết nối giữa chừng, quá trình upgrade dang dở có thể làm hỏng hệ thống
2. **Config file có thể bị ghi đè** — Tomcat, Nginx, Guacamole properties có thể bị reset về mặc định
3. **Database có thể bị lỗi** — MySQL/MariaDB có thể không tương thích với phiên bản mới
4. **Java/Tomcat version thay đổi** — Ubuntu 22.04 dùng Tomcat9 mặc định khác với 20.04
5. **Thiếu dependencies** — guacamole-server cần libcairo2-dev, freerdp2-dev... các phiên bản khác nhau trên mỗi OS
6. **Không có rollback** — nếu upgrade OS thất bại, không có backup đồng nghĩa với mất hết

### Quy tắc VÀNG

```
Luôn chạy Upgrade_OS_from_20.04_to_22.04LTS.sh TRƯỚC KHI nâng OS
                                ↓
Không bao giờ nâng OS trước rồi mới chạy script (vì khi đó đã mất dữ liệu)
```

### Tại sao backup phải làm trước?

```
Trạng thái hiện tại (20.04 + Guac 1.5.5)
         │
         ├── [SAFE] Chạy Upgrade_OS_from_20.04_to_22.04LTS.sh
         │       │
         │       ├── Bước 1: Backup → /opt/backup/ (toàn bộ config + DB)
         │       ├── Bước 2: Nâng OS 20.04 → 22.04
         │       ├── Bước 3: Reboot
         │       ├── Bước 4: --after-os-upgrade → Guac 1.6.0
         │       └── Bước 5: Restore DB nếu cần
         │
         └── [RISK] Nâng OS trước (do-release-upgrade)
                 │
                 ├── Mất config Guacamole / Tomcat / Nginx
                 ├── Mất quyền truy cập database
                 ├── Không có điểm rollback
                 └── Guacamole sẽ không chạy và bạn không có backup để restore
```

## Kiến trúc quy trình đầy đủ

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        HỆ THỐNG HIỆN TẠI                               │
│              Ubuntu 20.04 LTS + Guacamole 1.5.5                         │
│              + Tomcat9 + MySQL/MariaDB + Nginx + TLS                    │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Bước 1: CHẠY Upgrade_OS_from_20.04_to_22.04LTS.sh                     │
│                                                                         │
│  ┌─────────────────────────────────────────────┐                       │
│  │ 1a. Backup → /opt/backup/                   │                       │
│  │   ├── /etc/guacamole/ (properties, ext, lib)│                       │
│  │   ├── /var/lib/tomcat*/webapps/             │                       │
│  │   ├── /etc/nginx/                           │                       │
│  │   ├── /etc/letsencrypt/ + /etc/ssl/         │                       │
│  │   ├── MySQL dump: guacamole_db.sql          │                       │
│  │   ├── extensions/*.jar                      │                       │
│  │   ├── packages.list (dpkg list)             │                       │
│  │   └── guac-setup/ (scripts gốc)             │                       │
│  └─────────────────────────────────────────────┘                       │
│                                                                         │
│  ┌─────────────────────────────────────────────┐                       │
│  │ 1b. Update packages hiện tại +               │                       │
│  │     do-release-upgrade → Ubuntu 22.04 LTS    │                       │
│  └─────────────────────────────────────────────┘                       │
│                                                                         │
│  ┌─────────────────────────────────────────────┐                       │
│  │ 1c. Reboot                                   │                       │
│  └─────────────────────────────────────────────┘                       │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Bước 2: Sau reboot → Kiểm tra OS 22.04                                │
│                                                                         │
│  lsb_release -a → Ubuntu 22.04.xx LTS                                  │
│                                                                         │
│  Lưu ý: guacd + Tomcat có thể chưa chạy do thiếu dependencies          │
│         (Điều này bình thường, bước sau sẽ xử lý)                       │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Bước 3: CHẠY Upgrade_OS_from_20.04_to_22.04LTS.sh --after-os-upgrade  │
│                                                                         │
│  ┌─────────────────────────────────────────────┐                       │
│  │ 3a. apt update/upgrade (OS packages mới)     │                       │
│  │ 3b. Cài dependencies cho Guac 1.6.0          │                       │
│  │     (libcairo2-dev, freerdp2-dev, ...)        │                       │
│  │ 3c. Download Guacamole 1.6.0.war             │                       │
│  │ 3d. Download + compile guacamole-server 1.6.0│                       │
│  │ 3e. Update JDBC auth + MySQL Connector       │                       │
│  │ 3f. Nâng cấp DB schema                       │                       │
│  │ 3g. Restore DB từ backup (nếu cần)           │                       │
│  │ 3h. Start guacd + Tomcat                     │                       │
│  └─────────────────────────────────────────────┘                       │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                    KẾT QUẢ: Ubuntu 22.04 + Guacamole 1.6.0              │
│                                                                         │
│  Backup tại /opt/backup/ vẫn sẵn sàng để rollback nếu cần              │
└────────────────────────────────┬────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Bước 4 (Tùy chọn): Nâng tiếp lên Ubuntu 24.04 LTS                     │
│                                                                         │
│  ┌─────────────────────────────────────────────┐                       │
│  │ 4a. sudo apt update && sudo apt upgrade -y   │                       │
│  │ 4b. sudo do-release-upgrade                  │                       │
│  │ 4c. Reboot                                   │                       │
│  │ 4d. Chạy lại --after-os-upgrade              │                       │
│  │     (để rebuild guacd cho OS mới)             │                       │
│  └─────────────────────────────────────────────┘                       │
└─────────────────────────────────────────────────────────────────────────┘
```

## Lộ trình nâng cấp khuyến nghị

Tuân thủ đúng thứ tự sau để đảm bảo an toàn dữ liệu:

```
Lộ trình đầy đủ:       20.04 LTS ──→ 22.04 LTS ──→ 24.04 LTS
                         │              │              │
                    Guac 1.5.5      Guac 1.6.0     Guac 1.6.0
                         │              │              │
Lần chạy:               1              2              3
                         │              │              │
Script:              upgrade-os.sh  --after-os     do-release + --after-os
                     (backup+upgrade)  (rebuild)    (nếu cần rebuild)
```

## Các bước thực hiện chi tiết

### Bước 0: Kiểm tra hệ thống hiện tại

```bash
# Kiểm tra phiên bản Ubuntu
lsb_release -a

# Kiểm tra phiên bản Guacamole hiện tại
cat /var/lib/tomcat9/webapps/guacamole/guacamole-common-js/modules/Version.js | grep API_VERSION

# Kiểm tra dung lượng ổ cứng (cần ≥ 10GB trống)
df -h

# Kiểm tra các service đang chạy
systemctl status guacd tomcat9 --no-pager
```

### Bước 1: Tải script (chạy TRƯỚC khi nâng OS)

```bash
# Tải script từ GitHub
sudo wget -O /root/Upgrade_OS_from_20.04_to_22.04LTS.sh \
  https://raw.githubusercontent.com/PhDLeToanThang/cloudedge/main/1.6.0/Upgrade_OS_from_20.04_to_22.04LTS.sh

# Cấp quyền thực thi
sudo chmod +x /root/Upgrade_OS_from_20.04_to_22.04LTS.sh
```

### Bước 2: Chạy Backup + Upgrade OS (chạy TRƯỚC khi nâng OS)

```bash
# QUAN TRỌNG: Chạy lệnh này KHI HỆ THỐNG CŨ VẪN ĐANG HOẠT ĐỘNG
# Script sẽ tự động backup TOÀN BỘ trước khi nâng OS
sudo bash /root/Upgrade_OS_from_20.04_to_22.04LTS.sh
```

Script sẽ:
1. Backup toàn bộ Guacamole config + DB + extensions + Nginx + SSL → `/opt/backup/`
2. Update packages hiện tại (apt update/upgrade)
3. Hiện thông báo xác nhận: gõ `yes` để bắt đầu nâng OS
4. Chạy `do-release-upgrade` (có thể mất 15-30 phút)
5. Hỏi reboot: gõ `yes` để khởi động lại

### Bước 3: Sau reboot — Kiểm tra OS mới

```bash
# Kiểm tra phiên bản Ubuntu sau nâng cấp
lsb_release -a

# Kiểm tra các service (có thể chưa chạy → bình thường)
systemctl status guacd tomcat9 --no-pager
```

> Sau khi nâng OS lên 22.04, Tomcat và guacd có thể chưa chạy do thiếu thư viện cho OS mới. Điều này **hoàn toàn bình thường**. Bước sau sẽ xử lý.

### Bước 4: Nâng cấp Guacamole lên 1.6.0

```bash
# Chạy sau khi reboot vào OS mới
sudo bash /root/Upgrade_OS_from_20.04_to_22.04LTS.sh --after-os-upgrade
```

Script sẽ tự động:
1. Cập nhật OS packages
2. Cài dependencies cho Ubuntu 22.04 (libcairo2-dev, freerdp2-dev...)
3. Download Guacamole Client (.war) 1.6.0
4. Download và cài JDBC auth 1.6.0
5. Download MySQL Connector/J
6. Download source + compile Guacamole Server 1.6.0
7. Nâng cấp database schema
8. Hỏi restore database từ file backup (nếu cần)
9. Khởi động lại services

### Bước 5: Kiểm tra kết quả

```bash
# Kiểm tra Guacamole đã được nâng cấp
cat /var/lib/tomcat9/webapps/guacamole/guacamole-common-js/modules/Version.js | grep API_VERSION

# Kiểm tra services
systemctl status guacd --no-pager
systemctl status tomcat9 --no-pager

# Kiểm tra log nâng cấp
tail -50 /opt/backup/guacamole-backup-*/upgrade-os-guac.log

# Kiểm tra Web UI
curl -I http://localhost:8080/guacamole
```

### Bước 6: Truy cập Guacamole

Mở trình duyệt và truy cập:

```
http://<địa-chỉ-ip>:8080/guacamole
```

## Nâng cấp tiếp lên Ubuntu 24.04 LTS (tùy chọn)

Sau khi đã hoàn tất 22.04 + Guac 1.6.0, bạn có thể nâng tiếp:

```bash
# 1. Cập nhật packages hiện tại
sudo apt update && sudo apt upgrade -y

# 2. Kiểm tra bản nâng cấp có sẵn
sudo do-release-upgrade -c

# 3. Nâng cấp lên 24.04 LTS
sudo do-release-upgrade
```

Sau reboot vào 24.04, rebuild guacd cho OS mới:

```bash
sudo bash /root/Upgrade_OS_from_20.04_to_22.04LTS.sh --after-os-upgrade
```

## Trường hợp đã lỡ nâng OS trước khi backup

Nếu bạn đã nâng OS từ 20.04 lên 22.04 (hoặc 24.04) mà **chưa backup Guacamole**:

### Rủi ro
- Có thể mất hoàn toàn dữ liệu kết nối, user, phân quyền trong Guacamole
- Cấu hình Tomcat/Nginx có thể bị ghi đè
- extensions (.jar) có thể không tương thích

### Cách xử lý

```bash
# 1. Kiểm tra xem còn dữ liệu không
ls -la /etc/guacamole/
ls -la /var/lib/tomcat*/webapps/guacamole/
systemctl status mariadb mysql

# 2. Nếu database còn, export ngay
mysqldump --databases guacamole_db > /root/guacamole_db_emergency.sql

# 3. Nếu /etc/guacamole còn, copy ngay
cp -rp /etc/guacamole /root/guacamole-etc-emergency

# 4. Chạy --after-os-upgrade để rebuild Guac 1.6.0
sudo bash /root/Upgrade_OS_from_20.04_to_22.04LTS.sh --after-os-upgrade
```

## Restore từ backup (khi cần rollback)

Nếu có sự cố, restore toàn bộ cấu hình từ backup đã tạo trước đó:

```bash
# Liệt kê các bản backup
ls -la /opt/backup/

# Restore tự động
sudo bash Upgrade_OS_from_20.04_to_22.04LTS.sh --restore-backup /opt/backup/guacamole-backup-20260529-120000
```

Restore thủ công từng phần:

```bash
# Restore cấu hình Guacamole
sudo cp -rp /opt/backup/guacamole-backup-*/guacamole-etc/* /etc/guacamole/

# Restore database
sudo mysql -u root -D guacamole_db < /opt/backup/guacamole-backup-*/guacamole_db.sql

# Restart services
sudo systemctl restart guacd tomcat9
```

## Cấu trúc thư mục backup

```
/opt/backup/guacamole-backup-YYYYMMDD-HHMMSS/
├── guacamole-etc/              # /etc/guacamole/ (guacamole.properties, extensions, lib)
├── tomcat-webapps/             # Tomcat web applications
├── nginx/                      # Nginx configuration
├── letsencrypt/                # Let's Encrypt certificates
├── ssl/                        # SSL certificates
├── extensions/                 # Guacamole extension JARs
├── lib/                        # Guacamole lib JARs
├── guac-setup/                 # Original install scripts
├── guacamole_db.sql            # MySQL database dump (dữ liệu connections, users, permissions)
├── packages.list               # List of installed packages
└── upgrade-os-guac.log         # Installation log
```

## So sánh 2 script upgrade

| Tính năng | `upgrade-guac.sh` | `Upgrade_OS_from_20.04_to_22.04LTS.sh` |
|-----------|-------------------|----------------------------------------|
| **Mục đích** | Chỉ nâng Guacamle version | Nâng OS + Guacamole |
| **Có backup không?** | ❌ Không | ✅ Có (backup toàn bộ trước) |
| **Nâng OS?** | ❌ Không | ✅ Có (do-release-upgrade) |
| **Cài OS dependencies?** | ❌ Không | ✅ Có (libcairo2, freerdp2...) |
| **Upgrade Guacamole .war?** | ✅ Có | ✅ Có |
| **Compile guacamole-server?** | ✅ Có | ✅ Có |
| **Upgrade extensions?** | ✅ Có | ✅ Có |
| **Upgrade DB schema?** | ✅ Có | ✅ Có |
| **Restore DB?** | ❌ Không | ✅ Có (hỏi người dùng) |
| **Khi nào chạy?** | Trên OS đã ổn định | Trước/sau khi nâng OS |

## Khắc phục sự cố

### SSH bị ngắt trong quá trình nâng OS

Sử dụng IPMI/iLO/iDRAC hoặc console vật lý. Nếu không có, hãy dùng `screen`:

```bash
sudo apt install -y screen
screen -S os-upgrade
sudo bash Upgrade_OS_from_20.04_to_22.04LTS.sh
# Nếu SSH bị ngắt, reconnect và chạy: screen -r os-upgrade
```

### Guacamole không chạy sau nâng OS

```bash
# Kiểm tra Java
java -version

# Kiểm tra Tomcat
systemctl status tomcat9
journalctl -u tomcat9 -n 50 --no-pager

# Kiểm tra guacd
systemctl status guacd
journalctl -u guacd -n 50 --no-pager

# Kiểm tra log Guacamole
tail -100 /var/log/syslog | grep guacamole
```

### Lỗi database connection

```bash
# Kiểm tra MySQL/MariaDB
systemctl status mariadb

# Kiểm tra thông số kết nối
cat /etc/guacamole/guacamole.properties | grep mysql

# Test kết nối
mysql -u root -p -e "SHOW DATABASES;"
```

### Thiếu dependencies khi compile guacamole-server

```bash
# Cài đặt tất cả dependencies cho Ubuntu 22.04
sudo apt install -y build-essential libcairo2-dev libjpeg-turbo8-dev \
  libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev \
  libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev \
  libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev \
  libwebp-dev libsdl2-dev
```
