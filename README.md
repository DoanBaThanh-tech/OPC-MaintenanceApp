

 





🇻🇳 Tiếng Việt

🔧 OPC Maintenance App - Quản lý hồ sơ bảo trì & sửa chữa thiết bị cơ điện

Ứng dụng di động phục vụ công tác bảo trì và sửa chữa thiết bị cơ điện tại Công ty Cổ phần Dược phẩm OPC. App được xây dựng trong kỳ thực tập tốt nghiệp, nhằm số hóa quy trình đang làm thủ công: lập kế hoạch, tạo hồ sơ, phân công nhân viên, duyệt của giám đốc, ghi nhận vật tư và theo dõi tiến độ trên một nền tảng thống nhất.

Giao diện dùng màu xanh dương làm chủ đạo, tối ưu cho điện thoại và máy tính bảng, phù hợp môi trường nhà máy / xưởng.

🌟 Tính năng chính

👷 Tổ trưởng cơ điện





Kế hoạch bảo trì theo năm / tháng: Lập và theo dõi thiết bị cần bảo trì theo từng tháng trên lịch 12 tháng.



Tạo hồ sơ bảo trì: Hỗ trợ tạo nhanh hoặc tạo thủ công, chọn quy trình thực hiện ngay lúc lập hồ sơ.



Phân công nhân viên: Sau khi giám đốc duyệt, tổ trưởng phân công một hoặc nhiều nhân viên kỹ thuật; có thể cập nhật lại nếu người được giao đang bận.



Theo dõi hồ sơ: Xem trạng thái hồ sơ, nhân viên được phân công / đã bảo trì, lịch sử liên quan.

🏭 Xưởng





Chốt ngày bảo trì: Nhận hồ sơ từ tổ trưởng, chốt ngày trong tháng rồi gửi giám đốc duyệt.



Tạo hồ sơ sửa chữa: Khi thiết bị hỏng bất thường, xưởng tạo hồ sơ sửa chữa theo ngày hiện tại.



Xác nhận quy trình: Nhận kết quả làm việc từ nhân viên kỹ thuật, xác nhận hoặc trả về để cập nhật lại bước / vật tư.

👔 Giám đốc





Duyệt hồ sơ: Duyệt hoặc từ chối hồ sơ bảo trì, sửa chữa và hồ sơ vật tư; xem đầy đủ quy trình thực hiện (kể cả bước không chọn) và vật tư từng bước khi đã hoàn thành.



Thống kê tổng quan: Biểu đồ và chi tiết theo tháng về số thiết bị bảo trì / sửa chữa đã hoàn thành; số lượng và chi phí vật tư chỉ tính khi hồ sơ vật tư đã được giám đốc xác nhận.



Bộ lọc năm: Chỉ hiện năm có dữ liệu thực tế (từ 2026 trở đi), không hiện năm “ảo” trước khi có kế hoạch hoặc hồ sơ.

🛠️ Nhân viên kỹ thuật





Yêu cầu công việc: Nhận việc được phân công; thông báo ngoài app khi có việc mới (tránh spam khi đã xác nhận / đã biết).



Quy trình theo bước: Tích chọn bước cần làm, chỉnh mô tả, thêm vật tư từng bước; bắt buộc có vật tư trước khi hoàn thành quy trình nếu bước đã được chọn.



Gửi xưởng: Hoàn thành quy trình gửi xưởng; nếu bị từ chối có thể cập nhật lại rồi gửi lại.

🔐 Tài khoản & bảo mật





Đăng nhập bằng email công ty (@opc.com).



Quên mật khẩu qua OTP Gmail cá nhân (chỉ sau khi user đã cập nhật Gmail trong Thông tin cá nhân).



Mỗi email cá nhân chỉ gắn một tài khoản.



Admin quản lý người dùng, phân vai trò, xem nhật ký hệ thống.

🛠️ Công nghệ & kiến trúc

1. Ngôn ngữ & framework





Mobile: Dart / Flutter (Android)



API: C# / ASP.NET Core Web API



Database: Microsoft SQL Server

2. Backend & bảo mật





REST API, JWT đăng nhập



Mật khẩu hash BCrypt



OTP quên mật khẩu gửi qua Gmail SMTP



Phân quyền theo vai trò (Tổ trưởng, Xưởng, Giám đốc, NVKT, Admin)

3. Một số gói Flutter chính





http / client gọi API



flutter_secure_storage lưu phiên đăng nhập



flutter_local_notifications thông báo việc mới



Giao diện material tùy biến theo theme xanh

4. Tổ chức code

Tách rõ ba lớp trên cả API và Flutter:





Logic – ràng buộc nghiệp vụ



Presentation / UI – màn hình, widget



Service – gọi API / truy vấn

📸 Screenshots


<img width="404" height="718" alt="image" src="https://github.com/user-attachments/assets/fac9324c-550d-4c90-8a82-c02f76b54d37" /><img width="383" height="718" alt="image" src="https://github.com/user-attachments/assets/8f14aac8-c12c-46d6-9b4d-2be0e586656b" />
<img width="403" height="718" alt="image" src="https://github.com/user-attachments/assets/6fb3b7a4-dc29-44c0-9579-21d8b3fe7357" /><img width="403" height="718" alt="image" src="https://github.com/user-attachments/assets/21db9927-d6fd-4367-bcce-e50a41c07144" />
<img width="791" height="718" alt="image" src="https://github.com/user-attachments/assets/c56f0b1a-9010-4a88-af7c-c80a46890b37" /><img width="812" height="718" alt="image" src="https://github.com/user-attachments/assets/c532ae60-60d3-4c6d-b948-379e69c57293" />
<img width="968" height="564" alt="image" src="https://github.com/user-attachments/assets/a4af1fde-1ec5-4792-a9ba-3e42260460b2" /><img width="827" height="718" alt="image" src="https://github.com/user-attachments/assets/5ee7a011-92d9-4196-a554-1fcd26918e05" />
<img width="802" height="718" alt="image" src="https://github.com/user-attachments/assets/b74eed8e-edec-4703-97d9-72a272b0fa94" />
<img width="809" height="718" alt="image" src="https://github.com/user-attachments/assets/44fcd7b3-8ed7-4936-8a01-b49c04010a7f" />
<img width="802" height="718" alt="image" src="https://github.com/user-attachments/assets/8f0de4b6-af36-4d5a-bef5-83e6fdc08e2e" />

