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
Với Cloud9, Chúng tôi hy vọng các bạn có thêm 1 lựa chọn cho công cụ lập trình của mình trong bộ sưu tập DevOps và Agile-Scrum!

# Phần 2. Mô hình quản lý và vị trí khai thác sử dụng Cloud9:

## Giới thiệu về Hệ thống quản lý Dự án PMI và Tổ chức kế hoạch triển khai dự án Phần mềm Agile Scrum lưu tra cứu và Biên dịch code Github/Gitlab/Node.js/Cloud9

### Lược sử phát triển Private Cloud "Cloud Edge" và Cloud 9:

Hiện nay, trong lĩnh vực CNTT sẽ phải nhanh chóng nâng cấp việc quản lý dự án Công nghệ:
- Việc này cũng đã được bản thảo từ 2015 cho công tác quản lý Code source của các dự án DevOps.

- Sau đó năm 2018 có chính thức thử nghiệm phần “Agile scrum” với các vai trò quản lý khác nhau.

- Cuối năm 2019 thêm nhóm Lead PM nhập liệu thử nghiệm ở Opensource Orangescrum, GitLab  xong chưa thành công ở khâu quản lý source code, biên dịch Sourcecode, quản lý vòng đời phát triển (CI-CD LifeCycle software).
	
- Đến năm 2020 thực hiện hoá việc quản lý Lương khoán, tiến độ công việc … thì đi theo công nghệ quản lý PMI/PMP (Project Management Infrastructure — thiên về quản trị tài chính, tiền lương, tiến độ dự án và hồ sơ người phụ trách công việc).

- Cuối năm 2020 đã tích hợp giữa PMI với Agile Scurm Master và cho tích hợp với GitLabs, Github, Cloud9, Node.js để lưu các phiên bản code source hoặc Complier/De-complier các code source gửi sandbox và cho chạy trên các Web chuẩn HTML5 multi-devices.
(các source code chạy được Web như: IIS, Apache, NGINX, .Net framework/ Smartbox cho SharePoint Server…) và

- Năm 2021 tích hợp mảng IT Helpdesk Support của Công ty do IT-Helpdesk phụ trách (nó thuộc chuẩn Cobit, ITILv4, ITSAM, ITAM) cung cấp các dự án troubleshooting sau triển khai. 

- Giữa năm 2021 tích hợp hệ thống Cloud Edge giúp điều khiển các VDI, Virtual Desktop, PC Workstation có OS linux, Unix, Windows được điều khiển từ xa qua Proxy, FreeSwitch, FreeRDP, X11, xRDP, K8s Kube RDP... ổn định, mã hóa local PPK, issueSSL/TLS... 

- Đầu năm 2022 tích hợp hệ thống LDAPS, ADFS 2019 , CA enterprise với Let's Ecnrypt issue Local SSL/TLS và với vSphere vCenter 7u3 , 8u2, và SAML cho Veeam 11.a.

- Đầu năm 2023 tích hợp CoPilot iAM Platform cấu hình tích hợp Rest API với ADFS làm trang SSO Login cho .Net IIS và SAML 2 cho oAuth2 và các sản phẩm Web Service như MS Entra ID, SAML 2 VBR 11.a hoặc 12.x.

- Giữa năm 2024 nâng cấp iAM Security Paltform cho các giải pháp vừa Xác định danh tính, vừa kiểm toán PAM, IT Audit và Phân tích hành vi người dùng trong mạng Smart Campus Univeristy/School.

- Cuối năm 2024 bắt đầu bổ sung Pen-testing Checklist các việc triển khai hạ tầng Data Center, firmware/BIOS/LSI/Card RAID Controller bằng iDRAC/IPMI/iLO/BMC và OTP qua Email.

- Hiện nay 2025 tại việc này là một khối lượng công việc Tổng thể, các việc về lâu dài của ngành CNTT nói chung và là cơ hội quản lý tiến độ, chất lượng công việc, chăm sóc khách hàng của Công ty…

Nó cũng là nhiệm vụ hàng đầu hiện nay của cả nhóm (cho dựng hệ thống Demo, Trial, Pilot và chuyển sang khai thác sử dụng thật sự).

### Quy trình cơ bản có sử dụng Cloud 9:

#### Quy trình 1. Phân tích đầu vào dự án – SWOT:

**(Mục đích: phân tích cơ hội, kế hoạch, các rủi ro trước khi ra quyết định triển khai dự án BOM /Mind-stone power)**

