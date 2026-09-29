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

  /// true = nhập phút; false = nhập giờ.
  bool nhapPhut = false;

  void datDonViThoiGian({required bool laPhut}) {
    nhapPhut = laPhut;
    notifyListeners();
  }

  String? validateThoiGian(String? v) =>
      formValidateThoiGianDuKien(v, laPhut: nhapPhut);

  /// Trả về true nếu tạo thành công — presentation chỉ cần pop(context, true) khi true.
  Future<bool> luu({
    required int maChiTietKeHoach,
    required int maThietBi,
    required String noiDungCongViec,
    required String thoiGianDuKien,
    required bool guiDuyet,
  }) async {
    final kq = validateThoiGianDuKien(thoiGianDuKien, laPhut: nhapPhut);
    if (!kq.hopLe) {
      loi = kq.loi;
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
        thoiGianDuKien: kq.chuoiLuu,
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
    if (!thoiGianHopLe || chuoiThoiGianLuu == null) {
      loi = loiThoiGian ?? 'Vui lòng nhập thời gian dự kiến (giờ hoặc phút)';
      notifyListeners();
      return false;
    }
    if (gioBatDau == null) {
      loi = 'Vui lòng chọn giờ bắt đầu';
      notifyListeners();
      return false;
    }
    if (gioKetThuc == null) {
      loi =
      'Chưa tính được giờ kết thúc (thời lượng có thể tràn sang ngày sau)';
      notifyListeners();
      return false;
    }
    dangGui = true;
    notifyListeners();
    try {
      await WorkOrderService.taoHoSoSuaChua(
        maThietBi: thietBiChon!.maThietBi,
        moTaHuHong: moTa,
        phuongAnSuaChua: phuongAnSuaChua?.trim().isEmpty == true
            ? null
            : phuongAnSuaChua?.trim(),
        thoiGianDuKien: chuoiThoiGianLuu,
        gioBatDauDuKien: fmtGio(gioBatDau),
        gioKetThucDuKien: fmtGio(gioKetThuc),
        guiDuyet: true,
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