# Phần 1. Cài đặt Cloud9 Web (c9) – Công cụ lập trình biên dịch chuẩn IDE trên nền Web:

## Giới thiệu C9

Cloud9 là một nên tảng phát triển đám mây (IDE) cho phép bạn viết, chạy và debug code của mình chỉ với một trình duyệt. Nó bao gồm một trình soạn thảo code, debug và terminal. Cloud9 hỗ trợ nhiều ngôn ngữ phổ biến như là PHP, Python, Ruby… Với Cloud 9 bạn có thể lập trình ở bất cư nơi đâu, miễn là có internet, WAN hoặc LAN hoặc WLAN.

> Cloud9 hiện đã opensource dịch vụ của họ trên Github tại địa chỉ: https://github.com/c9/core. Vì vậy, bạn có thể tự cài đặt cho mình một IDE nền web trên máy chủ, trên localhost. Hiện tại AT.COM cũng đang host các máy chủ Cloud 9 Web IDE trên máy chủ điện toán của AT.COM Lab và đang tích hợp vận hành với DevOps, Agile, Scrum, PMI và Node.js rất hiệu quả cho các dự án Coding, lập trình và quản lý dự án phần mềm trên Cloud của AT.COM.

## Hướng dẫn cài đặt C9 Web IDE

Bài viết này sẽ hướng dẫn các bạn cài đặt trên máy chủ CentOS/RedHat.

**1. Cài đặt NodeJS**

Bước đầu tiên là cần cài đặt NodeJS, git bằng command dưới đây
```
sudo yum install nodejs nodejs-legacy git
```

**2. Cài đặt C9 Web IDE**

Thực hiện clone resource từ Github để tiến hành cài đặt
```
git clone https://github.com/c9/core cloud9
cd cloud9
./scripts/install-sdk.sh
```

**3. Khởi động Cloud9 Web IDE Server**

Sau khi cài đặt thành công, để start server lên, sử dụng command sau:
```
node server.js –listen 0.0.0.0 -p 8080 -a username:password -w /opt/myprojectname/
```

>Ý nghĩa các tham số: 
>–listen 0.0.0.0: là địa chỉ ipv4 muốn public ra
>-p: là cổng dịch vụ
>-a: là user/password xác thực
>-w: là workspace nơi chứa source code

Các bạn có thể truy cập thông qua qua địa chỉ: http://localhost:8080, chúng ta sẽ có giao diện Web IDE như bên dưới
Nếu muốn mở cổng firewall cho truy cập từ LAN/WAN vào cloud9:

ở màn Terminal của cloud 9 server gõ lệnh:
```
firewall-cmd –zone=public –add-port=8080/tcp –permanents
```
sau đó gõ lệnh tiếp để cổng này được mở và thực thi:
```
Firewall-cmd –reloads
```
Để test port http, gõ lệnh sau:
```
lsof -i -P |grep http
```

nếu muốn chạy nhiều project cùng 1 lúc thì các bạn sử dụng tham số -w , command như sau:
```
node server.js -p 8080 -a thanglt:pa25w.rd -w /opt/myproject_1/
node server.js -p 8080 -a thanglt:Pa25w.rd -w /opt/myproject_2/
```
**4. Cấu hình khởi động cùng hệ điều hành:**

– Cài đặt supervisor, công cụ quản lý process
```
sudo yum install supervisor
```
– Tạo script khởi động cho Cloud9 Web IDE
```
sudo nano /etc/supervisor/conf.d/cloud9.conf
```
Thêm nội dung sau:
```
[program:cloud9]
command=/usr/bin/node /home/thanglt/cloud9/server.js –listen 0.0.0.0 -p 8080 -w /opt/myproject -a thanglt:password
user=thanglt
directory=/home/thanglt
autostart=true
autorestart=true
startretries=3
stderr_logfile=/var/log/cloud9/cloud9.err.log
stdout_logfile=/var/log/cloud9/cloud9.out.log
```
– Sau đó restart lại supervisor:
```
sudo /etc/init.d/supervisor restart
```
Với Cloud9, AT.COM hy vọng các bạn có thêm 1 lựa chọn cho công cụ lập trình của mình trong bộ sưu tập DevOps và Agile-Scrum!
