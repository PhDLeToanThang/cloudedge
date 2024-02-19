# Bản cài đặt và cấu hình đầy đủ Cloud Edge vs IoT bằng phiên bản Guacamole 1.5.4

wget https://raw.githubusercontent.com/PhDLeToanThang/guacamole/main/advanced/1-setup.sh && chmod +x 1-setup.sh && ./1-setup.sh

GITHUB="https://raw.githubusercontent.com/PhDLeToanThang/guacamole/main"

---
Áp dụng trên Ubuntu 22.04 LTS Server: Cấu hình tối thiểu: 4GRAM, 2 vCPU core, 30GB SSD/NVME

**Tính năng chính:**

(1). **SSO** bằng **AD LDAP User/ MS Entra ID** _(tên gọi cũ Azure AD)_.
(2). **MFA** xác thực bằng chuẩn tOTP thông qua _SmartPhone Microsoft Authenticator App / Google Authenticator App_.
(3). Làm việc tại nhà **(WFH)**: Chúng tôi cảm thấy điều này khiến chúng tôi khác biệt với các giải pháp máy tính từ xa khác và mang lại cho chúng tôi một lợi thế khác biệt, an toàn, tiết kiệm, bảo mật đồng nhất, người dùng tiện lợi và người quản trị có đầy đủ công cụ kiểm soát hệ thống.
(4). **Truy cập máy tính của bạn từ mọi nơi**: Vì ứng dụng Guacamole client là một ứng dụng web chuẩn HTML5, việc sử dụng máy tính của bạn không bị ràng buộc với bất kỳ thiết bị hoặc vị trí nào. Miễn là bạn có quyền truy cập vào trình duyệt web, bạn có quyền truy cập vào máy của mình trên Private Cloud.
(5). **Giữ máy tính để bàn hoặc Ứng dụng của bạn trên đám mây**: Máy tính để bàn/ ứng dụng được truy cập thông qua Guacamole không cần phải tồn tại trong môi trường vật lý. Với cả Guacamole và hệ điều hành máy tính để bàn hoặc ứng dụng của bạn được lưu trữ trên đám mây cá nhân, bạn có thể kết hợp sự tiện lợi của Guacamole qua trình duyệt web với khả năng phục hồi và tính linh hoạt từ đám mây cá nhân ở Tổ chức của bạn.
