# Phần 1. Cài đặt Cloud9 Web (c9) – Công cụ lập trình biên dịch chuẩn IDE trên nền Web

> **Tài liệu tổng hợp:** PhD. Lê Toàn Thắng
>
> **Repository gốc:** [github.com/c9/core](https://github.com/c9/core) (archived 04/2021)
>
> **Demo:** [c9.github.io/core](https://c9.github.io/core/)
>
> **Bài viết tham khảo:** [Cài đặt Cloud9 Web IDE trên Ubuntu/CentOS](https://thangletoan.wordpress.com/2020/02/11/cai-dat-cloud9-web-c9-cong-cu-lap-trinh-ide-nen-web/)

## Giới thiệu C9

**Cloud9** là một nền tảng phát triển đám mây (IDE) cho phép bạn viết, chạy và debug code của mình chỉ với một trình duyệt. Nó bao gồm một trình soạn thảo code (Ace editor), debugger, terminal emulator và hỗ trợ nhiều ngôn ngữ phổ biến như PHP, Python, Ruby, JavaScript, Go, CSS, HTML… Với Cloud9 bạn có thể lập trình ở bất cứ nơi đâu, miễn là có internet, WAN, LAN hoặc WLAN.

> Cloud9 hiện đã opensource dịch vụ của họ trên Github tại địa chỉ: https://github.com/c9/core. Vì vậy, bạn có thể tự cài đặt cho mình một IDE nền web trên máy chủ, trên localhost. Các tổ chức đang host các máy chủ Cloud9 Web IDE trên máy chủ điện toán và đang tích hợp vận hành với DevOps, Agile, Scrum, PMI và Node.js rất hiệu quả cho các dự án Coding, lập trình và quản lý dự án phần mềm trên Cloud.

Năm 2016, Cloud9 được AWS mua lại và mã nguồn Cloud9 v3 SDK được mở tại github.com/c9/core dưới dạng **SDK cho Plugin Development**. Repository này đã được archive (read-only) từ tháng 4/2021, tuy nhiên mã nguồn vẫn hoạt động tốt và có thể self-hosted trên Ubuntu 24.04 LTS.

## Hướng dẫn cài đặt C9 Web IDE trên Ubuntu 24.04 LTS

Bài viết này hướng dẫn cài đặt trên máy chủ **Ubuntu 24.04 LTS** với **Nginx reverse proxy**, **Let's Encrypt SSL**, và **systemd service**.

> **Script tự động:** Tham khảo file `setup.sh` đi kèm để cài đặt tự động toàn bộ quy trình dưới đây.

### Yêu cầu hệ thống

| Component | Tối thiểu | Khuyến nghị |
|---|---|---|
| CPU | 1 core | 2 cores+ |
| RAM | 1 GB | 2-4 GB |
| Disk | 5 GB | 20 GB+ (cho workspaces) |
| Network | 100 Mbps | 1 Gbps |
| OS | Ubuntu 24.04 LTS | Hoặc mới hơn |

### 1. Cài đặt Node.js

Cloud9 Core SDK yêu cầu Node.js. Phiên bản khuyến nghị là **16.x LTS** (tương thích tốt nhất với các dependencies cũ). Sử dụng **nvm**:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 16
nvm alias default 16
node --version   # v16.x.x
npm --version    # 8.x.x
npm config set python python3
```

### 2. Cài đặt C9 Web IDE

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y build-essential git curl wget tmux nginx python3 python3-pip python3-venv certbot ufw
sudo mkdir -p /opt
sudo git clone https://github.com/c9/core.git /opt/c9sdk
sudo chown -R $USER:$USER /opt/c9sdk
cd /opt/c9sdk
npm install --legacy-peer-deps
```

> **Lưu ý:** Không dùng `scripts/install-sdk.sh` gốc (yêu cầu Python 2.7 + Node.js v6 không còn hỗ trợ trên Ubuntu 24.04).

### 3. Patch terminal cho Node.js 16+

`node-pty-prebuilt@0.7.3` không tương thích Node.js 16+. Patch sang `node-pty`:

```bash
npm uninstall node-pty-prebuilt
npm install node-pty@0.10.1
find plugins -name "*.js" -type f -exec sed -i 's/require("node-pty-prebuilt")/require("node-pty")/g' {} +
sed -i 's/node-pty-prebuilt/node-pty/g' plugins/*/package.json 2>/dev/null || true
```

### 4. Khởi động Cloud9 Web IDE Server

```bash
node server.js --listen 127.0.0.1 -p 8181 -a username:password -w /home/user/workspace --packed
```

**Ý nghĩa tham số:**
- `--listen 127.0.0.1`: Chỉ listen localhost (Nginx proxy ra ngoài)
- `-p 8181`: Cổng dịch vụ nội bộ
- `-a username:password`: Basic Auth
- `-w /path`: Workspace chứa source code
- `--packed`: Production mode

Truy cập: **http://localhost:8181** hoặc qua domain sau khi cấu hình Nginx.

### 5. Cấu hình khởi động cùng hệ điều hành (systemd)

```bash
sudo tee /etc/systemd/system/cloud9.service > /dev/null << 'SERVICEEOF'
[Unit]
Description=Cloud9 Web IDE
Documentation=https://github.com/c9/core
After=network.target nginx.service
Wants=nginx.service

[Service]
Type=simple
User=cloud9
Group=cloud9
WorkingDirectory=/opt/c9sdk
ExecStart=/home/cloud9/.nvm/versions/node/v16.x.x/bin/node /opt/c9sdk/server.js -l 127.0.0.1 -p 8181 -w /home/cloud9/workspace -a admin:your_password --packed
Restart=always
RestartSec=15
Environment=NODE_ENV=production
Environment=NODE_PATH=/opt/c9sdk/node_modules
Environment=C9_WORKSPACE=/home/cloud9/workspace
NoNewPrivileges=true
ProtectSystem=full
PrivateTmp=true
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICEEOF

sudo useradd -m -s /bin/bash cloud9
sudo mkdir -p /home/cloud9/workspace
sudo chown -R cloud9:cloud9 /home/cloud9/workspace /opt/c9sdk
sudo systemctl daemon-reload
sudo systemctl enable --now cloud9
```

### 6. Cấu hình Nginx Reverse Proxy

```nginx
server {
    listen 80;
    server_name c9.example.com;
    return 301 https://$server_name$request_uri;
}
server {
    listen 443 ssl http2;
    server_name c9.example.com;
    ssl_certificate     /etc/letsencrypt/live/c9.example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/c9.example.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
    ssl_prefer_server_ciphers on;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    location / {
        proxy_pass http://127.0.0.1:8181;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400s;
        proxy_buffering off;
    }
    location /static/ {
        proxy_pass http://127.0.0.1:8181/static/;
        proxy_cache_valid 200 302 60m;
        expires 7d;
    }
    client_max_body_size 100M;
}
```

Kích hoạt:
```bash
sudo ln -sf /etc/nginx/sites-available/cloud9 /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

### 7. Cấu hình SSL/TLS

**Let's Encrypt (có domain public DNS):**
```bash
sudo certbot --nginx --non-interactive --agree-tos -m admin@c9.example.com -d c9.example.com
```

**Self-Signed SSL (không có domain):**
```bash
sudo mkdir -p /etc/ssl/cloud9
sudo openssl req -x509 -nodes -days 3650 -newkey rsa:4096 -keyout /etc/ssl/cloud9/cloud9.key -out /etc/ssl/cloud9/cloud9.crt -subj "/C=VN/ST=Hanoi/L=Hanoi/O=Cloud9/CN=$(hostname -f)"
```

> **Lưu ý:** Trình duyệt cảnh báo với self-signed cert. Dùng Let's Encrypt cho production.

### 8. Firewall

```bash
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 'Nginx Full'
sudo ufw --force enable
```

### 9. Kiểm tra và quản lý

```bash
sudo systemctl status cloud9
sudo journalctl -u cloud9 -f
sudo nginx -t
sudo tail -f /var/log/nginx/access.log
```

Sau khi hoàn tất, truy cập **https://c9.example.com** để sử dụng Cloud9 IDE.

---
# Phần 2. Mô hình quản lý và vị trí khai thác sử dụng Cloud9

## Giới thiệu về Hệ thống quản lý Dự án PMI và Tổ chức kế hoạch triển khai dự án Phần mềm Agile Scrum — lưu tra cứu và Biên dịch code Github/Gitlab/Node.js/Cloud9

### Lược sử phát triển Private Cloud "Cloud Edge" và Cloud 9

Hiện nay trong lĩnh vực CNTT, việc quản lý dự án Công nghệ đã trải qua nhiều giai đoạn phát triển:

- **2015:** Bản thảo đầu tiên cho công tác quản lý Code source của các dự án DevOps.
- **2018:** Thử nghiệm "Agile Scrum" với các vai trò quản lý khác nhau.
- **2019:** Thử nghiệm Opensource Orangescrum, GitLab — chưa thành công ở khâu quản lý source code, biên dịch, quản lý vòng đời phát triển (CI/CD LifeCycle).
- **2020:** Thực hiện hoá quản lý theo **PMI/PMP** (Project Management Infrastructure). Cuối năm tích hợp **PMI + Agile Scrum + GitLabs, Github, Cloud9, Node.js** để lưu phiên bản code source, Complier/De-complier code sandbox và chạy Web chuẩn HTML5 multi-devices.
- **2021:** Tích hợp **IT Helpdesk Support** chuẩn Cobit, ITILv4, ITSAM, ITAM. Tích hợp **Cloud Edge** điều khiển VDI, Virtual Desktop từ xa qua Proxy, FreeSwitch, FreeRDP, X11, xRDP, K8s Kube RDP... mã hóa local PPK, SSL/TLS.
- **2022:** Tích hợp **LDAPS, ADFS 2019, CA Enterprise** — Let's Encrypt Local SSL/TLS, vSphere vCenter 7u3/8u2, SAML cho Veeam 11.a.
- **2023:** Tích hợp **CoPilot iAM Platform** — Rest API với ADFS làm SSO Login cho .NET IIS, SAML 2 cho oAuth2, MS Entra ID.
- **2024:** Nâng cấp **iAM Security Platform** — xác định danh tính, kiểm toán PAM, IT Audit, phân tích hành vi người dùng Smart Campus. Bổ sung **Pen-testing Checklist** triển khai Data Center qua iDRAC/IPMI/iLO/BMC.
- **2025:** Hoàn thiện quản lý tiến độ, chất lượng, chăm sóc khách hàng tổng thể.
- **2026:** Tích hợp AI Agent vào quy trình DevSecOps, tự động hóa kiểm thử bảo mật và phân tích code.

## Kiến trúc tổng quan Cloud9 Core SDK

### Sơ đồ kiến trúc

```
+--------------------------------------------------------------+
|                   Browser (Client)                           |
|  +--------------------------------------------------------+  |
|  |           Cloud9 IDE (Single Page Application)          |  |
|  |  +------+ +------+ +--------+ +------+ +------+       |  |
|  |  | Ace  | |Termi-| |Language| | Run/ | |  UI  |       |  |
|  |  |Editor| | nal  | |Support | |Debug | |Frame |       |  |
|  |  +------+ +------+ +--------+ +------+ +------+       |  |
|  |              AMD Loader (require.js)                    |  |
|  +--------------------------+-----------------------------+  |
+-----------------------------+--------------------------------+
                              | HTTPS / WSS
                              v
+--------------------------------------------------------------+
|               Nginx Reverse Proxy (port 443)                  |
|  SSL Termination -> Proxy Pass -> http://127.0.0.1:8181     |
|  WebSocket Upgrade: / -> ws://127.0.0.1:8181                |
+-----------------------------+--------------------------------+
                              |
+-----------------------------v--------------------------------+
|               Cloud9 Server (Node.js 16.x)                    |
|  +--------------------------------------------------------+  |
|  |  server.js (bootstrap + config selection)              |  |
|  |  +----------+ +--------------+ +--------------------+  |  |
|  |  | Architect| |  Connect     | |  Settings/Config   |  |  |
|  |  | DI Frame | |  Middleware  | |  (standalone.js)   |  |  |
|  |  +----------+ +--------------+ +--------------------+  |  |
|  +--------------------------------------------------------+  |
|  +--------------------------------------------------------+  |
|  |                 Plugins (100+)                          |  |
|  |  +--------+ +--------+ +--------+ +----------------+   |  |
|  |  |c9.core | |c9.vfs.*| |c9.ide.*| |c9.cli.*        |   |  |
|  |  |services| |FS virt | |client  | |command line     |   |  |
|  |  +--------+ +--------+ +--------+ +----------------+   |  |
|  |  +--------+ +--------+ +--------+ +----------------+   |  |
|  |  |c9.static|c9.preview|c9.nodeapi|c9.error          |   |  |
|  |  |CDN/Bld  | preview | API     |error handling     |   |  |
|  |  +--------+ +--------+ +--------+ +----------------+   |  |
|  +--------------------------------------------------------+  |
+--------------------------------------------------------------+
                              |
         +---------------------+----------------------+
         v                     v                      v
+------------------+ +------------------+ +------------------+
|  Workspace FS     | |  tmux (term)     | |  node-pty        |
|  (/home/user/ws)  | |  ~/.c9/bin/tmux  | |  (pty.js)        |
+------------------+ +------------------+ +------------------+
```

### Luồng request

1. **Browser** -> HTTPS request den Nginx (port 443)
2. **Nginx** SSL termination -> proxy_pass HTTP toi 127.0.0.1:8181
3. **Connect middleware** xu ly: basic auth -> static files -> routing
4. **Engine.io** WebSocket cho realtime communication (editor, terminal, collab)
5. **Plugins** xu ly logic nghiep vu: filesystem, run, debug, language analysis
6. **Ket noi workspace** thu muc that tren server qua VFS layer

### Stack cong nghe

| Layer | Cong nghe | Phien ban |
|---|---|---|
| Runtime | Node.js | 16.x LTS |
| DI Framework | Architect (connect-architect) | Internal |
| HTTP Server | Connect | 2.12.x |
| WebSocket | Engine.io | 1.6.x |
| Editor | Ace (Cloud9 fork) | Built-in |
| Module System | AMD (amd-loader) | Client + Server |
| Templating | EJS | 1.0.x |
| CSS Preprocessor | Less | 2.4.x |
| Terminal | tmux + node-pty | >=2.2 / >=0.10 |
| Reverse Proxy | Nginx | >=1.24 |
| SSL | Let's Encrypt / OpenSSL | Certbot / self-signed |

## Cac thanh phan loi

### server.js - Entry point

File khoi dong chinh cua Cloud9 server:
- Load `amd-loader` ho tro AMD define/require tren Node.js
- Kiem tra phien ban Node.js
- Chon **configuration profile**: `s` = standalone (mac dinh), `dev`, `onlinedev`, `beta`, `localdev`
- Load **settings file** tu `settings/<name>.js`
- Goi `architect.resolveConfig()` + `architect.createApp()` bootstrap plugin system

### configs/standalone.js - Plugin manifest

Dinh nghia danh sach plugin cho standalone mode:
- **connect-architect plugins**: HTTP server, basic auth, static files, CORS, redirect, render EJS
- **c9.core/ext**: Extension registry
- **c9.ide.server/ide-statics**: Serve IDE client assets
- **c9.vfs.standalone + c9.vfs.server**: Virtual filesystem services
- **c9.preview, c9.nodeapi, c9.static**: Preview, API, CDN/Build
- **c9.error, c9.analytics, c9.metrics**: Error handling, analytics mocks

CLI options (dinh nghia tai configs/standalone.js):

| Option | Alias | Mo ta | Default |
|---|---|---|---|
| `-p` / `--port` | | Cong HTTP | `$PORT` hoac 8181 |
| `-l` / `--listen` | | IP listen | `$IP` hoac 127.0.0.1 |
| `-a` / `--auth` | | Basic Auth `user:pass` | Khong auth |
| `-w` | | Workspace directory | Thu muc hien tai |
| `--packed` | | Dung ban packed (production) | false |
| `--collab` | | Bat collaboration | false |
| `--readonly` | `-ro` | Che do chi doc | false |
| `--debug` | `-d` | Debug mode | false |
| `--secure` | | Path SSL certificate | none |
| `-t` | | Test mode | false |
| `-b` | | Bridge server (CLI) | false |

## He thong Plugins

Cloud9 Core SDK su dung **Architect framework** - dependency injection container cho Node.js. Moi plugin la mot thu muc chua `package.json` (architect format) va AMD code.

### Plugin lifecycle
```
server.js
  +-> Load configs/<profile>.js -> mang plugin descriptors
  +-> architect.resolveConfig(plugins) -> dependency graph
  +-> architect.createApp(config, callback) -> load plugins
  +-> App ready -> HTTP server listening
```

### Phan loai Plugins

| Nhom | Plugin | Chuc nang |
|---|---|---|
| **Core** | `c9.core` | App framework: settings, extension registry, API client |
| | `c9.error` | Error handling, logging |
| | `c9.fs` | Filesystem abstraction (fs, proc, net) |
| **Editor** | `c9.ide.ace` | Ace editor integration |
| | `c9.ide.ace.keymaps` | Keymap (Vim, Emacs, Sublime) |
| | `c9.ide.ace.split` | Split pane editor |
| **Language** | `c9.ide.language.javascript` | JS (Tern.js, ESLint, inference) |
| | `c9.ide.language.css/html` | CSS/HTML support |
| | `c9.ide.language.python/go` | Python/Go support |
| | `c9.ide.language.codeintel` | PHP code intelligence |
| **Run/Debug** | `c9.ide.run` | Run framework |
| | `c9.ide.run.debug` | Debugger (V8, GDB, XDebug, ikpdb) |
| **Terminal** | `c9.ide.terminal` | Terminal emulator (tmux + node-pty) |
| **Collab** | `c9.ide.collab` | Real-time collaboration (OT, chat, cursors) |
| **VFS** | `c9.vfs.server` | Virtual filesystem server |
| | `c9.vfs.client` | VFS client (browser) |
| **Static** | `c9.static` | CDN + build cache |
| **UI** | `c9.ide.ui` | UI framework (menus, forms, widgets) |
| | `c9.ide.theme.*` | Themes (flat light/dark) |
| **SCM** | `c9.ide.scm` | Git integration |
| **CLI** | `c9.cli.*` | CLI bridge, exec, mount, sync |

## Quy trinh co ban co su dung Cloud 9

### Quy trinh 1. Phan tich dau vao du an - SWOT

Phan tich co hoi, ke hoach, cac rui ro truoc khi ra quyet dinh trien khai du an. (Tham khao hinh anh SWOT analysis trong tai lieu quan ly du an PMI)

### Quy trinh 2. Cong doan quan ly phat trien DevOps phan mem tong the

Cloud9 dong vai tro la IDE trung tam trong pipeline DevOps:
- **Code**: Cloud9 Editor (Ace) - da ngon ngu
- **Build**: Node.js, npm, cac language runners
- **Test**: Mocha, Chai, Selenium
- **Release**: Git integration (commit, push, pull)
- **Deploy**: Terminal truy cap server qua SSH

### Quy trinh 3. Business Operation Structure Basic

Cloud9 tich hop voi:
- **ITIL**: Quan ly dich vu Helpdesk, cham soc HW/SW CNTT
- **ITSAM**: Quan ly tai san, Document Check-in/out
- **Agile - Scrum - Kanban**: Quan ly tac vu san xuat phan mem
- **GitLabs, Github, Node.js, Codeplex, Cloud9**: Quan ly phien ban Source Code On-prem

### Quy trinh 4. Lead PM quan ly tien do, nhan su, dau viec

Cloud9 phuc vu nhu mot cong cu trong he thong PMI:
1. Theo doi tien do, Nhat ky cong viec hang ngay
2. Dau cong viec (Activity Stream)
3. Nhan su, Chi phi theo luong khoan
4. Chat luong helpdesk support phan hoi tu khach hang
5. Tai lieu thiet ke, phan tich dau vao cac du an
6. Tai lieu hoan cong, tap huan, ban giao
7. Tai lieu KB, Troubleshooting Case

### Quy trinh 5. Tap trung du lieu tai Cong thong tin Quan ly PMI

Cong thong tin Cloud9 tich hop 5 phan quan ly quy trinh san xuat phan mem trong CI/CD Pipeline:
1. **Git** - Version control
2. **GitHub** - Open source collaboration
3. **GitLabs** - On-prem DevOps
4. **Azure DevOps Desktop** - Microsoft ecosystem
5. **Jira Service Management for ITSM** - Toi uu quy trinh quan ly du an

Va DevSecOps:
1. **GitEA** (Github Agile scrum On-Prem)
2. **AI Agent** tu dong hoa kiem thu bao mat

Dap ung cho nhieu ngon ngu lap trinh: Visual Studio, Netbeans, Eclipse, Android Studio, Xcode, VS Code, Cloud9/C9, Node.js, C/C++/C#, VB/VB.NET, VF/F#, PHP, JSON, CSS, XML, HTML, JS, Java Jenkins, Java Jetty...

## Xu ly su co (Troubleshooting)

| Van de | Nguyen nhan | Giai phap |
|---|---|---|
| Node.js GLIBC error | Ubuntu 24.04 glibc moi | Dung nvm install ban prebuilt |
| Terminal khong hoat dong | Thieu node-pty-prebuilt | Patch sang node-pty (xem Phan 1, muc 3) |
| npm install that bai | Thieu build-essential | `sudo apt install build-essential && npm config set python python3` |
| WebSocket khong ket noi | Nginx thieu Upgrade header | Them `proxy_set_header Upgrade $http_upgrade` |
| IDE trang / khong load | AMD define/require loi | Dung `--packed` mode hoac xoa cache build |
| EADDRINUSE | Port conflict | `sudo lsof -i :8181` va kill process |
| Permission denied | Workspace sai quyen | `sudo chown -R cloud9:cloud9 /home/cloud9/workspace` |
| Nginx 502 Bad Gateway | Cloud9 service khong chay | `sudo systemctl status cloud9 && curl http://127.0.0.1:8181` |
| Let's Encrypt rate limit | 50 certs/tuan/domain | Dung `--staging` de test |

## Cac CLI options day du

| Option | Alias | Mo ta | Default |
|---|---|---|---|
| `-p` / `--port` | | Cong HTTP | `$PORT` hoac 8181 |
| `-l` / `--listen` | | IP listen | `$IP` hoac 127.0.0.1 |
| `-a` / `--auth` | | Basic Auth | Khong auth |
| `-w` | | Workspace directory | Thu muc hien tai |
| `--packed` | | Ban packed | false |
| `--collab` | | Collaboration | false |
| `--readonly` | `-ro` | Che do chi doc | false |
| `--debug` | `-d` | Debug mode | false |
| `--secure` | | SSL certificate path | none |
| `-t` | | Test mode | false |
| `-b` | | Bridge server | false |
| `--settings` | `-s` | Settings file | Auto-detect |
| `--help` | | Help | |
| `--dump` | | Dump config JSON | |

## Cac IDE features

Sau khi dang nhap, Cloud9 IDE cung cap:
- **Editor**: Ace editor - syntax highlighting, code completion, multiple cursors, split panes
- **File Tree**: Duyet files, drag-drop, context menu
- **Terminal**: Bash shell qua tmux (can node-pty)
- **Run**: Chay code truc tiep (Node.js, Python, PHP, Ruby...)
- **Debug**: Debug JavaScript (V8), PHP (XDebug), Python (ikpdb)
- **Git**: Source control (commit, push, pull, diff)
- **Search**: Tim kiem trong file/project
- **Preview**: Xem truoc HTML, Markdown
- **Plugin Manager**: Quan ly plugins cai dat them

## Tham khao

| Tai nguyen | URL |
|---|---|
| c9/core (GitHub) | https://github.com/c9/core |
| Cloud9 SDK Docs | http://cloud9-sdk.readme.io |
| API Docs | http://docs.c9.io/api |
| User Docs | http://docs.c9.io |
| Bai viet huong dan | https://thangletoan.wordpress.com/2020/02/11/cai-dat-cloud9-web-c9-cong-cu-lap-trinh-ide-nen-web/ |
| nvm | https://github.com/nvm-sh/nvm |
| Node.js | https://nodejs.org |
| Nginx | https://nginx.org |
| Let's Encrypt | https://letsencrypt.org |
| tmux | https://github.com/tmux/tmux |
| node-pty | https://github.com/microsoft/node-pty |

---

## License

Tai lieu nay duoc phat hanh theo giay phep MIT.
Cloud9 Core SDK goc thuoc so huu cua Ajax.org B.V., phat hanh theo giay phep ma nguon mo (xem LICENSE trong repository goc).