![image](https://github.com/user-attachments/assets/206ee08f-1e9a-4571-bee7-dda85834efa4)

*(Zoom in: phóng to các bước thực hiện trong Quản lý dự án Phần Cứng, Triển khai hạ tầng DCV)*

#### Quy trình 2. Công đoạn quản lý phát triển DevOps phần mềm tổng thể:

![image](https://github.com/user-attachments/assets/d2bdcece-4c09-46e6-a1ac-e25e65456117)

#### Quy trình 3. Phân tích cấu trúc thiết lập và vận hành “Business Operation Structure Basic”:

![image](https://github.com/user-attachments/assets/fb11fa04-8746-476a-8fb0-33551d4a7a54)

- Xây dựng các sơ đồ tư duy, nhằm nâng cao nhận thức/ quy trình có tính quy luật cho triển khai hoặc giám sát vận hành:

![image](https://github.com/user-attachments/assets/518a3d22-9b92-4dfc-9a50-a13f8c54d986)

*Ví dụ: quy trình labs để tổ chức dịch vụ nâng cấp và vá lỗi Outlook người dùng cho MS Office 365 (liên quan tới IT Helpdesk vs troubleshooting)*

#### Quy trình 4. Lead PM trong công tác quản lý tiến độ, nhân sự, đầu việc và các phương thức xử lý dự án PMI:

![image](https://github.com/user-attachments/assets/d8225af4-59a1-4a90-ade1-1cfc35abde11)

*(Tham khảo: PMI quản lý tiến độ, nhân sự, đầu công việc và dự toán chi phí)*

#### Quy trình 5. Tập trung dữ liệu tại Cổng thông tin Quản lý đầu vào và xử lý dự án PMI:

*Ví dụ: http://pmi.company.vn (cổng thông tin PMI Demo trial)*

**Mục đích:**
1. Theo dõi tiễn độ, Nhật ký công việc hàng ngày (Dashboard Today)
1. Đầu công việc (Activity Stream)
1. Nhân sự,
1. Chi phí theo lương khoá, công nhật, giờ/ngày/tháng/đầu kết quả – thuê dự án (Kanban)
1. Chất lượng helpdesk support được phản hồi từ khách hàng (Tickets dashboard).
1. Tài liệu thiết kế, phân tích đầu vào các dự án (Milestone )
1. Tài liệu hoàn công, tập huấn, bàn giao các dự án (Documents/ Kb/ Case Open/Closed tickets)
1. Tài liệu KB, Troubleshooting Case chia sẻ theo Khách hàng hoặc theo dự án Pipeline (Issues)

#### Quy trình 6. Cập nhật dữ liệu vận hành các công cụ hạ tầng quản lý dịch vụ:
*(Các công cụ hạ tầng cho vận hành, quản lý Source code và quy trình sản xuất phần mềm)*

1. ITIL (Quản lý các dịch vụ Helpdesk, chăm sóc HW/SW CNTT)
1. ITSAM (Công cụ quản lý, check list, Document Check-in/out, Quản lý tài sản, Chế độ bảo hành, tài liệu theo dõi History Version nâng cấp HW/SW CNTT)
1. Tích hợp với phần mềm quản lý các tác vụ trong sản xuất phần mềm Như: Agile – SCRUM – Kanban
1. Đồng thời cũng tích hợp để theo dõi các phiên bản Source Code theo các hãng như: Gitlabs, Gihub, Node.js, Codeplex, Cloud9 đều là dòng On-prem.

Hiện nay, Cổng thông tin Cloud9 này đã tích hợp cả 5 phần quản lý quy trình sản xuất phần mềm /tài liệu trong CI/CD Pipeline data and Documentations như: 
1. Git, 
1. GitHub, 
1. GitLabs,
1. Azure DevOps Desktop
1. Jira Service Management for ITSM (Tối ưu quy trình quản lý dự án).

hoặc DevSecOps như:
1. GitEA (Github Agile scrum On-Prem)
 
Đáp ứng cho chục loại ngôn ngữ lập trình như:
1. Visual Studio,
1. Netbeans, 
1. Eclipse, 
1. Visual Android Studio, 
1. Xcode, 
1. Visual Code (VS Code), 
1. Cloud9, C9, 
1. Node.js, 
1. C, C++, C#, Visual C
1. Visual Basic - VB, VB .net, 
1. Visual Fox - VF, F#, VF .net,
1. PHP development, 
1. JSon, 
1. CSS, 
1. XML, 
1. HTML, 
1. JS, 
1. java Jenkins, java jetty…
