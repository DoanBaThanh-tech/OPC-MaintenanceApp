import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../equipment/data/equipment_logic.dart';
import 'services/work_order_service.dart';
import 'work_order_validators.dart';

// Logic cho work_order_create_screen.dart

class CreateWorkOrderBaoTriController extends ChangeNotifier {
  bool dangLuu = false;
  String? loi;

  /// Ràng buộc số giờ — dùng trong Form validator.
  String? validateThoiGian(String? v) => formValidateSoGioDuKien(v);

  /// Trả về true nếu tạo thành công — presentation chỉ cần pop(context, true) khi true.
  Future<bool> luu({
    required int maChiTietKeHoach,
    required int maThietBi,
    required String noiDungCongViec,
    required String thoiGianDuKien,
    required bool guiDuyet,
  }) async {
    final kqGio = validateSoGioDuKien(thoiGianDuKien);
    if (!kqGio.hopLe) {
      loi = kqGio.loi;
      notifyListeners();
      return false;
    }
    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.taoHoSoBaoTri(
        maChiTietKeHoach: maChiTietKeHoach,
        maThietBi: maThietBi,
        noiDungCongViec: noiDungCongViec,
        thoiGianDuKien: thoiGianDuKien.trim(),
        guiDuyet: guiDuyet,
      );
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } finally {
      dangLuu = false;
      notifyListeners();
    }
  }
}

// ============================================================
// TẠO HỒ SƠ SỬA CHỮA (Xưởng) — ràng buộc nghiệp vụ nằm ở đây
// ============================================================

/// Controller form tạo hồ sơ SC.
///
/// Ràng buộc:
/// - Ngày sửa chữa = **hôm nay** (hư đột ngột, sửa liền) — không cho chọn ngày khác.
/// - Chọn **danh mục** trước → danh sách thiết bị chỉ còn TB thuộc danh mục đó
///   và đang **Sản xuất**.
class CreateHoSoSuaChuaController extends ChangeNotifier {
  List<NhomThietBiTheoDanhMuc> nhoms = [];
  String? danhMucChon;
  ThietBiModel? thietBiChon;

  /// Cố định ngày hiện tại lúc mở form.
  late final DateTime ngaySuaChua;

  bool dangTai = true;
  bool dangGui = false;
  String? loi;
  String? loiMoTa;

  CreateHoSoSuaChuaController() {
    final now = DateTime.now();
    ngaySuaChua = DateTime(now.year, now.month, now.day);
  }

  /// Thiết bị thuộc danh mục đã chọn (rỗng nếu chưa chọn danh mục).
  List<ThietBiModel> get dsThietBiTheoDanhMuc {
    if (danhMucChon == null) return const [];
    final match = nhoms.where((e) => e.tenDanhMuc == danhMucChon);
    if (match.isEmpty) return const [];
    return match.first.danhSach;
  }

  String get ngaySuaChuaHienThi {
    final d = ngaySuaChua;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Future<void> khoiTao() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      final raw = await EquipmentService.layTheoDanhMuc(trangThai: 'Sản xuất');
      // Chỉ giữ nhóm còn thiết bị đang Sản xuất
      nhoms = raw.where((n) => n.danhSach.isNotEmpty).toList();
      danhMucChon = null;
      thietBiChon = null;
    } catch (e) {
      loi = e is ApiException ? e.message : 'Không tải được thiết bị';
      nhoms = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  /// Đổi danh mục → reset thiết bị đã chọn.
  void chonDanhMuc(String? dm) {
    danhMucChon = dm;
    thietBiChon = null;
    loi = null;
    notifyListeners();
  }

  void chonThietBi(ThietBiModel? tb) {
    thietBiChon = tb;
    loi = null;
    notifyListeners();
  }

  void xoaLoiMoTa() {
    if (loiMoTa == null) return;
    loiMoTa = null;
    notifyListeners();
  }

  /// Validate + gọi API. Trả về true nếu thành công.
  Future<bool> gui({
    required String moTaHuHong,
    String? phuongAnSuaChua,
  }) async {
    if (danhMucChon == null || danhMucChon!.isEmpty) {
      loi = 'Vui lòng chọn danh mục thiết bị';
      notifyListeners();
      return false;
    }
    if (thietBiChon == null) {
      loi = 'Vui lòng chọn thiết bị hư hỏng';
      notifyListeners();
      return false;
    }
    final moTa = moTaHuHong.trim();
    if (moTa.isEmpty) {
      loiMoTa = 'Vui lòng mô tả hư hỏng';
      notifyListeners();
      return false;
    }

    dangGui = true;
    loi = null;
    loiMoTa = null;
    notifyListeners();
    try {
      // Ngày SC = hôm nay; server ghi NgayTao = DateTime.Now
      await WorkOrderService.taoHoSoSuaChua(
        maThietBi: thietBiChon!.maThietBi,
        moTaHuHong: moTa,
        phuongAnSuaChua: (phuongAnSuaChua == null || phuongAnSuaChua.trim().isEmpty)
            ? null
            : phuongAnSuaChua.trim(),
        guiDuyet: true,
      );
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } finally {
      dangGui = false;
      notifyListeners();
    }
  }
}