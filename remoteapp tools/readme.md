# Hướng dẫn sử dụng RemoteApps và tích hợp Cloud Edge

## Phần 1. Tạo và quản lý RemoteApps trên Win XP, 7, 8, 10,11 và Server: 
https://github.com/kimmknight/remoteapptool 

1.	Với công nghệ Microsoft RemoteApp, bạn có thể sử dụng liền mạch một ứng dụng đang chạy trên một máy tính khác.
1.	RemoteApp Tool là tiện ích cho phép bạn tạo/quản lý RemoteApps được lưu trữ trên Windows (7, 8, 10, XP và Server) cũng như tạo các tệp RDP và MSI cho máy khách.
1.	Nếu bạn muốn RemoteApps của mình xuất hiện trong Menu Bắt đầu của máy trạm hoặc thông qua giao diện web

### Tải xuống bản mới nhất:

-	RemoteApp Tool 6.1.0.0 Installer: https://github.com/kimmknight/remoteapptool/releases/download/v6.1.0.0/RemoteApp.Tool.6100.msi 
-	RemoteApp Tool 6.1.0.0 Zip: https://github.com/kimmknight/remoteapptool/releases/download/v6.1.0.0/RemoteApp.Tool.6100.zip 

**Lưu ý:** Trình cài đặt mới nhất không còn hoạt động trên Windows XP nữa, thay vào đó hãy sử dụng Zip.

### Đặc trưng:
•	Tạo và quản lý RemoteApps trên máy tính để bàn và máy chủ Windows
•	Tạo tập tin RDP
•	Tạo trình cài đặt MSI (yêu cầu Bộ công cụ WiX)
•	Sử dụng Cổng máy tính từ xa
•	Đặt các tùy chọn như thời gian chờ của phiên
•	Chọn biểu tượng cho ứng dụng của bạn
•	Liên kết loại tệp cho các ứng dụng được triển khai
•	Ký các tập tin RDP
•	Sao lưu ứng dụng từ xa

### Yêu cầu:
•	Microsoft .Net Framework 4
•	WiX Toolset (Nếu bạn muốn tạo MSI. Khởi động lại sau khi cài đặt)
•	Phiên bản được hỗ trợ của Windows XP, 7, 8, 10,11 hoặc Server. Xem biểu đồ tương thích.

**Lưu ý:** Nếu bạn cố gắng lưu trữ RemoteApps trên bất kỳ phiên bản Windows nào khác 
_ví dụ: Win 7/8/10/11 Professional hoặc Home, công cụ sẽ chạy nhưng RemoteApps sẽ không hoạt động. Máy khách RDP sẽ có vẻ như đang kết nối, sau đó biến mất mà không hiển thị lỗi._

### Hướng dẫn sử dụng:
•	Tạo RemoteApp và sử dụng nó trên một máy tính khác|

**Bước 1. Enable Remote Desktop (HOST)**
- Remote Desktop có thể được bật từ tab Remote trong cửa sổ Thuộc tính hệ thống.
Bạn có thể truy cập Thuộc tính hệ thống theo nhiều cách khác nhau, tùy thuộc vào hệ điều hành của bạn.

**Windows XP:**
Menu Bắt đầu > Nhấp chuột phải vào Máy tính của tôi > Nhấp vào Thuộc tính > Nhấp vào tab Điều khiển từ xa.

**Windows 7:**
Menu Bắt đầu > Nhấp chuột phải vào Máy tính > Nhấp vào Thuộc tính > Nhấp vào Cài đặt từ xa

**Windows 8.1,10, 11:**
Nhấp chuột phải vào Menu Bắt đầu > Nhấp vào Hệ thống > Nhấp vào Cài đặt từ xa
Khi đó, hãy chọn Cho phép kết nối từ xa với máy tính này

