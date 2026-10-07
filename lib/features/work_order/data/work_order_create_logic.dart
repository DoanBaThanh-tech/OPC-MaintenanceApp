import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;

import '../../../core/network/api_exception.dart';
import '../../equipment/data/equipment_logic.dart';
import 'services/work_order_service.dart';
import 'work_order_validators.dart';

// Logic cho work_order_create_screen.dart

class CreateWorkOrderBaoTriController extends ChangeNotifier {
  bool dangLuu = false;
  String? loi;

  /// Thời gian dự kiến / bắt đầu / kết thúc không nhập khi tạo —
  /// hệ thống ghi nhận khi NVKT Tiến hành và khi hoàn thành.
  Future<bool> luu({
    required int maChiTietKeHoach,
    required int maThietBi,
    required String noiDungCongViec,
    required bool guiDuyet,
    List<Map<String, dynamic>>? danhSachBuoc,
  }) async {
    dangLuu = true;
    loi = null;
    notifyListeners();
    try {
      await WorkOrderService.taoHoSoBaoTri(
        maChiTietKeHoach: maChiTietKeHoach,
        maThietBi: maThietBi,
        noiDungCongViec: noiDungCongViec,
        thoiGianDuKien: null,
        guiDuyet: guiDuyet,
        danhSachBuoc: danhSachBuoc,
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
// TẠO HỒ SƠ SỬA CHỮA (Xưởng)
// ============================================================

class CreateHoSoSuaChuaController extends ChangeNotifier {
  List<NhomThietBiTheoDanhMuc> nhoms = [];
  String? danhMucChon;
  ThietBiModel? thietBiChon;

  late final DateTime ngaySuaChua;

  /// true = nhập phút; false = nhập giờ.
  bool nhapPhut = false;
  int? soGioDuKien;
  int? soPhutDuKien;
  String? loiThoiGian;
  TimeOfDay? gioBatDau;
  TimeOfDay? gioKetThuc;

  bool dangTai = true;
  bool dangGui = false;
  String? loi;
  String? loiMoTa;

  CreateHoSoSuaChuaController() {
    final now = DateTime.now();
    ngaySuaChua = DateTime(now.year, now.month, now.day);
  }

  String get ngaySuaChuaHienThi {
    final d = ngaySuaChua;
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/'
        '${d.year}';
  }

  bool get thoiGianHopLe {
    if (loiThoiGian != null) return false;
    if (nhapPhut) return soPhutDuKien != null && soPhutDuKien! > 0;
    return soGioDuKien != null && soGioDuKien! > 0;
  }

  String? get chuoiThoiGianLuu {
    if (nhapPhut && soPhutDuKien != null) return '${soPhutDuKien}p';
    if (soGioDuKien != null) return '$soGioDuKien';
    return null;
  }

  String? fmtGio(TimeOfDay? t) {
    if (t == null) return null;
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  List<ThietBiModel> get dsThietBiTheoDanhMuc {
    if (danhMucChon == null) return const [];
    final match = nhoms.where((n) => n.tenDanhMuc == danhMucChon);
    if (match.isEmpty) return const [];
    return match.first.danhSach
        .where((t) => t.tinhTrangHienTai == TrangThaiThietBi.sanXuat)
        .toList();
  }

  Future<void> khoiTao() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      nhoms = await EquipmentService.layTheoDanhMuc(
        trangThai: TrangThaiThietBi.sanXuat,
      );
    } catch (e) {
      loi = 'Không tải được danh mục thiết bị: $e';
      nhoms = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

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
    if (loiMoTa != null) {
      loiMoTa = null;
      notifyListeners();
    }
  }

  void datDonViThoiGian({required bool laPhut}) {
    nhapPhut = laPhut;
    notifyListeners();
  }

  void datThoiGianTuChuoi(String raw) {
    // Trần tuyệt đối giờ ≤24 / phút ≤1440 — không giảm theo giờ bắt đầu
    final kq = validateThoiGianDuKien(
      raw,
      laPhut: nhapPhut,
    );
    loiThoiGian = kq.loi;
    if (!kq.hopLe) {
      soGioDuKien = null;
      soPhutDuKien = null;
      gioKetThuc = null;
    } else if (kq.laPhut) {
      soPhutDuKien = kq.soPhut;
      soGioDuKien = null;
      nhapPhut = true;
      final phutThem = soPhutDuKien ?? 0;
      if (gioBatDau != null && phutThem > 0) {
        gioKetThuc = tinhGioKetThuc(gioBatDau: gioBatDau!, tongPhut: phutThem);
      } else {
        _tinhGioKetThuc();
      }
    } else {
      soGioDuKien = kq.soGio;
      soPhutDuKien = null;
      nhapPhut = false;
      final phutThem = (soGioDuKien ?? 0) * 60;
      if (gioBatDau != null && phutThem > 0) {
        gioKetThuc = tinhGioKetThuc(gioBatDau: gioBatDau!, tongPhut: phutThem);
      } else {
        _tinhGioKetThuc();
      }
    }
    notifyListeners();
  }

  void datGioBatDau(TimeOfDay t) {
    if (!thoiGianHopLe) {
      loi = 'Nhập thời gian dự kiến hợp lệ trước khi chọn giờ bắt đầu';
      notifyListeners();
      return;
    }
    gioBatDau = t;
    loi = null;
    // Re-validate với giờ bắt đầu mới (không tràn ngày)
    final raw = nhapPhut
        ? (soPhutDuKien?.toString() ?? '')
        : (soGioDuKien?.toString() ?? '');
    if (raw.isNotEmpty) {
      final kq = validateThoiGianDuKien(
        raw,
        laPhut: nhapPhut,
        gioBatDau: t,
      );
      loiThoiGian = kq.loi;
      if (!kq.hopLe) {
        gioKetThuc = null;
        notifyListeners();
        return;
      }
    }
    _tinhGioKetThuc();
    notifyListeners();
  }

  void _tinhGioKetThuc() {
    final phutThem =
    nhapPhut ? (soPhutDuKien ?? 0) : (soGioDuKien ?? 0) * 60;
    if (gioBatDau == null || phutThem <= 0) {
      gioKetThuc = null;
      return;
    }
    gioKetThuc = tinhGioKetThuc(gioBatDau: gioBatDau!, tongPhut: phutThem);
    if (gioKetThuc == null) {
      loiThoiGian =
      'Thời lượng + giờ bắt đầu vượt quá 24:00 — không được lấn sang ngày khác';
    }
  }

  Future<bool> gui({
    required String moTaHuHong,
    String? phuongAnSuaChua,
    List<Map<String, dynamic>>? danhSachBuoc,
  }) async {
    loi = null;
    loiMoTa = null;
    final moTa = moTaHuHong.trim();
    if (moTa.isEmpty) {
      loiMoTa = 'Vui lòng mô tả hư hỏng';
      notifyListeners();
      return false;
    }
    if (thietBiChon == null) {
      loi = 'Vui lòng chọn thiết bị';
      notifyListeners();
      return false;
    }
    // Không nhập thời gian khi tạo — ghi nhận khi NVKT Tiến hành / hoàn thành
    dangGui = true;
    notifyListeners();
    try {
      await WorkOrderService.taoHoSoSuaChua(
        maThietBi: thietBiChon!.maThietBi,
        moTaHuHong: moTa,
        phuongAnSuaChua: phuongAnSuaChua?.trim().isEmpty == true
            ? null
            : phuongAnSuaChua?.trim(),
        thoiGianDuKien: null,
        gioBatDauDuKien: null,
        gioKetThucDuKien: null,
        guiDuyet: true,
        danhSachBuoc: danhSachBuoc,
      );
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } catch (e) {
      loi = 'Lỗi: $e';
      return false;
    } finally {
      dangGui = false;
      notifyListeners();
    }
  }
}

/// Tạo hồ sơ bảo trì thủ công (thiết bị mới / không qua hàng chờ).
class CreateWorkOrderBaoTriThuCongController extends ChangeNotifier {
  List<NhomThietBiTheoDanhMuc> nhoms = [];
  String? danhMucChon;
  ThietBiModel? thietBiChon;
  bool dangTai = true;
  bool dangLuu = false;
  String? loi;

  List<ThietBiModel> get dsThietBiTheoDanhMuc {
    if (danhMucChon == null) return const [];
    final match = nhoms.where((n) => n.tenDanhMuc == danhMucChon);
    if (match.isEmpty) return const [];
    return match.first.danhSach
        .where((t) => t.tinhTrangHienTai == TrangThaiThietBi.sanXuat)
        .toList();
  }

  Future<void> khoiTao() async {
    dangTai = true;
    loi = null;
    notifyListeners();
    try {
      nhoms = await EquipmentService.layTheoDanhMuc(
        trangThai: TrangThaiThietBi.sanXuat,
      );
    } catch (e) {
      loi = 'Không tải được danh mục thiết bị: $e';
      nhoms = [];
    } finally {
      dangTai = false;
      notifyListeners();
    }
  }

  void chonDanhMuc(String? v) {
    danhMucChon = v;
    thietBiChon = null;
    notifyListeners();
  }

  void chonThietBi(ThietBiModel? v) {
    thietBiChon = v;
    notifyListeners();
  }

  Future<bool> luu({
    required String noiDungCongViec,
    List<Map<String, dynamic>>? danhSachBuoc,
  }) async {
    loi = null;
    if (thietBiChon == null) {
      loi = 'Vui lòng chọn thiết bị';
      notifyListeners();
      return false;
    }
    if (noiDungCongViec.trim().isEmpty) {
      loi = 'Vui lòng nhập nội dung công việc';
      notifyListeners();
      return false;
    }
    dangLuu = true;
    notifyListeners();
    try {
      await WorkOrderService.taoHoSoBaoTri(
        maThietBi: thietBiChon!.maThietBi,
        noiDungCongViec: noiDungCongViec.trim(),
        thoiGianDuKien: null,
        guiDuyet: true,
        danhSachBuoc: danhSachBuoc,
      );
      return true;
    } on ApiException catch (e) {
      loi = e.message;
      return false;
    } catch (e) {
      loi = '$e';
      return false;
    } finally {
      dangLuu = false;
      notifyListeners();
    }
  }
}