<img width="802" height="718" alt="image" src="https://github.com/user-attachments/assets/8fcc5ffd-e33c-4ad9-8287-980373b80b2d" />








🚀 Bắt đầu nhanh

Yêu cầu





Flutter SDK (stable)



.NET SDK



SQL Server (Express trở lên)



Android Studio / thiết bị Android

1. Database

# Chạy script tạo bảng trên SQL Server
# TaoBang.sql  (hoặc TaoBang_ERD_DayDu.sql)
# Có thể thêm Insertdulieumau.sql nếu cần dữ liệu mẫu

2. API

cd OPC.MaintenanceAPI
# Sửa ConnectionStrings trong appsettings.json
dotnet restore
dotnet run

3. App Flutter

cd opc_maintenance_mobile
flutter pub get
# Trỏ baseUrl API về máy local hoặc URL ngrok
flutter run
# Build phát hành
flutter build apk --release

APK: build/app/outputs/flutter-apk/app-release.apk

📁 Cấu trúc gợi ý

OPC-MaintenanceApp/
├── opc_maintenance_mobile/     # Flutter app
├── OPC.MaintenanceAPI/         # ASP.NET Core API
├── TaoBang.sql
├── Insertdulieumau.sql
└── README.md

👤 Tác giả

Đoàn Bá Thành
Thực tập tại Công ty Cổ phần Dược phẩm OPC
Giảng viên hướng dẫn: ThS. Thái Thị Thanh Thảo

Mọi góp ý có thể tạo Issue trên repository này.





🇬🇧 English

🔧 OPC Maintenance App - Equipment Maintenance & Repair Work Orders

A mobile application for electrical equipment maintenance and repair at OPC Pharmaceutical Joint Stock Company. Built during a graduation internship to digitize a paper-heavy process: yearly plans, work orders, staff assignment, director approval, material usage, and progress tracking in one place.

The UI uses a blue primary palette and is designed for both phones and tablets on the shop floor.

🌟 Key features

👷 Maintenance team leader





Yearly / monthly plan: Schedule which assets need maintenance in each month.



Create maintenance orders: Quick or manual creation, with process steps selected at creation time.



Assign technicians: After director approval, assign one or more technicians; reassign when someone is busy.



Order tracking: Status, assigned / completed staff, related history.

🏭 Workshop





Confirm maintenance dates: Receive orders from the team leader, lock the date, send to the director.



Create repair orders: For unexpected breakdowns on the current day.



Confirm process work: Accept technician results or send them back for updates.

👔 Director





Approvals: Approve or reject maintenance, repair, and material requests; full process view (including unselected steps) and per-step materials when completed.



Statistics: Monthly charts for completed maintenance / repair jobs; material quantity and cost only after the director confirms the material request.



Year filter: Only years with real data (from 2026 onward).

🛠️ Technician





Job inbox: Assigned work with optional device notifications (no spam after the job is already known).



Step workflow: Select steps, edit descriptions, add materials; materials required on selected steps before completing the process.



Submit to workshop: Complete and send; update and resubmit if rejected.

🔐 Accounts & security





Sign-in with company email (@opc.com).



Password recovery via personal Gmail OTP (only after the user saves Gmail in Profile).



One personal email per account.



Admin user management and system activity log.

🛠️ Tech stack & architecture

1. Languages & frameworks





Mobile: Dart / Flutter (Android)



API: C# / ASP.NET Core Web API



Database: Microsoft SQL Server

2. Backend & security





REST API with JWT



BCrypt password hashing



OTP recovery over Gmail SMTP



Role-based access (Team leader, Workshop, Director, Technician, Admin)

3. Notable Flutter packages





HTTP API client



flutter_secure_storage for session



flutter_local_notifications for job alerts



Custom Material UI with blue theme

4. Code organization

Clear split on both API and Flutter sides:





Logic – business rules



Presentation / UI – screens and widgets



Service – API / data access

📸 Screenshots



Replace the placeholders below with real image URLs after uploading screenshots to GitHub.





🚀 Getting started

Requirements





Flutter SDK (stable)



.NET SDK



SQL Server (Express or higher)



Android Studio / Android device

1. Database

# Run the schema script on SQL Server
# TaoBang.sql  (or TaoBang_ERD_DayDu.sql)
# Optional sample data: Insertdulieumau.sql

2. API

cd OPC.MaintenanceAPI
# Set ConnectionStrings in appsettings.json
dotnet restore
dotnet run

3. Flutter app

cd opc_maintenance_mobile
flutter pub get
# Point API baseUrl to localhost or your ngrok URL
flutter run
flutter build apk --release

APK path: build/app/outputs/flutter-apk/app-release.apk

📁 Suggested layout

OPC-MaintenanceApp/
├── opc_maintenance_mobile/     # Flutter app
├── OPC.MaintenanceAPI/         # ASP.NET Core API
├── TaoBang.sql
├── Insertdulieumau.sql
└── README.md

👤 Author

Doan Ba Thanh
Internship at OPC Pharmaceutical JSC
Supervisor: M.A. Thai Thi Thanh Thao

Feel free to open an Issue if you run into problems.





