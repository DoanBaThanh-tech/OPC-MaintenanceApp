class ApiConstants {
  ApiConstants._();

  // Đổi IP theo máy chạy API của bạn
  static const String baseUrl = "https://crispness-retrain-aversion.ngrok-free.dev/api";

  static const Duration connectTimeout = Duration(seconds: 15);

  // Khớp route controller ASP.NET: [Route("api/[controller]")] hoặc [Route("api/system")]
  static const String auth = "/Auth";

  // ---------- Equipment (Thiết bị) ----------
  /// GET /api/Equipment — danh sách (query: maChuKy, trangThai)
  static const String equipment = "/Equipment";

  /// GET /api/Equipment/{maThietBi} — chi tiết 1 thiết bị
  static String equipmentDetail(int maThietBi) => '$equipment/$maThietBi';

  /// GET /api/Equipment/theo-danh-muc — nhóm theo danh mục (Loại / Chu kỳ)
  static const String equipmentTheoDanhMuc = '$equipment/theo-danh-muc';

  /// GET /api/Equipment/thong-ke — tổng quan số lượng theo trạng thái
  static const String equipmentThongKe = '$equipment/thong-ke';

  /// GET /api/Equipment/{id}/lich-su
  static String equipmentLichSu(int maThietBi) => '$equipment/$maThietBi/lich-su';

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