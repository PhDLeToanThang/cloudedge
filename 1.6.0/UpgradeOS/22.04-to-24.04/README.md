# Hướng dẫn nâng cấp Ubuntu 22.04 LTS → 24.04 LTS + Guacamole

## Mục lục

- [1. Tổng quan](#1-tổng-quan)
- [2. Danh sách rủi ro & Cảnh báo](#2-danh-sách-rủi-ro--cảnh-báo)
- [3. Yêu cầu hệ thống](#3-yêu-cầu-hệ-thống)
- [4. Quy trình chi tiết](#4-quy-trình-chi-tiết)
- [5. Hướng dẫn sử dụng Script](#5-hướng-dẫn-sử-dụng-script)
- [6. Kiểm tra sau nâng cấp](#6-kiểm-tra-sau-nâng-cấp)
- [7. Xử lý sự cố & Rollback](#7-xử-lý-sự-cố--rollback)
- [8. So sánh Ubuntu 22.04 vs 24.04](#8-so-sánh-ubuntu-2204-vs-2404)

---

## 1. Tổng quan

Tài liệu này hướng dẫn nâng cấp **Ubuntu 22.04 LTS (Jammy Jellyfish) lên 24.04 LTS (Noble Numbat)** trên hệ thống đang chạy **Guacamole 1.6.0**.

### Lộ trình

```
Ubuntu 22.04 LTS ──────→ Ubuntu 24.04 LTS
   (Jammy Jellyfish)         (Noble Numbat)
          │                        │
     Guacamole 1.6.0          Guacamole 1.6.0
          │                        │
     Phase 1                  Phase 2
     (backup + upgrade)       (rebuild guacd)
```

> **Lưu ý:** Quy trình này chỉ dành cho hệ thống đã hoàn thành nâng cấp từ 20.04 lên 22.04 và đang chạy Guacamole ổn định. Nếu bạn đang ở 20.04, hãy dùng script trong thư mục `../20.04-to-22.04/`.

---

## 2. Danh sách rủi ro & Cảnh báo

### ⚠️ Cảnh báo quan trọng

| # | Rủi ro | Tác động |
|---|--------|----------|
| 1 | **SSH bị ngắt giữa chừng** | Có thể làm hỏng quá trình nâng OS, dùng `screen` hoặc `tmux` |
| 2 | **Guacamole config bị ghi đè** | Cần backup /etc/guacamole/ trước |
| 3 | **MySQL/MariaDB không tương thích** | Cần backup database trước |
| 4 | **guacd không chạy trên kernel mới** | Cần compile lại guacamole-server cho 24.04 |
| 5 | **Thiếu dependencies cho 24.04** | Script sẽ cài tự động |
| 6 | **Không thể rollback OS** | Luôn snapshot VM trước khi nâng |

### Quy tắc bắt buộc

```
1. Luôn snapshot VM trước khi chạy Phase 1
2. Luôn dùng screen/tmux để giữ phiên SSH
3. Kiểm tra dung lượng ổ đĩa: df -h / (cần >= 15 GB trống)
4. Không tắt máy / reset giữa quá trình do-release-upgrade
5. Sau reboot, kiểm tra OS trước khi chạy Phase 2
6. Luôn có backup database + config trước khi nâng
```

---

## 3. Yêu cầu hệ thống

### Tối thiểu

| Thông số | Yêu cầu | Ghi chú |
|----------|---------|---------|
| CPU | 2 cores amd64 | ARM chưa hỗ trợ |
| RAM | 4 GB | Khuyến nghị 8 GB |
| Disk `/` | 15 GB trống | Cần cho packages mới + compile |
| OS hiện tại | Ubuntu 22.04 LTS | Kiểm tra: `lsb_release -a` |
| Guacamole | 1.6.0 | Kiểm tra: `cat /var/lib/tomcat*/webapps/guacamole/guacamole-common-js/modules/Version.js` |
| Tomcat | 9.0 | `systemctl status tomcat9` |
| Database | MySQL 8.0+ / MariaDB 10.5+ | `mysql --version` |

---

## 4. Quy trình chi tiết

### Phase 1: Backup + Nâng OS (chạy trên 22.04)

```bash
# 1. Cài screen để giữ phiên SSH
sudo apt install -y screen

# 2. Tạo session screen
screen -S upgrade-2404

# 3. Chạy script Phase 1
cd /path/to/UpgradeOS/22.04-to-24.04/
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh
```

Script sẽ tự động:

| Bước | Mô tả |
|------|-------|
| 0 | Kiểm tra OS = 22.04 LTS |
| 1a-1g | Backup toàn bộ config + DB + extensions + SSL |
| 2a | apt update/upgrade packages hiện tại |
| 2b | Cài update-manager-core |
| 2c | Cấu hình Prompt=normal |
| 2d | Dừng Tomcat + guacd |
| 2e | Chạy `do-release-upgrade` lên 24.04 |
| - | Hỏi reboot |

### Phase 2: Rebuild Guacamole (chạy trên 24.04)

Sau khi reboot vào 24.04:

```bash
# Kiểm tra OS
lsb_release -a
# => Ubuntu 24.04 LTS

# Chạy Phase 2
cd /path/to/UpgradeOS/22.04-to-24.04/
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --after-os-upgrade
```

Script Phase 2 sẽ:

| Bước | Mô tả |
|------|-------|
| 1 | apt update/upgrade cho 24.04 |
| 2 | Cài dependencies cho Guacamole |
| 3 | Dừng Tomcat + guacd |
| 4 | Download + compile guacamole-server cho kernel 24.04 |
| 5 | Nâng cấp database schema (nếu cần) |
| 6 | Khởi động lại services |
| - | Thông báo hoàn tất |

---

## 5. Hướng dẫn sử dụng Script

### Các mode

```bash
# Phase 1: Backup + do-release-upgrade 22.04 -> 24.04
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh

# Phase 2: Sau reboot, rebuild Guacamole cho 24.04
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --after-os-upgrade

# Restore từ backup
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --restore-backup /opt/backup/.../

# Fix network (nếu apt bị lỗi DNS/mirror)
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --fix-network

# Trợ giúp
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --help
```

### Cấu trúc backup

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

## 6. Kiểm tra sau nâng cấp

### Checklist

| # | Hạng mục | Lệnh kiểm tra |
|---|----------|---------------|
| 1 | OS version | `lsb_release -a` → `Ubuntu 24.04 LTS` |
| 2 | Kernel | `uname -r` → ≥ `6.8.x` |
| 3 | Disk | `df -h /` |
| 4 | Network | `ping -c 3 8.8.8.8` |
| 5 | Database | `systemctl status mariadb` |
| 6 | Tomcat | `systemctl status tomcat9` |
| 7 | Guacd | `systemctl status guacd` |
| 8 | Guacamole UI | `curl -I http://localhost:8080/guacamole` |
| 9 | Log | `tail -50 /opt/backup/guacamole-pre-24.04-*/upgrade-os-2404-guac.log` |

### Lưu thông tin hệ thống

```bash
{
  echo "=== SYSTEM INFO ==="
  echo "Date: $(date)"
  echo "OS: $(lsb_release -ds)"
  echo "Kernel: $(uname -r)"
  echo "CPU: $(nproc) cores"
  echo "RAM: $(free -h | grep Mem | awk '{print $2}')"
  echo "Disk: $(df -h / | tail -1 | awk '{print $4}') free"
  echo "Guacamole: $(cat /var/lib/tomcat*/webapps/guacamole/guacamole-common-js/modules/Version.js 2>/dev/null | grep -oP 'API_VERSION = "\K[^"]+' || echo 'unknown')"
  echo "Java: $(java -version 2>&1 | head -1)"
} | sudo tee /root/system-info-after-2404.txt
```

---

## 7. Xử lý sự cố & Rollback

### dpkg lock sau reboot — Process "noble" còn sót

Sau khi `do-release-upgrade` hoàn tất và reboot, process `noble` (Ubuntu release upgrader) có thể vẫn giữ lock dpkg:

```
Waiting for cache lock: Could not get lock /var/lib/dpkg/lock-frontend.
It is held by process 2722 (noble)...
```

**Xử lý:**

```bash
# 1. Kiểm tra process
ps aux | grep noble

# 2. Kill process còn sót
sudo kill <PID>

# 3. Dọn lock
sudo rm -f /var/lib/dpkg/lock-frontend
sudo rm -f /var/lib/dpkg/lock

# 4. Cấu hình packages dang dở
sudo dpkg --configure -a
sudo apt-get install -f -y

# 5. Chạy lại Phase 2
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --after-os-upgrade
```

> **Khuyến nghị:** Nếu không gấp, đợi 2-3 phút sau reboot cho process `noble` tự thoát.

### Guacamole không chạy sau Phase 2

```bash
# Kiểm tra services
systemctl status guacd --no-pager
journalctl -u guacd -n 50

systemctl status tomcat9 --no-pager
journalctl -u tomcat9 -n 50

# Kiểm tra Java
java -version

# Kiểm tra database
systemctl status mariadb
mysql -u root -e "USE guacamole_db; SHOW TABLES;"
```

### Lỗi apt (DNS/mirror)

```bash
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh --fix-network
```

### Rollback từ backup

```bash
# Liệt kê backup
ls -la /opt/backup/

# Restore tự động
sudo bash Upgrade_OS_from_22.04_to_24.04_LTS.sh \
  --restore-backup /opt/backup/guacamole-pre-24.04-YYYYMMDD-HHMMSS/
```

### Rollback OS (chỉ khi có VM snapshot)

```
1. Vào vSphere / Hyper-V
2. Chọn VM → Snapshots
3. Revert to snapshot trước khi nâng OS
4. Boot VM
5. Kiểm tra services
```

---

## 8. So sánh Ubuntu 22.04 vs 24.04

| Tính năng | Ubuntu 22.04 LTS | Ubuntu 24.04 LTS |
|-----------|-----------------|-----------------|
| **Tên mã** | Jammy Jellyfish | Noble Numbat |
| **Kernel** | 5.15.x | 6.8.x |
| **OpenSSL** | 3.0.x | 3.0.x (cập nhật) |
| **Python** | 3.10 | 3.12 |
| **GCC** | 11.x | 13.x |
| **systemd** | 249 | 255 |
| **Support đến** | Tháng 4/2027 | Tháng 4/2029 |
| **GLIBC** | 2.35 | 2.39 |
| **Network stack** | netplan.io 0.104 | netplan.io 0.106+ |

---

## Tham khảo

- Script gốc: [UpgradeOS](../README.md)
- Guacamole: https://guacamole.apache.org/
- Ubuntu Releases: https://releases.ubuntu.com/
- Ubuntu 24.04 Release Notes: https://discourse.ubuntu.com/t/noble-numbat-release-notes/39888

---

> **Tuyên bố miễn trừ trách nhiệm:** Nâng cấp OS là thao tác rủi ro cao. Người thực hiện chịu hoàn toàn trách nhiệm về dữ liệu. Luôn snapshot VM và kiểm tra backup trước khi tiến hành.
