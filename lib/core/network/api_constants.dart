class ApiConstants {
  ApiConstants._();

  static const String baseUrl = "http://192.168.70.181:5232/api";

  static const Duration connectTimeout = Duration(seconds: 15);

  // Khớp đúng route controller: [Route("api/[controller]")]
  static const String auth = "/Auth"; // hoặc "/Auth" nếu bạn tách riêng AuthController
  static const String equipment = "/Equipment";
  static const String maintenancePlan = "/MaintenancePlan";
  static const String workOrder = "/WorkOrder";
  static const String inventory = "/Inventory";
  static const String system = "/System";
  static const String chuKyBaoTri = '$maintenancePlan/chu-ky';
  static const String yeuCauNgayBaoTri = '$maintenancePlan/yeu-cau-ngay';
  static const String nhanVien = "/NhanVien";
}