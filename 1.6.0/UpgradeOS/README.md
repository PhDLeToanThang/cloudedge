# Hướng dẫn nâng cấp Ubuntu OS — 20.04 LTS → 22.04 LTS → 24.04 LTS

## Mục lục

1. [Tổng quan & Lộ trình nâng cấp](#1-tổng-quan--lộ-trình-nâng-cấp)
2. [Quy tắc VÀNG — Đọc trước khi làm](#2-quy-tắc-vàng--đọc-trước-khi-làm)
3. [Yêu cầu kỹ thuật & Chuẩn bị](#3-yêu-cầu-kỹ-thuật--chuẩn-bị)
4. [Quy trình nâng cấp 20.04 → 22.04](#4-quy-trình-nâng-cấp-2004--2204)
5. [Quy trình nâng cấp 22.04 → 24.04](#5-quy-trình-nâng-cấp-2204--2404)
6. [Quy định kỹ thuật & Kiểm tra sau nâng cấp](#6-quy-định-kỹ-thuật--kiểm-tra-sau-nâng-cấp)
7. [Xử lý sự cố & Rollback](#7-xử-lý-sự-cố--rollback)
8. [Cấu trúc thư mục dự án](#8-cấu-trúc-thư-mục-dự-án)

---

## 1. Tổng quan & Lộ trình nâng cấp

### Lộ trình khuyến nghị

```
Ubuntu 20.04 LTS ────→ Ubuntu 22.04 LTS ────→ Ubuntu 24.04 LTS
   (Focal Fossa)           (Jammy Jellyfish)       (Noble Numbat)
        │                        │                       │
   Guacamole 1.5.5          Guacamole 1.6.0         Guacamole 1.6.0
        │                        │                       │
   Phase 1                  Phase 2                 Phase 3
   (backup + upgrade)       (rebuild guacd)         (do-release-upgrade
                                                     + rebuild guacd)
```

### Các bước tổng thể

| Phase | Thao tác | Thời gian ước tính | Script |
|-------|----------|-------------------|--------|
| 0 | Kiểm tra hệ thống hiện tại | 10 phút | Thủ công |
| 1 | Backup + nâng OS 20.04 → 22.04 | 30–60 phút | `20.04-to-22.04/Upgrade_OS_from_20.04_to_22.04LTS.sh` (Phase 1) |
| 2 | Rebuild Guacamole + dependencies cho 22.04 | 20–40 phút | `Upgrade_OS_from_20.04_to_22.04LTS.sh --after-os-upgrade` |
| 3 | Nâng tiếp 22.04 → 24.04 (tùy chọn) | 30–60 phút | `22.04-to-24.04/Upgrade_OS_from_22.04_to_24.04_LTS.sh` + `--after-os-upgrade` |

---

## 2. Quy tắc VÀNG — Đọc trước khi làm

### ⚠️ CẢNH BÁO NGUY HIỂM

> **Nâng cấp OS là thao tác RỦI RO CAO. Không backup = MẤT HẾT DỮ LIỆU.**

```
❌ Không bao giờ làm:   do-release-upgrade TRƯỚC → chạy script SAU
✅ Phải làm đúng:       Chạy script TRƯỚC → backup tự động → do-release-upgrade SAU
```

### Danh sách rủi ro

1. **Mất kết nối SSH** — Nâng cấp OS có thể ngắt SSH giữa chừng, dẫn đến hệ thống hỏng (unbootable).
2. **Config bị ghi đè** — Tomcat, Nginx, Guacamole properties có thể bị reset về mặc định trên OS mới.
3. **Database không tương thích** — MySQL/MariaDB phiên bản mới có thể không đọc được dữ liệu cũ.
4. **Java/Tomcat thay đổi phiên bản** — Ubuntu 22.04 dùng Tomcat9 mặc định; 24.04 thay đổi hoàn toàn.
5. **Thiếu dependencies** — guacamole-server cần compile với thư viện của OS mới.
6. **Không có rollback OS** — Ubuntu không hỗ trợ downgrade. Nếu nâng thất bại, bạn phải cài lại OS từ đầu.

### Quy tắc an toàn bắt buộc

| # | Quy tắc | Mô tả |
|---|---------|-------|
| 1 | **Luôn backup trước** | Backup toàn bộ config, DB, extensions, SSL trước mọi thao tác nâng cấp |
| 2 | **Kiểm tra dung lượng** | Cần ≥ 10 GB trống trên ổ `/` |
| 3 | **Dùng screen/tmux** | Tránh mất phiên SSH giữa chừng |
| 4 | **Kiểm tra OS hiện tại** | Xác nhận đúng phiên bản trước khi chạy script |
| 5 | **Không tắt máy giữa chừng** | Ngắt nguồn khi đang nâng OS có thể làm hỏng hệ thống |
| 6 | **Kiểm tra service sau reboot** | Xác nhận guacd, tomcat, mysql hoạt động bình thường |

---

## 3. Yêu cầu kỹ thuật & Chuẩn bị

### Yêu cầu phần cứng tối thiểu

| Thông số | Yêu cầu | Ghi chú |
|----------|---------|---------|
| CPU | 2 cores (x86_64/amd64) | ARM chưa được hỗ trợ chính thức |
| RAM | ≥ 4 GB | Khuyến nghị 8 GB cho production |
| Disk `/` | ≥ 10 GB trống | Cần thêm dung lượng cho quá trình nâng cấp (download packages, compile) |
| Disk `/boot` | ≥ 500 MB trống | Đảm bảo đủ space cho kernel mới |
| Network | Kết nối Internet ổn định | Tải packages từ apt repositories |

### Yêu cầu phần mềm

| Phần mềm | Phiên bản tối thiểu | Mục đích |
|----------|---------------------|----------|
| Ubuntu | 20.04 LTS (Focal Fossa) | Hệ điều hành nguồn |
| Guacamole | 1.5.5 | Application server |
| Tomcat | 9.0 | Servlet container |
| MySQL/MariaDB | 8.0+ / 10.5+ | Database backend |
| Nginx | 1.18+ | Reverse proxy (optional) |

### Kiểm tra hệ thống trước khi nâng cấp

```bash
# 1. Kiểm tra OS
lsb_release -a

# 2. Kiểm tra disk space
df -h /

# 3. Kiểm tra kernel
uname -r

# 4. Kiểm tra services
systemctl status guacd tomcat9 mysql nginx --no-pager

# 5. Kiểm tra phiên bản Guacamole
cat /var/lib/tomcat9/webapps/guacamole/guacamole-common-js/modules/Version.js | grep API_VERSION

# 6. Kiểm tra port đang mở
ss -tlnp
```

---

## 4. Quy trình nâng cấp 20.04 → 22.04

### Phase 1: Backup + Nâng OS

> **Chạy lệnh này khi HỆ THỐNG VẪN ĐANG ỔN ĐỊNH trên Ubuntu 20.04**

```bash
# Cài screen để tránh mất SSH
sudo apt install -y screen
screen -S os-upgrade

# Chạy script backup + upgrade OS
cd /root
sudo bash /path/to/UpgradeOS/20.04-to-22.04/Upgrade_OS_from_20.04_to_22.04LTS.sh
```

Script sẽ tự động:
1. **Backup** toàn bộ Guacamole → `/opt/backup/guacamole-backup-YYYYMMDD-HHMMSS/`
2. Cập nhật packages hiện tại
3. Dừng Tomcat + guacd
4. Chạy `do-release-upgrade` lên Ubuntu 22.04
5. Hỏi xác nhận **Reboot**

> **⚠️ Extension:** `--after-os-upgrade` chỉ cập nhật extension **đã có** trong hệ thống, không tự động cài mới. Tránh lỗi `Property required` như Duo/LDAP.

Sau reboot, kiểm tra:
```bash
lsb_release -a
# => Ubuntu 22.04.xx LTS
```

### Phase 2: Rebuild Guacamole cho OS mới

> **Chạy SAU KHI reboot vào Ubuntu 22.04**

```bash
cd /root
sudo bash /path/to/UpgradeOS/20.04-to-22.04/Upgrade_OS_from_20.04_to_22.04LTS.sh --after-os-upgrade
```

Script sẽ:
1. Cập nhật OS packages cho 22.04
2. Cài dependencies cho Guacamole 1.6.0
3. Download & compile guacamole-server 1.6.0 từ source
4. Nâng cấp JDBC auth, MySQL Connector, extensions
5. Nâng cấp database schema
6. Hỏi restore database từ file backup (nếu cần)
7. Khởi động lại services

### Kiểm tra sau Phase 2

```bash
# Kiểm tra Guacamole version
cat /var/lib/tomcat9/webapps/guacamole/guacamole-common-js/modules/Version.js | grep API_VERSION
# => 1.6.0

# Kiểm tra services
systemctl status guacd --no-pager
systemctl status tomcat9 --no-pager

# Kiểm tra Web UI
curl -I http://localhost:8080/guacamole

# Xem log
tail -50 /opt/backup/guacamole-backup-*/upgrade-os-guac.log
```

---

## 5. Quy trình nâng cấp 22.04 → 24.04

> **Lưu ý:** Chỉ thực hiện sau khi đã hoàn tất Phase 2 (22.04 + Guacamole 1.6.0 ổn định).

Quy trình này đã được tự động hóa bởi script riêng trong thư mục [`22.04-to-24.04/`](22.04-to-24.04/README.md). Chi tiết tham khảo tại đó.

### Tóm tắt nhanh

```bash
# Phase 1: Backup + Nâng OS (chạy trên 22.04)
cd /path/to/UpgradeOS/22.04-to-24.04/
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh

# Sau reboot vào 24.04, Phase 2: Rebuild Guacamole
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --after-os-upgrade
```

---

## 6. Quy định kỹ thuật & Kiểm tra sau nâng cấp

### Danh sách kiểm tra bắt buộc (Post-Upgrade Checklist)

| # | Hạng mục | Kiểm tra | Command/Ghi chú |
|---|----------|----------|-----------------|
| 1 | OS version | `lsb_release -a` | Phải khớp với mục tiêu (22.04 hoặc 24.04) |
| 2 | Kernel version | `uname -r` | ≥ 5.15 (22.04) hoặc ≥ 6.8 (24.04) |
| 3 | Disk space | `df -h` | Không có partition nào đầy > 90% |
| 4 | Network | `ping -c 3 8.8.8.8` | Kết nối Internet OK |
| 5 | DNS | `dig google.com` | DNS resolution hoạt động |
| 6 | MySQL/MariaDB | `systemctl status mariadb` | Database service running |
| 7 | Guacamole DB | `mysql -e "USE guacamole_db; SHOW TABLES;"` | Tables tồn tại, không lỗi |
| 8 | Tomcat | `systemctl status tomcat9` | Service active, port 8080 listening |
| 9 | Guacd | `systemctl status guacd` | Service active, port 4822 listening |
| 10 | Nginx (nếu có) | `systemctl status nginx` | Service active, ports 80/443 listening |
| 11 | Guacamole WAR | `ls -la /etc/guacamole/guacamole.war` | File tồn tại, kích thước > 10MB |
| 12 | Guacamole UI | `curl -I http://localhost:8080/guacamole` | HTTP 200 hoặc 302 |
| 13 | Logs | `tail -50 /opt/backup/*/upgrade-os-guac.log` | Không có ERROR |
| 14 | SSH | Kiểm tra remote login | SSH service hoạt động sau reboot |
| 15 | Firewall | `ufw status` (nếu dùng) | Rules còn nguyên |

### Các thông số kỹ thuật cần ghi nhận

```bash
# Lưu thông tin hệ thống sau nâng cấp
{
  echo "=== SYSTEM INFO ==="
  echo "Date: $(date)"
  echo "Hostname: $(hostname)"
  echo "OS: $(lsb_release -ds)"
  echo "Kernel: $(uname -r)"
  echo "CPU: $(nproc) cores"
  echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
  echo "Disk: $(df -h / | tail -1 | awk '{print $4}') free"
  echo "Guacamole: $(cat /var/lib/tomcat*/webapps/guacamole/guacamole-common-js/modules/Version.js 2>/dev/null | grep -oP 'API_VERSION = "\K[^"]+' || echo 'unknown')"
  echo "Java: $(java -version 2>&1 | head -1)"
  echo "MySQL: $(mysql --version 2>/dev/null || echo 'not found')"
} | tee /root/system-info-after-upgrade.txt
```

---

## 7. Xử lý sự cố & Rollback

### Không thể SSH vào server sau nâng OS

**Nguyên nhân:** SSH service chưa start, firewall thay đổi, hoặc kernel mới không boot được.

**Xử lý:**
1. Dùng IPMI/iLO/iDRAC/truy cập console vật lý
2. Kiểm tra SSH: `systemctl status ssh`
3. Kiểm tra firewall: `ufw status` → `ufw allow ssh`
4. Nếu kernel lỗi: chọn kernel cũ từ GRUB menu

### Guacamole không chạy sau nâng OS

```bash
# 1. Kiểm tra Java
java -version

# 2. Kiểm tra Tomcat logs
journalctl -u tomcat9 -n 100 --no-pager

# 3. Kiểm tra guacd logs
journalctl -u guacd -n 100 --no-pager

# 4. Kiểm tra Guacamole log
tail -100 /var/log/syslog | grep -i guacamole

# 5. Kiểm tra database connection
mysql -u root -e "USE guacamole_db; SHOW TABLES;"
cat /etc/guacamole/guacamole.properties | grep -E "mysql-host|mysql-port|mysql-database|mysql-user"
```

### Thiếu dependencies khi compile guacamole-server

```bash
# Cài đủ dependencies cho Ubuntu 22.04
sudo apt install -y build-essential libcairo2-dev libjpeg-turbo8-dev \
  libpng-dev libtool-bin libossp-uuid-dev libavcodec-dev libavutil-dev \
  libswscale-dev freerdp2-dev libpango1.0-dev libssh2-1-dev libtelnet-dev \
  libvncserver-dev libwebsockets-dev libpulse-dev libssl-dev libvorbis-dev \
  libwebp-dev libsdl2-dev
```

### Rollback từ backup

**Rollback toàn bộ:**
```bash
# Liệt kê các bản backup
ls -la /opt/backup/

# Restore tự động bằng script
sudo bash /path/to/20.04-to-22.04/Upgrade_OS_from_20.04_to_22.04LTS.sh \
  --restore-backup /opt/backup/guacamole-backup-20260529-120000
```

**Restore thủ công từng phần:**
```bash
# Restore Guacamole config
sudo cp -rp /opt/backup/guacamole-backup-*/guacamole-etc/* /etc/guacamole/

# Restore Tomcat webapps
sudo cp -rp /opt/backup/guacamole-backup-*/tomcat-webapps/* /var/lib/tomcat9/webapps/

# Restore Nginx
sudo cp -rp /opt/backup/guacamole-backup-*/nginx/* /etc/nginx/
sudo nginx -t && sudo systemctl reload nginx

# Restore database
sudo mysql -u root -D guacamole_db < /opt/backup/guacamole-backup-*/guacamole_db.sql

# Restart services
sudo systemctl restart guacd tomcat9 mysql
```

**Lưu ý:** Không thể rollback OS sau khi nâng cấp. Nếu OS mới không ổn định, bạn phải:
- Cài lại Ubuntu 20.04 từ ISO
- Cài Guacamole từ đầu
- Restore database + config từ backup

---

## 8. Cấu trúc thư mục dự án

```
UpgradeOS/
├── README.md                                    # Hướng dẫn tổng thể (file này)
├── 20.04-to-22.04/                              # Script & tài liệu cho 20.04 → 22.04
│   ├── README.md                                # (tham khảo script --help)
│   └── Upgrade_OS_from_20.04_to_22.04LTS.sh     # Script backup + upgrade OS + Guacamole
├── 22.04-to-24.04/                              # Script & tài liệu cho 22.04 → 24.04
│   ├── README.md                                # Hướng dẫn chi tiết nâng OS
│   └── Upgrade_OS_from_22.04_to_24.04_LTS.sh    # Script tự động backup + upgrade + rebuild
└── common/                                      # Công cụ dùng chung
    └── (scripts, templates, utilities dùng chung)
```

### Cấu trúc backup

**Khi chạy `20.04-to-22.04/Upgrade_OS_from_20.04_to_22.04LTS.sh` → backup tại:**

```
/opt/backup/guacamole-backup-YYYYMMDD-HHMMSS/
├── guacamole-etc/              # /etc/guacamole/ (properties, extensions, lib)
├── tomcat-webapps/             # Tomcat web applications
├── nginx/                      # Nginx configuration
├── letsencrypt/                # Let's Encrypt certificates
├── ssl/                        # SSL certificates
├── extensions/                 # Guacamole extension JARs
├── lib/                        # Guacamole lib JARs
├── guac-setup/                 # Original install scripts
├── guacamole_db.sql            # MySQL database dump
├── packages.list               # List of installed packages
└── upgrade-os-guac.log         # Installation log
```

**Khi chạy `22.04-to-24.04/Upgrade_OS_from_22.04_to_24.04_LTS.sh` → backup tại:**

```
/opt/backup/guacamole-pre-24.04-YYYYMMDD-HHMMSS/
├── guacamole-etc/              # /etc/guacamole/
├── tomcat-webapps/             # Tomcat webapps
├── nginx/                      # Nginx config
├── letsencrypt/                # Let's Encrypt certs
├── ssl/                        # SSL certs
├── extensions/                 # JAR extensions
├── lib/                        # JAR libs
├── guacamole_db.sql            # MySQL dump
├── packages.list               # dpkg list
└── upgrade-os-2404.log         # Log file
```

---

## Phụ lục

### A. So sánh phiên bản Ubuntu

| Tính năng | Ubuntu 20.04 LTS | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS |
|-----------|-----------------|-----------------|-----------------|
| **Tên mã** | Focal Fossa | Jammy Jellyfish | Noble Numbat |
| **Kernel** | 5.4 | 5.15 | 6.8 |
| **OpenSSL** | 1.1.1 | 3.0.x | 3.0.x+ |
| **Python** | 3.8 | 3.10 | 3.12 |
| **GCC** | 9.x | 11.x | 13.x |
| **Support đến** | Tháng 4/2025 (EOL) | Tháng 4/2027 | Tháng 4/2029 |
| **systemd** | 245 | 249 | 255 |

### B. Các lệnh hữu ích

```bash
# Kiểm tra tiến trình nâng cấp (nếu SSH bị ngắt và dùng screen)
screen -r os-upgrade

# Kiểm tra upgrade history
cat /var/log/dist-upgrade/main.log | tail -100

# Kiểm tra kernel đã cài
dpkg --list | grep linux-image

# Xóa kernel cũ (sau khi đã boot kernel mới OK)
sudo apt autoremove --purge

# Kiểm tra services cần restart sau upgrade
sudo needrestart -a
```

### C. Liên hệ & Hỗ trợ

- **Script gốc:** [cloudedge repository](https://github.com/PhDLeToanThang/cloudedge)
- **Guacamole:** [https://guacamole.apache.org/](https://guacamole.apache.org/)
- **Ubuntu releases:** [https://releases.ubuntu.com/](https://releases.ubuntu.com/)

---

> **Tuyên bố miễn trừ trách nhiệm:** Nâng cấp hệ điều hành là thao tác rủi ro cao. Người thực hiện chịu hoàn toàn trách nhiệm về dữ liệu của mình. Luôn kiểm tra backup trước khi tiến hành.