![image](https://github.com/user-attachments/assets/590a9780-ffac-47b6-ba21-4d389115c04e)

**Bước 2. Mở phần mềm RemoteApp Tool 6.x**
-	Thêm các Apps vào danh sách

![image](https://github.com/user-attachments/assets/a73ff576-5749-459a-88cb-24ee20e6879b)

![image](https://github.com/user-attachments/assets/9e2f2fa8-c6cd-4b76-97f4-6d6efa942a29)

- Tạo kết nối RDP file:

![image](https://github.com/user-attachments/assets/bb904507-b449-4aa1-b0d5-888b22e7c8a1)

![image](https://github.com/user-attachments/assets/4778c60b-937d-44ad-a8e7-8c4e826b511e)

-	Thêm cấu hình lựa chọn tham số cho RDP:

![image](https://github.com/user-attachments/assets/68094929-8292-456d-86b0-b80fa4f93006)

## Phần 2. Cấu hình RAWeb cho một môi trường multi-user:

- Bài viết: https://github.com/kimmknight/raweb .
- Download bản mới nhất: https://github.com/kimmknight/raweb/archive/master.zip .

**RAWeb** cho phép những người dùng khác nhau xem các ứng dụng khác nhau bằng cách định cấu hình IIS và đặt một số quyền.

Bạn kiểm soát quyền truy cập vào các ứng dụng từ xa của mình bằng cách đặt quyền đối với tệp trên tệp RDP. Bạn có thể cấp quyền truy cập cho Active Directory hoặc người dùng hoặc nhóm cục bộ.

Tính năng này hoạt động với cả RAWeb dựa trên web và cả nguồn cấp dữ liệu web.

Hướng dẫn này sẽ chỉ cho bạn cách thiết lập cấu hình cơ bản để cung cấp cho một người dùng cục bộ quyền truy cập vào một số ứng dụng làm ví dụ.

**Thiết lập:**

- Cài đặt Web theo hướng dẫn trên trang Web chính. Bạn cũng sẽ cần thêm **Xác thực Windows** vào **IIS** bằng cách thêm **Tính năng Windows**:

![image](https://github.com/user-attachments/assets/13c89bef-f325-4e09-9bd4-42d7ff28ce62)

- Trong Trình quản lý IIS, hãy mở tính năng Xác thực cho trang web của bạn.

![image](https://github.com/user-attachments/assets/a3664109-fa44-4032-a23f-5b80ff39fcc7)

- Tắt Xác thực ẩn danh và bật Xác thực Windows. Các phương pháp khác có thể hoạt động nhưng chưa được kiểm tra.

![image](https://github.com/user-attachments/assets/a3c3254b-63b2-4027-bbcf-9e79d3332386)

**Quyền:**
Từ đây bạn cần thiết lập quyền. Điều này sẽ hoạt động với người dùng/nhóm cục bộ hoặc người dùng/nhóm Active Directory.

**Tóm lại:**
-	Người dùng (hoặc nhóm) RAWeb chỉ nên có quyền nội dung thư mục Danh sách trên thư mục rdp (tắt tính kế thừa).
-	Bất kỳ người dùng hoặc nhóm nào yêu cầu quyền truy cập vào ứng dụng từ xa đều phải có quyền Đọc đối với tệp RDP cho ứng dụng.

_Ví dụ:_
Trong ví dụ dưới đây, chúng tôi sẽ cấp cho một người dùng cục bộ quyền truy cập vào một số (nhưng không phải tất cả) ứng dụng có sẵn.

Chuyển đến tab Bảo mật **‘Security’** trong Thuộc tính của thư mục **rdp** và nhấp vào **Nâng cao**, sau đó nhấp vào **Thay đổi quyền**.

![image](https://github.com/user-attachments/assets/34299564-3001-4313-96da-e928b8e3e23f)

Tùy thuộc vào hệ điều hành của bạn, hãy nhấp vào Tắt tính kế thừa hoặc bỏ chọn Bao gồm các quyền có thể inheritable từ cấp độ gốc của đối tượng này.

![image](https://github.com/user-attachments/assets/6f6bc328-a50c-41f5-89c5-1ec4af5c6cd7)

Một lần nữa tùy thuộc vào hệ điều hành của bạn, hãy nhấp vào Chuyển đổi quyền kế thừa thành quyền rõ ràng trên đối tượng này hoặc Thêm.

![image](https://github.com/user-attachments/assets/4744c9e8-8dae-492f-b2e9-b0aab7899101)

![image](https://github.com/user-attachments/assets/7758394b-dfa2-4ef0-b920-1121bc79a43f)

Bấm **OK** và quay lại cửa sổ **Thuộc tính chính**. Chỉnh sửa quyền: Nhấp vào nhóm **Người dùng và đảm bảo rằng chỉ cho phép quyền nội dung thư mục Danh sách** (bỏ chọn các quyền khác).

![image](https://github.com/user-attachments/assets/67e7e4b6-bdf1-4ec6-a495-70c162acb178)

Bấm vào **OK**. Bây giờ hãy điền vào thư mục **rdp** của bạn một số tệp **RDP**.

![image](https://github.com/user-attachments/assets/7cec6a07-659e-4069-9fe6-c0bc54225c47)

Bây giờ để gán ứng dụng cho người dùng, hãy cấp cho người dùng quyền Đọc đối với các tệp RDP thích hợp.

Trong ví dụ này, có một người dùng cục bộ có tên TestUser sẽ được cấp quyền truy cập vào Calculator.rdp và Chrome.rdp chứ không phải TestApp.rdp.

Chỉ cần thêm quyền Đọc cho TestUser trên Calculator.rdp và Chrome.rdp.

![image](https://github.com/user-attachments/assets/46bb0ae7-6cfa-4e2a-ac7a-5cd66588f913)

Khi **TestUser** đăng nhập vào **RAWeb**, họ sẽ được nhắc **nhập thông tin xác thực** (hoặc thông tin xác thực của người dùng đã đăng nhập có thể được chuyển qua nếu một phần của miền). **TestUser** sẽ chỉ nhìn thấy các ứng dụng được chỉ định cho họ:

![image](https://github.com/user-attachments/assets/f1d7f3e0-d66b-4226-a25b-9dd352497fc4)

Trong trường hợp này, TestApp không được hiển thị (như mong muốn).

Điều này áp dụng cho RAWeb dựa trên web và cả tính năng nguồn cấp dữ liệu web.

## Phần 3. Tạo RemoteApp và sử dụng nó trên một máy vi tính khác:

Hướng dẫn này chỉ cho bạn cách sử dụng RemoteApp Tool 5x/ 6x để tạo RemoteApp trên máy tính HOST, sau đó sử dụng ứng dụng từ xa từ máy tính CLIENT.
Trong kịch bản này, chúng tôi tạo RemoteApp cho phần mềm GIMP 2 được cài đặt trên máy tính HOST. Máy tính CLIENT sẽ chạy GIMP 2 từ xa. Cả hai máy tính đều nằm trên cùng một mạng cục bộ.

**1. Enable Remote Desktop (HOST):**
- Remote Desktop có thể được bật từ tab Remote trong cửa sổ Thuộc tính hệ thống.
Bạn có thể truy cập Thuộc tính hệ thống theo nhiều cách khác nhau, tùy thuộc vào hệ điều hành của bạn.

**Windows XP:**
Menu Bắt đầu > Nhấp chuột phải vào Máy tính của tôi > Nhấp vào Thuộc tính > Nhấp vào tab Điều khiển từ xa.

**Windows 7:**
Menu Bắt đầu > Nhấp chuột phải vào Máy tính > Nhấp vào Thuộc tính > Nhấp vào Cài đặt từ xa

**Windows 8.1,10, 11:**
Nhấp chuột phải vào Menu Bắt đầu > Nhấp vào Hệ thống > Nhấp vào Cài đặt từ xa
Khi đó, hãy chọn Cho phép kết nối từ xa với máy tính này

![image](https://github.com/user-attachments/assets/e8aa7c80-a740-4c25-be80-1958d18ba3da)

**2. Mở RemoteApp Tool và tạo RemoteApp (HOST)**
Nhấp vào nút + (dấu cộng) để tạo RemoteApp mới.

![image](https://github.com/user-attachments/assets/a7db0cda-6ccb-4214-99ee-9bd0e3ec0d56)

**3. Chọn chương trình (HOST)**
Xác định vị trí tệp EXE hoặc tệp lối tắt cho ứng dụng của bạn.

![image](https://github.com/user-attachments/assets/9accfa84-b9d5-4b71-be0e-0b379504caac)

**4. Tạo file kết nối máy khách (HOST)**
1. Nhấp vào RemoteApp
1. Nhấp vào Tạo kết nối máy khách.

![image](https://github.com/user-attachments/assets/5cff8a7b-22f3-411c-a1b6-f22d83db14fa)

**5. Xác nhận chi tiết và nhấp vào Tạo... (HOST)**

Bạn có thể thay đổi địa chỉ Máy chủ thành địa chỉ IP của máy tính chủ nếu sau này bạn gặp sự cố kết nối trên máy khách.

![image](https://github.com/user-attachments/assets/0680e2be-c979-4013-8ca1-9aa1f779e350)

**6. Lưu tệp RDP (HOST) của bạn**

![image](https://github.com/user-attachments/assets/e872e934-ddfa-4230-b7dc-879264462b18)

**7. Sao chép tệp RDP của bạn từ máy tính HOST sang máy tính CLIENT:**

![image](https://github.com/user-attachments/assets/1830a422-4c5c-402d-b2fc-7c8e40c421c3)

**8. Mở tệp RDP (MÁY TRẠM)**

![image](https://github.com/user-attachments/assets/ad5fcdb0-0737-40ef-a716-1a83059b63d6)

**9. Xác nhận mọi lời nhắc bảo mật (MÁY TRẠM):**

![image](https://github.com/user-attachments/assets/4e830f7c-dfde-423d-b4a8-da27fdd01390)

**10. Nhập tên người dùng và mật khẩu để kết nối với máy tính HOST (MÁY TRẠM)**

![image](https://github.com/user-attachments/assets/8eeb054b-0946-4cf4-a6e9-cfce35bd79f7)

**11. RemoteApp của bạn sẽ mở:**

![image](https://github.com/user-attachments/assets/eaaebca2-e560-4067-b454-7b3ed7b0ac60)

## Phần 4. Tạo RemoteApp với Cloud Edge:

Tham khảo: https://guacamole.incubator.apache.org/doc/0.9.0/gug/configuring-guacamole.html 

> **remote-app:**
>  Specifies the RemoteApp to start on the remote desktop. If supported by your remote desktop server, this application, and only this application, will be visible to the user.
>  Windows requires a special notation for the names of remote applications. The names of remote applications must be prefixed with two vertical bars. For example, if you have created a remote application on your server for notepad.exe and have assigned it the name "notepad", you would set this parameter to: "||notepad".

_ví dụ: Đặt tên cho Apps:

![image](https://github.com/user-attachments/assets/50aecfb3-7f9e-497b-b85e-f5528aad2a2c)

Tham khảo: https://guacamole.apache.org/doc/gug/configuring-guacamole.html 

**Cấu hình Ứng dụng từ xa RemoteApp:**
-	Các phiên bản Windows gần đây cung cấp một tính năng gọi là RemoteApp cho phép sử dụng các ứng dụng riêng lẻ qua RDP mà không cung cấp quyền truy cập vào môi trường máy tính để bàn đầy đủ. Nếu máy chủ RDP của bạn đã bật và định cấu hình tính năng này, bạn có thể định cấu hình các kết nối Guacamole để sử dụng các ứng dụng riêng lẻ đó.
Không thể gọi đồng thời nhiều phần mềm RemoteApps như: ||WinSCP||RvTool|Word||Excel||Unikey 
Mà phải viết file Batch .bat gọi:
```q
“viết đoạn code file .bat để tôi load launch 3 file chạy cùng lúc trong remoteapps như: LOCalc , LOMath, WinSCP và có kiểm tra tình trạng đang chạy thì sẽ không load hoặc bỏ qua lệnh chạy”
```
```ai
Một đoạn mã file .bat để tải và chạy ba ứng dụng cùng một lúc (LOCalc, LOMath, WinSCP) thông qua RemoteApps. Đồng thời, bạn muốn kiểm tra xem các ứng dụng đã được chạy hay chưa, và tránh tải lại nếu chúng đang chạy. Dưới đây là một ví dụ về cách bạn có thể thực hiện điều này:
Ví du source code file .bat:
```
```bat
@echo off
setlocal
REM Kiểm tra xem LOCalc đã được chạy hay chưa
tasklist /FI "IMAGENAME eq scalc.exe" 2>NUL | find /I /N "scalc.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo LOCalc đã được chạy.
) else (
    echo Đang tải LOCalc...
    start "" "C:\Program Files\LibreOffice\program\scalc.exe"
)
REM Kiểm tra xem LOMath đã được chạy hay chưa
tasklist /FI "IMAGENAME eq smath.exe" 2>NUL | find /I /N "smath.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo LOMath đã được chạy.
) else (
    echo Đang tải LOMath...
    start "" "C:\Program Files\LibreOffice\program\smath.exe"
)
REM Kiểm tra xem WinSCP đã được chạy hay chưa
tasklist /FI "IMAGENAME eq WinSCP.exe" 2>NUL | find /I /N "WinSCP.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo WinSCP đã được chạy.
) else (
    echo Đang tải WinSCP...
    start "" "C:\Program Files (x86)\WinSCP\WinSCP.exe"
)
REM Kiểm tra xem RVTools đã được chạy hay chưa
tasklist /FI "IMAGENAME eq RVTools.exe" 2>NUL | find /I /N "RVTools.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo RVTools đã được chạy.
) else (
    echo Đang tải RVTools...
    start "" "C:\Program Files (x86)\Dell\RVTools\RVTools.exe"
)
REM Kiểm tra xem Opera đã được chạy hay chưa
tasklist /FI "IMAGENAME eq launcher.exe" 2>NUL | find /I /N "launcher.exe" >NUL
if "%ERRORLEVEL%"=="0" (
    echo Opera đã được chạy.
) else (
    echo Đang tải Opera...
    start "" "C:\Program Files\Opera\launcher.exe"
)
endlocal
```

![image](https://github.com/user-attachments/assets/3abbcb99-ba4c-49d5-8cca-cb2766a99f11)

- Dùng REmoteApp Tool 6x thêm Phần mềm Remote

![image](https://github.com/user-attachments/assets/e7c39229-5dab-4902-8f92-0cb0a8a0af61)

![image](https://github.com/user-attachments/assets/5e9548be-182e-43e9-9bfe-abb96831c5a0)

![image](https://github.com/user-attachments/assets/2f1033f3-80c8-4fc1-ac0c-30808abb7256)

- Nếu muốn lưu ra file .rdp:

![image](https://github.com/user-attachments/assets/5722afa7-046c-4179-8801-c8fdb45ac997)

![image](https://github.com/user-attachments/assets/68516e03-bdae-47d2-a65c-f5c36fbfe62e)

![image](https://github.com/user-attachments/assets/f1515329-3d02-4f29-b9ff-da60dd8a7c97)

![image](https://github.com/user-attachments/assets/309fd736-acfc-4fa4-9b20-7ee3ec0d13fb)

- Nếu đúp click để kiểm tra file .rdp

![image](https://github.com/user-attachments/assets/b0a3f721-2173-43ad-9a95-f2b34624d7ea)

- Cấu hình trong RemoteApp của Guacamole:

![image](https://github.com/user-attachments/assets/2dd67470-5702-4703-95c5-f0a01d274614)

- Và kết quả có nhiều phần mềm cùng chạy:

![image](https://github.com/user-attachments/assets/5a67ea4d-6b29-46a8-9d0b-7d945c8ac137)
