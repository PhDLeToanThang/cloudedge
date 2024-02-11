# Guacamole setup version 1.5.4: Updated 7.12.2023
Script guacamole 1.5.4 for Linux e.g: ubuntu 22.04 LTS OpenvSwitch 25Gbps, Tomcat 9.x PHP 8.x MySQL 5.x NGINX 1.8.x Certbot Let's Encrypt 2.x TLS 1.2/1.3

1. Bước 1. Run: Download và chạy code cài guac Gõ lệnh trên thông qua màn PuTTy đã kết nối thành công tới ipv4 của Ubuntu 20.04:
   
wget https://raw.githubusercontent.com/PhDLeToanThang/guacamole/main/advanced/s1-setup.s

![image](https://github.com/PhDLeToanThang/guacamole/assets/106635733/e4dd4678-65d8-44d1-be4e-da97a5c0de9d)

![image](https://github.com/PhDLeToanThang/guacamole/assets/106635733/b12004e7-1bcb-4ef5-9f89-a5c6b20216f3)

- LƯU Ý: SSH không hoạt động với Ubuntu 22.04:
Guacamole chỉ hỗ trợ ssh-dss và ssh-rsa và cả hai đều đã bị tắt trong Ubuntu 22.04.
Trong thời gian chờ đợi, giải pháp thay thế là thêm HostKeyAlgorithms +ssh-rsa vào cuối /etc/ssh/sshd_config trên máy Ubuntu và khởi động lại sshd.

2. Bước 2. Cấp quyền chạy và dùng lệnh chạy: 
chmod +x s1-setup.sh && bash ./s1-setup.sh
