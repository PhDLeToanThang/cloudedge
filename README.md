# Guacamole setup version 1.5.4: Updated 7.12.2023
Script guacamole 1.5.4 for Linux e.g: ubuntu 22.04 LTS OpenvSwitch 25Gbps, Tomcat 9.x PHP 8.x MySQL 5.x NGINX 1.8.x Certbot Let's Encrypt 2.x TLS 1.2/1.3

1. Bước 1. Run: Download và chạy code cài guac Gõ lệnh trên thông qua màn PuTTy đã kết nối thành công tới ipv4 của Ubuntu 20.04:
   
wget https://raw.githubusercontent.com/PhDLeToanThang/guacamole/main/setup154.sh && sudo bash setup154.sh

- LƯU Ý: SSH không hoạt động với Ubuntu 22.04:
Guacamole chỉ hỗ trợ ssh-dss và ssh-rsa và cả hai đều đã bị tắt trong Ubuntu 22.04.
Trong thời gian chờ đợi, giải pháp thay thế là thêm HostKeyAlgorithms +ssh-rsa vào cuối /etc/ssh/sshd_config trên máy Ubuntu và khởi động lại sshd.

2. Bước 2. Upgrade 1.5.4: Download và chạy code cài Upgrade Gõ lệnh trên thông qua màn PuTTy đã kết nối thành công tới ipv4 của Ubuntu 20.04:

wget https://raw.githubusercontent.com/PhDLeToanThang/guacamole/main/upgrade154.sh && sudo bash upgrade154.sh

-------------------------------
# guacamole setup version 1.5.0:
script guacamole 1.5.x for Linux e.g: ubuntu 20.04 LTS Tomcat 9.x PHP 8.x MySQL 5.x NGINX 1.8.x Certbot Let's Encrypt 2.x TLS 1.2/1.3
#Run: Download và chạy code cài guac Gõ lệnh trên thông qua màn PuTTy đã kết nối thành công tới ipv4 của Ubuntu 20.04:
wget https://raw.githubusercontent.com/PhDLeToanThang/guacamole/main/Setup150.sh && sudo bash Setup150.sh

-------------------------------
# guacamole setup version 1.4.0:
script guacamole 1.4.0  for Linux e.g: ubuntu 20.04 LTS Tomcat 9.x PHP 8.x MySQL NGINX 1.8.x Certbot 2.x Let's Encrypt 2.x TLS 1.2/1.3
#Run: Download và chạy code cài guac Gõ lệnh trên thông qua màn PuTTy đã kết nối thành công tới ipv4 của Ubuntu 20.04:
wget https://raw.githubusercontent.com/PhDLeToanThang/guacamole/main/Setup145.sh && sudo bash Setup145.sh

------------------------------------------
# Guacamole Update from version 1.4 to 1.5
#Run:
 Download và chạy code cài guac
Gõ lệnh trên thông qua màn PuTTy đã kết nối thành công tới ipv4 của Ubuntu 20.04:
cd /opt
wget https://raw.githubusercontent.com/PhDLeToanThang/guacamole/main/upgrade15.sh && bash upgrade15.sh
