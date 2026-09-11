class ApiConstants {
  ApiConstants._();

  // Đổi IP theo máy chạy API của bạn
  static const String baseUrl = "http://192.168.0.138:5232/api";

  static const Duration connectTimeout = Duration(seconds: 15);

  // Khớp route controller ASP.NET: [Route("api/[controller]")] hoặc [Route("api/system")]
  static const String auth = "/Auth";
  static const String equipment = "/Equipment";
  static const String maintenancePlan = "/MaintenancePlan";
  static const String workOrder = "/WorkOrder";
  static const String inventory = "/Inventory";
  static const String system = "/system";

  static const String chuKyBaoTri = '$maintenancePlan/chu-ky';
  static const String yeuCauNgayBaoTri = '$maintenancePlan/yeu-cau-ngay';

  /// Danh sách nhân viên cho phân công.
  /// Backend: GET /api/WorkOrder/nhan-vien?vaiTro=...
  /// (đặt ở WorkOrder để Tổ trưởng không bị 403 từ SystemController)
  static const String nhanVien = "$workOrder/nhan-vien";
}