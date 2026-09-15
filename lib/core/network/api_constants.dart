class ApiConstants {
  ApiConstants._();

  // Đổi IP theo máy chạy API của bạn
  static const String baseUrl = "https://crispness-retrain-aversion.ngrok-free.dev/api";

  static const Duration connectTimeout = Duration(seconds: 15);

  // Khớp route controller ASP.NET: [Route("api/[controller]")] hoặc [Route("api/system")]
  static const String auth = "/Auth";
  static const String equipment = "/Equipment";

  static const String maintenancePlan = "/MaintenancePlan";
  static const String namMoi = '$maintenancePlan/nam-moi';
  static const String themThietBiVaoNam = '$maintenancePlan/them-thiet-bi';
  static const String chuKyBaoTri = '$maintenancePlan/chu-ky';
  static const String yeuCauNgayBaoTri = '$maintenancePlan/yeu-cau-ngay';
  
  static const String workOrder = "/WorkOrder";
  static const String inventory = "/Inventory";
  static const String system = "/system";



  /// Danh sách nhân viên cho phân công.
  /// Backend: GET /api/WorkOrder/nhan-vien?vaiTro=...
  /// (đặt ở WorkOrder để Tổ trưởng không bị 403 từ SystemController)
  static const String nhanVien = "$workOrder/nhan-vien";
}